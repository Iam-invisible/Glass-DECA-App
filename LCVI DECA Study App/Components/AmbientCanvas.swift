//
//  AmbientCanvas.swift
//  LCVI DECA Study App
//
//  The light field every screen sits in.
//
//  The intro opens on drifting pools of coloured light behind the wordmark —
//  and then every screen after it used to be a flat grey wall, as if the
//  reveal happened somewhere else. This puts the same scene behind the whole
//  app, quiet enough to read over: three soft pools of the palette's meaning
//  colours, drifting on a half-minute cycle. Cards then read as panes of
//  glass resting on lit space rather than rectangles on a wall.
//
//  Performance, because this ships to an iPhone 8: the circles are static
//  content — only their *offset* animates, so Core Animation blurs each one
//  once, caches the raster, and just moves it. No per-frame blur. This is the
//  exact recipe the intro backdrop already ships on the same hardware; the
//  only differences are lower opacity and a much slower cycle.
//
//  Reduce Motion keeps the light but parks it.
//

import SwiftUI

struct AmbientCanvas: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        ZStack {
            Palette.canvas

            pool(Palette.accent,  size: 340, x: -130, y: -230, delay: 0)
            pool(Palette.gold,    size: 260, x:  150, y:  260, delay: 4)
            pool(Palette.success, size: 220, x:  170, y: -280, delay: 8)
        }
        .ignoresSafeArea()
        .onAppear { drift = true }
        .accessibilityHidden(true)
    }

    private func pool(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat, delay: Double) -> some View {
        Circle()
            .fill(color.opacity(0.11))
            .frame(width: size, height: size)
            .blur(radius: 70)
            .offset(x: x + (drift ? 16 : -16), y: y + (drift ? -20 : 20))
            .animation(reduceMotion ? nil
                       : .easeInOut(duration: 26).repeatForever(autoreverses: true).delay(delay),
                       value: drift)
    }
}
