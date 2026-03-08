import SwiftUI
import TaskRunner

@main
struct MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
            // Replace the default "New Window" with our task commands
            CommandGroup(replacing: .newItem) {
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
            }

            // Tasks menu
            CommandMenu("Tasks") {
                Button("Start All") {
                    manager.startAll()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(manager.pendingCount == 0)

                Button("Cancel All") {
                    manager.cancelAll()
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
                .disabled(!manager.hasRunningTasks)

                Divider()

                Button("Clear Finished") {
                    manager.clearFinished()
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                .disabled(manager.tasks.allSatisfy { !$0.status.isTerminal })
            }

            // Standard Edit menu (undo/redo/cut/copy/paste/select all)
            CommandGroup(replacing: .textEditing) {
                Button("Cut") {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x")

                Button("Copy") {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("c")

                Button("Paste") {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("v")

                Button("Select All") {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a")
            }

            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z")

                Button("Redo") {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            // View menu: switch tabs
            CommandMenu("View") {
                Button("Show Tasks") {
                    selectedTab = .tasks
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Show Math Demo") {
                    selectedTab = .math
                }
                .keyboardShortcut("2", modifiers: .command)
            }
        }
    }

    private func addAndSwitch(_ task: any AppTask) {
        manager.add(task)
        selectedTab = .tasks
    }
}

// MARK: - App Delegate

/// Ensures the app activates properly as a foreground application,
/// even when launched via `swift run`.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
