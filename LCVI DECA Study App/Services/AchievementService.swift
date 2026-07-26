//
//  AchievementService.swift
//  LCVI DECA Study App
//
//  A restrained badge system — professional, not childish. Achievements are
//  evaluated after each session against a snapshot of local stats.
//

import CoreData
import Foundation
import SwiftUI

struct AchievementDefinition: Identifiable, Hashable {
    let code: String
    let title: String
    let detail: String
    let symbol: String
    let isGold: Bool

    var id: String { code }
}

struct AchievementStatus: Identifiable, Hashable {
    let definition: AchievementDefinition
    let unlockedAt: Date?

    var id: String { definition.code }
    var isUnlocked: Bool { unlockedAt != nil }
}

/// Everything the evaluator needs, gathered once per check.
struct AchievementContext {
    var totalQuestionsAnswered: Int = 0
    var practiceSessionsCompleted: Int = 0
    var currentStreak: Int = 0
    var freezesEarned: Int = 0
    var mockExamsCompleted: Int = 0
    var bestMockScore: Double = 0
    var mistakesMastered: Int = 0
    var roleplayPracticeCount: Int = 0
    var examCramSessions: Int = 0
    var bestIndicatorMastery: Double = 0
}

@MainActor
final class AchievementService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames

    init(context: NSManagedObjectContext) { self.ctx = context }

    static let definitions: [AchievementDefinition] = [
        .init(code: "first_session", title: "First Practice Session",
              detail: "Complete your first practice session.",
              symbol: "flag.checkered", isGold: false),
        .init(code: "streak_3", title: "3-Day Streak",
              detail: "Meet your daily goal three days in a row.",
              symbol: "flame", isGold: true),
        .init(code: "streak_7", title: "7-Day Streak",
              detail: "Meet your daily goal seven days in a row.",
              symbol: "flame.fill", isGold: true),
        .init(code: "freeze_earned", title: "Streak Freeze Earned",
              detail: "Reach a 10-day streak to earn a streak freeze.",
              symbol: "snowflake", isGold: true),
        .init(code: "first_mock", title: "First Mock Exam",
              detail: "Complete a full mock exam.",
              symbol: "doc.text.magnifyingglass", isGold: false),
        .init(code: "mock_80", title: "80%+ Mock Exam",
              detail: "Score 80% or higher on a mock exam.",
              symbol: "rosette", isGold: false),
        .init(code: "mock_90", title: "90%+ Mock Exam",
              detail: "Score 90% or higher on a mock exam.",
              symbol: "trophy.fill", isGold: true),
        .init(code: "q_50", title: "50 Questions",
              detail: "Answer 50 practice questions.",
              symbol: "50.circle", isGold: false),
        .init(code: "q_100", title: "100 Questions",
              detail: "Answer 100 practice questions.",
              symbol: "100.circle", isGold: false),
        .init(code: "mistake_master", title: "Mistake Master",
              detail: "Correct 10 questions you previously missed.",
              symbol: "arrow.uturn.up.circle.fill", isGold: false),
        .init(code: "roleplay_ready", title: "Roleplay Ready",
              detail: "Complete 10 roleplay practices.",
              symbol: "person.wave.2.fill", isGold: false),
        .init(code: "exam_crammer", title: "Exam Crammer",
              detail: "Finish your first Exam Cram session.",
              symbol: "bolt.fill", isGold: false),
        .init(code: "performance_pro", title: "Performance Pro",
              detail: "Reach high mastery in one performance indicator.",
              symbol: "chart.bar.fill", isGold: true)
    ]

    // MARK: - Evaluation

    /// Returns definitions unlocked by this evaluation (empty if nothing new).
    @discardableResult
    func evaluate(_ context: AchievementContext) -> [AchievementDefinition] {
        var newlyUnlocked: [AchievementDefinition] = []

        func unlock(_ code: String, when condition: Bool) {
            guard condition, !isUnlocked(code) else { return }
            let row = self.row(for: code) ?? ctx.insert(CDAchievementRecord.self, entity: names.achievement)
            row.code = code
            row.unlockedAt = Date()
            if let def = Self.definitions.first(where: { $0.code == code }) {
                newlyUnlocked.append(def)
            }
        }

        unlock("first_session",   when: context.practiceSessionsCompleted >= 1)
        unlock("streak_3",        when: context.currentStreak >= 3)
        unlock("streak_7",        when: context.currentStreak >= 7)
        unlock("freeze_earned",   when: context.freezesEarned >= 1)
        unlock("first_mock",      when: context.mockExamsCompleted >= 1)
        unlock("mock_80",         when: context.bestMockScore >= 80)
        unlock("mock_90",         when: context.bestMockScore >= 90)
        unlock("q_50",            when: context.totalQuestionsAnswered >= 50)
        unlock("q_100",           when: context.totalQuestionsAnswered >= 100)
        unlock("mistake_master",  when: context.mistakesMastered >= 10)
        unlock("roleplay_ready",  when: context.roleplayPracticeCount >= 10)
        unlock("exam_crammer",    when: context.examCramSessions >= 1)
        unlock("performance_pro", when: context.bestIndicatorMastery >= 0.85)

        if ctx.hasChanges { try? ctx.save() }
        return newlyUnlocked
    }

    // MARK: - Queries

    func row(for code: String) -> CDAchievementRecord? {
        ctx.fetchAll(CDAchievementRecord.self, entity: names.achievement,
                     predicate: NSPredicate(format: "code == %@", code),
                     limit: 1).first
    }

    func isUnlocked(_ code: String) -> Bool {
        row(for: code)?.unlockedAt != nil
    }

    func statuses() -> [AchievementStatus] {
        let rows = ctx.fetchAll(CDAchievementRecord.self, entity: names.achievement)
        let byCode = Dictionary(uniqueKeysWithValues: rows.compactMap { row -> (String, Date)? in
            guard let code = row.code, let date = row.unlockedAt else { return nil }
            return (code, date)
        })
        return Self.definitions.map { AchievementStatus(definition: $0, unlockedAt: byCode[$0.code]) }
    }

    func unlockedCount() -> Int {
        statuses().filter(\.isUnlocked).count
    }

    func mostRecent() -> AchievementStatus? {
        statuses()
            .filter(\.isUnlocked)
            .max { ($0.unlockedAt ?? .distantPast) < ($1.unlockedAt ?? .distantPast) }
    }
}
