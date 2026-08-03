//
//  Cosmetics.swift
//  LCVI DECA Study App
//
//  The customise catalogue: what the hamster can wear, what the app itself can
//  wear, and what each costs.
//
//  Two rules shape the prices below.
//
//  First, coins are earned only by studying — 1 per question, 2 more for a
//  correct one, 15 for finishing the day's goal, 50 at each ten-day streak
//  mark, 25 per achievement. A student hitting a 10-question goal at ~70%
//  accuracy earns around 39 a day. Nothing is purchasable with money; adding
//  that would mean StoreKit, receipts and restore, which breaks the app's
//  no-account rule.
//
//  Second, nothing here touches studying. Every item is cosmetic. The moment a
//  purchase changes what questions you get or how they are marked, the shop
//  stops being a reward and starts being a tax on learning.
//

import SwiftUI

// MARK: - Earning

/// Every coin in the app is minted at one of these four events. Kept together
/// so the earn rate can be read against the prices below without hunting
/// through `AppStore`.
///
/// A 10-question goal at ~70% accuracy pays 10 + 14 + 15 = 39 a day, so the
/// cheapest item is about two days' work and the dearest about a fortnight.
enum CoinRate {
    static let answer = 1
    static let correctAnswer = 3
    static let dailyGoal = 15
    static let streakMilestone = 50
    static let achievement = 25
}

// MARK: - Slots

/// Where an item sits on the hamster. One item per slot at a time.
enum CosmeticSlot: String, CaseIterable, Codable, Identifiable {
    case hair, headwear, facialHair, earrings, chain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hair:       return "Hair"
        case .headwear:   return "Hats"
        case .facialHair: return "Facial hair"
        case .earrings:   return "Earrings"
        case .chain:      return "Chains"
        }
    }

    var symbol: String {
        switch self {
        case .hair:       return "comb.fill"
        case .headwear:   return "graduationcap.fill"
        case .facialHair: return "mustache.fill"
        case .earrings:   return "circle.circle.fill"
        case .chain:      return "link"
        }
    }
}

// MARK: - Designs

/// The drawing instruction for an item. `HamsterAvatar` switches on these, so
/// adding a style means adding a case here and a shape there — the catalogue
/// entry alone will not draw anything.
enum HairStyle: String, Codable { case buzz, dreads, long, sidePart, mohawk, afro, spikes }
enum HeadwearStyle: String, Codable { case cap, beanie, topHat, crown, headphones, visor }
enum FacialHairStyle: String, Codable { case stubble, moustache, goatee, beard, muttonChops }
enum EarringStyle: String, Codable { case studs, hoops, drops }
enum ChainStyle: String, Codable { case thin, cuban, pendant }

enum CosmeticDesign: Hashable {
    case hair(HairStyle)
    case headwear(HeadwearStyle)
    case facialHair(FacialHairStyle)
    case earrings(EarringStyle)
    case chain(ChainStyle)
}

// MARK: - Item

struct CosmeticItem: Identifiable, Hashable {
    /// Stable and stored in UserDefaults — renaming one un-owns it for every
    /// student who bought it, the same trap the seed content's stable IDs
    /// exist to avoid.
    let id: String
    let name: String
    let slot: CosmeticSlot
    let price: Int
    let design: CosmeticDesign
    /// The item's own colour, where it has one.
    var tintHex: UInt32 = 0x4A3426
}

// MARK: - Hamster catalogue

enum CosmeticCatalogue {
    static let all: [CosmeticItem] = hair + headwear + facialHair + earrings + chains

    static let hair: [CosmeticItem] = [
        .init(id: "hair.buzz",     name: "Buzz cut",   slot: .hair, price: 120, design: .hair(.buzz),     tintHex: 0x60482F),
        .init(id: "hair.side",     name: "Side part",  slot: .hair, price: 150, design: .hair(.sidePart), tintHex: 0x3A2C22),
        .init(id: "hair.long",     name: "Long hair",  slot: .hair, price: 200, design: .hair(.long),     tintHex: 0x4A3426),
        .init(id: "hair.dreads",   name: "Dreads",     slot: .hair, price: 240, design: .hair(.dreads),   tintHex: 0x3A281E),
        .init(id: "hair.afro",     name: "Afro",       slot: .hair, price: 240, design: .hair(.afro),     tintHex: 0x2E2018),
        .init(id: "hair.spikes",   name: "Spikes",     slot: .hair, price: 220, design: .hair(.spikes),   tintHex: 0x2A2A32),
        .init(id: "hair.mohawk",   name: "Mohawk",     slot: .hair, price: 260, design: .hair(.mohawk),   tintHex: 0xC4404A),
    ]

