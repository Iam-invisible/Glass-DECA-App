//
//  WidgetShared.swift
//  DECAStudyWidget
//
//  A self-contained copy of the snapshot the app publishes, plus the widget's
//  glass styling. The widget reads local data only — no account, no network.
//  If the App Group container isn't available it falls back to sample content.
//

import Foundation
import SwiftUI

/// Mirror of the app's `WidgetSnapshot` (Services/WidgetDataService.swift).
/// The extension is its own binary and cannot import the app, so the two are
/// kept in step by hand. Add a field in one and add it to the other in the
/// same change, or it decodes away to its default here and no one notices.
struct WidgetSnapshot: Codable, Equatable {

    // v1 — the daily ring and the streak.
    var clusterShortName: String = "Marketing"
    var answeredToday: Int = 0
    var goal: Int = 10
    var streak: Int = 0
    var freezes: Int = 0
    var dueForReview: Int = 0
    var updatedAt: Date = Date(timeIntervalSince1970: 0)

    // v2 — what the large widget reads.
    var eventCode: String = ""
    var quickThinkToday: Int = 0
    /// Zero means the student's event has no roleplay component, so the Quick
    /// Think dial is hidden rather than shown permanently complete at 0/0.
    var quickThinkGoal: Int = 0
    var openMistakes: Int = 0
    var accuracy: Double = 0
    var totalAnswered: Int = 0
    var bookmarked: Int = 0
    var achievements: Int = 0
    var lastMockScore: Int? = nil
    var weakestCode: String = ""
    var weakestText: String = ""

    var remaining: Int { max(0, goal - answeredToday) }
    var fraction: Double { goal <= 0 ? 1 : min(1, Double(answeredToday) / Double(goal)) }
    var goalMet: Bool { answeredToday >= goal }

    var showsQuickThink: Bool { quickThinkGoal > 0 }
    var quickThinkFraction: Double {
        quickThinkGoal <= 0 ? 1 : min(1, Double(quickThinkToday) / Double(quickThinkGoal))
    }
    var quickThinkGoalMet: Bool { quickThinkGoal > 0 && quickThinkToday >= quickThinkGoal }

    var accuracyPercent: Int { Int((accuracy * 100).rounded()) }

    static let sample = WidgetSnapshot(clusterShortName: "Marketing",
                                       answeredToday: 6,
                                       goal: 10,
                                       streak: 4,
                                       freezes: 0,
                                       dueForReview: 3,
                                       updatedAt: Date(timeIntervalSince1970: 0),
                                       eventCode: "PMK",
                                       quickThinkToday: 1,
                                       quickThinkGoal: 2,
                                       openMistakes: 5,
                                       accuracy: 0.78,
                                       totalAnswered: 214,
                                       bookmarked: 9,
                                       achievements: 7,
                                       lastMockScore: 82,
                                       weakestCode: "MK:006",
                                       weakestText: "Explain the concept of market segmentation")

    enum CodingKeys: String, CodingKey {
        case clusterShortName, answeredToday, goal, streak, freezes, dueForReview, updatedAt
        case eventCode, quickThinkToday, quickThinkGoal, openMistakes, accuracy
        case totalAnswered, bookmarked, achievements, lastMockScore, weakestCode, weakestText
    }

