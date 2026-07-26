//
//  PracticeRunner.swift
//  LCVI DECA Study App
//
//  Drives a single practice session: selection, reveal, scoring and timing.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class PracticeRunner: ObservableObject {
    struct AnswerLog {
        let question: QuestionData
        let selectedIndex: Int
        let isCorrect: Bool
    }

    let questions: [QuestionData]
    let mode: PracticeMode
    let cluster: DECACluster?
    let composition: [String]
    let timeLimit: TimeInterval?

    @Published private(set) var index = 0
    @Published var selected: Int?
    @Published private(set) var revealed = false
    @Published private(set) var correctCount = 0
    @Published private(set) var finished = false
    @Published private(set) var log: [AnswerLog] = []

    @Published var aiExplanation: String?
    @Published var isLoadingAI = false
    @Published var aiFailed = false

    @Published private(set) var secondsRemaining: TimeInterval = 0

    private(set) var sessionID: UUID?
    private var questionStart = Date()
    private var sessionStart = Date()
    private var ticker: AnyCancellable?

    init(session: BuiltSession, timeLimit: TimeInterval? = nil) {
        self.questions = session.questions
        self.mode = session.mode
        self.cluster = session.cluster
        self.composition = session.composition
        self.timeLimit = timeLimit
        self.secondsRemaining = timeLimit ?? 0
    }

    // MARK: Derived

    var current: QuestionData? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    var progress: Double {
        questions.isEmpty ? 0 : Double(index) / Double(questions.count)
    }

    var isLastQuestion: Bool { index >= questions.count - 1 }

    var elapsed: TimeInterval { Date().timeIntervalSince(sessionStart) }

    var accuracy: Double {
        log.isEmpty ? 0 : Double(correctCount) / Double(log.count)
    }

    var timeDisplay: String {
        let value = max(0, Int(secondsRemaining.rounded()))
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    var isTimeCritical: Bool { timeLimit != nil && secondsRemaining <= 30 }

    // MARK: Lifecycle

    func start(store: AppStore) {
        sessionID = store.sessions.createSession(mode: mode, cluster: cluster)
        sessionStart = Date()
        questionStart = Date()
        Haptics.prepare()
        SoundEffects.prepare()
        store.ai.prewarm()

        if timeLimit != nil {
            ticker = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.tickClock() }
        }
    }

    private func tickClock() {
        guard let limit = timeLimit else { return }
        let remaining = limit - Date().timeIntervalSince(sessionStart)
        secondsRemaining = max(0, remaining)
        if remaining <= 0 {
            ticker?.cancel()
            ticker = nil
            if !finished {
                Haptics.sessionComplete()
                finished = true
            }
        }
    }

    // MARK: Answering

    func select(_ choice: Int) {
        guard !revealed else { return }
        Haptics.tap()
        withAnimation(Motion.quick) { selected = choice }
    }

    /// Commits the current selection. Returns the question that was answered.
    @discardableResult
    func submit(store: AppStore) -> QuestionData? {
        guard let question = current, let choice = selected, !revealed else { return nil }

        let isCorrect = choice == question.correctIndex
        let seconds = Date().timeIntervalSince(questionStart)

        withAnimation(Motion.reveal) { revealed = true }

        if isCorrect {
            correctCount += 1
            Haptics.success()
            SoundEffects.correct()
        } else {
            Haptics.error()
            SoundEffects.wrong()
        }

        log.append(AnswerLog(question: question, selectedIndex: choice, isCorrect: isCorrect))

        store.recordAnswer(question: question,
                           selectedIndex: choice,
                           seconds: seconds,
                           sessionID: sessionID,
                           mode: mode)

        if store.settings.aiAutoExplain && store.ai.isUsable {
            requestAIExplanation(store: store, question: question, selectedIndex: choice)
        }
        return question
    }

    func requestAIExplanation(store: AppStore, question: QuestionData, selectedIndex: Int) {
        guard store.ai.isUsable, !isLoadingAI, aiExplanation == nil else { return }
        isLoadingAI = true
        aiFailed = false
        Task { @MainActor in
            let text = await store.ai.explainAnswer(question: question, selectedIndex: selectedIndex)
            isLoadingAI = false
            if let text {
                withAnimation(Motion.reveal) { aiExplanation = text }
                Haptics.tap()
            } else {
                aiFailed = true
            }
        }
    }

    func advance(store: AppStore) {
        guard revealed else { return }
        if isLastQuestion {
            complete(store: store)
            return
        }
        Haptics.tap()
        withAnimation(Motion.snappy) {
            index += 1
            selected = nil
            revealed = false
            aiExplanation = nil
            aiFailed = false
        }
        isLoadingAI = false
        questionStart = Date()
    }

    func complete(store: AppStore) {
        guard !finished else { return }
        ticker?.cancel()
        ticker = nil
        Haptics.sessionComplete()
        store.finishPracticeSession(sessionID: sessionID,
                                    mode: mode,
                                    questionCount: log.count,
                                    correctCount: correctCount,
                                    seconds: elapsed)
        withAnimation(Motion.gentle) { finished = true }
    }

    /// Ends early (the user tapped close) but still saves what was answered.
    func abandon(store: AppStore) {
        ticker?.cancel()
        ticker = nil
        guard !log.isEmpty, !finished else { return }
        store.finishPracticeSession(sessionID: sessionID,
                                    mode: mode,
                                    questionCount: log.count,
                                    correctCount: correctCount,
                                    seconds: elapsed)
    }

    // MARK: Summary helpers

    var missedQuestions: [QuestionData] { log.filter { !$0.isCorrect }.map(\.question) }

    var improvedTags: [String] {
        var tags = Set<String>()
        for entry in log where entry.isCorrect { entry.question.tags.forEach { tags.insert($0) } }
        for entry in log where !entry.isCorrect { entry.question.tags.forEach { tags.remove($0) } }
        return tags.sorted()
    }

    var weakTags: [String] {
        var tags = Set<String>()
        for entry in log where !entry.isCorrect { entry.question.tags.forEach { tags.insert($0) } }
        return tags.sorted()
    }
}
