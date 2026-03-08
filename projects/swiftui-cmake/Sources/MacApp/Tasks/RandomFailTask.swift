import Foundation
import TaskRunner

/// Example task that randomly fails partway through, useful for testing
/// error handling in the UI.
struct RandomFailTask: AppTask {
    let name = "Random Fail"

    func run(context: TaskContext) async throws {
        let steps = 20
        let failAt = Int.random(in: 5..<steps)
        context.log("Will attempt \(steps) steps (may fail at step \(failAt))")

        for i in 0..<steps {
            try context.checkCancellation()
            context.setProgress(Double(i) / Double(steps))
            context.setStatus("Step \(i + 1)/\(steps)")
            context.log("Processing step \(i + 1)")

            if i == failAt {
                context.log("Simulated failure at step \(i + 1)")
                throw TaskError.simulatedFailure(step: i + 1)
            }

            try await Task.sleep(for: .milliseconds(300))
        }
        context.setProgress(1.0)
        context.setStatus("Done")
    }
}

enum TaskError: Error, LocalizedError {
    case simulatedFailure(step: Int)

    var errorDescription: String? {
        switch self {
        case .simulatedFailure(let step):
            return "Simulated failure at step \(step)"
        }
    }
}
