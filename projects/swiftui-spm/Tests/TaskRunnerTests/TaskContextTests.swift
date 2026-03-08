import Testing
import Foundation
@testable import TaskRunner

@Suite("TaskContext Tests")
struct TaskContextTests {

    @Test func initialState() {
        let ctx = TaskContext()
        #expect(ctx.progress == 0)
        #expect(ctx.statusMessage == "")
        #expect(ctx.logs.isEmpty)
        #expect(ctx.isCancelled == false)
    }

    @Test func progressClamped() {
        let ctx = TaskContext()
        ctx.setProgress(0.5)
        #expect(ctx.progress == 0.5)
        ctx.setProgress(1.5)
        #expect(ctx.progress == 1.0)
        ctx.setProgress(-0.5)
        #expect(ctx.progress == 0.0)
    }

    @Test func statusMessage() {
        let ctx = TaskContext()
        ctx.setStatus("working")
        #expect(ctx.statusMessage == "working")
    }

    @Test func logsAccumulate() {
        let ctx = TaskContext()
        ctx.log("first")
        ctx.log("second")
        #expect(ctx.logs == ["first", "second"])
    }

    @Test func cancellation() throws {
        let ctx = TaskContext()
        // Should not throw when not cancelled
        try ctx.checkCancellation()

        ctx.requestCancellation()
        #expect(ctx.isCancelled == true)
        #expect(throws: CancellationError.self) {
            try ctx.checkCancellation()
        }
    }
}
