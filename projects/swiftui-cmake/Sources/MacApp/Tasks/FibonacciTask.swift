import Foundation
import TaskRunner
import MathBridge

/// Example task that computes Fibonacci numbers up to N, with a delay
/// between each to simulate heavier work.
struct FibonacciTask: AppTask {
    let name: String
    let count: Int32

    init(count: Int32 = 30) {
        self.name = "Fibonacci (1..\(count))"
        self.count = count
    }

    func run(context: TaskContext) async throws {
        context.log("Computing Fibonacci numbers from 1 to \(count)")
        for i: Int32 in 1...count {
            try context.checkCancellation()
            let result = try MathBridge.fibonacci(i)
            context.setProgress(Double(i) / Double(count))
            context.setStatus("fib(\(i)) = \(result)")
            context.log("fib(\(i)) = \(result)")
            try await Task.sleep(for: .milliseconds(200))
        }
        context.setProgress(1.0)
        context.setStatus("Done")
        context.log("Fibonacci computation complete")
    }
}
