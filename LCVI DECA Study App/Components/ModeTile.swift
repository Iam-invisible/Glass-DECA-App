//
//  ModeTile.swift
//  LCVI DECA Study App
//
//  One way to study, as a compact tinted tile.
//
//  The old IA presented every way to study as a full-width white row-card in
//  a long identical stack, spread across four tabs. Tiles trade that for a
//  two-column garden on one screen: each mode gets a colour, an icon, a serif
//  title and its one live number, so the whole studying surface is visible at
//  a glance and every mode is exactly one tap away.
//
//  A tile either *launches* (count in the corner: questions due, mistakes
//  open) or *leads somewhere* (chevron in the corner: Mock Exams, Roleplay,
//  Library). The corner glyph is the affordance.
//

import SwiftUI

struct ModeTile: View {
    let title: String
    let systemImage: String
    var tint: Color = Palette.accent
    /// A live count shown in the corner. `nil` shows a chevron instead —
    /// the tile navigates rather than launches.
    var count: Int? = nil
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(tint.opacity(0.16))
                            .frame(width: 36, height: 36)
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tint)
                    }
                    Spacer(minLength: 0)
                    if let count {
                        Text("\(count)")
                            .font(.numeric(17, weight: .semibold))
                            .foregroundStyle(count > 0 ? tint : Palette.textTertiary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)
                    }
                }
                Spacer(minLength: 10)
                Text(title)
                    .font(.appSectionTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .background(
                // Tinted glass rather than a white card: the tile's colour is
                // its identity, and the wash stays light enough to read over
                // in both themes.
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .fill(tint.opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .strokeBorder(tint.opacity(0.22), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
        .accessibilityLabel(count.map { "\(title), \($0)" } ?? title)
    }
}
