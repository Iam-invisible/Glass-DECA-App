//
//  Bunny.swift
//  LCVI DECA Study App
//
//  The bunny companion: a bought sprite that reacts to what the student does.
//
//  It is decoration with one job — make the app feel like it noticed. So the
//  design rule is that it reacts to things the student *did*, never to things
//  it wants them to do. No nagging, no "come back", no guilt. A study app that
//  makes a character sad at you is a different and worse app.
//
//  Reactions carry a small set of candidate moods rather than one, and pick at
//  random, because the same face every single time stops reading as a reaction
//  within about a dozen questions.
//

import SwiftUI

// MARK: - Moods

/// One sprite each, in `Resources/Bunny/`. Raw values are the filenames minus
/// the `bunny-` prefix, so a mood with no artwork fails to load rather than
/// silently drawing the wrong face.
enum BunnyMood: String, CaseIterable {
    case happy, content, calm, neutral, blank
    case starstruck, love, affection, pleased, yes
    case sad, disappointed, no, nervous, confused, curious
    case shocked, dizzy, dead
    case angry, furious, meh, unamused
    case sleepy, thinking, silly

    var imageName: String { "bunny-\(rawValue)" }
}

// MARK: - Events

/// Something the student did that is worth a face.
enum BunnyEvent {
    case correctAnswer
    case wrongAnswer
    case goalMet
    case streakMilestone
    case achievement
    case purchase
    case cantAfford
    case sessionFinished
    case mockFinished
    case opened
    case idle

    /// Candidates to pick from. Ordered loosely by how often each should come
    /// up — `randomElement` is uniform, so a mood that should dominate appears
    /// more than once rather than being weighted separately.
    var moods: [BunnyMood] {
        switch self {
        case .correctAnswer:   return [.happy, .happy, .yes, .starstruck, .pleased, .content]
        case .wrongAnswer:     return [.no, .disappointed, .confused, .nervous, .sad]
        case .goalMet:         return [.starstruck, .happy, .yes, .content]
        case .streakMilestone: return [.love, .starstruck, .happy]
        case .achievement:     return [.starstruck, .starstruck, .love, .affection]
        case .purchase:        return [.love, .affection, .pleased, .starstruck]
        case .cantAfford:      return [.no, .meh, .unamused, .nervous]
        case .sessionFinished: return [.content, .calm, .happy, .pleased]
        case .mockFinished:    return [.shocked, .content, .starstruck, .dizzy]
        case .opened:          return [.happy, .content, .curious, .calm]
        case .idle:            return [.neutral, .blank, .thinking, .calm, .sleepy, .unamused, .curious]
        }
    }

    /// How long the face holds before drifting back to idle.
    var duration: TimeInterval {
        switch self {
        case .achievement, .streakMilestone, .goalMet, .purchase: return 3.0
        case .mockFinished, .sessionFinished:                     return 2.6
        case .idle:                                               return 0
        default:                                                  return 1.8
        }
    }

    /// Big moments get a hop; a right answer gets a nudge. Reused as the
    /// spring's displacement so the motion matches the size of the news.
    var hop: CGFloat {
        switch self {
        case .achievement, .streakMilestone, .goalMet, .purchase: return 12
        case .correctAnswer, .mockFinished, .sessionFinished:     return 7
        case .wrongAnswer, .cantAfford:                           return 0
        default:                                                  return 0
        }
    }

    /// A refusal shakes rather than hops — same vocabulary as the shop tile.
    var shakes: Bool {
        switch self {
        case .wrongAnswer, .cantAfford: return true
        default:                        return false
        }
    }
}

// MARK: - Ownership

enum BunnyCompanion {
    /// The shop item id. Matches `AppCosmeticCatalogue.companions`.
    static let itemID = "companion.bunny"
    static let price = 600
}
