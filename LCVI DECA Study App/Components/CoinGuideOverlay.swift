//
//  CoinGuideOverlay.swift
//  LCVI DECA Study App
//
//  What tapping the coin balance opens: where coins come from, and how many.
//
//  Every figure is read from `CoinRate` rather than typed out. A rates table
//  that is written twice is a rates table that will disagree with itself the
//  first time one of the numbers is tuned, and the version the student reads
//  is the one that would be wrong.
//

import SwiftUI

struct CoinGuideOverlay: View {
    let coins: Int
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// Source of truth is `CoinRate`; only the wording lives here.
    ///
    /// Note the first two rows are alternatives, not a sum: a correct answer
    /// pays `correctAnswer` *instead of* `answer`, so listing "+1 to answer,
    /// +2 more if right" would overstate what a right answer is worth.
    private var rows: [(symbol: String, title: String, detail: String, amount: Int)] {
        [
            ("checkmark.circle.fill", "Answer correctly", "Every right answer",           CoinRate.correctAnswer),
            ("circle.dashed",         "Answer anything",  "Wrong ones still pay",         CoinRate.answer),
            ("target",                "Finish the day",   "Hit your daily question goal", CoinRate.dailyGoal),
            ("rosette",               "Unlock a badge",   "Each achievement",             CoinRate.achievement),
            ("flame.fill",            "Reach a streak mark",
             "Every \(StreakRules.daysPerFreeze) days in a row",                          CoinRate.streakMilestone),
        ]
    }

    var body: some View {
        ZStack {
            // Translucent rather than opaque: the screen underneath stays
            // legible, so this reads as a panel over the app rather than as a
            // new place you navigated to.
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Palette.shadow.opacity(0.28))
                .ignoresSafeArea()
                .onTapGesture { close() }
                .accessibilityLabel("Close")
                .accessibilityAddTraits(.isButton)

            card
                .padding(.horizontal, Metrics.gutter)
                .scaleEffect(shown || reduceMotion ? 1 : 0.94)
                .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : Motion.bouncy) { shown = true }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Metrics.stackSpacing) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Earning coins")
                        .font(.appTitle)
                        .foregroundStyle(Palette.textPrimary)
                    Text("Coins only come from studying.")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.gold)
                    Text("\(coins)")
                        .font(.numeric(17, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 { Divider().overlay(Palette.stroke) }
                    HStack(spacing: 12) {
                        Image(systemName: row.symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.gold)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.title)
                                .font(.appBodyMedium)
                                .foregroundStyle(Palette.textPrimary)
                            Text(row.detail)
                                .font(.appCaption)
                                .foregroundStyle(Palette.textTertiary)
                        }
                        Spacer(minLength: 8)
                        Text("+\(row.amount)")
                            .font(.numeric(16, weight: .semibold))
                            .foregroundStyle(Palette.gold)
                    }
                    .padding(.vertical, 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(row.title), \(row.detail), \(row.amount) coins")
                }
            }

            Text("Spend them in the Shop. Nothing in this app costs real money.")
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                close()
            } label: {
                Text("Done")
                    .font(.appHeadline)
                    .foregroundStyle(Palette.card)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Palette.accent))
            }
            .buttonStyle(PressableButtonStyle(haptic: false))
        }
        .appCard(padding: 18)
    }

    private func close() {
        Haptics.tap()
        withAnimation(reduceMotion ? nil : Motion.quick) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: onClose)
    }
}
