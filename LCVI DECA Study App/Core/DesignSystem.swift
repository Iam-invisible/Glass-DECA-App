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
    /// The lighter top edge of a card's border — a pane lit from above.
    static let strokeGlint  = Color(lightHex: 0xEDF2F9, darkHex: 0x3B4859)
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

/// Three vertical gaps, and they are a hierarchy rather than three numbers:
/// `headerGap` (10) binds a `SectionHeader` to the content it names,
/// `stackSpacing` (14) separates peers inside one group, and `sectionSpacing`
/// (32) separates groups from each other.
///
/// A screen that uses one gap everywhere is the failure mode — the eye has
/// nothing to group by, so a heading floats as far from its own content as
/// from the section above it and every screen reads as one long list. Keep
/// header < peer < section on any new screen.
///
/// `sectionSpacing` went 24 → 32 because grouping was still not doing enough
/// work on Study and Progress, the two densest screens. It is raised here
/// rather than overridden on those two: seventeen screens read this value,
/// and a Study screen spaced differently from Settings looks like a bug
/// rather than a decision. What matters is the ratio — at 14 against 24 the
/// section break was under twice the peer gap, which is inside the range the
/// eye reads as "slightly further apart" rather than as "new thing".
enum Metrics {
    static let gutter: CGFloat = 18
    static let cardRadius: CGFloat = 18
    static let controlRadius: CGFloat = 14
    static let rowMinHeight: CGFloat = 52
    static let headerGap: CGFloat = 10
    static let stackSpacing: CGFloat = 14
    static let sectionSpacing: CGFloat = 32
}

// MARK: - Typography

/// Michroma for display, Manrope for text and UI.
///
/// Michroma is an extended geometric display face. It replaced Instrument
/// Serif because a serif at 22pt reads as body text set larger, and the
/// heading level had stopped announcing itself; Michroma's wide, architectural
/// letterforms cannot be mistaken for the Manrope underneath them at any size.
/// It has one weight, which is the right number for a face used only at
/// headline sizes.
///
/// **Its width is the constraint that shapes every display size below.**
/// Michroma averages 0.719 em per lowercase letter against Instrument Serif's
/// 0.392 — 1.87× — so the previous 38/26/22 ladder overflowed. "Good
/// afternoon" needed 380pt of an iPhone 8's 339pt. The sizes were cut ~15%
/// rather than left to `minimumScaleFactor`, because a greeting that silently
/// shrinks while every other screen title stays full size reads as a bug.
/// Apparent size barely moved: Michroma's x-height is 0.562 against 0.510, so
/// 32pt here looks about as tall as 38pt did. Any future display face needs
/// this ladder re-derived from its own width, not inherited.
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
    static let display  = "Michroma-Regular"
    /// Michroma ships one cut, so this is a bold **generated** from it: every
    /// outline stroked by 95/2048 em with a round join and unioned back onto
    /// itself, which takes the stem from 0.094 em to 0.141 em — a textbook bold
    /// weight. Advances are untouched, so it drops in without moving any
    /// layout. Michroma carries no Reserved Font Name, so the OFL permits the
    /// derivative; the licence ships beside it and the font's own copyright
    /// string records the modification.
    ///
    /// It exists because `Font.custom(...).weight(.bold)` does nothing here.
    /// Weight resolves *within a family*, and a family of one resolves back to
    /// itself — no synthesis, no warning, no visible change.
    static let displayBold = "Michroma-Bold"
    /// Intro wordmark only — a monoline script whose letters can be written
    /// out along a pen path. Not a UI face; nothing else should set text in it.
    static let script   = "Sacramento-Regular"
    static let regular  = "Manrope-Regular"
    static let medium   = "Manrope-Medium"
    static let semibold = "Manrope-SemiBold"
}

extension Font {
    // Display — Michroma. Sizes are ~15% below the old serif ladder to pay for
    // Michroma's width; see the note on `AppType` before changing them.
    //
    // Headings take `displayBold` as a face in its own right. Asking for bold
    // via `.weight(.bold)` on the regular cut is the obvious move and it is
    // silently a no-op — see the note on `AppType.displayBold`.
    static let appLargeTitle = Font.custom(AppType.displayBold, size: 32, relativeTo: .largeTitle)
    static let appTitle      = Font.custom(AppType.displayBold, size: 22, relativeTo: .title2)

    /// Section titles inside screens. With the display face on section headings
    /// and Manrope on everything else, the eye can skim a screen by shape
    /// alone — the hierarchy is legible before anything is read. 19pt is also
    /// what keeps "Mock Exams" clear of `ModeTile`'s 0.72 scale floor.
    static let appSectionTitle = Font.custom(AppType.displayBold, size: 19, relativeTo: .title3)

    /// Titles inside a `ModeTile`. Smaller than a section title because a tile
    /// is not a section — and because 16 is the largest size at which every
    /// label in the garden fits an iPhone SE tile's 138pt text box without
    /// `minimumScaleFactor` firing. At 19 it fired on "Review Due", "Mock
    /// Exams" and "Exam Cram" but not on "Roleplay" or "Mistakes", so the
    /// labels rendered at four different sizes across one grid and looked
    /// like a rendering fault rather than a scale. Michroma is wide: "Mock
    /// Exams" is 158pt at 19 and 133pt at 16.
    static let appTileTitle = Font.custom(AppType.displayBold, size: 16, relativeTo: .callout)

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
