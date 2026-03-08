import Testing
import Foundation
@testable import TaskRunner

/// A minimal task that completes after a fixed number of steps.
struct StepTask: AppTask {
    let name: String
    let steps: Int
    let stepDelay: Duration

    init(name: String = "StepTask", steps: Int = 5, stepDelay: Duration = .milliseconds(50)) {
        self.name = name
        self.steps = steps
        self.stepDelay = stepDelay
    }

    func run(context: TaskContext) async throws {
        for i in 0..<steps {
            try context.checkCancellation()
            context.setProgress(Double(i + 1) / Double(steps))
            context.setStatus("Step \(i + 1)/\(steps)")
            try await Task.sleep(for: stepDelay)
        }
    }
}

/// A task that always throws.
struct FailingTask: AppTask {
    let name = "FailingTask"

    func run(context: TaskContext) async throws {
        throw NSError(domain: "test", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "intentional failure"
        ])
    }
}

@Suite("TaskManager Tests")
struct TaskManagerTests {

    @Test func addCreatesTask() {
        let mgr = TaskManager()
        let managed = mgr.add(StepTask())
        #expect(mgr.tasks.count == 1)
        #expect(managed.status == .pending)
        #expect(managed.name == "StepTask")
    }

    @Test func startRunsTask() async throws {
        let mgr = TaskManager()
        let managed = mgr.add(StepTask(steps: 3, stepDelay: .milliseconds(30)))
        mgr.start(managed)
        #expect(managed.status == .running)

        // Wait for completion
        while !managed.status.isTerminal {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(managed.status == .completed)
        #expect(managed.context.progress == 1.0)
        #expect(managed.startedAt != nil)
        #expect(managed.finishedAt != nil)
    }

    @Test func cancelStopsTask() async throws {
        let mgr = TaskManager()
        let managed = mgr.add(StepTask(steps: 100, stepDelay: .milliseconds(50)))
        mgr.start(managed)

        // Let it run briefly, then cancel
        try await Task.sleep(for: .milliseconds(100))
        mgr.cancel(managed)

        // Wait for the cancellation to take effect
        while !managed.status.isTerminal {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(managed.status == .cancelled)
    }

    @Test func failingTaskReportsError() async throws {
        let mgr = TaskManager()
        let managed = mgr.add(FailingTask())
        mgr.start(managed)

        while !managed.status.isTerminal {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(managed.status == .failed)
        #expect(managed.error == "intentional failure")
    }

    @Test func startAllRunsConcurrently() async throws {
        let mgr = TaskManager()
        let a = mgr.add(StepTask(name: "A", steps: 3, stepDelay: .milliseconds(30)))
        let b = mgr.add(StepTask(name: "B", steps: 3, stepDelay: .milliseconds(30)))
        let c = mgr.add(StepTask(name: "C", steps: 3, stepDelay: .milliseconds(30)))

        mgr.startAll()
        #expect(mgr.runningCount == 3)

        while mgr.hasRunningTasks {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(a.status == .completed)
        #expect(b.status == .completed)
        #expect(c.status == .completed)
    }

    @Test func cancelAllStopsRunning() async throws {
        let mgr = TaskManager()
        mgr.add(StepTask(name: "A", steps: 100, stepDelay: .milliseconds(50)))
        mgr.add(StepTask(name: "B", steps: 100, stepDelay: .milliseconds(50)))
        mgr.startAll()

        try await Task.sleep(for: .milliseconds(100))
        mgr.cancelAll()

        while mgr.hasRunningTasks {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(mgr.tasks.allSatisfy { $0.status == .cancelled })
    }

    @Test func removeTask() {
        let mgr = TaskManager()
        let managed = mgr.add(StepTask())
        #expect(mgr.tasks.count == 1)
        mgr.remove(managed)
        #expect(mgr.tasks.isEmpty)
    }

    @Test func clearFinishedKeepsRunning() async throws {
        let mgr = TaskManager()
        let fast = mgr.add(StepTask(name: "Fast", steps: 2, stepDelay: .milliseconds(20)))
        let slow = mgr.add(StepTask(name: "Slow", steps: 100, stepDelay: .milliseconds(50)))

        mgr.startAll()

        // Wait for fast to finish
        while !fast.status.isTerminal {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(slow.status == .running)

        mgr.clearFinished()
        #expect(mgr.tasks.count == 1)
        #expect(mgr.tasks.first?.name == "Slow")

        mgr.cancelAll()
    }

    @Test func startIgnoresNonPending() async throws {
        let mgr = TaskManager()
        let managed = mgr.add(StepTask(steps: 2, stepDelay: .milliseconds(20)))
        mgr.start(managed)
        while !managed.status.isTerminal {
            try await Task.sleep(for: .milliseconds(20))
        }
        // Starting a completed task should be a no-op
        mgr.start(managed)
        #expect(managed.status == .completed)
    }
}