    /// Hand-written so a snapshot left behind by the previous build — which
    /// has none of the v2 keys — decodes to defaults instead of throwing.
    /// Throwing here would blank every widget until the app next foregrounded.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clusterShortName = try c.decodeIfPresent(String.self, forKey: .clusterShortName) ?? "Marketing"
        answeredToday    = try c.decodeIfPresent(Int.self,    forKey: .answeredToday) ?? 0
        goal             = try c.decodeIfPresent(Int.self,    forKey: .goal) ?? 10
        streak           = try c.decodeIfPresent(Int.self,    forKey: .streak) ?? 0
        freezes          = try c.decodeIfPresent(Int.self,    forKey: .freezes) ?? 0
        dueForReview     = try c.decodeIfPresent(Int.self,    forKey: .dueForReview) ?? 0
        updatedAt        = try c.decodeIfPresent(Date.self,   forKey: .updatedAt) ?? Date(timeIntervalSince1970: 0)
        eventCode        = try c.decodeIfPresent(String.self, forKey: .eventCode) ?? ""
        quickThinkToday  = try c.decodeIfPresent(Int.self,    forKey: .quickThinkToday) ?? 0
        quickThinkGoal   = try c.decodeIfPresent(Int.self,    forKey: .quickThinkGoal) ?? 0
        openMistakes     = try c.decodeIfPresent(Int.self,    forKey: .openMistakes) ?? 0
        accuracy         = try c.decodeIfPresent(Double.self, forKey: .accuracy) ?? 0
        totalAnswered    = try c.decodeIfPresent(Int.self,    forKey: .totalAnswered) ?? 0
        bookmarked       = try c.decodeIfPresent(Int.self,    forKey: .bookmarked) ?? 0
        achievements     = try c.decodeIfPresent(Int.self,    forKey: .achievements) ?? 0
        lastMockScore    = try c.decodeIfPresent(Int.self,    forKey: .lastMockScore)
        weakestCode      = try c.decodeIfPresent(String.self, forKey: .weakestCode) ?? ""
        weakestText      = try c.decodeIfPresent(String.self, forKey: .weakestText) ?? ""
    }

    /// Declaring `init(from:)` suppresses the memberwise initialiser.
    init(clusterShortName: String = "Marketing",
         answeredToday: Int = 0,
         goal: Int = 10,
         streak: Int = 0,
         freezes: Int = 0,
         dueForReview: Int = 0,
         updatedAt: Date = Date(timeIntervalSince1970: 0),
         eventCode: String = "",
         quickThinkToday: Int = 0,
         quickThinkGoal: Int = 0,
         openMistakes: Int = 0,
         accuracy: Double = 0,
         totalAnswered: Int = 0,
         bookmarked: Int = 0,
         achievements: Int = 0,
         lastMockScore: Int? = nil,
         weakestCode: String = "",
         weakestText: String = "") {
        self.clusterShortName = clusterShortName
        self.answeredToday = answeredToday
        self.goal = goal
        self.streak = streak
        self.freezes = freezes
        self.dueForReview = dueForReview
        self.updatedAt = updatedAt
        self.eventCode = eventCode
        self.quickThinkToday = quickThinkToday
        self.quickThinkGoal = quickThinkGoal
        self.openMistakes = openMistakes
        self.accuracy = accuracy
        self.totalAnswered = totalAnswered
        self.bookmarked = bookmarked
        self.achievements = achievements
        self.lastMockScore = lastMockScore
        self.weakestCode = weakestCode
        self.weakestText = weakestText
    }
}

enum WidgetStore {
    static let appGroupID = "group.com.shailpatel.LCVI-DECA-Study-NewApp"
    static let snapshotKey = "widget.snapshot.v1"

    /// Returns nil — and the widget falls back to sample content — whenever
    /// the group is unreachable. The container check comes first for the same
    /// reason as in the app: an unentitled `UserDefaults(suiteName:)` is
    /// non-nil but broken, and touching it logs an initialisation failure on
    /// every timeline refresh.
    static func read() -> WidgetSnapshot? {
        guard FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil,
              let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}

// MARK: - Palette

enum WidgetPalette {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: 1)
        })
    }

    /// Opaque base, used only on systems with no Liquid Glass of their own.
    static let canvas  = dynamic(light: 0xF7F9FC, dark: 0x141B25)
    static let accent  = dynamic(light: 0x2563EB, dark: 0x5B8DEF)
    static let success = dynamic(light: 0x12855C, dark: 0x34C793)
    static let gold    = dynamic(light: 0xB07407, dark: 0xE8B14A)
}

// MARK: - Type

/// The app's own faces, bundled with the extension and registered in its
/// Info.plist. Michroma carries the hero numbers and titles — the same voice
/// as every screen header — and Manrope carries the reading.
/// `Font.custom` falls back to the system face if a font ever fails to
/// register, so the widget degrades rather than breaks.
enum WidgetType {
    /// Michroma's digits are 0.951 em against Instrument Serif's 0.460, so a
    /// three-digit hero number at the old sizes ran past the small widget's
    /// edge — "100" at 48pt wanted 137pt of about 130pt available. The
    /// correction lives here rather than at the nine call sites so those keep
    /// expressing intent ("the hero number is 48"), and so a future face swap
    /// is one number. Michroma's taller x-height means 0.8 costs little
    /// apparent size.
    static func display(_ size: CGFloat) -> Font {
        .custom("Michroma-Regular", fixedSize: size * 0.8)
    }
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(weight == .regular ? "Manrope-Regular" : "Manrope-SemiBold",
                fixedSize: size)
    }
}

