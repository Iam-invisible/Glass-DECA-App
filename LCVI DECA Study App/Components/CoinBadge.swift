//
//  CoinBadge.swift
//  LCVI DECA Study App
//
//  The coin balance, pinned to the top-right of every screen that can earn
//  coins, plus the refusal shake the shop uses when you cannot afford
//  something.
//

import SwiftUI

// MARK: - Badge

/// A floating balance. It sits above the scrolling content rather than inside
/// it, so it survives a scroll — a counter that scrolls away is a header, not
/// a HUD, and the point is being able to see the number at all times.
///
/// It deliberately does not appear on Settings: nothing there earns coins, and
/// a currency that follows you into the preferences screen reads as a nag.
struct CoinBadge: View {
    let coins: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bumped = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Palette.gold)
            // CountingNumber animates the digits rather than swapping them, so
            // earning reads as a tick upward instead of a jump. It carries its
            // own font and colour — it is a view, not a Text.
            CountingNumber(value: Double(coins),
                           font: .numeric(14, weight: .semibold),
                           color: Palette.textPrimary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(Palette.card)
                .overlay(Capsule(style: .continuous).strokeBorder(Palette.stroke, lineWidth: 0.5))
                .shadow(color: Palette.shadow.opacity(0.14), radius: 8, y: 3)
        )
        .scaleEffect(bumped && !reduceMotion ? 1.12 : 1)
        .onChange(of: coins) { _ in
            guard !reduceMotion else { return }
            withAnimation(Motion.bouncy) { bumped = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(Motion.gentle) { bumped = false }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(coins) coins")
    }
}

// MARK: - Refusal shake

/// A damped oscillation, not a wobble.
///
/// The first version offset the tile 6pt and back, which reads as a glitch.
/// This is the real thing: amplitude decays as `e^(-decay·t)` while the tile
/// crosses centre `oscillations` times, so it starts sharp and settles — the
/// motion of something that was pushed and sprang back.
///
/// It is a `GeometryEffect` rather than a plain modifier because only
/// `Animatable` types get their body re-evaluated every frame; a modifier
/// reading a `@State` offset would jump between two positions instead of
/// travelling. Same reason `CountingNumber` and `TracedGlyph` conform.
struct RefusalShake: GeometryEffect {
    /// 0 → 1 across the whole shake.
    var progress: CGFloat
    var amplitude: CGFloat = 11
    var oscillations: CGFloat = 3
    var decay: CGFloat = 4.2

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard progress > 0, progress < 1 else { return ProjectionTransform(.identity) }
        let dx = amplitude
            * exp(-decay * progress)
            * sin(progress * oscillations * 2 * .pi)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}
