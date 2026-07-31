//
//  GoalDial.swift
//  LCVI DECA Study App
//
//  One daily goal: a ring showing today's progress and a button that starts
//  the work.
//
//  The home screen carries two of these side by side — questions and Quick
//  Thinks — because they are the two things a student does daily.
//
//  The dial reports; it does not configure. A slider lived here briefly and
//  was wrong: the home screen is opened many times a day to see where the
//  day stands, and a goal is set once and then left alone. Mixing the two
//  put a draggable control under a thumb that was only ever reaching for
//  the start button. Both targets are adjusted with steppers in Settings.
//

import SwiftUI

struct GoalDial: View {
    let title: String
    let systemImage: String
    /// Completed today.
    let done: Int
    /// Today's target, set in Settings.
    let goal: Int
    let tint: Color
    let actionTitle: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Deliberately smaller than `PrimaryButton`: two of these sit side by
    /// side, and a pair of full-height primaries dominated the screen above
    /// the fold. A compact capsule still clears the 44pt touch target once
    /// its padding is counted, and the ring stays the loudest thing on the
    /// card — which is the point of the card.
    private var startButton: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: met ? "checkmark" : "play.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(actionTitle)
                    .font(.appFootnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(met ? tint : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                Capsule(style: .continuous)
                    .fill(met ? tint.opacity(0.14) : tint)
            )
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
        .accessibilityLabel(actionTitle)
    }

    private var met: Bool { done >= max(1, goal) }
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

            startButton
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
