//
//  PreviewSeed.swift
//  LCVI DECA Study App
//
//  The demo state behind the `GLASSPREVIEW` promo code: a phone that looks
//  like it has been used for a fortnight, so App Store screenshots show real
//  numbers instead of a fresh install's zeros.
//
//  **Debug builds only, on purpose.** Every other promo code touches the
//  wallet and the cosmetic catalogue — things §8.30 is happy to call public,
//  because the worst case is a hat nobody earned. This one calls
//  `resetProgress`, so a student who typed it into the shipping app would
//  lose their entire history to a code they were only curious about. Gating
//  it to DEBUG costs nothing: screenshots come off a build made here, and a
//  Debug build is pixel-identical to Release for this purpose.
//
//  Everything is seeded through the app's own funnels rather than written
//  straight to Core Data (§8.37 is the same argument at question scope): the
//  notebook, spaced repetition, indicator mastery and the daily rows all
//  derive from `recordAnswer` and `recordAnswers`, so a seeded phone is
//  internally consistent instead of merely looking full.
//

#if DEBUG

import Foundation

extension AppStore {

    /// Wipes progress and rebuilds a fortnight of plausible study history.
    func applyPreviewSeed() {
        resetProgress(keepQuestionBank: true)

        settings.cluster = .marketing
        settings.eventCode = "MCS"
        settings.dailyGoal = 10
        settings.quickThinkGoal = 1
        // The companion is charming and wrong for a screenshot: it sits in the
        // bottom-right of every screen and would land on top of the tab bar in
        // the one corner the preview frames crop tightest.
        settings.companionEnabled = false

        let pool = bank.questions(in: .marketing)
        guard !pool.isEmpty else { return }

        seedPastDays()
        seedAnswers(from: pool)
        seedRoleplays()
        seedQuickThinks()

        settings.coins = Self.previewCoins
        evaluateAchievements()

        // Achievements queue celebration overlays, and a seeded phone would
        // open with a stack of them covering the screen being photographed.
        eventQueue.removeAll()
        pendingStreakCelebration = nil
        refresh()
    }

    /// A balance that reads as earned. Enough to afford the dearest pack
    /// without looking like a cheat.
    private static var previewCoins: Int { 1_240 }

    /// Eleven completed days before today, oldest first so the streak logic
    /// chains day keys the way it would have in real use. Today is left to
    /// `seedAnswers`, which completes the goal through the live path and so
    /// lands the streak on twelve.
    private func seedPastDays() {
        let calendar = Calendar.current
        for offset in stride(from: 11, through: 1, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            // Varied rather than flat: an identical bar every day reads as
            // fabricated in the week chart, which is the one place it shows.
            let answered = 10 + (offset * 3) % 5
            let correct = Int((Double(answered) * 0.86).rounded())
            _ = streaks.recordAnswers(count: answered,
                                      correct: correct,
                                      seconds: Double(answered) * 24,
                                      goal: settings.dailyGoal,
                                      now: day)
        }
    }

    /// Real questions through the real funnel, so indicator mastery, the
    /// notebook and the review queue all agree with the accuracy on Progress.
    private func seedAnswers(from pool: [QuestionData]) {
        // Deterministic: the same phone every time the code is redeemed, so a
        // re-shoot matches the previous set rather than drifting.
        let ordered = pool.enumerated()
            .sorted { $0.element.id.uuidString < $1.element.id.uuidString }
            .map(\.element)

        let history = Array(ordered.prefix(48))
        for (index, question) in history.enumerated() {
            let correct = index % 7 != 3
            record(question, correct: correct, countsTowardDailyGoal: false)
        }

        // Today's ten, which completes the goal and leaves the day green.
        let todays = Array(ordered.dropFirst(48).prefix(10))
        for (index, question) in todays.enumerated() {
            record(question, correct: index != 6, countsTowardDailyGoal: true)
        }
    }

    private func record(_ question: QuestionData, correct: Bool, countsTowardDailyGoal: Bool) {
        let selected = correct
            ? question.correctIndex
            : (question.correctIndex + 1) % max(1, question.choices.count)
        recordAnswer(question: question,
                     selectedIndex: selected,
                     seconds: Double(18 + (question.choices.count * 3)),
                     sessionID: nil,
                     mode: .daily,
                     countsTowardDailyGoal: countsTowardDailyGoal)
    }

    private func seedRoleplays() {
        let prompts = bank.roleplays(for: .marketing).prefix(3)
        for (index, prompt) in prompts.enumerated() {
            var scores: [RubricCategory: Int] = [:]
            for (offset, category) in RubricCategory.allCases.enumerated() {
                scores[category] = 3 + ((index + offset) % 3 == 0 ? 1 : 0)
            }
            _ = saveRoleplayResponse(prompt: prompt,
                                     notes: "Led with the recommendation, then the two reasons behind it.",
                                     transcript: "",
                                     scores: scores,
                                     aiFeedback: nil,
                                     prepSeconds: 600,
                                     presentSeconds: 540)
        }
    }

    /// Exactly one, and only one.
    ///
    /// `saveQuickThink` stamps `Date()`, and the daily count is "rows dated
    /// today", so four seeded sessions made the Study panel read "4 of 1"
    /// against a goal of one — a number no real phone can produce, and the
    /// first thing a reader's eye would catch in a screenshot. Backdating the
    /// extras afterwards was tried and did not take, so the seed matches what
    /// the goal actually is rather than fighting the timestamp.
    private func seedQuickThinks() {
        let scenarios = SeedQuickThink.scenarios(for: .marketing).prefix(1)
        let feedback = QuickThinkFeedback(
            strongest: "You gave a clear recommendation before the reasoning.",
            weakest: "The close could name the next step.",
            conceptUsedWell: "Channel strategy",
            conceptMissing: "Risk to existing accounts",
            moreProfessional: "Open with the recommendation, then support it in two points.",
            strongerAnswer: "I would pilot a single region for six months against a sales target.")
        for scenario in scenarios {
            _ = saveQuickThink(scenario: scenario,
                               response: "I would not grant province-wide exclusivity yet.",
                               feedback: feedback,
                               seconds: 96,
                               usedAI: false)
        }
    }
}

#endif
