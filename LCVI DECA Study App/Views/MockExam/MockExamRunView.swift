//
//  MockExamRunView.swift
//  LCVI DECA Study App
//
//  Distraction-free exam mode: free navigation, flagging, optional timer.
//

import Combine
import SwiftUI

@MainActor
final class MockExamRunner: ObservableObject {
    let config: MockExamConfig
    let questions: [QuestionData]

    @Published var index = 0
    @Published var selections: [UUID: Int] = [:]
    @Published var flags: Set<UUID> = []
    @Published private(set) var secondsRemaining: TimeInterval = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var timeExpired = false

    private var start = Date()
    private var ticker: AnyCancellable?

    init(config: MockExamConfig, questions: [QuestionData]) {
        self.config = config
        self.questions = questions
        self.secondsRemaining = Double(config.timeLimitMinutes * 60)
    }

    var current: QuestionData? { questions.indices.contains(index) ? questions[index] : nil }
    var answeredCount: Int { selections.count }
    var progress: Double {
        questions.isEmpty ? 0 : Double(answeredCount) / Double(questions.count)
    }
    var isLast: Bool { index >= questions.count - 1 }
    var isFirst: Bool { index <= 0 }

    var timeDisplay: String {
        let value = max(0, Int(secondsRemaining.rounded()))
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    var elapsedDisplay: String {
        let value = max(0, Int(elapsed.rounded()))
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    var isTimeCritical: Bool { config.timed && secondsRemaining <= 60 }

    func begin() {
        start = Date()
        Haptics.prepare()
        ticker = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        elapsed = Date().timeIntervalSince(start)
        guard config.timed else { return }
        let limit = Double(config.timeLimitMinutes * 60)
        secondsRemaining = max(0, limit - elapsed)

        if secondsRemaining <= 0 && !timeExpired {
            timeExpired = true
            Haptics.warning()
            stop()
        } else if Int(secondsRemaining) == 300 || Int(secondsRemaining) == 60 {
            // Fires at most once per tick window; harmless if it repeats once.
            Haptics.warning()
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
    }

    func select(_ choice: Int) {
        guard let question = current else { return }
        Haptics.tap()
        selections[question.id] = choice
    }

    func toggleFlag() {
        guard let question = current else { return }
        Haptics.select()
        if flags.contains(question.id) {
            flags.remove(question.id)
        } else {
            flags.insert(question.id)
        }
    }

    func go(to newIndex: Int) {
        guard questions.indices.contains(newIndex) else { return }
        index = newIndex
    }

    func next() { if !isLast { Haptics.tap(); index += 1 } }
    func previous() { if !isFirst { Haptics.tap(); index -= 1 } }

    var isFlagged: Bool {
        guard let question = current else { return false }
        return flags.contains(question.id)
    }

    var unansweredCount: Int { questions.count - selections.count }

    deinit { ticker?.cancel() }
}

struct MockExamRunView: View {
    let payload: MockExamPayload
    var onFinish: (UUID) -> Void

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var runner: MockExamRunner
    @State private var showingSubmitConfirm = false
    @State private var showingExitConfirm = false
    @State private var showingNavigator = false

    init(payload: MockExamPayload, onFinish: @escaping (UUID) -> Void) {
        self.payload = payload
        self.onFinish = onFinish
        _runner = StateObject(wrappedValue: MockExamRunner(config: payload.config,
                                                           questions: payload.questions))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            questionBody
            footer
        }
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear { runner.begin() }
        .celebrationLayer(isFullScreen: true)
        .bunnyLayer(isFullScreen: true)
        .interactiveDismissDisabled(true)
        .sheet(isPresented: $showingNavigator) { navigator }
        .confirmationDialog("Submit this exam?",
                            isPresented: $showingSubmitConfirm,
                            titleVisibility: .visible) {
            Button("Submit", role: .destructive) { submit() }
            Button("Keep working", role: .cancel) { }
        } message: {
            Text(runner.unansweredCount == 0
                 ? "All \(runner.questions.count) questions are answered."
                 : "\(runner.unansweredCount) question\(runner.unansweredCount == 1 ? " is" : "s are") still unanswered. They'll be marked incorrect.")
        }
        .confirmationDialog("Leave the exam?",
                            isPresented: $showingExitConfirm,
                            titleVisibility: .visible) {
            Button("Discard exam", role: .destructive) {
                runner.stop()
                dismiss()
            }
            Button("Keep working", role: .cancel) { }
        } message: {
            Text("Nothing from this attempt will be saved.")
        }
        .onChange(of: runner.timeExpired) { expired in
            if expired { submit() }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    showingExitConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.cardSunken))
                }
                .accessibilityLabel("Exit exam")

                VStack(alignment: .leading, spacing: 1) {
                    Text("Question \(runner.index + 1) of \(runner.questions.count)")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.textPrimary)
                        .monospacedDigit()
                    Text("\(runner.answeredCount) answered")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)

