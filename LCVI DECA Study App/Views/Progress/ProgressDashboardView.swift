//
//  ProgressDashboardView.swift
//  LCVI DECA Study App
//
//  Analytics without overwhelming the screen: headline stats first, then
//  breakdowns, then achievements.
//

import SwiftUI

struct ProgressDashboardView: View {
    @EnvironmentObject private var store: AppStore

    @State private var indicatorStats: [IndicatorStat] = []
    @State private var suggested: [IndicatorStat] = []
    @State private var availableIndicatorCodes: Set<String> = []
    @State private var clusterAccuracy: [DECACluster: (correct: Int, total: Int)] = [:]
    @State private var tagAccuracy: [(tag: String, correct: Int, total: Int)] = []
    @State private var mockSummaries: [MockExamSummary] = []
    @State private var weekHistory: [DailyProgressSnapshot] = []
    @State private var achievements: [AchievementStatus] = []
    @State private var showAllIndicators = false
    @State private var aiAdvice: String?
    @State private var loadingAdvice = false
    @State private var session: SessionPayload?

    private var dash: DashboardState { store.dashboard }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.sectionSpacing) {
                    ScrollOffsetProbe()
                    ScreenHeader("Progress",
                                 eyebrow: store.settings.cluster.displayName,
                                 eyebrowSymbol: store.settings.cluster.symbol,
                                 eyebrowTint: store.settings.cluster.tint,
                                 subtitle: "Everything you've answered, and what it says about exam day.")
                        .appearIn(0)

                    todaySection.appearIn(0)
                    headlineStats.appearIn(1)
                    weekSection.appearIn(2)
                    if !clusterAccuracy.isEmpty { clusterSection.appearIn(3) }
                    if !indicatorStats.isEmpty { heatmapSection.appearIn(4) }
                    indicatorSection.appearIn(5)
                    if !tagAccuracy.isEmpty { topicSection.appearIn(6) }
                    if !mockSummaries.isEmpty { mockSection.appearIn(7) }
                    if store.ai.isUsable { adviceSection.appearIn(8) }
                    achievementSection.appearIn(9)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .reportsScrollOffset()
            .appCanvas()
            .rootScreenChrome()
        }
        .onAppear(perform: reload)
        .fullScreenCover(item: $session) { payload in
            PracticeSessionView(payload: payload).environmentObject(store)
        }
    }

    // MARK: Today

    private var todaySection: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: dash.today.fraction,
                             lineWidth: 10,
                             tint: dash.today.goalMet ? Palette.success : Palette.accent)
                    .frame(width: 84, height: 84)
                VStack(spacing: 0) {
                    Text("\(dash.today.answered)")
                        .font(.numeric(24))
                        .foregroundStyle(Palette.textPrimary)
                    Text("/ \(dash.today.goal)")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                        .monospacedDigit()
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily goal")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                StreakBadge(streak: dash.streak.current, freezes: dash.streak.freezes, compact: true)
                Text("Longest streak: \(dash.streak.longest) day\(dash.streak.longest == 1 ? "" : "s")")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .appCard(padding: 17)
        .accessibilityElement(children: .combine)
    }

    // MARK: Headline stats

    private var headlineStats: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatCard(title: "Answered", value: "\(dash.totalQuestionsAnswered)",
                         caption: "questions total", systemImage: "checkmark.circle")
                StatCard(title: "Accuracy", value: "\(Int((dash.overallAccuracy * 100).rounded()))%",
                         caption: "all time", systemImage: "target",
                         tint: dash.overallAccuracy >= 0.75 ? Palette.success : Palette.gold)
            }
            HStack(spacing: 10) {
                StatCard(title: "Review due", value: "\(dash.dueForReview)",
                         caption: "questions ready", systemImage: "arrow.triangle.2.circlepath")
                StatCard(title: "Mastered", value: "\(dash.mistakesMastered)",
                         caption: "past mistakes fixed", systemImage: "arrow.uturn.up",
                         tint: Palette.success)
            }
            HStack(spacing: 10) {
                StatCard(title: "Roleplays", value: "\(dash.roleplayCount)",
                         caption: "practices saved", systemImage: "person.wave.2")
                StatCard(title: "Quick Think", value: "\(dash.quickThinkCount)",
                         caption: "sessions done", systemImage: "brain.head.profile")
            }
        }
    }

    // MARK: Week

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Last 7 days")
            HStack(alignment: .bottom, spacing: 7) {
                ForEach(weekHistory, id: \.dayKey) { day in
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(day.goalMet ? Palette.success
                                          : (day.answered > 0 ? Palette.accent : Palette.cardSunken))
                                    .frame(height: max(6, geo.size.height * barFraction(day)))
                            }
                        }
                        .frame(height: 66)
                        Text(weekdayLabel(day.dayKey))
                            .font(.appSans(10, weight: .medium))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(weekdayLabel(day.dayKey)): \(day.answered) questions")
                }
            }
            .appCard(padding: 15)
        }
    }

    private func barFraction(_ day: DailyProgressSnapshot) -> Double {
        let peak = max(1, weekHistory.map(\.answered).max() ?? 1, day.goal)
        return min(1, Double(day.answered) / Double(peak))
    }

    private func weekdayLabel(_ dayKey: String) -> String {
        guard let date = DayKey.date(from: dayKey) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    // MARK: Clusters

    private var clusterSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Accuracy by cluster")
            VStack(spacing: 13) {
                ForEach(DECACluster.allCases.filter { clusterAccuracy[$0] != nil }) { cluster in
                    let entry = clusterAccuracy[cluster]!
                    LabeledBar(label: cluster.shortName,
                               value: entry.total == 0 ? 0 : Double(entry.correct) / Double(entry.total),
                               caption: "\(entry.correct)/\(entry.total)",
                               tint: cluster.tint)
                }
            }
            .appCard()
        }
    }

    // MARK: Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "PI heatmap",
                          subtitle: "Tap a tile to drill")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)],
                      alignment: .leading,
                      spacing: 8) {
                ForEach(indicatorStats) { stat in
                    let available = availableIndicatorCodes.contains(stat.code)
                    Button {
                        guard available else { return }
                        startIndicatorDrill(stat)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 4) {
                                Text(stat.code)
                                    .font(.appCaptionBold)
                                    .foregroundStyle(available ? Palette.textPrimary : Palette.textTertiary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                Spacer(minLength: 0)
                                if stat.roleplayCount > 0 {
                                    Image(systemName: "person.wave.2.fill")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(tileTint(for: stat))
                                }
                            }

                            Text("\(Int((stat.masteryScore * 100).rounded()))%")
                                .font(.numeric(18, weight: .semibold))
                                .foregroundStyle(tileTint(for: stat))
                                .monospacedDigit()

                            Text(stat.band.title)
                                .font(.appSans(10, weight: .medium))
                                .foregroundStyle(Palette.textTertiary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(tileTint(for: stat).opacity(available ? 0.13 : 0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(tileTint(for: stat).opacity(available ? 0.35 : 0.12), lineWidth: 0.8)
                        )
                        .opacity(available ? 1 : 0.52)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.98, haptic: false))
                    .disabled(!available)
                    .accessibilityLabel("\(stat.code), \(stat.band.title), \(Int((stat.masteryScore * 100).rounded())) percent mastery")
                }
            }
        }
    }

    private func tileTint(for stat: IndicatorStat) -> Color {
        stat.band == .untouched ? Palette.textTertiary : stat.band.color
    }

    private func startIndicatorDrill(_ stat: IndicatorStat) {
        Haptics.tap()
        var options = SessionOptions(mode: .indicator, cluster: nil, count: 12)
        options.indicators = [stat.code]
        let built = store.sessions.build(options)
        guard !built.questions.isEmpty else { return }
        session = SessionPayload(session: built, title: "PI \(stat.code)")
    }

    // MARK: Indicators

    private var indicatorSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Performance indicators",
                          subtitle: store.settings.cluster.shortName,
                          actionTitle: showAllIndicators ? "Show less" : "Show all") {
                withAnimation(Motion.snappy) { showAllIndicators.toggle() }
            }

            if indicatorStats.isEmpty {
                EmptyStateView(systemImage: "target",
                               title: "No indicator data yet",
                               message: "Answer questions tagged with performance indicators to see mastery here.")
                    .appCard()
            } else {
                VStack(spacing: 14) {
                    ForEach(displayedIndicators) { stat in
                        PerformanceIndicatorBar(code: stat.code,
                                                text: stat.text,
                                                value: stat.masteryScore,
                                                detail: detail(for: stat))
                    }
                }
                .appCard()

                if !suggested.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Study these next", systemImage: "arrow.right.circle")
                            .font(.appCaptionBold)
                            .foregroundStyle(Palette.accent)
                        ForEach(suggested) { stat in
                            HStack(alignment: .top, spacing: 8) {
                                Text(stat.code)
                                    .font(.appCaptionBold)
                                    .foregroundStyle(Palette.accent)
                                    .frame(width: 52, alignment: .leading)
                                Text(stat.text)
                                    .font(.appFootnote)
                                    .foregroundStyle(Palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
                }
            }
        }
    }

    private var displayedIndicators: [IndicatorStat] {
        let practiced = indicatorStats.filter { $0.timesAnswered > 0 || $0.roleplayCount > 0 }
        let sorted = practiced.sorted { $0.masteryScore > $1.masteryScore }
        if showAllIndicators { return indicatorStats.sorted { $0.masteryScore > $1.masteryScore } }
        return Array(sorted.prefix(5))
    }

    private func detail(for stat: IndicatorStat) -> String {
        if stat.timesAnswered == 0 && stat.roleplayCount == 0 { return "Not practised yet" }
        var parts = ["\(stat.timesCorrect)/\(stat.timesAnswered) correct"]
        if stat.roleplayCount > 0 {
            parts.append("\(stat.roleplayCount) roleplay\(stat.roleplayCount == 1 ? "" : "s")")
        }
        parts.append(stat.band.title)
        return parts.joined(separator: " · ")
    }

    // MARK: Topics

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Accuracy by topic")
            VStack(spacing: 13) {
                ForEach(tagAccuracy.prefix(6), id: \.tag) { row in
                    LabeledBar(label: row.tag.capitalized,
                               value: row.total == 0 ? 0 : Double(row.correct) / Double(row.total),
                               caption: "\(row.correct)/\(row.total)",
                               tint: barTint(row.total == 0 ? 0 : Double(row.correct) / Double(row.total)))
                }
            }
            .appCard()
        }
    }

    private func barTint(_ value: Double) -> Color {
        switch value {
        case 0.85...:    return Palette.success
        case 0.6..<0.85: return Palette.accent
        default:         return Palette.danger
        }
    }

    // MARK: Mock exams

    private var mockSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Mock exam scores",
                          subtitle: "\(mockSummaries.count) attempt\(mockSummaries.count == 1 ? "" : "s")")
            ScoreTrendChart(summaries: mockSummaries.reversed())
                .appCard()
        }
    }

    // MARK: AI advice

    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Study advice")
            VStack(alignment: .leading, spacing: 10) {
                Label("On-device coaching", systemImage: "sparkles")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.accent)

                if let aiAdvice {
                    Text(aiAdvice)
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if loadingAdvice {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Reviewing your weak areas on device…")
                            .font(.appFootnote)
                            .foregroundStyle(Palette.textSecondary)
                    }
                } else {
                    Button {
                        Haptics.tap()
                        requestAdvice()
                    } label: {
                        Label("Get study advice for my weak areas", systemImage: "sparkles")
                            .font(.appFootnote.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        }
    }

    private func requestAdvice() {
        guard store.ai.isUsable, !loadingAdvice else { return }
        loadingAdvice = true
        let weak = store.indicators.weakest(cluster: store.settings.cluster, limit: 3)
        let weakTopics = tagAccuracy
            .filter { $0.total >= 2 && Double($0.correct) / Double($0.total) < 0.7 }
            .prefix(3)
            .map(\.tag)
        Task { @MainActor in
            aiAdvice = await store.ai.studyAdvice(cluster: store.settings.cluster,
                                                  weakIndicators: weak,
                                                  weakTopics: Array(weakTopics),
                                                  accuracy: dash.overallAccuracy)
            loadingAdvice = false
            if aiAdvice != nil { Haptics.tap() }
        }
    }

    // MARK: Achievements

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Achievements",
                          subtitle: "\(achievements.filter(\.isUnlocked).count) of \(achievements.count) unlocked")
            NavigationLink {
                AchievementsView()
            } label: {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                          spacing: 14) {
                    ForEach(achievements.prefix(8)) { status in
                        AchievementBadge(status: status, size: 54, showsTitle: false)
                    }
                }
                .appCard()
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
        }
    }

    // MARK: Load

    private func reload() {
        store.refresh()
        indicatorStats = store.indicators.stats(cluster: store.settings.cluster)
        suggested = store.indicators.suggested(cluster: store.settings.cluster, limit: 3)
        availableIndicatorCodes = Set(store.bank.allIndicatorCodes())
        clusterAccuracy = store.sessions.accuracyByCluster()
        tagAccuracy = store.sessions.accuracyByTag(cluster: nil)
        mockSummaries = store.mocks.summaries()
        weekHistory = store.streaks.history(days: 7, goal: store.settings.dailyGoal)
        achievements = store.achievements.statuses()
    }
}

