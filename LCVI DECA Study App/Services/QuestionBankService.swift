//
//  QuestionBankService.swift
//  LCVI DECA Study App
//
//  Owns the local question bank: seeding, CRUD, duplicate detection and queries.
//

import CoreData
import Foundation

@MainActor
final class QuestionBankService {
    private let ctx: NSManagedObjectContext
    private let names = AppModel.entityNames

    /// Bump when bundled sample content changes so existing installs pick it up.
    ///
    /// 2 — per-choice rationales, and the corrections that came with writing
    ///     them. A bump alone is not enough: see `refreshSampleContent()`.
    static let seedVersion = 2

    init(context: NSManagedObjectContext) {
        self.ctx = context
    }

    // MARK: - Seeding

    /// Inserts bundled sample content that isn't present yet. Safe to call on
    /// every launch — stable UUIDs prevent duplicates and user edits survive.
    @discardableResult
    func seedIfNeeded(force: Bool = false) -> Int {
        var inserted = 0
        let existingIDs = Set(allQuestionEntities().compactMap { $0.id })

        for data in SeedQuestions.all where force || !existingIDs.contains(data.id) {
            if existingIDs.contains(data.id) { continue }
            let obj = ctx.insert(CDQuestion.self, entity: names.question)
            obj.apply(data)
            inserted += 1
        }

        let existingPromptIDs = Set(allRoleplayEntities().compactMap { $0.id })
        for data in SeedRoleplays.all where !existingPromptIDs.contains(data.id) {
            let obj = ctx.insert(CDRoleplayPrompt.self, entity: names.roleplayPrompt)
            obj.apply(data)
            inserted += 1
        }

        // Make sure every seeded indicator has a mastery row so Progress can
        // show "not started" instead of hiding the indicator entirely.
        let existingCodes = Set(ctx.fetchAll(CDPIMastery.self, entity: names.piMastery).compactMap { $0.code })
        for pi in SeedIndicators.all where !existingCodes.contains(pi.code) {
            let obj = ctx.insert(CDPIMastery.self, entity: names.piMastery)
            obj.code = pi.code
            obj.text = pi.text
            obj.cluster = pi.cluster.rawValue
            obj.masteryScore = 0
        }

        if ctx.hasChanges { try? ctx.save() }
        return inserted
    }

    /// Re-applies bundled content onto sample rows that already exist.
    ///
    /// `seedIfNeeded` only ever inserts, so a question that shipped in an
    /// earlier build never picks up a corrected explanation or newly written
    /// rationales — the stable IDs that stop duplicates also stop updates.
    /// This closes that gap and runs only on a seed-version bump.
    ///
    /// It touches rows still flagged `isSample`. Anything the student wrote
    /// themselves is untouched, and bookmarks survive on the rows it does
    /// rewrite, because a bookmark belongs to the student rather than to the
    /// content.
    func refreshSampleContent() {
        let seedsByID = Dictionary(SeedQuestions.all.map { ($0.id, $0) },
                                   uniquingKeysWith: { first, _ in first })
        for entity in allQuestionEntities() {
            guard entity.isSample,
                  let id = entity.id,
                  let seed = seedsByID[id] else { continue }
            let bookmarked = entity.isBookmarked
            entity.apply(seed)
            entity.isBookmarked = bookmarked
        }

        let promptsByID = Dictionary(SeedRoleplays.all.map { ($0.id, $0) },
                                     uniquingKeysWith: { first, _ in first })
        for entity in allRoleplayEntities() {
            guard entity.isSample,
                  let id = entity.id,
                  let seed = promptsByID[id] else { continue }
            entity.apply(seed)
        }

        if ctx.hasChanges { try? ctx.save() }
    }

    // MARK: - Queries

    func allQuestionEntities() -> [CDQuestion] {
        ctx.fetchAll(CDQuestion.self, entity: names.question,
                     sort: [NSSortDescriptor(key: "createdAt", ascending: false)])
    }

    func allQuestions() -> [QuestionData] {
        allQuestionEntities().map(\.asData)
    }

    func questionCount() -> Int { ctx.count(entity: names.question) }

