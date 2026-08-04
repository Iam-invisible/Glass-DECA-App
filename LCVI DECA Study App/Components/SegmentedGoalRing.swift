//
//  SegmentedGoalRing.swift
//  LCVI DECA Study App
//
//  A ring cut into one section per thing to do, lit as each is done.
//
//  A continuous arc answers "how far through am I" and nothing else. Sections
//  answer "how much is one question worth", which is the question a student
//  actually acts on — and a single lit section on a fresh day is visible where
//  a 1/20th arc is not.
//

import SwiftUI

struct SegmentedGoalRing: View {
    struct Section {
        let tint: Color
        let isFilled: Bool
    }

    let sections: [Section]
    var lineWidth: CGFloat = 14
    var track: Color = Palette.cardSunken

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Past roughly thirty sections the gaps eat more of the ring than the
    /// sections do, so the divider shrinks rather than the ring turning into a
    /// dotted line. A 50-question goal still reads as an arc.
    private var gapFraction: CGFloat {
        guard sections.count > 1 else { return 0 }
        return min(0.018, 0.55 / CGFloat(sections.count))
    }

    var body: some View {
        ZStack {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                arc(at: index)
                    .stroke(section.isFilled ? section.tint : track,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .animation(reduceMotion ? nil : Motion.gentle, value: section.isFilled)
            }
        }
        // -90° puts the first section at twelve o'clock; without it the ring
        // starts filling from three, which reads as starting late.
        .rotationEffect(.degrees(-90))
    }

    private func arc(at index: Int) -> some Shape {
        let step = 1 / CGFloat(max(1, sections.count))
        let gap = gapFraction / 2
        return Circle().trim(from: CGFloat(index) * step + gap,
                             to: CGFloat(index + 1) * step - gap)
    }
}
