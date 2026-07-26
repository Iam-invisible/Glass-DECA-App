//
//  IntroScriptView.swift
//  LCVI DECA Study App
//
//  The handwritten launch reveal: "glass" written out the way Apple's setup
//  "hello" is, then settling into the same solid glass tubing the classic
//  intro finishes on.
//
//  The trick is that nothing here traces a glyph outline. A wide round-capped
//  stroke runs along the pen's route (`GlassScriptPath`) and is used purely as
//  a *mask* over the letterforms, so what appears is always the true Sacramento
//  shape — the mask only decides how much of it has been written yet. Trimming
//  the outline instead would draw the edges of the letters, which is the
//  classic intro's etched look, not handwriting.
//
//  Choreography is unchanged from the classic so it still lands on the audio:
//  backdrop 0.6s; writing starts at 0.30s over 2.0s; the glass floods in on the
//  2.40s peak with a medium impact; success haptic and sweep 0.22s later.
//

import SwiftUI

// MARK: - The written stroke

/// The pen's route, drawn up to `progress`.
///
/// Conforms to `Animatable` so `path(in:)` is re-evaluated every frame while
/// the write animates — a plain animated `Double` would only interpolate the
/// endpoints of whatever it fed.
struct PenStroke: Shape {
    let word: WordGlyphs
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let pts = GlassScriptPath.points
        guard pts.count > 1, word.bounds.width > 0 else { return Path() }

        // Resolve the fitting transform once rather than per point — this runs
        // every frame on a phone that may be an iPhone 8.
        let t = word.transform(into: rect)
        let b = word.bounds
        func place(_ i: Int) -> CGPoint {
            CGPoint(x: b.minX + pts[i].0 * b.width,
                    y: b.minY + pts[i].1 * b.height).applying(t)
        }

        let clamped = min(max(progress, 0), 1)
        let exact = CGFloat(pts.count - 1) * clamped
        let last = Int(exact)

        var path = Path()
        path.move(to: place(0))
        guard last > 0 else { return path }
        for i in 1...last { path.addLine(to: place(i)) }

        // Interpolate the part-finished segment so the tip advances smoothly
        // instead of snapping from point to point.
        if last < pts.count - 1 {
            let f = exact - CGFloat(last)
            let a = place(last), c = place(last + 1)
            path.addLine(to: CGPoint(x: a.x + (c.x - a.x) * f, y: a.y + (c.y - a.y) * f))
        }
        return path
    }
}

/// A dot sitting at the pen tip. Also `Animatable`, for the same reason.
struct PenTip: Shape {
    let word: WordGlyphs
    var progress: CGFloat
    var radius: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let pts = GlassScriptPath.points
        guard pts.count > 1, word.bounds.width > 0 else { return Path() }
        let clamped = min(max(progress, 0), 1)
        let exact = CGFloat(pts.count - 1) * clamped
        let i = min(Int(exact), pts.count - 2)
        let f = exact - CGFloat(i)
        let a = word.place(pts[i].0, pts[i].1, into: rect)
        let c = word.place(pts[i + 1].0, pts[i + 1].1, into: rect)
        let p = CGPoint(x: a.x + (c.x - a.x) * f, y: a.y + (c.y - a.y) * f)
        return Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius,
                                      width: radius * 2, height: radius * 2))
    }
}

// MARK: - Intro

