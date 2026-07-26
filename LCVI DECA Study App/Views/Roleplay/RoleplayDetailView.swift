//
//  RoleplayDetailView.swift
//  LCVI DECA Study App
//
//  Briefing → prep timer → presentation timer → judge-style rubric review.
//

import CoreData
import SwiftUI

struct RoleplayDetailView: View {
    let prompt: RoleplayPromptData

    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Phase: Int { case briefing, prep, present, review }
    enum PrepMode: String, CaseIterable, Identifiable {
        case structured
        case free

        var id: String { rawValue }

        var title: String {
            switch self {
            case .structured: return "Structured"
            case .free:       return "Free"
            }
        }
    }

    @State private var phase: Phase = .briefing
    @State private var prepMode: PrepMode = .structured
    @State private var notes = ""
    @State private var structuredGreeting = ""
    @State private var structuredProblem = ""
    @State private var structuredRecommendation = ""
    @State private var structuredEvidence = ""
    @State private var structuredRisks = ""
    @State private var structuredClose = ""
    @State private var transcript = ""
    @State private var scores: [RubricCategory: Int] = [:]
    @State private var aiFeedback: RoleplayAIFeedback?
    @State private var aiTips: String?
    @State private var isLoadingAI = false
    @State private var aiFailed = false
    @State private var saved = false
    @State private var pastAttempts: [CDRoleplayResponse] = []

    @StateObject private var prepTimer: CountdownTimer
    @StateObject private var presentTimer: CountdownTimer

