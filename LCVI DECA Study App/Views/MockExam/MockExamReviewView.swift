//
//  MockExamReviewView.swift
//  LCVI DECA Study App
//
//  Results: animated score, topic and indicator breakdowns, missed questions,
//  a suggested study plan and full question review.
//

import SwiftUI

struct MockExamReviewView: View {
    let attemptID: UUID
    var onDone: () -> Void

    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var summary: MockExamSummary?
    @State private var outcomes: [MockQuestionOutcome] = []
    @State private var topics: [MockTopicAccuracy] = []
    @State private var indicatorRows: [MockTopicAccuracy] = []
    @State private var plan: [String] = []
    @State private var previousScore: Double?
    @State private var animatedScore: Double = 0
    @State private var showingAll = false
    @State private var retrySession: SessionPayload?

    private var missed: [MockQuestionOutcome] { outcomes.filter { !$0.isCorrect } }

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.sectionSpacing) {
                if let summary {
                    scoreHeader(summary).appearIn(0)
                    statRow(summary).appearIn(1)
                    if let improvement { improvementBanner(improvement).appearIn(2) }
                    topicSection.appearIn(3)
                    indicatorSection.appearIn(4)
                    missedSection.appearIn(5)
                    planSection.appearIn(6)
                    reviewSection.appearIn(7)
                    PrimaryButton(title: "Done", systemImage: "checkmark") { onDone() }
                        .appearIn(8)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .appCanvas()
        .navigationTitle("Exam results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { onDone() }
            }
        }
        .onAppear(perform: load)
        .celebrationLayer(isFullScreen: true)
        .fullScreenCover(item: $retrySession) { payload in
            PracticeSessionView(payload: payload).environmentObject(store)
        }
    }

    // MARK: Load

    private func load() {
        summary = store.mocks.summaries().first { $0.id == attemptID }
        outcomes = store.mocks.outcomes(for: attemptID)
        topics = store.mocks.topicAccuracy(for: outcomes)
        indicatorRows = store.mocks.indicatorAccuracy(for: outcomes)
        if let cluster = summary?.cluster {
            plan = store.mocks.suggestedPlan(for: outcomes, cluster: cluster)
            previousScore = store.mocks.previousScore(cluster: cluster, before: attemptID)
        }
        guard let summary else { return }
        if reduceMotion {
            animatedScore = summary.scorePercent
        } else {
            withAnimation(.easeOut(duration: 1.1)) { animatedScore = summary.scorePercent }
        }
    }

    private var improvement: Double? {
        guard let summary, let previousScore else { return nil }
        let delta = summary.scorePercent - previousScore
        return abs(delta) < 0.5 ? nil : delta
    }

    // MARK: Header

    private func scoreHeader(_ summary: MockExamSummary) -> some View {
        VStack(spacing: 13) {
            ZStack {
                ProgressRing(progress: summary.scorePercent / 100,
                             lineWidth: 13,
                             tint: tint(for: summary.scorePercent))
                    .frame(width: 148, height: 148)
                VStack(spacing: 0) {
                    CountingNumber(value: animatedScore,
                                   font: .numeric(42),
                                   color: Palette.textPrimary) { "\(Int($0.rounded()))%" }
                    Text("\(summary.correctCount) of \(summary.questionCount)")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                        .monospacedDigit()
                }
            }
            Text(summary.cluster.examName)
                .font(.appHeadline)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(summary.date.formatted(date: .abbreviated, time: .shortened))
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Score \(Int(summary.scorePercent.rounded())) percent, \(summary.correctCount) of \(summary.questionCount) correct")
    }

    private func statRow(_ summary: MockExamSummary) -> some View {
        HStack(spacing: 10) {
            StatCard(title: "Correct", value: "\(summary.correctCount)",
                     systemImage: "checkmark", tint: Palette.success)
            StatCard(title: "Incorrect", value: "\(summary.incorrectCount)",
                     systemImage: "xmark", tint: Palette.danger)
            StatCard(title: "Time", value: durationText(summary.durationSeconds),
                     caption: summary.timed ? "Timed" : "Untimed",
                     systemImage: "clock")
        }
    }

    private func improvementBanner(_ delta: Double) -> some View {
        InfoBanner(systemImage: delta > 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle",
                   title: delta > 0
                        ? "Up \(Int(abs(delta).rounded())) points from your last \(summary?.cluster.shortName ?? "") exam"
                        : "Down \(Int(abs(delta).rounded())) points from your last attempt",
                   message: delta > 0
                        ? "Whatever you changed is working — keep the same routine."
                        : "Work through the missed questions below before your next attempt.",
                   tint: delta > 0 ? Palette.success : Palette.gold)
    }

    private func tint(for score: Double) -> Color {
        switch score {
        case 85...:   return Palette.success
        case 65..<85: return Palette.accent
        default:      return Palette.gold
        }
    }

    // MARK: Breakdowns

    @ViewBuilder
    private var topicSection: some View {
        if !topics.isEmpty {
            VStack(alignment: .leading, spacing: 11) {
                SectionHeader(title: "Accuracy by topic")
                VStack(spacing: 13) {
                    ForEach(topics.prefix(6)) { topic in
                        LabeledBar(label: topic.name.capitalized,
                                   value: topic.accuracy,
                                   caption: "\(topic.correct)/\(topic.total)",
                                   tint: barTint(topic.accuracy))
                    }
                }
                .appCard()
            }
        }
    }

    @ViewBuilder
    private var indicatorSection: some View {
        if !indicatorRows.isEmpty {
            VStack(alignment: .leading, spacing: 11) {
                SectionHeader(title: "Accuracy by performance indicator")
                VStack(spacing: 13) {
                    ForEach(indicatorRows.prefix(6)) { row in
                        PerformanceIndicatorBar(code: row.name,
                                                text: SeedIndicators.text(forCode: row.name) ?? "Performance indicator",
                                                value: row.accuracy,
                                                detail: "\(row.correct) of \(row.total) correct on this exam",
                                                tint: barTint(row.accuracy))
                    }
                }
                .appCard()
            }
        }
    }

    private func barTint(_ value: Double) -> Color {
        switch value {
        case 0.85...:    return Palette.success
        case 0.6..<0.85: return Palette.accent
        default:         return Palette.danger
        }
    }

    // MARK: Missed

    @ViewBuilder
    private var missedSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Missed questions",
                          subtitle: missed.isEmpty ? nil : "Already saved to your Mistake Notebook")

            if missed.isEmpty {
                InfoBanner(systemImage: "checkmark.seal.fill",
                           title: "Perfect score",
                           message: "Nothing was missed on this attempt.",
                           tint: Palette.success)
            } else {
                PrimaryButton(title: "Retry \(missed.count) missed question\(missed.count == 1 ? "" : "s")",
                              systemImage: "arrow.uturn.left",
                              tint: Palette.danger) {
                    let built = BuiltSession(mode: .mockRetry,
                                             cluster: summary?.cluster,
                                             questions: missed.map(\.question).shuffled(),
                                             composition: ["\(missed.count) missed on your last mock exam"])
                    retrySession = SessionPayload(session: built, title: "Retry missed")
                }

                ForEach(missed.prefix(showingAll ? missed.count : 3)) { outcome in
                    MockQuestionRow(outcome: outcome)
                }

                if missed.count > 3 && !showingAll {
                    Button("Show all \(missed.count)") {
                        Haptics.tap()
                        withAnimation(Motion.snappy) { showingAll = true }
                    }
                    .font(.appFootnote.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                }
            }
        }
    }

    // MARK: Plan

    @ViewBuilder
    private var planSection: some View {
        if !plan.isEmpty {
            VStack(alignment: .leading, spacing: 11) {
                SectionHeader(title: "Suggested next study plan")
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(plan.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.appCaptionBold)
                                .foregroundStyle(Palette.accent)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Palette.accentSoft))
                            Text(step)
                                .font(.appFootnote)
                                .foregroundStyle(Palette.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .appCard()
            }
        }
    }

    // MARK: Full review

    private var reviewSection: some View {
        NavigationLink {
            FullExamReviewList(outcomes: outcomes)
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Palette.accentSoft)
                        .frame(width: 42, height: 42)
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Review every question")
                        .font(.appBodyMedium)
                        .foregroundStyle(Palette.textPrimary)
                    Text("All \(outcomes.count) questions with your answer and the explanation.")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .appCard()
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
    }

    private func durationText(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        if total < 60 { return "\(total)s" }
        return "\(total / 60)m \(total % 60)s"
    }
}