    func bookmarkedCount(cluster: DECACluster? = nil) -> Int {
        if let cluster {
            return ctx.count(entity: names.question,
                             predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                                NSPredicate(format: "isBookmarked == YES"),
                                NSPredicate(format: "cluster == %@", cluster.rawValue)
                             ]))
        }
        return ctx.count(entity: names.question,
                         predicate: NSPredicate(format: "isBookmarked == YES"))
    }

    func questions(in cluster: DECACluster) -> [QuestionData] {
        ctx.fetchAll(CDQuestion.self, entity: names.question,
                     predicate: NSPredicate(format: "cluster == %@", cluster.rawValue))
            .map(\.asData)
    }

    func bookmarkedQuestions(cluster: DECACluster? = nil) -> [QuestionData] {
        var predicates = [NSPredicate(format: "isBookmarked == YES")]
        if let cluster { predicates.append(NSPredicate(format: "cluster == %@", cluster.rawValue)) }
        return ctx.fetchAll(CDQuestion.self, entity: names.question,
                            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates),
                            sort: [NSSortDescriptor(key: "createdAt", ascending: false)])
            .map(\.asData)
    }

    func entity(for id: UUID) -> CDQuestion? {
        ctx.fetchAll(CDQuestion.self, entity: names.question,
                     predicate: NSPredicate(format: "id == %@", id as CVarArg),
                     limit: 1).first
    }

    func question(for id: UUID) -> QuestionData? { entity(for: id)?.asData }

    func questions(for ids: [UUID]) -> [QuestionData] {
        guard !ids.isEmpty else { return [] }
        let found = ctx.fetchAll(CDQuestion.self, entity: names.question,
                                 predicate: NSPredicate(format: "id IN %@", ids))
        let byID = Dictionary(uniqueKeysWithValues: found.compactMap { q -> (UUID, QuestionData)? in
            guard let id = q.id else { return nil }
            return (id, q.asData)
        })
        return ids.compactMap { byID[$0] }
    }

    /// All distinct tags across the bank, alphabetised.
    func allTags(cluster: DECACluster? = nil) -> [String] {
        var set = Set<String>()
        for q in allQuestionEntities() {
            if let cluster, q.clusterValue != cluster { continue }
            q.tagList.forEach { set.insert($0) }
        }
        return set.sorted()
    }

    func allIndicatorCodes(cluster: DECACluster? = nil) -> [String] {
        var set = Set<String>()
        for q in allQuestionEntities() {
            if let cluster, q.clusterValue != cluster { continue }
            q.indicatorList.forEach { set.insert($0) }
        }
        return set.sorted()
    }

    func clusterCounts() -> [DECACluster: Int] {
        var counts: [DECACluster: Int] = [:]
        for q in allQuestionEntities() {
            counts[q.clusterValue, default: 0] += 1
        }
        return counts
    }

    // MARK: - Mutations

    @discardableResult
    func add(_ data: QuestionData) -> Bool {
        let obj = ctx.insert(CDQuestion.self, entity: names.question)
        obj.apply(data)
        obj.createdAt = Date()
        return save()
    }

    @discardableResult
    func update(_ data: QuestionData) -> Bool {
        guard let obj = entity(for: data.id) else { return add(data) }
        obj.apply(data)
        return save()
    }

    @discardableResult
    func setBookmarked(_ bookmarked: Bool, questionID: UUID) -> Bool {
        guard let obj = entity(for: questionID) else { return false }
        obj.isBookmarked = bookmarked
        return save()
    }

    @discardableResult
    func toggleBookmark(questionID: UUID) -> Bool? {
        guard let obj = entity(for: questionID) else { return nil }
        obj.isBookmarked.toggle()
        return save() ? obj.isBookmarked : nil
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        guard let obj = entity(for: id) else { return false }
        ctx.delete(obj)
        // Clean up dependent rows so stats don't reference a missing question.
        for r in ctx.fetchAll(CDSRRecord.self, entity: names.srRecord,
                              predicate: NSPredicate(format: "questionID == %@", id as CVarArg)) {
            ctx.delete(r)
        }
        for m in ctx.fetchAll(CDMistake.self, entity: names.mistake,
                              predicate: NSPredicate(format: "questionID == %@", id as CVarArg)) {
            ctx.delete(m)
        }
        return save()
    }

    func deleteAllQuestions() {
        for q in allQuestionEntities() { ctx.delete(q) }
        save()
    }

    // MARK: - Duplicate detection

    /// Returns the existing question whose normalised text matches, if any.
    func duplicate(of data: QuestionData, excluding id: UUID? = nil) -> QuestionData? {
        let fp = data.fingerprint
        guard !fp.isEmpty else { return nil }
        let matches = ctx.fetchAll(CDQuestion.self, entity: names.question,
                                   predicate: NSPredicate(format: "fingerprint == %@", fp))
        return matches.first { $0.id != id }?.asData
    }

    // MARK: - Roleplays

    func allRoleplayEntities() -> [CDRoleplayPrompt] {
        ctx.fetchAll(CDRoleplayPrompt.self, entity: names.roleplayPrompt,
                     sort: [NSSortDescriptor(key: "title", ascending: true)])
    }

    func roleplays(for cluster: DECACluster? = nil) -> [RoleplayPromptData] {
        allRoleplayEntities()
            .map(\.asData)
            .filter { cluster == nil || $0.cluster == cluster }
    }

    func roleplay(for id: UUID) -> RoleplayPromptData? {
        allRoleplayEntities().first { $0.id == id }?.asData
    }

    @discardableResult
    private func save() -> Bool {
        guard ctx.hasChanges else { return true }
        do { try ctx.save(); return true }
        catch {
            NSLog("QuestionBankService save failed: \(error.localizedDescription)")
            ctx.rollback()
            return false
        }
    }
}
