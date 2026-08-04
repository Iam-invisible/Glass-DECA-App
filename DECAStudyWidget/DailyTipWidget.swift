//
//  DailyTipWidget.swift
//  DECAStudyWidget
//
//  One fact a day from the student's own cluster — on the home screen and on
//  the lock screen.
//
//  Its own `TimelineProvider`, unlike every other widget here. The rest show
//  progress, which changes when the student answers something, so they take a
//  single entry and let the app reload them. A tip changes at midnight and at
//  no other time, and the widget can work out every future tip on its own, so
//  this builds a week of entries ending at each day's start. That is what makes
//  it correct on a phone the app has not been opened on for days — which is
//  precisely the phone this widget is for.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct TipEntry: TimelineEntry {
    let date: Date
    let tip: String
    let clusterShortName: String
}

struct TipProvider: TimelineProvider {
    private static let placeholderTip =
        "Price skimming launches high to capture early adopters, then falls. Penetration pricing does the opposite."

    func placeholder(in context: Context) -> TipEntry {
        TipEntry(date: Date(), tip: Self.placeholderTip, clusterShortName: "Marketing")
    }

    func getSnapshot(in context: Context, completion: @escaping (TipEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TipEntry>) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // A week of days. WidgetKit will usually come back long before the last
        // one is reached, but if it does not — a phone left alone over a school
        // break — the tip still turns over each morning instead of freezing on
        // whichever day the timeline was built.
        var entries: [TipEntry] = [entry(for: Date())]
        for day in 1...7 {
            guard let start = calendar.date(byAdding: .day, value: day, to: today) else { continue }
            entries.append(entry(for: start))
        }

        let refresh = calendar.date(byAdding: .day, value: 1, to: today) ?? Date().addingTimeInterval(86_400)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func entry(for date: Date) -> TipEntry {
        guard let snapshot = WidgetStore.read() else {
            return TipEntry(date: date, tip: Self.placeholderTip, clusterShortName: "Marketing")
        }
        return TipEntry(date: date,
                        tip: WidgetTips.tip(clusterKey: snapshot.clusterKey,
                                            salt: snapshot.tipSalt,
                                            on: date),
                        clusterShortName: snapshot.clusterShortName)
    }
}

// MARK: - Home screen

struct DailyTipWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DECADailyTip", provider: TipProvider()) { entry in
            DailyTipView(entry: entry)
        }
        .configurationDisplayName("Daily fact")
        .description("One fact a day from your cluster.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyTipView: View {
    let entry: TipEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10, weight: .bold))
                Text(entry.clusterShortName.uppercased())
                    .font(WidgetType.sans(10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(WidgetPalette.accent)

            Text(entry.tip)
                .font(WidgetType.sans(family == .systemSmall ? 12 : 14))
                .foregroundStyle(.primary)
                // A tip is the whole content of this widget, so it shrinks to
                // fit rather than truncating. Half a fact is worse than a small
                // one — and the corpus is length-gated by check_tips.py so the
                // shrinking never has far to go.
                .minimumScaleFactor(0.72)
                .lineLimit(family == .systemSmall ? 7 : 5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetLink.dailyPractice)
        .glassWidgetBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.clusterShortName) fact of the day")
        .accessibilityValue(entry.tip)
    }
}

// MARK: - Lock screen

struct DailyTipLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DECADailyTipLock", provider: TipProvider()) { entry in
            DailyTipLockView(entry: entry)
        }
        .configurationDisplayName("Daily fact")
        .description("One fact a day from your cluster, on the lock screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct DailyTipLockView: View {
    let entry: TipEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                // One line, rendered by the system in its own style. No colour
                // and no icon survive here, so anything decorative is wasted.
                Text(entry.tip)

            default:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.clusterShortName.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .widgetAccentable()

                    Text(entry.tip)
                        .font(.system(size: 12))
                        .minimumScaleFactor(0.7)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        // No `glassWidgetBackground()` on the lock screen: accessory families
        // are rendered as a vibrancy mask over the wallpaper, so a fill of our
        // own comes out as a grey slab.
        .widgetURL(WidgetLink.dailyPractice)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.clusterShortName) fact of the day")
        .accessibilityValue(entry.tip)
    }
}
