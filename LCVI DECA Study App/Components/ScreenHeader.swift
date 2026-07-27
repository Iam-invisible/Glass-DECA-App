//
//  ScreenHeader.swift
//  LCVI DECA Study App
//
//  The title block every root tab opens with.
//
//  Two problems, one answer. The app's display face is now a high-contrast
//  serif, and a system large title can't use it — `navigationTitle` renders in
//  San Francisco, so five of the six tabs opened in a typeface the rest of the
//  app doesn't use. And the navigation bar is OS-drawn, so iOS 16 and iOS 26
//  draw it differently: it was the largest remaining source of the
//  cross-version inconsistency the custom controls exist to fix.
//
//  Drawing the title ourselves and hiding the bar solves both at once. Pushed
//  screens keep their normal inline bars, because those carry the back button
//  and should behave exactly as the OS expects.
//
//  The eyebrow above the title is where a screen says what it is *currently
//  scoped to* — the student's cluster, "All clusters", a count. It replaces
//  the subtitle-under-a-section-header pattern that used to carry that, and
//  puts the context where the eye already is.
//

import SwiftUI

struct ScreenHeader<Accessory: View>: View {
    let title: String

    var eyebrow: String? = nil
    var eyebrowSymbol: String? = nil
    var eyebrowTint: Color = Palette.accent
    var subtitle: String? = nil

    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                if let eyebrow {
                    HStack(spacing: 6) {
                        if let eyebrowSymbol {
                            Image(systemName: eyebrowSymbol)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(eyebrowTint)
                        }
                        Text(eyebrow)
                            .font(.appCaptionBold)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(title)
                    .font(.appLargeTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
            accessory()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

extension ScreenHeader where Accessory == EmptyView {
    init(_ title: String,
         eyebrow: String? = nil,
         eyebrowSymbol: String? = nil,
         eyebrowTint: Color = Palette.accent,
         subtitle: String? = nil) {
        self.init(title: title,
                  eyebrow: eyebrow,
                  eyebrowSymbol: eyebrowSymbol,
                  eyebrowTint: eyebrowTint,
                  subtitle: subtitle) { EmptyView() }
    }
}

extension View {
    /// Hides the system navigation bar on a root tab, which now draws its own
    /// title with `ScreenHeader`. Never apply this to a pushed screen — those
    /// need the bar for the back button.
    func rootScreenChrome() -> some View {
        toolbar(.hidden, for: .navigationBar)
    }
}
