//
//  WidgetDataService.swift
//  LCVI DECA Study App
//
//  Publishes a tiny local snapshot for the home-screen widgets.
//  Local data only — no account, no network. If the App Group entitlement is
//  missing the write simply lands in the app's own defaults and the widget
//  shows placeholder content instead of failing.
//
//  `WidgetSnapshot` is duplicated verbatim in DECAStudyWidget/WidgetShared.swift.
//  The extension is its own binary and cannot import the app, so the two copies
//  are kept in step by hand — add a field here and add it there in the same
//  change, or the widget silently decodes it away.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetSnapshot: Codable, Equatable {

    // v1 — the daily ring and the streak.
    var clusterShortName: String = "Marketing"
    var answeredToday: Int = 0
    var goal: Int = 10
    var streak: Int = 0
    var freezes: Int = 0
    var dueForReview: Int = 0
    var updatedAt: Date = Date()

    // v2 — what the large widget reads. Every one is optional on the wire, so
    // a payload written by the previous build still decodes to sane defaults.
    var eventCode: String = ""
    var quickThinkToday: Int = 0
    /// Zero means this student's event has no roleplay component, so the whole
    /// Quick Think dial is hidden rather than shown at 0/0 (§6).
    var quickThinkGoal: Int = 0
    var openMistakes: Int = 0
    var accuracy: Double = 0
    var totalAnswered: Int = 0
    var bookmarked: Int = 0
    var achievements: Int = 0
    var lastMockScore: Int? = nil
    var weakestCode: String = ""
    var weakestText: String = ""

    var remaining: Int { max(0, goal - answeredToday) }
    var fraction: Double { goal <= 0 ? 1 : min(1, Double(answeredToday) / Double(goal)) }
    var goalMet: Bool { answeredToday >= goal }

    var showsQuickThink: Bool { quickThinkGoal > 0 }
    var quickThinkFraction: Double {
        quickThinkGoal <= 0 ? 1 : min(1, Double(quickThinkToday) / Double(quickThinkGoal))
    }
    var quickThinkGoalMet: Bool { quickThinkGoal > 0 && quickThinkToday >= quickThinkGoal }

    static let placeholder = WidgetSnapshot(clusterShortName: "Marketing",
                                            answeredToday: 6,
                                            goal: 10,
                                            streak: 4,
                                            freezes: 0,
                                            dueForReview: 3)

    enum CodingKeys: String, CodingKey {
        case clusterShortName, answeredToday, goal, streak, freezes, dueForReview, updatedAt
        case eventCode, quickThinkToday, quickThinkGoal, openMistakes, accuracy
        case totalAnswered, bookmarked, achievements, lastMockScore, weakestCode, weakestText
    }

    /// Hand-written so a snapshot encoded by an older build — which carries
    /// none of the v2 keys — decodes to defaults rather than throwing. A failed
    /// decode would blank every widget until the app next reached the
    /// foreground, which is a visible regression for no benefit.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clusterShortName = try c.decodeIfPresent(String.self, forKey: .clusterShortName) ?? "Marketing"
        answeredToday    = try c.decodeIfPresent(Int.self,    forKey: .answeredToday) ?? 0
        goal             = try c.decodeIfPresent(Int.self,    forKey: .goal) ?? 10
        streak           = try c.decodeIfPresent(Int.self,    forKey: .streak) ?? 0
        freezes          = try c.decodeIfPresent(Int.self,    forKey: .freezes) ?? 0
        dueForReview     = try c.decodeIfPresent(Int.self,    forKey: .dueForReview) ?? 0
        updatedAt        = try c.decodeIfPresent(Date.self,   forKey: .updatedAt) ?? Date(timeIntervalSince1970: 0)
        eventCode        = try c.decodeIfPresent(String.self, forKey: .eventCode) ?? ""
        quickThinkToday  = try c.decodeIfPresent(Int.self,    forKey: .quickThinkToday) ?? 0
        quickThinkGoal   = try c.decodeIfPresent(Int.self,    forKey: .quickThinkGoal) ?? 0
        openMistakes     = try c.decodeIfPresent(Int.self,    forKey: .openMistakes) ?? 0
        accuracy         = try c.decodeIfPresent(Double.self, forKey: .accuracy) ?? 0
        totalAnswered    = try c.decodeIfPresent(Int.self,    forKey: .totalAnswered) ?? 0
        bookmarked       = try c.decodeIfPresent(Int.self,    forKey: .bookmarked) ?? 0
        achievements     = try c.decodeIfPresent(Int.self,    forKey: .achievements) ?? 0
        lastMockScore    = try c.decodeIfPresent(Int.self,    forKey: .lastMockScore)
        weakestCode      = try c.decodeIfPresent(String.self, forKey: .weakestCode) ?? ""
        weakestText      = try c.decodeIfPresent(String.self, forKey: .weakestText) ?? ""
    }

    /// Declaring `init(from:)` above suppresses the memberwise initialiser,
    /// so it is written out here.
    init(clusterShortName: String = "Marketing",
         answeredToday: Int = 0,
         goal: Int = 10,
         streak: Int = 0,
         freezes: Int = 0,
         dueForReview: Int = 0,
         updatedAt: Date = Date(),
         eventCode: String = "",
         quickThinkToday: Int = 0,
         quickThinkGoal: Int = 0,
         openMistakes: Int = 0,
         accuracy: Double = 0,
         totalAnswered: Int = 0,
         bookmarked: Int = 0,
         achievements: Int = 0,
         lastMockScore: Int? = nil,
         weakestCode: String = "",
         weakestText: String = "") {
        self.clusterShortName = clusterShortName
        self.answeredToday = answeredToday
        self.goal = goal
        self.streak = streak
        self.freezes = freezes
        self.dueForReview = dueForReview
        self.updatedAt = updatedAt
        self.eventCode = eventCode
        self.quickThinkToday = quickThinkToday
        self.quickThinkGoal = quickThinkGoal
        self.openMistakes = openMistakes
        self.accuracy = accuracy
        self.totalAnswered = totalAnswered
        self.bookmarked = bookmarked
        self.achievements = achievements
        self.lastMockScore = lastMockScore
        self.weakestCode = weakestCode
        self.weakestText = weakestText
    }
}

enum WidgetDataService {
    static let snapshotKey = "widget.snapshot.v1"
    static let kind = "DECAStudyWidget"

    static func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        SharedDefaults.suite.set(data, forKey: snapshotKey)
        reloadTimelines()
    }

    static func read() -> WidgetSnapshot? {
        guard let data = SharedDefaults.suite.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func reloadTimelines() {
        #if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }

    static func clear() {
        SharedDefaults.suite.removeObject(forKey: snapshotKey)
        reloadTimelines()
    }
}
