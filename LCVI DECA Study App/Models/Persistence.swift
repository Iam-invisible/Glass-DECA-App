//
//  Persistence.swift
//  LCVI DECA Study App
//
//  Core Data stack built entirely in code. A programmatic NSManagedObjectModel
//  keeps the app compatible with iOS 16 (iPhone 8) — SwiftData is not used.
//  Entities are linked by UUID rather than Core Data relationships so the whole
//  database can be exported to JSON without object-graph surprises.
//

import CoreData
import Foundation

// MARK: - Attribute builders

private func attr(_ name: String,
                  _ type: NSAttributeType,
                  optional: Bool = true,
                  defaultValue: Any? = nil,
                  indexed: Bool = false) -> NSAttributeDescription {
    let a = NSAttributeDescription()
    a.name = name
    a.attributeType = type
    a.isOptional = optional
    a.defaultValue = defaultValue
    if indexed {
        let index = NSFetchIndexDescription(
            name: "byIndex_\(name)",
            elements: [NSFetchIndexElementDescription(property: a, collationType: .binary)]
        )
        a.userInfo = ["index": index.name]
    }
    return a
}

private func entity(_ name: String,
                    _ cls: AnyClass,
                    _ attributes: [NSAttributeDescription]) -> NSEntityDescription {
    let e = NSEntityDescription()
    e.name = name
    e.managedObjectClassName = NSStringFromClass(cls)
    e.properties = attributes
    return e
}

// MARK: - Managed object subclasses

@objc(CDQuestion)
final class CDQuestion: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var text: String?
    @NSManaged var choiceA: String?
    @NSManaged var choiceB: String?
    @NSManaged var choiceC: String?
    @NSManaged var choiceD: String?
    @NSManaged var correctIndex: Int32
    @NSManaged var explanation: String?
    /// Why each choice is right or wrong. Four attributes rather than one
    /// encoded list, for the same reason the choices themselves are four:
    /// no delimiter to escape, and the shape is visible in the model.
    @NSManaged var rationaleA: String?
    @NSManaged var rationaleB: String?
    @NSManaged var rationaleC: String?
    @NSManaged var rationaleD: String?
    @NSManaged var cluster: String?
    @NSManaged var examType: String?
    @NSManaged var difficulty: Int32
    @NSManaged var tags: String?
    @NSManaged var indicators: String?
    @NSManaged var isSample: Bool
    @NSManaged var isBookmarked: Bool
    @NSManaged var createdAt: Date?
    @NSManaged var fingerprint: String?
}

@objc(CDSRRecord)
final class CDSRRecord: NSManagedObject {
    @NSManaged var questionID: UUID?
    @NSManaged var timesAnswered: Int32
    @NSManaged var timesCorrect: Int32
    @NSManaged var timesIncorrect: Int32
    @NSManaged var consecutiveCorrect: Int32
    @NSManaged var lastAnsweredAt: Date?
    @NSManaged var nextReviewAt: Date?
    @NSManaged var intervalDays: Double
    @NSManaged var ease: Double
    @NSManaged var masteryLevel: Int32
}

@objc(CDMistake)
final class CDMistake: NSManagedObject {
    @NSManaged var questionID: UUID?
    @NSManaged var selectedIndex: Int32
    @NSManaged var correctIndex: Int32
    @NSManaged var firstMissedAt: Date?
    @NSManaged var lastMissedAt: Date?
    @NSManaged var timesMissed: Int32
    @NSManaged var consecutiveCorrect: Int32
    @NSManaged var mastered: Bool
    @NSManaged var masteredAt: Date?
    @NSManaged var cluster: String?
}

@objc(CDPracticeSession)
final class CDPracticeSession: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var mode: String?
    @NSManaged var cluster: String?
    @NSManaged var startedAt: Date?
    @NSManaged var endedAt: Date?
    @NSManaged var questionCount: Int32
    @NSManaged var correctCount: Int32
    @NSManaged var durationSeconds: Double
}

