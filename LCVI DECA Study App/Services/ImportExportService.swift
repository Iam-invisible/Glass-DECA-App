//
//  ImportExportService.swift
//  LCVI DECA Study App
//
//  Local-only import and backup. Bulk text, CSV and JSON are all parsed
//  on-device; nothing is uploaded anywhere.
//

import CoreData
import Foundation
import UniformTypeIdentifiers

// MARK: - Import results

struct ImportCandidate: Identifiable {
    let id = UUID()
    var question: QuestionData?
    var errors: [String] = []
    var duplicateOf: QuestionData? = nil
    var sourceLabel: String = ""

    var isImportable: Bool { question != nil && errors.isEmpty }
    var isDuplicate: Bool { duplicateOf != nil }
}

struct ImportReport {
    var candidates: [ImportCandidate] = []

    var importable: [ImportCandidate] { candidates.filter { $0.isImportable && !$0.isDuplicate } }
    var duplicates: [ImportCandidate] { candidates.filter { $0.isDuplicate } }
    var invalid: [ImportCandidate] { candidates.filter { !$0.isImportable } }
    var isEmpty: Bool { candidates.isEmpty }
}

// MARK: - Export bundle

struct ExportBundle: Codable {
    var formatVersion: Int = 1
    var exportedAt: Date = Date()
    var appVersion: String = "1.0"

    var questions: [QuestionData] = []
    var roleplays: [RoleplayPromptData] = []
    var progress: ProgressExport? = nil
    var settings: SettingsExport? = nil

    struct ProgressExport: Codable {
        struct SRExport: Codable {
            var questionID: UUID
            var timesAnswered: Int
            var timesCorrect: Int
            var timesIncorrect: Int
            var consecutiveCorrect: Int
            var lastAnsweredAt: Date?
            var nextReviewAt: Date?
            var intervalDays: Double
            var ease: Double
            var masteryLevel: Int
        }
        struct MistakeExport: Codable {
            var questionID: UUID
            var selectedIndex: Int
            var timesMissed: Int
            var consecutiveCorrect: Int
            var mastered: Bool
            var firstMissedAt: Date?
            var lastMissedAt: Date?
            var cluster: String?
        }
        struct DayExport: Codable {
            var dayKey: String
            var questionsAnswered: Int
            var correctCount: Int
            var goal: Int
            var goalMet: Bool
            var secondsStudied: Double
        }
        struct IndicatorExport: Codable {
            var code: String
            var cluster: String
            var timesAnswered: Int
            var timesCorrect: Int
            var roleplayCount: Int
            var masteryScore: Double
        }
        struct MockExport: Codable {
            var id: UUID
            var date: Date
            var cluster: String
            var questionCount: Int
            var correctCount: Int
            var durationSeconds: Double
        }

        var spacedRepetition: [SRExport] = []
        var mistakes: [MistakeExport] = []
        var days: [DayExport] = []
        var indicators: [IndicatorExport] = []
        var mockExams: [MockExport] = []
        var achievements: [String] = []
        var streak: StreakState = StreakState()
    }

    struct SettingsExport: Codable {
        var cluster: String
        var dailyGoal: Int
        var remindersEnabled: Bool
        var reminderHour: Int
        var reminderMinute: Int
        var reminderStyle: String
        var appearance: String
        var hapticsEnabled: Bool
    }
}

// MARK: - Service

