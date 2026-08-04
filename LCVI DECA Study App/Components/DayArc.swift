//
//  DayArc.swift
//  LCVI DECA Study App
//
//  The day as one smooth semicircle, with the figure sitting in its well.
//
//  Half a ring, because the bottom half was holding nothing and the well the
//  top half leaves is where the number goes — so the shape and the figure read
//  as one object rather than as a chart with a caption under it.
//
//  One arc, not one per goal and not one per question. It was cut into a
//  segment per item before this, and segments answered "how much is one
//  question worth", which a smooth sweep cannot. That is a real thing to give
//  up; what it buys is a shape that reads as a single object at a glance
//  instead of a row of ticks. Both goals feed the same sweep, so the arc is
//  the day rather than a stacked chart of two jobs — the cards underneath are
//  where the split is stated, and the figure's tint says which goal is still
//  counting down.
//

import SwiftUI

struct DayArc: View {
    /// How far through the whole day's work, 0...1.
    let progress: Double
    let tint: Color

    var diameter: CGFloat = 290
    var lineWidth: CGFloat = 16
    var track: Color = Palette.cardSunken

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A `Circle` path is parameterised from three o'clock and runs clockwise,
    /// so the top half — nine o'clock over twelve to three — is the second half
    /// of the trim range, and needs no rotation to start on the left.
    private static let start: CGFloat = 0.5
    private static let sweep: CGFloat = 0.5

    private var filled: CGFloat { CGFloat(min(1, max(0, progress))) }

    var body: some View {
        ZStack {
            arc(to: Self.sweep)
                .stroke(track, style: stroke)

            // A zero-length trim with a round cap still paints a dot, which
            // would leave a bead of colour sitting on an untouched day.
            if filled > 0 {
                arc(to: Self.sweep * filled)
                    .stroke(tint, style: stroke)
                    .animation(reduceMotion ? nil : Motion.gentle, value: filled)
            }
        }
        .frame(width: diameter, height: diameter)
        // Only the top half carries ink, so the bottom half is cropped out of
        // the layout rather than reserved. The round caps do reach half a line
        // width below the horizontal diameter, which is why this crops to the
        // radius rather than clipping — a clip would shear them flat.
        .frame(height: diameter / 2, alignment: .top)
    }

    private var stroke: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    /// Inset by half the line width before trimming. `.stroke` centres the line
    /// on the path (§8.18), so an uninset circle paints half a line width of
    /// arc above its own frame and into whatever sits over it.
    private func arc(to length: CGFloat) -> some Shape {
        Circle().inset(by: lineWidth / 2)
            .trim(from: Self.start, to: Self.start + length)
    }
}
