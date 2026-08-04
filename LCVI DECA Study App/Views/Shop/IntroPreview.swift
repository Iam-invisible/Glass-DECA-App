//
//  IntroPreview.swift
//  LCVI DECA Study App
//
//  The two intros, shown rather than described.
//
//  The shop row used to give an intro a flat coloured square, and the preview
//  card gave it a static wordmark plus a sentence saying what it would do.
//  Both are the same failure the icon rows had: the app owns the artwork and
//  the animation, and a swatch standing in front of them means buying the thing
//  to find out what it is. An intro is a *motion*, so a still of it is only
//  half an answer — the preview here actually plays.
//
//  Both views reuse the intro's own primitives — `WordGlyphs`, `WordShape`,
//  `TracedGlyph`, `PenStroke` — so this cannot drift into showing a wordmark
//  the intro does not draw. What it does not reuse is the full layer stack:
//  the real thing carries a halo, three blurred contour passes and a travelling
//  sweep at full screen. At 120pt those read as mud and cost frames on an
//  iPhone 8, so the preview keeps the halo, the body and the sweep and drops
//  the contour passes.
//

import SwiftUI

// MARK: - Still mark

/// The wordmark for a 46pt shop row.
///
/// Etched is drawn as an outline and Script as a filled body, which is what
/// each intro actually does to the letters — so the two rows differ by more
/// than typeface at a size where typeface alone is hard to read.
struct IntroMark: View {
    let isScript: Bool
    var side: CGFloat = 46

    private var word: WordGlyphs { isScript ? .glassScript : .glass }

    var body: some View {
        ZStack {
            if isScript {
                WordShape(word: word)
                    .fill(Palette.accent)
            } else {
                WordShape(word: word)
                    .stroke(Palette.accent, style: StrokeStyle(lineWidth: 1.1,
                                                               lineCap: .round,
                                                               lineJoin: .round))
            }
        }
        .padding(.horizontal, side * 0.14)
        .padding(.vertical, side * 0.30)
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

// MARK: - Playing reveal

/// The intro's reveal, at card size.
///
/// Runs on appear and again whenever `playToken` changes, so the card can offer
/// a replay without this view owning a button.
struct IntroReveal: View {
    let isScript: Bool
    let playToken: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var write: CGFloat = 0
    @State private var fill: Double = 0
    @State private var bloom: Double = 0
    @State private var inkFade: Double = 1
    @State private var sweep: CGFloat = -1.4
    @State private var run: Task<Void, Never>?

    private var word: WordGlyphs { isScript ? .glassScript : .glass }

    /// The glass gradient both intros pour into the letters.
    private var glass: LinearGradient {
        LinearGradient(colors: [Palette.accent.opacity(0.92),
                                Palette.accent.opacity(0.62),
                                Palette.textPrimary.opacity(0.80)],
                       startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let ink = word.fittedInkHeight(in: rect)
            let inflate = ink * 0.020
            let reveal = ink * 0.095

            ZStack {
                solid(glass, inflate: inflate)
                    .blur(radius: 9)
                    .opacity(0.5 * bloom)

                if isScript {
                    // Only where the nib has already been. Same mask the real
                    // script intro uses, at the same proportion of ink height.
                    solid(glass, inflate: inflate)
                        .mask(
                            PenStroke(word: word, progress: write)
                                .stroke(style: StrokeStyle(lineWidth: reveal,
                                                           lineCap: .round,
                                                           lineJoin: .round))
                        )
                        .opacity(inkFade)
                } else {
                    // The hairline being etched, letter after letter.
                    ForEach(word.glyphs.indices, id: \.self) { index in
                        TracedGlyph(word: word, index: index, trimEnd: letterTrim(index))
                            .stroke(
                                LinearGradient(colors: [Palette.accent, Palette.textPrimary],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round)
                            )
                            .opacity(inkFade)
                    }
                }

                solid(glass, inflate: inflate)
                    .opacity(fill)

                // The band has to be positioned inside a full-size container
                // and the mask applied to *that*, not to the band.
                //
                // Masking the band directly puts the mask through the band's
                // own layout, so `WordShape` fits the whole word into a box
                // 40% of the width — and a squashed little wordmark rides
                // across the letters as a white block. This is the shape the
                // real intro uses for the same reason.
                GeometryReader { sweepBox in
                    LinearGradient(colors: [.clear, .white.opacity(0.85), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: sweepBox.size.width * 0.4)
                        .offset(x: sweep * sweepBox.size.width)
                        .blur(radius: 4)
                }
                .mask(solid(Color.black, inflate: inflate))
                .opacity(fill)
                .allowsHitTesting(false)
            }
        }
        .frame(height: 92)
        .padding(.horizontal, 26)
        .onAppear { start() }
        .onChange(of: playToken) { _ in start() }
        .onDisappear { run?.cancel(); run = nil }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isScript ? "The word glass, written by hand and filled"
                                     : "The word Glass, traced and filled")
    }

    /// The letterform as a swollen body rather than a hollow outline: filled,
    /// plus a round-joined stroke of the same style to puff the silhouette out.
    private func solid<S: ShapeStyle>(_ style: S, inflate: CGFloat) -> some View {
        ZStack {
            WordShape(word: word).fill(style)
            WordShape(word: word)
                .stroke(style, style: StrokeStyle(lineWidth: inflate,
                                                  lineCap: .round, lineJoin: .round))
        }
    }

    /// Word-level progress into a per-letter trim, so the etch runs in sequence
    /// rather than every letter at once. Only the classic reveal uses it.
    private func letterTrim(_ index: Int) -> CGFloat {
        guard word.glyphs.count > 1 else { return write }
        let span = 0.42
        let step = (1.0 - span) / Double(word.glyphs.count - 1)
        let local = (Double(write) - Double(index) * step) / span
        return CGFloat(min(max(local, 0), 1))
    }

    /// The real choreography at about two thirds the duration.
    ///
    /// The intro writes for 2.0s and then holds, because it is covering a cold
    /// launch and is scored to a 2.4s audio peak. Neither applies in a card the
    /// student opened on purpose and can replay, and two seconds of watching a
    /// line move is long when it is not the first thing you have seen. The
    /// curves and the order are the intro's own.
    private func start() {
        run?.cancel()

        guard !reduceMotion else {
            write = 1; fill = 1; bloom = 1; inkFade = 0; sweep = 1.4
            return
        }

        write = 0; fill = 0; bloom = 0; inkFade = 1; sweep = -1.4

        run = Task { @MainActor in
            withAnimation(isScript ? .timingCurve(0.40, 0, 0.40, 1, duration: 1.40)
                                   : .timingCurve(0.35, 0, 0.25, 1, duration: 1.32)) {
                write = 1
            }
            try? await Task.sleep(nanoseconds: UInt64(1.34 * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                fill = 1
                bloom = 1
            }
            // The etched hairline stays faintly visible under the glass, the
            // way it does at full size; the script's ink hands over completely,
            // because by then it is the same shape as the fill behind it.
            withAnimation(.easeOut(duration: isScript ? 0.5 : 0.9)) {
                inkFade = isScript ? 0 : 0.45
            }

            try? await Task.sleep(nanoseconds: UInt64(0.22 * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 1.0)) { sweep = 1.4 }
        }
    }
}
