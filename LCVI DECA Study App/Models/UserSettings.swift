//
//  UserSettings.swift
//  LCVI DECA Study App
//
//  Lightweight preferences + streak state. Stored in UserDefaults (mirrored to
//  the shared App Group suite when available so widgets can read it).
//

import Combine
import Foundation
import SwiftUI

// MARK: - Shared defaults

enum SharedDefaults {
    /// Must match the App Group entitlement on both the app and the widget.
    static let appGroupID = "group.com.shailpatel.LCVI-DECA-Study-App"

    /// The App Group suite when the entitlement is present, otherwise the
    /// standard suite. Widgets simply show placeholder data if the group is
    /// unavailable — the app itself never depends on it.
    nonisolated(unsafe) static let suite: UserDefaults = {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }()

    static var hasAppGroup: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }
}

// MARK: - Reminder styles

enum ReminderStyle: String, CaseIterable, Codable, Identifiable {
    case motivating, direct, calm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .motivating: return "Motivating"
        case .direct:     return "Direct"
        case .calm:       return "Calm"
        }
    }

    func body(goal: Int, remaining: Int) -> String {
        let n = max(remaining, 1)
        switch self {
        case .motivating:
            return [
                "Keep your streak alive with a quick practice session.",
                "Exam day gets easier when today's practice gets done.",
                "\(n) questions stand between you and today's goal."
            ].randomElement()!
        case .direct:
            return "Your DECA goal is waiting: \(goal) questions today."
        case .calm:
            return "A few minutes of practice is enough to keep moving."
        }
    }
}

// MARK: - Intro styles

/// Which launch reveal plays. Both are shipped; the original is kept as a
/// fallback in case the handwritten one does not land.
enum IntroStyle: String, CaseIterable, Codable, Identifiable {
    case script, classic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .script:  return "Handwritten"
        case .classic: return "Etched"
        }
    }

    var detail: String {
        switch self {
        case .script:  return "\"glass\" written out in script, then filled as glass."
        case .classic: return "\"Glass\" traced in Fraunces, then filled as glass."
        }
    }
}

// MARK: - Settings

