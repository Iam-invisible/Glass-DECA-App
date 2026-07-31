//
//  SeedRoleplays.swift
//  LCVI DECA Study App
//
//  Sample roleplay scenarios written for this app.
//  These are original practice scenarios modelled on the DECA roleplay format —
//  they are not official DECA Ontario or DECA Inc. competition materials.
//
//  Authored against cluster × event format, not per event code.
//  ------------------------------------------------------------
//  Selection is cluster-keyed: `prompts(for:)` filters on cluster alone, and
//  `eventType` is only ever displayed. Ontario's ~50 events map onto 6 clusters
//  and 5 roleplay-bearing formats, so writing one set per event would have
//  produced roughly eight near-identical scenarios for every genuinely distinct
//  one. Writing per cluster × format instead gives a student more variety, not
//  less — a marketing competitor sees Principles, Series, Team Decision Making
//  and Professional Selling shapes rather than the same case eight times.
//
//  The format decides prep and presentation time, team size and how the
//  situation is framed, which is why `RoleplayFormat` carries those rather than
//  each scenario repeating them.
//
//  Each cluster lives in Data/Roleplays/SeedRoleplays+<Cluster>.swift.
//

import Foundation

/// The five Ontario event formats that actually involve a live judged
/// interaction. Prepared written events (Operations Research, Project
/// Management, the entrepreneurship plans, Integrated Marketing Campaign) are
/// presentations of submitted work and are not roleplays, so they are absent.
enum RoleplayFormat {
    case principles
    case individualSeries
    case teamDecisionMaking
    case personalFinancialLiteracy
    case professionalSelling

    /// What the student sees on the scenario card.
    var label: String {
        switch self {
        case .principles:                 return "Principles"
        case .individualSeries:           return "Individual Series"
        case .teamDecisionMaking:         return "Team Decision Making"
        case .personalFinancialLiteracy:  return "Personal Financial Literacy"
        case .professionalSelling:        return "Professional Selling"
        }
    }

    /// Minutes of preparation the real event allows.
    var prepMinutes: Int {
        switch self {
        case .teamDecisionMaking: return 30
        default:                  return 10
        }
    }

    /// Minutes in front of the judge.
    var presentMinutes: Int {
        switch self {
        case .teamDecisionMaking, .professionalSelling: return 15
        default:                                        return 10
        }
    }
}

/// Builds one scenario. `format` supplies the timings so a scenario can never
/// drift out of step with the event it is preparing a student for.
///
/// Deliberately internal rather than private: the cluster files are extensions
/// of `SeedRoleplays` in their own files, and a `private` helper is visible
/// only inside the file that declares it.
func rp(_ key: String,
        _ title: String,
        _ cluster: DECACluster,
        _ format: RoleplayFormat,
        _ difficulty: Difficulty,
        situation: String,
        userRole: String,
        judgeRole: String,
        pis: [String]) -> RoleplayPromptData {
    RoleplayPromptData(
        id: UUID.stable("roleplay-\(key)"),
        title: title,
        cluster: cluster,
        eventType: format.label,
        situation: situation,
        userRole: userRole,
        judgeRole: judgeRole,
        performanceIndicators: pis,
        difficulty: difficulty,
        prepMinutes: format.prepMinutes,
        presentMinutes: format.presentMinutes,
        isSample: true
    )
}

enum SeedRoleplays {

    /// Every bundled scenario. The cluster arrays are defined in
    /// Data/Roleplays/SeedRoleplays+<Cluster>.swift.
    static let all: [RoleplayPromptData] = marketing + finance + hospitality
        + businessManagement + entrepreneurship + personalFinancialLiteracy

    static func prompts(for cluster: DECACluster) -> [RoleplayPromptData] {
        all.filter { $0.cluster == cluster }
    }
}
