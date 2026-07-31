//
//  PracticeSessionView.swift
//  LCVI DECA Study App
//
//  The question screen used by daily practice, review, mistakes, custom
//  practice and Exam Cram.
//

import SwiftUI

struct PracticeSessionView: View {
    let payload: SessionPayload

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var runner: PracticeRunner
    @State private var showingExitConfirm = false
    @State private var bookmarkedIDs: Set<UUID> = []

    init(payload: SessionPayload) {
        self.payload = payload
        _runner = StateObject(wrappedValue: PracticeRunner(session: payload.session,
                                                           timeLimit: payload.timeLimitSeconds))
    }

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            if runner.finished {
                SessionSummaryView(runner: runner, title: payload.title) { dismiss() }
                    .transition(reduceMotion ? .opacity
                                : .asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                              removal: .opacity))
            } else {
                questionFlow
            }
        }
        .onAppear {
            bookmarkedIDs = Set(payload.session.questions.filter(\.isBookmarked).map(\.id))
            runner.start(store: store)
        }
        .celebrationLayer(isFullScreen: true)
        .interactiveDismissDisabled(true)
        .confirmationDialog("End this session?",
                            isPresented: $showingExitConfirm,
                            titleVisibility: .visible) {
            Button("End session", role: .destructive) {
                runner.abandon(store: store)
                dismiss()
            }
            Button("Keep practising", role: .cancel) { }
        } message: {
            Text("Your answers so far are already saved.")
        }
    }

    // MARK: - Question flow

    private var questionFlow: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let question = runner.current {
                            questionMetaRow(for: question)
                            questionText(question)
                            choices(for: question)

                            if runner.revealed {
                                feedbackArea(for: question)
                                    .id("feedback")
                            }
                        }
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }
                .onChange(of: runner.revealed) { revealed in
                    guard revealed, !reduceMotion else { return }
                    withAnimation(Motion.gentle) { proxy.scrollTo("feedback", anchor: .top) }
                }
            }

            footer
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    Haptics.tap()
                    if runner.log.isEmpty {
                        dismiss()
                    } else {
                        showingExitConfirm = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.cardSunken))
                }
                .accessibilityLabel("Close session")

                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.cardSunken)
                            Capsule()
                                .fill(Palette.accent)
                                .frame(width: max(6, geo.size.width * progressFraction))
                                .animation(reduceMotion ? nil : Motion.snappy, value: progressFraction)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(min(runner.index + 1, runner.questions.count)) of \(runner.questions.count)")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                            .monospacedDigit()
                        Spacer()
                        Text("\(runner.correctCount) correct")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                            .monospacedDigit()
                    }
                }

                if runner.timeLimit != nil {
                    TimerPill(text: runner.timeDisplay, isWarning: runner.isTimeCritical)
                }
            }
            .padding(.horizontal, Metrics.gutter)
        }
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            Palette.card
                .overlay(alignment: .bottom) { Rectangle().fill(Palette.stroke).frame(height: 0.5) }
                .ignoresSafeArea(edges: .top)
        )
        .accessibilityElement(children: .contain)
    }

    private var progressFraction: Double {
        guard !runner.questions.isEmpty else { return 0 }
        let answered = Double(runner.index) + (runner.revealed ? 1 : 0)
        return min(1, answered / Double(runner.questions.count))
    }

    // MARK: - Question content

    private func questionMetaRow(for question: QuestionData) -> some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    TagPill(text: payload.title ?? question.cluster.shortName,
                            color: question.cluster.tint,
                            soft: question.cluster.tint.opacity(0.13),
                            icon: question.cluster.symbol)
                    TagPill(text: question.difficulty.title,
                            color: question.difficulty.color,
                            soft: question.difficulty.color.opacity(0.13))
                    ForEach(question.tags.prefix(2), id: \.self) { tag in
                        TagPill(text: tag, color: Palette.textSecondary, soft: Palette.cardSunken)
                    }
                    ForEach(question.performanceIndicators.prefix(2), id: \.self) { code in
                        TagPill(text: code, color: Palette.gold, soft: Palette.goldSoft, icon: "target")
                    }
                }
                .padding(.vertical, 1)
            }

            Button {
                toggleBookmark(question)
            } label: {
                Image(systemName: bookmarkedIDs.contains(question.id) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(bookmarkedIDs.contains(question.id) ? Palette.gold : Palette.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(bookmarkedIDs.contains(question.id) ? Palette.goldSoft : Palette.cardSunken))
            }
            .buttonStyle(PressableButtonStyle(scale: 0.94, haptic: false))
            .accessibilityLabel(bookmarkedIDs.contains(question.id) ? "Remove bookmark" : "Bookmark question")
        }
    }

    private func toggleBookmark(_ question: QuestionData) {
        Haptics.select()
        let shouldBookmark = !bookmarkedIDs.contains(question.id)
        if store.bank.setBookmarked(shouldBookmark, questionID: question.id) {
            withAnimation(Motion.quick) {
                if shouldBookmark {
                    bookmarkedIDs.insert(question.id)
                } else {
                    bookmarkedIDs.remove(question.id)
                }
            }
            store.refresh()
        }
    }

    private func questionText(_ question: QuestionData) -> some View {
        Text(question.text)
            .font(.appQuestion)
            .foregroundStyle(Palette.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private func choices(for question: QuestionData) -> some View {
        VStack(spacing: 9) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, text in
                AnswerChoiceButton(letter: AnswerLetter(rawValue: index)?.label ?? "?",
                                   text: text,
                                   state: state(for: index, question: question),
                                   isLocked: runner.revealed) {
                    runner.select(index)
                }
            }
        }
    }

    private func state(for index: Int, question: QuestionData) -> AnswerChoiceState {
        guard runner.revealed else {
            return runner.selected == index ? .selected : .neutral
        }
        if index == question.correctIndex { return .correct }
        if index == runner.selected { return .wrong }
        return .dimmed
    }

    // MARK: - Feedback

    private func feedbackArea(for question: QuestionData) -> some View {
        let isCorrect = runner.selected == question.correctIndex
        return VStack(alignment: .leading, spacing: 12) {
            AnimatedFeedbackBanner(
                isCorrect: isCorrect,
                title: isCorrect ? "Correct" : "Not quite",
                message: isCorrect
                    ? nil
                    : "Answer \(AnswerLetter(rawValue: question.correctIndex)?.label ?? "") is correct. Saved to your Mistake Notebook."
            )

            explanationCard(for: question)
        }
    }

    private func explanationCard(for question: QuestionData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !question.explanation.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Explanation", systemImage: "text.alignleft")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.textSecondary)
                    Text(question.explanation)
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if !store.ai.isUsable {
                VStack(alignment: .leading, spacing: 6) {
                    Label("No explanation saved", systemImage: "text.alignleft")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.textSecondary)
                    Text("This question doesn't have a written explanation yet. Review \(topicHint(for: question)) and add an explanation from the Question Bank Manager.")
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if question.hasChoiceRationales {
                Divider().overlay(Palette.stroke)
                ChoiceRationaleList(question: question, selectedIndex: runner.selected)
            }

            if !question.performanceIndicators.isEmpty {
                Divider().overlay(Palette.stroke)
                VStack(alignment: .leading, spacing: 5) {
                    Label("Performance indicator", systemImage: "target")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.gold)
                    ForEach(question.performanceIndicators, id: \.self) { code in
                        Text("\(code) — \(SeedIndicators.text(forCode: code) ?? "Indicator")")
                            .font(.appFootnote)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            aiSection(for: question)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    @ViewBuilder
    private func aiSection(for question: QuestionData) -> some View {
        if store.ai.isUsable {
            Divider().overlay(Palette.stroke)

            if let explanation = runner.aiExplanation {
                VStack(alignment: .leading, spacing: 6) {
                    Label("AI coaching · on device", systemImage: "sparkles")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.accent)
                    Text(explanation)
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if runner.isLoadingAI {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Thinking on device…")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                .accessibilityLabel("Generating AI explanation on device")
            } else if runner.aiFailed {
                Text("AI coaching couldn't run for this question. The written explanation above still applies.")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Button {
                    Haptics.tap()
                    runner.requestAIExplanation(store: store,
                                                question: question,
                                                selectedIndex: runner.selected ?? -1)
                } label: {
                    Label("Explain with AI", systemImage: "sparkles")
                        .font(.appFootnote.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func topicHint(for question: QuestionData) -> String {
        if let tag = question.tags.first { return tag }
        return question.cluster.shortName.lowercased()
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.stroke)
            Group {
                if runner.revealed {
                    PrimaryButton(title: runner.isLastQuestion ? "Finish session" : "Continue",
                                  systemImage: runner.isLastQuestion ? "flag.checkered" : "arrow.right",
                                  tint: runner.selected == runner.current?.correctIndex
                                        ? Palette.success : Palette.accent) {
                        runner.advance(store: store)
                    }
                } else {
                    PrimaryButton(title: "Submit answer",
                                  isEnabled: runner.selected != nil) {
                        runner.submit(store: store)
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 12)
            .padding(.bottom, 6)
        }
        .background(Palette.card.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Summary

struct SessionSummaryView: View {
    @ObservedObject var runner: PracticeRunner
    var title: String?
    var onDone: () -> Void

    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedAccuracy: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.stackSpacing) {
                header.appearIn(0)
                stats.appearIn(1)

                if !runner.improvedTags.isEmpty {
                    summaryCard(title: "Topics improved",
                                symbol: "arrow.up.right",
                                tint: Palette.success,
                                items: runner.improvedTags)
                        .appearIn(2)
                }

                if !runner.weakTags.isEmpty {
                    summaryCard(title: "Still needs work",
                                symbol: "exclamationmark.triangle",
                                tint: Palette.gold,
                                items: runner.weakTags)
                        .appearIn(3)
                }

                if !runner.missedQuestions.isEmpty {
                    missedList.appearIn(4)
                }

                nextStep.appearIn(5)

                // The suggestion used to be prose only — "try a mock exam",
                // "review your Mistake Notebook" — leaving the student to
                // find the way themselves. Now the advice is a button: it
                // dismisses this cover, and the app routes there.
                if let action = nextStepAction {
                    PrimaryButton(title: action.title,
                                  systemImage: action.symbol,
                                  isProminent: false) {
                        onDone()
                        action.perform(store)
                    }
                    .appearIn(6)
                }

                PrimaryButton(title: "Done", systemImage: "checkmark") { onDone() }
                    .appearIn(7)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 24)
            .padding(.bottom, 30)
        }
        .onAppear {
            if reduceMotion {
                animatedAccuracy = runner.accuracy
            } else {
                withAnimation(.easeOut(duration: 0.9)) { animatedAccuracy = runner.accuracy }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                ProgressRing(progress: runner.accuracy,
                             lineWidth: 12,
                             tint: accuracyTint)
                    .frame(width: 130, height: 130)
                VStack(spacing: 0) {
                    CountingNumber(value: animatedAccuracy * 100,
                                   font: .numeric(36),
                                   color: Palette.textPrimary) { "\(Int($0.rounded()))%" }
                    Text("accuracy")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Text(title ?? "\(runner.mode.title) complete")
                .font(.appTitle)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
            Text("\(runner.correctCount) of \(runner.log.count) correct in \(formatted(runner.elapsed))")
                .font(.appCallout)
                .foregroundStyle(Palette.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var accuracyTint: Color {
        switch runner.accuracy {
        case 0.85...:    return Palette.success
        case 0.6..<0.85: return Palette.accent
        default:         return Palette.gold
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatCard(title: "Answered", value: "\(runner.log.count)", systemImage: "checkmark.circle")
            StatCard(title: "Correct", value: "\(runner.correctCount)",
                     systemImage: "hand.thumbsup", tint: Palette.success)
            StatCard(title: "Missed", value: "\(runner.log.count - runner.correctCount)",
                     systemImage: "arrow.uturn.left", tint: Palette.danger)
        }
    }

    private func summaryCard(title: String, symbol: String, tint: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: symbol)
                .font(.appCaptionBold)
                .foregroundStyle(tint)
            FlowTags(items: items, tint: tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var missedList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Added to your Mistake Notebook", systemImage: "book.closed.fill")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.danger)
            ForEach(runner.missedQuestions.prefix(4)) { question in
                Text("• \(question.text)")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if runner.missedQuestions.count > 4 {
                Text("and \(runner.missedQuestions.count - 4) more")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var nextStep: some View {
        InfoBanner(systemImage: "arrow.right.circle",
                   title: "Suggested next session",
                   message: nextStepMessage,
                   tint: Palette.accent)
    }

    private struct NextStepAction {
        let title: String
        let symbol: String
        let perform: (AppStore) -> Void
    }

    /// The one-tap version of `nextStepMessage`, when the advice has a
    /// destination in the app. Routing happens through the store's navigation
    /// intents, so this works no matter which tab presented the session.
    private var nextStepAction: NextStepAction? {
        if runner.log.isEmpty { return nil }
        if runner.accuracy >= 0.9 {
            return NextStepAction(title: "Set up a mock exam", symbol: "doc.text") {
                $0.openMockExams()
            }
        }
        if !runner.missedQuestions.isEmpty {
            return NextStepAction(title: "Open Mistake Notebook", symbol: "book.closed") {
                $0.openMistakeNotebook()
            }
        }
        return nil
    }

    private var nextStepMessage: String {
        if runner.log.isEmpty { return "Start a daily practice session to build your streak." }
        if runner.accuracy >= 0.9 {
            return "Strong session. Try a timed mock exam to test yourself under pressure."
        }
        if !runner.weakTags.isEmpty {
            return "Run a topic session on \(runner.weakTags.prefix(2).joined(separator: " and ")), then review your Mistake Notebook."
        }
        return "Review your Mistake Notebook, then come back tomorrow to keep the streak alive."
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }
}

/// Simple wrapping tag list (no iOS 16+ Layout requirement).
struct FlowTags: View {
    let items: [String]
    var tint: Color = Palette.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows(), id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { item in
                        TagPill(text: item, color: tint, soft: tint.opacity(0.13))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// Groups tags two-per-row, which reads well at every Dynamic Type size.
    private func rows() -> [[String]] {
        stride(from: 0, to: items.count, by: 2).map {
            Array(items[$0..<min($0 + 2, items.count)])
        }
    }
}
