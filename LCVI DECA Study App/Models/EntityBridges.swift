//
//  EntityBridges.swift
//  LCVI DECA Study App
//
//  Conversion between Core Data objects and the Codable value types the UI uses.
//

import CoreData
import Foundation

extension CDQuestion {
    var choicesArray: [String] {
        [choiceA ?? "", choiceB ?? "", choiceC ?? "", choiceD ?? ""]
    }

    var clusterValue: DECACluster { DECACluster.from(cluster) ?? .marketing }
    var difficultyValue: Difficulty { Difficulty(rawValue: Int(difficulty)) ?? .medium }
    var tagList: [String] { ListCodec.decode(tags) }
    var indicatorList: [String] { ListCodec.decode(indicators) }

    var asData: QuestionData {
        QuestionData(
            id: id ?? UUID(),
            text: text ?? "",
            choices: choicesArray,
            correctIndex: Int(correctIndex),
            explanation: explanation ?? "",
            cluster: clusterValue,
            examType: examType ?? clusterValue.examName,
            difficulty: difficultyValue,
            tags: tagList,
            performanceIndicators: indicatorList,
            isSample: isSample,
            isBookmarked: isBookmarked
        )
    }

    func apply(_ data: QuestionData) {
        id = data.id
        text = data.text
        choiceA = data.choices.indices.contains(0) ? data.choices[0] : ""
        choiceB = data.choices.indices.contains(1) ? data.choices[1] : ""
        choiceC = data.choices.indices.contains(2) ? data.choices[2] : ""
        choiceD = data.choices.indices.contains(3) ? data.choices[3] : ""
        correctIndex = Int32(data.correctIndex)
        explanation = data.explanation
        cluster = data.cluster.rawValue
        examType = data.examType
        difficulty = Int32(data.difficulty.rawValue)
        tags = ListCodec.encode(data.tags)
        indicators = ListCodec.encode(data.performanceIndicators)
        isSample = data.isSample
        isBookmarked = data.isBookmarked
        if createdAt == nil { createdAt = Date() }
        fingerprint = data.fingerprint
    }
}

extension CDRoleplayPrompt {
    var clusterValue: DECACluster { DECACluster.from(cluster) ?? .marketing }
    var difficultyValue: Difficulty { Difficulty(rawValue: Int(difficulty)) ?? .medium }
    var indicatorList: [String] { ListCodec.decode(indicators) }

    var asData: RoleplayPromptData {
        RoleplayPromptData(
            id: id ?? UUID(),
            title: title ?? "",
            cluster: clusterValue,
            eventType: eventType ?? "",
            situation: situation ?? "",
            userRole: userRole ?? "",
            judgeRole: judgeRole ?? "",
            performanceIndicators: indicatorList,
            difficulty: difficultyValue,
            prepMinutes: Int(prepMinutes),
            presentMinutes: Int(presentMinutes),
            isSample: isSample
        )
    }

    func apply(_ data: RoleplayPromptData) {
        id = data.id
        title = data.title
        cluster = data.cluster.rawValue
        eventType = data.eventType
        situation = data.situation
        userRole = data.userRole
        judgeRole = data.judgeRole
        indicators = ListCodec.encode(data.performanceIndicators)
        difficulty = Int32(data.difficulty.rawValue)
        prepMinutes = Int32(data.prepMinutes)
        presentMinutes = Int32(data.presentMinutes)
        isSample = data.isSample
    }
}

extension CDSRRecord {
    var accuracy: Double {
        timesAnswered == 0 ? 0 : Double(timesCorrect) / Double(timesAnswered)
    }

    var isDue: Bool {
        guard let next = nextReviewAt else { return timesAnswered == 0 }
        return next <= Date()
    }

    var masteryBand: MasteryBand { MasteryBand(rawValue: Int(masteryLevel)) ?? .untouched }
}

extension CDPIMastery {
    var clusterValue: DECACluster { DECACluster.from(cluster) ?? .marketing }
    var band: MasteryBand { MasteryBand.from(score: masteryScore) }
    var accuracy: Double {
        timesAnswered == 0 ? 0 : Double(timesCorrect) / Double(timesAnswered)
    }
}

extension CDMockAttempt {
    var clusterValue: DECACluster { DECACluster.from(cluster) ?? .marketing }
    var scorePercent: Double {
        questionCount == 0 ? 0 : Double(correctCount) / Double(questionCount) * 100
    }
}

extension CDRoleplayResponse {
    var scores: [RubricCategory: Int] {
        guard let scoresJSON,
              let data = scoresJSON.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
        var out: [RubricCategory: Int] = [:]
        for (key, value) in raw {
            if let cat = RubricCategory(rawValue: key) { out[cat] = value }
        }
        return out
    }

    func setScores(_ scores: [RubricCategory: Int]) {
        var raw: [String: Int] = [:]
        for (key, value) in scores { raw[key.rawValue] = value }
        scoresJSON = (try? JSONEncoder().encode(raw)).flatMap { String(data: $0, encoding: .utf8) }
        averageScore = scores.isEmpty ? 0 : Double(scores.values.reduce(0, +)) / Double(scores.count)
    }
}

extension CDMistake {
    var clusterValue: DECACluster { DECACluster.from(cluster) ?? .marketing }
}
