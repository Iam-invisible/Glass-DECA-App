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
    case starstruck, yes
    case sad, disappointed, no, nervous, confused, curious
    case shocked, dizzy, dead
    case angry, furious, meh, unamused
    case sleepy, thinking

    var imageName: String { "bunny-\(rawValue)" }
}

// MARK: - Events

/// Something the student did that is worth a face.
///
/// Three cases carry what actually happened rather than just that it happened.
/// Without that, one right answer drew the same face as unlocking an
/// achievement, and a mock scored 12% drew the same face as one scored 95% —
/// which makes the companion feel like it is not watching.
enum BunnyEvent {
    /// `run` is how many correct in a row, this one included.
    case correctAnswer(run: Int)
    /// `run` is how many wrong in a row, this one included.
    case wrongAnswer(run: Int)
    case goalMet
    case streakMilestone
    case achievement
    case purchase
    case cantAfford
    case sessionFinished
    case mockFinished(percent: Int)
    case opened
    case tabChanged
    case idle

    /// Candidates to pick from. `randomElement` is uniform, so a face that
    /// should dominate is listed more than once rather than weighted.
    ///
    /// The registers are deliberate. Celebration climbs with the size of the
    /// thing — `starstruck` is reserved for a run, a milestone or an unlock,
    /// so a single right answer cannot produce the app's biggest face. And
    /// nothing aimed at the student is ever harsher than concern: a wrong
    /// answer gets confusion, then disappointment *in the question*, never
    /// blame.
    var moods: [BunnyMood] {
        switch self {
        case .correctAnswer(let run):
            // A run earns the big face; one right answer does not.
            if run >= 5 { return [.starstruck, .starstruck, .yes] }
            if run >= 3 { return [.starstruck, .happy, .yes] }
            return [.happy, .happy, .yes, .content]

        case .wrongAnswer(let run):
            // Climbing concern, not climbing blame. The exasperation at the
            // top is at the questions, shared with the student — it is rare
            // enough (five wrong in a row) to read as sympathy.
            if run >= 5 { return [.furious, .angry, .nervous] }
            if run >= 3 { return [.nervous, .sad, .disappointed] }
            if run == 2 { return [.disappointed, .confused, .no] }
            return [.confused, .no, .curious]

        case .mockFinished(let percent):
            // A mock is the one place a bad result should read as dazed rather
            // than as a shrug — it is an hour of work, and `content` after 12%
            // would be the companion not paying attention.
            if percent >= 80 { return [.starstruck, .shocked, .yes] }
            if percent >= 50 { return [.happy, .content, .yes] }
            return [.dizzy, .dead, .nervous]

        case .goalMet:         return [.happy, .happy, .starstruck, .yes]
        case .streakMilestone: return [.starstruck, .starstruck, .happy, .yes]
        // Surprise is the honest reaction to an unlock you did not see coming.
        case .achievement:     return [.starstruck, .starstruck, .shocked, .yes]
        case .purchase:        return [.starstruck, .happy, .yes, .content]
        // Aimed at the price, not at the person.
        case .cantAfford:      return [.no, .meh, .unamused]
        case .sessionFinished: return [.content, .calm, .happy]
        case .opened:          return [.happy, .content, .curious, .calm]
        // A tap is not news. `neutral` and `blank` were in here and meant the
        // bunny could answer a deliberate interaction by going expressionless,
        // which reads as broken rather than as calm.
        case .tabChanged:      return [.curious, .thinking]
        case .idle:            return [.neutral, .blank, .thinking, .calm, .sleepy, .unamused, .curious]
        }
    }

    /// How long the face holds before drifting back to idle.
    var duration: TimeInterval {
        switch self {
        case .achievement, .streakMilestone, .goalMet, .purchase: return 3.0
        case .mockFinished, .sessionFinished:                     return 2.6
        case .tabChanged:                                         return 1.1
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
