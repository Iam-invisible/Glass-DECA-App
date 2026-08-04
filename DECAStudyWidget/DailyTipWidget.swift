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
    let clusterKey: String

    /// The cluster's glyph, mirroring `DECACluster.symbol`. Duplicated for the
    /// same reason everything else here is: the extension cannot import the app.
    var symbol: String {
        switch clusterKey {
        case "finance":                   return "chart.line.uptrend.xyaxis"
        case "hospitality":               return "fork.knife"
        case "businessManagement":        return "building.2.fill"
        case "entrepreneurship":          return "lightbulb.fill"
        case "personalFinancialLiteracy": return "creditcard.fill"
        default:                          return "megaphone.fill"
        }
    }
}

struct TipProvider: TimelineProvider {
    private static let placeholderTip =
        "Price skimming launches high to capture early adopters, then falls. Penetration pricing does the opposite."

    func placeholder(in context: Context) -> TipEntry {
        TipEntry(date: Date(), tip: Self.placeholderTip,
                 clusterShortName: "Marketing", clusterKey: "marketing")
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
            return TipEntry(date: date, tip: Self.placeholderTip,
                            clusterShortName: "Marketing", clusterKey: "marketing")
        }
        return TipEntry(date: date,
                        tip: WidgetTips.tip(clusterKey: snapshot.clusterKey,
                                            salt: snapshot.tipSalt,
                                            on: date),
                        clusterShortName: snapshot.clusterShortName,
                        clusterKey: snapshot.clusterKey)
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

/// The home-screen fact.
///
/// Medium is a landscape box roughly 305×130pt once the system's own padding is
/// taken off, and the corpus averages 96 characters. At the 14pt it used to be
/// set at, that is a couple of lines against the top edge and half the widget
/// left empty — a small widget's layout stretched sideways.
///
/// So medium gets its own arrangement rather than a shared one: the same
/// inline header the small widget uses, the fact set large enough to be the
/// object rather than a caption and centred in everything below the header,
/// and the cluster's own symbol carried through the background at low contrast
/// so the empty corner is doing something. Small keeps the compact stack,
/// because at 141pt square there is nothing spare to spend.
struct DailyTipView: View {
    let entry: TipEntry
    @Environment(\.widgetFamily) private var family

    private var isMedium: Bool { family == .systemMedium }

    var body: some View {
        Group {
            if isMedium { medium } else { small }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetLink.dailyPractice)
        .tipWidgetBackground(symbol: entry.symbol, prominent: isMedium)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.clusterShortName) fact of the day")
        .accessibilityValue(entry.tip)
    }

    // MARK: Medium

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The small widget's header, kept: glyph and cluster inline along
            // the top. The tile that used to sit on the left read as a second
            // object competing with the fact, and it cost 58pt of the column —
            // width the fact now has, which is most of a line back.
            HStack(spacing: 6) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 11, weight: .bold))
                Text(entry.clusterShortName.uppercased())
                    .font(WidgetType.sans(10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                Text("FACT OF THE DAY")
                    .font(WidgetType.sans(9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .foregroundStyle(WidgetPalette.accent)

            // Ranged left, sitting in the middle. `Alignment.leading` is
            // horizontally leading and vertically centre, which is exactly the
            // pair wanted: prose keeps the straight left edge that makes it
            // easy to read, and the block still sits in the middle of the space
            // rather than falling to the top of it.
            //
            // 20pt. Instrument Serif is narrow enough that every one of the 605
            // facts fits in three lines at this size — 511 take three and 94
            // take two — and not one is scaled down. 21pt is where nine of them
            // start needing a fourth. The lineLimit is 4 rather than 3 so a
            // longer fact added later wraps and shrinks a little instead of
            // being cut off mid-sentence.
            Text(entry.tip)
                .font(WidgetType.serif(20))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .minimumScaleFactor(0.62)
                .lineLimit(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 10, weight: .bold))
                Text(entry.clusterShortName.uppercased())
                    .font(WidgetType.sans(10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(WidgetPalette.accent)

            // The same serif as medium, and it is the better face here too —
            // which was not true of the system serif this replaced. Instrument
            // Serif is narrow, so a fact reaches five lines in a 126pt column
            // where Manrope reached seven: at 13pt every one of the 605 fits
            // without being scaled, against 311 of them shrinking under Manrope
            // at 12.5pt. Its x-height is 6.6pt to Manrope's 6.8pt, so almost
            // none of that is paid for in apparent size.
            //
            // A tip is the whole content of this widget, so it shrinks to fit
            // rather than truncating. Half a fact is worse than a small one —
            // and the corpus is length-gated by check_tips.py so the shrinking
            // never has far to go.
            Text(entry.tip)
                .font(WidgetType.serif(13))
                .foregroundStyle(.primary)
                .lineSpacing(1)
                .minimumScaleFactor(0.72)
                .lineLimit(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private extension View {
    /// The house glass, plus the cluster's own symbol bled off the trailing
    /// edge at low contrast.
    ///
    /// It goes inside `containerBackground` rather than in an overlay, which is
    /// what the API is for: the system clips it to the widget's corner radius,
    /// so a glyph running past the edge is cropped by the shape instead of
    /// needing a `clipShape` that would also crop the content.
    @ViewBuilder
    func tipWidgetBackground(symbol: String, prominent: Bool) -> some View {
        let backdrop = ZStack {
            WidgetGlass.containerFill
            if prominent {
                Image(systemName: symbol)
                    .font(.system(size: 150, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accent.opacity(0.09))
                    .rotationEffect(.degrees(-14))
                    .offset(x: 46, y: 30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }

        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { backdrop }
        } else {
            self.padding(12).background(backdrop)
        }
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
        // An empty container background, not a missing one. Accessory families
        // must not paint a fill — the system renders them as a vibrancy mask
        // over the wallpaper, so anything of ours comes out as a grey slab —
        // but skipping the call entirely makes iOS 17 replace the whole widget
        // with "Please adopt containerBackground API".
        .accessoryWidgetContainer()
        .widgetURL(WidgetLink.dailyPractice)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.clusterShortName) fact of the day")
        .accessibilityValue(entry.tip)
    }
}
