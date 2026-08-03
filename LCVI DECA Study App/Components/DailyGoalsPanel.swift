//
//  DailyGoalsPanel.swift
//  LCVI DECA Study App
//
//  The day's two goals as one object.
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

import SwiftUI

struct DailyGoalsPanel: View {
    let questionsDone: Int
    let questionsGoal: Int
    let quickThinkDone: Int
    let quickThinkGoal: Int
    /// False for events with no roleplay component — then this is a single
    /// ring and a single row, not a hollowed-out version of the pair.
    let showsQuickThink: Bool
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
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
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
