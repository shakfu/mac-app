import Foundation

/// Shared context passed to a running `AppTask`. Thread-safe.
/// Tasks use this to report progress, log messages, and check cancellation.
@Observable
public final class TaskContext: @unchecked Sendable {

    /// Fraction complete, 0.0 to 1.0.
    public private(set) var progress: Double = 0

    /// Short status string shown in the UI.
    public private(set) var statusMessage: String = ""

    /// Accumulated log lines.
    public private(set) var logs: [String] = []

    /// Whether cancellation has been requested.
    public private(set) var isCancelled: Bool = false

    private let lock = NSLock()

    public init() {}

    // MARK: - API for task implementations

    /// Update the progress fraction (clamped to 0...1).
    public func setProgress(_ value: Double) {
        lock.withLock {
            progress = min(max(value, 0), 1)
        }
    }

    /// Set the short status message.
    public func setStatus(_ message: String) {
        lock.withLock {
            statusMessage = message
        }
    }

    /// Append a log line.
    public func log(_ message: String) {
        lock.withLock {
            logs.append(message)
        }
    }

    /// Throws `CancellationError` if the task has been cancelled.
    public func checkCancellation() throws {
        if isCancelled {
            throw CancellationError()
        }
    }

    // MARK: - Internal

    func requestCancellation() {
        lock.withLock {
            isCancelled = true
        }
    }
}
