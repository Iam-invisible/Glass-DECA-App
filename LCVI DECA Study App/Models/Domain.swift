//
//  Domain.swift
//  LCVI DECA Study App
//
//  Plain value types shared across the app. These are storage-agnostic and
//  Codable so they can be exported/imported without touching Core Data.
//

import SwiftUI

// MARK: - Clusters

/// DECA Ontario competitive-event clusters covered by this app.
enum DECACluster: String, CaseIterable, Codable, Identifiable, Hashable {
    case marketing
    case finance
    case hospitality
    case businessManagement
    case entrepreneurship
    case personalFinancialLiteracy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .marketing:                 return "Marketing"
        case .finance:                   return "Finance"
        case .hospitality:               return "Hospitality and Tourism"
        case .businessManagement:        return "Business Management and Administration"
        case .entrepreneurship:          return "Entrepreneurship and Small Business Management"
        case .personalFinancialLiteracy: return "Personal Financial Literacy"
        }
    }

    var shortName: String {
        switch self {
        case .marketing:                 return "Marketing"
        case .finance:                   return "Finance"
        case .hospitality:               return "Hospitality"
        case .businessManagement:        return "Business Mgmt"
        case .entrepreneurship:          return "Entrepreneurship"
        case .personalFinancialLiteracy: return "Personal Finance"
        }
    }

    var code: String {
        switch self {
        case .marketing:                 return "MKT"
        case .finance:                   return "FIN"
        case .hospitality:               return "HT"
        case .businessManagement:        return "BMA"
        case .entrepreneurship:          return "ENT"
        case .personalFinancialLiteracy: return "PFL"
        }
    }

    var symbol: String {
        switch self {
        case .marketing:                 return "megaphone.fill"
        case .finance:                   return "chart.line.uptrend.xyaxis"
        case .hospitality:               return "fork.knife"
        case .businessManagement:        return "building.2.fill"
        case .entrepreneurship:          return "lightbulb.fill"
        case .personalFinancialLiteracy: return "creditcard.fill"
        }
    }

    var blurb: String {
        switch self {
        case .marketing:
            return "Promotion, pricing, channel management and market research."
        case .finance:
            return "Accounting, financial analysis, risk and banking services."
        case .hospitality:
            return "Lodging, food service, travel and guest experience."
        case .businessManagement:
            return "Operations, human resources, strategic management and law."
        case .entrepreneurship:
            return "Business concepts, funding, growth and small-business ownership."
        case .personalFinancialLiteracy:
            return "Earning, spending, saving, investing and credit management."
        }
    }

    /// Every cluster uses the same accent family — colour carries meaning,
    /// not category — but a subtle tint helps scanning long lists.
    /// The cluster's colour, used for the Study screen's light field, the
    /// onboarding retint and the cluster chips.
    ///
    /// Muted ink tones rather than screen colours, because they now sit on warm
    /// paper. Each one is deliberately clear of the four semantic accents in
    /// `Palette` — the previous set was not, and three collisions were real
    /// bugs: marketing *was* the accent colour, personal finance was three per
    /// cent from the correct-answer green, and in dark mode hospitality and the
    /// streak gold were the same value. A student could not tell their cluster
    /// from a button, a right answer, or a streak.
    var tint: Color {
        switch self {
        case .marketing:                 return Color(lightHex: 0x7C3F66, darkHex: 0xC98BB0)
        case .finance:                   return Color(lightHex: 0x1F6B63, darkHex: 0x5FBAAD)
        case .hospitality:               return Color(lightHex: 0x8A5A4A, darkHex: 0xC79A87)
        case .businessManagement:        return Color(lightHex: 0x45508C, darkHex: 0x8D97D8)
        case .entrepreneurship:          return Color(lightHex: 0xA8455E, darkHex: 0xE28CA0)
        case .personalFinancialLiteracy: return Color(lightHex: 0x5F7038, darkHex: 0xA8BE73)
        }
    }

    /// The DECA Ontario exam most commonly written for this cluster.
    var examName: String {
        switch self {
        case .marketing:                 return "Marketing Cluster Exam"
        case .finance:                   return "Finance Cluster Exam"
        case .hospitality:               return "Hospitality and Tourism Cluster Exam"
        case .businessManagement:        return "Business Management and Administration Cluster Exam"
        case .entrepreneurship:          return "Entrepreneurship Cluster Exam"
        case .personalFinancialLiteracy: return "Personal Financial Literacy Exam"
        }
    }

    static func from(_ raw: String?) -> DECACluster? {
        guard let raw else { return nil }
        if let exact = DECACluster(rawValue: raw) { return exact }
        let normalized = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for c in DECACluster.allCases {
            if c.displayName.lowercased() == normalized { return c }
            if c.shortName.lowercased() == normalized { return c }
            if c.code.lowercased() == normalized { return c }
        }
        // Forgiving matches for bulk import.
        if normalized.contains("market") { return .marketing }
        if normalized.contains("hospitality") || normalized.contains("tourism") { return .hospitality }
        if normalized.contains("entrepreneur") { return .entrepreneurship }
        if normalized.contains("personal") { return .personalFinancialLiteracy }
        if normalized.contains("management") || normalized.contains("admin") { return .businessManagement }
        if normalized.contains("financ") { return .finance }
        return nil
    }
}