// MARK: - Question row

struct MockQuestionRow: View {
    let outcome: MockQuestionOutcome
    @EnvironmentObject private var store: AppStore
    @State private var expanded = false
    @State private var isBookmarked = false

    private var question: QuestionData { outcome.question }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    toggleExpanded()
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: outcome.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(outcome.isCorrect ? Palette.success : Palette.danger)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question.text)
                                .font(.appFootnote.weight(.medium))
                                .foregroundStyle(Palette.textPrimary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(expanded ? nil : 2)
                                .fixedSize(horizontal: false, vertical: true)
                            if outcome.flagged {
                                TagPill(text: "Flagged", color: Palette.gold, soft: Palette.goldSoft, icon: "flag.fill")
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
                bookmarkButton
                Button(action: toggleExpanded) {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(expanded ? "Collapse question" : "Expand question")
            }

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(question.choices.enumerated()), id: \.offset) { index, text in
                        HStack(alignment: .top, spacing: 8) {
                            Text(AnswerLetter(rawValue: index)?.label ?? "")
                                .font(.appCaptionBold)
                                .foregroundStyle(color(for: index))
                                .frame(width: 16, alignment: .leading)
                            Text(text)
                                .font(.appFootnote)
                                .foregroundStyle(color(for: index))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            if index == question.correctIndex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Palette.success)
                            } else if index == outcome.selectedIndex {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Palette.danger)
                            }
                        }
                    }
                    if outcome.selectedIndex < 0 {
                        Text("You didn't answer this question.")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textTertiary)
                    }
                    if !question.explanation.isEmpty {
                        Divider().overlay(Palette.stroke)
                        Text(question.explanation)
                            .font(.appFootnote)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if question.hasChoiceRationales {
                        Divider().overlay(Palette.stroke)
                        ChoiceRationaleList(question: question,
                                            selectedIndex: outcome.selectedIndex < 0 ? nil : outcome.selectedIndex)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
        .onAppear { isBookmarked = question.isBookmarked }
    }

    private var bookmarkButton: some View {
        Button {
            toggleBookmark()
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isBookmarked ? Palette.gold : Palette.textTertiary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(isBookmarked ? Palette.goldSoft : Palette.cardSunken))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94, haptic: false))
        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark question")
    }

    private func toggleExpanded() {
        Haptics.tap()
        withAnimation(Motion.snappy) { expanded.toggle() }
    }

    private func toggleBookmark() {
        Haptics.select()
        let next = !isBookmarked
        if store.bank.setBookmarked(next, questionID: question.id) {
            withAnimation(Motion.quick) { isBookmarked = next }
            store.refresh()
        }
    }

    private func color(for index: Int) -> Color {
        if index == question.correctIndex { return Palette.success }
        if index == outcome.selectedIndex { return Palette.danger }
        return Palette.textSecondary
    }
}

// MARK: - Full list

struct FullExamReviewList: View {
    let outcomes: [MockQuestionOutcome]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(outcomes) { outcome in
                    MockQuestionRow(outcome: outcome)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 12)
        }
        .appCanvas()
        .navigationTitle("All questions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
