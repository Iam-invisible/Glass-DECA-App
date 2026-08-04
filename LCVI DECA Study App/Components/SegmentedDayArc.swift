//
//  SegmentedDayArc.swift
//  LCVI DECA Study App
//
//  The day as a half ring, cut into a segment per thing to do.
//
//  Same idea as `SegmentedGoalRing` and the same reason for it: a continuous
//  track answers "how far through am I" and nothing else, while segments answer
//  "how much is one question worth" — the question a student acts on. A single
//  lit segment on a fresh day is visible where a 1/20th sliver is not.
//
//  Half of it, because the bottom half of a full ring was holding nothing. The
//  arc keeps the object — one shape means one day — and the well underneath is
//  where the figure sits, so the two read as one thing rather than as a chart
//  with a caption. A 250pt circle costs 250pt of height; this costs 132.
//

import SwiftUI

struct SegmentedDayArc: View {
    let sections: [SegmentedGoalRing.Section]
    var diameter: CGFloat = 250
    var lineWidth: CGFloat = 14
    var track: Color = Palette.cardSunken

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A `Circle` path is parameterised from three o'clock and runs clockwise,
    /// so the top half — nine o'clock over twelve to three — is the second half
    /// of the trim range. `SegmentedGoalRing` rotates by -90° to start at
    /// twelve; this needs no rotation because it starts at nine by definition.
    private static let topHalf: CGFloat = 0.5

    /// The gap is a share of one segment rather than a fixed slice, so it
    /// shrinks with the segments instead of eating them. The daily goal goes to
    /// 100: at that count each segment keeps 70% of its own span, and the arc
    /// stays an arc rather than turning into a dotted line.
    private func span(_ index: Int) -> (from: CGFloat, to: CGFloat) {
        let count = max(1, sections.count)
        let step = Self.topHalf / CGFloat(count)
        let gap = count > 1 ? min(step * 0.30, 0.010) : 0
        let start = Self.topHalf + step * CGFloat(index)
        return (start + gap / 2, start + step - gap / 2)
    }

    var body: some View {
        ZStack {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                let range = span(index)
                // Inset by half the line width before trimming. `.stroke`
                // centres the line on the path (§8.18), so an uninset circle
                // would paint 7pt of arc above its own frame and collide with
                // the header sitting over it. Inset, the ink runs from radius
                // 111 to 125 inside a 250pt box and the top of the arc lands
                // exactly on the frame's top edge.
                Circle()
                    .inset(by: lineWidth / 2)
                    .trim(from: range.from, to: range.to)
                    .stroke(section.isFilled ? section.tint : track,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .animation(reduceMotion ? nil : Motion.gentle, value: section.isFilled)
            }
        }
        .frame(width: diameter, height: diameter)
        // Only the top half carries ink, so the bottom half is cropped out of
        // the layout rather than reserved. The butt caps end flat on the
        // horizontal diameter, so nothing is drawn below it and no clip is
        // needed — which matters, because a clip here would cut the caps.
        .frame(height: diameter / 2, alignment: .top)
    }
}