// MARK: - Achievements grid

struct AchievementsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var statuses: [AchievementStatus] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                if !unlocked.isEmpty {
                    section(title: "Unlocked", items: unlocked)
                }
                if !locked.isEmpty {
                    section(title: "Still to earn", items: locked)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 14)
        }
        .appCanvas()
        .navigationTitle("Achievements")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { statuses = store.achievements.statuses() }
    }

    private var unlocked: [AchievementStatus] { statuses.filter(\.isUnlocked) }
    private var locked: [AchievementStatus] { statuses.filter { !$0.isUnlocked } }

    private func section(title: String, items: [AchievementStatus]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: title,
                          subtitle: items.first?.isUnlocked == true
                            ? "\(items.count) · tap to replay"
                            : "\(items.count)")
            VStack(spacing: 10) {
                ForEach(items) { status in
                    if status.isUnlocked {
                        Button {
                            // Reuses the app's celebration overlay so a student
                            // can watch a badge they've already earned again.
                            store.enqueue(.achievement(status.definition))
                        } label: {
                            row(status)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.98))
                    } else {
                        row(status)
                    }
                }
            }
        }
    }

    private func row(_ status: AchievementStatus) -> some View {
        HStack(spacing: 13) {
            AchievementBadge(status: status, size: 48, showsTitle: false)
            VStack(alignment: .leading, spacing: 3) {
                Text(status.definition.title)
                    .font(.appBodyMedium)
                    .foregroundStyle(status.isUnlocked ? Palette.textPrimary : Palette.textSecondary)
                    .multilineTextAlignment(.leading)
                Text(status.definition.detail)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let date = status.unlockedAt {
                    Text("Earned \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.appCaption)
                        .foregroundStyle(status.definition.isGold ? Palette.gold : Palette.accent)
                }
            }
            Spacer(minLength: 0)
            if status.isUnlocked {
                Image(systemName: "play.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint(status.isUnlocked ? "Replays the unlock animation" : "")
    }
}
