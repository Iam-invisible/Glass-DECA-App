//
//  SeedQuestions.swift
//  LCVI DECA Study App
//
//  Sample practice questions written for this app.
//  These are NOT official DECA Ontario or DECA Inc. exam questions — they are
//  original practice items modelled on the style of cluster exams so the app is
//  usable the moment it is installed. Import your own bank from Settings ▸
//  Question Bank Manager to study material from your own class or club.
//
//  The bank is 100 questions per cluster, which is why this file holds only the
//  aggregate and the helper: each cluster lives in its own file under
//  Data/Questions/ so a single cluster can be reviewed, corrected or replaced
//  without scrolling past five others. The target uses synchronized folder
//  groups (§4), so those files compile by virtue of existing.
//

import Foundation

/// Builds one question.
///
/// `why` is one line per choice, in A–D order, saying why that option is right
/// or wrong. It carries a default only so the field could be introduced without
/// rewriting every existing item in the same commit — everything in the bank
/// now supplies it, and anything new should too.
///
/// Deliberately `internal` rather than `private`: the cluster files are
/// extensions of `SeedQuestions` living in their own files, and a `private`
/// helper is visible only within the file that declares it.
func q(_ key: String,
       _ cluster: DECACluster,
       _ difficulty: Difficulty,
       _ text: String,
       _ a: String, _ b: String, _ c: String, _ d: String,
       correct: Int,
       explanation: String,
       why: [String] = [],
       tags: [String],
       pis: [String]) -> QuestionData {
    QuestionData(
        id: UUID.stable("question-\(key)"),
        text: text,
        choices: [a, b, c, d],
        correctIndex: correct,
        explanation: explanation,
        choiceRationales: why,
        cluster: cluster,
        examType: cluster.examName,
        difficulty: difficulty,
        tags: tags,
        performanceIndicators: pis,
        isSample: true
    )
}

enum SeedQuestions {

    /// Every bundled question. The cluster arrays are defined in
    /// Data/Questions/SeedQuestions+<Cluster>.swift.
    static let all: [QuestionData] = marketing + finance + hospitality
        + businessManagement + entrepreneurship + personalFinance
}
