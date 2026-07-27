//
//  PracticeView.swift
//  LCVI DECA Study App
//
//  The practice hub: every way to start a question session.
//

import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var session: SessionPayload?

    private var cluster: DECACluster { store.settings.cluster }
    private var dash: DashboardState { store.dashboard }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.sectionSpacing) {
                    ScreenHeader("Practice",
                                 eyebrow: store.settings.cluster.displayName,
                                 eyebrowSymbol: store.settings.cluster.symbol,
                                 eyebrowTint: store.settings.cluster.tint,
                                 subtitle: dash.questionBankCount == 0 ? nil
                                    : "\(dash.questionBankCount) questions in your bank.")
                        .appearIn(0)

                    if dash.questionBankCount == 0 {
                        EmptyStateView(systemImage: "tray",
                                       title: "No questions yet",
                                       message: "Add or import a question bank to start practising. Settings ▸ Question Bank Manager has manual entry, bulk paste, CSV and JSON import.")
                            .appCard()
                            .appearIn(0)
                    } else {
                        quickStart.appearIn(0)
                        browse.appearIn(1)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .appCanvas()
            .rootScreenChrome()
        }
        .fullScreenCover(item: $session) { payload in
            PracticeSessionView(payload: payload).environmentObject(store)
        }
    }

    // MARK: Quick start

    private var quickStart: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "Start now", subtitle: cluster.displayName)

            NavigationRowCard(title: "Daily Practice",
                              subtitle: "A targeted mix of due reviews, past mistakes, weak indicators and new questions.",
                              systemImage: "sun.max.fill",
                              tint: Palette.accent,
                              badge: dash.today.goalMet ? "Done" : "\(dash.today.remaining) left",
                              badgeTint: dash.today.goalMet ? Palette.success : Palette.accent) {
                launch(.daily(cluster: cluster, count: max(1, dash.today.goalMet ? store.settings.dailyGoal : dash.today.remaining)))
            }

            NavigationRowCard(title: "Review Due",
                              subtitle: dash.dueForReview > 0
                                ? "Spaced repetition questions ready for another look."
                                : "Nothing is due right now — answer more questions to build the schedule.",
                              systemImage: "arrow.triangle.2.circlepath",
                              tint: Palette.success,
                              badge: dash.dueForReview > 0 ? "\(dash.dueForReview)" : nil,
                              badgeTint: Palette.success) {
                guard dash.dueForReview > 0 else { return }
                launch(SessionOptions(mode: .reviewDue, cluster: cluster, count: 20))
            }

            NavigationLink {
                MistakeNotebookView()
            } label: {
                rowLabel(title: "Mistake Notebook",
                         subtitle: dash.openMistakes > 0
                            ? "Missed questions stay here until you get them right twice."
                            : "Mistakes you make during practice will appear here.",
                         systemImage: "book.closed.fill",
                         tint: Palette.danger,
                         badge: dash.openMistakes > 0 ? "\(dash.openMistakes)" : nil,
                         badgeTint: Palette.danger)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))

            NavigationRowCard(title: "Bookmarked Questions",
                              subtitle: dash.bookmarkedQuestions > 0
                                ? "Review the questions you saved for another look."
                                : "Tap the bookmark on any question to save it here.",
                              systemImage: "bookmark.fill",
                              tint: Palette.gold,
                              badge: dash.bookmarkedQuestions > 0 ? "\(dash.bookmarkedQuestions)" : nil,
                              badgeTint: Palette.gold) {
                guard dash.bookmarkedQuestions > 0 else { return }
                launch(SessionOptions(mode: .bookmarked,
                                      cluster: cluster,
                                      count: min(20, dash.bookmarkedQuestions)))
            }
        }
    }

    // MARK: Browse

    private var browse: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "Choose what to study")

            NavigationLink {
                ClusterPracticeList { options in launch(options) }
            } label: {
                rowLabel(title: "By Cluster",
                         subtitle: "Practise any of the six DECA Ontario clusters.",
                         systemImage: "square.grid.2x2.fill",
                         tint: Palette.accent)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))

            NavigationLink {
                TopicPracticeList { options in launch(options) }
            } label: {
                rowLabel(title: "By Topic",
                         subtitle: "Focus on a single tag such as pricing or risk management.",
                         systemImage: "tag.fill",
                         tint: Palette.gold)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))

            NavigationLink {
                IndicatorPracticeList { options in launch(options) }
            } label: {
                rowLabel(title: "By Performance Indicator",
                         subtitle: "Drill the exact indicators judges score you on.",
                         systemImage: "target",
                         tint: Palette.success)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))

            NavigationLink {
                CustomPracticeView { options in launch(options) }
            } label: {
                rowLabel(title: "Custom Practice",
                         subtitle: "Pick the cluster, length, difficulty, tags and question sources.",
                         systemImage: "slider.horizontal.3",
                         tint: Palette.textSecondary)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
        }
    }

    private func rowLabel(title: String,
                          subtitle: String,
                          systemImage: String,
                          tint: Color,
                          badge: String? = nil,
                          badgeTint: Color = Palette.accent) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.appBodyMedium)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if let badge {
                Text(badge)
                    .font(.appCaptionBold)
                    .foregroundStyle(badgeTint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(badgeTint.opacity(0.14)))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.textTertiary)
        }
        .frame(minHeight: Metrics.rowMinHeight)
        .appCard()
        .accessibilityElement(children: .combine)
    }

    private func launch(_ options: SessionOptions) {
        let built = store.sessions.build(options)
        guard !built.questions.isEmpty else { return }
        session = SessionPayload(session: built)
    }
}

