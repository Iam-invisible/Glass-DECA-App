//
//  SeedRoleplays.swift
//  LCVI DECA Study App
//
//  Sample roleplay scenarios and Quick Think prompts written for this app.
//  These are original practice scenarios modelled on the DECA roleplay format —
//  they are not official DECA Ontario or DECA Inc. competition materials.
//

import Foundation

private func rp(_ key: String,
                _ title: String,
                _ cluster: DECACluster,
                _ eventType: String,
                _ difficulty: Difficulty,
                prep: Int,
                present: Int,
                situation: String,
                userRole: String,
                judgeRole: String,
                pis: [String]) -> RoleplayPromptData {
    RoleplayPromptData(
        id: UUID.stable("roleplay-\(key)"),
        title: title,
        cluster: cluster,
        eventType: eventType,
        situation: situation,
        userRole: userRole,
        judgeRole: judgeRole,
        performanceIndicators: pis,
        difficulty: difficulty,
        prepMinutes: prep,
        presentMinutes: present,
        isSample: true
    )
}

enum SeedRoleplays {

    static let all: [RoleplayPromptData] = [

        // MARK: Marketing

        rp("mkt-launch", "Launching a Student Meal Subscription", .marketing,
           "Individual Series", .medium, prep: 10, present: 10,
           situation: """
           A campus café chain wants to grow weekday lunch traffic, which has fallen 14% since students began ordering delivery. The owner is considering a prepaid meal subscription: students pay $60 per month for one lunch every weekday.

           Before committing, the owner wants to understand how the subscription should be priced and promoted, which student segments it should target, and what risks the café should plan for.
           """,
           userRole: "You are a marketing consultant hired by the café chain.",
           judgeRole: "The judge is the owner of the café chain.",
           pis: ["MK:002", "MK:006", "MK:010", "MK:001"]),

        rp("mkt-rebrand", "Repositioning a Struggling Retailer", .marketing,
           "Individual Series", .hard, prep: 10, present: 10,
           situation: """
           A 30-year-old family sporting-goods store is losing sales to large online retailers. Its customers are loyal but aging, and shoppers under 25 rarely visit. The owner refuses to compete on price.

           The owner has asked for a repositioning plan that explains how the store should be perceived differently, which segments it should pursue, and how promotion should change to support that position.
           """,
           userRole: "You are a marketing strategist hired by the store owner.",
           judgeRole: "The judge is the store owner.",
           pis: ["MK:008", "MK:005", "MK:006", "MK:004"]),

        // MARK: Finance

        rp("fin-ratios", "Explaining the Numbers to a Franchise Owner", .finance,
           "Individual Series", .medium, prep: 10, present: 10,
           situation: """
           A franchisee operating two quick-service restaurants has strong sales but is repeatedly short of cash. Their current ratio has fallen from 1.8 to 0.9 in one year while revenue grew 12%.

           The franchisee does not have an accounting background and wants a plain-language explanation of what the numbers show, why profitable stores can run out of cash, and what should change in the next quarter.
           """,
           userRole: "You are a financial analyst at the franchisee's bank.",
           judgeRole: "The judge is the franchise owner.",
           pis: ["FI:002", "FI:001", "FI:007", "FI:005"]),

        rp("fin-risk", "Building a Risk Plan for a Growing Business", .finance,
           "Individual Series", .medium, prep: 10, present: 10,
           situation: """
           A landscaping company has grown from 4 to 22 employees in two years. It now owns $340,000 of equipment, operates seven vehicles, and works on client property daily. The owner carries only basic liability coverage and has no formal risk plan.

           The owner wants to understand the main categories of risk the business faces and how each should be handled.
           """,
           userRole: "You are a risk-management advisor.",
           judgeRole: "The judge is the owner of the landscaping company.",
           pis: ["FI:006", "FI:005", "FI:004"]),

        // MARK: Hospitality and Tourism

        rp("ht-recovery", "Recovering a Ruined Guest Stay", .hospitality,
           "Individual Series", .easy, prep: 10, present: 10,
           situation: """
           A guest arrived at your 180-room hotel for a wedding weekend. Their pre-paid suite was not available, they were moved twice, and housekeeping entered the room without knocking. The guest has posted a one-star review and is now standing at the front desk.

           Your general manager wants you to resolve the situation in person and then recommend what should change so it does not happen again.
           """,
           userRole: "You are the front-office manager of the hotel.",
           judgeRole: "The judge is the hotel's general manager.",
           pis: ["HT:004", "HT:002", "HT:008"]),

        rp("ht-revenue", "Filling Midweek Rooms in the Off-Season", .hospitality,
           "Individual Series", .hard, prep: 10, present: 10,
           situation: """
           A lakeside resort runs at 82% occupancy on summer weekends but only 31% on midweek nights from October to April. Fixed costs continue year-round. Ownership has proposed a flat 50% discount on all midweek rates.

           Ownership wants your assessment of that proposal and any alternative approaches to raising off-season RevPAR without damaging the resort's rate integrity.
           """,
           userRole: "You are the revenue manager at the resort.",
           judgeRole: "The judge is a member of the ownership group.",
           pis: ["HT:003", "HT:006", "HT:001"]),

        // MARK: Business Management and Administration

        rp("bma-scheduling", "Introducing a New Scheduling System", .businessManagement,
           "Individual Series", .medium, prep: 10, present: 10,
           situation: """
           A 90-employee distribution centre is replacing paper schedules with a mobile app. Long-tenured staff have objected loudly: some do not have modern phones, and others believe the app will be used to track them.

           The operations director wants a plan for introducing the change, addressing the objections, and measuring whether the rollout succeeded.
           """,
           userRole: "You are the human resources coordinator at the distribution centre.",
           judgeRole: "The judge is the operations director.",
           pis: ["BM:008", "BM:003", "BM:009", "BM:005"]),

        rp("bma-ethics", "Handling a Workplace Safety Concern", .businessManagement,
           "Individual Series", .hard, prep: 10, present: 10,
           situation: """
           A worker on the packaging line has refused to operate a machine whose guard was removed last week to speed up changeovers. A supervisor told the worker to "just be careful." Production is now behind schedule and the plant manager is frustrated.

           The plant manager has asked you to explain the company's legal and ethical obligations and to recommend how this should be handled today and prevented long-term.
           """,
           userRole: "You are the health and safety representative at the plant.",
           judgeRole: "The judge is the plant manager.",
           pis: ["BM:004", "BM:005", "BM:002"]),

        // MARK: Entrepreneurship

        rp("ent-pitch", "Pitching a Repair Café Franchise", .entrepreneurship,
           "Individual Series", .medium, prep: 10, present: 10,
           situation: """
           You have run a successful electronics repair shop for three years, with $410,000 in annual revenue and 22% net margin. You want to open five more locations across the province but have only $60,000 of your own capital.

           You have a meeting with a potential investor who wants to understand the concept, the competitive advantage, how growth would be financed, and what they would receive in return.
           """,
           userRole: "You are the founder of the repair shop.",
           judgeRole: "The judge is a potential angel investor.",
           pis: ["EN:003", "EN:005", "EN:007", "EN:001"]),

        rp("ent-mvp", "Testing a Concept Before Building It", .entrepreneurship,
           "Individual Series", .easy, prep: 10, present: 10,
           situation: """
           Two students want to build an app that matches high-school tutors with younger students. They have quoted $45,000 for full development and want to borrow the money from a family member before any customer has used the product.

           The family member has asked you to advise the founders on how to test the concept first and what evidence would justify the investment.
           """,
           userRole: "You are a small-business advisor.",
           judgeRole: "The judge is the family member considering the loan.",
           pis: ["EN:006", "EN:002", "EN:005"]),

        // MARK: Personal Financial Literacy

        rp("pfl-firstjob", "Coaching a First-Time Earner", .personalFinancialLiteracy,
           "Individual Series", .easy, prep: 10, present: 10,
           situation: """
           A 17-year-old has started a part-time job earning about $900 per month. They were surprised that their first pay was less than expected, they have no savings, and they have been pre-approved for a $1,500 credit card.

           Their parent has asked you to explain how pay deductions work, how the student should structure a first budget, and how to use credit without getting into trouble.
           """,
           userRole: "You are a financial literacy coach.",
           judgeRole: "The judge is the student's parent.",
           pis: ["PF:005", "PF:001", "PF:002"]),

        rp("pfl-postsecondary", "Planning to Pay for Post-Secondary", .personalFinancialLiteracy,
           "Individual Series", .medium, prep: 10, present: 10,
           situation: """
           A Grade 12 student has been accepted to a program costing about $9,000 per year in tuition plus $12,000 in living costs. They have $6,000 saved, expect a $2,000 scholarship, and are considering borrowing the rest.

           The student's guidance counsellor has asked you to explain the funding options, the true cost of borrowing, and how the student should decide.
           """,
           userRole: "You are a student financial advisor.",
           judgeRole: "The judge is the guidance counsellor.",
           pis: ["PF:008", "PF:007", "PF:001"])
    ]

