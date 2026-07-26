//
//  IntroBackdrop.swift
//  LCVI DECA Study App
//
//  The soft coloured bubbles behind whichever wordmark is being revealed.
//  Shared by both intros so the two only differ in how the word arrives, not
//  in what it arrives on.
//

import SwiftUI

struct IntroBackdrop: View {
    /// Faded in by the caller as the first beat of the sequence.
    var opacity: Double
    /// Flipped once on appear; the bubbles then drift forever.
    var drift: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Palette.canvas

            // Soft bubbles drifting behind the glass.
            bubble(color: Palette.accent, size: 320, x: -110, y: -180, delay: 0)
            bubble(color: Palette.gold, size: 240, x: 130, y: 210, delay: 0.6)
            bubble(color: Palette.success, size: 200, x: 150, y: -240, delay: 1.2)

            RadialGradient(colors: [.clear, Palette.canvas.opacity(0.85)],
                           center: .center, startRadius: 90, endRadius: 420)
        }
        .opacity(opacity)
        .ignoresSafeArea()
    }

    private func bubble(color: Color, size: CGFloat, x: CGFloat, y: CGFloat, delay: Double) -> some View {
        Circle()
            .fill(color.opacity(0.20))
            .frame(width: size, height: size)
            .blur(radius: 70)
            .offset(x: x + (drift ? 18 : -18), y: y + (drift ? -22 : 22))
            .animation(reduceMotion ? nil
                       : .easeInOut(duration: 6).repeatForever(autoreverses: true).delay(delay),
                       value: drift)
    }
}