// MARK: - Difficulty

enum Difficulty: Int, CaseIterable, Codable, Identifiable, Hashable {
    case easy = 1
    case medium = 2
    case hard = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }

    var color: Color {
        switch self {
        case .easy:   return Palette.success
        case .medium: return Palette.accent
        case .hard:   return Palette.danger
        }
    }

    static func from(_ raw: String?) -> Difficulty {
        guard let raw = raw?.lowercased().trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return .medium }
        if raw.hasPrefix("e") || raw == "1" { return .easy }
        if raw.hasPrefix("h") || raw == "3" { return .hard }
        return .medium
    }
}

// MARK: - Answer letters

enum AnswerLetter: Int, CaseIterable, Identifiable {
    case a = 0, b = 1, c = 2, d = 3

    var id: Int { rawValue }
    var label: String { ["A", "B", "C", "D"][rawValue] }

    static func from(_ raw: String) -> AnswerLetter? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let first = t.first else { return nil }
        switch first {
        case "A": return .a
        case "B": return .b
        case "C": return .c
        case "D": return .d
        case "1": return .a
        case "2": return .b
        case "3": return .c
        case "4": return .d
        default:  return nil
        }
    }
}

// MARK: - Question value type

struct QuestionData: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var choices: [String]          // exactly 4
    var correctIndex: Int
    var explanation: String
    /// One line per choice saying why it is right or wrong, parallel to
    /// `choices`. Empty means the question predates the field or was imported
    /// without it — every reader must treat it as optional, because a student's
    /// own imported bank will never have it.
    var choiceRationales: [String] = []
    var cluster: DECACluster
    var examType: String
    var difficulty: Difficulty
    var tags: [String]
    var performanceIndicators: [String]
    var isSample: Bool = true
    var isBookmarked: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, text, choices, correctIndex, explanation, choiceRationales, cluster, examType
        case difficulty, tags, performanceIndicators, isSample, isBookmarked
    }

    init(id: UUID = UUID(),
         text: String,
         choices: [String],
         correctIndex: Int,
         explanation: String,
         choiceRationales: [String] = [],
         cluster: DECACluster,
         examType: String,
         difficulty: Difficulty,
         tags: [String],
         performanceIndicators: [String],
         isSample: Bool = true,
         isBookmarked: Bool = false) {
        self.id = id
        self.text = text
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.choiceRationales = choiceRationales
        self.cluster = cluster
        self.examType = examType
        self.difficulty = difficulty
        self.tags = tags
        self.performanceIndicators = performanceIndicators
        self.isSample = isSample
        self.isBookmarked = isBookmarked
    }

    /// The line for one choice, or nil when this question carries none.
    func rationale(for index: Int) -> String? {
        guard choiceRationales.indices.contains(index) else { return nil }
        let line = choiceRationales[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return line.isEmpty ? nil : line
    }

    var hasChoiceRationales: Bool {
        choiceRationales.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        text = try container.decode(String.self, forKey: .text)
        choices = try container.decode([String].self, forKey: .choices)
        correctIndex = try container.decode(Int.self, forKey: .correctIndex)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation) ?? ""
        choiceRationales = try container.decodeIfPresent([String].self, forKey: .choiceRationales) ?? []
        cluster = try container.decode(DECACluster.self, forKey: .cluster)
        examType = try container.decodeIfPresent(String.self, forKey: .examType) ?? cluster.examName
        difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? .medium
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        performanceIndicators = try container.decodeIfPresent([String].self, forKey: .performanceIndicators) ?? []
        isSample = try container.decodeIfPresent(Bool.self, forKey: .isSample) ?? true
        isBookmarked = try container.decodeIfPresent(Bool.self, forKey: .isBookmarked) ?? false
    }

    var correctLetter: String { AnswerLetter(rawValue: correctIndex)?.label ?? "?" }

    /// Normalised text used for duplicate detection.
    var fingerprint: String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Performance indicators