    static func prompts(for cluster: DECACluster) -> [RoleplayPromptData] {
        all.filter { $0.cluster == cluster }
    }
}

// MARK: - Quick Think scenarios

enum SeedQuickThink {

    static let all: [QuickThinkScenario] = [
        // Marketing
        .init(id: "qt-mkt-1", cluster: .marketing,
              prompt: "A clothing brand's Instagram engagement has dropped 40% in three months even though it posts daily. In 60 seconds, tell the marketing director what you would investigate first and why.",
              focus: "Promotion diagnosis"),
        .init(id: "qt-mkt-2", cluster: .marketing,
              prompt: "A competitor just cut prices 20% below yours. Your owner wants to match immediately. Give your recommendation and justify it.",
              focus: "Pricing strategy"),
        .init(id: "qt-mkt-3", cluster: .marketing,
              prompt: "You have $2,000 to promote a new smoothie at a store near a high school. Explain how you would spend it and how you would measure success.",
              focus: "Promotional mix"),

        // Finance
        .init(id: "qt-fin-1", cluster: .finance,
              prompt: "A client's sales rose 20% but net income fell. Explain two likely reasons and what you would check in the financial statements.",
              focus: "Financial analysis"),
        .init(id: "qt-fin-2", cluster: .finance,
              prompt: "A small business owner asks whether to lease or buy a $50,000 delivery vehicle. Explain the trade-off in plain language.",
              focus: "Financing decisions"),
        .init(id: "qt-fin-3", cluster: .finance,
              prompt: "Your client wants to invest their entire emergency fund in one stock because a friend recommended it. Respond professionally.",
              focus: "Risk management"),

        // Hospitality
        .init(id: "qt-ht-1", cluster: .hospitality,
              prompt: "A tour group of 40 arrives two hours early and the rooms are not ready. Describe how you handle the next 15 minutes.",
              focus: "Guest relations"),
        .init(id: "qt-ht-2", cluster: .hospitality,
              prompt: "Your restaurant's online rating has fallen from 4.6 to 4.1 in one month. Explain your first three actions.",
              focus: "Service quality"),
        .init(id: "qt-ht-3", cluster: .hospitality,
              prompt: "A conference client asks for a 30% discount because a competitor hotel offered one. Give your response and reasoning.",
              focus: "Revenue management"),

        // Business Management
        .init(id: "qt-bma-1", cluster: .businessManagement,
              prompt: "Two team leads are in open conflict and their departments have stopped sharing information. Outline how you would address it.",
              focus: "Leadership"),
        .init(id: "qt-bma-2", cluster: .businessManagement,
              prompt: "Turnover among new hires in their first 90 days has doubled. Explain what you would examine and one change you would make.",
              focus: "Human resources"),
        .init(id: "qt-bma-3", cluster: .businessManagement,
              prompt: "An employee reports that a manager asked them to falsify a delivery log. Explain your immediate response.",
              focus: "Business ethics"),

        // Entrepreneurship
        .init(id: "qt-ent-1", cluster: .entrepreneurship,
              prompt: "You have 60 seconds with an investor in an elevator. Pitch a business that delivers fresh school lunches to secondary students.",
              focus: "Pitching"),
        .init(id: "qt-ent-2", cluster: .entrepreneurship,
              prompt: "Your start-up has four months of cash left and sales are below plan. Describe the decisions you would make this week.",
              focus: "Cash management"),
        .init(id: "qt-ent-3", cluster: .entrepreneurship,
              prompt: "A large competitor has copied your main product feature. Explain how you would protect and grow your position.",
              focus: "Competitive advantage"),

        // Personal Financial Literacy
        .init(id: "qt-pfl-1", cluster: .personalFinancialLiteracy,
              prompt: "A friend says they only ever pay the minimum on their credit card because it keeps their score high. Correct them respectfully.",
              focus: "Credit management"),
        .init(id: "qt-pfl-2", cluster: .personalFinancialLiteracy,
              prompt: "Explain to a 16-year-old why starting to invest at 18 instead of 28 matters, using a concrete example.",
              focus: "Compound growth"),
        .init(id: "qt-pfl-3", cluster: .personalFinancialLiteracy,
              prompt: "A client earning $52,000 wants to buy a $45,000 car with 84-month financing. Give your professional advice.",
              focus: "Spending decisions")
    ]

    static func scenarios(for cluster: DECACluster) -> [QuickThinkScenario] {
        all.filter { $0.cluster == cluster }
    }
}
