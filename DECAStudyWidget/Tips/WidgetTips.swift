//
//  WidgetTips.swift
//  DECAStudyWidget
//
//  One fact a day, from the student's own cluster.
//
//  These live in the widget target rather than the app because only the widget
//  reads them, and the extension cannot import the app (§4). Putting them here
//  keeps one copy: the alternative — the app owning them and writing today's
//  line into the snapshot — would leave the widget unable to build a timeline
//  past today whenever the app had not been opened, which is exactly the
//  student this widget exists for.
//
//  ⚠️ Same disclaimer as the question bank. These are original study notes
//  written for this app, not official DECA Ontario or DECA Inc. material.
//  Correct anything that drifts from the current guidelines — the arrays are
//  plain lists precisely so that correcting one is a one-line edit.
//
//  Roughly 100 per cluster. `Scripts/check_tips.py` enforces the count, the
//  length window a widget can actually show, and that no two are duplicates.
//

import Foundation

enum WidgetTips {

    /// Every tip for one cluster, keyed by `DECACluster.rawValue` as the app
    /// writes it into the snapshot.
    static func all(for clusterKey: String) -> [String] {
        switch clusterKey {
        case "marketing":                 return marketing
        case "finance":                   return finance
        case "hospitality":               return hospitality
        case "businessManagement":        return businessManagement
        case "entrepreneurship":          return entrepreneurship
        case "personalFinancialLiteracy": return personalFinance
        default:                          return marketing
        }
    }

    /// Today's tip.
    ///
    /// Two properties matter and they pull in opposite directions. It has to be
    /// stable — the same line all day, on every refresh and on both widgets, or
    /// a student sees it change while they look at it. And it has to differ
    /// between students, so a class does not spend the term reciting the same
    /// line to each other on the same morning.
    ///
    /// A seeded *permutation* rather than a seeded pick. Hashing the day into
    /// an index gives a random tip each morning but repeats one long before the
    /// list is exhausted — with 100 tips there is about a 26% chance of a
    /// repeat inside a fortnight. Walking a shuffled order shows all 100 before
    /// any comes round again, and the salt makes that order this install's own.
    static func tip(clusterKey: String, salt: UInt64, on date: Date = Date()) -> String {
        let pool = all(for: clusterKey)
        guard !pool.isEmpty else { return "" }

        // The order is per cluster as well as per install, so switching cluster
        // does not resume someone else's position in a different list.
        var rng = TipRandom(seed: salt ^ stableHash(clusterKey))
        var order = Array(pool.indices)
        for i in stride(from: order.count - 1, to: 0, by: -1) {
            order.swapAt(i, Int(rng.next() % UInt64(i + 1)))
        }
        return pool[order[dayIndex(date) % order.count]]
    }

    /// Whole days since the reference date, in the student's own time zone, so
    /// the tip turns over at their midnight rather than at UTC's.
    static func dayIndex(_ date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        let days = Int(start.timeIntervalSinceReferenceDate / 86_400)
        return max(0, days)
    }

    /// FNV-1a. `hashValue` is salted per process and would hand back a
    /// different order on every launch (§8.35).
    private static func stableHash(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }
}

/// A seedable generator. `SystemRandomNumberGenerator` cannot be seeded, and
/// this needs the same order tomorrow that it produced today.
///
/// SplitMix64, the same one the app uses to shuffle answer choices. Duplicated
/// rather than shared because the extension cannot import the app — the same
/// reason `WidgetSnapshot` exists twice.
struct TipRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
