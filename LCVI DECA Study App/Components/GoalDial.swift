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
        // Deliberately uneven rhythm rather than one uniform gap. The label
        // belongs to the top edge, so it sits close to it; the ring is the
        // subject and needs air on both sides to read as the centre of the
        // card; the button is a separate act and takes the largest gap. A
        // single spacing value made all three feel like a list.
        VStack(spacing: 0) {
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
            .padding(.bottom, 15)

            ZStack {
                ProgressRing(progress: fraction,
                             lineWidth: 9,
                             tint: met ? Palette.success : tint)
                    .frame(width: 86, height: 86)
                VStack(spacing: 1) {
                    CountingNumber(value: Double(done),
                                   font: .numeric(25),
                                   color: Palette.textPrimary)
                    Text("of \(goal)")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                        .monospacedDigit()
                }
            }
            .padding(.bottom, 18)

            startButton
        }
        // No card. The ring is already a strong closed shape and the start
        // button is a filled capsule, so both read as objects without a panel
        // behind them — the border was outlining things that had their own
        // outline. The horizontal inset went with it: with no card edge to
        // clear, it was only making the button narrower than its column.
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? nil : Motion.gentle, value: met)
        .accessibilityElement(children: .contain)
    }
}
