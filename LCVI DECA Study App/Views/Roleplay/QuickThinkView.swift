//
//  QuickThinkView.swift
//  LCVI DECA Study App
//
//  Fast roleplay response drill: scenario, short timer, typed answer, feedback.
//

import SwiftUI

struct QuickThinkView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var editorFocused: Bool

    @State private var scenario: QuickThinkScenario?
    @State private var response = ""
    @State private var feedback: QuickThinkFeedback?
    @State private var usedAI = false
    @State private var isThinking = false
    @State private var useTimer = true
    @State private var started = false
    @State private var startedAt = Date()

    @StateObject private var timer = CountdownTimer(minutes: 2)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.stackSpacing) {
                    if let scenario {
                        scenarioCard(scenario)

                        if feedback == nil {
                            if useTimer { timerCard }
                            editor
                            submitButton(scenario)
                        } else {
                            feedbackView
                        }
                    } else {
                        EmptyStateView(systemImage: "brain.head.profile",
                                       title: "No scenarios yet",
                                       message: "Quick Think scenarios for your cluster will appear here.")
                            .appCard()
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .appCanvas()
            .navigationTitle("Quick Think")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { finishAndClose() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.tap()
                        newScenario()
                    } label: {
                        Image(systemName: "shuffle")
                    }
                    .accessibilityLabel("New scenario")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { editorFocused = false }
                }
            }
        }
        .celebrationLayer(isFullScreen: true)
        .onAppear {
            if scenario == nil { newScenario() }
        }
    }

    // MARK: Scenario

    private func scenarioCard(_ scenario: QuickThinkScenario) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                TagPill(text: scenario.cluster.shortName,
                        color: scenario.cluster.tint,
                        soft: scenario.cluster.tint.opacity(0.13),
                        icon: scenario.cluster.symbol)
                TagPill(text: scenario.focus, color: Palette.gold, soft: Palette.goldSoft)
                Spacer(minLength: 0)
            }
            Text(scenario.prompt)
                .font(.appBodyMedium)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 17)
        .accessibilityElement(children: .combine)
    }

    // MARK: Timer

    private var timerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                ProgressRing(progress: timer.progress,
                             lineWidth: 6,
                             tint: timer.isCritical ? Palette.danger : Palette.accent,
                             animated: false)
                    .frame(width: 52, height: 52)
                Text(timer.display)
                    .font(.numeric(14))
                    .foregroundStyle(Palette.textPrimary)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(timer.isRunning ? "Answer while the clock runs" : "Two minutes to answer")
                    .font(.appFootnote.weight(.medium))
                    .foregroundStyle(Palette.textPrimary)
                Text("The timer is a guide, not a hard stop.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }

            Spacer(minLength: 0)

            Button {
                timer.toggle()
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(timer.isRunning ? Palette.gold : Palette.accent))
            }
            .buttonStyle(PressableButtonStyle(haptic: false))
            .accessibilityLabel(timer.isRunning ? "Pause timer" : "Start timer")
        }
        .appCard(padding: 13)
    }

    // MARK: Editor

    private var editor: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label("Your answer", systemImage: "text.cursor")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                Toggle("Timer", isOn: $useTimer)
                    .font(.appCaption)
                    .tint(Palette.accent)
                    .fixedSize()
                    .onChange(of: useTimer) { on in
                        if !on { timer.pause() }
                    }
            }

            TextEditor(text: $response)
                .font(.appCallout)
                .frame(minHeight: 190)
                .scrollContentBackground(.hidden)
                .background(Palette.cardSunken)
                .cornerRadius(10)
                .focused($editorFocused)
                .overlay(alignment: .topLeading) {
                    if response.isEmpty {
                        Text("Say what you'd actually say to the judge. State your recommendation, then support it.")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 10)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: response) { _ in
                    guard !started else { return }
                    started = true
                    startedAt = Date()
                    if useTimer { timer.start() }
                }
                .accessibilityLabel("Your Quick Think answer")

            Text("\(wordCount) word\(wordCount == 1 ? "" : "s")")
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
                .monospacedDigit()
        }
        .appCard()
    }

    private var wordCount: Int {
        response.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private func submitButton(_ scenario: QuickThinkScenario) -> some View {
        VStack(spacing: 9) {
            PrimaryButton(title: isThinking ? "Analysing…" : "Get feedback",
                          systemImage: isThinking ? nil : "checkmark",
                          isEnabled: wordCount >= 5 && !isThinking) {
                submit(scenario)
            }
            if wordCount < 5 {
                Text("Write at least a sentence to get useful feedback.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
            if !store.ai.isUsable {
                Text("AI coaching isn't available on this device — you'll get a structured self-check instead.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Feedback

    @ViewBuilder
    private var feedbackView: some View {
        if let feedback {
            VStack(spacing: Metrics.stackSpacing) {
                HStack(spacing: 8) {
                    Image(systemName: usedAI ? "sparkles" : "checklist")
                        .foregroundStyle(Palette.accent)
                    Text(usedAI ? "On-device coaching" : "Self-check")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.accent)
                    Spacer()
                    Text("\(wordCount) words")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .monospacedDigit()
                }

                // In self-check mode nothing has read the answer, so every
                // heading is phrased as something for the student to check
                // rather than a finding. The AI labels stay untouched.
                if feedback.isSelfCheck {
                    Text("No AI coaching on this device, so nothing here is based on reading your answer. Use it as a checklist against what you wrote.")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    block("Check this first", feedback.strongest, "questionmark.circle.fill", Palette.accent)
                    block("Length", feedback.weakest, "textformat.size", Palette.gold)
                    block("Focus area for this prompt", feedback.conceptUsedWell, "target", Palette.accent)
                    block("Run this checklist", feedback.conceptMissing, "checklist", Palette.accent)
                    block("Phrasing that scores", feedback.moreProfessional, "quote.opening", Palette.accent)
                    block("Structure to aim for", feedback.strongerAnswer, "list.number", Palette.gold)
                } else {
                    block("Strongest part", feedback.strongest, "hand.thumbsup.fill", Palette.success)
                    block("Weakest part", feedback.weakest, "exclamationmark.triangle.fill", Palette.gold)
                    block("Business concept used well", feedback.conceptUsedWell, "checkmark.seal.fill", Palette.accent)
                    block("Business concept missing", feedback.conceptMissing, "questionmark.circle.fill", Palette.danger)
                    block("Say it more professionally", feedback.moreProfessional, "quote.opening", Palette.accent)
                    block("A stronger answer", feedback.strongerAnswer, "star.fill", Palette.gold)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Label("Your answer", systemImage: "text.quote")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.textSecondary)
                    Text(response)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()

                PrimaryButton(title: "Next scenario", systemImage: "arrow.right") {
                    newScenario()
                }
                SecondaryButton(title: "Done", systemImage: "checkmark") {
                    finishAndClose()
                }
            }
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func block(_ title: String, _ body: String, _ symbol: String, _ tint: Color) -> some View {
        if !body.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: symbol)
                    .font(.appCaptionBold)
                    .foregroundStyle(tint)
                Text(body)
                    .font(.appCallout)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Actions

    private func newScenario() {
        var pool = SeedQuickThink.scenarios(for: store.settings.cluster)
        if pool.isEmpty { pool = SeedQuickThink.all }
        let next = pool.filter { $0.id != scenario?.id }.randomElement() ?? pool.first
        withAnimation(reduceMotion ? nil : Motion.snappy) {
            scenario = next
            response = ""
            feedback = nil
            usedAI = false
            started = false
        }
        timer.setMinutes(2)
        editorFocused = false
    }

    private func submit(_ scenario: QuickThinkScenario) {
        editorFocused = false
        timer.pause()
        let seconds = started ? Date().timeIntervalSince(startedAt) : 0

        guard store.ai.isUsable else {
            let manual = QuickThinkFeedback.manual(scenario: scenario, response: response)
            Haptics.success()
            withAnimation(Motion.reveal) {
                feedback = manual
                usedAI = false
            }
            _ = store.saveQuickThink(scenario: scenario, response: response,
                                 feedback: manual, seconds: seconds, usedAI: false)
            return
        }

        isThinking = true
        Task { @MainActor in
            let result = await store.ai.improveQuickThink(scenario: scenario, response: response)
            isThinking = false
            let final = result ?? QuickThinkFeedback.manual(scenario: scenario, response: response)
            Haptics.success()
            withAnimation(Motion.reveal) {
                feedback = final
                usedAI = result != nil
            }
            _ = store.saveQuickThink(scenario: scenario, response: response,
                                 feedback: final, seconds: seconds, usedAI: result != nil)
        }
    }

    private func finishAndClose() {
        timer.pause()
        dismiss()
    }
}
