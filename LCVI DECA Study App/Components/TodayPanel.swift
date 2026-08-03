//
//  TodayPanel.swift
//  LCVI DECA Study App
//
//  The day — both goals and the streak — as one object.
//
//  They used to be two separate dials sitting side by side, each with its own
//  ring and its own full-width button. Once the cards came off, that read as
//  two unrelated widgets that happened to be adjacent: two big empty rings
//  competing for the eye and two heavy buttons competing for the thumb, with
//  nothing saying they were the same thought.
//
//  Concentric rings fix the relationship rather than the styling. One ring
//  stack is one object — "today" — and the two arcs are obviously parts of it.
//  The questions goal takes the outer arc because it is the larger job, ten or
//  more items against Quick Think's one or two.
//
//  The centre answers the question a student actually has, which is "what is
//  left", not "what have I done". Done-versus-goal is already in the legend
//  beside it, so repeating it in the middle would waste the one piece of
//  prominent space on the screen.
//
//  The streak sits inside this panel rather than under it. Left outside it was
//  a bare line in a different visual language directly beneath a composed
//  panel, which read as something that had fallen off. It is the third fact
//  about today, so it belongs in the thing that states today — but full width
//  under the rings rather than a third item in the legend column, because the
//  two rows up there start something and this one does not.
//

import SwiftUI

struct TodayPanel: View {
    let questionsDone: Int
    let questionsGoal: Int
    let quickThinkDone: Int
    let quickThinkGoal: Int
    /// False for events with no roleplay component — then this is a single
    /// ring and a single row, not a hollowed-out version of the pair.
    let showsQuickThink: Bool
    let streak: Int
    let freezes: Int
    let daysUntilNextFreeze: Int
    let onQuestions: () -> Void
    let onQuickThink: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var questionsFraction: Double {
        min(1, Double(questionsDone) / Double(max(1, questionsGoal)))
    }
    private var quickThinkFraction: Double {
        min(1, Double(quickThinkDone) / Double(max(1, quickThinkGoal)))
    }
    private var questionsMet: Bool { questionsDone >= max(1, questionsGoal) }
    private var quickThinkMet: Bool { quickThinkDone >= max(1, quickThinkGoal) }
    private var allMet: Bool { questionsMet && (!showsQuickThink || quickThinkMet) }

    var body: some View {
        VStack(spacing: 12) {
            goals
            streakRow
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }

    private var goals: some View {
        HStack(spacing: 20) {
            rings
            VStack(spacing: 10) {
                goalRow(title: "Questions",
                        symbol: "list.bullet",
                        tint: Palette.accent,
                        done: questionsDone,
                        goal: questionsGoal,
                        met: questionsMet,
                        action: onQuestions)

                if showsQuickThink {
                    goalRow(title: "Quick Think",
                            symbol: "brain.head.profile",
                            tint: Palette.gold,
                            done: quickThinkDone,
                            goal: quickThinkGoal,
                            met: quickThinkMet,
                            action: onQuickThink)
                }
            }
        }
    }

    // MARK: Streak

    /// The same row vocabulary as the goals — tinted glyph, title, sub-line,
    /// soft tinted plate — so it reads as a sibling rather than as leftovers.
    /// It is deliberately not a button: nothing here starts anything, and the
    /// full-width shape against the two column-width rows above is what says
    /// so without an affordance that lies.
    private var streakRow: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(Palette.gold.opacity(0.18))
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.gold)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(streak == 1 ? "1 day streak" : "\(streak) day streak")
                    .font(.appBodyMedium)
                    .foregroundStyle(Palette.textPrimary)
                    .monospacedDigit()
                Text(streakDetail)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            HStack(spacing: 3) {
                Image(systemName: "snowflake")
                    .font(.system(size: 11, weight: .bold))
                Text("\(freezes)/\(StreakRules.maxFreezes)")
                    .font(.appCaptionBold)
                    .monospacedDigit()
            }
            .foregroundStyle(freezes > 0 ? Palette.gold : Palette.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(freezes > 0 ? Palette.goldSoft : Palette.cardSunken))
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                .fill(Palette.gold.opacity(0.07))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streak) day streak, \(freezes) of \(StreakRules.maxFreezes) freezes")
        .accessibilityValue(streakDetail)
    }

    private var streakDetail: String {
        if streak == 0 { return "Answer today to start one" }
        if freezes >= StreakRules.maxFreezes { return "Freezes full" }
        return daysUntilNextFreeze == 1
            ? "1 day to your next freeze"
            : "\(daysUntilNextFreeze) days to your next freeze"
    }

    // MARK: Rings

    private var rings: some View {
        ZStack {
            ProgressRing(progress: questionsFraction,
                         lineWidth: 11,
                         tint: questionsMet ? Palette.success : Palette.accent)
                .frame(width: 132, height: 132)

            if showsQuickThink {
                ProgressRing(progress: quickThinkFraction,
                             lineWidth: 10,
                             tint: quickThinkMet ? Palette.success : Palette.gold)
                    .frame(width: 96, height: 96)
            }

            centre
        }
        .frame(width: 132, height: 132)
        .accessibilityHidden(true)
    }

    /// What is still owed, in the units of whichever goal is still open. The
    /// tint matches that goal's arc, so the number is always attributable to a
    /// ring without a label saying which.
    @ViewBuilder
    private var centre: some View {
        if allMet {
            VStack(spacing: 2) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Palette.success)
                Text("Done")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
            }
        } else {
            let onQuestionsStill = !questionsMet
            let remaining = onQuestionsStill
                ? max(0, questionsGoal - questionsDone)
                : max(0, quickThinkGoal - quickThinkDone)
            VStack(spacing: 0) {
                CountingNumber(value: Double(remaining),
                               font: .numeric(30),
                               color: onQuestionsStill ? Palette.accent : Palette.gold)
                Text(onQuestionsStill
                     ? "question\(remaining == 1 ? "" : "s") left"
                     : "quick think\(remaining == 1 ? "" : "s") left")
                    .font(.appSans(10, weight: .medium))
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: Rows

    /// The whole row is the control. Two full-width buttons were the heaviest
    /// thing on the screen and neither was the point; a tinted glyph carries
    /// the affordance and doubles as the key linking the row to its arc.
    private func goalRow(title: String,
                         symbol: String,
                         tint: Color,
                         done: Int,
                         goal: Int,
                         met: Bool,
                         action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    Circle().fill(tint.opacity(met ? 0.14 : 0.18))
                    Image(systemName: met ? "checkmark" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(met ? Palette.success : tint)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.appBodyMedium)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(done) of \(goal)")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(tint.opacity(0.07))
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98, haptic: false))
        .accessibilityLabel("\(title), \(done) of \(goal)")
        .accessibilityHint(met ? "Goal met. Double tap for more."
                               : "Double tap to start.")
    }
}