struct PerformanceIndicatorData: Identifiable, Codable, Hashable {
    var id: String { code }
    var code: String
    var text: String
    var instructionalArea: String
    var cluster: DECACluster
}

// MARK: - Roleplay

struct RoleplayPromptData: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var cluster: DECACluster
    var eventType: String
    var situation: String
    var userRole: String
    var judgeRole: String
    var performanceIndicators: [String]
    var difficulty: Difficulty
    var prepMinutes: Int
    var presentMinutes: Int
    var isSample: Bool = true
}

/// Judge-style rubric used for both self-rating and AI-estimated scores.
enum RubricCategory: String, CaseIterable, Codable, Identifiable {
    case understanding
    case indicators
    case professionalism
    case creativity
    case clarity
    case persuasiveness
    case practicality
    case reasoning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .understanding:   return "Understanding of the business problem"
        case .indicators:      return "Use of performance indicators"
        case .professionalism: return "Professionalism"
        case .creativity:      return "Creativity"
        case .clarity:         return "Clarity"
        case .persuasiveness:  return "Persuasiveness"
        case .practicality:    return "Practicality of solution"
        case .reasoning:       return "Overall business reasoning"
        }
    }

    var shortTitle: String {
        switch self {
        case .understanding:   return "Understanding"
        case .indicators:      return "Indicators"
        case .professionalism: return "Professional"
        case .creativity:      return "Creativity"
        case .clarity:         return "Clarity"
        case .persuasiveness:  return "Persuasion"
        case .practicality:    return "Practicality"
        case .reasoning:       return "Reasoning"
        }
    }

    var symbol: String {
        switch self {
        case .understanding:   return "brain.head.profile"
        case .indicators:      return "list.bullet.clipboard"
        case .professionalism: return "person.crop.circle.badge.checkmark"
        case .creativity:      return "sparkles"
        case .clarity:         return "text.alignleft"
        case .persuasiveness:  return "hand.raised.fill"
        case .practicality:    return "wrench.and.screwdriver.fill"
        case .reasoning:       return "function"
        }
    }
}

// MARK: - Quick Think

struct QuickThinkScenario: Identifiable, Codable, Hashable {
    var id: String
    var cluster: DECACluster
    var prompt: String
    var focus: String
}

// MARK: - Practice modes

enum PracticeMode: String, Codable, Hashable {
    case daily
    case reviewDue
    case mistakes
    case bookmarked
    case cluster
    case topic
    case indicator
    case custom
    case examCram
    case mockRetry

    var title: String {
        switch self {
        case .daily:      return "Daily Practice"
        case .reviewDue:  return "Review Due"
        case .mistakes:   return "Mistake Notebook"
        case .bookmarked: return "Bookmarked"
        case .cluster:    return "Cluster Practice"
        case .topic:      return "Topic Practice"
        case .indicator:  return "Indicator Practice"
        case .custom:     return "Custom Practice"
        case .examCram:   return "Exam Cram"
        case .mockRetry:  return "Retry Missed"
        }
    }
}

// MARK: - Mastery

enum MasteryBand: Int, CaseIterable {
    case untouched = 0
    case learning = 1
    case developing = 2
    case proficient = 3
    case mastered = 4

    var title: String {
        switch self {
        case .untouched:  return "Not started"
        case .learning:   return "Learning"
        case .developing: return "Developing"
        case .proficient: return "Proficient"
        case .mastered:   return "Mastered"
        }
    }

    var color: Color {
        switch self {
        case .untouched:  return Palette.inactive
        case .learning:   return Palette.danger
        case .developing: return Palette.gold
        case .proficient: return Palette.accent
        case .mastered:   return Palette.success
        }
    }

    static func from(score: Double) -> MasteryBand {
        switch score {
        case ..<0.01: return .untouched
        case ..<0.45: return .learning
        case ..<0.68: return .developing
        case ..<0.85: return .proficient
        default:      return .mastered
        }
    }
}

// MARK: - Date helpers

extension Date {
    /// Local-calendar day key. Streaks are computed from these so time-zone
    /// changes never double-count a day.
    var dayKey: String {
        DayKey.formatter.string(from: self)
    }
}

enum DayKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String { formatter.string(from: date) }

    static func date(from key: String) -> Date? { formatter.date(from: key) }

    /// Whole days between two day keys using the user's calendar.
    static func daysBetween(_ a: String, _ b: String) -> Int? {
        guard let d1 = date(from: a), let d2 = date(from: b) else { return nil }
        return Calendar.current.dateComponents([.day], from: d1, to: d2).day
    }
}
