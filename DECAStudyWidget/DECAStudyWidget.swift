//
//  DECAStudyWidget.swift
//  DECAStudyWidget
//
//  Home-screen widgets: daily progress, streak, questions remaining and quick
//  launch. All data is read from the app's local snapshot.
//
//  Text uses `.primary`/`.secondary` rather than fixed colours: with the
//  container background left translucent, content sits on the system's glass
//  over an unknown wallpaper, and only the semantic colours adapt to it.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct DECAEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let isPlaceholder: Bool
}

struct DECAProvider: TimelineProvider {
    func placeholder(in context: Context) -> DECAEntry {
        DECAEntry(date: Date(), snapshot: .sample, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (DECAEntry) -> Void) {
        let stored = WidgetStore.read()
        completion(DECAEntry(date: Date(),
                             snapshot: stored ?? .sample,
                             isPlaceholder: stored == nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DECAEntry>) -> Void) {
        let stored = WidgetStore.read()
        let entry = DECAEntry(date: Date(),
                              snapshot: stored ?? .sample,
                              isPlaceholder: stored == nil)
        // The app reloads timelines whenever progress changes; this refresh is
        // only a safety net so the widget rolls over at midnight.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Daily progress

struct DailyProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DECADailyProgress", provider: DECAProvider()) { entry in
            DailyProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Progress")
        .description("Your daily question goal, streak and what's left today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyProgressWidgetView: View {
    let entry: DECAEntry
    @Environment(\.widgetFamily) private var family

    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var tint: Color { snapshot.goalMet ? WidgetPalette.success : WidgetPalette.accent }

    var body: some View {
        Group {
            switch family {
            case .systemMedium: medium
            default:            small
            }
        }
        .widgetURL(WidgetLink.dailyPractice)
        .glassWidgetBackground()
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(WidgetPalette.accent)
                Text(snapshot.clusterShortName)
                    .widgetKicker(WidgetPalette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    WidgetRing(progress: snapshot.fraction, lineWidth: 7, tint: tint)
                        .frame(width: 46, height: 46)
                    Text("\(snapshot.answeredToday)")
                        .font(WidgetType.serif(19))
                        .foregroundStyle(.primary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("of \(snapshot.goal)")
                        .font(WidgetType.sans(12))
                        .foregroundStyle(.secondary)
                    if snapshot.streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill").font(.system(size: 9, weight: .bold))
                            Text("\(snapshot.streak)")
                                .font(WidgetType.sans(11, weight: .semibold))
                        }
                        .foregroundStyle(WidgetPalette.gold)
                        .glassChip(tint: WidgetPalette.gold)
                    }
                }
            }

            Spacer(minLength: 0)

            Text(statusLine)
                .font(WidgetType.sans(11))
                .foregroundStyle(snapshot.goalMet ? WidgetPalette.success : .secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glass daily goal")
        .accessibilityValue(accessibilityValue)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ZStack {
                WidgetRing(progress: snapshot.fraction, lineWidth: 9, tint: tint)
                    .frame(width: 68, height: 68)
                VStack(spacing: 0) {
                    Text("\(snapshot.answeredToday)")
                        .font(WidgetType.serif(24))
                        .foregroundStyle(.primary)
                    Text("of \(snapshot.goal)")
                        .font(WidgetType.sans(10))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(snapshot.clusterShortName)
                    .widgetKicker(WidgetPalette.accent)
                    .lineLimit(1)

                Text(statusLine)
                    .font(WidgetType.serif(19))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 6) {
                    Label("\(snapshot.streak)", systemImage: "flame.fill")
                        .foregroundStyle(WidgetPalette.gold)
                        .glassChip(tint: WidgetPalette.gold)
                    if snapshot.freezes > 0 {
                        Label("\(snapshot.freezes)", systemImage: "snowflake")
                            .foregroundStyle(WidgetPalette.gold)
                            .glassChip(tint: WidgetPalette.gold)
                    }
                    if snapshot.dueForReview > 0 {
                        Label("\(snapshot.dueForReview)", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundStyle(WidgetPalette.accent)
                            .glassChip(tint: WidgetPalette.accent)
                    }
                }
                .font(WidgetType.sans(11, weight: .semibold))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glass daily goal")
        .accessibilityValue(accessibilityValue)
    }

    private var statusLine: String {
        if entry.isPlaceholder { return "Open Glass to start tracking" }
        if snapshot.goalMet { return "Goal complete for today" }
        return "\(snapshot.remaining) question\(snapshot.remaining == 1 ? "" : "s") to go"
    }

    private var accessibilityValue: String {
        "\(snapshot.answeredToday) of \(snapshot.goal) questions answered, \(snapshot.streak) day streak"
    }
}

// MARK: - Streak

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DECAStreak", provider: DECAProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current streak and streak freezes.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakWidgetView: View {
    let entry: DECAEntry
    private var snapshot: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(WidgetPalette.gold)
                .shadow(color: WidgetPalette.gold.opacity(0.4), radius: 6)

            Spacer(minLength: 0)

            Text("\(snapshot.streak)")
                .font(WidgetType.serif(46))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("day streak")
                .font(WidgetType.sans(12))
                .foregroundStyle(.secondary)

            if snapshot.freezes > 0 {
                Label("\(snapshot.freezes) freeze\(snapshot.freezes == 1 ? "" : "s")", systemImage: "snowflake")
                    .font(WidgetType.sans(11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.gold)
                    .glassChip(tint: WidgetPalette.gold)
            } else {
                Text("\(max(0, 10 - (snapshot.streak % 10))) days to a freeze")
                    .font(WidgetType.sans(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(WidgetLink.dailyPractice)
        .glassWidgetBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glass streak")
        .accessibilityValue("\(snapshot.streak) days, \(snapshot.freezes) freezes")
    }
}

// MARK: - Questions remaining

struct RemainingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DECARemaining", provider: DECAProvider()) { entry in
            RemainingWidgetView(entry: entry)
        }
        .configurationDisplayName("Questions Remaining")
        .description("How many questions are left in today's goal.")
        .supportedFamilies([.systemSmall])
    }
}

struct RemainingWidgetView: View {
    let entry: DECAEntry
    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var tint: Color { snapshot.goalMet ? WidgetPalette.success : WidgetPalette.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: snapshot.goalMet ? "checkmark.circle.fill" : "target")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.35), radius: 6)

            Spacer(minLength: 0)

            Text(snapshot.goalMet ? "Done" : "\(snapshot.remaining)")
                .font(WidgetType.serif(snapshot.goalMet ? 30 : 48))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(snapshot.goalMet
                 ? "Goal complete today"
                 : "question\(snapshot.remaining == 1 ? "" : "s") left today")
                .font(WidgetType.sans(12))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if snapshot.dueForReview > 0 {
                Label("\(snapshot.dueForReview) due", systemImage: "arrow.triangle.2.circlepath")
                    .font(WidgetType.sans(11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accent)
                    .glassChip(tint: WidgetPalette.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(WidgetLink.dailyPractice)
        .glassWidgetBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Questions remaining today")
        .accessibilityValue("\(snapshot.remaining)")
    }
}

// MARK: - Quick launch

struct QuickLaunchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DECAQuickLaunch", provider: DECAProvider()) { entry in
            QuickLaunchWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Launch")
        .description("Jump straight into Daily Practice or Exam Cram.")
        .supportedFamilies([.systemMedium])
    }
}

struct QuickLaunchWidgetView: View {
    let entry: DECAEntry
    private var snapshot: WidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text(snapshot.clusterShortName)
                    .widgetKicker(WidgetPalette.accent)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(snapshot.goalMet
                     ? "Goal complete"
                     : "\(snapshot.answeredToday)/\(snapshot.goal) today")
                    .font(WidgetType.sans(12))
                    .foregroundStyle(snapshot.goalMet ? WidgetPalette.success : .secondary)
            }

            HStack(spacing: 10) {
                Link(destination: WidgetLink.dailyPractice) {
                    tile(title: "Daily Practice",
                         symbol: "play.fill",
                         tint: WidgetPalette.accent,
                         prominent: true)
                }
                Link(destination: WidgetLink.examCram) {
                    tile(title: "Exam Cram",
                         symbol: "bolt.fill",
                         tint: WidgetPalette.gold,
                         prominent: false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassWidgetBackground()
    }

    private func tile(title: String, symbol: String, tint: Color, prominent: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
            Text(title)
                .font(WidgetType.serif(15))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(prominent ? Color.white : tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassTile(tint: tint, prominent: prominent)
        .accessibilityLabel(title)
    }
}
