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

struct WidgetSnapshot: Codable, Equatable {
    var clusterShortName: String = "Marketing"
    var answeredToday: Int = 0
    var goal: Int = 10
    var streak: Int = 0
    var freezes: Int = 0
    var dueForReview: Int = 0
    var updatedAt: Date = Date(timeIntervalSince1970: 0)

    var remaining: Int { max(0, goal - answeredToday) }
    var fraction: Double { goal <= 0 ? 1 : min(1, Double(answeredToday) / Double(goal)) }
    var goalMet: Bool { answeredToday >= goal }

    static let sample = WidgetSnapshot(clusterShortName: "Marketing",
                                       answeredToday: 6,
                                       goal: 10,
                                       streak: 4,
                                       freezes: 0,
                                       dueForReview: 3,
                                       updatedAt: Date(timeIntervalSince1970: 0))
}

enum WidgetStore {
    static let appGroupID = "group.com.shailpatel.LCVI-DECA-Study-App"
    static let snapshotKey = "widget.snapshot.v1"

    static func read() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
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
    static var sheen: some View {
        ZStack {
            LinearGradient(colors: [Color.white.opacity(0.20), Color.white.opacity(0.02), .clear],
                           startPoint: .topLeading,
                           endPoint: .bottom)
            RadialGradient(colors: [WidgetPalette.accent.opacity(0.16), .clear],
                           center: .topTrailing,
                           startRadius: 2,
                           endRadius: 190)
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

enum WidgetLink {
    static let dailyPractice = URL(string: "decastudy://practice")!
    static let examCram = URL(string: "decastudy://cram")!
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
        }
    }
}
