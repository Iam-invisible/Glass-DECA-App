//
//  StreakService.swift
//  LCVI DECA Study App
//
//  Daily goal tracking + streaks with automatic streak freezes.
//  All dates are local-calendar day keys so travelling across time zones can
//  never double-count or skip a day.
//

import CoreData
import Foundation

/// Streak tuning in one place.
enum StreakRules {
    /// How many freezes a student can hold at once. Two is enough to survive a
    /// bad week without making a streak unbreakable.
    static let maxFreezes = 2
    /// Consecutive days between earned freezes.
    static let daysPerFreeze = 10
}

struct DailyProgressSnapshot: Equatable {
    var dayKey: String
    var answered: Int
    var correct: Int
    var goal: Int
    var goalMet: Bool
    var secondsStudied: Double

    var remaining: Int { max(0, goal - answered) }
    var fraction: Double { goal <= 0 ? 1 : min(1, Double(answered) / Double(goal)) }
    var accuracy: Double { answered == 0 ? 0 : Double(correct) / Double(answered) }
}

/// What changed when progress was recorded — drives celebration animations.
struct StreakOutcome: Equatable {
    var goalJustCompleted = false
    var streakIncreased = false
    var freezeEarned = false
    var freezeUsed = false
    var newStreak = 0
}

@MainActor
final class StreakService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames
    private let store: StreakStore

    init(context: NSManagedObjectContext, store: StreakStore) {
        self.ctx = context
        self.store = store
    }

    var state: StreakState { store.state }

    // MARK: - Daily progress

    func progressRow(for date: Date = Date(), goal: Int, createIfNeeded: Bool = true) -> CDDailyProgress? {
        let key = date.dayKey
        if let existing = ctx.fetchAll(CDDailyProgress.self, entity: names.dailyProgress,
                                       predicate: NSPredicate(format: "dayKey == %@", key),
                                       limit: 1).first {
            return existing
        }
        guard createIfNeeded else { return nil }
        let row = ctx.insert(CDDailyProgress.self, entity: names.dailyProgress)
        row.dayKey = key
        row.date = Calendar.current.startOfDay(for: date)
        row.goal = Int32(goal)
        return row
    }

    func snapshot(for date: Date = Date(), goal: Int) -> DailyProgressSnapshot {
        let key = date.dayKey
        let row = ctx.fetchAll(CDDailyProgress.self, entity: names.dailyProgress,
                               predicate: NSPredicate(format: "dayKey == %@", key),
                               limit: 1).first
        return DailyProgressSnapshot(
            dayKey: key,
            answered: Int(row?.questionsAnswered ?? 0),
            correct: Int(row?.correctCount ?? 0),
            goal: goal,
            goalMet: row?.goalMet ?? false,
            secondsStudied: row?.secondsStudied ?? 0
        )
    }

    func history(days: Int, goal: Int) -> [DailyProgressSnapshot] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let rows = ctx.fetchAll(CDDailyProgress.self, entity: names.dailyProgress)
        let byKey = Dictionary(uniqueKeysWithValues: rows.compactMap { row -> (String, CDDailyProgress)? in
            guard let key = row.dayKey else { return nil }
            return (key, row)
        })

        return (0..<days).reversed().compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let key = date.dayKey
            let row = byKey[key]
            return DailyProgressSnapshot(
                dayKey: key,
                answered: Int(row?.questionsAnswered ?? 0),
                correct: Int(row?.correctCount ?? 0),
                goal: Int(row?.goal ?? Int32(goal)),
                goalMet: row?.goalMet ?? false,
                secondsStudied: row?.secondsStudied ?? 0
            )
        }
    }

    // MARK: - Recording

    /// Records answered questions toward today's goal and updates the streak.
    @discardableResult
    func recordAnswers(count: Int, correct: Int, seconds: Double, goal: Int, now: Date = Date()) -> StreakOutcome {
        guard count > 0 else { return StreakOutcome(newStreak: state.current) }

        // Bring the streak up to date before adding today's work, so a missed
        // day is resolved (freeze or reset) exactly once.
        var outcome = reconcile(now: now)

        guard let row = progressRow(for: now, goal: goal) else {
            return outcome
        }
        let wasMet = row.goalMet
        row.questionsAnswered += Int32(count)
        row.correctCount += Int32(correct)
        row.secondsStudied += seconds
        row.goal = Int32(goal)

        if !wasMet && Int(row.questionsAnswered) >= goal {
            row.goalMet = true
            outcome.goalJustCompleted = true
            outcome = applyGoalCompletion(dayKey: now.dayKey, into: outcome)
        }
        try? ctx.save()
        outcome.newStreak = state.current
        return outcome
    }

    /// Advances the streak for a newly completed day.
    private func applyGoalCompletion(dayKey: String, into outcome: StreakOutcome) -> StreakOutcome {
        var outcome = outcome
        var didIncrease = false
        var didEarnFreeze = false

        store.update { s in
            // Guard against double counting if the same day is completed twice.
            guard s.lastCompletedDayKey != dayKey else { return }

            // `reconcile` has already reset or rescued the streak for any
            // missed days, so completing today always advances by exactly one.
            s.current += 1
            s.lastCompletedDayKey = dayKey
            s.longest = max(s.longest, s.current)
            didIncrease = true

            // Capped at two. Freezes exist to survive a bad day, not to make a
            // streak unbreakable — banking ten would mean the number stopped
            // meaning anything. At the cap the milestone simply passes: no
            // freeze, so no celebration and no coins for one either.
            if s.current > 0 && s.current % 10 == 0 && s.freezes < StreakRules.maxFreezes {
                s.freezes += 1
                s.freezesEarnedTotal += 1
                didEarnFreeze = true
            }
        }

        outcome.streakIncreased = didIncrease
        outcome.freezeEarned = didEarnFreeze
        return outcome
    }

    // MARK: - Reconciliation

    /// Applies missed days: a freeze rescues exactly one missed day, otherwise
    /// the streak resets. Safe to call as often as you like.
    @discardableResult
    func reconcile(now: Date = Date()) -> StreakOutcome {
        var outcome = StreakOutcome()
        let todayKey = now.dayKey

        store.update { s in
            guard let last = s.lastCompletedDayKey,
                  let gap = DayKey.daysBetween(last, todayKey) else {
                return
            }
            // gap 0 = already completed today, gap 1 = yesterday (streak alive).
            guard gap >= 2 else { return }

            let missedDays = gap - 1
            var remaining = missedDays

            while remaining > 0, s.freezes > 0 {
                s.freezes -= 1
                remaining -= 1
                outcome.freezeUsed = true
                // Record which day was rescued so it is never rescued twice.
                if let rescued = Calendar.current.date(byAdding: .day, value: -remaining - 1, to: now) {
                    let key = rescued.dayKey
                    if !s.frozenDayKeys.contains(key) { s.frozenDayKeys.append(key) }
                }
            }

            if remaining > 0 {
                s.current = 0
            } else {
                // Freezes covered every missed day; the streak survives.
                s.lastCompletedDayKey = Calendar.current
                    .date(byAdding: .day, value: -1, to: now)?.dayKey ?? last
            }
        }

        outcome.newStreak = state.current
        return outcome
    }

    func resetStreak() {
        store.reset()
    }
}
