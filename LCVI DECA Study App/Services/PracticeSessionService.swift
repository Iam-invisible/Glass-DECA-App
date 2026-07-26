//
//  PracticeSessionService.swift
//  LCVI DECA Study App
//
//  Builds targeted practice sessions and persists the results.
//  A daily session is never purely random: it blends due review, unresolved
//  mistakes, weak performance indicators and fresh questions.
//

import CoreData
import Foundation

struct SessionOptions {
    var mode: PracticeMode = .custom
    var cluster: DECACluster? = nil
    var count: Int = 10
    var difficulties: Set<Difficulty> = Set(Difficulty.allCases)
    var tags: Set<String> = []
    var indicators: Set<String> = []
    var includeMissed: Bool = true
    var includeNew: Bool = true
    var includeDue: Bool = true

    static func daily(cluster: DECACluster, count: Int) -> SessionOptions {
        SessionOptions(mode: .daily, cluster: cluster, count: count)
    }
}

/// A built session ready to run.
struct BuiltSession {
    var mode: PracticeMode
    var cluster: DECACluster?
    var questions: [QuestionData]
    /// Human-readable description of how the session was assembled.
    var composition: [String]
}

@MainActor
final class PracticeSessionService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames
    private let bank: QuestionBankService
    private let sr: SpacedRepetitionService
    private let mistakes: MistakeNotebookService
    private let indicators: PerformanceIndicatorService

    init(context: NSManagedObjectContext,
         bank: QuestionBankService,
         sr: SpacedRepetitionService,
         mistakes: MistakeNotebookService,
         indicators: PerformanceIndicatorService) {
        self.ctx = context
        self.bank = bank
        self.sr = sr
        self.mistakes = mistakes
        self.indicators = indicators
    }

    // MARK: - Building

    func build(_ options: SessionOptions) -> BuiltSession {
        switch options.mode {
        case .daily:     return buildDaily(options)
        case .examCram:  return buildExamCram(options)
        case .reviewDue: return buildFromIDs(sr.dueQuestionIDs(), options, label: "Due for review")
        case .mistakes:  return buildFromIDs(mistakes.openQuestionIDs(cluster: options.cluster),
                                             options, label: "From your Mistake Notebook")
        case .bookmarked:
            let ids = bank.bookmarkedQuestions(cluster: options.cluster).map(\.id)
            return buildFromIDs(ids, options, label: "bookmarked")
        default:         return buildCustom(options)
        }
    }

    /// The signature "intelligent" daily mix.
    private func buildDaily(_ options: SessionOptions) -> BuiltSession {
        let pool = filteredPool(options)
        guard !pool.isEmpty else {
            return BuiltSession(mode: .daily, cluster: options.cluster, questions: [], composition: [])
        }

        let target = max(1, options.count)
        let byID = Dictionary(uniqueKeysWithValues: pool.map { ($0.id, $0) })

        var picked: [QuestionData] = []
        var used = Set<UUID>()
        var composition: [String] = []

        func take(_ ids: [UUID], limit: Int, label: String) {
            guard limit > 0 else { return }
            var added = 0
            for id in ids where !used.contains(id) {
                guard added < limit, picked.count < target, let q = byID[id] else { break }
                picked.append(q)
                used.insert(id)
                added += 1
            }
            if added > 0 { composition.append("\(added) \(label)") }
        }

        // 1. Questions that are due for spaced review.
        take(sr.dueQuestionIDs(), limit: Int(ceil(Double(target) * 0.40)), label: "due for review")

        // 2. Questions still open in the Mistake Notebook.
        take(mistakes.openQuestionIDs(cluster: options.cluster),
             limit: Int(ceil(Double(target) * 0.25)), label: "previously missed")

        // 3. Questions tied to weak performance indicators.
        let weakCodes = indicators.weakIndicatorCodes(cluster: options.cluster)
        if !weakCodes.isEmpty {
            let weakIDs = pool
                .filter { !$0.performanceIndicators.filter(weakCodes.contains).isEmpty }
                .map(\.id)
            take(weakIDs.shuffled(), limit: Int(ceil(Double(target) * 0.20)),
                 label: "on weak indicators")
        }

        // 4. Fresh questions the student has never seen.
        let unseen = sr.unseenQuestionIDs(from: pool.map(\.id))
        take(unseen.shuffled(), limit: target, label: "new")

        // 5. Backfill with the least recently practised questions.
        if picked.count < target {
            let records = sr.recordsByQuestion()
            let remaining = pool
                .filter { !used.contains($0.id) }
                .sorted {
                    let l = records[$0.id]?.lastAnsweredAt ?? .distantPast
                    let r = records[$1.id]?.lastAnsweredAt ?? .distantPast
                    return l < r
                }
                .map(\.id)
            take(remaining, limit: target - picked.count, label: "for reinforcement")
        }

        // Interleave so the session doesn't front-load every hard review item.
        return BuiltSession(mode: .daily,
                            cluster: options.cluster,
                            questions: interleave(picked),
                            composition: composition)
    }

    /// Exam Cram prioritises whatever is weakest, hardest and most overdue.
    private func buildExamCram(_ options: SessionOptions) -> BuiltSession {
        let pool = filteredPool(options)
        guard !pool.isEmpty else {
            return BuiltSession(mode: .examCram, cluster: options.cluster, questions: [], composition: [])
        }

        let dueSet = Set(sr.dueQuestionIDs())
        let missedSet = Set(mistakes.openQuestionIDs(cluster: options.cluster))
        let weakCodes = indicators.weakIndicatorCodes(cluster: options.cluster)
        let records = sr.recordsByQuestion()

        func priority(_ q: QuestionData) -> Double {
            var score = 0.0
            if missedSet.contains(q.id) { score += 5 }
            if dueSet.contains(q.id) { score += 4 }
            if !q.performanceIndicators.filter(weakCodes.contains).isEmpty { score += 3 }
            if let record = records[q.id] {
                score += (1 - record.accuracy) * 3
                score -= Double(record.masteryLevel) * 0.8
            } else {
                score += 1.5   // unseen material is high-yield before a competition
            }
            score += Double(q.difficulty.rawValue) * 0.4
            return score
        }

        let ranked = pool
            .map { ($0, priority($0)) }
            .sorted { $0.1 > $1.1 }
            .prefix(max(1, options.count))
            .map(\.0)

        var composition: [String] = []
        let missedCount = ranked.filter { missedSet.contains($0.id) }.count
        let dueCount = ranked.filter { dueSet.contains($0.id) }.count
        if missedCount > 0 { composition.append("\(missedCount) previously missed") }
        if dueCount > 0 { composition.append("\(dueCount) due for review") }
        composition.append("prioritised by weakest topics")

        return BuiltSession(mode: .examCram,
                            cluster: options.cluster,
                            questions: Array(ranked),
                            composition: composition)
    }

    private func buildCustom(_ options: SessionOptions) -> BuiltSession {
        var pool = filteredPool(options)

        let dueSet = Set(sr.dueQuestionIDs())
        let missedSet = Set(mistakes.openQuestionIDs(cluster: options.cluster))
        let seenIDs = Set(sr.recordsByQuestion().keys)

        // Narrowing the sources filters the pool. Turning every source off is
        // read as "no preference" rather than "no questions".
        let anySourceOn = options.includeDue || options.includeMissed || options.includeNew
        let allSourcesOn = options.includeDue && options.includeMissed && options.includeNew
        if anySourceOn && !allSourcesOn {
            let narrowed = pool.filter { q in
                (options.includeDue && dueSet.contains(q.id))
                    || (options.includeMissed && missedSet.contains(q.id))
                    || (options.includeNew && !seenIDs.contains(q.id))
            }
            if !narrowed.isEmpty { pool = narrowed }
        }

        let questions = Array(pool.shuffled().prefix(max(1, options.count)))
        return BuiltSession(mode: options.mode,
                            cluster: options.cluster,
                            questions: questions,
                            composition: ["\(questions.count) questions"])
    }

    private func buildFromIDs(_ ids: [UUID], _ options: SessionOptions, label: String) -> BuiltSession {
        var questions = bank.questions(for: ids)
        if let cluster = options.cluster, options.mode == .reviewDue || options.mode == .mistakes {
            let filtered = questions.filter { $0.cluster == cluster }
            // Never leave the student with an empty screen just because of the
            // cluster filter — fall back to everything that is genuinely due.
            if !filtered.isEmpty { questions = filtered }
        }
        questions = Array(questions.prefix(max(1, options.count)))
        return BuiltSession(mode: options.mode,
                            cluster: options.cluster,
                            questions: questions,
                            composition: questions.isEmpty ? [] : ["\(questions.count) \(label)"])
    }

    /// Applies cluster / difficulty / tag / indicator filters.
    private func filteredPool(_ options: SessionOptions) -> [QuestionData] {
        var pool = options.cluster.map { bank.questions(in: $0) } ?? bank.allQuestions()
        if pool.isEmpty && options.cluster != nil {
            pool = bank.allQuestions()   // graceful fallback for a thin bank
        }
        if options.difficulties.count != Difficulty.allCases.count {
            pool = pool.filter { options.difficulties.contains($0.difficulty) }
        }
        if !options.tags.isEmpty {
            pool = pool.filter { !Set($0.tags).isDisjoint(with: options.tags) }
        }
        if !options.indicators.isEmpty {
            pool = pool.filter { !Set($0.performanceIndicators).isDisjoint(with: options.indicators) }
        }
        return pool
    }

    /// Light shuffle that keeps a mix of sources spread through the session.
    private func interleave(_ questions: [QuestionData]) -> [QuestionData] {
        guard questions.count > 3 else { return questions }
        var result = questions
        // Rotate every other item to break up long runs from the same source.
        let half = result.count / 2
        var interleaved: [QuestionData] = []
        for i in 0..<half {
            interleaved.append(result[i])
            interleaved.append(result[half + i])
        }
        if result.count % 2 == 1, let last = result.last {
            interleaved.append(last)
        }
        result = interleaved
        return result
    }

    // MARK: - Persisting

    @discardableResult
    func createSession(mode: PracticeMode, cluster: DECACluster?) -> UUID {
        let id = UUID()
        let row = ctx.insert(CDPracticeSession.self, entity: names.practiceSession)
        row.id = id
        row.mode = mode.rawValue
        row.cluster = cluster?.rawValue
        row.startedAt = Date()
        try? ctx.save()
        return id
    }

    func recordAnswer(sessionID: UUID,
                      question: QuestionData,
                      selectedIndex: Int,
                      isCorrect: Bool,
                      seconds: Double) {
        let row = ctx.insert(CDPracticeAnswer.self, entity: names.practiceAnswer)
        row.id = UUID()
        row.sessionID = sessionID
        row.questionID = question.id
        row.selectedIndex = Int32(selectedIndex)
        row.isCorrect = isCorrect
        row.answeredAt = Date()
        row.secondsSpent = seconds
        row.cluster = question.cluster.rawValue
        row.indicators = ListCodec.encode(question.performanceIndicators)
        row.tags = ListCodec.encode(question.tags)
        try? ctx.save()
    }

    func finishSession(sessionID: UUID, questionCount: Int, correctCount: Int, seconds: Double) {
        guard let row = ctx.fetchAll(CDPracticeSession.self, entity: names.practiceSession,
                                     predicate: NSPredicate(format: "id == %@", sessionID as CVarArg),
                                     limit: 1).first else { return }
        row.endedAt = Date()
        row.questionCount = Int32(questionCount)
        row.correctCount = Int32(correctCount)
        row.durationSeconds = seconds
        try? ctx.save()
    }

    // MARK: - Stats

    func completedSessionCount(mode: PracticeMode? = nil) -> Int {
        var predicates = [NSPredicate(format: "endedAt != nil")]
        if let mode { predicates.append(NSPredicate(format: "mode == %@", mode.rawValue)) }
        return ctx.count(entity: names.practiceSession,
                         predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
    }

    func answers(cluster: DECACluster? = nil) -> [CDPracticeAnswer] {
        let predicate = cluster.map { NSPredicate(format: "cluster == %@", $0.rawValue) }
        return ctx.fetchAll(CDPracticeAnswer.self, entity: names.practiceAnswer, predicate: predicate)
    }

    /// Accuracy grouped by tag, for the Progress dashboard.
    func accuracyByTag(cluster: DECACluster?) -> [(tag: String, correct: Int, total: Int)] {
        var totals: [String: (correct: Int, total: Int)] = [:]
        for answer in answers(cluster: cluster) {
            for tag in ListCodec.decode(answer.tags) {
                var entry = totals[tag] ?? (0, 0)
                entry.total += 1
                if answer.isCorrect { entry.correct += 1 }
                totals[tag] = entry
            }
        }
        return totals
            .map { (tag: $0.key, correct: $0.value.correct, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }

    func accuracyByCluster() -> [DECACluster: (correct: Int, total: Int)] {
        var totals: [DECACluster: (correct: Int, total: Int)] = [:]
        for answer in answers() {
            guard let cluster = DECACluster.from(answer.cluster) else { continue }
            var entry = totals[cluster] ?? (0, 0)
            entry.total += 1
            if answer.isCorrect { entry.correct += 1 }
            totals[cluster] = entry
        }
        return totals
    }

    func totalAnswered() -> Int { ctx.count(entity: names.practiceAnswer) }
}
