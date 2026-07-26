//
//  PerformanceIndicatorService.swift
//  LCVI DECA Study App
//
//  Tracks mastery per DECA performance indicator from both question answers
//  and roleplay practice.
//

import CoreData
import Foundation

struct IndicatorStat: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let text: String
    let cluster: DECACluster
    let timesAnswered: Int
    let timesCorrect: Int
    let roleplayCount: Int
    let masteryScore: Double
    let lastPracticedAt: Date?

    var accuracy: Double { timesAnswered == 0 ? 0 : Double(timesCorrect) / Double(timesAnswered) }
    var band: MasteryBand { MasteryBand.from(score: masteryScore) }
}

@MainActor
final class PerformanceIndicatorService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames

    init(context: NSManagedObjectContext) { self.ctx = context }

    // MARK: - Recording

    func recordAnswer(indicators: [String], cluster: DECACluster, correct: Bool, at date: Date = Date()) {
        for code in indicators {
            let row = row(for: code) ?? makeRow(code: code, cluster: cluster)
            row.timesAnswered += 1
            if correct { row.timesCorrect += 1 }
            row.lastPracticedAt = date
            row.masteryScore = Self.score(answered: Int(row.timesAnswered),
                                          correct: Int(row.timesCorrect),
                                          roleplays: Int(row.roleplayCount))
        }
        try? ctx.save()
    }

    func recordRoleplay(indicators: [String], cluster: DECACluster, at date: Date = Date()) {
        for code in indicators {
            let row = row(for: code) ?? makeRow(code: code, cluster: cluster)
            row.roleplayCount += 1
            row.lastPracticedAt = date
            row.masteryScore = Self.score(answered: Int(row.timesAnswered),
                                          correct: Int(row.timesCorrect),
                                          roleplays: Int(row.roleplayCount))
        }
        try? ctx.save()
    }

    /// Accuracy weighted by how much evidence exists, plus a small roleplay
    /// bonus. Few attempts pull the score toward the middle so a single lucky
    /// answer never reads as "mastered".
    static func score(answered: Int, correct: Int, roleplays: Int) -> Double {
        guard answered > 0 || roleplays > 0 else { return 0 }
        let accuracy = answered == 0 ? 0.5 : Double(correct) / Double(answered)
        let confidence = min(1.0, Double(answered) / 8.0)
        let base = 0.5 + (accuracy - 0.5) * confidence
        let roleplayBonus = min(0.08, Double(roleplays) * 0.02)
        return min(1.0, max(0.0, base * (answered == 0 ? 0.4 : 1.0) + roleplayBonus))
    }

    // MARK: - Queries

    func row(for code: String) -> CDPIMastery? {
        ctx.fetchAll(CDPIMastery.self, entity: names.piMastery,
                     predicate: NSPredicate(format: "code == %@", code),
                     limit: 1).first
    }

    func stats(cluster: DECACluster? = nil, practicedOnly: Bool = false) -> [IndicatorStat] {
        let rows = ctx.fetchAll(CDPIMastery.self, entity: names.piMastery)
        return rows.compactMap { row -> IndicatorStat? in
            guard let code = row.code else { return nil }
            let rowCluster = row.clusterValue
            if let cluster, rowCluster != cluster { return nil }
            if practicedOnly && row.timesAnswered == 0 && row.roleplayCount == 0 { return nil }
            return IndicatorStat(
                code: code,
                text: row.text ?? SeedIndicators.text(forCode: code) ?? code,
                cluster: rowCluster,
                timesAnswered: Int(row.timesAnswered),
                timesCorrect: Int(row.timesCorrect),
                roleplayCount: Int(row.roleplayCount),
                masteryScore: row.masteryScore,
                lastPracticedAt: row.lastPracticedAt
            )
        }
        .sorted { $0.code < $1.code }
    }

    func strongest(cluster: DECACluster?, limit: Int = 3) -> [IndicatorStat] {
        stats(cluster: cluster, practicedOnly: true)
            .sorted { $0.masteryScore > $1.masteryScore }
            .prefix(limit)
            .map { $0 }
    }

    func weakest(cluster: DECACluster?, limit: Int = 3) -> [IndicatorStat] {
        let practiced = stats(cluster: cluster, practicedOnly: true)
            .filter { $0.timesAnswered > 0 }
            .sorted { $0.masteryScore < $1.masteryScore }
        return Array(practiced.prefix(limit))
    }

    /// Indicators worth studying next: never practised, or practised poorly.
    func suggested(cluster: DECACluster?, limit: Int = 4) -> [IndicatorStat] {
        let all = stats(cluster: cluster)
        let weak = all.filter { $0.timesAnswered > 0 && $0.masteryScore < 0.68 }
            .sorted { $0.masteryScore < $1.masteryScore }
        let untouched = all.filter { $0.timesAnswered == 0 && $0.roleplayCount == 0 }
        return Array((weak + untouched).prefix(limit))
    }

    func weakIndicatorCodes(cluster: DECACluster?, threshold: Double = 0.68) -> Set<String> {
        Set(stats(cluster: cluster)
            .filter { $0.masteryScore < threshold }
            .map { $0.code })
    }

    private func makeRow(code: String, cluster: DECACluster) -> CDPIMastery {
        let row = ctx.insert(CDPIMastery.self, entity: names.piMastery)
        row.code = code
        row.text = SeedIndicators.text(forCode: code) ?? code
        row.cluster = cluster.rawValue
        return row
    }
}
