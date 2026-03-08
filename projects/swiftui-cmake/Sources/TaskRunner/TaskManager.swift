import Foundation

/// Manages a collection of `ManagedTask`s and runs them concurrently.
@Observable
public final class TaskManager {

    public private(set) var tasks: [ManagedTask] = []

    public init() {}

    // MARK: - Task lifecycle

    /// Register a new task (in pending state). Returns the managed wrapper.
    @discardableResult
    public func add(_ appTask: any AppTask) -> ManagedTask {
        let managed = ManagedTask(appTask: appTask)
        tasks.append(managed)
        return managed
    }

    /// Start a single pending task.
    public func start(_ managed: ManagedTask) {
        guard managed.status == .pending else { return }
        managed.markRunning()

        managed.handle = Task { [weak managed] in
            guard let managed else { return }
            do {
                try await managed.appTask.run(context: managed.context)
                if managed.context.isCancelled {
                    managed.markCancelled()
                } else {
                    managed.markCompleted()
                }
            } catch is CancellationError {
                managed.markCancelled()
            } catch {
                managed.markFailed(error.localizedDescription)
            }
        }
    }

    /// Cancel a running task.
    public func cancel(_ managed: ManagedTask) {
        guard managed.status == .running else { return }
        managed.context.requestCancellation()
        managed.handle?.cancel()
    }

    /// Remove a task from the manager. Cancels it first if running.
    public func remove(_ managed: ManagedTask) {
        if managed.status == .running {
            cancel(managed)
        }
        tasks.removeAll { $0.id == managed.id }
    }

    /// Start all pending tasks concurrently.
    public func startAll() {
        for task in tasks where task.status == .pending {
            start(task)
        }
    }

    /// Cancel all running tasks.
    public func cancelAll() {
        for task in tasks where task.status == .running {
            cancel(task)
        }
    }

    /// Remove all tasks that have reached a terminal state.
    public func clearFinished() {
        tasks.removeAll { $0.status.isTerminal }
    }

    // MARK: - Computed helpers

    public var runningCount: Int {
        tasks.count(where: { $0.status == .running })
    }

    public var pendingCount: Int {
        tasks.count(where: { $0.status == .pending })
    }

    public var hasRunningTasks: Bool {
        runningCount > 0
    }
}