    static let headwear: [CosmeticItem] = [
        .init(id: "hat.cap",        name: "Ball cap",    slot: .headwear, price: 160, design: .headwear(.cap),        tintHex: 0x265AA0),
        .init(id: "hat.beanie",     name: "Beanie",      slot: .headwear, price: 180, design: .headwear(.beanie),     tintHex: 0x964646),
        .init(id: "hat.visor",      name: "Visor",       slot: .headwear, price: 200, design: .headwear(.visor),      tintHex: 0x2F7D5C),
        .init(id: "hat.headphones", name: "Headphones",  slot: .headwear, price: 260, design: .headwear(.headphones), tintHex: 0x33343C),
        .init(id: "hat.top",        name: "Top hat",     slot: .headwear, price: 340, design: .headwear(.topHat),     tintHex: 0x1E1E24),
        .init(id: "hat.crown",      name: "Crown",       slot: .headwear, price: 400, design: .headwear(.crown),      tintHex: 0xD4AF37),
    ]

    static let facialHair: [CosmeticItem] = [
        .init(id: "face.stubble",   name: "Stubble",      slot: .facialHair, price: 90,  design: .facialHair(.stubble),     tintHex: 0x967C60),
        .init(id: "face.moustache", name: "Moustache",    slot: .facialHair, price: 130, design: .facialHair(.moustache),   tintHex: 0x4A3426),
        .init(id: "face.goatee",    name: "Goatee",       slot: .facialHair, price: 150, design: .facialHair(.goatee),      tintHex: 0x4A3426),
        .init(id: "face.chops",     name: "Mutton chops", slot: .facialHair, price: 180, design: .facialHair(.muttonChops), tintHex: 0x5A3E2C),
        .init(id: "face.beard",     name: "Full beard",   slot: .facialHair, price: 200, design: .facialHair(.beard),       tintHex: 0x4A3426),
    ]

    static let earrings: [CosmeticItem] = [
        .init(id: "ear.studs", name: "Studs",  slot: .earrings, price: 100, design: .earrings(.studs), tintHex: 0xE4E4EE),
        .init(id: "ear.hoops", name: "Hoops",  slot: .earrings, price: 140, design: .earrings(.hoops), tintHex: 0xD4AF37),
        .init(id: "ear.drops", name: "Drops",  slot: .earrings, price: 180, design: .earrings(.drops), tintHex: 0xD4AF37),
    ]

    static let chains: [CosmeticItem] = [
        .init(id: "chain.thin",    name: "Thin chain",  slot: .chain, price: 150, design: .chain(.thin),    tintHex: 0xD4AF37),
        .init(id: "chain.cuban",   name: "Cuban link",  slot: .chain, price: 260, design: .chain(.cuban),   tintHex: 0xD4AF37),
        .init(id: "chain.pendant", name: "Pendant",     slot: .chain, price: 350, design: .chain(.pendant), tintHex: 0xD4AF37),
    ]

    static func items(in slot: CosmeticSlot) -> [CosmeticItem] {
        all.filter { $0.slot == slot }
    }

    static func item(id: String) -> CosmeticItem? {
        all.first { $0.id == id }
    }
}

// MARK: - App catalogue

/// The other half of the shop. Unlike the hamster items these each drive a
/// real setting, so buying one has to actually change the app — a shop row
/// that unlocks nothing is worse than no row.
enum AppCosmeticKind: String, CaseIterable, Identifiable {
    case icon, theme, intro, sound
    var id: String { rawValue }

    var title: String {
        switch self {
        case .icon:  return "App icons"
        case .theme: return "Themes"
        case .intro: return "Intros"
        case .sound: return "Sounds"
        }
    }

    var symbol: String {
        switch self {
        case .icon:  return "app.badge"
        case .theme: return "paintpalette.fill"
        case .intro: return "sparkles"
        case .sound: return "speaker.wave.2.fill"
        }
    }
}

struct AppCosmeticItem: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let kind: AppCosmeticKind
    let price: Int
    /// Swatch shown in the shop tile.
    let previewHex: UInt32
    /// Free and owned from the start — the default in its category.
    var isDefault: Bool = false
}

