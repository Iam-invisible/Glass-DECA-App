//
//  GoalDial.swift
//  LCVI DECA Study App
//
//  One daily goal: a ring showing today's progress, a button that starts the
//  work, and a slider that sets the target.
//
//  The home screen carries two of these side by side — questions and Quick
//  Thinks — because they are the two things a student does daily and they
//  were previously buried: the questions goal was only adjustable in
//  Settings, and Quick Think had no goal at all. Putting the slider on the
//  card means the target is tuned where it is felt, on the morning a
//  student decides today is a light day.
//
//  The slider is deliberately not a stepper: a goal is a rough intention,
//  and dragging expresses that better than tapping a plus button eleven
//  times.
//

import SwiftUI

struct GoalDial: View {
    let title: String
    let systemImage: String
    /// Completed today.
    let done: Int
    /// Target, bound so the slider can move it.
    @Binding var goal: Int
    let range: ClosedRange<Int>
    let tint: Color
    /// Label under the ring — "questions", "Quick Thinks".
    let unit: String
    let actionTitle: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var met: Bool { done >= max(range.lowerBound, goal) }
    private var fraction: Double {
        let target = max(1, goal)
        return min(1, Double(done) / Double(target))
    }

    var body: some View {
        VStack(spacing: 11) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(met ? Palette.success : tint)
                Text(title)
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }

            ZStack {
                ProgressRing(progress: fraction,
                             lineWidth: 9,
                             tint: met ? Palette.success : tint)
                    .frame(width: 84, height: 84)
                VStack(spacing: -1) {
                    CountingNumber(value: Double(done),
                                   font: .numeric(24),
                                   color: Palette.textPrimary)
                    Text("of \(goal)")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                        .monospacedDigit()
                }
            }

            // Slider over Stepper on purpose — see the type's note.
            VStack(spacing: 2) {
                Slider(value: Binding(get: { Double(goal) },
                                      set: { goal = Int($0.rounded()) }),
                       in: Double(range.lowerBound)...Double(range.upperBound),
                       step: 1)
                    .tint(tint)
                    .accessibilityLabel("\(title) target")
                    .accessibilityValue("\(goal) \(unit)")
                Text(unit)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }

            PrimaryButton(title: actionTitle,
                          systemImage: met ? "checkmark" : "play.fill",
                          tint: tint,
                          isProminent: !met) {
                action()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Palette.shadow.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [met ? Palette.success.opacity(0.45) : Palette.strokeGlint,
                                            Palette.stroke],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
        .animation(reduceMotion ? nil : Motion.gentle, value: met)
        .accessibilityElement(children: .contain)
    }
}
