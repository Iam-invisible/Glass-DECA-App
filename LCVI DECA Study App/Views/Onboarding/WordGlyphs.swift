//
//  WordGlyphs.swift
//  LCVI DECA Study App
//
//  Vector plumbing shared by the two intro reveals: a word turned into glyph
//  outlines in one coordinate space, plus the shapes that draw them.
//
//  Both intros fit the same way — `transform(into:)` maps the word's ink
//  bounds into the view rect without distorting the letterforms — so anything
//  else expressed in those bounds (the handwriting stroke in
//  `GlassScriptPath`) lines up with the letters for free.
//

import CoreText
import SwiftUI
import UIKit

// MARK: - Glyph outlines

/// The word broken into per-glyph vector outlines, in one shared coordinate
/// space so they can be traced individually but stay aligned.
struct WordGlyphs {
    let glyphs: [CGPath]
    let bounds: CGRect

    /// The classic reveal: a serif wordmark whose outlines get etched.
    static let glass = make("Glass", fontName: AppType.display, size: 260)

    /// The handwritten reveal. Lowercase, because the script's capital G is a
    /// large open flourish that dominates the word — and because Apple's own
    /// greeting is lowercase for the same reason.
    static let glassScript = make("glass", fontName: AppType.script, size: 260)

    static func make(_ text: String, fontName: String, size: CGFloat) -> WordGlyphs {
        guard let uiFont = UIFont(name: fontName, size: size) else {
            return WordGlyphs(glyphs: [], bounds: .zero)
        }
        let attributed = NSAttributedString(string: text, attributes: [.font: uiFont])
        let line = CTLineCreateWithAttributedString(attributed)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else {
            return WordGlyphs(glyphs: [], bounds: .zero)
        }

        var out: [CGPath] = []
        // Core Text is y-up; SwiftUI is y-down.
        let flip = CGAffineTransform(scaleX: 1, y: -1)

        for run in runs {
            let attrs = CTRunGetAttributes(run) as NSDictionary
            guard let runFont = attrs[kCTFontAttributeName as String] else { continue }
            let ctFont = runFont as! CTFont

            let count = CTRunGetGlyphCount(run)
            var ids = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &ids)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)

            for i in 0..<count {
                guard let glyph = CTFontCreatePathForGlyph(ctFont, ids[i], nil) else { continue }
                var transform = CGAffineTransform(translationX: positions[i].x, y: positions[i].y)
                    .concatenating(flip)
                if let placed = glyph.copy(using: &transform) {
                    out.append(placed)
                }
            }
        }

        let union = out.reduce(CGRect.null) { $0.union($1.boundingBox) }
        return WordGlyphs(glyphs: out, bounds: union.isNull ? .zero : union)
    }

    /// Fits the shared bounds into `rect` without distorting the letterforms.
    func transform(into rect: CGRect) -> CGAffineTransform {
        guard bounds.width > 0, bounds.height > 0 else { return .identity }
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        return CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: rect.midX, y: rect.midY))
    }

    /// Maps a point expressed in normalised ink-bounds space (0...1, y-down)
    /// into the same fitted rect the letterforms land in.
    func place(_ nx: CGFloat, _ ny: CGFloat, into rect: CGRect) -> CGPoint {
        let p = CGPoint(x: bounds.minX + nx * bounds.width,
                        y: bounds.minY + ny * bounds.height)
        return p.applying(transform(into: rect))
    }

    /// How tall the ink actually ends up once fitted. The word may be
    /// constrained by either axis, so anything sized against the letterforms
    /// — stroke weights, the reveal width — has to measure this rather than
    /// the frame it was given.
    func fittedInkHeight(in rect: CGRect) -> CGFloat {
        guard bounds.width > 0, bounds.height > 0 else { return rect.height }
        return bounds.height * min(rect.width / bounds.width, rect.height / bounds.height)
    }
}

/// One glyph's outline, drawn up to `trimEnd`.
struct TracedGlyph: Shape {
    let word: WordGlyphs
    let index: Int
    var trimEnd: CGFloat

    var animatableData: CGFloat {
        get { trimEnd }
        set { trimEnd = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard word.glyphs.indices.contains(index) else { return Path() }
        var t = word.transform(into: rect)
        guard let placed = word.glyphs[index].copy(using: &t) else { return Path() }
        let full = Path(placed)
        guard trimEnd < 1 else { return full }
        return full.trimmedPath(from: 0, to: max(0.0001, trimEnd))
    }
}

/// The whole word as one filled shape — used for fills and as a mask.
struct WordShape: Shape {
    let word: WordGlyphs

    func path(in rect: CGRect) -> Path {
        var t = word.transform(into: rect)
        let combined = CGMutablePath()
        for glyph in word.glyphs {
            if let placed = glyph.copy(using: &t) { combined.addPath(placed) }
        }
        return Path(combined)
    }
}
