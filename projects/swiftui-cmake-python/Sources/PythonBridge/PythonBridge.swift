import CPythonLib
import Foundation

/// Swift wrapper around the embedded Python interpreter.
public enum PythonBridge {

    /// Python version string (major.minor), set at build time via -DPY_VER_STRING.
    /// Falls back to "3.13" if not provided.
    #if PY_VER_3_14
    public static let version = "3.14"
    #elseif PY_VER_3_12
    public static let version = "3.12"
    #elseif PY_VER_3_11
    public static let version = "3.11"
    #else
    public static let version = "3.13"
    #endif

    public enum PythonError: Error, CustomStringConvertible {
        case initFailed
        case notInitialized
        case executionFailed(String)

        public var description: String {
            switch self {
            case .initFailed:
                return "Failed to initialize Python interpreter"
            case .notInitialized:
                return "Python interpreter is not initialized"
            case .executionFailed(let message):
                return message.isEmpty ? "Python execution failed" : message
            }
        }
    }

    /// Initialize the Python interpreter with the given framework prefix.
    /// - Parameter home: Path to `Python.framework/Versions/X.Y`
    public static func initialize(home: String) throws {
        let rc = python_init(home)
        if rc != 0 {
            throw PythonError.initFailed
        }
    }

    /// Whether the interpreter is currently initialized.
    public static var isInitialized: Bool {
        python_is_initialized() != 0
    }

    /// Execute Python source code and return the captured stdout/stderr.
    /// - Parameter code: Python source to execute.
    /// - Returns: The combined stdout and stderr output (may be empty).
    public static func run(_ code: String) throws -> String {
        guard isInitialized else {
            throw PythonError.notInitialized
        }

        var outputPtr: UnsafeMutablePointer<CChar>?
        let rc = python_run(code, &outputPtr)

        var output = ""
        if let ptr = outputPtr {
            output = String(cString: ptr)
            free(ptr)
        }

        if rc != 0 {
            throw PythonError.executionFailed(output)
        }

        return output
    }

    /// Shut down the interpreter.
    public static func shutdown() {
        python_finalize()
    }
}
