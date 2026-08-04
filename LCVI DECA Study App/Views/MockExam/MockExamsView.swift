//
//  MockExamsView.swift
//  LCVI DECA Study App
//
//  Setup, history and launch for full-length mock exams.
//

import SwiftUI

struct MockExamsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var config = MockExamConfig(cluster: .marketing)
    @State private var runningExam: MockExamPayload?
    @State private var reviewAttempt: AttemptReview?
    @State private var summaries: [MockExamSummary] = []
    @State private var bankCount = 0

    var body: some View {
        ScrollView {
                VStack(spacing: Metrics.sectionSpacing) {
                    ScreenHeader("Mock Exams",
                                 subtitle: "Full-length practice under real time pressure.")
                        .appearIn(0)

                    if bankCount == 0 {
                        EmptyStateView(systemImage: "doc.text",
                                       title: "No questions yet",
                                       message: "Add or import a question bank to build a mock exam.",
                                       actionTitle: "Add questions") {
                            store.openQuestionBankManager()
                        }
                            .appCard()
                    } else {
                        setupCard.appearIn(0)
                        startButton.appearIn(1)
                        history.appearIn(2)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .appCanvas()
            .toolbar(.visible, for: .navigationBar)
        .onAppear(perform: reload)
        .fullScreenCover(item: $runningExam) { payload in
            MockExamRunView(payload: payload) { attemptID in
                runningExam = nil
                reload()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    reviewAttempt = AttemptReview(id: attemptID)
                }
            }
            .environmentObject(store)
        }
        .fullScreenCover(item: $reviewAttempt) { attempt in
            NavigationStack {
                MockExamReviewView(attemptID: attempt.id) { reviewAttempt = nil }
            }
            .environmentObject(store)
        }
    }

    // MARK: Setup

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "New exam", subtitle: "Set it up the way your competition runs.")

            VStack(spacing: 14) {
                HStack {
                    Text("Cluster / exam")
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    AppMenuPicker("Cluster", selection: $config.cluster,
                                  options: DECACluster.allCases) { $0.shortName }
                }

                Divider().overlay(Palette.stroke)

                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("Questions")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Text("\(config.questionCount)")
                            .font(.appCallout.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                            .monospacedDigit()
                    }
                    HStack(spacing: 8) {
                        ForEach([10, 25, 50, 100], id: \.self) { value in
                            countChip(value)
                        }
                    }
                }

                Divider().overlay(Palette.stroke)

                Toggle("Timed exam", isOn: $config.timed)
                    .font(.appCallout)
                    .tint(Palette.accent)

                if config.timed {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text("Time limit")
                                .font(.appCallout)
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Text("\(config.timeLimitMinutes) min")
                                .font(.appCallout.weight(.semibold))
                                .foregroundStyle(Palette.accent)
                                .monospacedDigit()
                        }
                        HStack(spacing: 8) {
                            ForEach([15, 30, 60, 70], id: \.self) { value in
                                timeChip(value)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider().overlay(Palette.stroke)

                Toggle(isOn: $config.weakTopicsOnly) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weak topics only")
                            .font(.appCallout)
                            .foregroundStyle(Palette.textPrimary)
                        Text("Draws from indicators you're scoring lowest on.")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                .tint(Palette.accent)
            }
            .appCard()
            .animation(Motion.snappy, value: config.timed)
        }
    }

    private func countChip(_ value: Int) -> some View {
        let available = min(value, bankCount)
        return Button {
            Haptics.select()
            withAnimation(Motion.quick) { config.questionCount = available }
        } label: {
            Text("\(value)")
                .font(.appFootnote.weight(.semibold))
                .foregroundStyle(config.questionCount == available ? .white : Palette.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(config.questionCount == available ? Palette.accent : Palette.cardSunken)
                )
                .opacity(value > bankCount ? 0.5 : 1)
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
        .accessibilityLabel("\(value) questions")
    }

    private func timeChip(_ value: Int) -> some View {
        Button {
            Haptics.select()
            withAnimation(Motion.quick) { config.timeLimitMinutes = value }
        } label: {
            Text("\(value)m")
                .font(.appFootnote.weight(.semibold))
                .foregroundStyle(config.timeLimitMinutes == value ? .white : Palette.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(config.timeLimitMinutes == value ? Palette.accent : Palette.cardSunken)
                )
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
        .accessibilityLabel("\(value) minute limit")
    }

    private var startButton: some View {
        PrimaryButton(title: "Start mock exam", systemImage: "play.fill") {
            let questions = store.mocks.buildExam(config)
            guard !questions.isEmpty else { return }
            var applied = config
            applied.questionCount = questions.count
            runningExam = MockExamPayload(config: applied, questions: questions)
        }
    }

    // MARK: History

    @ViewBuilder
    private var history: some View {
        // Lazy: attempt history only ever grows, so this is the one section on
        // the screen whose cost is unbounded.
        LazyVStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Score history",
                          subtitle: summaries.isEmpty ? nil : "\(summaries.count) attempt\(summaries.count == 1 ? "" : "s")")

            if summaries.isEmpty {
                EmptyStateView(systemImage: "chart.line.uptrend.xyaxis",
                               title: "No mock exams yet",
                               message: "Take your first mock exam to start tracking scores.")
                    .appCard()
            } else {
                ScoreTrendChart(summaries: summaries.reversed())
                    .appCard()

                ForEach(summaries) { summary in
                    Button {
                        Haptics.tap()
                        reviewAttempt = AttemptReview(id: summary.id)
                    } label: {
                        HStack(spacing: 13) {
                            ZStack {
                                Circle()
                                    .fill(tint(for: summary.scorePercent).opacity(0.14))
                                    .frame(width: 46, height: 46)
                                Text("\(Int(summary.scorePercent.rounded()))")
                                    .font(.numeric(16))
                                    .foregroundStyle(tint(for: summary.scorePercent))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(summary.cluster.shortName)
                                    .font(.appBodyMedium)
                                    .foregroundStyle(Palette.textPrimary)
                                Text("\(summary.correctCount)/\(summary.questionCount) correct · \(durationText(summary.durationSeconds))")
                                    .font(.appCaption)
                                    .foregroundStyle(Palette.textSecondary)
                                Text(summary.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.appCaption)
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.textTertiary)
                        }
                        .appCard()
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func tint(for score: Double) -> Color {
        switch score {
        case 85...:    return Palette.success
        case 65..<85:  return Palette.accent
        default:       return Palette.gold
        }
    }

    private func durationText(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return total < 60 ? "\(total)s" : "\(total / 60)m"
    }

    private func reload() {
        summaries = store.mocks.summaries()
        bankCount = store.bank.questionCount()
        config.cluster = store.settings.cluster
        config.questionCount = min(config.questionCount, max(1, bankCount))
    }
}

// MARK: - Payload

struct MockExamPayload: Identifiable {
    let id = UUID()
    let config: MockExamConfig
    let questions: [QuestionData]
}

/// Wrapper so a completed attempt can drive `.fullScreenCover(item:)`.
struct AttemptReview: Identifiable {
    let id: UUID
}

// MARK: - Score trend chart

struct ScoreTrendChart: View {
    let summaries: [MockExamSummary]

    private var points: [Double] { summaries.map(\.scorePercent) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Score trend")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                if let last = points.last {
                    Text("\(Int(last.rounded()))%")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.accent)
                        .monospacedDigit()
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    ForEach([0.0, 0.5, 1.0], id: \.self) { level in
                        Rectangle()
                            .fill(Palette.stroke)
                            .frame(height: 0.5)
                            .offset(y: -geo.size.height * level)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }

                    if points.count >= 2 {
                        Path { path in
                            for (index, value) in points.enumerated() {
                                let x = geo.size.width * Double(index) / Double(max(1, points.count - 1))
                                let y = geo.size.height * (1 - min(1, value / 100))
                                index == 0 ? path.move(to: CGPoint(x: x, y: y))
                                           : path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(Palette.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }

                    ForEach(Array(points.enumerated()), id: \.offset) { index, value in
                        Circle()
                            .fill(Palette.accent)
                            .frame(width: 6, height: 6)
                            .position(
                                x: points.count == 1
                                    ? geo.size.width / 2
                                    : geo.size.width * Double(index) / Double(max(1, points.count - 1)),
                                y: geo.size.height * (1 - min(1, value / 100))
                            )
                    }
                }
            }
            .frame(height: 72)

            HStack {
                Text("0%").font(.appCaption).foregroundStyle(Palette.textTertiary)
                Spacer()
                Text("100%").font(.appCaption).foregroundStyle(Palette.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mock exam score trend")
        .accessibilityValue(points.map { "\(Int($0.rounded())) percent" }.joined(separator: ", "))
    }
}