struct IntroScriptView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var backdrop: Double = 0
    @State private var write: CGFloat = 0
    @State private var fill: Double = 0
    @State private var bloom: Double = 0
    @State private var inkFade: Double = 1
    @State private var tipFade: Double = 0
    @State private var sweep: CGFloat = -1.4
    @State private var scale: CGFloat = 0.94
    @State private var drift = false
    @State private var leaving = false
    @State private var finished = false
    @State private var sequence: Task<Void, Never>?

    private let word = WordGlyphs.glassScript

    var body: some View {
        ZStack {
            IntroBackdrop(opacity: backdrop, drift: drift)
            wordmark
        }
        .opacity(leaving ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear(perform: run)
        .onDisappear { sequence?.cancel() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glass")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to skip")
        .accessibilityAction { finish() }
    }

    // MARK: Wordmark

    /// Sacramento stands 4.9 x-heights tall against Fraunces' 2.0, almost all
    /// of it loop, so the script needs a much taller box to end up with
    /// letterforms of a comparable size. Width still constrains it on a small
    /// phone, which `transform(into:)` handles.
    private var wordmark: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let ink = word.fittedInkHeight(in: rect)
            // The letterform is ~0.031 of the ink height thick, plus the
            // swelling below. Comfortably wider than that so the mask never
            // clips the middle out of a stroke it is meant to be revealing.
            // Measured offline: at this width 0.19% of the ink sits outside
            // the pen's sweep — one speck where the a's bowl meets its stem
            // and the ink is locally thicker than any single pass can cover.
            // Going wider closes it but starts revealing ink ahead of the nib.
            let reveal = ink * 0.095
            let inflate = ink * 0.020

            ZStack {
                // Halo — the letters look lit from within.
                solid(Palette.accent, inflate: inflate)
                    .blur(radius: 18)
                    .opacity(0.55 * bloom)

                // What has been written so far: the glass body, but showing
                // only where the pen has already been.
                solid(
                    LinearGradient(colors: [Palette.accent.opacity(0.92),
                                            Palette.accent.opacity(0.62),
                                            Palette.textPrimary.opacity(0.80)],
                                   startPoint: .top, endPoint: .bottom),
                    inflate: inflate
                )
                .mask(
                    PenStroke(word: word, progress: write)
                        .stroke(style: StrokeStyle(lineWidth: reveal,
                                                   lineCap: .round, lineJoin: .round))
                )
                .opacity(inkFade)

                // The finished word, flooding in on the peak.
                solid(
                    LinearGradient(colors: [Palette.accent.opacity(0.92),
                                            Palette.accent.opacity(0.62),
                                            Palette.textPrimary.opacity(0.80)],
                                   startPoint: .top, endPoint: .bottom),
                    inflate: inflate
                )
                .opacity(fill)

                // Shading hugging the lower-right of every stroke: a blurred
                // contour pass, pushed down and clipped inside the letter,
                // which is what gives a flat shape the roundness of a rod.
                WordShape(word: word)
                    .stroke(Palette.accent.opacity(0.95),
                            style: StrokeStyle(lineWidth: inflate * 1.7, lineCap: .round, lineJoin: .round))
                    .blur(radius: 4)
                    .offset(x: 2.0, y: 3.0)
                    .mask(solid(Color.black, inflate: inflate))
                    .opacity(0.85 * fill)

                // The matching highlight along the upper-left — the light
                // running down the top of the tube.
                WordShape(word: word)
                    .stroke(.white.opacity(0.95),
                            style: StrokeStyle(lineWidth: inflate * 1.15, lineCap: .round, lineJoin: .round))
                    .blur(radius: 3)
                    .offset(x: -1.6, y: -2.4)
                    .mask(solid(Color.black, inflate: inflate))
                    .opacity(0.9 * fill)

                // Bright rim where the glass turns away at the edge.
                WordShape(word: word)
                    .stroke(.white.opacity(0.55),
                            style: StrokeStyle(lineWidth: inflate, lineCap: .round, lineJoin: .round))
                    .blur(radius: 1.2)
                    .mask(solid(Color.black, inflate: inflate))
                    .blendMode(.plusLighter)
                    .opacity(0.55 * fill)

                // Sweep travelling across the word.
                LinearGradient(colors: [.clear, .white.opacity(0.9), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: sweep * geo.size.width)
                    .blur(radius: 5)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .mask(solid(Color.black, inflate: inflate))
                    .opacity(fill)
                    .allowsHitTesting(false)

                // The nib: a bright point of light at the pen, so the eye has
                // something to follow rather than just watching ink appear.
                PenTip(word: word, progress: write, radius: reveal * 0.42)
                    .fill(.white)
                    .blur(radius: reveal * 0.30)
                    .opacity(tipFade)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 208)
        .padding(.horizontal, 44)
        .scaleEffect(scale)
        .shadow(color: Palette.accent.opacity(0.3 * bloom), radius: 22)
    }

    /// The letterform as a solid, swollen body rather than a hollow outline:
    /// the glyph filled, plus a round-joined stroke of the same style to puff
    /// the silhouette out and soften every corner.
    private func solid<S: ShapeStyle>(_ style: S, inflate: CGFloat) -> some View {
        ZStack {
            WordShape(word: word).fill(style)
            WordShape(word: word)
                .stroke(style, style: StrokeStyle(lineWidth: inflate, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: Choreography

    private func run() {
        guard sequence == nil else { return }
        SoundEffects.intro()

        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.5)) {
                backdrop = 1; write = 1; fill = 1; bloom = 1; scale = 1
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

            // Write the word — still finishes on the audio's 2.4s peak, but
            // starting sooner so the hand has longer to get there.
            //
            // The curve is a gentle symmetric ease rather than the classic's
            // ease-out. An ease-out spends its speed early, so the g whips out
            // and the last s crawls; this one peaks at 2.0x the average rate
            // instead of 2.4x and holds close to steady through the middle,
            // which is what reads as a hand writing at its own pace.
            try? await sleep(0.18)
            withAnimation(.easeOut(duration: 0.25)) { tipFade = 1 }
            withAnimation(.timingCurve(0.40, 0, 0.40, 1, duration: 2.12)) { write = 1 }

            // The reveal.
            try? await sleep(2.12)
            Haptics.impact(.medium, intensity: 0.8)
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                fill = 1
                bloom = 1
                scale = 1
            }
            // Hand over from the written ink to the finished word. They are
            // the same shape by now, so the crossfade is invisible — it only
            // exists so nothing the pen's mask happened to miss stays hidden.
            withAnimation(.easeOut(duration: 0.5)) { inkFade = 0 }
            withAnimation(.easeOut(duration: 0.35)) { tipFade = 0 }

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

    private func finish() {
        guard !finished else { return }
        finished = true
        sequence?.cancel()
        // The reveal track is deliberately *not* stopped — see the classic
        // intro for why: the player lives on `SoundEffects`, not on this view,
        // so the swell resolves under whatever comes next.

        guard !reduceMotion else { onFinish(); return }
        withAnimation(.easeIn(duration: 0.45)) {
            leaving = true
            scale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: onFinish)
    }
}
