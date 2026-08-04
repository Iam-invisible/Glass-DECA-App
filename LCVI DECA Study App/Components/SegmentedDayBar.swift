//
//  SegmentedDayBar.swift
//  LCVI DECA Study App
//
//  The day as one bar, cut into a segment per thing to do.
//
//  Same idea as `SegmentedGoalRing` and the same reason for it: a continuous
//  track answers "how far through am I" and nothing else, while segments answer
//  "how much is one question worth" — the question a student acts on. A single
//  lit segment on a fresh day is visible where a 1/20th sliver is not.
//
//  Laid out rather than drawn, so it costs a row of rectangles instead of one
//  trimmed path per section. That matters more here than on the ring: the bar
//  is the width of the screen, so a large goal is a long row of thin shapes
//  rather than a long stack of arcs.
//

import SwiftUI

struct SegmentedDayBar: View {
    let sections: [SegmentedGoalRing.Section]
    var height: CGFloat = 9
    var spacing: CGFloat = 4
    var track: Color = Palette.cardSunken

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The daily goal goes to 100, and a hundred segments across a phone is a
    /// dotted line rather than a bar. Two things keep it honest: the dividers
    /// close up so they never eat more than about a third of the width, and
    /// once a segment would be thinner than `mergeBelow` they close completely
    /// and the row becomes one continuous two-tone bar.
    ///
    /// Merging rather than shrinking further is the point. At a 100-question
    /// goal "what one question is worth" is not a fact the eye can read however
    /// it is drawn, so the bar stops implying that it can and goes back to
    /// answering how far through the day is — which is what a smooth track is
    /// good at.
    private static let mergeBelow: CGFloat = 3
    private static let maxGapShare: CGFloat = 0.34

    var body: some View {
        GeometryReader { geo in
            let count = max(1, sections.count)
            let ideal = count > 1
                ? min(spacing, geo.size.width * Self.maxGapShare / CGFloat(count - 1))
                : 0
            let width = (geo.size.width - ideal * CGFloat(count - 1)) / CGFloat(count)
            let merged = width < Self.mergeBelow

            HStack(spacing: merged ? 0 : ideal) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    // Rounded per segment while they stand apart, square once
                    // they touch. Capsules on a merged run would scallop the
                    // seam of what has to read as one continuous track; the
                    // clip below is what still rounds the bar's two ends.
                    Group {
                        if merged {
                            Rectangle().fill(section.isFilled ? section.tint : track)
                        } else {
                            Capsule().fill(section.isFilled ? section.tint : track)
                        }
                    }
                    .animation(reduceMotion ? nil : Motion.gentle, value: section.isFilled)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
    }
}
