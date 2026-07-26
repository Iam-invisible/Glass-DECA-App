//
//  WidgetDataService.swift
//  LCVI DECA Study App
//
//  Publishes a tiny local snapshot for the home-screen widgets.
//  Local data only — no account, no network. If the App Group entitlement is
//  missing the write simply lands in the app's own defaults and the widget
//  shows placeholder content instead of failing.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetSnapshot: Codable, Equatable {
    var clusterShortName: String = "Marketing"
    var answeredToday: Int = 0
    var goal: Int = 10
    var streak: Int = 0
    var freezes: Int = 0
    var dueForReview: Int = 0
    var updatedAt: Date = Date()

    var remaining: Int { max(0, goal - answeredToday) }
    var fraction: Double { goal <= 0 ? 1 : min(1, Double(answeredToday) / Double(goal)) }
    var goalMet: Bool { answeredToday >= goal }

    static let placeholder = WidgetSnapshot(clusterShortName: "Marketing",
                                            answeredToday: 6,
                                            goal: 10,
                                            streak: 4,
                                            freezes: 0,
                                            dueForReview: 3)
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
