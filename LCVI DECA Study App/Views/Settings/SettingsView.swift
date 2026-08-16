//
//  SettingsView.swift
//  LCVI DECA Study App
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showingResetConfirm = false
    @State private var showingResetEverythingConfirm = false
    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var showingImporter = false
    @State private var importMessage: String?
    @State private var showingImportAlert = false
    @State private var notificationDenied = false
    /// Driven by `store.wantsQuestionBank` rather than bound to it: flipping
    /// local state after the screen is mounted pushes reliably on iOS 16,
    /// where a navigationDestination that is already true at first render
    /// does not.
    @State private var pushQuestionBank = false

    private var settings: UserSettings { store.settings }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.sectionSpacing) {
                    ScreenHeader("Settings",
                                 subtitle: "No account, no sync, no tracking.")
                        .appearIn(0)

                    studySection.appearIn(0)
                    reminderSection.appearIn(1)
                    aiSection.appearIn(2)
                    contentSection.appearIn(3)
                    dataSection.appearIn(4)
                    appearanceSection.appearIn(5)
                    aboutSection.appearIn(6)
                }
                .scrollOffsetProbe()
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .reportsScrollOffset()
            .appCanvas()
            .rootScreenChrome()
            .navigationDestination(isPresented: $pushQuestionBank) {
                QuestionBankManagerView()
            }
        }
        .onAppear {
            consumeBankIntent()
            store.ai.refreshAvailability()
            Task { await store.notifications.refreshAuthorization() }
        }
        .onChange(of: store.wantsQuestionBank) { _ in consumeBankIntent() }
        .sheet(isPresented: $showingShare) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.json],
                      allowsMultipleSelection: false) { result in
            handleRestore(result)
        }
        .alert("Import", isPresented: $showingImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage ?? "")
        }
        .confirmationDialog("Reset progress?",
                            isPresented: $showingResetConfirm,
                            titleVisibility: .visible) {
            Button("Reset progress", role: .destructive) {
                store.resetProgress(keepQuestionBank: true)
                Haptics.warning()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Streaks, mistakes, review schedules, mock exams, roleplays and achievements will be erased. Your question bank is kept.")
        }
        .confirmationDialog("Erase everything?",
                            isPresented: $showingResetEverythingConfirm,
                            titleVisibility: .visible) {
            Button("Erase everything", role: .destructive) {
                store.eraseEverything()
                Haptics.warning()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(eraseEverythingWarning)
        }
    }

    /// Names the model only when one is actually on the phone. Warning about
    /// deleting an 808 MB download nobody has would be noise, and the size is
    /// there because re-downloading it is the one part of this that costs more
    /// than a tap.
    private var eraseEverythingWarning: String {
        let base = "This deletes your progress AND every question you've added, "
                 + "plus coins and anything bought in the Shop, "
                 + "then restores the bundled sample content."
        guard LocalModelService.isModelPresent else {
            return base + " This cannot be undone."
        }
        return base
             + " The \(LocalModelCatalog.approximateMegabytes) MB AI model is deleted too "
             + "and would need downloading again. This cannot be undone."
    }

    // MARK: Study

    private var studySection: some View {
        settingsSection("Study") {
            VStack(spacing: 14) {
                NavigationLink {
                    ClusterSettingsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: settings.cluster.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(settings.cluster.tint)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DECA exam / cluster")
                                .font(.appCallout)
                                .foregroundStyle(Palette.textPrimary)
                            Text(settings.cluster.displayName)
                                .font(.appCaption)
                                .foregroundStyle(Palette.textSecondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider().overlay(Palette.stroke)

                // The competitive event. Editable here because students
                // commit to one weeks after they start studying — and the
                // catalogue may be corrected between seasons, so the stored
                // code is re-resolved every time it is read.
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.gold)
                            .frame(width: 24)
                        Text("Competitive event")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Spacer(minLength: 0)
                    }
                    EventPicker(eventCode: Binding(get: { settings.eventCode },
                                                   set: { settings.eventCode = $0; store.refresh() }),
                                cluster: settings.cluster) { newCluster in
                        settings.cluster = newCluster
                        store.refresh()
                    }
                }

                Divider().overlay(Palette.stroke)

                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Image(systemName: "target")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                            .frame(width: 24)
                        Text("Daily question goal")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Text("\(settings.dailyGoal)")
                            .font(.appCallout.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                            .monospacedDigit()
                    }
                    AppStepper(value: Binding(get: { settings.dailyGoal },
                                              set: { settings.dailyGoal = $0; store.refresh() }),
                               in: 1...100) {
                        Text("\(settings.dailyGoal) questions per day")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }

                Divider().overlay(Palette.stroke)

                // The second daily goal, adjusted the same way as the first.
                // Hidden for events with no roleplay component — the same
                // rule that hides the dial on the home screen.
                if settings.eventHasRoleplay {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Palette.gold)
                                .frame(width: 24)
                            Text("Daily Quick Think goal")
                                .font(.appCallout)
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Text("\(settings.quickThinkGoal)")
                                .font(.appCallout.weight(.semibold))
                                .foregroundStyle(Palette.gold)
                                .monospacedDigit()
                        }
                        AppStepper(value: Binding(get: { settings.quickThinkGoal },
                                                  set: { settings.quickThinkGoal = $0; store.refresh() }),
                                   in: 1...10) {
                            Text("\(settings.quickThinkGoal) Quick Think\(settings.quickThinkGoal == 1 ? "" : "s") per day")
                                .font(.appCaption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Reminders

    private var reminderSection: some View {
        settingsSection("Reminders") {
            VStack(spacing: 14) {
                Toggle(isOn: Binding(get: { settings.remindersEnabled },
                                     set: { newValue in
                                         if newValue {
                                             enableReminders()
                                         } else {
                                             settings.remindersEnabled = false
                                             store.notifications.cancelDailyReminder()
                                         }
                                     })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily reminder")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Text("Local notification only — never sent over the internet.")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                .tint(Palette.accent)

                if notificationDenied {
                    InfoBanner(systemImage: "bell.slash",
                               title: "Notifications are off for this app",
                               message: "Turn them on in the iOS Settings app to use reminders.",
                               tint: Palette.gold)
                }

                if settings.remindersEnabled {
                    Divider().overlay(Palette.stroke)

                    DatePicker("Reminder time",
                               selection: Binding(get: { settings.reminderDate },
                                                  set: { settings.reminderDate = $0; syncNotifications() }),
                               displayedComponents: .hourAndMinute)
                        .font(.appCallout)
                        .tint(Palette.accent)

                    Divider().overlay(Palette.stroke)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder style")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        AppSegmentedPicker("Reminder style",
                                           selection: Binding(get: { settings.reminderStyle },
                                                              set: { settings.reminderStyle = $0; syncNotifications() }),
                                           options: ReminderStyle.allCases) { $0.title }
                        Text("“\(settings.reminderStyle.body(goal: settings.dailyGoal, remaining: settings.dailyGoal))”")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("If you've already met your goal, the reminder is skipped for that day.")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .animation(Motion.snappy, value: settings.remindersEnabled)
        }
    }

    private func enableReminders() {
        Task { @MainActor in
            let granted = await store.notifications.requestAuthorization()
            notificationDenied = !granted
            settings.remindersEnabled = granted
            if granted { await store.syncNotifications() }
        }
    }

    private func syncNotifications() {
        Task { await store.syncNotifications() }
    }

    // MARK: AI

    private var aiSection: some View {
        settingsSection("AI feedback") {
            VStack(spacing: 14) {
                NavigationLink {
                    AIStatusView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: store.ai.availability.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(store.ai.availability.tint)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.ai.availability.title)
                                .font(.appCallout)
                                .foregroundStyle(Palette.textPrimary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Apple Foundation Models · on device")
                                .font(.appCaption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if LocalModelService.isOffered, !store.ai.availability.isUsable {
                    Divider().overlay(Palette.stroke)
                    LocalAICoachCard(service: store.localModel, ai: store.ai, showsIntroCopy: false)
                }

                if store.ai.availability.isUsable {
                    Divider().overlay(Palette.stroke)

                    Toggle(isOn: Binding(get: { settings.aiEnabled },
                                         set: { settings.aiEnabled = $0; store.ai.userEnabled = $0 })) {
                        Text("Use AI coaching")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                    }
                    .tint(Palette.accent)

                    if settings.aiEnabled {
                        Divider().overlay(Palette.stroke)
                        Toggle(isOn: Binding(get: { settings.aiAutoExplain },
                                             set: { settings.aiAutoExplain = $0 })) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Explain answers automatically")
                                    .font(.appCallout)
                                    .foregroundStyle(Palette.textPrimary)
                                Text("Off means you tap “Explain with AI” when you want it.")
                                    .font(.appCaption)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                        .tint(Palette.accent)
                    }
                }
            }
            .animation(Motion.snappy, value: settings.aiEnabled)
        }
    }

    // MARK: Content

    private var contentSection: some View {
        settingsSection("Content") {
            NavigationLink {
                QuestionBankManagerView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Question Bank Manager")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Text("\(store.dashboard.questionBankCount) questions · add, import, edit, export")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Data

    private var dataSection: some View {
        settingsSection("Data") {
            VStack(spacing: 14) {
                Button {
                    Haptics.tap()
                    exportBackup()
                } label: {
                    settingsRow(symbol: "square.and.arrow.up",
                                title: "Export backup",
                                subtitle: "Questions, progress and settings as a JSON file.",
                                tint: Palette.accent)
                }
                .buttonStyle(.plain)

                Divider().overlay(Palette.stroke)

                Button {
                    Haptics.tap()
                    showingImporter = true
                } label: {
                    settingsRow(symbol: "square.and.arrow.down",
                                title: "Restore from backup",
                                subtitle: "Replaces your current progress with the file's.",
                                tint: Palette.accent)
                }
                .buttonStyle(.plain)

                Divider().overlay(Palette.stroke)

                Button {
                    Haptics.tap()
                    showingResetConfirm = true
                } label: {
                    settingsRow(symbol: "arrow.counterclockwise",
                                title: "Reset progress",
                                subtitle: "Keeps your question bank.",
                                tint: Palette.gold)
                }
                .buttonStyle(.plain)

                Divider().overlay(Palette.stroke)

                Button {
                    Haptics.tap()
                    showingResetEverythingConfirm = true
                } label: {
                    settingsRow(symbol: "trash",
                                title: "Erase everything",
                                subtitle: "Progress and every question you've added.",
                                tint: Palette.danger)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func exportBackup() {
        let bundle = store.importExport.makeExport(includeProgress: true,
                                                   includeSettings: true,
                                                   settings: settings,
                                                   streak: store.streakStore.state)
        guard let url = store.importExport.writeExportFile(bundle) else { return }
        exportURL = url
        showingShare = true
    }

    private func consumeBankIntent() {
        guard store.wantsQuestionBank else { return }
        store.wantsQuestionBank = false
        // Next runloop: the push animates instead of appearing pre-committed.
        DispatchQueue.main.async { pushQuestionBank = true }
    }

    private func handleRestore(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            guard let data = try? Data(contentsOf: url) else {
                importMessage = "That file couldn't be read."
                showingImportAlert = true
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let bundle = try? decoder.decode(ExportBundle.self, from: data) else {
                importMessage = "That isn't a Glass backup file."
                showingImportAlert = true
                return
            }
            store.importExport.restore(bundle, settings: settings, streakStore: store.streakStore)
            store.refresh()
            Haptics.success()
            importMessage = "Restored \(bundle.questions.count) questions and your saved progress."
            showingImportAlert = true

        case .failure(let error):
            importMessage = error.localizedDescription
            showingImportAlert = true
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        settingsSection("Appearance and feedback") {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                    AppSegmentedPicker("Theme",
                                       selection: Binding(get: { settings.appearance },
                                                          set: { settings.appearance = $0 }),
                                       options: AppearanceMode.allCases) { $0.title }
                }

                Divider().overlay(Palette.stroke)

                Toggle(isOn: Binding(get: { settings.hapticsEnabled },
                                     set: { settings.hapticsEnabled = $0; if $0 { Haptics.tap() } })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Haptic feedback")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Text("Taps, correct/incorrect answers and celebrations.")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                .tint(Palette.accent)

                Divider().overlay(Palette.stroke)

                Toggle(isOn: Binding(get: { settings.soundEnabled },
                                     set: { settings.soundEnabled = $0; if $0 { SoundEffects.correct() } })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Answer sounds")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Text("A short tone for correct and incorrect answers. Silenced by the ring/silent switch, and never interrupts your music.")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Palette.accent)
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        settingsSection("About") {
            VStack(alignment: .leading, spacing: 12) {
                aboutRow("Works offline",
                         "Every feature except AI coaching runs with no internet connection. AI coaching runs on-device too.")
                Divider().overlay(Palette.stroke)
                aboutRow("No account, no tracking",
                         "There is no sign-in and no analytics. Your questions, answers and statistics never leave this phone.")
                Divider().overlay(Palette.stroke)

                // Accepting a notice once is worth nothing if it cannot be
                // read again afterwards, so it lives here permanently.
                NavigationLink {
                    PrivacyPolicyScreen()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.success)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacy notice")
                                .font(.appCallout)
                                .foregroundStyle(Palette.textPrimary)
                            Text(settings.acceptedPrivacyAt
                                 .map { "Accepted \($0.formatted(date: .abbreviated, time: .omitted))" }
                                 ?? "Updated \(PrivacyPolicy.lastUpdated)")
                                .font(.appCaption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider().overlay(Palette.stroke)
                aboutRow("Sample content",
                         "The bundled questions and roleplays are original practice material written for this app. They are not official DECA Ontario or DECA Inc. competition content — always check the current competitive event guidelines for your event.")
                Divider().overlay(Palette.stroke)
                aboutRow("Version", "1.0")
                Divider().overlay(Palette.stroke)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Intro style")
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                    // The picker still offers both, and the setter refuses the
                    // locked one, so tapping it does nothing and would look
                    // broken. The line underneath says why and where to go —
                    // a disabled control that explains itself, rather than one
                    // that silently ignores you.
                    AppSegmentedPicker("Intro style",
                                       selection: Binding(get: { settings.introStyle },
                                                          set: { settings.introStyle = $0 }),
                                       options: IntroStyle.allCases) { style in
                        settings.ownsIntro(style) ? style.title : "\(style.title) 🔒"
                    }
                    if settings.ownsScriptIntro {
                        Text(settings.introStyle.detail)
                            .font(.appFootnote)
                            .foregroundStyle(Palette.textSecondary)
                    } else {
                        Button {
                            Haptics.tap()
                            store.requestedTab = .shop
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Script is locked. Unlock it in the Shop.")
                                    .font(.appFootnote)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(Palette.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
                    }
                }

                Divider().overlay(Palette.stroke)

                Button {
                    Haptics.tap()
                    store.showIntro = true
                } label: {
                    settingsRow(symbol: "sparkles",
                                title: "Replay intro",
                                subtitle: "Watch the Glass reveal again.",
                                tint: Palette.accent)
                }
                .buttonStyle(.plain)

                Divider().overlay(Palette.stroke)

                Button {
                    Haptics.tap()
                    store.showGuide = true
                    store.requestedTab = .study
                } label: {
                    settingsRow(symbol: "questionmark.circle",
                                title: "Replay app guide",
                                subtitle: "The Study screen, the tabs, and adding the daily fact widget.",
                                tint: Palette.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func aboutRow(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.appCallout.weight(.medium))
                .foregroundStyle(Palette.textPrimary)
            Text(body)
                .font(.appCaption)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Helpers

    private func settingsRow(symbol: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appCallout)
                    .foregroundStyle(Palette.textPrimary)
                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String,
                                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            content().appCard()
        }
    }
}

// MARK: - Cluster settings

struct ClusterSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selection: DECACluster = .marketing

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Changing your cluster personalises daily practice, mock exams, roleplays, Quick Think, indicator tracking and Exam Cram. Your progress is kept.")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ClusterPicker(selection: $selection)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 14)
        }
        .appCanvas()
        .navigationTitle("Cluster")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selection = store.settings.cluster }
        .onChange(of: selection) { newValue in
            store.settings.cluster = newValue
            store.refresh()
        }
    }
}

// MARK: - AI status detail

struct AIStatusView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                AIStatusCard(availability: store.ai.availability)

                VStack(alignment: .leading, spacing: 11) {
                    SectionHeader(title: "What AI coaching does")
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(symbol: "text.bubble",
                                   title: "Explains wrong answers",
                                   detail: "Why your choice missed, and why the correct answer is the better business decision.")
                        FeatureRow(symbol: "lightbulb",
                                   title: "Study advice",
                                   detail: "A short plan based on your weakest indicators and topics.")
                        FeatureRow(symbol: "person.wave.2",
                                   title: "Roleplay coaching",
                                   detail: "Judge-style rubric feedback, missing concepts and a stronger sample answer.")
                        FeatureRow(symbol: "bolt",
                                   title: "Quick Think feedback",
                                   detail: "The strongest and weakest parts of your answer and a more professional rewrite.")
                    }
                    .appCard()
                }

                VStack(alignment: .leading, spacing: 11) {
                    SectionHeader(title: "What AI never does")
                    VStack(alignment: .leading, spacing: 10) {
                        ruleRow("It never decides the correct answer.",
                                "Correct answers always come from your local question bank. The model is told the answer as fact and only explains it.")
                        Divider().overlay(Palette.stroke)
                        ruleRow("It never goes online.",
                                "Apple's on-device model runs locally. This app makes no network requests of any kind.")
                        Divider().overlay(Palette.stroke)
                        ruleRow("It never blocks the app.",
                                "If the model is unavailable or fails, you get the written explanation or the manual rubric instead.")
                    }
                    .appCard()
                }

                VStack(alignment: .leading, spacing: 11) {
                    SectionHeader(title: "Status details")
                    VStack(spacing: 12) {
                        detailRow("Foundation Models framework",
                                  frameworkAvailable ? "Available on this OS" : "Not available on this OS version")
                        Divider().overlay(Palette.stroke)
                        detailRow("Apple Intelligence",
                                  appleIntelligenceLine)
                        Divider().overlay(Palette.stroke)
                        detailRow("Local model", modelLine)
                        Divider().overlay(Palette.stroke)
                        detailRow("Coaching in this app",
                                  store.ai.isUsable ? "Enabled" : "Using offline fallbacks")
                    }
                    .appCard()

                    Button {
                        Haptics.tap()
                        store.ai.refreshAvailability()
                    } label: {
                        Label("Check again", systemImage: "arrow.clockwise")
                            .font(.appFootnote.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 14)
        }
        .appCanvas()
        .navigationTitle("AI feedback")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.ai.refreshAvailability() }
    }

    private var frameworkAvailable: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    private var appleIntelligenceLine: String {
        switch store.ai.availability {
        case .available:                   return "On"
        case .appleIntelligenceNotEnabled: return "Off — enable it in iOS Settings"
        case .deviceNotSupported:          return "Not supported on this device"
        case .modelDownloading:            return "On"
        case .temporarilyUnavailable:      return "Unknown"
        // This row is about Apple's model specifically, which is exactly what
        // is missing when the local coach is the one running.
        case .localCoachAvailable:         return "Not supported on this device"
        }
    }

    private var modelLine: String {
        switch store.ai.availability {
        case .available:                   return "Ready"
        case .modelDownloading:            return "Downloading"
        case .deviceNotSupported:          return "Unavailable"
        case .appleIntelligenceNotEnabled: return "Not loaded"
        case .temporarilyUnavailable:      return "Unavailable right now"
        case .localCoachAvailable:         return "Local coach ready"
        }
    }

    private func ruleRow(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: "checkmark.shield.fill")
                .font(.appCallout.weight(.medium))
                .foregroundStyle(Palette.textPrimary)
            Text(body)
                .font(.appCaption)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.appFootnote)
                .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.appFootnote.weight(.medium))
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
