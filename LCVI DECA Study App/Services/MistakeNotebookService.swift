//
//  MistakeNotebookService.swift
//  LCVI DECA Study App
//
//  Every wrong answer is captured automatically. A question is only marked
//  mastered after it has been answered correctly several times in a row.
//

import CoreData
import Foundation

enum MistakeSort: String, CaseIterable, Identifiable {
    case recent, mostMissed, dueReview

    var id: String { rawValue }
    var title: String {
        switch self {
        case .recent:     return "Most recent"
        case .mostMissed: return "Most missed"
        case .dueReview:  return "Due review"
        }
    }
}

/// A mistake joined with its question, ready for display.
struct MistakeEntry: Identifiable {
    var id: UUID { question.id }
    let question: QuestionData
    let selectedIndex: Int
    let timesMissed: Int
    let lastMissedAt: Date
    let mastered: Bool
    let consecutiveCorrect: Int
    let nextReviewAt: Date?

    var isDue: Bool {
        guard let nextReviewAt else { return true }
        return nextReviewAt <= Date()
    }
}

@MainActor
final class MistakeNotebookService {
    /// Correct answers in a row required before a mistake counts as mastered.
    static let masteryThreshold = 2

    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames
    private let bank: QuestionBankService
    private let sr: SpacedRepetitionService

    init(context: NSManagedObjectContext, bank: QuestionBankService, sr: SpacedRepetitionService) {
        self.ctx = context
        self.bank = bank
        self.sr = sr
    }

    // MARK: - Recording

    func recordMistake(question: QuestionData, selectedIndex: Int, at date: Date = Date()) {
        let existing = record(for: question.id)
        let record = existing ?? ctx.insert(CDMistake.self, entity: names.mistake)
        if existing == nil {
            record.questionID = question.id
            record.firstMissedAt = date
            record.timesMissed = 0
        }
        record.selectedIndex = Int32(selectedIndex)
        record.correctIndex = Int32(question.correctIndex)
        record.lastMissedAt = date
        record.timesMissed += 1
        record.consecutiveCorrect = 0
        record.mastered = false
        record.masteredAt = nil
        record.cluster = question.cluster.rawValue
        try? ctx.save()
    }

    /// Called when a previously missed question is answered correctly.
    /// Returns true if this answer just moved the question to mastered.
    @discardableResult
    func recordCorrect(questionID: UUID, at date: Date = Date()) -> Bool {
        guard let record = record(for: questionID), !record.mastered else { return false }
        record.consecutiveCorrect += 1
        if Int(record.consecutiveCorrect) >= Self.masteryThreshold {
            record.mastered = true
            record.masteredAt = date
            try? ctx.save()
            return true
        }
        try? ctx.save()
        return false
    }

    // MARK: - Queries

    func record(for questionID: UUID) -> CDMistake? {
        ctx.fetchAll(CDMistake.self, entity: names.mistake,
                     predicate: NSPredicate(format: "questionID == %@", questionID as CVarArg),
                     limit: 1).first
    }

    func allRecords(includeMastered: Bool = true) -> [CDMistake] {
        let predicate = includeMastered ? nil : NSPredicate(format: "mastered == NO")
        return ctx.fetchAll(CDMistake.self, entity: names.mistake, predicate: predicate)
    }

    func openMistakeCount() -> Int {
        ctx.count(entity: names.mistake, predicate: NSPredicate(format: "mastered == NO"))
    }

    func masteredCount() -> Int {
        ctx.count(entity: names.mistake, predicate: NSPredicate(format: "mastered == YES"))
    }

    /// Question IDs still open (not yet mastered), most recently missed first.
    func openQuestionIDs(cluster: DECACluster? = nil) -> [UUID] {
        var predicates = [NSPredicate(format: "mastered == NO")]
        if let cluster {
            predicates.append(NSPredicate(format: "cluster == %@", cluster.rawValue))
        }
        return ctx.fetchAll(CDMistake.self, entity: names.mistake,
                            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates),
                            sort: [NSSortDescriptor(key: "lastMissedAt", ascending: false)])
            .compactMap { $0.questionID }
    }

    /// Full display entries with filters and sorting applied.
    func entries(cluster: DECACluster? = nil,
                 tag: String? = nil,
                 indicator: String? = nil,
                 includeMastered: Bool = false,
                 sort: MistakeSort = .recent) -> [MistakeEntry] {
        let records = allRecords(includeMastered: includeMastered)
        let questionIDs = records.compactMap { $0.questionID }
        let questions = Dictionary(uniqueKeysWithValues:
            bank.questions(for: questionIDs).map { ($0.id, $0) })
        let srRecords = sr.recordsByQuestion()

        var entries: [MistakeEntry] = []
        for record in records {
            guard let qid = record.questionID, let question = questions[qid] else { continue }
            if let cluster, question.cluster != cluster { continue }
            if let tag, !question.tags.contains(tag) { continue }
            if let indicator, !question.performanceIndicators.contains(indicator) { continue }
            entries.append(MistakeEntry(
                question: question,
                selectedIndex: Int(record.selectedIndex),
                timesMissed: Int(record.timesMissed),
                lastMissedAt: record.lastMissedAt ?? Date.distantPast,
                mastered: record.mastered,
                consecutiveCorrect: Int(record.consecutiveCorrect),
                nextReviewAt: srRecords[qid]?.nextReviewAt
            ))
        }

        switch sort {
        case .recent:
            entries.sort { $0.lastMissedAt > $1.lastMissedAt }
        case .mostMissed:
            entries.sort { ($0.timesMissed, $0.lastMissedAt) > ($1.timesMissed, $1.lastMissedAt) }
        case .dueReview:
            entries.sort {
                ($0.nextReviewAt ?? .distantPast) < ($1.nextReviewAt ?? .distantPast)
            }
        }
        return entries
    }

    func clearAll() {
        for record in allRecords() { ctx.delete(record) }
        try? ctx.save()
    }
}
