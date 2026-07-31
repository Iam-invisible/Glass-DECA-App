//
//  SeedRoleplays+Personal.swift
//  LCVI DECA Study App
//
//  Personal Financial Literacy roleplay scenarios.
//
//  PFL is a single event rather than a family of them, so every scenario here
//  uses that format: 10 minutes of preparation, 10 in front of the judge, one
//  competitor. The judge is almost always a person being advised rather than a
//  manager receiving a report, which is why these are written as conversations.
//
//  Original practice scenarios modelled on the DECA roleplay format.
//  They are NOT official DECA Ontario or DECA Inc. competition materials.
//

import Foundation

extension SeedRoleplays {

    static let personalFinancialLiteracy: [RoleplayPromptData] = [

        rp("pfl-firstjob", "Coaching a First-Time Earner", .personalFinancialLiteracy, .personalFinancialLiteracy, .easy,
           situation: """
           A 17-year-old has started a part-time job earning about $900 per month. They were surprised that their first pay was less than expected, they have no savings, and they have been pre-approved for a $1,500 credit card.

           Their parent has asked you to explain how pay deductions work, how the student should structure a first budget, and how to use credit without getting into trouble.
           """,
           userRole: "You are a financial literacy coach.",
           judgeRole: "The judge is the student's parent.",
           pis: ["PF:005", "PF:001", "PF:002"]),

        rp("pfl-postsecondary", "Planning to Pay for Post-Secondary", .personalFinancialLiteracy, .personalFinancialLiteracy, .medium,
           situation: """
           A Grade 12 student has been accepted to a program costing about $9,000 per year in tuition plus $12,000 in living costs. They have $6,000 saved, expect a $2,000 scholarship, and are considering borrowing the rest.

           The student's guidance counsellor has asked you to explain the funding options, the true cost of borrowing, and how the student should decide.
           """,
           userRole: "You are a student financial advisor.",
           judgeRole: "The judge is the guidance counsellor.",
           pis: ["PF:008", "PF:007", "PF:001"]),

        rp("pfl-cardtrap", "A Balance That Will Not Go Down", .personalFinancialLiteracy, .personalFinancialLiteracy, .medium,
           situation: """
           A 22-year-old carries $4,200 across two credit cards at 19.99% and 22.99%, and has $2,600 sitting in a savings account earning 1.5% that they are keeping "for emergencies." They pay the minimum on both cards each month and cannot understand why the balances barely move.

           They have come to you for help.
           """,
           userRole: "You are a credit counsellor.",
           judgeRole: "The judge is the client.",
           pis: ["PF:002", "PF:007", "PF:001"]),

        rp("pfl-firstinvest", "Starting to Invest With a Small Amount", .personalFinancialLiteracy, .personalFinancialLiteracy, .medium,
           situation: """
           A 19-year-old has $3,000 saved and $200 a month available. A friend has told them to put it all into a single technology stock. They have heard of a TFSA but think it is "just a savings account for older people."

           Their older sibling has asked you to explain the options and give a recommendation the 19-year-old will actually follow.
           """,
           userRole: "You are a financial literacy educator.",
           judgeRole: "The judge is the client's older sibling.",
           pis: ["PF:004", "PF:003", "PF:007"]),

        rp("pfl-tfsavsrrsp", "Choosing Between Two Registered Accounts", .personalFinancialLiteracy, .personalFinancialLiteracy, .hard,
           situation: """
           A 26-year-old earning $48,000 has $8,000 to put away. They are saving for a home in roughly four years but have also been told they "should be doing RRSPs by now." They have contribution room in both a TFSA and an RRSP and do not understand the difference.

           They want a clear recommendation and the reasoning behind it.
           """,
           userRole: "You are a financial advisor.",
           judgeRole: "The judge is your client.",
           pis: ["PF:004", "PF:005", "PF:003"]),

        rp("pfl-firstcar", "Financing a First Vehicle", .personalFinancialLiteracy, .personalFinancialLiteracy, .medium,
           situation: """
           A 20-year-old earning $2,400 a month after deductions is about to sign an 84-month loan on a $38,000 vehicle at 9.9%. The dealer has focused entirely on the monthly payment, which fits their budget. They have $900 saved and no emergency fund.

           A parent has asked you to walk through the decision with them before anything is signed.
           """,
           userRole: "You are a financial counsellor.",
           judgeRole: "The judge is the client's parent.",
           pis: ["PF:001", "PF:007", "PF:003"]),

        rp("pfl-insurance", "Deciding What Insurance Is Actually Needed", .personalFinancialLiteracy, .personalFinancialLiteracy, .medium,
           situation: """
           A 24-year-old renting an apartment has been told by a salesperson that they need a whole life insurance policy at $180 a month. They have no dependants, $19,000 in student debt, no tenant insurance, and no disability coverage.

           They have come to you for a second opinion before signing.
           """,
           userRole: "You are an independent insurance advisor.",
           judgeRole: "The judge is your client.",
           pis: ["PF:006", "PF:003", "PF:001"]),

        rp("pfl-fraud", "A Message That Feels Urgent", .personalFinancialLiteracy, .personalFinancialLiteracy, .easy,
           situation: """
           A family friend received a text saying their bank account will be frozen within two hours unless they verify their identity through a link. They clicked the link, entered their card number and password, and only afterwards began to worry.

           They have called you in a panic.
           """,
           userRole: "You are a financial literacy volunteer.",
           judgeRole: "The judge is the family friend.",
           pis: ["PF:002", "PF:006"]),

        rp("pfl-variable", "Budgeting on an Income That Moves", .personalFinancialLiteracy, .personalFinancialLiteracy, .hard,
           situation: """
           A freelance graphic designer earns between $1,800 and $6,400 a month with no pattern. They budget against their best months, so they overspend in good months and borrow in poor ones. They have no tax money set aside and were caught out by a bill last April.

           They want a system they can actually stick to.
           """,
           userRole: "You are a personal finance coach.",
           judgeRole: "The judge is your client.",
           pis: ["PF:001", "PF:005", "PF:007"]),

        rp("pfl-firstoffer", "Comparing Two Job Offers", .personalFinancialLiteracy, .personalFinancialLiteracy, .medium,
           situation: """
           A recent graduate has two offers. One pays $58,000 with no benefits and a 70-minute commute each way. The other pays $53,000 with health benefits worth about $6,000, a 5% pension match, and a fifteen-minute walk.

           They are about to accept the first because "it pays more."

           Their parent has asked you to work through it with them.
           """,
           userRole: "You are a financial literacy advisor.",
           judgeRole: "The judge is the graduate's parent.",
           pis: ["PF:005", "PF:001", "PF:004"])
    ]
}
