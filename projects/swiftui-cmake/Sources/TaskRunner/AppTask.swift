import Foundation

/// Protocol that defines a runnable task. Implement this to create
/// custom tasks that the TaskManager can execute concurrently.
public protocol AppTask: Sendable {
    /// Human-readable name for display in the UI.
    var name: String { get }

    /// Execute the task's work. Use `context` to report progress,
    /// emit log lines, and check for cancellation.
    func run(context: TaskContext) async throws
}
