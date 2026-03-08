import Foundation
import TaskRunner

/// Example task that counts down from N to 0, sleeping between steps.
struct CountdownTask: AppTask {
    let name: String
    let seconds: Int

    init(seconds: Int = 10) {
        self.name = "Countdown (\(seconds)s)"
        self.seconds = seconds
    }

    func run(context: TaskContext) async throws {
        context.log("Starting countdown from \(seconds)")
        for i in stride(from: seconds, through: 0, by: -1) {
            try context.checkCancellation()
            context.setStatus("\(i) seconds remaining")
            context.setProgress(Double(seconds - i) / Double(seconds))
            context.log("Tick: \(i)")
            if i > 0 {
                try await Task.sleep(for: .seconds(1))
            }
        }
        context.setProgress(1.0)
        context.setStatus("Done")
        context.log("Countdown finished")
    }
}
