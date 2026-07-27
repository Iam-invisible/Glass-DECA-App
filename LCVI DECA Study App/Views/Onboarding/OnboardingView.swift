//
//  OnboardingView.swift
//  LCVI DECA Study App
//
//  Five short screens: welcome, cluster, daily goal, reminders, AI status.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 0
    @State private var cluster: DECACluster = .marketing
    @State private var goal = 10
    @State private var wantsReminders = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 30)) ?? Date()
    @State private var permissionRequested = false
    @State private var permissionGranted = false

    private let lastStep = 4

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $step) {
                welcome.tag(0)
                clusterStep.tag(1)
                goalStep.tag(2)
                reminderStep.tag(3)
                aiStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : Motion.snappy, value: step)

            footer
        }
        .appCanvas()
        .onAppear {
            cluster = store.settings.cluster
            goal = store.settings.dailyGoal
            store.ai.refreshAvailability()
        }
    }

    // MARK: Chrome

    private var header: some View {
        HStack(spacing: 6) {
            ForEach(0...lastStep, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Palette.accent : Palette.stroke)
                    .frame(height: 4)
                    .animation(reduceMotion ? nil : Motion.snappy, value: step)
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of \(lastStep + 1)")
    }

    private var footer: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: step == lastStep ? "Start studying" : "Continue") {
                advance()
            }
            if step > 0 {
                Button("Back") {
                    Haptics.tap()
                    withAnimation(reduceMotion ? nil : Motion.snappy) { step -= 1 }
                }
                .font(.appFootnote.weight(.medium))
                .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 14)
        .padding(.top, 8)
    }

    private func advance() {
        if step < lastStep {
            withAnimation(reduceMotion ? nil : Motion.snappy) { step += 1 }
            return
        }
        finish()
    }

    private func finish() {
        store.settings.cluster = cluster
        store.settings.dailyGoal = goal
        store.settings.remindersEnabled = wantsReminders && permissionGranted
        store.settings.reminderDate = reminderTime
        store.settings.hasOnboarded = true
        Haptics.success()
        store.refresh()
        Task { await store.syncNotifications() }
    }

    // MARK: Step 1 — welcome

    private var welcome: some View {
        OnboardingPage {
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Palette.accentSoft)
                        .frame(width: 96, height: 96)
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
                .appearIn(0)

                VStack(spacing: 10) {
                    Text("Glass")
                        .font(.appLargeTitle)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Your DECA Ontario study companion. Exams, roleplays and daily practice — all of it works offline.")
                        .font(.appBody)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .appearIn(1)

                VStack(spacing: 10) {
                    FeatureRow(symbol: "list.bullet.rectangle.portrait",
                               title: "Cluster exam practice",
                               detail: "Targeted multiple-choice sessions that adapt to your weak spots.")
                    FeatureRow(symbol: "timer",
                               title: "Mock exams",
                               detail: "Full timed exams with a detailed breakdown afterwards.")
                    FeatureRow(symbol: "person.wave.2.fill",
                               title: "Roleplays and Quick Think",
                               detail: "Prep timers, judge-style rubrics and fast thinking drills.")
                    FeatureRow(symbol: "flame.fill",
                               title: "Daily streaks",
                               detail: "Small daily goals, streak freezes and progress you can see.")
                }
                .appearIn(2)
            }
        }
    }

    // MARK: Step 2 — cluster

    private var clusterStep: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingTitle(title: "Choose your event",
                                subtitle: "We'll personalise practice, mock exams, roleplays and progress around this cluster. You can change it any time in Settings.")
                ClusterPicker(selection: $cluster)
            }
        }
    }

    // MARK: Step 3 — goal

    private var goalStep: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingTitle(title: "Set a daily goal",
                                subtitle: "Meeting your goal completes the day and builds your streak. Ten a day is a solid pace for most students.")
                GoalStepper(goal: $goal)

                InfoBanner(systemImage: "flame.fill",
                           title: "Every 10 days earns a streak freeze",
                           message: "A freeze automatically protects your streak the first day you miss.",
                           tint: Palette.gold)
            }
        }
    }

    // MARK: Step 4 — reminders

    private var reminderStep: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingTitle(title: "Daily reminders",
                                subtitle: "One quiet notification at a time you choose. It's local to your phone — no account, no internet. If you've already met your goal, we skip it.")

                Toggle(isOn: $wantsReminders) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remind me daily")
                            .font(.appBodyMedium)
                            .foregroundStyle(Palette.textPrimary)
                        Text(permissionRequested && !permissionGranted
                             ? "Notifications are turned off in iOS Settings."
                             : "You'll be asked for permission once.")
                            .font(.appCaption)
                            .foregroundStyle(permissionRequested && !permissionGranted
                                             ? Palette.danger : Palette.textSecondary)
                    }
                }
                .tint(Palette.accent)
                .appCard()
                .onChange(of: wantsReminders) { newValue in
                    guard newValue else { return }
                    Haptics.tap()
                    Task {
                        permissionGranted = await store.notifications.requestAuthorization()
                        permissionRequested = true
                        if !permissionGranted { wantsReminders = false }
                    }
                }

                if wantsReminders && permissionGranted {
                    DatePicker("Reminder time",
                               selection: $reminderTime,
                               displayedComponents: .hourAndMinute)
                        .font(.appBodyMedium)
                        .tint(Palette.accent)
                        .appCard()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Text("You can turn reminders on or off later in Settings.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
            .animation(reduceMotion ? nil : Motion.snappy, value: wantsReminders)
            .animation(reduceMotion ? nil : Motion.snappy, value: permissionGranted)
        }
    }

    // MARK: Step 5 — AI

    private var aiStep: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingTitle(title: "AI coaching, if your device supports it",
                                subtitle: "When Apple Intelligence is available, this app can explain answers and grade roleplays using Apple's on-device model. Nothing is ever sent to a server.")

                AIStatusCard(availability: store.ai.availability)

                if store.ai.availability.isUsable {
                    VStack(alignment: .leading, spacing: 10) {
                        FeatureRow(symbol: "text.bubble",
                                   title: "Why an answer is wrong",
                                   detail: "Explanations connected to business reasoning.")
                        FeatureRow(symbol: "checklist",
                                   title: "Roleplay rubric feedback",
                                   detail: "Judge-style scoring with a stronger sample answer.")
                    }
                } else {
                    InfoBanner(systemImage: "checkmark.circle",
                               title: "The app is fully usable without AI",
                               message: "Practice, mock exams, roleplays, streaks and progress all work offline. Explanations come from the question bank and roleplays use a manual rubric.",
                               tint: Palette.success)

                    // Only offered when Apple's model is unavailable — there
                    // is no reason to spend a student's data on a smaller
                    // model when a better one is already built into the phone.
                    LocalAICoachCard(service: store.localModel)
                        .appCard()
                }

                InfoBanner(systemImage: "lock.shield",
                           title: "No sign-in, no internet, no tracking",
                           message: "Every question, answer and statistic stays on this phone.",
                           tint: Palette.accent)
            }
        }
    }
}

// MARK: - Pieces

private struct OnboardingPage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 18)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct OnboardingTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appLargeTitle)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.appCallout)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appCallout.weight(.medium))
                    .foregroundStyle(Palette.textPrimary)
                Text(detail)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Shared by onboarding and Settings so the wording never drifts.
struct AIStatusCard: View {
    let availability: AIAvailability

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: availability.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(availability.tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(availability.title)
                    .font(.appBodyMedium)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(availability.detail)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }
}
