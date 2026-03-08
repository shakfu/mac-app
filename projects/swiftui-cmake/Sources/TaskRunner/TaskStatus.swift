import Foundation

/// Lifecycle state of a managed task.
public enum TaskStatus: String, Sendable {
    case pending   = "Pending"
    case running   = "Running"
    case completed = "Completed"
    case failed    = "Failed"
    case cancelled = "Cancelled"

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled: return true
        case .pending, .running: return false
        }
    }
}
