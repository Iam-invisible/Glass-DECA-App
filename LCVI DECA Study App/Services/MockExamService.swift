//
//  MockExamService.swift
//  LCVI DECA Study App
//
//  Full-length exam simulation with flagging, navigation and a detailed
//  breakdown afterwards.
//

import CoreData
import Foundation

struct MockExamConfig {
    var cluster: DECACluster
    var questionCount: Int = 25
    var timed: Bool = true
    var timeLimitMinutes: Int = 30
    var weakTopicsOnly: Bool = false
}

struct MockTopicAccuracy: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let correct: Int
    let total: Int
    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}

struct MockExamSummary: Identifiable {
    let id: UUID
    let date: Date
    let cluster: DECACluster
    let questionCount: Int
    let correctCount: Int
    let durationSeconds: Double
    let timed: Bool

    var incorrectCount: Int { questionCount - correctCount }
    var scorePercent: Double {
        questionCount == 0 ? 0 : Double(correctCount) / Double(questionCount) * 100
    }
}

/// One question's outcome inside a completed attempt.
struct MockQuestionOutcome: Identifiable {
    var id: UUID { question.id }
    let question: QuestionData
    let selectedIndex: Int      // -1 = unanswered
    let flagged: Bool
    var isCorrect: Bool { selectedIndex == question.correctIndex }
}

