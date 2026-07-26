//
//  FoundationModelFeedbackService.swift
//  LCVI DECA Study App
//
//  Optional, on-device AI coaching through Apple's Foundation Models framework.
//
//  Rules this file enforces:
//   • The app never requires AI. Every entry point returns nil on failure and
//     the caller falls back to stored explanations or a manual rubric.
//   • The model NEVER decides which answer is correct. The correct answer is
//     always supplied from the local question bank and the model is instructed
//     to treat it as fact.
//   • Nothing leaves the device. No network calls, no bundled model files —
//     only Apple's system-managed local model.
//

import Combine
import Foundation
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Availability

enum AIAvailability: Equatable {
    case available
    case appleIntelligenceNotEnabled
    case deviceNotSupported
    case modelDownloading
    case temporarilyUnavailable

    var title: String {
        switch self {
        case .available:                  return "AI Feedback Available"
        case .appleIntelligenceNotEnabled: return "Apple Intelligence Not Enabled"
        case .deviceNotSupported:         return "This Device Does Not Support AI Feedback"
        case .modelDownloading:           return "Local Model Still Downloading"
        case .temporarilyUnavailable:     return "AI Feedback Temporarily Unavailable"
        }
    }

    var detail: String {
        switch self {
        case .available:
            return "Explanations and roleplay coaching run entirely on this device using Apple's on-device model. Nothing is sent to a server."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings ▸ Apple Intelligence & Siri to enable AI coaching. Everything else in this app keeps working."
        case .deviceNotSupported:
            return "This device can't run Apple's on-device model. Practice, mock exams, roleplays and progress tracking all work offline as normal, with written explanations and a manual rubric."
        case .modelDownloading:
            return "Apple is still downloading the on-device model. AI coaching will switch on automatically once it finishes."
        case .temporarilyUnavailable:
            return "AI coaching can't run right now — this is usually temporary. The rest of the app is unaffected."
        }
    }

    var symbol: String {
        switch self {
        case .available:                   return "checkmark.seal.fill"
        case .appleIntelligenceNotEnabled: return "switch.2"
        case .deviceNotSupported:          return "iphone.slash"
        case .modelDownloading:            return "arrow.down.circle"
        case .temporarilyUnavailable:      return "exclamationmark.triangle"
        }
    }

    var tint: Color {
        switch self {
        case .available:        return Palette.success
        case .modelDownloading: return Palette.accent
        case .deviceNotSupported, .appleIntelligenceNotEnabled: return Palette.textSecondary
        case .temporarilyUnavailable: return Palette.gold
        }
    }

    var isUsable: Bool { self == .available }
}

// MARK: - Feedback shapes

struct QuickThinkFeedback: Equatable {
    var strongest: String
    var weakest: String
    var conceptUsedWell: String
    var conceptMissing: String
    var moreProfessional: String
    var strongerAnswer: String

    static func manual(scenario: QuickThinkScenario, response: String) -> QuickThinkFeedback {
        let words = response.split(whereSeparator: { $0.isWhitespace }).count
        let lengthNote = words < 30
            ? "Your answer is short — judges expect you to state a recommendation and support it with reasoning."
            : "You gave a full answer; make sure every sentence adds something a judge can score."
        return QuickThinkFeedback(
            strongest: "You responded to the scenario and committed to a position — that is what judges want first.",
            weakest: lengthNote,
            conceptUsedWell: "Focus area: \(scenario.focus).",
            conceptMissing: "Check whether you named a specific business concept, a measurable outcome, and a next step.",
            moreProfessional: "Open with \"My recommendation is…\" and close with \"…because it improves…\".",
            strongerAnswer: "Structure to aim for: 1) restate the problem, 2) give your recommendation, 3) give two supporting reasons tied to business concepts, 4) state how you would measure success."
        )
    }
}

struct RoleplayAIFeedback: Equatable {
    var wentWell: String
    var couldImprove: String
    var missingConcepts: String
    var strongerPhrasing: String
    var suggestedStructure: String
    var sampleAnswer: String
    var estimatedScores: [RubricCategory: Int]
}

// MARK: - Service

@MainActor
final class FoundationModelFeedbackService: ObservableObject {

    @Published private(set) var availability: AIAvailability = .deviceNotSupported
    @Published private(set) var isGenerating = false

