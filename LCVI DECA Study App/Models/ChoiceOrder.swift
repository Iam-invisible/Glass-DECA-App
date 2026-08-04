//
//  ChoiceOrder.swift
//  LCVI DECA Study App
//
//  Shuffling a question's four choices for one presentation, so the position of
//  the right answer cannot be memorised.
//
//  The bank's stored order is *canonical* and never changes: it is what Core
//  Data holds, what an export writes, and what every review screen speaks. A
//  shuffle produces a throwaway copy carrying `canonicalOrder`, the map back.
//  Two funnels — `AppStore.recordAnswer` and `MockExamService.saveAttempt` —
//  convert to canonical before anything is written, which is why no schema
//  change is needed and why an existing answer, mistake or attempt keeps
//  meaning exactly what it meant before.
//

import Foundation

/// A seedable generator.
///
/// `SystemRandomNumberGenerator` cannot be seeded and `Hasher` is salted per
/// process (§8.35), so neither can produce the same order twice. A review
/// screen replaying an answered question needs exactly that.
struct SplitMix64: RandomNumberGenerator {
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

extension UUID {
    /// A launch-stable 64-bit digest of this UUID.
    ///
    /// FNV-1a rather than `hashValue`, which is salted per process and so
    /// differs between launches (§8.35).
    var stableSeed: UInt64 {
        withUnsafeBytes(of: uuid) { raw in
            var hash: UInt64 = 0xCBF2_9CE4_8422_2325        // FNV-1a offset basis
            for byte in raw {
                hash ^= UInt64(byte)
                hash = hash &* 0x0000_0100_0000_01B3        // FNV-1a prime
            }
            return hash
        }
    }
}

extension QuestionData {

    /// The order a question sits in when nothing has been shuffled.
    static let identityOrder = [0, 1, 2, 3]

    /// True when this copy was built for one presentation and its choices are
    /// no longer in the bank's order.
    var isPresented: Bool { canonicalOrder != Self.identityOrder }

    /// The slot the bank stores for a slot the student saw.
    ///
    /// Out-of-range input passes through unchanged, which is what keeps the
    /// mock exam's `-1` sentinel for "unanswered" meaning unanswered.
    func canonicalIndex(for displaySlot: Int) -> Int {
        guard canonicalOrder.indices.contains(displaySlot) else { return displaySlot }
        return canonicalOrder[displaySlot]
    }

    /// This question's correct answer in the bank's own ordering.
    var canonicalCorrectIndex: Int { canonicalIndex(for: correctIndex) }

    /// The same question with its choices shuffled for one presentation.
    ///
    /// `salt` is shared across a session so one session is one shuffle basis,
    /// while each question still lands in its own order. Anything that is not
    /// a well-formed four-choice question is returned untouched rather than
    /// risked — an imported bank is only sanitised at `bank.add`/`update`
    /// (§8.26), and a question that predates the rationale field carries none.
    func presented(salt: UInt64) -> QuestionData {
        let base = canonical()
        guard base.choices.count == 4,
              base.choiceRationales.isEmpty || base.choiceRationales.count == 4,
              (0..<4).contains(base.correctIndex) else { return base }

        var rng = SplitMix64(seed: base.id.stableSeed ^ salt)
        var order = Self.identityOrder
        for i in stride(from: order.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            order.swapAt(i, j)
        }
        return base.reordered(to: order)
    }

    /// This question with its choices back in the order the bank stores.
    ///
    /// Safe to call on a question that was never shuffled, and safe to call
    /// twice — which is what lets both funnels normalise without checking.
    func canonical() -> QuestionData {
        guard isPresented, canonicalOrder.count == choices.count else { return self }

        var restoredChoices = choices
        var restoredRationales = choiceRationales
        let hasRationales = choiceRationales.count == choices.count

        for (displaySlot, canonicalSlot) in canonicalOrder.enumerated() {
            restoredChoices[canonicalSlot] = choices[displaySlot]
            if hasRationales {
                restoredRationales[canonicalSlot] = choiceRationales[displaySlot]
            }
        }

        var copy = self
        copy.choices = restoredChoices
        copy.choiceRationales = restoredRationales
        copy.correctIndex = canonicalCorrectIndex
        copy.canonicalOrder = Self.identityOrder
        return copy
    }

    /// Builds the presented copy. `order[displaySlot] == canonicalSlot`.
    private func reordered(to order: [Int]) -> QuestionData {
        var copy = self
        copy.choices = order.map { choices[$0] }
        if choiceRationales.count == choices.count {
            copy.choiceRationales = order.map { choiceRationales[$0] }
        }
        copy.correctIndex = order.firstIndex(of: correctIndex) ?? correctIndex
        copy.canonicalOrder = order
        return copy
    }
}

extension Array where Element == QuestionData {
    /// Shuffles every question's choices against one shared salt.
    func presented(salt: UInt64 = .random(in: .min ... .max)) -> [QuestionData] {
        map { $0.presented(salt: salt) }
    }
}