@MainActor
final class MockExamService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames
    private let bank: QuestionBankService
    private let indicators: PerformanceIndicatorService
    private let sessions: PracticeSessionService

    init(context: NSManagedObjectContext,
         bank: QuestionBankService,
         indicators: PerformanceIndicatorService,
         sessions: PracticeSessionService) {
        self.ctx = context
        self.bank = bank
        self.indicators = indicators
        self.sessions = sessions
    }

    // MARK: - Building

    func buildExam(_ config: MockExamConfig) -> [QuestionData] {
        var pool = bank.questions(in: config.cluster)
        if pool.isEmpty { pool = bank.allQuestions() }

        if config.weakTopicsOnly {
            let weak = indicators.weakIndicatorCodes(cluster: config.cluster)
            let filtered = pool.filter { !Set($0.performanceIndicators).isDisjoint(with: weak) }
            if filtered.count >= max(5, config.questionCount / 2) { pool = filtered }
        }

        return Array(pool.shuffled().prefix(max(1, config.questionCount)))
    }

    var maxQuestions: Int { max(5, bank.questionCount()) }

    // MARK: - Saving an attempt

    @discardableResult
    func saveAttempt(config: MockExamConfig,
                     questions: [QuestionData],
                     selections: [UUID: Int],
                     flags: Set<UUID>,
                     elapsedSeconds: Double) -> UUID {
        let attemptID = UUID()
        let attempt = ctx.insert(CDMockAttempt.self, entity: names.mockAttempt)
        attempt.id = attemptID
        attempt.date = Date()
        attempt.cluster = config.cluster.rawValue
        attempt.questionCount = Int32(questions.count)
        attempt.durationSeconds = elapsedSeconds
        attempt.timed = config.timed
        attempt.timeLimitSeconds = Double(config.timeLimitMinutes * 60)
        attempt.weakTopicsOnly = config.weakTopicsOnly

        var correct = 0
        for (index, question) in questions.enumerated() {
            let selected = selections[question.id] ?? -1
            let isCorrect = selected == question.correctIndex
            if isCorrect { correct += 1 }

            let result = ctx.insert(CDMockResult.self, entity: names.mockResult)
            result.id = UUID()
            result.attemptID = attemptID
            result.questionID = question.id
            result.selectedIndex = Int32(selected)
            result.correctIndex = Int32(question.correctIndex)
            result.isCorrect = isCorrect
            result.flagged = flags.contains(question.id)
            result.order = Int32(index)
        }
        attempt.correctCount = Int32(correct)
        try? ctx.save()
        return attemptID
    }

    // MARK: - Queries

    func attempt(id: UUID) -> CDMockAttempt? {
        ctx.fetchAll(CDMockAttempt.self, entity: names.mockAttempt,
                     predicate: NSPredicate(format: "id == %@", id as CVarArg),
                     limit: 1).first
    }

    func summaries(limit: Int? = nil) -> [MockExamSummary] {
        let rows = ctx.fetchAll(CDMockAttempt.self, entity: names.mockAttempt,
                                sort: [NSSortDescriptor(key: "date", ascending: false)],
                                limit: limit)
        return rows.compactMap { row in
            guard let id = row.id else { return nil }
            return MockExamSummary(
                id: id,
                date: row.date ?? Date(),
                cluster: row.clusterValue,
                questionCount: Int(row.questionCount),
                correctCount: Int(row.correctCount),
                durationSeconds: row.durationSeconds,
                timed: row.timed
            )
        }
    }

    func attemptCount() -> Int { ctx.count(entity: names.mockAttempt) }

    func bestScorePercent() -> Double {
        summaries().map(\.scorePercent).max() ?? 0
    }

    /// Score of the previous attempt in the same cluster, for improvement checks.
    func previousScore(cluster: DECACluster, before id: UUID) -> Double? {
        let all = summaries().filter { $0.cluster == cluster }
        guard let index = all.firstIndex(where: { $0.id == id }), index + 1 < all.count else { return nil }
        return all[index + 1].scorePercent
    }

    func outcomes(for attemptID: UUID) -> [MockQuestionOutcome] {
        let results = ctx.fetchAll(CDMockResult.self, entity: names.mockResult,
                                   predicate: NSPredicate(format: "attemptID == %@", attemptID as CVarArg),
                                   sort: [NSSortDescriptor(key: "order", ascending: true)])
        let ids = results.compactMap { $0.questionID }
        let questions = Dictionary(uniqueKeysWithValues: bank.questions(for: ids).map { ($0.id, $0) })
        return results.compactMap { result in
            guard let qid = result.questionID, let question = questions[qid] else { return nil }
            return MockQuestionOutcome(question: question,
                                       selectedIndex: Int(result.selectedIndex),
                                       flagged: result.flagged)
        }
    }

    func topicAccuracy(for outcomes: [MockQuestionOutcome]) -> [MockTopicAccuracy] {
        var totals: [String: (correct: Int, total: Int)] = [:]
        for outcome in outcomes {
            for tag in outcome.question.tags {
                var entry = totals[tag] ?? (0, 0)
                entry.total += 1
                if outcome.isCorrect { entry.correct += 1 }
                totals[tag] = entry
            }
        }
        return totals.map { MockTopicAccuracy(name: $0.key, correct: $0.value.correct, total: $0.value.total) }
            .sorted { $0.accuracy < $1.accuracy }
    }

    func indicatorAccuracy(for outcomes: [MockQuestionOutcome]) -> [MockTopicAccuracy] {
        var totals: [String: (correct: Int, total: Int)] = [:]
        for outcome in outcomes {
            for code in outcome.question.performanceIndicators {
                var entry = totals[code] ?? (0, 0)
                entry.total += 1
                if outcome.isCorrect { entry.correct += 1 }
                totals[code] = entry
            }
        }
        return totals.map { MockTopicAccuracy(name: $0.key, correct: $0.value.correct, total: $0.value.total) }
            .sorted { $0.accuracy < $1.accuracy }
    }

    /// A short, concrete study plan derived from the attempt.
    func suggestedPlan(for outcomes: [MockQuestionOutcome], cluster: DECACluster) -> [String] {
        var plan: [String] = []
        let missed = outcomes.filter { !$0.isCorrect }
        guard !missed.isEmpty else {
            return ["Strong result — keep the streak going with daily practice and try a timed exam next."]
        }

        let weakTopics = topicAccuracy(for: outcomes).filter { $0.accuracy < 0.7 && $0.total >= 2 }
        if let first = weakTopics.first {
            plan.append("Run a topic session on \(first.name) — you scored \(Int(first.accuracy * 100))% there.")
        }
        if weakTopics.count > 1 {
            plan.append("Review \(weakTopics.dropFirst().prefix(2).map(\.name).joined(separator: " and ")) next.")
        }

        let weakIndicators = indicatorAccuracy(for: outcomes).filter { $0.accuracy < 0.7 }
        if let code = weakIndicators.first?.name {
            let text = SeedIndicators.text(forCode: code) ?? code
            plan.append("Practise the indicator \(code): \(text).")
        }

        plan.append("Retry the \(missed.count) missed question\(missed.count == 1 ? "" : "s") — they are already in your Mistake Notebook.")
        plan.append("Finish with a short Exam Cram session in \(cluster.shortName) before your next full exam.")
        return plan
    }

    func deleteAllAttempts() {
        for row in ctx.fetchAll(CDMockAttempt.self, entity: names.mockAttempt) { ctx.delete(row) }
        for row in ctx.fetchAll(CDMockResult.self, entity: names.mockResult) { ctx.delete(row) }
        try? ctx.save()
    }
}
