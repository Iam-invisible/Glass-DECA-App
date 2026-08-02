//
//  IntroClassicView.swift
//  LCVI DECA Study App
//
//  The original launch reveal: "Glass" traced out in the display serif, then
//  filled in as glass. Kept intact and selectable in Settings alongside the
//  handwritten reveal — this one is the fallback if the new one does not land.
//
//  Apple's setup "hello" works because it's a single script stroke being
//  written. Instrument Serif is a serif, so its glyphs are closed outlines
//  rather than a handwriting path — tracing those draws the *edge* of each
//  letter instead. That reads as etching rather than handwriting, which suits
//  the name anyway: the letters appear cut into glass, then fill with light.
//
//  The choreography is timed to the audio, which swells from 0.3s and peaks at
//  2.4s — the trace finishes exactly on that hit.
//

import CoreText
import SwiftUI
import UIKit

// MARK: - Intro

struct IntroClassicView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var backdrop: Double = 0
    @State private var trace: CGFloat = 0
    @State private var fill: Double = 0
    @State private var bloom: Double = 0
    @State private var strokeFade: Double = 1
    @State private var sweep: CGFloat = -1.4
    @State private var scale: CGFloat = 0.94
    @State private var drift = false
    @State private var leaving = false
    @State private var finished = false
    @State private var sequence: Task<Void, Never>?

    private let word = WordGlyphs.glass
    /// Letters overlap slightly so it reads as one continuous hand.
    private var letterSpan: Double { 1.0 / Double(max(1, word.glyphs.count)) * 1.9 }

    var body: some View {
        ZStack {
            IntroBackdrop(opacity: backdrop, drift: drift)
            wordmark
        }
        .opacity(leaving ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { finish(skipped: true) }
        .onAppear(perform: run)
        .onDisappear { sequence?.cancel() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glass")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to skip")
        .accessibilityAction { finish(skipped: true) }
    }

    // MARK: Wordmark

    /// How far the letterforms puff outward. Stroking the filled shape with a
    /// round join swells it and rounds off the serifs and flat terminals,
    /// which is what turns a printed letter into something that looks blown
    /// from glass rod.
    private let inflate: CGFloat = 5

    private var wordmark: some View {
        ZStack {
            // Halo — the letters look lit from within.
            solid(Palette.accent)
                .blur(radius: 18)
                .opacity(0.55 * bloom)

            // The glass itself.
            solid(
                LinearGradient(colors: [Palette.accent.opacity(0.92),
                                        Palette.accent.opacity(0.62),
                                        Palette.textPrimary.opacity(0.80)],
                               startPoint: .top, endPoint: .bottom)
            )
            .opacity(fill)

            // Shading hugging the lower-right of every stroke: a blurred
            // contour pass, pushed down and clipped inside the letter, which
            // is what gives a flat shape the roundness of a rod.
            WordShape(word: word)
                .stroke(Palette.accent.opacity(0.95),
                        style: StrokeStyle(lineWidth: inflate * 1.7, lineCap: .round, lineJoin: .round))
                .blur(radius: 4)
                .offset(x: 2.0, y: 3.0)
                .mask(solid(Color.black))
                .opacity(0.85 * fill)

            // The matching highlight along the upper-left — the light running
            // down the top of the tube.
            WordShape(word: word)
                .stroke(.white.opacity(0.95),
                        style: StrokeStyle(lineWidth: inflate * 1.15, lineCap: .round, lineJoin: .round))
                .blur(radius: 3)
                .offset(x: -1.6, y: -2.4)
                .mask(solid(Color.black))
                .opacity(0.9 * fill)

            // Bright rim where the glass turns away at the edge.
            WordShape(word: word)
                .stroke(.white.opacity(0.55),
                        style: StrokeStyle(lineWidth: inflate, lineCap: .round, lineJoin: .round))
                .blur(radius: 1.2)
                .mask(solid(Color.black))
                .blendMode(.plusLighter)
                .opacity(0.55 * fill)

            // Sweep travelling across the word.
            GeometryReader { geo in
                LinearGradient(colors: [.clear, .white.opacity(0.9), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: sweep * geo.size.width)
                    .blur(radius: 5)
            }
            .mask(solid(Color.black))
            .opacity(fill)
            .allowsHitTesting(false)

            // The hairline being written, before the glass pours in behind it.
            ForEach(word.glyphs.indices, id: \.self) { index in
                TracedGlyph(word: word, index: index, trimEnd: letterTrim(index))
                    .stroke(
                        LinearGradient(colors: [Palette.accent, Palette.textPrimary],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
                    )
                    .opacity(strokeFade)
            }
        }
        .frame(height: 104)
        .padding(.horizontal, 62)
        .scaleEffect(scale)
        .shadow(color: Palette.accent.opacity(0.3 * bloom), radius: 22)
    }

    /// The letterform as a solid, swollen body rather than a hollow outline:
    /// the glyph filled, plus a round-joined stroke of the same style to puff
    /// the silhouette out and soften every corner.
    private func solid<S: ShapeStyle>(_ style: S) -> some View {
        ZStack {
            WordShape(word: word).fill(style)
            WordShape(word: word)
                .stroke(style, style: StrokeStyle(lineWidth: inflate, lineCap: .round, lineJoin: .round))
        }
    }

    /// Converts the single word-level progress into a per-letter trim, so the
    /// letters are written in sequence rather than all at once.
    private func letterTrim(_ index: Int) -> CGFloat {
        guard word.glyphs.count > 1 else { return trace }
        let step = (1.0 - letterSpan) / Double(word.glyphs.count - 1)
        let start = Double(index) * step
        let local = (Double(trace) - start) / letterSpan
        return CGFloat(min(max(local, 0), 1))
    }

    // MARK: Choreography

    private func run() {
        guard sequence == nil else { return }
        SoundEffects.intro()

        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.5)) {
                backdrop = 1; trace = 1; fill = 1; bloom = 1; scale = 1
            }
            sequence = Task { @MainActor in
                try? await sleep(2.8)
                finish()
            }
            return
        }

        sequence = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.6)) { backdrop = 1 }
            drift = true

            // Write the letters — finishes on the audio's 2.4s peak.
            try? await sleep(0.30)
            withAnimation(.timingCurve(0.35, 0, 0.25, 1, duration: 2.0)) { trace = 1 }

            // The reveal.
            try? await sleep(2.00)
            Haptics.impact(.medium, intensity: 0.8)
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                fill = 1
                bloom = 1
                scale = 1
            }
            withAnimation(.easeOut(duration: 0.9)) { strokeFade = 0.45 }

            try? await sleep(0.22)
            Haptics.success()
            withAnimation(.easeInOut(duration: 1.0)) { sweep = 1.4 }

            // Hold, then hand over.
            try? await sleep(2.0)
            finish()
        }
    }

    private func sleep(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func finish(skipped: Bool = false) {
        guard !finished else { return }
        finished = true
        sequence?.cancel()
        // A finished intro still lets the track resolve under whatever comes
        // next: the reveal is 6.7s against 2.6s of choreography, and that
        // overhang is the point — the player lives on `SoundEffects`, not on
        // this view. Tapping away is the opposite intent, so a skip takes the
        // audio with it. The fade matches the departure animation so picture
        // and sound leave together; Reduce Motion has no departure to match,
        // so it gets a short one rather than a tail over the next screen.
        if skipped {
            SoundEffects.stop(.intro, fadeDuration: reduceMotion ? 0.2 : 0.45)
        }

        guard !reduceMotion else { onFinish(); return }
        withAnimation(.easeIn(duration: 0.45)) {
            leaving = true
            scale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: onFinish)
    }
}
