//
//  LocalCoachEngine.swift
//  LCVI DECA Study App
//
//  The inference seam for the downloaded local model.
//
//  What is and isn't wired up
//  --------------------------
//  Everything around inference is finished: the model is offered, downloaded
//  over Wi-Fi only, checksummed, installed and manageable. What runs it is
//  not, and cannot be added from outside Xcode — a GGUF runtime means adding
//  llama.cpp as a Swift package, and §4 forbids hand-editing project.pbxproj
//  to add dependencies. That is a two-minute step in Xcode:
//
//      File ▸ Add Package Dependencies… ▸ https://github.com/ggml-org/llama.cpp
//      add the `llama` library to the "LCVI DECA Study App" target,
//      then replace `StubCoachEngine` below with a real implementation.
//
//  Until then this returns nil for everything, which is a supported state
//  rather than a broken one: `FoundationModelFeedbackService` already treats
//  nil as "no AI available" and falls through to the written `manual()`
//  feedback, exactly as it does on a device with no Apple Intelligence.
//
//  Notes for whoever writes the real one
//  -------------------------------------
//  - Load lazily and unload on background. Holding ~1 GB across a suspend is
//    the fastest way to be jetsammed on a 4 GB phone.
//  - Cap generation hard. These prompts want 3-4 sentences; an unbounded
//    generation on an A13 is a thermal problem, not a quality one.
//  - `analyzeRoleplay` is the fragile prompt: `parseRoleplayFeedback` splits
//    on section labels and a 1B model drifts off that format far more than
//    Apple's does. Use llama.cpp's GBNF grammar support to make the sections
//    structurally guaranteed instead of hoped for.
//  - The correct answer always arrives in the prompt as fact (§2.4). Nothing
//    here may ever decide correctness.
//

import Foundation

/// Anything that can turn one of the app's prompts into prose on-device.
protocol LocalCoachEngine: AnyObject {
    /// True when a model is loaded, or could be loaded on demand.
    var isReady: Bool { get }

    /// Returns nil on any failure, which the caller treats as "no AI".
    func respond(instructions: String, prompt: String, maxTokens: Int) async -> String?

    /// Called when the app leaves the foreground so the weights can be freed.
    func unload()
}

/// The placeholder engine. Reports not-ready and generates nothing, so the
/// app behaves exactly as it does on a device without Apple Intelligence.
final class StubCoachEngine: LocalCoachEngine {
    var isReady: Bool { false }

    func respond(instructions: String, prompt: String, maxTokens: Int) async -> String? {
        nil
    }

    func unload() {}
}
