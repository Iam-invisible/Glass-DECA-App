//
//  DECAEvents.swift
//  LCVI DECA Study App
//
//  The competitive event catalogue, keyed by the code students actually say
//  out loud — "I'm doing EIP", "we're in HTDM".
//
//  ⚠️ VERIFY BEFORE COMPETITION SEASON.
//  Event codes, names and — above all — which components run at which level
//  change between years and between regions. This catalogue is a good-faith
//  reference so the app can shape itself around a student's event; it is NOT
//  official DECA Ontario material, and the same disclaimer that governs the
//  question bank governs this. Check every entry against the current DECA
//  Ontario competitive event guidelines and correct this file — it is a plain
//  list precisely so that correcting it is a one-line edit with no other code
//  to touch.
//
//  Checked against deca.ca/v2/competitive-events and DECA Inc's guide in
//  July 2026. Corrected then: PEN added; QSRM removed (DECA Inc runs it,
//  Ontario does not list it); the entrepreneurship written block rebuilt (EBP
//  and ISP were not real codes, IBP was under Independent rather than
//  International Business Plan, and EIB/EFB/EBG were missing); IMC and the
//  professional selling events given the regional exam they actually have.
//
//  Still unverified, and the thing to ask an advisor about first: whether
//  Series, Principles and Team Decision Making run their roleplay at regionals
//  or advance on the exam alone. Ontario's own pages point both ways and it
//  varies by area, so those events are left as exam + roleplay at both levels —
//  the safer error, since it over-prepares rather than under-prepares.
//
//  Why per-level components exist: some events are not the same competition
//  twice. An IMC or professional selling competitor advances out of regionals
//  on a cluster exam and does not present until provincials — so they should be
//  pushed toward exam practice now and presentation rehearsal later. Modelling
//  each level separately is what makes that possible.
//

import Foundation

// MARK: - Components

/// What a student actually has to *do* at one level of competition.
struct EventComponents: Equatable, Codable {
    var hasExam = false
    var hasRoleplay = false
    var hasPresentation = false

    static let examOnly = EventComponents(hasExam: true)
    static let examAndRoleplay = EventComponents(hasExam: true, hasRoleplay: true)
    static let presentationOnly = EventComponents(hasPresentation: true)
    static let examAndPresentation = EventComponents(hasExam: true, hasPresentation: true)
    static let none = EventComponents()

    var summary: String {
        var parts: [String] = []
        if hasExam { parts.append("exam") }
        if hasRoleplay { parts.append("roleplay") }
        if hasPresentation { parts.append("presentation") }
        // Prepared written events submit ahead of the deadline and present at
        // provincials, so their regional column is genuinely empty. "No scored
        // components" read like something had gone wrong; this says what is
        // actually true.
        return parts.isEmpty ? "nothing to compete" : parts.joined(separator: " + ")
    }
}

// MARK: - Event

struct DECAEvent: Equatable, Identifiable, Codable {
    /// The abbreviation students use. Uppercase, and unique.
    let code: String
    let name: String
    let cluster: DECACluster
    let regional: EventComponents
    let provincial: EventComponents

    var id: String { code }

    /// True if an exam appears anywhere in the student's season.
    var hasAnyExam: Bool { regional.hasExam || provincial.hasExam }
    var hasAnyRoleplay: Bool { regional.hasRoleplay || provincial.hasRoleplay }
    var hasAnyPresentation: Bool { regional.hasPresentation || provincial.hasPresentation }

    /// One line describing the shape of the season, said plainly. When the
    /// two levels differ that difference *is* the headline.
    var formatSummary: String {
        if regional == provincial { return "Regionals and provincials: \(regional.summary)." }
        return "Regionals: \(regional.summary). Provincials: \(provincial.summary)."
    }
}

// MARK: - Catalogue

enum DECAEvents {

    /// Sentinel for a student who has not chosen yet. Never appears in
    /// `all`, so it can't be matched by a code search.
    static let undecidedCode = "UNDECIDED"

    static let all: [DECAEvent] = principles + individualSeries + teamDecisionMaking
        + personalFinance + businessOperations + projectManagement
        + entrepreneurshipWritten + integratedMarketing + professionalSelling

    // MARK: Principles — first-year events. Exam plus one roleplay.

