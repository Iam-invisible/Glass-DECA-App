//
//  InputSanitizer.swift
//  LCVI DECA Study App
//
//  Normalising everything a person can type or import before it is stored,
//  and again before any of it reaches a language model.
//
//  Where untrusted content actually comes from
//  ------------------------------------------
//  There is no server and no account, so "untrusted" does not mean an attacker
//  — it means content the app did not author. Three sources qualify:
//
//   1. The question bank manager, where a student types their own items.
//   2. A restored backup or an imported bank, which may have been produced by
//      someone else entirely and passed around a class.
//   3. Roleplay transcripts and Quick Think answers.
//
//  All three end up in Core Data, on screen, and — once AI is available — in a
//  model prompt. The bank is the one that bites: a question with a
//  `correctIndex` of 9, or three choices instead of four, is accepted happily
//  by JSONDecoder and then indexes straight out of bounds when the explanation
//  prompt is built.
//
//  The rule this file enforces is that a `QuestionData` reaching storage is
//  structurally impossible to crash on: exactly four choices, a `correctIndex`
//  inside them, and every string trimmed, stripped of control characters and
//  length-capped.
//

import Foundation

// MARK: - Limits

/// Ceilings on stored text. Generous enough that no honest entry hits them,
/// low enough that a pathological import cannot exhaust memory, stall the UI
/// or blow a model's context window.
enum InputLimits {
    static let questionText = 2_000
    static let choice = 600
    static let explanation = 4_000
    static let rationale = 1_200
    static let tag = 40
    static let tagCount = 12
    static let indicatorCode = 24
    static let indicatorCount = 12
    static let examType = 120

    /// Roleplay transcripts and Quick Think answers, which are the longest
    /// things a student produces in one go.
    static let freeResponse = 12_000

    /// What any single field is allowed to contribute to a model prompt.
    static let promptField = 4_000
}

// MARK: - Strings

extension String {

    /// Trimmed, stripped of control characters, and capped.
    ///
    /// Control characters are removed rather than escaped because nothing in
    /// this app renders anything but plain text — they cannot be displayed,
    /// and inside a prompt they are only useful for disguising content.
    /// Tab and newline survive, since typed answers legitimately contain them.
    func sanitized(maxLength: Int) -> String {
        let cleaned = String(unicodeScalars.filter { scalar in
            scalar == "\n" || scalar == "\t"
                || (!CharacterSet.controlCharacters.contains(scalar)
                    && !scalar.properties.isDefaultIgnorableCodePoint)
        })
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else { return trimmed }
        return String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    /// Prepared for interpolation into a model prompt.
    ///
    /// The app's real protection against a crafted question is architectural:
    /// §2.4 means the correct answer always comes from the bank and the model
    /// is never asked to decide it, so the worst a hostile item can do is make
    /// the coaching strange rather than wrong.
    ///
    /// What this adds is removing the two things that actually help an
    /// injection land — long runs of blank lines, used to fake the end of one
    /// prompt section and the start of another, and the triple backticks that
    /// would close a fence early.
    func promptSafe(maxLength: Int = InputLimits.promptField) -> String {
        var text = sanitized(maxLength: maxLength)
        text = text.replacingOccurrences(of: "```", with: "'''")
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return text
    }
}

// MARK: - Questions

extension QuestionData {

    /// True when this can be displayed and answered without special-casing.
    ///
    /// Deliberately narrow: it asks only what the rest of the app assumes,
    /// which is four choices and a correct answer among them.
    var isStructurallyValid: Bool {
        choices.count == 4
            && choices.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && (0..<4).contains(correctIndex)
            && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// A copy that cannot crash a view or a prompt builder.
    ///
    /// Choices are padded or truncated to exactly four, because every screen
    /// and both index accesses in the AI prompt assume that. `correctIndex` is
    /// clamped rather than rejected — an out-of-range value in an imported
    /// bank is far more likely to be an off-by-one in whatever produced the
    /// file than a deliberate attack, and dropping the question loses a
    /// student their content.
    func sanitized() -> QuestionData {
        var copy = self

        copy.text = text.sanitized(maxLength: InputLimits.questionText)
        copy.explanation = explanation.sanitized(maxLength: InputLimits.explanation)
        copy.examType = examType.sanitized(maxLength: InputLimits.examType)

        var fixedChoices = choices
            .prefix(4)
            .map { $0.sanitized(maxLength: InputLimits.choice) }
        while fixedChoices.count < 4 { fixedChoices.append("—") }
        copy.choices = fixedChoices.map { $0.isEmpty ? "—" : $0 }

        copy.correctIndex = min(max(correctIndex, 0), 3)

        // Rationales are optional, so an odd count is normalised to either
        // none at all or exactly four — never a partial array that would make
        // `rationale(for:)` answer for some choices and not others.
        if choiceRationales.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            var fixed = choiceRationales
                .prefix(4)
                .map { $0.sanitized(maxLength: InputLimits.rationale) }
            while fixed.count < 4 { fixed.append("") }
            copy.choiceRationales = fixed
        } else {
            copy.choiceRationales = []
        }

        copy.tags = tags
            .prefix(InputLimits.tagCount)
            .map { $0.sanitized(maxLength: InputLimits.tag) }
            .filter { !$0.isEmpty }

        copy.performanceIndicators = performanceIndicators
            .prefix(InputLimits.indicatorCount)
            .map { $0.sanitized(maxLength: InputLimits.indicatorCode) }
            .filter { !$0.isEmpty }

        return copy
    }
}
