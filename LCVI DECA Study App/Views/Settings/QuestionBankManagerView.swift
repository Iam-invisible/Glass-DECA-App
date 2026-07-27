//
//  QuestionBankManagerView.swift
//  LCVI DECA Study App
//
//  Manual entry, bulk paste, CSV/JSON import, editing, deletion and export.
//

import SwiftUI
import UniformTypeIdentifiers

struct QuestionBankManagerView: View {
    @EnvironmentObject private var store: AppStore

    @State private var questions: [QuestionData] = []
    @State private var searchText = ""
    @State private var clusterFilter: DECACluster?
    @State private var showBookmarkedOnly = false
    @State private var editing: QuestionData?
    @State private var creatingNew = false
    @State private var showingBulk = false
    @State private var showingFileImporter = false
    @State private var importReport: ImportReport?
    @State private var showingReport = false
    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var pendingDelete: QuestionData?
    @State private var message: String?
    @State private var showingMessage = false

    private var filtered: [QuestionData] {
        questions.filter { question in
            if let clusterFilter, question.cluster != clusterFilter { return false }
            if showBookmarkedOnly && !question.isBookmarked { return false }
            guard !searchText.isEmpty else { return true }
            let needle = searchText.lowercased()
            return question.text.lowercased().contains(needle)
                || question.tags.contains { $0.lowercased().contains(needle) }
                || question.performanceIndicators.contains { $0.lowercased().contains(needle) }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                toolbarCard

                if questions.isEmpty {
                    EmptyStateView(systemImage: "tray",
                                   title: "No questions yet",
                                   message: "Add or import a question bank to start practising.",
                                   actionTitle: "Add a question") { creatingNew = true }
                        .appCard()
                } else if filtered.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass",
                                   title: "Nothing matches",
                                   message: "Try a different search or clear the cluster filter.")
                        .appCard()
                } else {
                    ForEach(filtered) { question in
                        QuestionRow(question: question,
                                    onEdit: { editing = question },
                                    onBookmark: { toggleBookmark(question) },
                                    onDelete: { pendingDelete = question })
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 12)
        }
        .appCanvas()
        .navigationTitle("Question Bank")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search questions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { creatingNew = true } label: { Label("Add question", systemImage: "plus") }
                    Button { showingBulk = true } label: { Label("Bulk paste", systemImage: "doc.on.clipboard") }
                    Button { showingFileImporter = true } label: { Label("Import CSV or JSON", systemImage: "square.and.arrow.down") }
                    Divider()
                    Button { exportJSON() } label: { Label("Export as JSON", systemImage: "square.and.arrow.up") }
                    Button { exportCSV() } label: { Label("Export as CSV", systemImage: "tablecells") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Question bank actions")
            }
        }
        .onAppear(perform: reload)
        .sheet(isPresented: $creatingNew) {
            NavigationStack {
                QuestionEditorView(question: nil) { saved in
                    store.bank.add(saved)
                    reload()
                }
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { question in
            NavigationStack {
                QuestionEditorView(question: question) { saved in
                    store.bank.update(saved)
                    reload()
                }
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingBulk) {
            NavigationStack {
                BulkImportView { report in
                    importReport = report
                    showingBulk = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showingReport = true }
                }
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingReport) {
            if let importReport {
                NavigationStack {
                    ImportReportView(report: importReport) { committed in
                        showingReport = false
                        reload()
                        message = "Imported \(committed) question\(committed == 1 ? "" : "s")."
                        showingMessage = true
                    }
                }
                .environmentObject(store)
            }
        }
        .sheet(isPresented: $showingShare) {
            if let exportURL { ShareSheet(items: [exportURL]) }
        }
        .fileImporter(isPresented: $showingFileImporter,
                      allowedContentTypes: [.json, .commaSeparatedText, .plainText],
                      allowsMultipleSelection: false) { result in
            handleFileImport(result)
        }
        .alert("Question bank", isPresented: $showingMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(message ?? "")
        }
        .confirmationDialog("Delete this question?",
                            isPresented: Binding(get: { pendingDelete != nil },
                                                 set: { if !$0 { pendingDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let pendingDelete {
                    store.bank.delete(id: pendingDelete.id)
                    Haptics.warning()
                    reload()
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Its review history and any mistake record are removed too. This can't be undone.")
        }
    }

    // MARK: Toolbar card

    private var toolbarCard: some View {
        VStack(spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(questions.count) question\(questions.count == 1 ? "" : "s")")
                        .font(.appBodyMedium)
                        .foregroundStyle(Palette.textPrimary)
                    Text("\(filtered.count) shown")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Menu {
                    Button("All clusters") { clusterFilter = nil }
                    ForEach(DECACluster.allCases) { cluster in
                        Button(cluster.shortName) { clusterFilter = cluster }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(clusterFilter?.shortName ?? "Filter")
                    }
                    .font(.appCaptionBold)
                    .foregroundStyle(clusterFilter == nil ? Palette.textSecondary : Palette.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(Capsule().fill(clusterFilter == nil ? Palette.cardSunken : Palette.accentSoft))
                }
            }

            HStack(spacing: 9) {
                SecondaryButton(title: "Add", systemImage: "plus") { creatingNew = true }
                SecondaryButton(title: "Bulk paste", systemImage: "doc.on.clipboard") { showingBulk = true }
            }

            Button {
                Haptics.select()
                withAnimation(Motion.quick) { showBookmarkedOnly.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showBookmarkedOnly ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Bookmarked only")
                        .font(.appFootnote.weight(.semibold))
                    Spacer()
                    Text("\(questions.filter(\.isBookmarked).count)")
                        .font(.appCaptionBold)
                        .monospacedDigit()
                }
                .foregroundStyle(showBookmarkedOnly ? Palette.gold : Palette.textSecondary)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(showBookmarkedOnly ? Palette.goldSoft : Palette.cardSunken)
                )
            }
            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
            .accessibilityAddTraits(showBookmarkedOnly ? [.isSelected, .isButton] : .isButton)
        }
        .appCard()
    }

    // MARK: Actions

    private func reload() {
        questions = store.bank.allQuestions()
        store.refresh()
    }

    private func toggleBookmark(_ question: QuestionData) {
        guard let bookmarked = store.bank.toggleBookmark(questionID: question.id) else { return }
        Haptics.select()
        if let index = questions.firstIndex(where: { $0.id == question.id }) {
            withAnimation(Motion.quick) { questions[index].isBookmarked = bookmarked }
        }
        store.refresh()
    }

    private func exportJSON() {
        var bundle = store.importExport.makeExport(includeProgress: false,
                                                   includeSettings: false,
                                                   settings: store.settings,
                                                   streak: store.streakStore.state)
        bundle.progress = nil
        guard let url = store.importExport.writeExportFile(bundle) else { return }
        exportURL = url
        showingShare = true
    }

    private func exportCSV() {
        guard let url = store.importExport.writeCSVFile() else { return }
        exportURL = url
        showingShare = true
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            guard let data = try? Data(contentsOf: url) else {
                message = "That file couldn't be read."
                showingMessage = true
                return
            }

            let report: ImportReport
            if url.pathExtension.lowercased() == "json" {
                report = store.importExport.parseJSON(data, defaultCluster: store.settings.cluster)
            } else if let text = String(data: data, encoding: .utf8) {
                report = url.pathExtension.lowercased() == "csv"
                    ? store.importExport.parseCSV(text, defaultCluster: store.settings.cluster)
                    : store.importExport.parseBulkText(text, defaultCluster: store.settings.cluster)
            } else {
                message = "That file isn't readable text."
                showingMessage = true
                return
            }

            importReport = report
            showingReport = true

        case .failure(let error):
            message = error.localizedDescription
            showingMessage = true
        }
    }
}

// MARK: - Row

private struct QuestionRow: View {
    let question: QuestionData
    let onEdit: () -> Void
    let onBookmark: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Button(action: onBookmark) {
                    Image(systemName: question.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(question.isBookmarked ? Palette.gold : Palette.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(question.isBookmarked ? Palette.goldSoft : Palette.cardSunken))
                }
                .buttonStyle(PressableButtonStyle(scale: 0.94, haptic: false))
                .accessibilityLabel(question.isBookmarked ? "Remove bookmark" : "Bookmark question")

                TagPill(text: question.cluster.shortName,
                        color: question.cluster.tint,
                        soft: question.cluster.tint.opacity(0.13))
                TagPill(text: question.difficulty.title,
                        color: question.difficulty.color,
                        soft: question.difficulty.color.opacity(0.13))
                if question.isSample {
                    TagPill(text: "Sample", color: Palette.textSecondary, soft: Palette.cardSunken)
                }
                Spacer(minLength: 0)
                Menu {
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.textTertiary)
                        .frame(width: 30, height: 30)
                }
                .accessibilityLabel("Question actions")
            }

            Text(question.text)
                .font(.appCallout.weight(.medium))
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text("Correct: \(question.correctLetter)")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.success)
                if !question.tags.isEmpty {
                    Text("· \(question.tags.joined(separator: ", "))")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Editor

struct QuestionEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let existing: QuestionData?
    let onSave: (QuestionData) -> Void

    @State private var text = ""
    @State private var choices = ["", "", "", ""]
    @State private var correctIndex = 0
    @State private var explanation = ""
    @State private var cluster: DECACluster = .marketing
    @State private var examType = ""
    @State private var difficulty: Difficulty = .medium
    @State private var tagsText = ""
    @State private var indicatorsText = ""
    @State private var duplicateWarning: String?

    init(question: QuestionData?, onSave: @escaping (QuestionData) -> Void) {
        self.existing = question
        self.onSave = onSave
    }

    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && choices.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.sectionSpacing) {
                field(title: "Question text") {
                    TextEditor(text: $text)
                        .font(.appCallout)
                        .frame(minHeight: 110)
                        .scrollContentBackground(.hidden)
                        .background(Palette.cardSunken)
                        .cornerRadius(10)
                        .accessibilityLabel("Question text")
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Answer choices",
                                  subtitle: "Tap a letter to mark the correct answer.")
                    VStack(spacing: 9) {
                        ForEach(0..<4, id: \.self) { index in
                            HStack(spacing: 10) {
                                Button {
                                    Haptics.select()
                                    withAnimation(Motion.quick) { correctIndex = index }
                                } label: {
                                    Text(AnswerLetter(rawValue: index)?.label ?? "")
                                        .font(.appSans(14, weight: .bold))
                                        .foregroundStyle(correctIndex == index ? .white : Palette.textSecondary)
                                        .frame(width: 34, height: 34)
                                        .background(Circle().fill(correctIndex == index
                                                                  ? Palette.success : Palette.cardSunken))
                                }
                                .buttonStyle(PressableButtonStyle(haptic: false))
                                .accessibilityLabel("Mark option \(AnswerLetter(rawValue: index)?.label ?? "") correct")
                                .accessibilityAddTraits(correctIndex == index ? [.isSelected, .isButton] : .isButton)

                                TextField("Answer \(AnswerLetter(rawValue: index)?.label ?? "")",
                                          text: $choices[index], axis: .vertical)
                                    .font(.appCallout)
                                    .padding(10)
                                    .background(Palette.cardSunken)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .appCard()
                }

                field(title: "Explanation (optional)") {
                    TextEditor(text: $explanation)
                        .font(.appCallout)
                        .frame(minHeight: 90)
                        .scrollContentBackground(.hidden)
                        .background(Palette.cardSunken)
                        .cornerRadius(10)
                        .accessibilityLabel("Explanation")
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Classification")
                    VStack(spacing: 13) {
                        HStack {
                            Text("Cluster").font(.appCallout).foregroundStyle(Palette.textPrimary)
                            Spacer()
                            AppMenuPicker("Cluster", selection: $cluster,
                                          options: DECACluster.allCases) { $0.shortName }
                        }
                        Divider().overlay(Palette.stroke)
                        HStack {
                            Text("Difficulty").font(.appCallout).foregroundStyle(Palette.textPrimary)
                            Spacer()
                            AppSegmentedPicker("Difficulty", selection: $difficulty,
                                               options: Difficulty.allCases) { $0.title }
                                .frame(width: 200)
                        }
                        Divider().overlay(Palette.stroke)
                        TextField("Exam type (optional)", text: $examType)
                            .font(.appCallout)
                        Divider().overlay(Palette.stroke)
                        TextField("Tags, comma separated", text: $tagsText)
                            .font(.appCallout)
                            .autocorrectionDisabled()
                        Divider().overlay(Palette.stroke)
                        TextField("Performance indicators, comma separated", text: $indicatorsText)
                            .font(.appCallout)
                            .autocorrectionDisabled()
                    }
                    .appCard()
                }

                if let duplicateWarning {
                    InfoBanner(systemImage: "exclamationmark.triangle.fill",
                               title: "Possible duplicate",
                               message: duplicateWarning,
                               tint: Palette.gold)
                }

                PrimaryButton(title: existing == nil ? "Add question" : "Save changes",
                              systemImage: "checkmark",
                              isEnabled: isValid) {
                    save()
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 14)
        }
        .appCanvas()
        .navigationTitle(existing == nil ? "New question" : "Edit question")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear(perform: load)
        .onChange(of: text) { _ in checkDuplicate() }
    }

    @ViewBuilder
    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            content().appCard()
        }
    }

    private func load() {
        guard let existing else {
            cluster = store.settings.cluster
            return
        }
        text = existing.text
        choices = existing.choices.count == 4 ? existing.choices : ["", "", "", ""]
        correctIndex = existing.correctIndex
        explanation = existing.explanation
        cluster = existing.cluster
        examType = existing.examType
        difficulty = existing.difficulty
        tagsText = existing.tags.joined(separator: ", ")
        indicatorsText = existing.performanceIndicators.joined(separator: ", ")
    }

    private func checkDuplicate() {
        guard text.count > 12 else { duplicateWarning = nil; return }
        let candidate = build()
        if let dupe = store.bank.duplicate(of: candidate, excluding: existing?.id) {
            duplicateWarning = "A question with almost identical wording already exists: “\(String(dupe.text.prefix(70)))…”"
        } else {
            duplicateWarning = nil
        }
    }

    private func build() -> QuestionData {
        QuestionData(
            id: existing?.id ?? UUID(),
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            choices: choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            correctIndex: correctIndex,
            explanation: explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            cluster: cluster,
            examType: examType.isEmpty ? cluster.examName : examType,
            difficulty: difficulty,
            tags: splitList(tagsText),
            performanceIndicators: splitList(indicatorsText),
            isSample: existing?.isSample ?? false,
            isBookmarked: existing?.isBookmarked ?? false
        )
    }

    private func splitList(_ raw: String) -> [String] {
        raw.components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func save() {
        Haptics.success()
        onSave(build())
        dismiss()
    }
}
