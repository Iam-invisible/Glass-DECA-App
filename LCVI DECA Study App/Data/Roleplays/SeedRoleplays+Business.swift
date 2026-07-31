//
//  SeedRoleplays+Business.swift
//  LCVI DECA Study App
//
//  Business Management and Administration roleplay scenarios.
//
//  Original practice scenarios modelled on the DECA roleplay format.
//  They are NOT official DECA Ontario or DECA Inc. competition materials.
//

import Foundation

extension SeedRoleplays {

    static let businessManagement: [RoleplayPromptData] = [

        // MARK: Principles

        rp("bma-p-delegate", "Learning to Delegate", .businessManagement, .principles, .easy,
           situation: """
           A newly promoted shift lead at a retail store is working twelve-hour days because they are doing every task themselves. They have told you they cannot delegate because "it's faster if I just do it."

           The store manager wants you to explain what delegation actually involves and why holding onto everything is a problem for the team as well as for the shift lead.
           """,
           userRole: "You are an assistant manager mentoring the new shift lead.",
           judgeRole: "The judge is the store manager.",
           pis: ["BM:001", "BM:002"]),

        rp("bma-p-safety", "A Worker Who Will Not Wear the Equipment", .businessManagement, .principles, .easy,
           situation: """
           An employee at a warehouse has stopped wearing safety glasses because they fog up and "nothing has ever happened." Two other staff have started doing the same.

           Your supervisor wants to see how you address it with the employee, and what you would suggest so the rule is actually followed.
           """,
           userRole: "You are a team lead on the warehouse floor.",
           judgeRole: "The judge is your supervisor.",
           pis: ["BM:004", "BM:002"]),

        rp("bma-p-ethics", "Being Asked to Round the Numbers", .businessManagement, .principles, .easy,
           situation: """
           You work part-time in an office. A manager has asked you to record a delivery as arriving on Friday when it actually arrived on Monday, because "it makes the monthly numbers work and it's only two days."

           The manager is friendly, senior, and has been good to you.

           Explain how you would respond and why.
           """,
           userRole: "You are an office assistant.",
           judgeRole: "The judge is the company's operations manager.",
           pis: ["BM:005", "BM:007"]),

        // MARK: Individual Series

        rp("bma-scheduling", "Introducing a New Scheduling System", .businessManagement, .individualSeries, .medium,
           situation: """
           A 90-employee distribution centre is replacing paper schedules with a mobile app. Long-tenured staff have objected loudly: some do not have modern phones, and others believe the app will be used to track them.

           The operations director wants a plan for introducing the change, addressing the objections, and measuring whether the rollout succeeded.
           """,
           userRole: "You are the human resources coordinator at the distribution centre.",
           judgeRole: "The judge is the operations director.",
           pis: ["BM:008", "BM:003", "BM:009", "BM:005"]),

        rp("bma-ethics", "Handling a Workplace Safety Concern", .businessManagement, .individualSeries, .hard,
           situation: """
           A worker on the packaging line has refused to operate a machine whose guard was removed last week to speed up changeovers. A supervisor told the worker to "just be careful." Production is now behind schedule and the plant manager is frustrated.

           The plant manager has asked you to explain the company's legal and ethical obligations and to recommend how this should be handled today and prevented long-term.
           """,
           userRole: "You are the health and safety representative at the plant.",
           judgeRole: "The judge is the plant manager.",
           pis: ["BM:004", "BM:005", "BM:002"]),

        rp("bma-turnover", "Stopping New Hires From Leaving", .businessManagement, .individualSeries, .medium,
           situation: """
           A call centre has lost 34 of its last 60 hires within 90 days. Exit interviews mention unclear expectations, a first week spent watching videos, and supervisors who are unavailable. Recruitment costs have doubled and the operations manager's proposed fix is a signing bonus.

           The manager wants your assessment of that fix and what you would do instead.
           """,
           userRole: "You are a human resources consultant.",
           judgeRole: "The judge is the operations manager.",
           pis: ["BM:003", "BM:009", "BM:002"]),

        rp("bma-kpi", "A Measure That Backfired", .businessManagement, .individualSeries, .hard,
           situation: """
           Six months ago a service desk introduced a single performance measure: calls handled per agent per hour. Volume per agent is up 22%. Repeat contacts are up 40%, customer satisfaction has fallen 15 points, and two of the best agents have resigned.

           The director still believes the measure is working because the headline number improved.

           The director wants your analysis.
           """,
           userRole: "You are a performance management consultant.",
           judgeRole: "The judge is the service desk director.",
           pis: ["BM:009", "BM:002", "BM:006"]),

        rp("bma-process", "Finding the Bottleneck", .businessManagement, .individualSeries, .medium,
           situation: """
           A custom furniture workshop takes 19 days from order to delivery. The owner has bought a second cutting machine to speed things up, but delivery times have not moved. Cutting takes half a day; finishing, which is done by one person, takes eleven days.

           The owner is now considering a third cutting machine.

           They want your assessment before spending the money.
           """,
           userRole: "You are an operations consultant.",
           judgeRole: "The judge is the workshop owner.",
           pis: ["BM:006", "BM:009", "BM:002"]),

        // MARK: Team Decision Making

        rp("bma-tdm-harass", "Responding to a Harassment Complaint", .businessManagement, .teamDecisionMaking, .hard,
           situation: """
           An employee has told their supervisor verbally that a colleague has repeatedly made comments they find humiliating. They have asked the supervisor "not to make it a big thing" and have not put anything in writing. The colleague is a high performer and a friend of the department head.

           Your team must recommend what the company does, in what order, and how the employee's request is weighed against the employer's obligations.
           """,
           userRole: "You are a two-person human resources team.",
           judgeRole: "The judge is the company's president.",
           pis: ["BM:004", "BM:005", "BM:007", "BM:003"]),

        rp("bma-tdm-restructure", "Restructuring Without Losing the Business", .businessManagement, .teamDecisionMaking, .hard,
           situation: """
           A 140-person company has grown by acquisition and now has three sales teams, three finance functions and three sets of software doing the same jobs. Consolidating would save an estimated $2.1 million a year but would eliminate roughly 25 roles, and the three founders each want to keep their own team's systems.

           Your team must present a restructuring approach, including how it is sequenced and communicated.
           """,
           userRole: "You are a two-person organisational consulting team.",
           judgeRole: "The judge is the board chair.",
           pis: ["BM:001", "BM:008", "BM:006", "BM:002"]),

        rp("bma-tdm-privacy", "A Data Breach and a Difficult Disclosure", .businessManagement, .teamDecisionMaking, .hard,
           situation: """
           A laptop containing unencrypted customer records for roughly 9,000 people has been stolen from an employee's car. Company policy prohibited storing that data locally. The head of sales wants to wait until the laptop is recovered before saying anything, arguing that disclosure would cause panic over a device that may never be opened.

           Your team must recommend what the company does about notification, about the employee, and about the policy.
           """,
           userRole: "You are a two-person governance and compliance team.",
           judgeRole: "The judge is the chief executive.",
           pis: ["BM:007", "BM:005", "BM:008"])
    ]
}
