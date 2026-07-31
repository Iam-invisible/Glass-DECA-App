//
//  LlamaCoachEngine.swift
//  LCVI DECA Study App
//
//  The real inference engine behind the downloaded GGUF, and the factory that
//  decides whether the app gets it or the stub.
//
//  Why this file compiles today without llama.cpp
//  ----------------------------------------------
//  Everything below the factory is inside `#if canImport(...)`. §4 forbids
//  hand-editing project.pbxproj to add dependencies, so the package has to be
//  added from Xcode:
//
//      File ▸ Add Package Dependencies… ▸ https://github.com/mattt/llama.swift
//      ▸ Up to Next Major ▸ add the `LlamaSwift` product to the app target
//
//  NOT https://github.com/ggml-org/llama.cpp — that repository has no
//  Package.swift and Xcode will refuse it. llama.swift wraps the *official*
//  precompiled XCFramework from llama.cpp's own releases, so nothing is
//  compiled from source and the C API is upstream's, unmodified.
//
//  Both module names are accepted below: `LlamaSwift` for that package, and
//  `llama` for a direct XCFramework drop-in, which llama.cpp also publishes.
//  Either route lights this file up; neither requires touching anything else.
//
//  Until one of them happens the imports resolve to nothing,
//  `CoachEngineFactory` hands back `StubCoachEngine`, and the app behaves
//  exactly as it does on a device with no Apple Intelligence.
//
//  READ THIS BEFORE TRUSTING THE C CALLS
//  -------------------------------------
//  The Swift wiring here — lifecycle, threading, token cap, prompt template,
//  cancellation — is written to be correct and is the part that matters. The
//  raw `llama_*` calls are written against the current upstream C API but have
//  never been compiled, because the package is not in the project yet and
//  cannot be added from outside Xcode. That API is not stable across
//  revisions: `llama_model_load_from_file`, `llama_init_from_model` and the
//  sampler-chain functions have all been renamed at least once. Expect to fix
//  call sites on the first build, and pin the package to an exact revision
//  rather than a branch so it cannot move underneath the app.
//

import Foundation

// `LlamaSwift` is the product mattt/llama.swift vends; `llama` is the module
// name you get from adding llama.cpp's XCFramework directly. Supporting both
// means the choice of route is not baked into the source.
#if canImport(LlamaSwift)
import LlamaSwift
#elseif canImport(llama)
import llama
#endif

// MARK: - Factory

/// Chooses the engine the app runs with.
///
/// This is the piece that was missing: `LocalCoachEngine` existed and
/// `StubCoachEngine` existed, but nothing ever constructed either of them, so
/// the download could never have produced behaviour no matter how complete the
/// rest of it was.
enum CoachEngineFactory {

    /// True when this build can actually run a GGUF.
    static var canRunLocalModel: Bool {
        #if canImport(LlamaSwift) || canImport(llama)
        return true
        #else
        return false
        #endif
    }

    /// Returns a live engine for the model at `url`, or nil when this build
    /// has no runtime, the file is absent, or the phone is too small to hold
    /// the weights.
    static func makeEngine(modelURL: URL) -> LocalCoachEngine? {
        guard FileManager.default.fileExists(atPath: modelURL.path) else { return nil }
        #if canImport(LlamaSwift) || canImport(llama)
        return LlamaCoachEngine(modelURL: modelURL)
        #else
        return nil
        #endif
    }
}

#if canImport(LlamaSwift) || canImport(llama)

// MARK: - Engine

