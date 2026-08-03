//
//  StudyView.swift
//  LCVI DECA Study App
//
//  The home of the three-pane app: Study · Progress · Settings.
//
//  This screen absorbs what used to be four tabs. Today, Practice, Mock Exams
//  and Roleplay were all the same verb — *study* — scattered across the tab
//  bar with overlapping launch rows. Here the day comes first (greeting, goal
//  ring, streak), then every way to study sits in one two-column garden of
//  tinted tiles, each with its live count. Mock Exams and Roleplay keep their
//  entire screens; they are pushed from their tiles instead of owning tabs.
//
//  This is also where the app-level intents land: widget deep links, the
//  summary screen's "open Mistake Notebook", and "set up a mock exam" all
//  resolve here, because Study is always the first tab.
//

import SwiftUI

struct StudyView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: SessionPayload?
    @State private var showingCramSetup = false
    @State private var showingQuickThink = false
    @State private var pushMistakes = false
    @State private var pushMock = false
    @State private var pushRoleplay = false
    @State private var pushLibrary = false

    private var dash: DashboardState { store.dashboard }
    private var cluster: DECACluster { store.settings.cluster }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
            ScrollView {
                // Groups, not a flat list. Everything here used to sit at one
                // gap, so "Ways to study" was exactly as far from its own
                // tiles as from the streak card above it and the screen read
                // as one undifferentiated column. See `Metrics`.
                VStack(spacing: Metrics.sectionSpacing) {
                    greeting.appearIn(0)

                    // One view now: the goals and the streak were always one
                    // thought, and TodayPanel states it in one vocabulary.
                    todayPanel.appearIn(1).guideAnchor(.goalCard)
                        .id(GuideTarget.goalCard)

                    if dash.questionBankCount == 0 {
                        EmptyStateView(systemImage: "tray",
                                       title: "No questions yet",
                                       message: "Add or import a question bank to start practising.",
                                       actionTitle: "Add questions") {
                            store.openQuestionBankManager()
                        }
                        .appCard()
                        .appearIn(2)
                    } else {
                        waysToStudy.guideAnchor(.waysToStudy)
                            .id(GuideTarget.waysToStudy)
                        insightCards
                    }

                    footerNote.appearIn(9)
                }
                .scrollOffsetProbe()
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .reportsScrollOffset()
            .appCanvas()
            .rootScreenChrome()
            .navigationDestination(isPresented: $pushMistakes) { MistakeNotebookView() }
            .navigationDestination(isPresented: $pushMock)     { MockExamsView() }
            .navigationDestination(isPresented: $pushRoleplay) { RoleplayView() }
            .navigationDestination(isPresented: $pushLibrary)  { LibraryView() }
            // When the tour moves to a stop, bring it on screen first. The
            // anchors are live, so the spotlight follows the scroll.
            .onChange(of: store.guideFocus) { focus in
                guard let focus, focus != .tabBar else { return }
                withAnimation(reduceMotion ? nil : Motion.gentle) {
                    scroller.scrollTo(focus, anchor: .center)
                }
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
        .onChange(of: store.pendingDeepLink) { _ in consumeDeepLink() }
        .onChange(of: store.wantsMistakeNotebook) { _ in consumeIntents() }
        .onChange(of: store.wantsMockExam) { _ in consumeIntents() }
        // A link that arrived before this tab existed (cold launch, or straight
        // out of onboarding) is still waiting here.
        .onAppear {
            consumeDeepLink()
            consumeIntents()
        }
    }

    // MARK: - Greeting

    /// The eyebrow names the student's event when they have one — "EIP ·
    /// Entrepreneurship" — and falls back to the cluster when they are still
    /// undecided.
    private var greeting: some View {
        ScreenHeader(greetingLine,
                     eyebrow: eyebrowText,
                     eyebrowSymbol: cluster.symbol,
                     eyebrowTint: cluster.tint,
                     subtitle: dayLine)
    }

    private var eyebrowText: String {
        guard let event = store.settings.event else { return cluster.displayName }
        return "\(event.code) · \(cluster.shortName)"
    }

    /// The one line on the home screen that changes every day. Streak
    /// first when there is one to protect — that is the thing a student
    /// actually does not want to break.
    private var dayLine: String {
        if dash.today.goalMet {
            return dash.streak.current > 1
                ? "Goal met. \(dash.streak.current) days running."
                : "Goal met for today."
        }
        let left = max(0, store.settings.dailyGoal - dash.today.answered)
        if dash.streak.current > 1 {
            return "\(left) more to keep a \(dash.streak.current)-day streak alive."
        }
        return left == store.settings.dailyGoal
            ? "\(left) questions to start today off."
            : "\(left) to go today."
    }

    private var greetingLine: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<5:   return "Still up"
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    // MARK: - Goal card

    /// The day's two goals, side by side: questions and Quick Thinks. Each
    /// dial owns its own ring, its own slider and its own start button, so
    /// the target can be tuned in the place it is felt rather than buried in
    /// Settings — and Quick Think finally has a goal at all.
    ///
    /// The Quick Think dial is hidden for students whose event has no
    /// roleplay component: the catalogue knows, so the home screen should
    /// not push work their competition will never score.
    private var todayPanel: some View {
        TodayPanel(questionsDone: dash.today.answered,
                   questionsGoal: store.settings.dailyGoal,
                   quickThinkDone: dash.quickThinkToday,
                   quickThinkGoal: store.settings.quickThinkGoal,
                   showsQuickThink: store.settings.eventHasRoleplay,
                   streak: dash.streak.current,
                   freezes: dash.streak.freezes,
                   daysUntilNextFreeze: dash.streak.daysUntilNextFreeze,
                   onQuestions: { startDaily() },
                   onQuickThink: { showingQuickThink = true })
    }

    /// Streak, freezes and the freeze bar — lifted out of the old goal hero
    /// so the dials stay about today and this stays about the run.
    // MARK: - Ways to study

    /// The whole studying surface, visible at once. Launch tiles carry their
    /// live count; navigation tiles carry a chevron.
    private var waysToStudy: some View {
        VStack(spacing: Metrics.headerGap) {
            SectionHeader(title: "Ways to study")
                .appearIn(2)

            // The tiles and the Library banner are one field, held together
            // below the heading rather than each floating at header distance.
            VStack(spacing: 10) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)],
                          spacing: 10) {
                    ModeTile(title: "Review Due", systemImage: "arrow.triangle.2.circlepath",
                             tint: Palette.success, count: dash.dueForReview) {
                        startReviewDue()
                    }
                    .appearIn(3, distance: 10)
                    ModeTile(title: "Mistakes", systemImage: "book.closed.fill",
                             tint: Palette.danger, count: dash.openMistakes) {
                        pushMistakes = true
                    }
                    .appearIn(4, distance: 10)
                    ModeTile(title: "Mock Exams", systemImage: "doc.text.fill",
                             tint: Palette.accent) {
                        pushMock = true
                    }
                    .appearIn(5, distance: 10)
                    ModeTile(title: "Roleplay", systemImage: "person.wave.2.fill",
                             tint: Palette.accent) {
                        pushRoleplay = true
                    }
                    .appearIn(6, distance: 10)
                    ModeTile(title: "Exam Cram", systemImage: "bolt.fill",
                             tint: Palette.gold) {
                        showingCramSetup = true
                    }
                    .appearIn(8, distance: 10)
                    ModeTile(title: "Bookmarks", systemImage: "bookmark.fill",
                             tint: Palette.gold, count: dash.bookmarkedQuestions) {
                        startBookmarked()
                    }
                    .appearIn(9, distance: 10)
                }

                // Six modes make three clean rows; Library then spans the full
                // width beneath them. Left in the grid it was a seventh square
                // stranded beside a gap.
                ModeTile(title: "Library", systemImage: "square.grid.2x2.fill",
                         tint: Palette.accent, isWide: true) {
                    pushLibrary = true
                }
                .appearIn(10, distance: 10)
            }
        }
    }

    // MARK: - Insight card

    /// The weakest performance indicator, and a route to the screen that
    /// explains it. A bare `if let` rather than a stack: one conditional child
    /// emits nothing at all when it fails, where a wrapper would lay out at
    /// zero height and still collect a section gap on each side.
    @ViewBuilder
    private var insightCards: some View {
        if let weakest = dash.weakestIndicator {
            Button {
                Haptics.tap()
                store.requestedTab = .progress
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
        case .reviewDue:     startReviewDue()
        case .quickThink:    showingQuickThink = true
        case .mistakes:
            // Same reset-then-act as consumeIntents: a navigationDestination
            // already true at first render does not push reliably on iOS 16.
            DispatchQueue.main.async { pushMistakes = true }
        }
    }

    /// Reset-then-act, as everywhere: flipping local state after the screen
    /// is mounted pushes reliably on iOS 16.
    private func consumeIntents() {
        if store.wantsMistakeNotebook {
            store.wantsMistakeNotebook = false
            DispatchQueue.main.async { pushMistakes = true }
        }
        if store.wantsMockExam {
            store.wantsMockExam = false
            DispatchQueue.main.async { pushMock = true }
        }
    }

    private func startDaily() {
        let remaining = dash.today.goalMet ? store.settings.dailyGoal : max(1, dash.today.remaining)
        let built = store.sessions.build(.daily(cluster: cluster, count: remaining))
        guard !built.questions.isEmpty else { return }
        session = SessionPayload(session: built)
    }

    private func startReviewDue() {
        guard dash.dueForReview > 0 else { return }
        var options = SessionOptions(mode: .reviewDue, cluster: cluster, count: 20)
        options.cluster = cluster
        let built = store.sessions.build(options)
        guard !built.questions.isEmpty else { return }
        session = SessionPayload(session: built)
    }

    private func startBookmarked() {
        guard dash.bookmarkedQuestions > 0 else { return }
        let built = store.sessions.build(SessionOptions(mode: .bookmarked,
                                                        cluster: cluster,
                                                        count: min(20, dash.bookmarkedQuestions)))
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