    /// Master switch from Settings. When off, the service behaves as if AI is
    /// unavailable without changing the reported hardware status.
    var userEnabled: Bool = true

    var isUsable: Bool { userEnabled && availability.isUsable }

    #if canImport(FoundationModels)
    /// Held as `Any` so the property itself doesn't need an availability guard.
    private var sessionBox: Any?
    #endif

    init() {
        refreshAvailability()
    }

    // MARK: Availability

    func refreshAvailability() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                availability = .available
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    availability = .deviceNotSupported
                case .appleIntelligenceNotEnabled:
                    availability = .appleIntelligenceNotEnabled
                case .modelNotReady:
                    availability = .modelDownloading
                @unknown default:
                    availability = .temporarilyUnavailable
                }
            @unknown default:
                availability = .temporarilyUnavailable
            }
            return
        }
        #endif
        // iOS 16–25, or a build without the framework: no on-device model.
        availability = .deviceNotSupported
    }

    /// Warms the model so the first explanation feels instant.
    func prewarm() {
        #if canImport(FoundationModels)
        guard isUsable, #available(iOS 26.0, *) else { return }
        session()?.prewarm()
        #endif
    }

    // MARK: Session

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func session() -> LanguageModelSession? {
        if let existing = sessionBox as? LanguageModelSession { return existing }
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let created = LanguageModelSession(instructions: Self.systemInstructions)
        sessionBox = created
        return created
    }

    /// A fresh session per request keeps unrelated feedback from bleeding into
    /// the next answer, and keeps the transcript from growing unbounded.
    @available(iOS 26.0, *)
    private func freshSession() -> LanguageModelSession? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        return LanguageModelSession(instructions: Self.systemInstructions)
    }
    #endif

    private static let systemInstructions = """
    You are a DECA coach helping a Canadian high-school student prepare for DECA Ontario \
    competition. You explain business reasoning clearly and briefly.

    Rules you must follow:
    - The correct answer to any multiple-choice question is given to you as fact. Never \
    contradict it, never re-decide it, and never say a different option is correct.
    - Address the student directly as "you". Never write "the student" or refer to them in the third person.
    - Use plain, professional language a Grade 10-12 student understands.
    - Be concise. Never exceed the requested length.
    - Connect every explanation to a business concept or performance indicator.
    - Do not invent statistics, sources or official DECA rules.
    - Never use markdown headings, bullets or asterisks unless explicitly asked for a list.
    """

    // MARK: - Core generation

    /// Runs a prompt against the on-device model. Returns nil on any failure so
    /// callers can fall back silently.
    private func generate(_ prompt: String) async -> String? {
        guard isUsable else { return nil }
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return nil }
        guard let session = freshSession() else { return nil }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let response = try await session.respond(to: prompt)
            let text = Self.sanitize(response.content)
            return text.isEmpty ? nil : text
        } catch {
            NSLog("FoundationModels generation failed: \(error.localizedDescription)")
            // A failure here is almost always transient (guardrails, context
            // limit, model busy). Surface it as temporarily unavailable but
            // leave the reported hardware capability alone.
            refreshAvailability()
            return nil
        }
        #else
        return nil
        #endif
    }

    /// The model still reaches for markdown emphasis now and then. Strip it so
    /// feedback renders as clean prose instead of stray asterisks.
    static func sanitize(_ raw: String) -> String {
        let stripped = raw
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            // The model occasionally narrates in the third person despite the
            // instructions; feedback reads much better addressed to the student.
            .replacingOccurrences(of: "The student's", with: "Your")
            .replacingOccurrences(of: "the student's", with: "your")
            .replacingOccurrences(of: "The student ", with: "You ")
            .replacingOccurrences(of: "the student ", with: "you ")

        var lines: [String] = []
        for rawLine in stripped.components(separatedBy: .newlines) {
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            while line.hasPrefix("#") { line.removeFirst() }
            if line.hasPrefix("* ") || line.hasPrefix("- ") { line.removeFirst(2) }
            line = line.trimmingCharacters(in: .whitespaces)

            // Drop lines that were nothing but leftover decoration.
            if !line.isEmpty, line.allSatisfy({ "*_-#".contains($0) }) { continue }

            if line.isEmpty {
                if lines.last?.isEmpty == false { lines.append("") }
            } else {
                lines.append(line)
            }
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Question explanations

    /// Explains why the chosen answer is wrong and why the bank's answer is better.
    func explainAnswer(question: QuestionData, selectedIndex: Int) async -> String? {
        let letters = ["A", "B", "C", "D"]
        let choices = question.choices.enumerated()
            .map { "\(letters[$0.offset])) \($0.element)" }
            .joined(separator: "\n")

        let indicatorLine = question.performanceIndicators.isEmpty
            ? ""
            : "\nRelated performance indicator(s): " + question.performanceIndicators
                .map { code in SeedIndicators.text(forCode: code).map { "\(code) — \($0)" } ?? code }
                .joined(separator: "; ")

        let storedLine = question.explanation.isEmpty
            ? ""
            : "\nThe study bank's explanation: \(question.explanation)"

        let wasCorrect = selectedIndex == question.correctIndex
        let selectedLine = question.choices.indices.contains(selectedIndex)
            ? "You chose \(letters[selectedIndex])) \(question.choices[selectedIndex])."
            : "You did not answer."

        let task = wasCorrect
            ? """
              You answered correctly. In at most 3 sentences, speaking directly to the student as \
              "you", reinforce WHY \(letters[question.correctIndex]) is the best answer and name the \
              business concept behind it. Then add one sentence on a trap to avoid on similar questions.
              """
            : """
              In at most 4 sentences, speaking directly to the student as "you": first explain \
              specifically why your choice is wrong, then explain why \(letters[question.correctIndex]) \
              is the better business answer, and finish with one short tip for recognising this on the exam.
              """

        let prompt = """
        Cluster: \(question.cluster.displayName)
        Question: \(question.text)
        \(choices)

        FACT — the correct answer is \(letters[question.correctIndex])) \(question.choices[question.correctIndex]). \
        Treat this as absolutely correct.
        \(selectedLine)\(indicatorLine)\(storedLine)

        \(task)
        Write flowing prose with no headings or bullets.
        """
        return await generate(prompt)
    }

    /// Study advice based on the student's weakest areas.
    func studyAdvice(cluster: DECACluster,
                     weakIndicators: [IndicatorStat],
                     weakTopics: [String],
                     accuracy: Double) async -> String? {
        let indicatorLines = weakIndicators.isEmpty
            ? "None recorded yet."
            : weakIndicators.map { "\($0.code) — \($0.text) (\(Int($0.accuracy * 100))% accurate over \($0.timesAnswered) questions)" }
                .joined(separator: "\n")
        let topicLine = weakTopics.isEmpty ? "None recorded yet." : weakTopics.joined(separator: ", ")

        let prompt = """
        A student is preparing for the \(cluster.examName).
        Overall accuracy so far: \(Int(accuracy * 100))%.

        Weakest performance indicators:
        \(indicatorLines)

        Weakest topics: \(topicLine)

        Write a focused study plan of at most 5 short sentences. Say specifically what to review \
        and in what order, and name one concrete practice activity. Do not use bullets or headings.
        """
        return await generate(prompt)
    }

    // MARK: - Roleplay

    func roleplayTips(prompt promptData: RoleplayPromptData) async -> String? {
        let pis = promptData.performanceIndicators
            .map { code in SeedIndicators.text(forCode: code).map { "\(code) — \($0)" } ?? code }
            .joined(separator: "; ")

        let prompt = """
        DECA roleplay scenario (\(promptData.cluster.displayName)):
        \(promptData.situation)

        Student's role: \(promptData.userRole)
        Judge's role: \(promptData.judgeRole)
        Performance indicators to hit: \(pis)

        In at most 5 short sentences, give the student preparation tips: what to structure their \
        \(promptData.presentMinutes)-minute presentation around, which indicator to lead with, and one \
        thing judges reward that students usually forget. No bullets, no headings.
        """
        return await generate(prompt)
    }

    /// Full rubric-based coaching on a typed roleplay response.
    func analyzeRoleplay(prompt promptData: RoleplayPromptData,
                         response: String,
                         notes: String) async -> RoleplayAIFeedback? {
        let pis = promptData.performanceIndicators
            .map { code in SeedIndicators.text(forCode: code).map { "\(code) — \($0)" } ?? code }
            .joined(separator: "; ")

        let notesBlock = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "" : "\n\nThe student's prep notes:\n\(notes)"

        let prompt = """
        DECA roleplay scenario (\(promptData.cluster.displayName)):
        \(promptData.situation)

        Student's role: \(promptData.userRole)
        Judge's role: \(promptData.judgeRole)
        Performance indicators being judged: \(pis)

        The student's presentation (address them directly as "you" in your feedback):
        \(response)\(notesBlock)

        Act as the judge. Reply using EXACTLY these labels, each on its own line, each followed by \
        one or two sentences and nothing else:

        WENT WELL:
        IMPROVE:
        MISSING:
        PHRASING:
        STRUCTURE:
        SAMPLE:
        SCORES:

        For SCORES, output exactly eight integers from 1 to 5 separated by commas, in this order: \
        understanding, indicators, professionalism, creativity, clarity, persuasiveness, \
        practicality, reasoning. Output only the numbers on that line.
        For SAMPLE, write two to three sentences of a stronger opening the student could actually say.
        """

        guard let raw = await generate(prompt) else { return nil }
        return Self.parseRoleplayFeedback(raw)
    }

    static func parseRoleplayFeedback(_ raw: String) -> RoleplayAIFeedback {
        func section(_ label: String) -> String {
            let labels = ["WENT WELL:", "IMPROVE:", "MISSING:", "PHRASING:", "STRUCTURE:", "SAMPLE:", "SCORES:"]
            guard let start = raw.range(of: label) else { return "" }
            var end = raw.endIndex
            for other in labels where other != label {
                if let r = raw.range(of: other, range: start.upperBound..<raw.endIndex), r.lowerBound < end {
                    end = r.lowerBound
                }
            }
            return String(raw[start.upperBound..<end])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var scores: [RubricCategory: Int] = [:]
        let scoreText = section("SCORES:")
        let numbers = scoreText
            .components(separatedBy: CharacterSet(charactersIn: ", \n"))
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { (1...5).contains($0) }
        if numbers.count >= RubricCategory.allCases.count {
            for (index, category) in RubricCategory.allCases.enumerated() {
                scores[category] = numbers[index]
            }
        }

        return RoleplayAIFeedback(
            wentWell: section("WENT WELL:"),
            couldImprove: section("IMPROVE:"),
            missingConcepts: section("MISSING:"),
            strongerPhrasing: section("PHRASING:"),
            suggestedStructure: section("STRUCTURE:"),
            sampleAnswer: section("SAMPLE:"),
            estimatedScores: scores
        )
    }

    // MARK: - Quick Think

    func improveQuickThink(scenario: QuickThinkScenario, response: String) async -> QuickThinkFeedback? {
        let prompt = """
        Quick-thinking business drill (\(scenario.cluster.displayName), focus: \(scenario.focus)).

        Scenario: \(scenario.prompt)

        The student's spoken-style answer (address them directly as "you" in your feedback):
        \(response)

        Reply using EXACTLY these labels, each on its own line, each followed by one sentence only \
        except SAMPLE which may use three:

        STRONGEST:
        WEAKEST:
        CONCEPT USED:
        CONCEPT MISSING:
        REPHRASE:
        SAMPLE:

        REPHRASE must quote one sentence from the student's answer and rewrite it more professionally.
        SAMPLE must be a stronger version of the whole answer the student could say in 45 seconds.
        """

        guard let raw = await generate(prompt) else { return nil }

        func section(_ label: String) -> String {
            let labels = ["STRONGEST:", "WEAKEST:", "CONCEPT USED:", "CONCEPT MISSING:", "REPHRASE:", "SAMPLE:"]
            guard let start = raw.range(of: label) else { return "" }
            var end = raw.endIndex
            for other in labels where other != label {
                if let r = raw.range(of: other, range: start.upperBound..<raw.endIndex), r.lowerBound < end {
                    end = r.lowerBound
                }
            }
            return String(raw[start.upperBound..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let feedback = QuickThinkFeedback(
            strongest: section("STRONGEST:"),
            weakest: section("WEAKEST:"),
            conceptUsedWell: section("CONCEPT USED:"),
            conceptMissing: section("CONCEPT MISSING:"),
            moreProfessional: section("REPHRASE:"),
            strongerAnswer: section("SAMPLE:")
        )
        // If parsing produced nothing usable, treat it as a failure.
        return feedback.strongest.isEmpty && feedback.strongerAnswer.isEmpty ? nil : feedback
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
extension SystemLanguageModel {
    var isAvailable: Bool {
        if case .available = availability { return true }
        return false
    }
}
#endif
