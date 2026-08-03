//
//  PromoCode.swift
//  LCVI DECA Study App
//
//  Codes that unlock shop content, for testing the shop without grinding out
//  the coins first.
//
//  **These are not a security boundary and are not meant to be one.**
//
//  As it happens neither code appears in the shipped binary as plain text, but
//  not for any reason worth relying on: Swift stores string literals of 15
//  UTF-8 bytes or fewer inline in the instruction stream rather than in
//  `__TEXT,__cstring`, and both of these are shorter than that. Checked
//  against the Release build — a 28-byte literal from this same target *is*
//  findable in it; these are not. Lengthen a code past 15 bytes and it becomes
//  plain text, and either way it is recoverable from a debugger in minutes.
//
//  So treat any code here as public. That is acceptable because everything
//  they unlock is cosmetic: the worst outcome is a student wearing a hat they
//  did not earn. Never gate anything behind one of these that would matter if
//  it were bypassed — question content, anything that costs money, anything
//  added later that does.
//

import Foundation

enum PromoCode: String, CaseIterable {
    /// Owns every shop item and tops the balance up, for walking the whole
    /// shop without earning first.
    case unlockEverything = "GLASSUNLOCK"
    /// Puts it all back: nothing owned, no coins, defaults reselected. The
    /// counterpart matters as much as the unlock — without it, testing the
    /// earning path again means deleting the app.
    case resetEverything = "GLASSRESET"

    /// Matched case- and whitespace-insensitively; nobody types a code exactly.
    init?(entry: String) {
        let cleaned = entry
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard let match = PromoCode.allCases.first(where: { $0.rawValue == cleaned }) else {
            return nil
        }
        self = match
    }

    var confirmation: String {
        switch self {
        case .unlockEverything: return "Everything unlocked, and coins topped up."
        case .resetEverything:  return "Reset. Nothing owned, no coins."
        }
    }

    /// Enough to buy anything without being so large the balance stops
    /// looking like a number.
    static let unlockGrant = 9_999
}
