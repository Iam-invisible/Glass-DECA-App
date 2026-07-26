//
//  TodayView.swift
//  LCVI DECA Study App
//
//  The home dashboard: daily goal, streak, and the three ways to start studying.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var switchTab: (AppTab) -> Void

    @State private var session: SessionPayload?
    @State private var showingCramSetup = false
    @State private var showingQuickThink = false
    @State private var showingMistakes = false

    private var dash: DashboardState { store.dashboard }
    private var cluster: DECACluster { store.settings.cluster }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.stackSpacing) {
                    greeting.appearIn(0)
                    goalCard.appearIn(1)
                    actions.appearIn(2)
                    secondaryCards
                    footerNote.appearIn(9)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .appCanvas()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Today").font(.appHeadline).foregroundStyle(Palette.textPrimary)
                }
            }
        }
        .fullScreenCover(item: $session) { payload in
            PracticeSessionView(payload: payload)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingCramSetup) {
            ExamCramSetupView { payload in
                showingCramSetup = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { session = payload }
            }
            .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showingQuickThink) {
            QuickThinkView().environmentObject(store)
        }
        .sheet(isPresented: $showingMistakes) {
            NavigationStack { MistakeNotebookView() }.environmentObject(store)
        }
        .onChange(of: store.pendingDeepLink) { _ in consumeDeepLink() }
        // A link that arrived before this tab existed (cold launch, or straight
        // out of onboarding) is still waiting here.
        .onAppear { consumeDeepLink() }
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingLine)
                .font(.appLargeTitle)
                .foregroundStyle(Palette.textPrimary)
            HStack(spacing: 6) {
                Image(systemName: cluster.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(cluster.tint)
                Text(cluster.displayName)
                    .font(.appCallout)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Today's DECA Practice"
        case 12..<17: return "Today's DECA Practice"
        default:      return "Tonight's DECA Practice"
        }
    }

    // MARK: - Goal card

    private var goalCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 18) {
                ZStack {
                    ProgressRing(progress: dash.today.fraction,
                                 lineWidth: 11,
                                 tint: dash.today.goalMet ? Palette.success : Palette.accent)
                        .frame(width: 96, height: 96)
                    VStack(spacing: 0) {
                        CountingNumber(value: Double(dash.today.answered),
                                       font: .numeric(28),
                                       color: Palette.textPrimary)
                        Text("of \(dash.today.goal)")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                            .monospacedDigit()
                    }
                }

                VStack(alignment: .leading, spacing: 9) {
                    if dash.today.goalMet {
                        Label("Goal complete", systemImage: "checkmark.circle.fill")
                            .font(.appBodyMedium)
                            .foregroundStyle(Palette.success)
                    } else {
                        Text("\(dash.today.remaining) question\(dash.today.remaining == 1 ? "" : "s") to go")
                            .font(.appBodyMedium)
                            .foregroundStyle(Palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    StreakBadge(streak: dash.streak.current, freezes: dash.streak.freezes)

                    if dash.streak.current > 0 {
                        Text("\(dash.streak.daysUntilNextFreeze) more day\(dash.streak.daysUntilNextFreeze == 1 ? "" : "s") to your next freeze")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }

            if dash.streak.current > 0 {
                freezeProgressBar
            }
        }
        .appCard(padding: 18)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Daily goal: \(dash.today.answered) of \(dash.today.goal) questions answered. \(dash.streak.current) day streak.")
    }

    private var freezeProgressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Next streak freeze")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                Text("\(dash.streak.progressToNextFreeze)/10")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.gold)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.cardSunken)
                    Capsule()
                        .fill(Palette.gold)
                        .frame(width: max(4, geo.size.width * Double(dash.streak.progressToNextFreeze) / 10))
                        .animation(reduceMotion ? nil : Motion.gentle, value: dash.streak.progressToNextFreeze)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Next streak freeze: \(dash.streak.progressToNextFreeze) of 10 days")
    }

    // MARK: - Primary actions

    private var actions: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: dash.today.goalMet ? "Keep practising" : "Start Daily Practice",
                          systemImage: "play.fill") {
                startDaily()
            }
            HStack(spacing: 10) {
                SecondaryButton(title: "Exam Cram", systemImage: "bolt.fill") {
                    showingCramSetup = true
                }
                SecondaryButton(title: "Quick Think", systemImage: "brain.head.profile") {
                    showingQuickThink = true
                }
            }
        }
    }

    // MARK: - Secondary cards

    @ViewBuilder
    private var secondaryCards: some View {
        if dash.questionBankCount == 0 {
            EmptyStateView(systemImage: "tray",
                           title: "No questions yet",
                           message: "Add or import a question bank to start practising.",
                           actionTitle: "Open Question Bank Manager") {
                switchTab(.settings)
            }
            .appCard()
            .appearIn(3)
        } else {
            VStack(spacing: 10) {
                if dash.dueForReview > 0 {
                    NavigationRowCard(title: "Review due",
                                      subtitle: "Questions your spaced repetition schedule says are ready.",
                                      systemImage: "arrow.triangle.2.circlepath",
                                      tint: Palette.accent,
                                      badge: "\(dash.dueForReview)") {
                        startReviewDue()
                    }
                    .appearIn(3)
                }

                if dash.openMistakes > 0 {
                    NavigationRowCard(title: "Mistake Notebook",
                                      subtitle: "Questions you've missed, waiting to be mastered.",
                                      systemImage: "book.closed.fill",
                                      tint: Palette.danger,
                                      badge: "\(dash.openMistakes)",
                                      badgeTint: Palette.danger) {
                        showingMistakes = true
                    }
                    .appearIn(4)
                }

                NavigationRowCard(title: dash.mockExamCount == 0 ? "Take your first mock exam" : "Next mock exam",
                                  subtitle: mockSubtitle,
                                  systemImage: "doc.text.fill",
                                  tint: Palette.accent) {
                    switchTab(.mock)
                }
                .appearIn(5)

                if let weakest = dash.weakestIndicator {
                    Button {
                        Haptics.tap()
                        switchTab(.progress)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "target")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Palette.gold)
                                Text("Weakest performance indicator")
                                    .font(.appCaptionBold)
                                    .foregroundStyle(Palette.textSecondary)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            PerformanceIndicatorBar(code: weakest.code,
                                                    text: weakest.text,
                                                    value: weakest.masteryScore,
                                                    detail: "\(weakest.timesCorrect) of \(weakest.timesAnswered) correct so far")
                        }
                        .appCard()
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
                    .appearIn(6)
                }

                if let recent = dash.recentAchievement {
                    HStack(spacing: 13) {
                        AchievementBadge(status: recent, size: 46, showsTitle: false)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Recent achievement")
                                .font(.appCaptionBold)
                                .foregroundStyle(Palette.textSecondary)
                            Text(recent.definition.title)
                                .font(.appBodyMedium)
                                .foregroundStyle(Palette.textPrimary)
                            Text(recent.definition.detail)
                                .font(.appCaption)
                                .foregroundStyle(Palette.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .appCard()
                    .appearIn(7)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var mockSubtitle: String {
        if dash.mockExamCount == 0 {
            return "Take your first mock exam to start tracking scores."
        }
        if let last = dash.lastMockScore {
            return "Last attempt: \(Int(last.rounded()))% · \(dash.mockExamCount) completed"
        }
        return "\(dash.mockExamCount) completed"
    }

    private var footerNote: some View {
        Text("Practice questions in this app are sample study questions, not official DECA Ontario exam content.")
            .font(.appCaption)
            .foregroundStyle(Palette.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // MARK: - Launchers

    private func consumeDeepLink() {
        guard let link = store.pendingDeepLink, session == nil else { return }
        store.pendingDeepLink = nil
        switch link {
        case .dailyPractice: startDaily()
        case .examCram:      showingCramSetup = true
        }
    }

    private func startDaily() {
        let remaining = dash.today.goalMet ? store.settings.dailyGoal : max(1, dash.today.remaining)
        let built = store.sessions.build(.daily(cluster: cluster, count: remaining))
        guard !built.questions.isEmpty else { return }
        session = SessionPayload(session: built)
    }

    private func startReviewDue() {
        var options = SessionOptions(mode: .reviewDue, cluster: cluster, count: 20)
        options.cluster = cluster
        let built = store.sessions.build(options)
        guard !built.questions.isEmpty else { return }
        session = SessionPayload(session: built)
    }
}

// MARK: - Session payload

struct SessionPayload: Identifiable {
    let id = UUID()
    let session: BuiltSession
    var timeLimitSeconds: Double? = nil
    var title: String? = nil
}