@objc(CDPracticeAnswer)
final class CDPracticeAnswer: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var sessionID: UUID?
    @NSManaged var questionID: UUID?
    @NSManaged var selectedIndex: Int32
    @NSManaged var isCorrect: Bool
    @NSManaged var answeredAt: Date?
    @NSManaged var secondsSpent: Double
    @NSManaged var cluster: String?
    @NSManaged var indicators: String?
    @NSManaged var tags: String?
}

@objc(CDMockAttempt)
final class CDMockAttempt: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var date: Date?
    @NSManaged var cluster: String?
    @NSManaged var questionCount: Int32
    @NSManaged var correctCount: Int32
    @NSManaged var durationSeconds: Double
    @NSManaged var timed: Bool
    @NSManaged var timeLimitSeconds: Double
    @NSManaged var weakTopicsOnly: Bool
}

@objc(CDMockResult)
final class CDMockResult: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var attemptID: UUID?
    @NSManaged var questionID: UUID?
    @NSManaged var selectedIndex: Int32   // -1 = unanswered
    @NSManaged var correctIndex: Int32
    @NSManaged var isCorrect: Bool
    @NSManaged var flagged: Bool
    @NSManaged var order: Int32
}

@objc(CDRoleplayPrompt)
final class CDRoleplayPrompt: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var cluster: String?
    @NSManaged var eventType: String?
    @NSManaged var situation: String?
    @NSManaged var userRole: String?
    @NSManaged var judgeRole: String?
    @NSManaged var indicators: String?
    @NSManaged var difficulty: Int32
    @NSManaged var prepMinutes: Int32
    @NSManaged var presentMinutes: Int32
    @NSManaged var isSample: Bool
}

@objc(CDRoleplayResponse)
final class CDRoleplayResponse: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var promptID: UUID?
    @NSManaged var date: Date?
    @NSManaged var notes: String?
    @NSManaged var transcript: String?
    @NSManaged var scoresJSON: String?
    @NSManaged var aiFeedback: String?
    @NSManaged var averageScore: Double
    @NSManaged var cluster: String?
    @NSManaged var indicators: String?
    @NSManaged var prepSeconds: Double
    @NSManaged var presentSeconds: Double
}

@objc(CDQuickThinkSession)
final class CDQuickThinkSession: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var date: Date?
    @NSManaged var scenarioID: String?
    @NSManaged var scenarioText: String?
    @NSManaged var response: String?
    @NSManaged var feedback: String?
    @NSManaged var cluster: String?
    @NSManaged var secondsSpent: Double
    @NSManaged var usedAI: Bool
}

@objc(CDDailyProgress)
final class CDDailyProgress: NSManagedObject {
    @NSManaged var dayKey: String?
    @NSManaged var date: Date?
    @NSManaged var questionsAnswered: Int32
    @NSManaged var correctCount: Int32
    @NSManaged var goal: Int32
    @NSManaged var goalMet: Bool
    @NSManaged var secondsStudied: Double
}

@objc(CDPIMastery)
final class CDPIMastery: NSManagedObject {
    @NSManaged var code: String?
    @NSManaged var text: String?
    @NSManaged var cluster: String?
    @NSManaged var timesAnswered: Int32
    @NSManaged var timesCorrect: Int32
    @NSManaged var roleplayCount: Int32
    @NSManaged var masteryScore: Double
    @NSManaged var lastPracticedAt: Date?
}

@objc(CDAchievementRecord)
final class CDAchievementRecord: NSManagedObject {
    @NSManaged var code: String?
    @NSManaged var unlockedAt: Date?
    @NSManaged var progressValue: Double
}

// MARK: - Model

