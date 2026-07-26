//
//  CustomPracticeView.swift
//  LCVI DECA Study App
//

import SwiftUI

struct CustomPracticeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var onStart: (SessionOptions) -> Void

    @State private var cluster: DECACluster = .marketing
    @State private var allClusters = false
    @State private var count = 10
    @State private var difficulties: Set<Difficulty> = Set(Difficulty.allCases)
    @State private var selectedTags: Set<String> = []
    @State private var includeMissed = true
    @State private var includeNew = true
    @State private var includeDue = true
    @State private var availableTags: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.sectionSpacing) {
                section("Cluster") {
                    VStack(spacing: 10) {
                        Toggle("All clusters", isOn: $allClusters)
                            .font(.appCallout)
                            .tint(Palette.accent)
                        if !allClusters {
                            AppMenuPicker("Cluster", selection: $cluster,
                                          options: DECACluster.allCases) { $0.shortName }
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                section("Number of questions") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach([5, 10, 20, 30], id: \.self) { value in
                                chip(title: "\(value)", selected: count == value) { count = value }
                            }
                        }
                        AppStepper(value: $count, in: 1...100) {
                            Text("\(count) questions")
                                .font(.appCallout.weight(.medium))
                                .foregroundStyle(Palette.textPrimary)
                                .monospacedDigit()
                        }
                    }
                }

                section("Difficulty") {
                    HStack(spacing: 8) {
                        ForEach(Difficulty.allCases) { level in
                            chip(title: level.title,
                                 selected: difficulties.contains(level),
                                 tint: level.color) {
                                if difficulties.contains(level) {
                                    if difficulties.count > 1 { difficulties.remove(level) }
                                } else {
                                    difficulties.insert(level)
                                }
                            }
                        }
                    }
                }

                if !availableTags.isEmpty {
                    section("Tags") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tagRows(), id: \.self) { row in
                                HStack(spacing: 8) {
                                    ForEach(row, id: \.self) { tag in
                                        chip(title: tag,
                                             selected: selectedTags.contains(tag),
                                             tint: Palette.gold) {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                            if !selectedTags.isEmpty {
                                Button("Clear tags") {
                                    Haptics.tap()
                                    selectedTags.removeAll()
                                }
                                .font(.appCaption)
                                .foregroundStyle(Palette.accent)
                            }
                        }
                    }
                }

                section("Include") {
                    VStack(spacing: 4) {
                        Toggle("Questions I've missed", isOn: $includeMissed)
                        Divider().overlay(Palette.stroke)
                        Toggle("New questions", isOn: $includeNew)
                        Divider().overlay(Palette.stroke)
                        Toggle("Due review questions", isOn: $includeDue)
                    }
                    .font(.appCallout)
                    .tint(Palette.accent)
                }

                PrimaryButton(title: "Start practice", systemImage: "play.fill") {
                    var options = SessionOptions(mode: .custom,
                                                 cluster: allClusters ? nil : cluster,
                                                 count: count)
                    options.difficulties = difficulties
                    options.tags = selectedTags
                    options.includeMissed = includeMissed
                    options.includeNew = includeNew
                    options.includeDue = includeDue
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onStart(options) }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 14)
        }
        .appCanvas()
        .navigationTitle("Custom Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cluster = store.settings.cluster
            availableTags = store.bank.allTags()
        }
        .onChange(of: allClusters) { _ in refreshTags() }
        .onChange(of: cluster) { _ in refreshTags() }
    }

    private func refreshTags() {
        availableTags = store.bank.allTags(cluster: allClusters ? nil : cluster)
        selectedTags = selectedTags.filter { availableTags.contains($0) }
    }

    private func tagRows() -> [[String]] {
        stride(from: 0, to: availableTags.count, by: 2).map {
            Array(availableTags[$0..<min($0 + 2, availableTags.count)])
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            content().appCard()
        }
    }

    private func chip(title: String,
                      selected: Bool,
                      tint: Color = Palette.accent,
                      action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(Motion.quick) { action() }
        } label: {
            Text(title)
                .font(.appFootnote.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(selected ? .white : Palette.textPrimary)
                .padding(.horizontal, 13)
                .frame(minHeight: 38)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? tint : Palette.cardSunken)
                )
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Exam Cram setup

struct ExamCramSetupView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var onStart: (SessionPayload) -> Void

    @State private var minutes = 10
    @State private var useTimer = true
    @State private var customCount = 15

    private let presets = [5, 10, 20]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.sectionSpacing) {
                    InfoBanner(systemImage: "bolt.fill",
                               title: "Exam Cram prioritises your weak spots",
                               message: "Missed questions, overdue reviews and low-mastery indicators come first, with short explanations so you keep moving.",
                               tint: Palette.gold)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Session length")
                        VStack(spacing: 12) {
                            Toggle("Timed session", isOn: $useTimer)
                                .font(.appCallout)
                                .tint(Palette.accent)

                            if useTimer {
                                HStack(spacing: 8) {
                                    ForEach(presets, id: \.self) { value in
                                        Button {
                                            Haptics.select()
                                            withAnimation(Motion.quick) { minutes = value }
                                        } label: {
                                            VStack(spacing: 1) {
                                                Text("\(value)").font(.numeric(20))
                                                Text("min").font(.appCaption)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .foregroundStyle(minutes == value ? .white : Palette.textPrimary)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(minutes == value ? Palette.gold : Palette.cardSunken)
                                            )
                                        }
                                        .buttonStyle(PressableButtonStyle(haptic: false))
                                        .accessibilityLabel("\(value) minute session")
                                    }
                                }
                            } else {
                                AppStepper(value: $customCount, in: 5...60, step: 5) {
                                    Text("\(customCount) questions")
                                        .font(.appCallout.weight(.medium))
                                        .foregroundStyle(Palette.textPrimary)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .appCard()
                    }

                    PrimaryButton(title: "Start Exam Cram",
                                  systemImage: "bolt.fill",
                                  tint: Palette.gold) {
                        start()
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.vertical, 14)
            }
            .appCanvas()
            .navigationTitle("Exam Cram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func start() {
        // Roughly 30 seconds per question in a timed cram.
        let count = useTimer ? max(5, minutes * 2) : customCount
        let options = SessionOptions(mode: .examCram, cluster: store.settings.cluster, count: count)
        let built = store.sessions.build(options)
        guard !built.questions.isEmpty else { return }
        onStart(SessionPayload(session: built,
                               timeLimitSeconds: useTimer ? Double(minutes * 60) : nil,
                               title: "Exam Cram"))
    }
}