enum AppCosmeticCatalogue {
    static let all: [AppCosmeticItem] = icons + themes + intros + sounds

    /// `id` doubles as the value written to `UIApplication.setAlternateIconName`,
    /// except for the default, which passes nil. The names must match the keys
    /// in `CFBundleAlternateIcons`.
    static let icons: [AppCosmeticItem] = [
        .init(id: "icon.default", name: "Glass",    detail: "The original",       kind: .icon, price: 0,   previewHex: 0x2563EB, isDefault: true),
        .init(id: "AppIconInk",   name: "Ink",      detail: "Warm dark",          kind: .icon, price: 450, previewHex: 0x231F1A),
        .init(id: "AppIconGold",  name: "Gold",     detail: "Streak gold",        kind: .icon, price: 500, previewHex: 0xB07407),
        .init(id: "AppIconMint",  name: "Mint",     detail: "Cool green",         kind: .icon, price: 500, previewHex: 0x12855C),
    ]

    static let themes: [AppCosmeticItem] = [
        .init(id: "theme.blue",   name: "Classic",  detail: "Progress blue",      kind: .theme, price: 0,   previewHex: 0x2563EB, isDefault: true),
        .init(id: "theme.plum",   name: "Plum",     detail: "Deep violet accent", kind: .theme, price: 380, previewHex: 0x7A3E8F),
        .init(id: "theme.teal",   name: "Teal",     detail: "Cool green accent",  kind: .theme, price: 380, previewHex: 0x0F766E),
        .init(id: "theme.clay",   name: "Clay",     detail: "Warm orange accent", kind: .theme, price: 420, previewHex: 0xB4531F),
    ]

    static let intros: [AppCosmeticItem] = [
        .init(id: "intro.classic", name: "Etched",  detail: "Traced and filled",  kind: .intro, price: 0,   previewHex: 0x53627A, isDefault: true),
        .init(id: "intro.script",  name: "Script",  detail: "Handwritten glass",  kind: .intro, price: 300, previewHex: 0x2563EB),
    ]

    static let sounds: [AppCosmeticItem] = [
        .init(id: "sound.default", name: "Default", detail: "The original tones", kind: .sound, price: 0,   previewHex: 0x2563EB, isDefault: true),
        .init(id: "sound.chime",   name: "Chime",   detail: "Softer, bell-like",  kind: .sound, price: 300, previewHex: 0x12855C),
    ]

    static func items(of kind: AppCosmeticKind) -> [AppCosmeticItem] {
        all.filter { $0.kind == kind }
    }

    static func item(id: String) -> AppCosmeticItem? {
        all.first { $0.id == id }
    }

    static func defaultItem(of kind: AppCosmeticKind) -> AppCosmeticItem {
        items(of: kind).first(where: \.isDefault) ?? items(of: kind)[0]
    }
}

// MARK: - Accent themes

/// A theme recolours the accent only. The meaning colours — green for correct,
/// red for wrong, gold for streaks — are deliberately not themeable: they carry
/// information, and letting a student repaint "correct" to red would be a
/// legibility bug sold as a feature.
enum AccentTheme: String, CaseIterable {
    case blue, plum, teal, clay

    init(itemID: String) {
        switch itemID {
        case "theme.plum": self = .plum
        case "theme.teal": self = .teal
        case "theme.clay": self = .clay
        default:           self = .blue
        }
    }

    var accent: Color {
        switch self {
        case .blue: return Color(lightHex: 0x2563EB, darkHex: 0x5B8DEF)
        case .plum: return Color(lightHex: 0x7A3E8F, darkHex: 0xB782C6)
        case .teal: return Color(lightHex: 0x0F766E, darkHex: 0x3FBFB2)
        case .clay: return Color(lightHex: 0xB4531F, darkHex: 0xE8925A)
        }
    }

    var accentSoft: Color {
        switch self {
        case .blue: return Color(lightHex: 0xE4EDFF, darkHex: 0x1B2942)
        case .plum: return Color(lightHex: 0xF3E7F7, darkHex: 0x2A1B31)
        case .teal: return Color(lightHex: 0xDDF2F0, darkHex: 0x0E2B29)
        case .clay: return Color(lightHex: 0xFCEADF, darkHex: 0x35190C)
        }
    }
}
