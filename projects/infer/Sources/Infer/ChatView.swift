import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ChatMessage: Identifiable, Equatable {
    enum Role: String { case user, assistant, system }
    let id = UUID()
    let role: Role
    var text: String
}

enum Backend: String, CaseIterable, Identifiable {
    case llama
    case mlx
    var id: String { rawValue }
    var label: String {
        switch self {
        case .llama: return "llama.cpp"
        case .mlx: return "MLX"
        }
    }
}

@MainActor
@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var input: String = ""
    var backend: Backend = .llama
    var modelLoaded: Bool = false
    var modelStatus: String = "No model loaded"
    var isLoadingModel = false
    var isGenerating = false
    var errorMessage: String? = nil
    /// User-entered HF repo id for MLX; empty => registry default.
    var mlxModelId: String = ""

    let llama = LlamaRunner()
    let mlx = MLXRunner()
    private var generationTask: Task<Void, Never>? = nil

    // MARK: - Loading

    func loadCurrentBackend() {
        switch backend {
        case .llama: pickLlamaModel()
        case .mlx: loadMLX(hfId: mlxModelId.trimmingCharacters(in: .whitespaces))
        }
    }

    private func pickLlamaModel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if let gguf = UTType(filenameExtension: "gguf") {
            panel.allowedContentTypes = [gguf]
        }
        panel.message = "Select a .gguf model file"
        if panel.runModal() == .OK, let url = panel.url {
            loadLlama(at: url.path)
        }
    }

    private func loadLlama(at path: String) {
        guard !isLoadingModel else { return }
        isLoadingModel = true
        modelLoaded = false
        modelStatus = "Loading \((path as NSString).lastPathComponent)…"
        errorMessage = nil
        let runner = self.llama
        Task {
            do {
                try await runner.load(path: path)
                await MainActor.run {
                    self.modelLoaded = true
                    self.modelStatus = "llama: \((path as NSString).lastPathComponent)"
                    self.isLoadingModel = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load model: \(error)"
                    self.modelStatus = "No model loaded"
                    self.isLoadingModel = false
                }
            }
        }
    }

    private func loadMLX(hfId: String) {
        guard !isLoadingModel else { return }
        isLoadingModel = true
        modelLoaded = false
        let id = hfId.isEmpty ? nil : hfId
        modelStatus = "Downloading \(id ?? "default")…"
        errorMessage = nil
        let runner = self.mlx
        Task {
            do {
                try await runner.load(hfId: id)
                let shown = await runner.loadedModelId ?? "mlx"
                await MainActor.run {
                    self.modelLoaded = true
                    self.modelStatus = "MLX: \(shown)"
                    self.isLoadingModel = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load MLX model: \(error)"
                    self.modelStatus = "No model loaded"
                    self.isLoadingModel = false
                }
            }
        }
    }

    // MARK: - Generate

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, modelLoaded, !isGenerating else { return }

        messages.append(ChatMessage(role: .user, text: text))
        messages.append(ChatMessage(role: .assistant, text: ""))
        let assistantIndex = messages.count - 1
        input = ""
        isGenerating = true

        let backend = self.backend

        generationTask = Task {
            do {
                let stream: AsyncThrowingStream<String, Error>
                switch backend {
                case .llama:
                    stream = await self.llama.sendUserMessage(text, maxTokens: 512)
                case .mlx:
                    stream = await self.mlx.sendUserMessage(text, maxTokens: 512)
                }
                for try await piece in stream {
                    if assistantIndex < self.messages.count {
                        self.messages[assistantIndex].text += piece
                    }
                }
            } catch is CancellationError {
                // user-initiated stop
            } catch LlamaError.cancelled {
                // user-initiated stop
            } catch MLXRunnerError.cancelled {
                // user-initiated stop
            } catch {
                self.errorMessage = "Generation error: \(error)"
            }
            self.isGenerating = false
        }
    }

    func stop() {
        let b = self.backend
        Task {
            switch b {
            case .llama: await self.llama.requestStop()
            case .mlx: await self.mlx.requestStop()
            }
        }
        generationTask?.cancel()
        generationTask = nil
    }

    func reset() {
        stop()
        messages.removeAll()
        let b = self.backend
        Task {
            switch b {
            case .llama: await self.llama.resetConversation()
            case .mlx: await self.mlx.resetConversation()
            }
        }
    }
}

struct ChatView: View {
    @Bindable var vm: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            transcript
            Divider()
            composer
        }
        .frame(minWidth: 600, minHeight: 500)
        .alert("Error",
               isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
               ),
               actions: { Button("OK") { vm.errorMessage = nil } },
               message: { Text(vm.errorMessage ?? "") })
    }

    private var header: some View {
        HStack(spacing: 12) {
            Picker("", selection: $vm.backend) {
                ForEach(Backend.allCases) { b in
                    Text(b.label).tag(b)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            .disabled(vm.isLoadingModel || vm.isGenerating)

            if vm.backend == .mlx {
                TextField("HF repo id (empty = default)", text: $vm.mlxModelId)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                    .disabled(vm.isLoadingModel || vm.isGenerating)
            }

            Button(action: { vm.loadCurrentBackend() }) {
                Label(vm.backend == .llama ? "Load Model…" : "Load",
                      systemImage: "tray.and.arrow.down")
            }
            .disabled(vm.isLoadingModel || vm.isGenerating)

            Text(vm.modelStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button("Reset") { vm.reset() }
                .disabled(vm.messages.isEmpty && !vm.isGenerating)
        }
        .padding(10)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.messages) { msg in
                        MessageRow(message: msg).id(msg.id)
                    }
                }
                .padding(12)
            }
            .onChange(of: vm.messages.last?.text) { _, _ in
                if let last = vm.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message", text: $vm.input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...6)
                .font(.body)
                .onSubmit { vm.send() }

            if vm.isGenerating {
                Button("Stop") { vm.stop() }
                    .keyboardShortcut(".", modifiers: .command)
            } else {
                Button("Send") { vm.send() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!vm.modelLoaded || vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(10)
    }
}

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(roleLabel)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
            Text(message.text.isEmpty ? "…" : message.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var roleLabel: String {
        switch message.role {
        case .user: return "user"
        case .assistant: return "assistant"
        case .system: return "system"
        }
    }
}