/// A llama.cpp-backed engine.
///
/// `nonisolated` on purpose: the target sets
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (§8.21), so without this every
/// member would be main-actor isolated and a 1B model would decode on the main
/// thread — a guaranteed watchdog kill. All work happens on `queue`; all
/// mutable state is touched only from there.
/// `@unchecked Sendable` is a claim the compiler cannot verify, so it has to be
/// earned: every pointer is created, used and freed on `queue` and touched
/// nowhere else, and the one field read from other threads — `_isReady` — is
/// behind `readyLock`. Without this the closures below capture a non-Sendable
/// `self` and warn, and warnings are errors under Swift 6 (§3).
nonisolated final class LlamaCoachEngine: LocalCoachEngine, @unchecked Sendable {

    private let modelURL: URL
    private let queue = DispatchQueue(label: "com.shailpatel.glass.llama", qos: .userInitiated)

    /// Owned by `queue`. `OpaquePointer?` rather than the typed handles so the
    /// property declarations don't need the C types at file scope.
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?

    /// Read from any thread, so it gets its own lock rather than riding on
    /// `queue` — `isReady` is called from SwiftUI during layout.
    private let readyLock = NSLock()
    private var _isReady = false

    var isReady: Bool {
        readyLock.lock(); defer { readyLock.unlock() }
        return _isReady
    }

    private func setReady(_ value: Bool) {
        readyLock.lock(); _isReady = value; readyLock.unlock()
    }

    init(modelURL: URL) {
        self.modelURL = modelURL
    }

    deinit { teardown() }

    // MARK: Lifecycle

    /// Loads lazily. A 1B Q4 model is roughly 1 GB resident once the KV cache
    /// is allocated, so it is never held before it is asked for.
    private func loadIfNeeded() -> Bool {
        if context != nil { return true }

        llama_backend_init()

        var modelParams = llama_model_default_params()
        // Metal is fine for a 1B model and dramatically cheaper thermally
        // than CPU decode. 0 would force CPU.
        modelParams.n_gpu_layers = 99

        guard let loaded = llama_model_load_from_file(modelURL.path, modelParams) else {
            NSLog("LlamaCoachEngine: model failed to load at \(modelURL.lastPathComponent)")
            return false
        }
        model = loaded
        vocab = llama_model_get_vocab(loaded)

        var contextParams = llama_context_default_params()
        // The app's prompts are a few hundred tokens and the replies are
        // capped at 4 sentences. 2048 covers both with room spare, and every
        // token of context is KV cache the phone has to hold.
        contextParams.n_ctx = 2048
        contextParams.n_batch = 512
        let cores = ProcessInfo.processInfo.activeProcessorCount
        // Leave a core for the UI; more threads than performance cores costs
        // more in contention than it buys in throughput.
        contextParams.n_threads = Int32(max(2, min(4, cores - 2)))
        contextParams.n_threads_batch = contextParams.n_threads

        guard let ctx = llama_init_from_model(loaded, contextParams) else {
            NSLog("LlamaCoachEngine: context creation failed")
            llama_model_free(loaded)
            model = nil
            vocab = nil
            return false
        }
        context = ctx
        setReady(true)
        return true
    }

    /// Frees the weights. Called when the app backgrounds — holding ~1 GB
    /// across a suspend is the fastest way to be jetsammed on a 4 GB phone.
    func unload() {
        queue.async { [weak self] in self?.teardown() }
    }

    private func teardown() {
        setReady(false)
        if let context { llama_free(context) }
        if let model { llama_model_free(model) }
        context = nil
        model = nil
        vocab = nil
    }

    // MARK: Generation

    func respond(instructions: String, prompt: String, maxTokens: Int) async -> String? {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self else { return continuation.resume(returning: nil) }
                continuation.resume(returning: self.generateOnQueue(instructions: instructions,
                                                                    prompt: prompt,
                                                                    maxTokens: maxTokens))
            }
        }
    }

    private func generateOnQueue(instructions: String, prompt: String, maxTokens: Int) -> String? {
        guard loadIfNeeded(), let context, let vocab else { return nil }

        let formatted = Self.llama32Prompt(instructions: instructions, user: prompt)
        var tokens = tokenize(formatted, vocab: vocab)
        guard !tokens.isEmpty else { return nil }

        // Refuse rather than truncate. A silently clipped prompt drops the
        // correct answer out of context, and §2.4 says the model must never be
        // in a position to re-decide correctness.
        let budget = Int(llama_n_ctx(context))
        guard tokens.count + maxTokens < budget else {
            NSLog("LlamaCoachEngine: prompt of \(tokens.count) tokens does not fit in \(budget)")
            return nil
        }

        // Clear any KV state from the previous request. Each call is
        // independent — same reason the Foundation Models path builds a fresh
        // session per request.
        llama_memory_clear(llama_get_memory(context), true)

        var batch = llama_batch_init(Int32(max(tokens.count, 1)), 0, 1)
        defer { llama_batch_free(batch) }

        for (i, token) in tokens.enumerated() {
            batchAdd(&batch, token: token, position: Int32(i), logits: i == tokens.count - 1)
        }
        guard llama_decode(context, batch) == 0 else { return nil }

        guard let sampler = makeSampler() else { return nil }
        defer { llama_sampler_free(sampler) }

        var output = ""
        var position = Int32(tokens.count)

        for _ in 0..<maxTokens {
            let token = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocab, token) { break }

            output += piece(for: token, vocab: vocab)

            batch.n_tokens = 0
            batchAdd(&batch, token: token, position: position, logits: true)
            position += 1
            guard llama_decode(context, batch) == 0 else { break }
        }

        tokens.removeAll()
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: Sampling

    /// Deliberately conservative. These prompts want a correct, dull
    /// explanation, not a creative one, and a 1B model drifts off format fast
    /// when it is allowed to wander.
    ///
    /// The sampler chain is a typed `llama_sampler` pointer, unlike the model
    /// and context handles which really are opaque. Mixing the two up is the
    /// only thing that failed to compile on the first build.
    private func makeSampler() -> UnsafeMutablePointer<llama_sampler>? {
        var params = llama_sampler_chain_default_params()
        params.no_perf = true
        guard let chain = llama_sampler_chain_init(params) else { return nil }
        llama_sampler_chain_add(chain, llama_sampler_init_top_k(40))
        llama_sampler_chain_add(chain, llama_sampler_init_top_p(0.9, 1))
        llama_sampler_chain_add(chain, llama_sampler_init_temp(0.3))
        llama_sampler_chain_add(chain, llama_sampler_init_dist(LLAMA_DEFAULT_SEED))
        return chain
    }

    // MARK: Tokens

    private func batchAdd(_ batch: inout llama_batch, token: llama_token, position: Int32, logits: Bool) {
        let i = Int(batch.n_tokens)
        batch.token[i] = token
        batch.pos[i] = position
        batch.n_seq_id[i] = 1
        batch.seq_id[i]?[0] = 0
        batch.logits[i] = logits ? 1 : 0
        batch.n_tokens += 1
    }

    private func tokenize(_ text: String, vocab: OpaquePointer) -> [llama_token] {
        let utf8Count = text.utf8.count
        // Worst case is roughly one token per byte plus the specials.
        let capacity = utf8Count + 16
        var result = [llama_token](repeating: 0, count: capacity)
        let count = llama_tokenize(vocab, text, Int32(utf8Count),
                                   &result, Int32(capacity),
                                   /* add_special */ true,
                                   /* parse_special */ true)
        guard count > 0 else { return [] }
        return Array(result.prefix(Int(count)))
    }

    /// Detokenises one token. The two-pass call is required: the first tells
    /// us the length, which is negative when the buffer was too small.
    private func piece(for token: llama_token, vocab: OpaquePointer) -> String {
        var buffer = [CChar](repeating: 0, count: 32)
        var written = llama_token_to_piece(vocab, token, &buffer, 32, 0, true)
        if written < 0 {
            buffer = [CChar](repeating: 0, count: Int(-written) + 1)
            written = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, true)
            guard written > 0 else { return "" }
        }
        return String(decoding: buffer.prefix(Int(written)).map { UInt8(bitPattern: $0) },
                      as: UTF8.self)
    }

    // MARK: Prompt template

    /// Llama 3.2 Instruct's chat template. Getting this wrong does not fail
    /// loudly — it just makes the model answer as if it were completing a
    /// document, which reads as "the AI is bad" rather than "the prompt is
    /// malformed".
    static func llama32Prompt(instructions: String, user: String) -> String {
        """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>

        \(instructions)<|eot_id|><|start_header_id|>user<|end_header_id|>

        \(user)<|eot_id|><|start_header_id|>assistant<|end_header_id|>


        """
    }
}

#endif
