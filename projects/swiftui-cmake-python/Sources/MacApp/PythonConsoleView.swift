import SwiftUI
import PythonBridge

struct PythonConsoleView: View {
    @State private var source: String = "print('Hello from Python!')"
    @State private var output: String = ""
    @State private var isInitialized = false
    @State private var initError: String?

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            HSplitView {
                editorPane
                outputPane
            }
        }
        .task {
            initializePython()
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("Python Console")
                .font(.title)
                .fontWeight(.bold)
            if isInitialized {
                Text("Embedded Python interpreter ready")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let error = initError {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            } else {
                Text("Initializing Python...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private var editorPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Source")
                    .font(.headline)
                Spacer()
                Button("Run") {
                    runCode()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(!isInitialized)
            }

            TextEditor(text: $source)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding()
        .frame(minWidth: 250)
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    output = ""
                }
                .buttonStyle(.bordered)
                .disabled(output.isEmpty)
            }

            ScrollView {
                Text(output.isEmpty ? "(no output)" : output)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(output.isEmpty ? .tertiary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding()
        .frame(minWidth: 250)
    }

    private func initializePython() {
        guard let fwPath = Bundle.main.privateFrameworksPath else {
            initError = "Could not locate Frameworks directory"
            return
        }

        let home = fwPath + "/Python.framework/Versions/" + PythonBridge.version
        do {
            try PythonBridge.initialize(home: home)
            isInitialized = true
        } catch {
            initError = "Init failed: \(error)"
        }
    }

    private func runCode() {
        do {
            let result = try PythonBridge.run(source)
            if !result.isEmpty {
                if !output.isEmpty {
                    output += "\n"
                }
                output += result
            }
        } catch {
            if !output.isEmpty {
                output += "\n"
            }
            output += "Error: \(error)"
        }
    }
}