extension View {
    /// The app's eyebrow voice: small tracked uppercase Manrope.
    func widgetKicker(_ color: Color) -> some View {
        font(WidgetType.sans(10, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(color)
    }
}

// MARK: - Glass

/// Widget glass is a two-part illusion.
///
/// The real refraction is the system's: on iOS 26 the Home Screen paints a
/// Liquid Glass panel *behind* each widget. A widget can't sample the wallpaper
/// itself — it renders out of process — so the trick is simply to stop painting
/// over that panel and let it through.
///
/// Everything drawn inside is then styled to match: translucent fills, hairline
/// light-catching strokes and a specular sheen, all of which render predictably
/// in a widget snapshot.
enum WidgetGlass {

    /// Highlight and brand wash layered over whatever sits behind.
    ///
    /// The light pools are pushed harder than the in-app canvas: a widget is
    /// two inches wide on a busy wallpaper, so the same opacities that read as
    /// atmosphere on a full screen read as nothing at all here.
    static var sheen: some View {
        ZStack {
            LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.04), .clear],
                           startPoint: .topLeading,
                           endPoint: .bottom)
            // The app's ambient light field, in miniature: an accent pool and
            // a gold one, the same two colours that drift behind every screen.
            RadialGradient(colors: [WidgetPalette.accent.opacity(0.26), .clear],
                           center: .topTrailing,
                           startRadius: 2,
                           endRadius: 190)
            RadialGradient(colors: [WidgetPalette.gold.opacity(0.16), .clear],
                           center: .bottomLeading,
                           startRadius: 2,
                           endRadius: 150)
        }
    }

    @ViewBuilder
    static var containerFill: some View {
        if #available(iOS 26.0, *) {
            // The system's glass is already there — only add the sheen on top.
            sheen
        } else {
            // No system glass here, so the widget is the surface. Without an
            // opaque base the text would sit straight on the wallpaper.
            ZStack {
                WidgetPalette.canvas
                sheen
            }
        }
    }
}

extension View {
    /// Background that defers to the system's Liquid Glass where it exists.
    /// `containerBackground` is iOS 17+; older widgets paint their own.
    @ViewBuilder
    func glassWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { WidgetGlass.containerFill }
        } else {
            self.padding(12).background(WidgetGlass.containerFill)
        }
    }

    /// A frosted capsule for inline stats.
    func glassChip(tint: Color) -> some View {
        self
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.16))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                    )
            }
    }

    /// A hero numeral. The gradient is what makes a big number read as glass
    /// rather than as flat text — it is the same top-bright/bottom-dim
    /// modulation the display serif already has built into its strokes.
    func heroNumeral(_ tint: Color) -> some View {
        foregroundStyle(
            LinearGradient(colors: [Color.primary, Color.primary.opacity(0.72)],
                           startPoint: .top, endPoint: .bottom)
        )
        .shadow(color: tint.opacity(0.28), radius: 5, y: 1)
    }

    /// A frosted tile, used for the quick-launch targets.
    func glassTile(tint: Color, prominent: Bool) -> some View {
        self.background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(prominent ? 0.85 : 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color.white.opacity(0.28), .clear],
                                           startPoint: .top, endPoint: .center)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(prominent ? 0.35 : 0.22), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Deep links

/// Keep in step with the `onOpenURL` switch in LCVI_DECA_Study_AppApp.swift,
/// which is the only thing that reads these.
enum WidgetLink {
    static let dailyPractice = URL(string: "decastudy://practice")!
    static let examCram = URL(string: "decastudy://cram")!
    static let reviewDue = URL(string: "decastudy://review")!
    static let mistakes = URL(string: "decastudy://mistakes")!
    static let quickThink = URL(string: "decastudy://quickthink")!
}

// MARK: - Stat cell

/// One number and its label, on its own frosted panel. The large widget is a
/// grid of these; giving each a panel is what stops the extra information
/// reading as a wall of text.
struct WidgetStat: View {
    var value: String
    var label: String
    var systemImage: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                Text(value)
                    .font(WidgetType.display(21))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(tint)

            Text(label)
                .font(WidgetType.sans(10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

// MARK: - Ring

/// Progress ring with an etched track, so it reads as cut into the glass
/// rather than painted on top of it.
struct WidgetRing: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .stroke(Color.white.opacity(0.18),
                        style: StrokeStyle(lineWidth: 0.5))
                .padding(lineWidth / 2)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.65), tint, tint.opacity(0.9)],
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.35), radius: 3)

            // The point of light at the arc's tip — the same motif as the
            // in-app ring. Radius is min/2: the stroke centreline, learned
            // the hard way on the app side.
            if progress > 0.02 {
                GeometryReader { geo in
                    let r = min(geo.size.width, geo.size.height) / 2
                    Circle()
                        .fill(.white)
                        .frame(width: lineWidth * 0.42, height: lineWidth * 0.42)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2 - r)
                        .rotationEffect(.degrees(360 * min(max(progress, 0), 1)))
                        .shadow(color: tint.opacity(0.9), radius: 2.5)
                }
            }
        }
    }
}
