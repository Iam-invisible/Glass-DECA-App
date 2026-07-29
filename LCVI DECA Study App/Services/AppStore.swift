//
//  AppStore.swift
//  LCVI DECA Study App
//
//  The single coordination point: owns persistence, every service, and the
//  derived numbers the dashboard reads. All work is local and synchronous.
//

import Combine
import CoreData
import Foundation
import SwiftUI

/// Something worth celebrating, surfaced as an overlay.
enum AppEvent: Identifiable, Equatable {
    case goalCompleted(streak: Int)
    case freezeEarned(total: Int)
    case achievement(AchievementDefinition)

    var id: String {
        switch self {
        case .goalCompleted:              return "goal"
        case .freezeEarned:               return "freeze"
        case .achievement(let def):       return "achievement-\(def.code)"
        }
    }
}

/// Everything the Today tab and widgets display.
struct DashboardState: Equatable {
    var today = DailyProgressSnapshot(dayKey: "", answered: 0, correct: 0, goal: 10,
                                      goalMet: false, secondsStudied: 0)
    var streak = StreakState()
    var dueForReview = 0
    var openMistakes = 0
    var mistakesMastered = 0
    var totalQuestionsAnswered = 0
    var overallAccuracy: Double = 0
    var questionBankCount = 0
    var bookmarkedQuestions = 0
    var mockExamCount = 0
    var lastMockScore: Double? = nil
    var roleplayCount = 0
    var quickThinkCount = 0
    var achievementsUnlocked = 0
    var weakestIndicator: IndicatorStat? = nil
    var recentAchievement: AchievementStatus? = nil
}

@MainActor
final class AppStore: ObservableObject {

    // Infrastructure
    let persistence: PersistenceController
    var context: NSManagedObjectContext { persistence.viewContext }

    // Preferences
    let settings: UserSettings
    let streakStore: StreakStore

    // Services
    let bank: QuestionBankService
    let sr: SpacedRepetitionService
    let mistakes: MistakeNotebookService
    let indicators: PerformanceIndicatorService
    let sessions: PracticeSessionService
    let mocks: MockExamService
    let streaks: StreakService
    let achievements: AchievementService
    let notifications: NotificationService
    let importExport: ImportExportService
    let ai: FoundationModelFeedbackService
    /// Second AI tier for devices Apple Intelligence does not reach.
    /// Nothing downloads unless the student asks for it.
    let localModel: LocalModelService

    // Derived state
    @Published private(set) var dashboard = DashboardState()
    @Published var eventQueue: [AppEvent] = []
    /// How many full-screen flows are currently presented. A `fullScreenCover`
    /// draws above anything the root view can, so celebrations have to be
    /// hosted by the top-most layer rather than always by the root.
    @Published var fullScreenLayers = 0
    /// Set when the user taps a widget or a shortcut into a specific flow.
    @Published var pendingDeepLink: DeepLink? = nil

    // MARK: Navigation intents
    //
    // The app used to *describe* routes — "Settings ▸ Question Bank Manager
    // has manual entry…" — and leave the student to walk them. These let any
    // screen hand the walk to the app instead: RootView consumes the tab
    // switch, and the destination screen consumes its own push. Both are
    // consumed with a reset-then-act pattern so a stale intent can never
    // re-fire on a later visit.

    /// A tab some screen wants selected. RootView consumes and clears it.
    @Published var requestedTab: AppTab? = nil
    /// Settings should push the Question Bank Manager when it next appears.
    @Published var wantsQuestionBank = false
    /// Study should push the Mistake Notebook when it next appears.
    @Published var wantsMistakeNotebook = false
    /// Study should push Mock Exams when it next appears.
    @Published var wantsMockExam = false
    /// The guided tour overlay. Fired automatically the moment onboarding
    /// hands over, and replayable from Settings.
    @Published var showGuide = false

    /// One tap from any "no questions yet" state to the place that fixes it.
    func openQuestionBankManager() {
        wantsQuestionBank = true
        requestedTab = .settings
    }

    func openMistakeNotebook() {
        wantsMistakeNotebook = true
        requestedTab = .study
    }

