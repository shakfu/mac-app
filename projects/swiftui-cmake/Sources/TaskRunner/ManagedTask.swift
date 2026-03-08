import Foundation

/// Wraps an `AppTask` with its runtime state (status, context, Swift Task handle).
@Observable
public final class ManagedTask: Identifiable {
    public let id: UUID
    public let appTask: any AppTask
    public let context: TaskContext
    public private(set) var status: TaskStatus = .pending
    public private(set) var error: String?
    public private(set) var startedAt: Date?
    public private(set) var finishedAt: Date?

    /// The underlying Swift concurrency task handle.
    var handle: Task<Void, Never>?

    public init(appTask: any AppTask) {
        self.id = UUID()
        self.appTask = appTask
        self.context = TaskContext()
    }

    public var name: String { appTask.name }

    public var elapsed: TimeInterval? {
        guard let start = startedAt else { return nil }
        let end = finishedAt ?? Date()
        return end.timeIntervalSince(start)
    }

    // MARK: - Internal state transitions

    func markRunning() {
        status = .running
        startedAt = Date()
    }

    func markCompleted() {
        status = .completed
        finishedAt = Date()
    }

    func markFailed(_ message: String) {
        status = .failed
        error = message
        finishedAt = Date()
    }

    func markCancelled() {
        status = .cancelled
        finishedAt = Date()
    }
}
