//
//  MistakeNotebookView.swift
//  LCVI DECA Study App
//

import SwiftUI

struct MistakeNotebookView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var entries: [MistakeEntry] = []
    @State private var sort: MistakeSort = .recent
    @State private var clusterFilter: DECACluster?
    @State private var tagFilter: String?
    @State private var indicatorFilter: String?
    @State private var showMastered = false
    @State private var session: SessionPayload?
    @State private var expanded: Set<UUID> = []

    var body: some View {
        ScrollView {
            // Lazy: the notebook has no upper bound, and every entry is a card
            // carrying the question and its choices. An eager stack builds and
            // lays out all of them the moment the screen opens.
            LazyVStack(spacing: 12) {
                if entries.isEmpty && !hasAnyFilter {
                    EmptyStateView(systemImage: "book.closed",
                                   title: "No mistakes yet",
                                   message: "Mistakes you make during practice will appear here automatically, along with the correct answer and an explanation.")
                        .appCard()
                } else {
                    controls
                    if entries.isEmpty {
                        EmptyStateView(systemImage: "line.3.horizontal.decrease.circle",
                                       title: "Nothing matches",
                                       message: "Try clearing a filter to see more of your notebook.")
                            .appCard()
                    } else {
                        practiceButton
                        ForEach(entries) { entry in
                            MistakeCard(entry: entry,
                                        isExpanded: expanded.contains(entry.id)) {
                                Haptics.tap()
                                withAnimation(Motion.snappy) {
                                    if expanded.contains(entry.id) {
                                        expanded.remove(entry.id)
                                    } else {
                                        expanded.insert(entry.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 12)
        }
        .appCanvas()
        .navigationTitle("Mistake Notebook")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
        .fullScreenCover(item: $session) { payload in
            PracticeSessionView(payload: payload)
                .environmentObject(store)
                .onDisappear(perform: reload)
        }
    }

    private var hasAnyFilter: Bool {
        clusterFilter != nil || tagFilter != nil || indicatorFilter != nil || showMastered
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(MistakeSort.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    filterChip(title: sort.title, systemImage: "arrow.up.arrow.down", active: true)
                }

                Menu {
                    Button("All clusters") { clusterFilter = nil }
                    ForEach(DECACluster.allCases) { cluster in
                        Button(cluster.shortName) { clusterFilter = cluster }
                    }
                } label: {
                    filterChip(title: clusterFilter?.shortName ?? "Cluster",
                               systemImage: "square.grid.2x2",
                               active: clusterFilter != nil)
                }

                Menu {
                    Button("All topics") { tagFilter = nil }
                    ForEach(availableTags, id: \.self) { tag in
                        Button(tag) { tagFilter = tag }
                    }
                } label: {
                    filterChip(title: tagFilter ?? "Topic",
                               systemImage: "tag",
                               active: tagFilter != nil)
                }
            }

            HStack(spacing: 8) {
                Menu {
                    Button("All indicators") { indicatorFilter = nil }
                    ForEach(availableIndicators, id: \.self) { code in
                        Button(code) { indicatorFilter = code }
                    }
                } label: {
                    filterChip(title: indicatorFilter ?? "Indicator",
                               systemImage: "target",
                               active: indicatorFilter != nil)
                }

                Toggle("Show mastered", isOn: $showMastered)
                    .font(.appFootnote)
                    .tint(Palette.success)
                    .fixedSize()
                Spacer(minLength: 0)
            }
        }
        .onChange(of: sort) { _ in reload() }
        .onChange(of: clusterFilter) { _ in reload() }
        .onChange(of: tagFilter) { _ in reload() }
        .onChange(of: indicatorFilter) { _ in reload() }
        .onChange(of: showMastered) { _ in reload() }
    }

    private func filterChip(title: String, systemImage: String, active: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage).font(.system(size: 11, weight: .bold))
            Text(title).font(.appCaptionBold).lineLimit(1)
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(active ? Palette.accent : Palette.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Capsule().fill(active ? Palette.accentSoft : Palette.cardSunken))
    }

    private var practiceButton: some View {
        PrimaryButton(title: "Practise \(min(entries.filter { !$0.mastered }.count, 20)) missed question\(entries.filter { !$0.mastered }.count == 1 ? "" : "s")",
                      systemImage: "arrow.uturn.left",
                      tint: Palette.danger,
                      isEnabled: entries.contains { !$0.mastered }) {
            let ids = entries.filter { !$0.mastered }.map(\.question.id)
            let questions = store.bank.questions(for: Array(ids.prefix(20)))
            guard !questions.isEmpty else { return }
            let built = BuiltSession(mode: .mistakes,
                                     cluster: clusterFilter,
                                     questions: questions.shuffled(),
                                     composition: ["\(questions.count) from your Mistake Notebook"])
            session = SessionPayload(session: built, title: "Mistake Notebook")
        }
    }

    private var availableTags: [String] {
        Array(Set(entries.flatMap { $0.question.tags })).sorted()
    }

    private var availableIndicators: [String] {
        Array(Set(entries.flatMap { $0.question.performanceIndicators })).sorted()
    }

    private func reload() {
        entries = store.mistakes.entries(cluster: clusterFilter,
                                         tag: tagFilter,
                                         indicator: indicatorFilter,
                                         includeMastered: showMastered,
                                         sort: sort)
        store.refresh()
    }
}

// MARK: - Card

private struct MistakeCard: View {
    let entry: MistakeEntry
    let isExpanded: Bool
    let onToggle: () -> Void

    @EnvironmentObject private var store: AppStore
    @State private var isBookmarked = false

    private var question: QuestionData { entry.question }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                TagPill(text: question.cluster.shortName,
                        color: question.cluster.tint,
                        soft: question.cluster.tint.opacity(0.13))
                if entry.mastered {
                    TagPill(text: "Mastered", color: Palette.success,
                            soft: Palette.successSoft, icon: "checkmark")
                } else {
                    TagPill(text: "Missed ×\(entry.timesMissed)",
                            color: Palette.danger, soft: Palette.dangerSoft)
                }
                Spacer(minLength: 0)
                bookmarkButton
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse question" : "Expand question")
            }

            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(question.text)
                        .font(.appCallout.weight(.medium))
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isExpanded ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Text(relativeDate)
                            .font(.appCaption)
                            .foregroundStyle(Palette.textTertiary)
                        if !entry.mastered {
                            Text("\(MistakeNotebookService.masteryThreshold - entry.consecutiveCorrect) correct in a row to master")
                                .font(.appCaption)
                                .foregroundStyle(Palette.textTertiary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 9) {
                    Divider().overlay(Palette.stroke)

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
                            } else if index == entry.selectedIndex {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Palette.danger)
                            }
                        }
                    }

                    if !question.explanation.isEmpty {
                        Divider().overlay(Palette.stroke)
                        Text(question.explanation)
                            .font(.appFootnote)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !question.performanceIndicators.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(question.performanceIndicators, id: \.self) { code in
                                TagPill(text: code, color: Palette.gold, soft: Palette.goldSoft, icon: "target")
                            }
                            Spacer(minLength: 0)
                        }
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
        if index == entry.selectedIndex { return Palette.danger }
        return Palette.textSecondary
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Missed " + formatter.localizedString(for: entry.lastMissedAt, relativeTo: Date())
    }
}
