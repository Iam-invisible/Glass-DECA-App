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
    static let appGroupID = "group.com.shailpatel.LCVI-DECA-Study-NewApp"

    /// The App Group suite when the entitlement is genuinely present,
    /// otherwise the standard suite. Widgets simply show placeholder data if
    /// the group is unavailable — the app itself never depends on it.
    ///
    /// The container URL is the probe, not `UserDefaults(suiteName:)`. When a
    /// process is not entitled for a group, that initialiser does **not**
    /// return nil — it hands back an object whose backing store failed to
    /// open, and every read or write against it logs "invalid reuse after
    /// initialization failure". Asking the file system whether the container
    /// exists is the only answer that can be trusted, and it costs one call
    /// at launch.
    nonisolated(unsafe) static let suite: UserDefaults = {
        guard hasAppGroup, let shared = UserDefaults(suiteName: appGroupID) else {
            return .standard
        }
        return shared
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
        case .classic: return "\"Glass\" traced in Instrument Serif, then filled as glass."
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
        self.hasSeenGuide = defaults.bool(forKey: Keys.hasSeenGuide)
        self.acceptedPrivacyVersion = defaults.integer(forKey: Keys.acceptedPrivacyVersion)
        self.acceptedPrivacyAt = defaults.object(forKey: Keys.acceptedPrivacyAt) as? Date
        self.eventCode = defaults.string(forKey: Keys.eventCode) ?? ""
        self.quickThinkGoal = defaults.object(forKey: Keys.quickThinkGoal) as? Int ?? 1
        self.coins = defaults.integer(forKey: Keys.coins)
        self.ownedCosmeticIDs = Set(defaults.stringArray(forKey: Keys.ownedCosmetics) ?? [])
        self.equippedCosmeticIDs = (defaults.dictionary(forKey: Keys.equippedCosmetics) as? [String: String]) ?? [:]
        self.ownedAppItemIDs = Set(defaults.stringArray(forKey: Keys.ownedAppItems) ?? [])
        self.appIconID = defaults.string(forKey: Keys.appIcon) ?? "icon.default"
        self.themeID = defaults.string(forKey: Keys.theme) ?? "theme.blue"
        self.soundPackID = defaults.string(forKey: Keys.soundPack) ?? "sound.default"
        Haptics.enabled = self.hapticsEnabled
        SoundEffects.enabled = self.soundEnabled
        Palette.accentTheme = AccentTheme(itemID: self.themeID)
        SoundEffects.pack = self.soundPackID
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
        static let hasSeenGuide = "hasSeenGuide"
        static let acceptedPrivacyVersion = "acceptedPrivacyVersion"
        static let acceptedPrivacyAt = "acceptedPrivacyAt"
        static let eventCode = "eventCode"
        static let quickThinkGoal = "quickThinkGoal"
        static let coins = "coins"
        static let ownedCosmetics = "ownedCosmetics"
        static let equippedCosmetics = "equippedCosmetics"
        static let ownedAppItems = "ownedAppItems"
        static let appIcon = "appIcon"
        static let theme = "appTheme"
        static let soundPack = "soundPack"
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
    @Published var hasSeenGuide: Bool { didSet { defaults.set(hasSeenGuide, forKey: Keys.hasSeenGuide) } }

    /// Which version of the privacy notice the student accepted, or 0 if none.
    ///
    /// Stored as a version rather than a flag so a material change to the
    /// notice can ask again: `PrivacyPolicy.version` is bumped and everyone is
    /// re-prompted on next launch, without the app having to remember who was
    /// shown what.
    @Published var acceptedPrivacyVersion: Int {
        didSet { defaults.set(acceptedPrivacyVersion, forKey: Keys.acceptedPrivacyVersion) }
    }

    /// When that acceptance happened. Recorded because "we asked and they
    /// agreed" is worth being able to show, and it costs one date to keep.
    @Published var acceptedPrivacyAt: Date? {
        didSet { defaults.set(acceptedPrivacyAt, forKey: Keys.acceptedPrivacyAt) }
    }

    /// True when the current notice has been accepted.
    var hasAcceptedCurrentPrivacyPolicy: Bool {
        acceptedPrivacyVersion >= PrivacyPolicy.version
    }

    func acceptPrivacyPolicy() {
        acceptedPrivacyAt = Date()
        acceptedPrivacyVersion = PrivacyPolicy.version
    }
    /// The student's competitive event code, or "" while undecided. Stored as
    /// the code rather than the resolved event so a corrected catalogue takes
    /// effect immediately instead of freezing last year's format.
    @Published var eventCode: String { didSet { defaults.set(eventCode, forKey: Keys.eventCode) } }
    @Published var quickThinkGoal: Int { didSet { defaults.set(quickThinkGoal, forKey: Keys.quickThinkGoal) } }

    /// The resolved event, or nil while undecided. Everything that shapes the
    /// app around a student's season reads this.
    var event: DECAEvent? {
        eventCode.isEmpty ? nil : DECAEvents.event(forCode: eventCode)
    }

    /// Whether an exam appears anywhere in the student's season. With no event
    /// chosen the answer is yes — the app should not hide its core feature
    /// from someone who has not told it anything yet.
    var eventHasExam: Bool { event?.hasAnyExam ?? true }
    var eventHasRoleplay: Bool { event?.hasAnyRoleplay ?? true }

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

    // MARK: - Wallet and customisation

    /// Coins are earned by studying and spent in the customise shop. They are
    /// never purchasable with money: that would need StoreKit, receipts and a
    /// restore path, and restore needs an account — which the app does not
    /// have and is not going to grow.
    @Published var coins: Int { didSet { defaults.set(coins, forKey: Keys.coins) } }

    @Published var ownedCosmeticIDs: Set<String> {
        didSet { defaults.set(Array(ownedCosmeticIDs), forKey: Keys.ownedCosmetics) }
    }

    /// Slot raw value → item id. A slot missing from the dictionary is bare,
    /// which is how "take it off" works without a null item in the catalogue.
    @Published var equippedCosmeticIDs: [String: String] {
        didSet { defaults.set(equippedCosmeticIDs, forKey: Keys.equippedCosmetics) }
    }

    @Published var ownedAppItemIDs: Set<String> {
        didSet { defaults.set(Array(ownedAppItemIDs), forKey: Keys.ownedAppItems) }
    }

    @Published var appIconID: String { didSet { defaults.set(appIconID, forKey: Keys.appIcon) } }

    @Published var themeID: String {
        didSet {
            defaults.set(themeID, forKey: Keys.theme)
            Palette.accentTheme = AccentTheme(itemID: themeID)
        }
    }

    @Published var soundPackID: String {
        didSet {
            defaults.set(soundPackID, forKey: Keys.soundPack)
            SoundEffects.pack = soundPackID
        }
    }

    // MARK: Queries

    func owns(_ item: CosmeticItem) -> Bool { ownedCosmeticIDs.contains(item.id) }

    func owns(_ item: AppCosmeticItem) -> Bool {
        item.isDefault || ownedAppItemIDs.contains(item.id)
    }

    func equipped(_ slot: CosmeticSlot) -> CosmeticItem? {
        equippedCosmeticIDs[slot.rawValue].flatMap(CosmeticCatalogue.item(id:))
    }

    var equippedCosmetics: [CosmeticSlot: CosmeticItem] {
        var out: [CosmeticSlot: CosmeticItem] = [:]
        for slot in CosmeticSlot.allCases {
            if let item = equipped(slot) { out[slot] = item }
        }
        return out
    }

    func isSelected(_ item: AppCosmeticItem) -> Bool {
        switch item.kind {
        case .icon:  return appIconID == item.id
        case .theme: return themeID == item.id
        case .sound: return soundPackID == item.id
        case .intro: return introStyleRaw == (item.id == "intro.classic" ? IntroStyle.classic.rawValue
                                                                        : IntroStyle.script.rawValue)
        }
    }

    // MARK: Mutations

    func award(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
    }

    /// Returns false when the balance will not cover it, so the caller can say
    /// so rather than silently doing nothing.
    @discardableResult
    func buy(_ item: CosmeticItem) -> Bool {
        guard !owns(item), coins >= item.price else { return false }
        coins -= item.price
        ownedCosmeticIDs.insert(item.id)
        equip(item)
        return true
    }

    @discardableResult
    func buy(_ item: AppCosmeticItem) -> Bool {
        guard !owns(item), coins >= item.price else { return false }
        coins -= item.price
        ownedAppItemIDs.insert(item.id)
        select(item)
        return true
    }

    func equip(_ item: CosmeticItem) {
        guard owns(item) else { return }
        equippedCosmeticIDs[item.slot.rawValue] = item.id
    }

    func unequip(_ slot: CosmeticSlot) {
        equippedCosmeticIDs.removeValue(forKey: slot.rawValue)
    }

    /// Toggles: tapping an equipped item takes it off, which is what a student
    /// expects and saves a separate remove control per slot.
    func toggleEquip(_ item: CosmeticItem) {
        if equipped(item.slot)?.id == item.id { unequip(item.slot) } else { equip(item) }
    }

    func select(_ item: AppCosmeticItem) {
        guard owns(item) else { return }
        switch item.kind {
        case .icon:  appIconID = item.id
        case .theme: themeID = item.id
        case .sound: soundPackID = item.id
        case .intro: introStyleRaw = (item.id == "intro.classic" ? IntroStyle.classic.rawValue
                                                                : IntroStyle.script.rawValue)
        }
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
