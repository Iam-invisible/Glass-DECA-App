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
/// Accent colours carry meaning only — blue = progress, green = correct,
/// red = wrong, gold = streaks & achievements, gray = inactive.
enum Palette {
    // Surfaces
    static let canvas       = Color(lightHex: 0xF4F6FA, darkHex: 0x0D1219)
    static let card         = Color(lightHex: 0xFFFFFF, darkHex: 0x161E29)
    static let cardRaised   = Color(lightHex: 0xFFFFFF, darkHex: 0x1D2632)
    static let cardSunken   = Color(lightHex: 0xEDF1F7, darkHex: 0x111823)
    static let stroke       = Color(lightHex: 0xE2E8F0, darkHex: 0x27313F)
    static let strokeStrong = Color(lightHex: 0xCBD5E1, darkHex: 0x33404F)

    // Text
    static let textPrimary   = Color(lightHex: 0x0F1B2D, darkHex: 0xF2F5F9)
    static let textSecondary = Color(lightHex: 0x53627A, darkHex: 0x9AA8BC)
    static let textTertiary  = Color(lightHex: 0x8A97AB, darkHex: 0x6C7A8D)

    // Meaningful accents
    static let accent      = Color(lightHex: 0x2563EB, darkHex: 0x5B8DEF)
    static let accentSoft  = Color(lightHex: 0xE4EDFF, darkHex: 0x1B2942)
    static let success     = Color(lightHex: 0x12855C, darkHex: 0x34C793)
    static let successSoft = Color(lightHex: 0xDDF5EC, darkHex: 0x11312A)
    static let danger      = Color(lightHex: 0xC8342F, darkHex: 0xF2645F)
    static let dangerSoft  = Color(lightHex: 0xFCE6E5, darkHex: 0x3A1B1C)
    static let gold        = Color(lightHex: 0xB07407, darkHex: 0xE8B14A)
    static let goldSoft    = Color(lightHex: 0xFBF0DA, darkHex: 0x33270F)
    static let inactive    = Color(lightHex: 0xB4BECC, darkHex: 0x3C4757)

    static let shadow = Color(lightHex: 0x0F1B2D, darkHex: 0x000000)
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

/// Fraunces for display, Inter for text and UI.
///
/// Both ship from Google Fonts as variable fonts. They're instanced at build
/// time to fixed weights (and, for Fraunces, fixed softness/wonk) but keep their
/// `opsz` axis, so CoreText still applies optical sizing as text grows.
///
/// Everything goes through `Font.custom(_:size:relativeTo:)` rather than a
/// pre-scaled `UIFont`: a `UIFont` built with `UIFontMetrics` resolves once and
/// caches, so it silently stops responding to the reader's text-size setting.
/// `Font.custom` is resolved at render time and keeps Dynamic Type working.
enum AppType {
    static let display  = "Fraunces-Display"
    /// Intro wordmark only — a monoline script whose letters can be written
    /// out along a pen path. Not a UI face; nothing else should set text in it.
    static let script   = "Sacramento-Regular"
    static let regular  = "Inter-Regular"
    static let medium   = "Inter-Medium"
    static let semibold = "Inter-SemiBold"
}

extension Font {
    // Display — Fraunces
    static let appLargeTitle = Font.custom(AppType.display, size: 32, relativeTo: .largeTitle)
    static let appTitle      = Font.custom(AppType.display, size: 22, relativeTo: .title2)

    // Text and UI — Inter
    static let appHeadline    = Font.custom(AppType.semibold, size: 17, relativeTo: .headline)
    static let appBody        = Font.custom(AppType.regular,  size: 17, relativeTo: .body)
    static let appBodyMedium  = Font.custom(AppType.medium,   size: 17, relativeTo: .body)
    static let appCallout     = Font.custom(AppType.regular,  size: 16, relativeTo: .callout)
    static let appFootnote    = Font.custom(AppType.regular,  size: 13, relativeTo: .footnote)
    static let appCaption     = Font.custom(AppType.regular,  size: 12, relativeTo: .caption)
    static let appCaptionBold = Font.custom(AppType.semibold, size: 12, relativeTo: .caption)

    /// Question and scenario copy — the most-read text in the app.
    static let appQuestion = Font.custom(AppType.semibold, size: 20, relativeTo: .title3)

    /// Inter at a fixed size, for labels inside fixed-height chrome (the tab
    /// bar, chart axes) where Dynamic Type growth would break the layout.
    static func appSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(name(for: weight), fixedSize: size)
    }

    /// Counters, timers and scores. Fixed size on purpose — these sit inside
    /// progress rings and other fixed-diameter layouts. Inter carries `tnum`,
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
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
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
            .background(Palette.canvas.ignoresSafeArea())
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
