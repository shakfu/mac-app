import SwiftUI
import TaskRunner

@main
struct MacApp: App {
    @State private var manager = TaskManager()
    @State private var selectedTab: AppTab = .tasks

    enum AppTab: String, CaseIterable, Identifiable {
        case tasks = "Tasks"
        case math = "Math Demo"
        var id: String { rawValue }
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    ForEach(AppTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(8)

                Divider()

                switch selectedTab {
                case .tasks:
                    TaskManagerView(manager: manager)
                case .math:
                    ContentView()
                }
            }
        }
        .defaultSize(width: 700, height: 600)
        .commands {
            taskMenuCommands
        }
    }

    private var taskMenuCommands: some Commands {
        CommandGroup(after: .newItem) {
            Divider()
            Menu("New Task") {
                Button("Countdown (10s)") {
                    addAndSwitch(CountdownTask(seconds: 10))
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])

                Button("Countdown (30s)") {
                    addAndSwitch(CountdownTask(seconds: 30))
                }

                Button("Fibonacci (1..20)") {
                    addAndSwitch(FibonacciTask(count: 20))
                }
                .keyboardShortcut("2", modifiers: [.command, .shift])

                Button("Fibonacci (1..30)") {
                    addAndSwitch(FibonacciTask(count: 30))
                }

                Button("Random Fail") {
                    addAndSwitch(RandomFailTask())
                }
                .keyboardShortcut("3", modifiers: [.command, .shift])
            }

            Divider()

            Button("Start All Tasks") {
                manager.startAll()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(manager.pendingCount == 0)

            Button("Cancel All Tasks") {
                manager.cancelAll()
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])
            .disabled(!manager.hasRunningTasks)

            Button("Clear Finished Tasks") {
                manager.clearFinished()
            }
        }
    }

    private func addAndSwitch(_ task: any AppTask) {
        manager.add(task)
        selectedTab = .tasks
    }
}
