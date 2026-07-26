//
//  SpacedRepetitionService.swift
//  LCVI DECA Study App
//
//  A local SM-2 style scheduler. Everything runs on-device against Core Data:
//  correct answers stretch the interval, wrong answers pull the question back
//  into the near-term queue.
//

import CoreData
import Foundation

@MainActor
final class SpacedRepetitionService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames

    init(context: NSManagedObjectContext) { self.ctx = context }

    // MARK: - Recording

    /// Updates (or creates) the record for a question after it is answered.
    @discardableResult
    func record(questionID: UUID, correct: Bool, at date: Date = Date()) -> CDSRRecord {
        let record = self.record(for: questionID) ?? makeRecord(questionID: questionID)

        record.timesAnswered += 1
        record.lastAnsweredAt = date

        if correct {
            record.timesCorrect += 1
            record.consecutiveCorrect += 1
            record.ease = min(2.8, record.ease + 0.09)

            switch record.consecutiveCorrect {
            case 1:  record.intervalDays = 1
            case 2:  record.intervalDays = 3
            case 3:  record.intervalDays = 7
            default: record.intervalDays = min(120, max(1, record.intervalDays) * record.ease)
            }
        } else {
            record.timesIncorrect += 1
            record.consecutiveCorrect = 0
            record.ease = max(1.3, record.ease - 0.22)
            // Wrong answers come back the same study day.
            record.intervalDays = 0
        }

        record.nextReviewAt = record.intervalDays <= 0
            ? date.addingTimeInterval(15 * 60)
            : Calendar.current.date(byAdding: .day,
                                    value: Int(record.intervalDays.rounded()),
                                    to: Calendar.current.startOfDay(for: date)) ?? date

        record.masteryLevel = Int32(masteryBand(for: record).rawValue)
        try? ctx.save()
        return record
    }

    private func masteryBand(for record: CDSRRecord) -> MasteryBand {
        guard record.timesAnswered > 0 else { return .untouched }
        let accuracy = record.accuracy
        let streak = Int(record.consecutiveCorrect)

        if streak >= 4 && accuracy >= 0.85 { return .mastered }
        if streak >= 3 && accuracy >= 0.7  { return .proficient }
        if streak >= 1 && accuracy >= 0.5  { return .developing }
        return .learning
    }

    // MARK: - Queries

    func record(for questionID: UUID) -> CDSRRecord? {
        ctx.fetchAll(CDSRRecord.self, entity: names.srRecord,
                     predicate: NSPredicate(format: "questionID == %@", questionID as CVarArg),
                     limit: 1).first
    }

    func allRecords() -> [CDSRRecord] {
        ctx.fetchAll(CDSRRecord.self, entity: names.srRecord)
    }

    func recordsByQuestion() -> [UUID: CDSRRecord] {
        var map: [UUID: CDSRRecord] = [:]
        for r in allRecords() {
            if let id = r.questionID { map[id] = r }
        }
        return map
    }

    /// Question IDs whose next review date has arrived.
    func dueQuestionIDs(now: Date = Date()) -> [UUID] {
        ctx.fetchAll(CDSRRecord.self, entity: names.srRecord,
                     predicate: NSPredicate(format: "nextReviewAt != nil AND nextReviewAt <= %@", now as NSDate),
                     sort: [NSSortDescriptor(key: "nextReviewAt", ascending: true)])
            .compactMap { $0.questionID }
    }

    func dueCount(now: Date = Date()) -> Int {
        ctx.count(entity: names.srRecord,
                  predicate: NSPredicate(format: "nextReviewAt != nil AND nextReviewAt <= %@", now as NSDate))
    }

    /// Question IDs that have never been answered.
    func unseenQuestionIDs(from allIDs: [UUID]) -> [UUID] {
        let seen = Set(allRecords().compactMap { $0.questionID })
        return allIDs.filter { !seen.contains($0) }
    }

    func totalAnswered() -> Int {
        allRecords().reduce(0) { $0 + Int($1.timesAnswered) }
    }

    func totalCorrect() -> Int {
        allRecords().reduce(0) { $0 + Int($1.timesCorrect) }
    }

    func overallAccuracy() -> Double {
        let answered = totalAnswered()
        return answered == 0 ? 0 : Double(totalCorrect()) / Double(answered)
    }

    private func makeRecord(questionID: UUID) -> CDSRRecord {
        let record = ctx.insert(CDSRRecord.self, entity: names.srRecord)
        record.questionID = questionID
        record.ease = 2.5
        record.intervalDays = 0
        return record
    }
}