    func openMockExams() {
        wantsMockExam = true
        requestedTab = .study
    }
    /// Shown on every cold launch. Not persisted — a fresh process means a
    /// fresh reveal, and Settings can re-arm it.
    @Published var showIntro = true

    /// `UserSettings` publishes its own changes. Without forwarding them,
    /// anything observing `AppStore` (which is every screen) never hears about
    /// a preference change and silently fails to redraw.
    private var settingsBridge: AnyCancellable?

    enum DeepLink: Equatable {
        case dailyPractice
        case examCram
    }

    init(inMemory: Bool = false) {
        let persistence = PersistenceController(inMemory: inMemory)
        self.persistence = persistence

        let settings = UserSettings()
        self.settings = settings
        let streakStore = StreakStore()
        self.streakStore = streakStore

        let ctx = persistence.viewContext
        let bank = QuestionBankService(context: ctx)
        let sr = SpacedRepetitionService(context: ctx)
        let mistakes = MistakeNotebookService(context: ctx, bank: bank, sr: sr)
        let indicators = PerformanceIndicatorService(context: ctx)
        let sessions = PracticeSessionService(context: ctx, bank: bank, sr: sr,
                                              mistakes: mistakes, indicators: indicators)

        self.bank = bank
        self.sr = sr
        self.mistakes = mistakes
        self.indicators = indicators
        self.sessions = sessions
        self.mocks = MockExamService(context: ctx, bank: bank, indicators: indicators, sessions: sessions)
        self.streaks = StreakService(context: ctx, store: streakStore)
        self.achievements = AchievementService(context: ctx)
        self.notifications = NotificationService()
        self.importExport = ImportExportService(context: ctx, bank: bank)
        self.ai = FoundationModelFeedbackService()
        self.localModel = LocalModelService()

        self.ai.userEnabled = settings.aiEnabled
        Haptics.enabled = settings.hapticsEnabled
        SoundEffects.enabled = settings.soundEnabled

        bank.seedIfNeeded()
        if settings.seededVersion < QuestionBankService.seedVersion {
            settings.seededVersion = QuestionBankService.seedVersion
        }
        streaks.reconcile()
        refresh()

        settingsBridge = settings.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Lifecycle

    func onAppear() {
        ai.userEnabled = settings.aiEnabled
        ai.refreshAvailability()
        streaks.reconcile()
        refresh()
        Haptics.prepare()
        SoundEffects.prepare()
        Task { await notifications.refreshAuthorization() }
    }

    func onForeground() {
        streaks.reconcile()
        refresh()
        ai.refreshAvailability()
    }

    // MARK: - Derived state

    func refresh() {
        var state = DashboardState()
        state.today = streaks.snapshot(goal: settings.dailyGoal)
        state.streak = streakStore.state
        state.dueForReview = sr.dueCount()
        state.openMistakes = mistakes.openMistakeCount()
        state.mistakesMastered = mistakes.masteredCount()
        state.totalQuestionsAnswered = sr.totalAnswered()
        state.overallAccuracy = sr.overallAccuracy()
        state.questionBankCount = bank.questionCount()
        state.bookmarkedQuestions = bank.bookmarkedCount(cluster: settings.cluster)
        state.mockExamCount = mocks.attemptCount()
        state.lastMockScore = mocks.summaries(limit: 1).first?.scorePercent
        state.roleplayCount = context.count(entity: AppModel.entityNames.roleplayResponse)
        state.quickThinkCount = context.count(entity: AppModel.entityNames.quickThink)
        state.achievementsUnlocked = achievements.unlockedCount()
        state.weakestIndicator = indicators.weakest(cluster: settings.cluster, limit: 1).first
        state.recentAchievement = achievements.mostRecent()
        dashboard = state

        publishWidgetSnapshot(state)
    }

    private func publishWidgetSnapshot(_ state: DashboardState) {
        WidgetDataService.write(WidgetSnapshot(
            clusterShortName: settings.cluster.shortName,
            answeredToday: state.today.answered,
            goal: state.today.goal,
            streak: state.streak.current,
            freezes: state.streak.freezes,
            dueForReview: state.dueForReview,
            updatedAt: Date()
        ))
    }

    // MARK: - The single answer pipeline

    /// Everything that happens when a question is answered anywhere in the app.
    func recordAnswer(question: QuestionData,
                      selectedIndex: Int,
                      seconds: Double,
                      sessionID: UUID?,
                      mode: PracticeMode,
                      countsTowardDailyGoal: Bool = true) {
        let isCorrect = selectedIndex == question.correctIndex

        sr.record(questionID: question.id, correct: isCorrect)
        indicators.recordAnswer(indicators: question.performanceIndicators,
                                cluster: question.cluster,
                                correct: isCorrect)

        if isCorrect {
            mistakes.recordCorrect(questionID: question.id)
        } else {
            mistakes.recordMistake(question: question, selectedIndex: selectedIndex)
        }

        if let sessionID {
            sessions.recordAnswer(sessionID: sessionID,
                                  question: question,
                                  selectedIndex: selectedIndex,
                                  isCorrect: isCorrect,
                                  seconds: seconds)
        }

        if countsTowardDailyGoal {
            let outcome = streaks.recordAnswers(count: 1,
                                                correct: isCorrect ? 1 : 0,
                                                seconds: seconds,
                                                goal: settings.dailyGoal)
            handle(outcome)
        }
        _ = mode
        refresh()
    }

    /// Records a completed session and evaluates achievements.
    func finishPracticeSession(sessionID: UUID?,
                               mode: PracticeMode,
                               questionCount: Int,
                               correctCount: Int,
                               seconds: Double) {
        if let sessionID {
            sessions.finishSession(sessionID: sessionID,
                                   questionCount: questionCount,
                                   correctCount: correctCount,
                                   seconds: seconds)
        }
        evaluateAchievements()
        refresh()
    }

    func handle(_ outcome: StreakOutcome) {
        if outcome.goalJustCompleted {
            enqueue(.goalCompleted(streak: outcome.newStreak))
        }
        if outcome.freezeEarned {
            enqueue(.freezeEarned(total: streakStore.state.freezes))
        }
    }

    func evaluateAchievements() {
        var context = AchievementContext()
        context.totalQuestionsAnswered = sr.totalAnswered()
        context.practiceSessionsCompleted = sessions.completedSessionCount()
        context.currentStreak = streakStore.state.current
        context.freezesEarned = streakStore.state.freezesEarnedTotal
        context.mockExamsCompleted = mocks.attemptCount()
        context.bestMockScore = mocks.bestScorePercent()
        context.mistakesMastered = mistakes.masteredCount()
        context.roleplayPracticeCount = self.context.count(entity: AppModel.entityNames.roleplayResponse)
        context.examCramSessions = sessions.completedSessionCount(mode: .examCram)
        context.bestIndicatorMastery = indicators.stats().map(\.masteryScore).max() ?? 0

        for definition in achievements.evaluate(context) {
            enqueue(.achievement(definition))
        }
    }

    func enqueue(_ event: AppEvent) {
        guard !eventQueue.contains(event) else { return }
        eventQueue.append(event)
    }

    func dismissCurrentEvent() {
        if !eventQueue.isEmpty { eventQueue.removeFirst() }
    }

    // MARK: - Roleplay & Quick Think

    @discardableResult
    func saveRoleplayResponse(prompt: RoleplayPromptData,
                              notes: String,
                              transcript: String,
                              scores: [RubricCategory: Int],
                              aiFeedback: String?,
                              prepSeconds: Double,
                              presentSeconds: Double) -> UUID {
        let id = UUID()
        let row = context.insert(CDRoleplayResponse.self, entity: AppModel.entityNames.roleplayResponse)
        row.id = id
        row.promptID = prompt.id
        row.date = Date()
        row.notes = notes
        row.transcript = transcript
        row.aiFeedback = aiFeedback
        row.cluster = prompt.cluster.rawValue
        row.indicators = ListCodec.encode(prompt.performanceIndicators)
        row.prepSeconds = prepSeconds
        row.presentSeconds = presentSeconds
        row.setScores(scores)
        try? context.save()

        indicators.recordRoleplay(indicators: prompt.performanceIndicators, cluster: prompt.cluster)
        evaluateAchievements()
        refresh()
        return id
    }

    func roleplayResponses(promptID: UUID? = nil) -> [CDRoleplayResponse] {
        let predicate = promptID.map { NSPredicate(format: "promptID == %@", $0 as CVarArg) }
        return context.fetchAll(CDRoleplayResponse.self,
                                entity: AppModel.entityNames.roleplayResponse,
                                predicate: predicate,
                                sort: [NSSortDescriptor(key: "date", ascending: false)])
    }

    @discardableResult
    func saveQuickThink(scenario: QuickThinkScenario,
                        response: String,
                        feedback: QuickThinkFeedback,
                        seconds: Double,
                        usedAI: Bool) -> UUID {
        let id = UUID()
        let row = context.insert(CDQuickThinkSession.self, entity: AppModel.entityNames.quickThink)
        row.id = id
        row.date = Date()
        row.scenarioID = scenario.id
        row.scenarioText = scenario.prompt
        row.response = response
        row.cluster = scenario.cluster.rawValue
        row.secondsSpent = seconds
        row.usedAI = usedAI
        row.feedback = [feedback.strongest, feedback.weakest, feedback.strongerAnswer]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        try? context.save()
        refresh()
        return id
    }

    // MARK: - Mock exams

    func finishMockExam(config: MockExamConfig,
                        questions: [QuestionData],
                        selections: [UUID: Int],
                        flags: Set<UUID>,
                        elapsedSeconds: Double) -> UUID {
        let attemptID = mocks.saveAttempt(config: config,
                                          questions: questions,
                                          selections: selections,
                                          flags: flags,
                                          elapsedSeconds: elapsedSeconds)

        // Feed every answered question through the normal learning pipeline so
        // spaced repetition, indicator mastery and the notebook stay accurate.
        var correct = 0
        for question in questions {
            guard let selected = selections[question.id] else { continue }
            let isCorrect = selected == question.correctIndex
            if isCorrect { correct += 1 }
            sr.record(questionID: question.id, correct: isCorrect)
            indicators.recordAnswer(indicators: question.performanceIndicators,
                                    cluster: question.cluster,
                                    correct: isCorrect)
            if isCorrect {
                mistakes.recordCorrect(questionID: question.id)
            } else {
                mistakes.recordMistake(question: question, selectedIndex: selected)
            }
        }

        let answered = selections.count
        if answered > 0 {
            let outcome = streaks.recordAnswers(count: answered,
                                                correct: correct,
                                                seconds: elapsedSeconds,
                                                goal: settings.dailyGoal)
            handle(outcome)
        }
        evaluateAchievements()
        refresh()
        return attemptID
    }

    // MARK: - Notifications

    func syncNotifications() async {
        await notifications.refreshAuthorization()
        guard settings.remindersEnabled else {
            notifications.cancelDailyReminder()
            return
        }
        await notifications.restoreRepeatingReminder(hour: settings.reminderHour,
                                                     minute: settings.reminderMinute,
                                                     goal: settings.dailyGoal,
                                                     style: settings.reminderStyle)
        // Don't nag when the work is already done.
        if dashboard.today.goalMet {
            await notifications.suppressTodayIfGoalMet(hour: settings.reminderHour,
                                                       minute: settings.reminderMinute,
                                                       goal: settings.dailyGoal,
                                                       style: settings.reminderStyle)
        }
    }

    // MARK: - Reset

    func resetProgress(keepQuestionBank: Bool) {
        let names = AppModel.entityNames
        persistence.deleteAll(entity: names.srRecord)
        persistence.deleteAll(entity: names.mistake)
        persistence.deleteAll(entity: names.practiceSession)
        persistence.deleteAll(entity: names.practiceAnswer)
        persistence.deleteAll(entity: names.mockAttempt)
        persistence.deleteAll(entity: names.mockResult)
        persistence.deleteAll(entity: names.roleplayResponse)
        persistence.deleteAll(entity: names.quickThink)
        persistence.deleteAll(entity: names.dailyProgress)
        persistence.deleteAll(entity: names.piMastery)
        persistence.deleteAll(entity: names.achievement)

        if !keepQuestionBank {
            persistence.deleteAll(entity: names.question)
            persistence.deleteAll(entity: names.roleplayPrompt)
        }
        persistence.save()

        streakStore.reset()
        bank.seedIfNeeded()
        refresh()
    }
}