// MARK: - By cluster

struct ClusterPracticeList: View {
    @EnvironmentObject private var store: AppStore
    var onStart: (SessionOptions) -> Void

    @State private var counts: [DECACluster: Int] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(DECACluster.allCases) { cluster in
                    let count = counts[cluster] ?? 0
                    NavigationRowCard(title: cluster.displayName,
                                      subtitle: count == 0
                                        ? "No questions in this cluster yet."
                                        : "\(count) question\(count == 1 ? "" : "s") available",
                                      systemImage: cluster.symbol,
                                      tint: cluster.tint,
                                      badge: count > 0 ? "\(min(count, 20))" : nil,
                                      badgeTint: cluster.tint) {
                        guard count > 0 else { return }
                        onStart(SessionOptions(mode: .cluster, cluster: cluster, count: min(count, 20)))
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 12)
        }
        .appCanvas()
        .navigationTitle("By Cluster")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { counts = store.bank.clusterCounts() }
    }
}

// MARK: - By topic

struct TopicPracticeList: View {
    @EnvironmentObject private var store: AppStore
    var onStart: (SessionOptions) -> Void

    @State private var tags: [String] = []
    @State private var scopeToCluster = true

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Toggle("Only my cluster", isOn: $scopeToCluster)
                    .font(.appCallout)
                    .tint(Palette.accent)
                    .appCard(padding: 13)
                    .onChange(of: scopeToCluster) { _ in reload() }

                if tags.isEmpty {
                    EmptyStateView(systemImage: "tag",
                                   title: "No topics yet",
                                   message: "Tag your questions in the Question Bank Manager to practise by topic.")
                        .appCard()
                } else {
                    ForEach(tags, id: \.self) { tag in
                        NavigationRowCard(title: tag.capitalized,
                                          subtitle: "Practise every question tagged \(tag).",
                                          systemImage: "tag.fill",
                                          tint: Palette.gold) {
                            var options = SessionOptions(mode: .topic,
                                                         cluster: scopeToCluster ? store.settings.cluster : nil,
                                                         count: 15)
                            options.tags = [tag]
                            onStart(options)
                        }
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 12)
        }
        .appCanvas()
        .navigationTitle("By Topic")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reload() }
    }

    private func reload() {
        tags = store.bank.allTags(cluster: scopeToCluster ? store.settings.cluster : nil)
    }
}

// MARK: - By performance indicator

struct IndicatorPracticeList: View {
    @EnvironmentObject private var store: AppStore
    var onStart: (SessionOptions) -> Void

    @State private var stats: [IndicatorStat] = []
    @State private var availableCodes: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if stats.isEmpty {
                    EmptyStateView(systemImage: "target",
                                   title: "No indicators yet",
                                   message: "Tag questions with performance indicators to drill them here.")
                        .appCard()
                } else {
                    ForEach(stats) { stat in
                        Button {
                            guard availableCodes.contains(stat.code) else { return }
                            Haptics.tap()
                            var options = SessionOptions(mode: .indicator,
                                                         cluster: nil,
                                                         count: 12)
                            options.indicators = [stat.code]
                            onStart(options)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                PerformanceIndicatorBar(code: stat.code,
                                                        text: stat.text,
                                                        value: stat.masteryScore,
                                                        detail: detail(for: stat))
                            }
                            .appCard()
                            .opacity(availableCodes.contains(stat.code) ? 1 : 0.55)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
                        .disabled(!availableCodes.contains(stat.code))
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 12)
        }
        .appCanvas()
        .navigationTitle("Performance Indicators")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            stats = store.indicators.stats(cluster: store.settings.cluster)
            availableCodes = Set(store.bank.allIndicatorCodes())
        }
    }

    private func detail(for stat: IndicatorStat) -> String {
        guard availableCodes.contains(stat.code) else { return "No questions tagged with this indicator yet" }
        if stat.timesAnswered == 0 { return "Not practised yet — tap to start" }
        return "\(stat.timesCorrect) of \(stat.timesAnswered) correct · \(stat.band.title)"
    }
}