@MainActor
final class ImportExportService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames
    private let bank: QuestionBankService

    init(context: NSManagedObjectContext, bank: QuestionBankService) {
        self.ctx = context
        self.bank = bank
    }

    // MARK: - Bulk text format

    /// Parses the app's simple paste format. Blocks are separated by a blank
    /// line or a line of dashes.
    func parseBulkText(_ text: String, defaultCluster: DECACluster) -> ImportReport {
        var report = ImportReport()
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized
            .components(separatedBy: "\n---")
            .flatMap { $0.components(separatedBy: "\n\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for block in blocks {
            report.candidates.append(parseBlock(block, defaultCluster: defaultCluster))
        }
        return report
    }

    private func parseBlock(_ block: String, defaultCluster: DECACluster) -> ImportCandidate {
        var candidate = ImportCandidate()
        candidate.sourceLabel = String(block.prefix(60)).replacingOccurrences(of: "\n", with: " ")

        var questionLines: [String] = []
        var choices: [Int: String] = [:]
        var correctRaw: String?
        var explanation = ""
        var clusterRaw: String?
        var examType: String?
        var difficultyRaw: String?
        var tags: [String] = []
        var indicators: [String] = []

        func value(_ line: String, after prefix: String) -> String {
            String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }

        for rawLine in block.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            let lower = line.lowercased()

            // Answer lines: "A) text", "A. text", "A: text"
            if line.count > 2, let first = line.first,
               "ABCDabcd".contains(first),
               [") ", ". ", ": ", ")", ".", ":"].contains(where: { line.dropFirst().hasPrefix($0) }) {
                let letter = AnswerLetter.from(String(first))
                let body = line.dropFirst()
                    .drop(while: { ").:".contains($0) })
                    .trimmingCharacters(in: .whitespaces)
                if let letter, !body.isEmpty, choices[letter.rawValue] == nil {
                    choices[letter.rawValue] = body
                    continue
                }
            }

            if lower.hasPrefix("correct:")      { correctRaw = value(line, after: "correct:"); continue }
            if lower.hasPrefix("answer:")       { correctRaw = value(line, after: "answer:"); continue }
            if lower.hasPrefix("explanation:")  { explanation = value(line, after: "explanation:"); continue }
            if lower.hasPrefix("cluster:")      { clusterRaw = value(line, after: "cluster:"); continue }
            if lower.hasPrefix("exam:")         { examType = value(line, after: "exam:"); continue }
            if lower.hasPrefix("exam type:")    { examType = value(line, after: "exam type:"); continue }
            if lower.hasPrefix("difficulty:")   { difficultyRaw = value(line, after: "difficulty:"); continue }
            if lower.hasPrefix("tags:") {
                tags = value(line, after: "tags:").components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                continue
            }
            if lower.hasPrefix("performance indicator:") || lower.hasPrefix("performance indicators:") {
                let prefix = lower.hasPrefix("performance indicators:") ? "performance indicators:" : "performance indicator:"
                indicators = value(line, after: prefix).components(separatedBy: ";")
                    .flatMap { $0.components(separatedBy: ",") }
                    .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                continue
            }
            if lower.hasPrefix("pi:") {
                indicators = value(line, after: "pi:").components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                continue
            }

            questionLines.append(line)
        }

        let questionText = questionLines.joined(separator: " ").trimmingCharacters(in: .whitespaces)

        // Validation
        if questionText.isEmpty { candidate.errors.append("Missing question text") }
        let orderedChoices = (0..<4).map { choices[$0] ?? "" }
        if orderedChoices.contains(where: { $0.isEmpty }) {
            candidate.errors.append("Needs four answer choices (A–D)")
        }
        guard let correctRaw, let letter = AnswerLetter.from(correctRaw) else {
            candidate.errors.append("Missing or unreadable \"Correct:\" line")
            return candidate
        }
        let cluster = DECACluster.from(clusterRaw) ?? defaultCluster
        if clusterRaw != nil && DECACluster.from(clusterRaw) == nil {
            candidate.errors.append("Unknown cluster \"\(clusterRaw ?? "")\"")
        }

        guard candidate.errors.isEmpty else { return candidate }

        let question = QuestionData(
            id: UUID(),
            text: questionText,
            choices: orderedChoices,
            correctIndex: letter.rawValue,
            explanation: explanation,
            cluster: cluster,
            examType: examType ?? cluster.examName,
            difficulty: Difficulty.from(difficultyRaw),
            tags: tags,
            performanceIndicators: indicators,
            isSample: false
        )
        candidate.question = question
        candidate.duplicateOf = bank.duplicate(of: question)
        return candidate
    }

    // MARK: - CSV

    /// Expects a header row. Recognised columns: question, a, b, c, d, correct,
    /// explanation, cluster, difficulty, tags, indicators, bookmarked.
    func parseCSV(_ text: String, defaultCluster: DECACluster) -> ImportReport {
        var report = ImportReport()
        let rows = CSVParser.parse(text)
        guard let header = rows.first, rows.count > 1 else {
            var candidate = ImportCandidate()
            candidate.errors = ["The file needs a header row and at least one question row."]
            report.candidates = [candidate]
            return report
        }

        let keys = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        func index(_ options: [String]) -> Int? {
            for option in options {
                if let i = keys.firstIndex(of: option) { return i }
            }
            return nil
        }

        let qIdx = index(["question", "question text", "text", "prompt"])
        let aIdx = index(["a", "answer a", "choice a", "option a"])
        let bIdx = index(["b", "answer b", "choice b", "option b"])
        let cIdx = index(["c", "answer c", "choice c", "option c"])
        let dIdx = index(["d", "answer d", "choice d", "option d"])
        let correctIdx = index(["correct", "correct answer", "answer", "key"])
        let expIdx = index(["explanation", "rationale"])
        let clusterIdx = index(["cluster", "event", "exam"])
        let diffIdx = index(["difficulty", "level"])
        let tagsIdx = index(["tags", "topic", "topics"])
        let piIdx = index(["indicators", "performance indicator", "performance indicators", "pi"])
        let bookmarkIdx = index(["bookmarked", "bookmark", "saved"])

        for (rowNumber, row) in rows.dropFirst().enumerated() {
            guard row.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { continue }
            var candidate = ImportCandidate()
            candidate.sourceLabel = "Row \(rowNumber + 2)"

            func field(_ index: Int?) -> String {
                guard let index, row.indices.contains(index) else { return "" }
                return row[index].trimmingCharacters(in: .whitespaces)
            }

            let text = field(qIdx)
            let choices = [field(aIdx), field(bIdx), field(cIdx), field(dIdx)]
            if text.isEmpty { candidate.errors.append("Missing question text") }
            if choices.contains(where: { $0.isEmpty }) { candidate.errors.append("Needs four answer choices") }
            guard let letter = AnswerLetter.from(field(correctIdx)) else {
                candidate.errors.append("Missing or unreadable correct answer")
                report.candidates.append(candidate)
                continue
            }
            let cluster = DECACluster.from(field(clusterIdx)) ?? defaultCluster

            guard candidate.errors.isEmpty else {
                report.candidates.append(candidate)
                continue
            }

            let question = QuestionData(
                id: UUID(),
                text: text,
                choices: choices,
                correctIndex: letter.rawValue,
                explanation: field(expIdx),
                cluster: cluster,
                examType: cluster.examName,
                difficulty: Difficulty.from(field(diffIdx)),
                tags: splitList(field(tagsIdx)),
                performanceIndicators: splitList(field(piIdx)),
                isSample: false,
                isBookmarked: Self.truthy(field(bookmarkIdx))
            )
            candidate.question = question
            candidate.duplicateOf = bank.duplicate(of: question)
            report.candidates.append(candidate)
        }
        return report
    }

    private func splitList(_ raw: String) -> [String] {
        raw.components(separatedBy: CharacterSet(charactersIn: ",;|"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func truthy(_ raw: String) -> Bool {
        let value = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return ["1", "true", "yes", "y", "saved", "bookmarked"].contains(value)
    }

    // MARK: - JSON

    func parseJSON(_ data: Data, defaultCluster: DECACluster) -> ImportReport {
        var report = ImportReport()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var questions: [QuestionData] = []
        if let bundle = try? decoder.decode(ExportBundle.self, from: data) {
            questions = bundle.questions
        } else if let plain = try? decoder.decode([QuestionData].self, from: data) {
            questions = plain
        } else {
            var candidate = ImportCandidate()
            candidate.errors = ["This file isn't a recognised question bank export."]
            report.candidates = [candidate]
            return report
        }

        for var question in questions {
            var candidate = ImportCandidate()
            candidate.sourceLabel = String(question.text.prefix(60))
            if question.text.isEmpty { candidate.errors.append("Missing question text") }
            if question.choices.count != 4 || question.choices.contains(where: { $0.isEmpty }) {
                candidate.errors.append("Needs four answer choices")
            }
            if !(0...3).contains(question.correctIndex) {
                candidate.errors.append("Correct answer must be A–D")
            }
            question.isSample = false
            guard candidate.errors.isEmpty else {
                report.candidates.append(candidate)
                continue
            }
            candidate.question = question
            candidate.duplicateOf = bank.duplicate(of: question)
            report.candidates.append(candidate)
        }
        return report
    }

    // MARK: - Commit

    @discardableResult
    func commit(_ candidates: [ImportCandidate], includeDuplicates: Bool = false) -> Int {
        var inserted = 0
        for candidate in candidates {
            guard var question = candidate.question, candidate.errors.isEmpty else { continue }
            if candidate.isDuplicate && !includeDuplicates { continue }
            question.id = UUID()
            if bank.add(question) { inserted += 1 }
        }
        return inserted
    }

    // MARK: - Export

    func makeExport(includeProgress: Bool,
                    includeSettings: Bool,
                    settings: UserSettings,
                    streak: StreakState) -> ExportBundle {
        var bundle = ExportBundle()
        bundle.questions = bank.allQuestions()
        bundle.roleplays = bank.roleplays()

        if includeProgress {
            var progress = ExportBundle.ProgressExport()
            progress.spacedRepetition = ctx.fetchAll(CDSRRecord.self, entity: names.srRecord)
                .compactMap { row in
                    guard let id = row.questionID else { return nil }
                    return .init(questionID: id,
                                 timesAnswered: Int(row.timesAnswered),
                                 timesCorrect: Int(row.timesCorrect),
                                 timesIncorrect: Int(row.timesIncorrect),
                                 consecutiveCorrect: Int(row.consecutiveCorrect),
                                 lastAnsweredAt: row.lastAnsweredAt,
                                 nextReviewAt: row.nextReviewAt,
                                 intervalDays: row.intervalDays,
                                 ease: row.ease,
                                 masteryLevel: Int(row.masteryLevel))
                }
            progress.mistakes = ctx.fetchAll(CDMistake.self, entity: names.mistake)
                .compactMap { row in
                    guard let id = row.questionID else { return nil }
                    return .init(questionID: id,
                                 selectedIndex: Int(row.selectedIndex),
                                 timesMissed: Int(row.timesMissed),
                                 consecutiveCorrect: Int(row.consecutiveCorrect),
                                 mastered: row.mastered,
                                 firstMissedAt: row.firstMissedAt,
                                 lastMissedAt: row.lastMissedAt,
                                 cluster: row.cluster)
                }
            progress.days = ctx.fetchAll(CDDailyProgress.self, entity: names.dailyProgress)
                .compactMap { row in
                    guard let key = row.dayKey else { return nil }
                    return .init(dayKey: key,
                                 questionsAnswered: Int(row.questionsAnswered),
                                 correctCount: Int(row.correctCount),
                                 goal: Int(row.goal),
                                 goalMet: row.goalMet,
                                 secondsStudied: row.secondsStudied)
                }
            progress.indicators = ctx.fetchAll(CDPIMastery.self, entity: names.piMastery)
                .compactMap { row in
                    guard let code = row.code else { return nil }
                    return .init(code: code,
                                 cluster: row.cluster ?? "",
                                 timesAnswered: Int(row.timesAnswered),
                                 timesCorrect: Int(row.timesCorrect),
                                 roleplayCount: Int(row.roleplayCount),
                                 masteryScore: row.masteryScore)
                }
            progress.mockExams = ctx.fetchAll(CDMockAttempt.self, entity: names.mockAttempt)
                .compactMap { row in
                    guard let id = row.id else { return nil }
                    return .init(id: id,
                                 date: row.date ?? Date(),
                                 cluster: row.cluster ?? "",
                                 questionCount: Int(row.questionCount),
                                 correctCount: Int(row.correctCount),
                                 durationSeconds: row.durationSeconds)
                }
            progress.achievements = ctx.fetchAll(CDAchievementRecord.self, entity: names.achievement)
                .compactMap { $0.unlockedAt != nil ? $0.code : nil }
            progress.streak = streak
            bundle.progress = progress
        }

        if includeSettings {
            bundle.settings = .init(cluster: settings.cluster.rawValue,
                                    dailyGoal: settings.dailyGoal,
                                    remindersEnabled: settings.remindersEnabled,
                                    reminderHour: settings.reminderHour,
                                    reminderMinute: settings.reminderMinute,
                                    reminderStyle: settings.reminderStyleRaw,
                                    appearance: settings.appearanceRaw,
                                    hapticsEnabled: settings.hapticsEnabled)
        }
        return bundle
    }

    /// Writes the export to a temporary file and returns its URL for sharing.
    func writeExportFile(_ bundle: ExportBundle) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(bundle) else { return nil }

        let name = "Glass-Backup-\(Date().dayKey).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            NSLog("Export write failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Exports just the question bank as CSV.
    func writeCSVFile() -> URL? {
        var lines = ["question,a,b,c,d,correct,explanation,cluster,difficulty,tags,indicators,bookmarked"]
        for q in bank.allQuestions() {
            let fields = [
                q.text,
                q.choices.indices.contains(0) ? q.choices[0] : "",
                q.choices.indices.contains(1) ? q.choices[1] : "",
                q.choices.indices.contains(2) ? q.choices[2] : "",
                q.choices.indices.contains(3) ? q.choices[3] : "",
                q.correctLetter,
                q.explanation,
                q.cluster.displayName,
                q.difficulty.title,
                q.tags.joined(separator: ";"),
                q.performanceIndicators.joined(separator: ";"),
                q.isBookmarked ? "yes" : "no"
            ]
            lines.append(fields.map(CSVParser.escape).joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Glass-Questions-\(Date().dayKey).csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Restore

    /// Restores progress from a backup bundle. Questions are merged by ID.
    func restore(_ bundle: ExportBundle, settings: UserSettings, streakStore: StreakStore) {
        // `bank.add` sanitises, so nothing stored here can be structurally
        // dangerous. What it cannot do is invent a question out of one that
        // arrived empty, so those are skipped rather than turned into a row of
        // em-dashes the student would have to find and delete by hand.
        let existingIDs = Set(bank.allQuestions().map(\.id))
        for question in bundle.questions where !existingIDs.contains(question.id) {
            let cleaned = question.sanitized()
            guard cleaned.isStructurallyValid else { continue }
            bank.add(cleaned)
        }

        guard let progress = bundle.progress else {
            applySettings(bundle.settings, to: settings)
            return
        }

        for row in ctx.fetchAll(CDSRRecord.self, entity: names.srRecord) { ctx.delete(row) }
        for record in progress.spacedRepetition {
            let row = ctx.insert(CDSRRecord.self, entity: names.srRecord)
            row.questionID = record.questionID
            row.timesAnswered = Int32(record.timesAnswered)
            row.timesCorrect = Int32(record.timesCorrect)
            row.timesIncorrect = Int32(record.timesIncorrect)
            row.consecutiveCorrect = Int32(record.consecutiveCorrect)
            row.lastAnsweredAt = record.lastAnsweredAt
            row.nextReviewAt = record.nextReviewAt
            row.intervalDays = record.intervalDays
            row.ease = record.ease
            row.masteryLevel = Int32(record.masteryLevel)
        }

        for row in ctx.fetchAll(CDMistake.self, entity: names.mistake) { ctx.delete(row) }
        for record in progress.mistakes {
            let row = ctx.insert(CDMistake.self, entity: names.mistake)
            row.questionID = record.questionID
            row.selectedIndex = Int32(record.selectedIndex)
            row.timesMissed = Int32(record.timesMissed)
            row.consecutiveCorrect = Int32(record.consecutiveCorrect)
            row.mastered = record.mastered
            row.firstMissedAt = record.firstMissedAt
            row.lastMissedAt = record.lastMissedAt
            row.cluster = record.cluster
        }

        for row in ctx.fetchAll(CDDailyProgress.self, entity: names.dailyProgress) { ctx.delete(row) }
        for record in progress.days {
            let row = ctx.insert(CDDailyProgress.self, entity: names.dailyProgress)
            row.dayKey = record.dayKey
            row.date = DayKey.date(from: record.dayKey)
            row.questionsAnswered = Int32(record.questionsAnswered)
            row.correctCount = Int32(record.correctCount)
            row.goal = Int32(record.goal)
            row.goalMet = record.goalMet
            row.secondsStudied = record.secondsStudied
        }

        for row in ctx.fetchAll(CDPIMastery.self, entity: names.piMastery) { ctx.delete(row) }
        for record in progress.indicators {
            let row = ctx.insert(CDPIMastery.self, entity: names.piMastery)
            row.code = record.code
            row.text = SeedIndicators.text(forCode: record.code) ?? record.code
            row.cluster = record.cluster
            row.timesAnswered = Int32(record.timesAnswered)
            row.timesCorrect = Int32(record.timesCorrect)
            row.roleplayCount = Int32(record.roleplayCount)
            row.masteryScore = record.masteryScore
        }

        for row in ctx.fetchAll(CDAchievementRecord.self, entity: names.achievement) { ctx.delete(row) }
        for code in progress.achievements {
            let row = ctx.insert(CDAchievementRecord.self, entity: names.achievement)
            row.code = code
            row.unlockedAt = Date()
        }

        streakStore.replace(with: progress.streak)
        try? ctx.save()
        applySettings(bundle.settings, to: settings)
    }

    private func applySettings(_ exported: ExportBundle.SettingsExport?, to settings: UserSettings) {
        guard let exported else { return }
        if let cluster = DECACluster(rawValue: exported.cluster) { settings.cluster = cluster }
        settings.dailyGoal = exported.dailyGoal
        settings.remindersEnabled = exported.remindersEnabled
        settings.reminderHour = exported.reminderHour
        settings.reminderMinute = exported.reminderMinute
        settings.reminderStyleRaw = exported.reminderStyle
        settings.appearanceRaw = exported.appearance
        settings.hapticsEnabled = exported.hapticsEnabled
    }
}

// MARK: - Minimal CSV parser

enum CSVParser {
    /// Handles quoted fields, escaped quotes and embedded newlines.
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        let chars = Array(text.replacingOccurrences(of: "\r\n", with: "\n"))
        var i = 0

        while i < chars.count {
            let ch = chars[i]
            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 2
                        continue
                    }
                    inQuotes = false
                } else {
                    field.append(ch)
                }
            } else {
                switch ch {
                case "\"":
                    inQuotes = true
                case ",":
                    row.append(field)
                    field = ""
                case "\n":
                    row.append(field)
                    rows.append(row)
                    row = []
                    field = ""
                default:
                    field.append(ch)
                }
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } }
    }

    static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
