//
//  StatusBarScrim.swift
//  LCVI DECA Study App
//
//  A short fade under the status bar so the clock, signal and battery stay
//  readable while content scrolls beneath them.
//
//  Once the root tabs started drawing their own titles, the system navigation
//  bar went away — and with it the opaque strip that used to sit behind the
//  status bar. Cards now scroll all the way up, so a dark card passing under
//  the time made it briefly unreadable, and the app looked like it had no top
//  edge at all.
//
//  This is a gradient of the canvas colour rather than a material. A blurred
//  strip across the full width would be recomputed every frame that anything
//  moves beneath it, which on an A11 is the same class of cost as the card
//  shadows that were making scrolling stutter. A gradient is a single cheap
//  fill and reads as the content receding rather than as a bar.
//
//  It ends fully transparent, so nothing is hidden — content is still visible
//  through it as it scrolls away, which is the point.
//

import SwiftUI

struct StatusBarScrim: View {
    /// How far past the status bar the fade runs before it reaches nothing.
    var falloff: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let inset = geo.safeAreaInsets.top
            LinearGradient(
                stops: [
                    // Solid across the status bar itself, then away quickly —
                    // an even fade over the whole height reads as a grey haze
                    // rather than as an edge.
                    .init(color: Palette.canvas, location: 0),
                    .init(color: Palette.canvas.opacity(0.96),
                          location: inset > 0 ? inset / (inset + falloff) : 0.55),
                    .init(color: Palette.canvas.opacity(0), location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: inset + falloff)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
        }
        // Purely decorative: it must never eat a tap meant for the content
        // underneath, and VoiceOver has no reason to know it exists.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