enum AppModel {
    static let entityNames = (
        question: "Question",
        srRecord: "SRRecord",
        mistake: "Mistake",
        practiceSession: "PracticeSession",
        practiceAnswer: "PracticeAnswer",
        mockAttempt: "MockAttempt",
        mockResult: "MockResult",
        roleplayPrompt: "RoleplayPrompt",
        roleplayResponse: "RoleplayResponse",
        quickThink: "QuickThinkSession",
        dailyProgress: "DailyProgress",
        piMastery: "PIMastery",
        achievement: "AchievementRecord"
    )

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let question = entity(entityNames.question, CDQuestion.self, [
            attr("id", .UUIDAttributeType),
            attr("text", .stringAttributeType),
            attr("choiceA", .stringAttributeType),
            attr("choiceB", .stringAttributeType),
            attr("choiceC", .stringAttributeType),
            attr("choiceD", .stringAttributeType),
            attr("correctIndex", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("explanation", .stringAttributeType),
            // Added after v1.0 build 1. Optional string attributes are a
            // textbook lightweight migration, which the store description
            // already opts into, and the recovery path below covers the rest.
            attr("rationaleA", .stringAttributeType),
            attr("rationaleB", .stringAttributeType),
            attr("rationaleC", .stringAttributeType),
            attr("rationaleD", .stringAttributeType),
            attr("cluster", .stringAttributeType),
            attr("examType", .stringAttributeType),
            attr("difficulty", .integer32AttributeType, optional: false, defaultValue: 2),
            attr("tags", .stringAttributeType),
            attr("indicators", .stringAttributeType),
            attr("isSample", .booleanAttributeType, optional: false, defaultValue: true),
            attr("isBookmarked", .booleanAttributeType, optional: false, defaultValue: false),
            attr("createdAt", .dateAttributeType),
            attr("fingerprint", .stringAttributeType)
        ])

        let srRecord = entity(entityNames.srRecord, CDSRRecord.self, [
            attr("questionID", .UUIDAttributeType),
            attr("timesAnswered", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("timesCorrect", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("timesIncorrect", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("consecutiveCorrect", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("lastAnsweredAt", .dateAttributeType),
            attr("nextReviewAt", .dateAttributeType),
            attr("intervalDays", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("ease", .doubleAttributeType, optional: false, defaultValue: 2.5),
            attr("masteryLevel", .integer32AttributeType, optional: false, defaultValue: 0)
        ])

        let mistake = entity(entityNames.mistake, CDMistake.self, [
            attr("questionID", .UUIDAttributeType),
            attr("selectedIndex", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("correctIndex", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("firstMissedAt", .dateAttributeType),
            attr("lastMissedAt", .dateAttributeType),
            attr("timesMissed", .integer32AttributeType, optional: false, defaultValue: 1),
            attr("consecutiveCorrect", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("mastered", .booleanAttributeType, optional: false, defaultValue: false),
            attr("masteredAt", .dateAttributeType),
            attr("cluster", .stringAttributeType)
        ])

        let practiceSession = entity(entityNames.practiceSession, CDPracticeSession.self, [
            attr("id", .UUIDAttributeType),
            attr("mode", .stringAttributeType),
            attr("cluster", .stringAttributeType),
            attr("startedAt", .dateAttributeType),
            attr("endedAt", .dateAttributeType),
            attr("questionCount", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("correctCount", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("durationSeconds", .doubleAttributeType, optional: false, defaultValue: 0)
        ])

        let practiceAnswer = entity(entityNames.practiceAnswer, CDPracticeAnswer.self, [
            attr("id", .UUIDAttributeType),
            attr("sessionID", .UUIDAttributeType),
            attr("questionID", .UUIDAttributeType),
            attr("selectedIndex", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("isCorrect", .booleanAttributeType, optional: false, defaultValue: false),
            attr("answeredAt", .dateAttributeType),
            attr("secondsSpent", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("cluster", .stringAttributeType),
            attr("indicators", .stringAttributeType),
            attr("tags", .stringAttributeType)
        ])

        let mockAttempt = entity(entityNames.mockAttempt, CDMockAttempt.self, [
            attr("id", .UUIDAttributeType),
            attr("date", .dateAttributeType),
            attr("cluster", .stringAttributeType),
            attr("questionCount", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("correctCount", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("durationSeconds", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("timed", .booleanAttributeType, optional: false, defaultValue: false),
            attr("timeLimitSeconds", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("weakTopicsOnly", .booleanAttributeType, optional: false, defaultValue: false)
        ])

        let mockResult = entity(entityNames.mockResult, CDMockResult.self, [
            attr("id", .UUIDAttributeType),
            attr("attemptID", .UUIDAttributeType),
            attr("questionID", .UUIDAttributeType),
            attr("selectedIndex", .integer32AttributeType, optional: false, defaultValue: -1),
            attr("correctIndex", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("isCorrect", .booleanAttributeType, optional: false, defaultValue: false),
            attr("flagged", .booleanAttributeType, optional: false, defaultValue: false),
            attr("order", .integer32AttributeType, optional: false, defaultValue: 0)
        ])

        let roleplayPrompt = entity(entityNames.roleplayPrompt, CDRoleplayPrompt.self, [
            attr("id", .UUIDAttributeType),
            attr("title", .stringAttributeType),
            attr("cluster", .stringAttributeType),
            attr("eventType", .stringAttributeType),
            attr("situation", .stringAttributeType),
            attr("userRole", .stringAttributeType),
            attr("judgeRole", .stringAttributeType),
            attr("indicators", .stringAttributeType),
            attr("difficulty", .integer32AttributeType, optional: false, defaultValue: 2),
            attr("prepMinutes", .integer32AttributeType, optional: false, defaultValue: 10),
            attr("presentMinutes", .integer32AttributeType, optional: false, defaultValue: 10),
            attr("isSample", .booleanAttributeType, optional: false, defaultValue: true)
        ])

        let roleplayResponse = entity(entityNames.roleplayResponse, CDRoleplayResponse.self, [
            attr("id", .UUIDAttributeType),
            attr("promptID", .UUIDAttributeType),
            attr("date", .dateAttributeType),
            attr("notes", .stringAttributeType),
            attr("transcript", .stringAttributeType),
            attr("scoresJSON", .stringAttributeType),
            attr("aiFeedback", .stringAttributeType),
            attr("averageScore", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("cluster", .stringAttributeType),
            attr("indicators", .stringAttributeType),
            attr("prepSeconds", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("presentSeconds", .doubleAttributeType, optional: false, defaultValue: 0)
        ])

        let quickThink = entity(entityNames.quickThink, CDQuickThinkSession.self, [
            attr("id", .UUIDAttributeType),
            attr("date", .dateAttributeType),
            attr("scenarioID", .stringAttributeType),
            attr("scenarioText", .stringAttributeType),
            attr("response", .stringAttributeType),
            attr("feedback", .stringAttributeType),
            attr("cluster", .stringAttributeType),
            attr("secondsSpent", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("usedAI", .booleanAttributeType, optional: false, defaultValue: false)
        ])

        let dailyProgress = entity(entityNames.dailyProgress, CDDailyProgress.self, [
            attr("dayKey", .stringAttributeType),
            attr("date", .dateAttributeType),
            attr("questionsAnswered", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("correctCount", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("goal", .integer32AttributeType, optional: false, defaultValue: 10),
            attr("goalMet", .booleanAttributeType, optional: false, defaultValue: false),
            attr("secondsStudied", .doubleAttributeType, optional: false, defaultValue: 0)
        ])

        let piMastery = entity(entityNames.piMastery, CDPIMastery.self, [
            attr("code", .stringAttributeType),
            attr("text", .stringAttributeType),
            attr("cluster", .stringAttributeType),
            attr("timesAnswered", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("timesCorrect", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("roleplayCount", .integer32AttributeType, optional: false, defaultValue: 0),
            attr("masteryScore", .doubleAttributeType, optional: false, defaultValue: 0),
            attr("lastPracticedAt", .dateAttributeType)
        ])

        let achievement = entity(entityNames.achievement, CDAchievementRecord.self, [
            attr("code", .stringAttributeType),
            attr("unlockedAt", .dateAttributeType),
            attr("progressValue", .doubleAttributeType, optional: false, defaultValue: 0)
        ])

        model.entities = [
            question, srRecord, mistake, practiceSession, practiceAnswer,
            mockAttempt, mockResult, roleplayPrompt, roleplayResponse,
            quickThink, dailyProgress, piMastery, achievement
        ]
        return model
    }
}

// MARK: - Stack

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        let model = AppModel.makeModel()
        container = NSPersistentContainer(name: "DECAStudy", managedObjectModel: model)

        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        } else {
            let url = PersistenceController.storeURL()
            let desc = NSPersistentStoreDescription(url: url)
            desc.shouldMigrateStoreAutomatically = true
            desc.shouldInferMappingModelAutomatically = true
            desc.setOption(FileProtectionType.completeUntilFirstUserAuthentication as NSObject,
                           forKey: NSPersistentStoreFileProtectionKey)
            container.persistentStoreDescriptions = [desc]
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }

        if let loadError {
            // Recovery path: a corrupt or unreadable store should never brick the
            // app. Remove it and start clean rather than crashing on launch.
            NSLog("DECAStudy: store failed to load (\(loadError.localizedDescription)); recreating.")
            let url = PersistenceController.storeURL()
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            container.loadPersistentStores { _, _ in }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
    }

    static func storeURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true))
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("DECAStudy", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("DECAStudy.sqlite")
    }

    @discardableResult
    func save() -> Bool {
        guard viewContext.hasChanges else { return true }
        do {
            try viewContext.save()
            return true
        } catch {
            NSLog("DECAStudy: save failed — \(error.localizedDescription)")
            viewContext.rollback()
            return false
        }
    }

    func wipeAll() {
        let names = [
            AppModel.entityNames.question, AppModel.entityNames.srRecord,
            AppModel.entityNames.mistake, AppModel.entityNames.practiceSession,
            AppModel.entityNames.practiceAnswer, AppModel.entityNames.mockAttempt,
            AppModel.entityNames.mockResult, AppModel.entityNames.roleplayPrompt,
            AppModel.entityNames.roleplayResponse, AppModel.entityNames.quickThink,
            AppModel.entityNames.dailyProgress, AppModel.entityNames.piMastery,
            AppModel.entityNames.achievement
        ]
        for name in names { deleteAll(entity: name) }
        save()
    }

    /// Deletes every object in an entity. Uses a batch delete for the SQLite
    /// store and falls back to per-object deletion for in-memory stores.
    func deleteAll(entity name: String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        if container.persistentStoreDescriptions.first?.type == NSInMemoryStoreType {
            if let objects = try? viewContext.fetch(request) as? [NSManagedObject] {
                objects.forEach { viewContext.delete($0) }
            }
            return
        }
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        delete.resultType = .resultTypeObjectIDs
        if let result = try? viewContext.execute(delete) as? NSBatchDeleteResult,
           let ids = result.result as? [NSManagedObjectID] {
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                                                into: [viewContext])
        }
    }
}

// MARK: - Fetch conveniences

extension NSManagedObjectContext {
    func fetchAll<T: NSManagedObject>(_ type: T.Type,
                                      entity name: String,
                                      predicate: NSPredicate? = nil,
                                      sort: [NSSortDescriptor] = [],
                                      limit: Int? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: name)
        request.predicate = predicate
        request.sortDescriptors = sort
        if let limit { request.fetchLimit = limit }
        return (try? fetch(request)) ?? []
    }

    func count(entity name: String, predicate: NSPredicate? = nil) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        request.predicate = predicate
        return (try? count(for: request)) ?? 0
    }

    func insert<T: NSManagedObject>(_ type: T.Type, entity name: String) -> T {
        NSEntityDescription.insertNewObject(forEntityName: name, into: self) as! T
    }
}

// MARK: - String list helpers

enum ListCodec {
    static let separator = "|"

    static func encode(_ items: [String]) -> String {
        items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: separator)
    }

    static func decode(_ raw: String?) -> [String] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: separator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