/// Observable settings object. Every property writes straight through to
/// UserDefaults so nothing is lost if the app is killed.
@MainActor
final class UserSettings: ObservableObject {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = SharedDefaults.suite) {
        self.defaults = defaults
        self.hasOnboarded = defaults.bool(forKey: Keys.hasOnboarded)
        self.clusterRaw = defaults.string(forKey: Keys.cluster) ?? DECACluster.marketing.rawValue
        self.dailyGoal = defaults.object(forKey: Keys.dailyGoal) as? Int ?? 10
        self.remindersEnabled = defaults.bool(forKey: Keys.remindersEnabled)
        self.reminderHour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 18
        self.reminderMinute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 30
        self.reminderStyleRaw = defaults.string(forKey: Keys.reminderStyle) ?? ReminderStyle.motivating.rawValue
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        self.appearanceRaw = defaults.string(forKey: Keys.appearance) ?? AppearanceMode.system.rawValue
        self.aiAutoExplain = defaults.object(forKey: Keys.aiAutoExplain) as? Bool ?? true
        self.aiEnabled = defaults.object(forKey: Keys.aiEnabled) as? Bool ?? true
        self.seededVersion = defaults.integer(forKey: Keys.seededVersion)
        self.introStyleRaw = defaults.string(forKey: Keys.introStyle) ?? IntroStyle.script.rawValue
        Haptics.enabled = self.hapticsEnabled
        SoundEffects.enabled = self.soundEnabled
    }

    private enum Keys {
        static let hasOnboarded = "hasOnboarded"
        static let cluster = "selectedCluster"
        static let dailyGoal = "dailyGoal"
        static let remindersEnabled = "remindersEnabled"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
        static let reminderStyle = "reminderStyle"
        static let haptics = "hapticsEnabled"
        static let sound = "soundEnabled"
        static let appearance = "appearance"
        static let aiAutoExplain = "aiAutoExplain"
        static let aiEnabled = "aiEnabled"
        static let seededVersion = "seededVersion"
        static let introStyle = "introStyle"
    }

    @Published var hasOnboarded: Bool { didSet { defaults.set(hasOnboarded, forKey: Keys.hasOnboarded) } }
    @Published var clusterRaw: String { didSet { defaults.set(clusterRaw, forKey: Keys.cluster) } }
    @Published var dailyGoal: Int { didSet { defaults.set(dailyGoal, forKey: Keys.dailyGoal) } }
    @Published var remindersEnabled: Bool { didSet { defaults.set(remindersEnabled, forKey: Keys.remindersEnabled) } }
    @Published var reminderHour: Int { didSet { defaults.set(reminderHour, forKey: Keys.reminderHour) } }
    @Published var reminderMinute: Int { didSet { defaults.set(reminderMinute, forKey: Keys.reminderMinute) } }
    @Published var reminderStyleRaw: String { didSet { defaults.set(reminderStyleRaw, forKey: Keys.reminderStyle) } }
    @Published var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: Keys.haptics)
            Haptics.enabled = hapticsEnabled
        }
    }
    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Keys.sound)
            SoundEffects.enabled = soundEnabled
        }
    }
    @Published var appearanceRaw: String { didSet { defaults.set(appearanceRaw, forKey: Keys.appearance) } }
    @Published var aiAutoExplain: Bool { didSet { defaults.set(aiAutoExplain, forKey: Keys.aiAutoExplain) } }
    @Published var aiEnabled: Bool { didSet { defaults.set(aiEnabled, forKey: Keys.aiEnabled) } }
    @Published var seededVersion: Int { didSet { defaults.set(seededVersion, forKey: Keys.seededVersion) } }
    @Published var introStyleRaw: String { didSet { defaults.set(introStyleRaw, forKey: Keys.introStyle) } }

    var cluster: DECACluster {
        get { DECACluster(rawValue: clusterRaw) ?? .marketing }
        set { clusterRaw = newValue.rawValue }
    }

    var reminderStyle: ReminderStyle {
        get { ReminderStyle(rawValue: reminderStyleRaw) ?? .motivating }
        set { reminderStyleRaw = newValue.rawValue }
    }

    var introStyle: IntroStyle {
        get { IntroStyle(rawValue: introStyleRaw) ?? .script }
        set { introStyleRaw = newValue.rawValue }
    }

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var reminderDate: Date {
        get {
            var comps = DateComponents()
            comps.hour = reminderHour
            comps.minute = reminderMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = comps.hour ?? 18
            reminderMinute = comps.minute ?? 30
        }
    }

    func resetToDefaults() {
        hasOnboarded = false
        cluster = .marketing
        dailyGoal = 10
        remindersEnabled = false
        reminderHour = 18
        reminderMinute = 30
        reminderStyle = .motivating
        hapticsEnabled = true
        soundEnabled = true
        appearance = .system
        aiAutoExplain = true
        aiEnabled = true
        seededVersion = 0
    }
}

// MARK: - Streak state

struct StreakState: Codable, Equatable {
    var current: Int = 0
    var longest: Int = 0
    var freezes: Int = 0
    var freezesEarnedTotal: Int = 0
    var lastCompletedDayKey: String? = nil
    /// Day keys that were rescued by a freeze — prevents double-spending.
    var frozenDayKeys: [String] = []

    /// Streak days completed since the last freeze was earned (0..<10).
    var progressToNextFreeze: Int {
        guard current > 0 else { return 0 }
        return current % 10
    }

    var daysUntilNextFreeze: Int {
        current == 0 ? 10 : (10 - (current % 10))
    }
}

@MainActor
final class StreakStore: ObservableObject {
    private let defaults: UserDefaults
    private let key = "streakState"

    @Published private(set) var state: StreakState

    init(defaults: UserDefaults = SharedDefaults.suite) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(StreakState.self, from: data) {
            self.state = decoded
        } else {
            self.state = StreakState()
        }
    }

    func update(_ transform: (inout StreakState) -> Void) {
        var copy = state
        transform(&copy)
        state = copy
        persist()
    }

    func replace(with newState: StreakState) {
        state = newState
        persist()
    }

    func reset() {
        state = StreakState()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: key)
        }
    }
}
