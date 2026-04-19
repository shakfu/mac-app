import SwiftUI
import AppKit
import llama

@main
struct InferApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var chatVM = ChatViewModel()

    var body: some Scene {
        WindowGroup("Infer") {
            ChatView(vm: chatVM)
                .onAppear { appDelegate.chatVM = chatVM }
        }
        .defaultSize(width: 780, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Populated by InferApp.onAppear so terminate can reach the runner.
    var chatVM: ChatViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        // Block the main thread briefly so the llama context is freed and any
        // in-flight decode is cancelled before the process exits.
        guard let vm = chatVM else { return }
        let sem = DispatchSemaphore(value: 0)
        Task.detached {
            await vm.runner.requestStop()
            await vm.runner.shutdown()
            llama_backend_free()
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 2.0)
    }
}
