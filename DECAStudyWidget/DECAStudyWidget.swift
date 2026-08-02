//
//  DECAStudyWidget.swift
//  DECAStudyWidget
//
//  Home-screen widgets: daily progress, streak, questions remaining, quick
//  launch and a full overview. All data is read from the app's local snapshot.
//
//  Text uses `.primary`/`.secondary` rather than fixed colours: with the
//  container background left translucent, content sits on the system's glass
//  over an unknown wallpaper, and only the semantic colours adapt to it.
//
//  Layout rule learned here: a widget's root frame must state its alignment.
//  `.frame(maxWidth: .infinity, maxHeight: .infinity)` with no alignment
//  argument defaults to `.center`, which floats a short stack in the middle of
//  a large widget and reads as a bug rather than a choice. Every root below
//  passes an explicit alignment.
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
                        .frame(width: 48, height: 48)
                    Text("\(snapshot.answeredToday)")
                        .font(WidgetType.display(20))
                        .heroNumeral(tint)
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

    /// The medium used to be a ring plus a left-hugging column, which left the
    /// right third of the widget empty. The stat rail fills it with the three
    /// numbers a student actually glances for.
    private var medium: some View {
        HStack(spacing: 14) {
            ZStack {
                WidgetRing(progress: snapshot.fraction, lineWidth: 9, tint: tint)
                    .frame(width: 74, height: 74)
                VStack(spacing: -2) {
                    Text("\(snapshot.answeredToday)")
                        .font(WidgetType.display(26))
                        .heroNumeral(tint)
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
                    .font(WidgetType.display(20))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

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
            // Greedy, so the column takes the width the old layout wasted.
            .frame(maxWidth: .infinity, alignment: .leading)
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
                .shadow(color: WidgetPalette.gold.opacity(0.45), radius: 7)

            Spacer(minLength: 0)

            Text("\(snapshot.streak)")
                .font(WidgetType.display(46))
                .heroNumeral(WidgetPalette.gold)
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
                .shadow(color: tint.opacity(0.4), radius: 7)

            Spacer(minLength: 0)

            Text(snapshot.goalMet ? "Done" : "\(snapshot.remaining)")
                .font(WidgetType.display(snapshot.goalMet ? 30 : 48))
                .heroNumeral(tint)
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
        // Explicit `.top`: without it this frame centres the stack and the
        // header floats away from the widget's top edge.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .glassWidgetBackground()
    }

    private func tile(title: String, symbol: String, tint: Color, prominent: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
            Text(title)
                .font(WidgetType.display(15))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(prominent ? Color.white : tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassTile(tint: tint, prominent: prominent)
        .accessibilityLabel(title)
    }
}

// MARK: - Overview

/// The large widget: both daily dials, the numbers behind them, the weakest
/// performance indicator, and two launchers.
///
/// This is the only widget that shows anything Progress owns. Everything on it
/// is a number the student would otherwise open the app to see, and every
/// region is a `Link`, so it is a control surface rather than a poster.
struct OverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DECAOverview", provider: DECAProvider()) { entry in
            OverviewWidgetView(entry: entry)
        }
        .configurationDisplayName("Study Overview")
        .description("Both daily goals, your accuracy, review queue, mistakes and weakest indicator.")
        .supportedFamilies(OverviewWidget.families)
    }

    /// `systemExtraLarge` exists only on iPad; listing it is harmless on
    /// iPhone, where the system simply never offers that size.
    static var families: [WidgetFamily] {
        [.systemLarge, .systemExtraLarge]
    }
}

