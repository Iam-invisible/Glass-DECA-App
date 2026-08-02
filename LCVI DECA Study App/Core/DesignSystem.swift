//
//  DesignSystem.swift
//  LCVI DECA Study App
//
//  Colors, typography, spacing and shared view modifiers.
//  Everything here is deliberately semantic so light/dark mode stays consistent.
//

import SwiftUI
import UIKit

// MARK: - Dynamic color helper

extension Color {
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Palette

/// Refined academic / business palette.
/// Warm paper.
///
/// Surfaces sit on a warm off-white rather than the blue-grey every dashboard
/// uses, and the ink is a warm near-black rather than navy. The point is that
/// the app reads as a printed study book, which is also what the display serif
/// has been asking for since it was chosen.
///
/// Dark mode is a *warm* dark — brown-black, not blue-black. A cool dark under
/// a warm light theme reads as two different apps.
///
/// Accent colours still carry meaning only — blue = progress, green = correct,
/// red = wrong, gold = streaks and achievements, grey = inactive. Warm paper
/// leaves less room in the warm half of the wheel, so the cluster tints in
/// `DECACluster.tint` were pulled apart deliberately to stay clear of these
/// four. Before adding any new colour, check it against both sets.
enum Palette {
    // Surfaces — warm paper, with cards lifting slightly off the page.
    static let canvas       = Color(lightHex: 0xFAF7F2, darkHex: 0x14110D)
    static let card         = Color(lightHex: 0xFFFDF9, darkHex: 0x1F1A14)
    static let cardRaised   = Color(lightHex: 0xFFFFFF, darkHex: 0x2A241C)
    static let cardSunken   = Color(lightHex: 0xF1ECE3, darkHex: 0x19150F)
    static let stroke       = Color(lightHex: 0xE6DFD3, darkHex: 0x372F25)
    /// The lighter top edge of a card's border — a pane lit from above.
    static let strokeGlint  = Color(lightHex: 0xFBF8F2, darkHex: 0x4B4133)
    static let strokeStrong = Color(lightHex: 0xD4CABA, darkHex: 0x473D31)

    // Text — warm ink rather than black, so it belongs on the paper.
    static let textPrimary   = Color(lightHex: 0x231F1A, darkHex: 0xF5F0E7)
    static let textSecondary = Color(lightHex: 0x5C5348, darkHex: 0xB6A994)
    static let textTertiary  = Color(lightHex: 0x8C8175, darkHex: 0x86796A)

    // Meaningful accents — deepened so they read as ink on paper rather than
    // as the bright screen colours a white background can carry.
    static let accent      = Color(lightHex: 0x175C7A, darkHex: 0x6FAECB)
    static let accentSoft  = Color(lightHex: 0xE2EDF2, darkHex: 0x182A33)
    static let success     = Color(lightHex: 0x3D7A4E, darkHex: 0x6FB985)
    static let successSoft = Color(lightHex: 0xE5EFE5, darkHex: 0x17281B)
    static let danger      = Color(lightHex: 0xB33A2B, darkHex: 0xE8776A)
    static let dangerSoft  = Color(lightHex: 0xF8E5E1, darkHex: 0x351A15)
    static let gold        = Color(lightHex: 0xA87422, darkHex: 0xDDA945)
    static let goldSoft    = Color(lightHex: 0xF6EBD7, darkHex: 0x33270F)
    static let inactive    = Color(lightHex: 0xB8AFA2, darkHex: 0x4B4238)

    static let shadow = Color(lightHex: 0x2A2118, darkHex: 0x000000)
}

// MARK: - Spacing / radius

enum Metrics {
    static let gutter: CGFloat = 18
    static let cardRadius: CGFloat = 18
    static let controlRadius: CGFloat = 14
    static let rowMinHeight: CGFloat = 52
    static let stackSpacing: CGFloat = 14
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Typography

/// Instrument Serif for display, Manrope for text and UI.
///
/// Instrument Serif is a high-contrast display serif — the thick-to-thin
/// modulation is the point, since the app is called Glass and that contrast is
/// what light through glass looks like. It has one weight by design; display
/// roles are headline contexts where a second weight would only dilute it.
///
/// Manrope carries the reading. It was chosen on measurements rather than
/// taste: of fourteen candidates it has the largest x-height relative to em
/// (0.540), which is what legibility at caption sizes depends on, and it is
/// also the second most compact, so more of a question fits on a line at the
/// same apparent size. It ships `tnum`, which `numeric()` relies on.
///
/// Manrope's Google-served static instances all report a PostScript name of
/// `ManropeExtraLight-*`, inherited from the variable font's default instance.
/// `Font.custom` resolves by PostScript name, so the name tables were rewritten
/// by hand — the same fix §7.8 records for Fraunces.
///
/// Everything goes through `Font.custom(_:size:relativeTo:)` rather than a
/// pre-scaled `UIFont`: a `UIFont` built with `UIFontMetrics` resolves once and
/// caches, so it silently stops responding to the reader's text-size setting.
/// `Font.custom` is resolved at render time and keeps Dynamic Type working.
enum AppType {
    static let display  = "InstrumentSerif-Regular"
    /// Intro wordmark only — a monoline script whose letters can be written
    /// out along a pen path. Not a UI face; nothing else should set text in it.
    static let script   = "Sacramento-Regular"
    static let regular  = "Manrope-Regular"
    static let medium   = "Manrope-Medium"
    static let semibold = "Manrope-SemiBold"
}

extension Font {
    // Display — Instrument Serif
    static let appLargeTitle = Font.custom(AppType.display, size: 38, relativeTo: .largeTitle)
    static let appTitle      = Font.custom(AppType.display, size: 26, relativeTo: .title2)