    init(prompt: RoleplayPromptData) {
        self.prompt = prompt
        _prepTimer = StateObject(wrappedValue: CountdownTimer(minutes: prompt.prepMinutes))
        _presentTimer = StateObject(wrappedValue: CountdownTimer(minutes: prompt.presentMinutes))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.sectionSpacing) {
                phasePicker

                switch phase {
                case .briefing: briefing
                case .prep:     prepSection
                case .present:  presentSection
                case .review:   reviewSection
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .navigationTitle(prompt.title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(reduceMotion ? nil : Motion.snappy, value: phase)
        .onAppear {
            pastAttempts = store.roleplayResponses(promptID: prompt.id)
            if scores.isEmpty {
                RubricCategory.allCases.forEach { scores[$0] = 3 }
            }
        }
    }

    // MARK: Phase picker

    private var phasePicker: some View {
        HStack(spacing: 0) {
            ForEach([Phase.briefing, .prep, .present, .review], id: \.rawValue) { item in
                Button {
                    Haptics.select()
                    withAnimation(reduceMotion ? nil : Motion.snappy) { phase = item }
                } label: {
                    Text(label(for: item))
                        .font(.appCaptionBold)
                        .foregroundStyle(phase == item ? .white : Palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(phase == item ? Palette.accent : .clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(phase == item ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Palette.cardSunken)
        )
    }

    private func label(for phase: Phase) -> String {
        switch phase {
        case .briefing: return "Brief"
        case .prep:     return "Prep"
        case .present:  return "Present"
        case .review:   return "Review"
        }
    }

    // MARK: Briefing

    private var briefing: some View {
        VStack(spacing: Metrics.stackSpacing) {
            infoCard(title: "Business situation", symbol: "building.2", text: prompt.situation)
            infoCard(title: "Your role", symbol: "person.fill", text: prompt.userRole)
            infoCard(title: "Judge's role", symbol: "person.crop.square.filled.and.at.rectangle", text: prompt.judgeRole)

            if !prompt.performanceIndicators.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Label("Performance indicators", systemImage: "target")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.gold)
                    ForEach(prompt.performanceIndicators, id: \.self) { code in
                        HStack(alignment: .top, spacing: 8) {
                            Text(code)
                                .font(.appCaptionBold)
                                .foregroundStyle(Palette.gold)
                                .frame(width: 52, alignment: .leading)
                            Text(SeedIndicators.text(forCode: code) ?? "Performance indicator")
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

            HStack(spacing: 10) {
                StatCard(title: "Prep", value: "\(prompt.prepMinutes) min", systemImage: "hourglass")
                StatCard(title: "Present", value: "\(prompt.presentMinutes) min", systemImage: "person.wave.2")
                StatCard(title: "Level", value: prompt.difficulty.title,
                         systemImage: "chart.bar", tint: prompt.difficulty.color)
            }

            if store.ai.isUsable {
                aiTipsCard
            }

            PrimaryButton(title: "Start preparation", systemImage: "play.fill") {
                withAnimation(Motion.snappy) { phase = .prep }
                prepTimer.start()
            }

            if !pastAttempts.isEmpty {
                pastAttemptsCard
            }
        }
    }

    private var aiTipsCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Preparation tips · on device", systemImage: "sparkles")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.accent)

            if let aiTips {
                Text(aiTips)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if isLoadingAI {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Thinking on device…")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            } else {
                Button {
                    Haptics.tap()
                    isLoadingAI = true
                    Task { @MainActor in
                        aiTips = await store.ai.roleplayTips(prompt: prompt)
                        isLoadingAI = false
                        if aiTips == nil { aiFailed = true }
                        if aiTips != nil { Haptics.tap() }
                    }
                } label: {
                    Label("Get roleplay tips", systemImage: "sparkles")
                        .font(.appFootnote.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                }
                .buttonStyle(.plain)
            }

            if aiFailed && aiTips == nil {
                Text("AI tips couldn't run right now. The briefing above still has everything you need.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var pastAttemptsCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Your past attempts", systemImage: "clock.arrow.circlepath")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.textSecondary)
            ForEach(pastAttempts.prefix(3), id: \.objectID) { attempt in
                HStack {
                    Text((attempt.date ?? Date()).formatted(date: .abbreviated, time: .shortened))
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    if attempt.averageScore > 0 {
                        Text(String(format: "%.1f / 5", attempt.averageScore))
                            .font(.appCaptionBold)
                            .foregroundStyle(Palette.accent)
                            .monospacedDigit()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func infoCard(title: String, symbol: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: symbol)
                .font(.appCaptionBold)
                .foregroundStyle(Palette.textSecondary)
            Text(text)
                .font(.appCallout)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: Prep

    private var prepSection: some View {
        VStack(spacing: Metrics.stackSpacing) {
            TimerControl(timer: prepTimer, title: "Preparation", tint: Palette.accent)
                .appCard(padding: 20)

            VStack(alignment: .leading, spacing: 9) {
                Label("Prep notes", systemImage: "square.and.pencil")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)

                AppSegmentedPicker("Prep style", selection: $prepMode,
                                   options: PrepMode.allCases) { $0.title }

                if prepMode == .structured {
                    structuredPrepFields
                } else {
                    freePrepEditor
                }
            }
            .appCard()

            InfoBanner(systemImage: "target",
                       title: "Hit every indicator",
                       message: prompt.performanceIndicators.joined(separator: " · "),
                       tint: Palette.gold)

            PrimaryButton(title: "Start presentation", systemImage: "person.wave.2.fill") {
                prepTimer.pause()
                withAnimation(Motion.snappy) { phase = .present }
                presentTimer.start()
            }
        }
    }

    private var freePrepEditor: some View {
        TextEditor(text: $notes)
            .font(.appCallout)
            .frame(minHeight: 170)
            .scrollContentBackground(.hidden)
            .background(Palette.cardSunken)
            .cornerRadius(10)
            .overlay(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Jot your structure: greeting, the problem, your recommendation, the indicators you'll hit, and your close.")
                        .font(.appCallout)
                        .foregroundStyle(Palette.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityLabel("Preparation notes")
    }

    private var structuredPrepFields: some View {
        VStack(spacing: 10) {
            prepField(title: "Opening", icon: "hand.wave.fill",
                      placeholder: "Greet the judge and name your role.",
                      text: $structuredGreeting)
            prepField(title: "Problem", icon: "exclamationmark.triangle.fill",
                      placeholder: "What business issue needs to be solved?",
                      text: $structuredProblem)
            prepField(title: "Recommendation", icon: "lightbulb.fill",
                      placeholder: "What should the business do?",
                      text: $structuredRecommendation)
            prepField(title: "Evidence", icon: "chart.bar.fill",
                      placeholder: "Use the indicators, data, costs or customer impact.",
                      text: $structuredEvidence)
            prepField(title: "Risks", icon: "shield.lefthalf.filled",
                      placeholder: "Name a tradeoff and how you would reduce it.",
                      text: $structuredRisks)
            prepField(title: "Close", icon: "checkmark.seal.fill",
                      placeholder: "End with next steps and how success will be measured.",
                      text: $structuredClose)
        }
    }

    private func prepField(title: String,
                           icon: String,
                           placeholder: String,
                           text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.appCaptionBold)
                .foregroundStyle(Palette.textSecondary)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Palette.cardSunken)
                TextEditor(text: text)
                    .font(.appCallout)
                    .frame(minHeight: 76)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, -4)
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.appCallout)
                        .foregroundStyle(Palette.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var prepNotesText: String {
        if prepMode == .free {
            return notes.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let rows = [
            ("Opening", structuredGreeting),
            ("Problem", structuredProblem),
            ("Recommendation", structuredRecommendation),
            ("Evidence", structuredEvidence),
            ("Risks", structuredRisks),
            ("Close", structuredClose)
        ]
        return rows
            .map { title, value in
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : "\(title): \(trimmed)"
            }
            .compactMap { $0 }
            .joined(separator: "\n\n")
    }

    // MARK: Present

    private var presentSection: some View {
        VStack(spacing: Metrics.stackSpacing) {
            TimerControl(timer: presentTimer, title: "Presentation", tint: Palette.success)
                .appCard(padding: 20)

            VStack(alignment: .leading, spacing: 9) {
                Label("Type what you would say", systemImage: "text.bubble")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                Text(store.ai.isUsable
                     ? "Your typed answer stays on this device and is used to generate rubric feedback."
                     : "Typing your answer helps you self-assess against the rubric on the next screen.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                TextEditor(text: $transcript)
                    .font(.appCallout)
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .background(Palette.cardSunken)
                    .cornerRadius(10)
                    .accessibilityLabel("Presentation transcript")
            }
            .appCard()

            if !prepNotesText.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Your prep notes", systemImage: "square.and.pencil")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.textSecondary)
                    Text(prepNotesText)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()
            }

            PrimaryButton(title: "Finish and review", systemImage: "checkmark") {
                presentTimer.pause()
                withAnimation(Motion.snappy) { phase = .review }
                if store.ai.isUsable && !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    requestAIFeedback()
                }
            }
        }
    }

    // MARK: Review

    private var reviewSection: some View {
        VStack(spacing: Metrics.stackSpacing) {
            if store.ai.isUsable {
                aiFeedbackCard
            } else {
                InfoBanner(systemImage: "checklist",
                           title: "Self-assessment rubric",
                           message: "AI feedback isn't available on this device, so rate yourself honestly against the same categories judges use.",
                           tint: Palette.accent)
            }

            rubricCard

            PrimaryButton(title: saved ? "Saved" : "Save this practice",
                          systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down",
                          tint: saved ? Palette.success : Palette.accent,
                          isEnabled: !saved) {
                save()
            }

            if saved {
                InfoBanner(systemImage: "chart.bar.fill",
                           title: "Counted toward your indicators",
                           message: "This practice was added to \(prompt.performanceIndicators.count) performance indicator\(prompt.performanceIndicators.count == 1 ? "" : "s") in Progress.",
                           tint: Palette.success)
            }
        }
    }

    private var aiFeedbackCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Judge feedback · on device", systemImage: "sparkles")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.accent)

            if isLoadingAI {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Reviewing your response on device…")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            } else if let feedback = aiFeedback {
                feedbackRow("What went well", feedback.wentWell, Palette.success)
                feedbackRow("What could improve", feedback.couldImprove, Palette.gold)
                feedbackRow("Missing business concepts", feedback.missingConcepts, Palette.danger)
                feedbackRow("Stronger phrasing", feedback.strongerPhrasing, Palette.accent)
                feedbackRow("Suggested structure", feedback.suggestedStructure, Palette.accent)
                feedbackRow("A stronger answer", feedback.sampleAnswer, Palette.textSecondary)

                if !feedback.estimatedScores.isEmpty {
                    Button {
                        Haptics.success()
                        withAnimation(Motion.snappy) { scores = feedback.estimatedScores }
                    } label: {
                        Label("Apply AI score estimate to rubric", systemImage: "wand.and.stars")
                            .font(.appFootnote.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    .buttonStyle(.plain)
                }
            } else if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Type your presentation on the Present tab to get rubric feedback.")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
            } else if aiFailed {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI feedback couldn't run this time. Use the rubric below to score yourself.")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Try again") {
                        Haptics.tap()
                        aiFailed = false
                        requestAIFeedback()
                    }
                    .font(.appFootnote.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                }
            } else {
                Button {
                    Haptics.tap()
                    requestAIFeedback()
                } label: {
                    Label("Generate judge feedback", systemImage: "sparkles")
                        .font(.appFootnote.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    @ViewBuilder
    private func feedbackRow(_ title: String, _ body: String, _ tint: Color) -> some View {
        if !body.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.appCaptionBold)
                    .foregroundStyle(tint)
                Text(body)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var rubricCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("Judge rubric", systemImage: "checklist")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                Text(String(format: "%.1f / 5", averageScore))
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
            }

            ForEach(RubricCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)
                            .frame(width: 16)
                        Text(category.title)
                            .font(.appFootnote)
                            .foregroundStyle(Palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Text("\(scores[category] ?? 3)")
                            .font(.appCaptionBold)
                            .foregroundStyle(scoreColor(scores[category] ?? 3))
                            .monospacedDigit()
                    }
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                Haptics.select()
                                withAnimation(Motion.quick) { scores[category] = value }
                            } label: {
                                Text("\(value)")
                                    .font(.appCaptionBold)
                                    .foregroundStyle((scores[category] ?? 3) >= value ? .white : Palette.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill((scores[category] ?? 3) >= value
                                                  ? scoreColor(scores[category] ?? 3)
                                                  : Palette.cardSunken)
                                    )
                            }
                            .buttonStyle(PressableButtonStyle(haptic: false))
                            .accessibilityLabel("\(category.title): \(value) out of 5")
                            .accessibilityAddTraits((scores[category] ?? 3) == value ? [.isSelected, .isButton] : .isButton)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func scoreColor(_ value: Int) -> Color {
        switch value {
        case 5: return Palette.success
        case 4: return Palette.accent
        case 3: return Palette.gold
        default: return Palette.danger
        }
    }

    private var averageScore: Double {
        let values = RubricCategory.allCases.compactMap { scores[$0] }
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    // MARK: Actions

    private func requestAIFeedback() {
        guard store.ai.isUsable, !isLoadingAI else { return }
        isLoadingAI = true
        aiFailed = false
        Task { @MainActor in
            let result = await store.ai.analyzeRoleplay(prompt: prompt,
                                                        response: transcript,
                                                        notes: prepNotesText)
            isLoadingAI = false
            if let result {
                withAnimation(Motion.reveal) { aiFeedback = result }
                Haptics.success()
            } else {
                aiFailed = true
            }
        }
    }

    private func save() {
        let feedbackText = aiFeedback.map { fb in
            [fb.wentWell, fb.couldImprove, fb.missingConcepts, fb.sampleAnswer]
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")
        }
        store.saveRoleplayResponse(prompt: prompt,
                                   notes: prepNotesText,
                                   transcript: transcript,
                                   scores: scores,
                                   aiFeedback: feedbackText,
                                   prepSeconds: prepTimer.elapsed,
                                   presentSeconds: presentTimer.elapsed)
        Haptics.success()
        withAnimation(Motion.snappy) { saved = true }
        pastAttempts = store.roleplayResponses(promptID: prompt.id)
    }
}