                if payload.config.timed {
                    TimerPill(text: runner.timeDisplay, isWarning: runner.isTimeCritical)
                } else {
                    TimerPill(text: runner.elapsedDisplay)
                }

                Button {
                    Haptics.tap()
                    showingNavigator = true
                } label: {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.cardSunken))
                }
                .accessibilityLabel("Question navigator")
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.cardSunken)
                    Capsule()
                        .fill(Palette.accent)
                        .frame(width: max(6, geo.size.width * runner.progress))
                        .animation(reduceMotion ? nil : Motion.snappy, value: runner.progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 10)
        .padding(.bottom, 11)
        .background(
            Palette.card
                .overlay(alignment: .bottom) { Rectangle().fill(Palette.stroke).frame(height: 0.5) }
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: Body

    private var questionBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let question = runner.current {
                    HStack(spacing: 6) {
                        TagPill(text: question.cluster.shortName,
                                color: question.cluster.tint,
                                soft: question.cluster.tint.opacity(0.13))
                        Spacer(minLength: 0)
                        Button {
                            runner.toggleFlag()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: runner.isFlagged ? "flag.fill" : "flag")
                                Text(runner.isFlagged ? "Flagged" : "Flag")
                            }
                            .font(.appCaptionBold)
                            .foregroundStyle(runner.isFlagged ? Palette.gold : Palette.textSecondary)
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                            .background(Capsule().fill(runner.isFlagged ? Palette.goldSoft : Palette.cardSunken))
                        }
                        .buttonStyle(PressableButtonStyle(haptic: false))
                        .accessibilityLabel(runner.isFlagged ? "Remove flag" : "Flag for review")
                    }

                    Text(question.text)
                        .font(.appQuestion)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 9) {
                        ForEach(Array(question.choices.enumerated()), id: \.offset) { index, text in
                            AnswerChoiceButton(letter: AnswerLetter(rawValue: index)?.label ?? "?",
                                               text: text,
                                               state: runner.selections[question.id] == index ? .selected : .neutral) {
                                runner.select(index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
            .id(runner.index)
        }
        .animation(reduceMotion ? nil : Motion.quick, value: runner.index)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.stroke)
            HStack(spacing: 9) {
                Button {
                    runner.previous()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 52, height: 48)
                        .foregroundStyle(runner.isFirst ? Palette.textTertiary : Palette.textPrimary)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Palette.cardSunken))
                }
                .buttonStyle(PressableButtonStyle(haptic: false))
                .disabled(runner.isFirst)
                .accessibilityLabel("Previous question")

                if runner.isLast {
                    PrimaryButton(title: "Submit exam", systemImage: "checkmark") {
                        showingSubmitConfirm = true
                    }
                } else {
                    PrimaryButton(title: "Next", systemImage: "chevron.right") {
                        runner.next()
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 11)
            .padding(.bottom, 5)
        }
        .background(Palette.card.ignoresSafeArea(edges: .bottom))
    }

    // MARK: Navigator

    private var navigator: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    legend
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                              spacing: 8) {
                        ForEach(Array(runner.questions.enumerated()), id: \.offset) { index, question in
                            Button {
                                Haptics.tap()
                                runner.go(to: index)
                                showingNavigator = false
                            } label: {
                                Text("\(index + 1)")
                                    .font(.appFootnote.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(navigatorForeground(question))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(navigatorFill(question))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(index == runner.index ? Palette.accent : .clear,
                                                          lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PressableButtonStyle(haptic: false))
                            .accessibilityLabel("Question \(index + 1)")
                            .accessibilityValue(runner.selections[question.id] != nil ? "Answered" : "Not answered")
                        }
                    }

                    PrimaryButton(title: "Submit exam", systemImage: "checkmark") {
                        showingNavigator = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingSubmitConfirm = true
                        }
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.vertical, 16)
            }
            .appCanvas()
            .navigationTitle("Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingNavigator = false }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Palette.accentSoft, label: "Answered")
            legendItem(color: Palette.goldSoft, label: "Flagged")
            legendItem(color: Palette.cardSunken, label: "Blank")
            Spacer(minLength: 0)
        }
        .font(.appCaption)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 14, height: 14)
            Text(label).foregroundStyle(Palette.textSecondary)
        }
    }

    private func navigatorFill(_ question: QuestionData) -> Color {
        if runner.flags.contains(question.id) { return Palette.goldSoft }
        if runner.selections[question.id] != nil { return Palette.accentSoft }
        return Palette.cardSunken
    }

    private func navigatorForeground(_ question: QuestionData) -> Color {
        if runner.flags.contains(question.id) { return Palette.gold }
        if runner.selections[question.id] != nil { return Palette.accent }
        return Palette.textSecondary
    }

    // MARK: Submit

    private func submit() {
        runner.stop()
        Haptics.sessionComplete()
        let attemptID = store.finishMockExam(config: payload.config,
                                             questions: runner.questions,
                                             selections: runner.selections,
                                             flags: runner.flags,
                                             elapsedSeconds: runner.elapsed)
        onFinish(attemptID)
    }
}
