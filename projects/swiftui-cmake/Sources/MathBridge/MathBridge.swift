import CMathLib

/// Swift-idiomatic wrapper around the C mathlib library.
public enum MathBridge {

    /// Errors that can occur during math operations.
    public enum MathError: Error, CustomStringConvertible {
        case divisionByZero
        case negativeInput

        public var description: String {
            switch self {
            case .divisionByZero: return "Division by zero"
            case .negativeInput: return "Negative input not allowed"
            }
        }
    }

    public static func add(_ a: Int32, _ b: Int32) -> Int32 {
        mathlib_add(a, b)
    }

    public static func subtract(_ a: Int32, _ b: Int32) -> Int32 {
        mathlib_subtract(a, b)
    }

    public static func multiply(_ a: Int32, _ b: Int32) -> Int32 {
        mathlib_multiply(a, b)
    }

    public static func divide(_ a: Int32, _ b: Int32) throws -> Int32 {
        var error: Int32 = 0
        let result = mathlib_divide(a, b, &error)
        if error != 0 {
            throw MathError.divisionByZero
        }
        return result
    }

    public static func factorial(_ n: Int32) throws -> Int64 {
        let result = mathlib_factorial(n)
        if result < 0 {
            throw MathError.negativeInput
        }
        return result
    }

    public static func fibonacci(_ n: Int32) throws -> Int64 {
        let result = mathlib_fibonacci(n)
        if result < 0 {
            throw MathError.negativeInput
        }
        return result
    }
}