    static let principles: [DECAEvent] = [
        DECAEvent(code: "PBM", name: "Principles of Business Management and Administration",
                  cluster: .businessManagement,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "PEN", name: "Principles of Entrepreneurship",
                  cluster: .entrepreneurship,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "PFN", name: "Principles of Finance",
                  cluster: .finance,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "PHT", name: "Principles of Hospitality and Tourism",
                  cluster: .hospitality,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        // Ontario restricts PMK to Grade 9. The catalogue has nowhere to say
        // that yet; the picker offers it to everyone.
        DECAEvent(code: "PMK", name: "Principles of Marketing",
                  cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
    ]

    // MARK: Individual series — exam plus roleplay at both levels.

    static let individualSeries: [DECAEvent] = [
        DECAEvent(code: "ACT", name: "Accounting Applications Series", cluster: .finance,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "AAM", name: "Apparel and Accessories Marketing Series", cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "ASM", name: "Automotive Services Marketing Series", cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "BFS", name: "Business Finance Series", cluster: .finance,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "BSM", name: "Business Services Marketing Series", cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "ENT", name: "Entrepreneurship Series", cluster: .entrepreneurship,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "FMS", name: "Food Marketing Series", cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "HLM", name: "Hotel and Lodging Management Series", cluster: .hospitality,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "HRM", name: "Human Resources Management Series", cluster: .businessManagement,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "MCS", name: "Marketing Communications Series", cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        // QSRM (Quick Serve Restaurant Management) was removed: DECA Inc runs
        // it, but it does not appear on Ontario's competitive events list.
        // If an Ontario region does offer it, restoring it is one line.
        DECAEvent(code: "RFSM", name: "Restaurant and Food Service Management Series", cluster: .hospitality,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "RMS", name: "Retail Merchandising Series", cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "SEM", name: "Sports and Entertainment Marketing Series", cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
    ]

    // MARK: Team decision making — exam plus a team case study.

    static let teamDecisionMaking: [DECAEvent] = [
        DECAEvent(code: "BLTDM", name: "Business Law and Ethics Team Decision Making",
                  cluster: .businessManagement,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "BTDM", name: "Buying and Merchandising Team Decision Making",
                  cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "ETDM", name: "Entrepreneurship Team Decision Making",
                  cluster: .entrepreneurship,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "FTDM", name: "Financial Services Team Decision Making",
                  cluster: .finance,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "HTDM", name: "Hospitality Services Team Decision Making",
                  cluster: .hospitality,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "MTDM", name: "Marketing Management Team Decision Making",
                  cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "STDM", name: "Sports and Entertainment Marketing Team Decision Making",
                  cluster: .marketing,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
        DECAEvent(code: "TTDM", name: "Travel and Tourism Team Decision Making",
                  cluster: .hospitality,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
    ]

    // MARK: Personal financial literacy

    static let personalFinance: [DECAEvent] = [
        DECAEvent(code: "PFL", name: "Personal Financial Literacy",
                  cluster: .personalFinancialLiteracy,
                  regional: .examAndRoleplay, provincial: .examAndRoleplay),
    ]

    // MARK: Business operations research — written report plus presentation.

    static let businessOperations: [DECAEvent] = [
        DECAEvent(code: "BOR", name: "Business Operations Research", cluster: .businessManagement,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "BMOR", name: "Buying and Merchandising Operations Research", cluster: .marketing,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "FOR", name: "Finance Operations Research", cluster: .finance,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "HTOR", name: "Hospitality and Tourism Operations Research", cluster: .hospitality,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "SEOR", name: "Sports and Entertainment Marketing Operations Research",
                  cluster: .marketing,
                  regional: .none, provincial: .presentationOnly),
    ]

    // MARK: Project management — written project plus presentation.

    static let projectManagement: [DECAEvent] = [
        DECAEvent(code: "PMBS", name: "Project Management — Business Solutions",
                  cluster: .businessManagement,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "PMCD", name: "Project Management — Career Development",
                  cluster: .businessManagement,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "PMCA", name: "Project Management — Community Awareness",
                  cluster: .marketing,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "PMCG", name: "Project Management — Community Giving",
                  cluster: .marketing,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "PMFL", name: "Project Management — Financial Literacy",
                  cluster: .personalFinancialLiteracy,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "PMSP", name: "Project Management — Sales Project",
                  cluster: .marketing,
                  regional: .none, provincial: .presentationOnly),
    ]

    // MARK: Entrepreneurship written events
    //
    // Prepared written events: a pitch deck is submitted ahead of the deadline
    // and presented live. Ontario lists no exam for these, and prepared written
    // events have no in-person requirement at regionals — which is why the
    // regional column is empty rather than a presentation.
    //
    // This block previously carried two codes that do not exist (EBP, and ISP
    // duplicating EIP) and had IBP under the wrong name: IBP is *International*
    // Business Plan, and Independent Business Plan is EIB.

    static let entrepreneurshipWritten: [DECAEvent] = [
        DECAEvent(code: "EIP", name: "Innovation Plan",
                  cluster: .entrepreneurship,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "ESB", name: "Start-Up Business Plan",
                  cluster: .entrepreneurship,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "EIB", name: "Independent Business Plan",
                  cluster: .entrepreneurship,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "IBP", name: "International Business Plan",
                  cluster: .entrepreneurship,
                  regional: .none, provincial: .presentationOnly),
        DECAEvent(code: "EFB", name: "Franchise Business Plan",
                  cluster: .entrepreneurship,
                  regional: .none, provincial: .presentationOnly),
        // EBG appears in DECA Inc's guide but not on Ontario's current list.
        // Kept because an Ontario student may still be entered in it; delete
        // this line if the advisor confirms Ontario does not run it.
        DECAEvent(code: "EBG", name: "Business Growth Plan",
                  cluster: .entrepreneurship,
                  regional: .none, provincial: .presentationOnly),
    ]

    // MARK: Integrated marketing campaigns — pitch deck plus presentation.
    //
    // These now carry an exam at regionals. Ontario advances IMC competitors on
    // a cluster exam alone, so a student who was told their event had no exam
    // was being pointed away from the only thing that gets them to provincials.

    static let integratedMarketing: [DECAEvent] = [
        DECAEvent(code: "IMCE", name: "Integrated Marketing Campaign — Event", cluster: .marketing,
                  regional: .examOnly, provincial: .presentationOnly),
        DECAEvent(code: "IMCP", name: "Integrated Marketing Campaign — Product", cluster: .marketing,
                  regional: .examOnly, provincial: .presentationOnly),
        DECAEvent(code: "IMCS", name: "Integrated Marketing Campaign — Service", cluster: .marketing,
                  regional: .examOnly, provincial: .presentationOnly),
    ]

    // MARK: Professional selling and consulting
    //
    // Same correction as IMC, and a larger one: these were modelled as having
    // no exam at all. Ontario advances them on a cluster exam at regionals and
    // has them write a multiple-choice test again at provincials, alongside a
    // submitted paper and a live presentation.
    //
    // `hasRoleplay` stays true at provincials on purpose. The judged
    // interaction is a sales call performed to a judge in role, so Quick Think
    // drills are exactly the right practice — and that flag is what keeps the
    // Quick Think dial on the Study screen for these students.

    static let professionalSelling: [DECAEvent] = [
        DECAEvent(code: "PSE", name: "Professional Selling", cluster: .marketing,
                  regional: .examOnly,
                  provincial: EventComponents(hasExam: true, hasRoleplay: true, hasPresentation: true)),
        DECAEvent(code: "FCE", name: "Financial Consulting", cluster: .finance,
                  regional: .examOnly,
                  provincial: EventComponents(hasExam: true, hasRoleplay: true, hasPresentation: true)),
        DECAEvent(code: "HTPS", name: "Hospitality and Tourism Professional Selling",
                  cluster: .hospitality,
                  regional: .examOnly,
                  provincial: EventComponents(hasExam: true, hasRoleplay: true, hasPresentation: true)),
    ]

    // MARK: - Lookup

    /// Exact match on the code, case- and whitespace-insensitive. This is the
    /// validator: anything it cannot resolve is not a real event.
    static func event(forCode raw: String) -> DECAEvent? {
        let needle = normalise(raw)
        guard !needle.isEmpty else { return nil }
        return all.first { $0.code == needle }
    }

    /// Suggestions while typing: code prefix first (what a student is most
    /// likely typing), then anything whose name contains the text.
    static func suggestions(for raw: String,
                            cluster: DECACluster? = nil,
                            limit: Int = 5) -> [DECAEvent] {
        let pool = cluster.map { c in all.filter { $0.cluster == c } } ?? all
        let needle = normalise(raw)
        // With a cluster in hand an empty field still has something useful to
        // say: here is everything you could be entering.
        guard !needle.isEmpty else { return Array(pool.prefix(limit)) }
        let byCode = pool.filter { $0.code.hasPrefix(needle) }
        let byName = pool.filter {
            !$0.code.hasPrefix(needle) && $0.name.uppercased().contains(needle)
        }
        return Array((byCode + byName).prefix(limit))
    }

    /// Every event a given cluster can enter.
    static func events(in cluster: DECACluster) -> [DECAEvent] {
        all.filter { $0.cluster == cluster }
    }

    static func normalise(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}