struct OverviewWidgetView: View {
    let entry: DECAEntry
    @Environment(\.widgetFamily) private var family

    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var tint: Color { snapshot.goalMet ? WidgetPalette.success : WidgetPalette.accent }
    private var isExtraLarge: Bool { family == .systemExtraLarge }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            dials
            stats
            if !snapshot.weakestText.isEmpty { weakest }
            Spacer(minLength: 0)
            launchers
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassWidgetBackground()
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WidgetPalette.accent)
            Text(snapshot.clusterShortName)
                .widgetKicker(WidgetPalette.accent)
                .lineLimit(1)
            if !snapshot.eventCode.isEmpty {
                Text(snapshot.eventCode)
                    .font(WidgetType.sans(10, weight: .semibold))
                    .foregroundStyle(WidgetPalette.gold)
                    .glassChip(tint: WidgetPalette.gold)
            }
            Spacer(minLength: 0)
            Text(entry.isPlaceholder ? "Open Glass" : headline)
                .font(WidgetType.sans(11))
                .foregroundStyle(snapshot.goalMet ? WidgetPalette.success : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var headline: String {
        snapshot.goalMet
            ? "Goal complete"
            : "\(snapshot.remaining) to go"
    }

    // MARK: Dials

    /// Both daily goals, matching Study. The Quick Think dial disappears for
    /// events with no roleplay component — the app publishes a goal of 0 to
    /// say so, rather than the widget trying to know the catalogue.
    private var dials: some View {
        HStack(spacing: 14) {
            Link(destination: WidgetLink.dailyPractice) {
                dial(progress: snapshot.fraction,
                     value: "\(snapshot.answeredToday)",
                     of: "of \(snapshot.goal)",
                     caption: "Questions",
                     tint: tint)
            }
            if snapshot.showsQuickThink {
                Link(destination: WidgetLink.quickThink) {
                    dial(progress: snapshot.quickThinkFraction,
                         value: "\(snapshot.quickThinkToday)",
                         of: "of \(snapshot.quickThinkGoal)",
                         caption: "Quick Think",
                         tint: snapshot.quickThinkGoalMet ? WidgetPalette.success : WidgetPalette.gold)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func dial(progress: Double,
                      value: String,
                      of: String,
                      caption: String,
                      tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                WidgetRing(progress: progress, lineWidth: 8, tint: tint)
                    .frame(width: 62, height: 62)
                VStack(spacing: -2) {
                    Text(value)
                        .font(WidgetType.display(23))
                        .heroNumeral(tint)
                    Text(of)
                        .font(WidgetType.sans(9))
                        .foregroundStyle(.secondary)
                }
            }
            Text(caption)
                .font(WidgetType.sans(11, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue("\(value) \(of)")
    }

    // MARK: Stats

    /// Four on a large, six on an iPad's extra large — the extra width is real
    /// estate for more numbers, not for stretching the same four.
    private var stats: some View {
        let cells = statCells
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(cells.prefix(isExtraLarge ? 3 : 2), id: \.label) { $0.view }
            }
            HStack(spacing: 8) {
                ForEach(cells.dropFirst(isExtraLarge ? 3 : 2), id: \.label) { $0.view }
            }
        }
    }

    private struct StatCell {
        let label: String
        let view: WidgetStat
    }

    private var statCells: [StatCell] {
        var cells: [StatCell] = [
            StatCell(label: "Streak",
                     view: WidgetStat(value: "\(snapshot.streak)",
                                      label: "Day streak",
                                      systemImage: "flame.fill",
                                      tint: WidgetPalette.gold)),
            StatCell(label: "Accuracy",
                     view: WidgetStat(value: "\(snapshot.accuracyPercent)%",
                                      label: "Accuracy",
                                      systemImage: "target",
                                      tint: WidgetPalette.success)),
            StatCell(label: "Due",
                     view: WidgetStat(value: "\(snapshot.dueForReview)",
                                      label: "Due to review",
                                      systemImage: "arrow.triangle.2.circlepath",
                                      tint: WidgetPalette.accent)),
            StatCell(label: "Mistakes",
                     view: WidgetStat(value: "\(snapshot.openMistakes)",
                                      label: "Open mistakes",
                                      systemImage: "exclamationmark.triangle.fill",
                                      tint: WidgetPalette.gold))
        ]
        if isExtraLarge {
            cells.append(StatCell(label: "Answered",
                                  view: WidgetStat(value: "\(snapshot.totalAnswered)",
                                                   label: "Answered",
                                                   systemImage: "checkmark.circle.fill",
                                                   tint: WidgetPalette.success)))
            cells.append(StatCell(label: "Badges",
                                  view: WidgetStat(value: "\(snapshot.achievements)",
                                                   label: "Badges",
                                                   systemImage: "rosette",
                                                   tint: WidgetPalette.gold)))
        }
        return cells
    }

    // MARK: Weakest indicator

    private var weakest: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.system(size: 9, weight: .bold))
                Text("Weakest indicator")
                    .widgetKicker(WidgetPalette.accent)
            }
            .foregroundStyle(WidgetPalette.accent)

            Text(snapshot.weakestCode.isEmpty
                 ? snapshot.weakestText
                 : "\(snapshot.weakestCode) · \(snapshot.weakestText)")
                .font(WidgetType.sans(11))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Launchers

    private var launchers: some View {
        HStack(spacing: 8) {
            Link(destination: WidgetLink.dailyPractice) {
                launchTile(title: "Practice", symbol: "play.fill",
                           tint: WidgetPalette.accent, prominent: true)
            }
            Link(destination: snapshot.dueForReview > 0 ? WidgetLink.reviewDue : WidgetLink.examCram) {
                launchTile(title: snapshot.dueForReview > 0 ? "Review" : "Cram",
                           symbol: snapshot.dueForReview > 0 ? "arrow.triangle.2.circlepath" : "bolt.fill",
                           tint: WidgetPalette.gold, prominent: false)
            }
            Link(destination: WidgetLink.mistakes) {
                launchTile(title: "Mistakes", symbol: "exclamationmark.triangle.fill",
                           tint: WidgetPalette.accent, prominent: false)
            }
        }
        .frame(height: 46)
    }

    private func launchTile(title: String, symbol: String, tint: Color, prominent: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(WidgetType.display(15))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(prominent ? Color.white : tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassTile(tint: tint, prominent: prominent)
        .accessibilityLabel(title)
    }
}
