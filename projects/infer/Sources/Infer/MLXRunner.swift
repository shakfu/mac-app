import Foundation
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers

enum MLXRunnerError: Error {
    case notLoaded
    case busy
    case cancelled
}

actor MLXRunner {
    private var container: ModelContainer?
    private var session: ChatSession?
    private var modelId: String?
    private var isGenerating = false

    private var activeTask: Task<Void, Never>?

    init() {}

    var loadedModelId: String? { modelId }

    /// Load a model from a Hugging Face repository id. Pass `nil` to use the
    /// registry default (gemma3_1B qat 4bit). Downloads on first use.
    func load(hfId: String? = nil) async throws {
        session = nil
        container = nil
        modelId = nil

        let configuration: ModelConfiguration
        if let hfId {
            configuration = ModelConfiguration(id: hfId)
        } else {
            configuration = LLMRegistry.gemma3_1B_qat_4bit
        }

        let loaded = try await #huggingFaceLoadModelContainer(configuration: configuration)
        self.container = loaded
        self.session = ChatSession(loaded)
        self.modelId = configuration.name
    }

    func sendUserMessage(_ text: String, maxTokens _: Int = 512) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard !isGenerating else {
                continuation.finish(throwing: MLXRunnerError.busy)
                return
            }
            guard let session else {
                continuation.finish(throwing: MLXRunnerError.notLoaded)
                return
            }

            isGenerating = true
            let task = Task {
                defer { Task { self.finishGeneration() } }
                do {
                    for try await piece in session.streamResponse(to: text) {
                        if Task.isCancelled {
                            continuation.finish(throwing: MLXRunnerError.cancelled)
                            return
                        }
                        continuation.yield(piece)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: MLXRunnerError.cancelled)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            activeTask = task
        }
    }

    private func finishGeneration() {
        isGenerating = false
        activeTask = nil
    }

    func requestStop() {
        activeTask?.cancel()
    }

    func resetConversation() async {
        if let container {
            session = ChatSession(container)
        }
    }

    func shutdown() {
        activeTask?.cancel()
        activeTask = nil
        session = nil
        container = nil
        modelId = nil
        isGenerating = false
    }
}
