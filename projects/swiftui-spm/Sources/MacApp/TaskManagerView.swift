import SwiftUI
import TaskRunner

struct TaskManagerView: View {
    @Bindable var manager: TaskManager

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if manager.tasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Text("Tasks")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Menu("Add Task") {
                Button("Countdown (10s)") {
                    manager.add(CountdownTask(seconds: 10))
                }
                Button("Countdown (30s)") {
                    manager.add(CountdownTask(seconds: 30))
                }
                Button("Fibonacci (1..20)") {
                    manager.add(FibonacciTask(count: 20))
                }
                Button("Fibonacci (1..30)") {
                    manager.add(FibonacciTask(count: 30))
                }
                Button("Random Fail") {
                    manager.add(RandomFailTask())
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button("Start All") {
                manager.startAll()
            }
            .disabled(manager.pendingCount == 0)

            Button("Cancel All") {
                manager.cancelAll()
            }
            .disabled(!manager.hasRunningTasks)

            Button("Clear Finished") {
                manager.clearFinished()
            }
            .disabled(manager.tasks.allSatisfy { !$0.status.isTerminal })
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No tasks")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Use \"Add Task\" to create tasks, then start them.")
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Task list

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(manager.tasks) { managed in
                    TaskRowView(managed: managed, manager: manager)
                }
            }
            .padding()
        }
    }
}

// MARK: - Row

struct TaskRowView: View {
    @Bindable var managed: ManagedTask
    let manager: TaskManager

    @State private var showLogs = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                statusIndicator
                Text(managed.name)
                    .fontWeight(.medium)
                Spacer()
                Text(managed.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                rowButtons
            }

            if managed.status == .running {
                ProgressView(value: managed.context.progress)
                    .progressViewStyle(.linear)
                if !managed.context.statusMessage.isEmpty {
                    Text(managed.context.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = managed.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let elapsed = managed.elapsed {
                Text(String(format: "%.1fs elapsed", elapsed))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if showLogs && !managed.context.logs.isEmpty {
                logView
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
    }

    private var statusColor: Color {
        switch managed.status {
        case .pending:   return .gray
        case .running:   return .blue
        case .completed: return .green
        case .failed:    return .red
        case .cancelled: return .orange
        }
    }

    private var rowButtons: some View {
        HStack(spacing: 4) {
            if managed.status == .pending {
                Button("Start") { manager.start(managed) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            if managed.status == .running {
                Button("Cancel") { manager.cancel(managed) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Button(showLogs ? "Hide Logs" : "Logs") {
                showLogs.toggle()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if managed.status.isTerminal {
                Button("Remove") { manager.remove(managed) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private var logView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(managed.context.logs.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 150)
        .padding(8)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