    /// Section titles inside screens. With the display serif on section
    /// headings and Manrope on everything else, the eye can skim a screen by
    /// serif alone — the hierarchy is legible before anything is read.
    static let appSectionTitle = Font.custom(AppType.display, size: 22, relativeTo: .title3)

    // Text and UI — Manrope
    static let appHeadline    = Font.custom(AppType.semibold, size: 17, relativeTo: .headline)
    static let appBody        = Font.custom(AppType.regular,  size: 17, relativeTo: .body)
    static let appBodyMedium  = Font.custom(AppType.medium,   size: 17, relativeTo: .body)
    static let appCallout     = Font.custom(AppType.regular,  size: 16, relativeTo: .callout)
    static let appFootnote    = Font.custom(AppType.regular,  size: 13, relativeTo: .footnote)
    static let appCaption     = Font.custom(AppType.regular,  size: 12, relativeTo: .caption)
    static let appCaptionBold = Font.custom(AppType.semibold, size: 12, relativeTo: .caption)

    /// Question and scenario copy — the most-read text in the app.
    static let appQuestion = Font.custom(AppType.semibold, size: 20, relativeTo: .title3)

    /// Manrope at a fixed size, for labels inside fixed-height chrome (the tab
    /// bar, chart axes) where Dynamic Type growth would break the layout.
    static func appSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(name(for: weight), fixedSize: size)
    }

    /// Counters, timers and scores. Fixed size on purpose — these sit inside
    /// progress rings and other fixed-diameter layouts. Manrope carries `tnum`,
    /// so `monospacedDigit()` stops digits jittering as they change.
    static func numeric(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom(name(for: weight), fixedSize: size).monospacedDigit()
    }

    private static func name(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black, .semibold: return AppType.semibold
        case .medium:                          return AppType.medium
        default:                               return AppType.regular
        }
    }
}

// MARK: - Card styling

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = Metrics.cardRadius
    var fill: Color = Palette.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                // The shadow belongs to the card's shape, not to the card.
                // Applied to the whole modified view it would blur the
                // composite — background, border and every glyph of text —
                // which costs an offscreen render pass per card per frame,
                // and there are 80-odd cards' worth of call sites. The fill
                // is opaque, so the text never contributed anything visible
                // to the shadow anyway: same picture, one cheap pass.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .shadow(color: Palette.shadow.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .overlay(
                // A gradient border, lighter at the top: the pane's edge
                // catching the light field it sits in. Static fill — costs
                // the same as the flat stroke it replaces.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Palette.strokeGlint, Palette.stroke],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Bottom bar inset

/// Height the tab bar occupies, published to the tab hierarchy so scrollable
/// screens can reserve room for it.
///
/// The obvious approach — `safeAreaInset` on the tab content in `RootView` —
/// does not work: each tab wraps its screens in a `NavigationStack`, which
/// establishes its own safe area and swallows the inset, leaving content
/// stranded behind the bar. Publishing the value instead lets `appCanvas()`
/// apply the inset *inside* the navigation stack, where it takes effect.
private struct BottomBarInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var bottomBarInset: CGFloat {
        get { self[BottomBarInsetKey.self] }
        set { self[BottomBarInsetKey.self] = newValue }
    }
}

struct AppCanvas: ViewModifier {
    @Environment(\.bottomBarInset) private var bottomBarInset

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: bottomBarInset)
            }
            // The intro's light field, app-wide. See AmbientCanvas for the
            // iPhone 8 performance reasoning.
            .background(AmbientCanvas())
    }
}

extension View {
    func appCard(padding: CGFloat = 16,
                 radius: CGFloat = Metrics.cardRadius,
                 fill: Color = Palette.card) -> some View {
        modifier(CardBackground(padding: padding, radius: radius, fill: fill))
    }

    /// Applies the app canvas colour behind a scrolling screen, and reserves
    /// room for the tab bar when one is present.
    func appCanvas() -> some View {
        modifier(AppCanvas())
    }

    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide { self.hidden() } else { self }
    }
}

// MARK: - Pill / tag

struct TagPill: View {
    let text: String
    var color: Color = Palette.accent
    var soft: Color = Palette.accentSoft
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.appCaptionBold)
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule(style: .continuous).fill(soft))
        .accessibilityLabel(text)
    }
}

// MARK: - Appearance preference

enum AppearanceMode: String, CaseIterable, Codable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
