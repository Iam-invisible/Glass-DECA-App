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

    private var greeting: some View {
        ScreenHeader(greetingLine,
                     subtitle: dayLine,
                     event: EventTag(event: store.settings.event,
                                     cluster: store.settings.cluster))
    }

    // MARK: - What the header says

    private var showsQuickThink: Bool { store.settings.eventHasRoleplay }
    private var questionsMet: Bool { dash.today.goalMet }
    private var allGoalsMet: Bool {
        questionsMet && (!showsQuickThink || dash.quickThinkGoalMet)
    }
    private var nothingDoneToday: Bool {
        dash.today.answered == 0 && dash.quickThinkToday == 0
    }

    /// The largest text on the home screen, so it should be the line that says
    /// the most.
    ///
    /// It used to be the time of day — "Morning", "Afternoon" — which is the
    /// one thing on this screen a student can already see on their own status
    /// bar. Everything else in the panel states a number: the ring centre, both
    /// goal cards and the line directly underneath this one. The title was the
    /// only element free to say where the day actually stands, and it was
    /// spending that on the clock.
    ///
    /// All four hold one line at 32pt Michroma to at least 134% Dynamic Type on
    /// an iPhone 8, which is what keeps the header from changing height — and
    /// shifting the whole panel — as the day is worked through. Michroma is
    /// wide enough that this is a real constraint and not a formality: "Done
    /// for today" reads better and wraps at 112%.
    private var greetingLine: String {
        if allGoalsMet { return "Done today" }
        // Only reachable with Quick Think shown and still open; without it,
        // the questions goal is the whole day and the branch above catches it.
        if questionsMet { return "Nearly there" }
        if nothingDoneToday { return "Start today" }
        return "Keep going"
    }

    /// The line under the title. The title says where the day stands; this says
    /// what it will take, and what is at stake when there is a streak running.
    private var dayLine: String {
        let streak = dash.streak.current

        if allGoalsMet {
            if streak > 1 { return "\(streak) days running." }
            if streak == 1 { return "Day one of a new streak." }
            return goalsMetLine
        }

        let questionsLeft = max(0, store.settings.dailyGoal - dash.today.answered)
        let thinksLeft = showsQuickThink
            ? max(0, store.settings.quickThinkGoal - dash.quickThinkToday)
            : 0

        // A streak is the strongest reason to come back, so it leads when there
        // is one to protect. It rides on the questions goal alone, so that is
        // the number it is allowed to name.
        if streak > 1 && questionsLeft > 0 {
            return "\(questionsLeft) more to keep a \(streak)-day streak alive."
        }

        // Both goals, because the panel shows both and naming only the
        // questions left made the Quick Think card look like it was not part
        // of the day.
        var parts: [String] = []
        if questionsLeft > 0 {
            parts.append("\(questionsLeft) question\(questionsLeft == 1 ? "" : "s")")
        }
        if thinksLeft > 0 {
            parts.append("\(thinksLeft) quick think\(thinksLeft == 1 ? "" : "s")")
        }
        guard !parts.isEmpty else { return goalsMetLine }
        return parts.joined(separator: " and ") + " to go."
    }

    /// Goals met with no streak to report. Reachable rather than theoretical:
    /// lowering the daily goal in Settings after answering leaves today met
    /// without the answer that would have advanced a streak.
    private var goalsMetLine: String {
        showsQuickThink ? "Both goals met." : "Goal met for today."
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
                   // Withheld while a session, a mock or Quick Think is over
                   // the top of this screen. The streak always advances inside
                   // one of those, and a card celebrating behind a cover has
                   // celebrated to nobody.
                   pendingCelebration: store.fullScreenLayers == 0
                       ? store.pendingStreakCelebration : nil,
                   onCelebrated: { store.pendingStreakCelebration = nil },
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
