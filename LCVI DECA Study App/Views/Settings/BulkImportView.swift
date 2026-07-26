//
//  BulkImportView.swift
//  LCVI DECA Study App
//
//  Paste-in question format with validation and duplicate detection.
//

import SwiftUI

struct BulkImportView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var onParsed: (ImportReport) -> Void

    @State private var text = ""
    @State private var defaultCluster: DECACluster = .marketing
    @FocusState private var focused: Bool

    private static let sample = """
    Which pricing strategy sets a high introductory price for early adopters?
    A) Penetration pricing
    B) Price skimming
    C) Loss-leader pricing
    D) Cost-plus pricing
    Correct: B
    Explanation: Skimming captures revenue from customers who are least price-sensitive, then lowers price over time.
    Cluster: Marketing
    Performance Indicator: MK:002
    Tags: pricing, strategy
    """

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Format",
                                  subtitle: "One question per block, separated by a blank line or ---")
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Self.sample)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider().overlay(Palette.stroke)
                        Text("Explanation, Cluster, Performance Indicator, Tags, Difficulty and Exam are all optional. Anything missing falls back to the default cluster below.")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Default cluster",
                                  subtitle: "Used when a block has no Cluster line")
                    HStack {
                        Text("Cluster").font(.appCallout).foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Picker("Cluster", selection: $defaultCluster) {
                            ForEach(DECACluster.allCases) { item in
                                Text(item.shortName).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Palette.accent)
                    }
                    .appCard()
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Paste your questions")
                    TextEditor(text: $text)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(minHeight: 260)
                        .scrollContentBackground(.hidden)
                        .background(Palette.cardSunken)
                        .cornerRadius(10)
                        .focused($focused)
                        .accessibilityLabel("Bulk question text")
                        .appCard()
                }

                HStack(spacing: 9) {
                    SecondaryButton(title: "Insert example", systemImage: "text.badge.plus") {
                        text = text.isEmpty ? Self.sample : text + "\n\n" + Self.sample
                    }
                    SecondaryButton(title: "Clear", systemImage: "trash") {
                        text = ""
                    }
                }

                PrimaryButton(title: "Validate and preview",
                              systemImage: "checkmark.circle",
                              isEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    focused = false
                    let report = store.importExport.parseBulkText(text, defaultCluster: defaultCluster)
                    Haptics.tap()
                    onParsed(report)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 14)
        }
        .appCanvas()
        .navigationTitle("Bulk paste")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
            }
        }
        .onAppear { defaultCluster = store.settings.cluster }
    }
}

// MARK: - Report

struct ImportReportView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let report: ImportReport
    var onCommit: (Int) -> Void

    @State private var includeDuplicates = false

    private var willImport: Int {
        includeDuplicates
            ? report.candidates.filter { $0.question != nil && $0.errors.isEmpty }.count
            : report.importable.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.sectionSpacing) {
                summaryCard

                if !report.invalid.isEmpty {
                    issueSection(title: "Can't be imported",
                                 tint: Palette.danger,
                                 candidates: report.invalid)
                }

                if !report.duplicates.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Possible duplicates",
                                      subtitle: "Already in your bank with near-identical wording")
                        Toggle("Import duplicates anyway", isOn: $includeDuplicates)
                            .font(.appCallout)
                            .tint(Palette.gold)
                            .appCard(padding: 13)
                        ForEach(report.duplicates) { candidate in
                            candidateRow(candidate, tint: Palette.gold)
                        }
                    }
                }

                if !report.importable.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Ready to import",
                                      subtitle: "\(report.importable.count) question\(report.importable.count == 1 ? "" : "s")")
                        ForEach(report.importable.prefix(20)) { candidate in
                            candidateRow(candidate, tint: Palette.success)
                        }
                        if report.importable.count > 20 {
                            Text("and \(report.importable.count - 20) more")
                                .font(.appCaption)
                                .foregroundStyle(Palette.textTertiary)
                        }
                    }
                }

                PrimaryButton(title: willImport == 0
                                ? "Nothing to import"
                                : "Import \(willImport) question\(willImport == 1 ? "" : "s")",
                              systemImage: "square.and.arrow.down",
                              isEnabled: willImport > 0) {
                    let count = store.importExport.commit(report.candidates,
                                                          includeDuplicates: includeDuplicates)
                    Haptics.success()
                    onCommit(count)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 14)
        }
        .appCanvas()
        .navigationTitle("Import preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 10) {
            StatCard(title: "Valid", value: "\(report.importable.count)",
                     systemImage: "checkmark", tint: Palette.success)
            StatCard(title: "Duplicates", value: "\(report.duplicates.count)",
                     systemImage: "doc.on.doc", tint: Palette.gold)
            StatCard(title: "Errors", value: "\(report.invalid.count)",
                     systemImage: "exclamationmark.triangle", tint: Palette.danger)
        }
    }

    private func issueSection(title: String, tint: Color, candidates: [ImportCandidate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, subtitle: "\(candidates.count) block\(candidates.count == 1 ? "" : "s")")
            ForEach(candidates) { candidate in
                VStack(alignment: .leading, spacing: 6) {
                    Text(candidate.sourceLabel.isEmpty ? "Unnamed block" : candidate.sourceLabel)
                        .font(.appFootnote.weight(.medium))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(2)
                    ForEach(candidate.errors, id: \.self) { error in
                        Label(error, systemImage: "xmark.circle.fill")
                            .font(.appCaption)
                            .foregroundStyle(tint)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard(padding: 13)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func candidateRow(_ candidate: ImportCandidate, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if let question = candidate.question {
                HStack(spacing: 6) {
                    TagPill(text: question.cluster.shortName,
                            color: question.cluster.tint,
                            soft: question.cluster.tint.opacity(0.13))
                    TagPill(text: "Correct: \(question.correctLetter)",
                            color: tint, soft: tint.opacity(0.13))
                    Spacer(minLength: 0)
                }
                Text(question.text)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if let dupe = candidate.duplicateOf {
                    Text("Matches: “\(String(dupe.text.prefix(60)))…”")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 13)
        .accessibilityElement(children: .combine)
    }
}
