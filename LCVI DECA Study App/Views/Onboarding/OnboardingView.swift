//
//  OnboardingView.swift
//  LCVI DECA Study App
//
//  Setup as one continuous surface rather than a carousel of pages.
//
//  The old version was five `TabView` slides. It worked, but it read like
//  every other onboarding: title, subtitle, rows, dot, repeat. Nothing about
//  it was Glass.
//
//  This one keeps the space the intro leaves behind. The same drifting
//  backdrop stays on screen and the setup assembles on top of it — each
//  question opens, gets answered, then collapses into a compact line that
//  stays visible. The student watches their own setup stack up instead of
//  watching a progress dot advance, so progress *is* the screen rather than an
//  indicator on it, and every earlier answer stays one tap away.
//
//  Everything is reversible, nothing is required, and the whole thing can be
//  skipped in one tap with sane defaults.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Stage: Int, CaseIterable, Identifiable {
        case cluster, goal, reminders, coaching
        var id: Int { rawValue }
    }

    @State private var stage: Stage = .cluster
    @State private var done: Set<Stage> = []

    @State private var cluster: DECACluster = .marketing
    @State private var goal = 10
    @State private var wantsReminders = false
    @State private var reminderHour = 18
    @State private var reminderMinute = 30
    @State private var permissionRequested = false
    @State private var permissionGranted = false

    private var everythingDone: Bool { done.count == Stage.allCases.count }

    var body: some View {
        ZStack {
            // The intro hands over mid-scene rather than cutting to a new one.
            IntroBackdrop(opacity: 1, drift: true)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        masthead
                        ForEach(Stage.allCases) { s in
                            pane(for: s).id(s)
                        }
                        footer
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
                .onChange(of: stage) { newValue in
                    withAnimation(reduceMotion ? nil : Motion.gentle) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Glass")
                .font(.appLargeTitle)
                .foregroundStyle(Palette.textPrimary)
            Text("Four quick choices and you're studying. Everything here is editable later, and none of it leaves your phone.")
                .font(.appFootnote)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: Panes

    @ViewBuilder
    private func pane(for s: Stage) -> some View {
        if stage == s {
            open(s)
                .transition(reduceMotion ? .opacity
                            : .opacity.combined(with: .move(edge: .top)))
        } else if done.contains(s) {
            summary(for: s)
        }
        // Unstarted stages render nothing: the column grows as it is answered,
        // which is what makes the stack itself read as progress.
    }

    @ViewBuilder
    private func open(_ s: Stage) -> some View {
        switch s {
        case .cluster:   clusterPane
        case .goal:      goalPane
        case .reminders: reminderPane
        case .coaching:  coachingPane
        }
    }

    private func summary(for s: Stage) -> some View {
        Button {
            Haptics.tap()
            withAnimation(reduceMotion ? nil : Motion.snappy) { stage = s }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.success)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title(for: s))
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                    Text(answer(for: s))
                        .font(.appCallout.weight(.medium))
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text("Change")
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
            .appCard(padding: 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to change")
    }

    private func title(for s: Stage) -> String {
        switch s {
        case .cluster:   return "Your event"
        case .goal:      return "Daily goal"
        case .reminders: return "Reminder"
        case .coaching:  return "Coaching"
        }
    }

    private func answer(for s: Stage) -> String {
        switch s {
        case .cluster:
            return cluster.displayName
        case .goal:
            return "\(goal) question\(goal == 1 ? "" : "s") a day"
        case .reminders:
            guard wantsReminders else { return "No reminders" }
            return String(format: "Every day at %d:%02d", reminderHour, reminderMinute)
        case .coaching:
            if store.ai.availability.isUsable { return "Apple's on-device model" }
            return store.localModel.state.isReady ? "Local AI coach installed"
                                                  : "Written explanations"
        }
    }

    // MARK: Stage 1 — event

    private var clusterPane: some View {
        paneShell(step: 1,
                  title: "Which event are you preparing for?",
                  detail: "This decides which questions, roleplays and performance indicators you see first. You can switch any time.") {
            VStack(spacing: 8) {
                ForEach(DECACluster.allCases) { item in
                    clusterRow(item)
                }
            }
            PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                complete(.cluster)
            }
            .padding(.top, 4)
        }
    }

    private func clusterRow(_ item: DECACluster) -> some View {
        let selected = cluster == item
        return Button {
            Haptics.select()
            withAnimation(reduceMotion ? nil : Motion.quick) { cluster = item }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? .white : item.tint)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(selected ? item.tint : item.tint.opacity(0.13)))
                Text(item.displayName)
                    .font(.appCallout.weight(selected ? .semibold : .regular))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(selected ? item.tint : Palette.inactive)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(selected ? item.tint.opacity(0.09) : Palette.cardSunken)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(selected ? item.tint.opacity(0.45) : Palette.stroke, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.displayName)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Stage 2 — goal

    private var goalPane: some View {
        paneShell(step: 2,
                  title: "How many questions a day?",
                  detail: "Small and daily beats heroic and rare. Ten takes about five minutes.") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                CountingNumber(value: Double(goal), font: .numeric(46), color: Palette.accent)
                Text("a day")
                    .font(.appCallout)
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 2)
            .accessibilityHidden(true)

            HStack(spacing: 8) {
                ForEach([5, 10, 20, 30], id: \.self) { value in
                    goalChip(value)
                }
            }

            AppStepper(value: $goal, in: 1...100) {
                Text("Fine-tune")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
            }

            PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                complete(.goal)
            }
            .padding(.top, 4)
        }
    }

    private func goalChip(_ value: Int) -> some View {
        let selected = goal == value
        return Button {
            Haptics.select()
            withAnimation(reduceMotion ? nil : Motion.quick) { goal = value }
        } label: {
            Text("\(value)")
                .font(.appFootnote.weight(.semibold))
                .foregroundStyle(selected ? .white : Palette.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(selected ? Palette.accent : Palette.cardSunken)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(value) questions a day")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Stage 3 — reminders

    private var reminderPane: some View {
        paneShell(step: 3,
                  title: "Want a nudge?",
                  detail: "One quiet notification, local to this phone. If you've already hit your goal that day, it stays quiet.") {
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
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onChange(of: wantsReminders) { newValue in
                guard newValue else { return }
                Task {
                    permissionGranted = await store.notifications.requestAuthorization()
                    permissionRequested = true
                    if !permissionGranted { wantsReminders = false }
                }
            }

            if wantsReminders {
                // Preset times rather than a wheel: `DatePicker` is drawn by
                // the OS and looks different on iOS 16 and iOS 26, which is
                // exactly what the custom controls exist to avoid. Four
                // after-school times cover almost everyone, and Settings still
                // offers an exact time later.
                VStack(alignment: .leading, spacing: 8) {
                    Text("What time?")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                    HStack(spacing: 8) {
                        timeChip(16, 0)
                        timeChip(17, 30)
                        timeChip(18, 30)
                        timeChip(20, 0)
                    }
                }
                .transition(.opacity)
            }

            PrimaryButton(title: wantsReminders ? "Continue" : "Not now",
                          systemImage: "arrow.right") {
                complete(.reminders)
            }
            .padding(.top, 4)
        }
        .animation(reduceMotion ? nil : Motion.snappy, value: wantsReminders)
    }

    private func timeChip(_ hour: Int, _ minute: Int) -> some View {
        let selected = reminderHour == hour && reminderMinute == minute
        return Button {
            Haptics.select()
            withAnimation(reduceMotion ? nil : Motion.quick) {
                reminderHour = hour; reminderMinute = minute
            }
        } label: {
            Text(String(format: "%d:%02d", hour, minute))
                .font(.appFootnote.weight(.semibold))
                .foregroundStyle(selected ? .white : Palette.textPrimary)
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(selected ? Palette.accent : Palette.cardSunken)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "%d:%02d", hour, minute))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Stage 4 — coaching

    private var coachingPane: some View {
        paneShell(step: 4,
                  title: "AI coaching",
                  detail: "Explanations and roleplay feedback, generated on this phone. Never a server — and never the source of a correct answer, which always comes from the question bank.") {
            AIStatusCard(availability: store.ai.availability)

            if store.ai.availability.isUsable {
                VStack(spacing: 10) {
                    FeatureRow(symbol: "text.bubble",
                               title: "Why an answer is wrong",
                               detail: "Explanations connected to business reasoning.")
                    FeatureRow(symbol: "checklist",
                               title: "Roleplay rubric feedback",
                               detail: "Judge-style scoring with a stronger sample answer.")
                }
            } else {
                LocalAICoachCard(service: store.localModel)
                    .appCard()
            }

            PrimaryButton(title: "Start studying", systemImage: "arrow.right") {
                complete(.coaching)
            }
            .padding(.top, 4)
        }
    }

    // MARK: Shell

    private func paneShell<Content: View>(step: Int,
                                          title: String,
                                          detail: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 9) {
                Text("\(step)")
                    .font(.numeric(12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Palette.accent))
                Text("Step \(step) of \(Stage.allCases.count)")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.appTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .appCard(padding: 17)
    }

    // MARK: Footer

    @ViewBuilder
    private var footer: some View {
        if everythingDone {
            PrimaryButton(title: "Start studying", systemImage: "checkmark") {
                finish()
            }
            .padding(.top, 6)
        } else {
            Button {
                Haptics.tap()
                finish()
            } label: {
                Text("Skip setup — use the defaults")
                    .font(.appFootnote.weight(.medium))
                    .foregroundStyle(Palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Starts the app with marketing, ten questions a day and no reminders")
        }
    }

    // MARK: Flow

    private func complete(_ s: Stage) {
        done.insert(s)
        // Reopening an answered stage should hand back to whatever is still
        // unanswered, rather than marching the student through the rest again.
        guard let next = Stage.allCases.first(where: { !done.contains($0) }) else {
            Haptics.success()
            finish()
            return
        }
        Haptics.tap()
        withAnimation(reduceMotion ? nil : Motion.snappy) { stage = next }
    }

    private func finish() {
        store.settings.cluster = cluster
        store.settings.dailyGoal = goal
        store.settings.remindersEnabled = wantsReminders && permissionGranted
        store.settings.reminderHour = reminderHour
        store.settings.reminderMinute = reminderMinute
        store.settings.hasOnboarded = true
        Haptics.success()
        store.refresh()
        Task { await store.syncNotifications() }
    }
}

// MARK: - Pieces shared with Settings

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
