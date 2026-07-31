//
//  SeedRoleplays+Finance.swift
//  LCVI DECA Study App
//
//  Finance roleplay scenarios.
//
//  Original practice scenarios modelled on the DECA roleplay format.
//  They are NOT official DECA Ontario or DECA Inc. competition materials.
//

import Foundation

extension SeedRoleplays {

    static let finance: [RoleplayPromptData] = [

        // MARK: Principles

        rp("fin-p-statements", "Reading a Statement for the First Time", .finance, .principles, .easy,
           situation: """
           A student-run school store has been operating for a year. The teacher supervising it has printed an income statement and a balance sheet but the new student treasurer does not know what either one shows.

           The teacher has asked you to explain what each statement reports, how they differ, and one thing the treasurer should watch each month.
           """,
           userRole: "You are the outgoing student treasurer.",
           judgeRole: "The judge is the teacher who supervises the school store.",
           pis: ["FI:001", "FI:005"]),

        rp("fin-p-credit", "Explaining the Cost of Carrying a Balance", .finance, .principles, .easy,
           situation: """
           A part-time employee at the business where you work has just received their first credit card. They have told you they plan to pay only the minimum each month because "that keeps the card active and the score high."

           Your manager has asked you to explain, plainly and without lecturing, what carrying a balance actually costs and what you would recommend instead.
           """,
           userRole: "You are a peer financial-literacy mentor at the workplace.",
           judgeRole: "The judge is your manager.",
           pis: ["FI:003", "FI:007"]),

        rp("fin-p-budget", "Building a First Departmental Budget", .finance, .principles, .easy,
           situation: """
           A school athletics department has always spent whatever it needed and asked for more when it ran out. The principal now wants a budget prepared before the season.

           The principal wants you to explain what a budget is for, what information you would need to build one, and how the department would know during the season whether it was on track.
           """,
           userRole: "You are a student assistant in the school's business office.",
           judgeRole: "The judge is the school principal.",
           pis: ["FI:005", "FI:001"]),

        // MARK: Individual Series

        rp("fin-ratios", "Explaining the Numbers to a Franchise Owner", .finance, .individualSeries, .medium,
           situation: """
           A franchisee operating two quick-service restaurants has strong sales but is repeatedly short of cash. Their current ratio has fallen from 1.8 to 0.9 in one year while revenue grew 12%.

           The franchisee does not have an accounting background and wants a plain-language explanation of what the numbers show, why profitable stores can run out of cash, and what should change in the next quarter.
           """,
           userRole: "You are a financial analyst at the franchisee's bank.",
           judgeRole: "The judge is the franchise owner.",
           pis: ["FI:002", "FI:001", "FI:007", "FI:005"]),

        rp("fin-risk", "Building a Risk Plan for a Growing Business", .finance, .individualSeries, .medium,
           situation: """
           A landscaping company has grown from 4 to 22 employees in two years. It now owns $340,000 of equipment, operates seven vehicles, and works on client property daily. The owner carries only basic liability coverage and has no formal risk plan.

           The owner wants to understand the main categories of risk the business faces and how each should be handled.
           """,
           userRole: "You are a risk-management advisor.",
           judgeRole: "The judge is the owner of the landscaping company.",
           pis: ["FI:006", "FI:005", "FI:004"]),

        rp("fin-breakeven", "Deciding Whether to Open a Second Location", .finance, .individualSeries, .hard,
           situation: """
           A bubble tea shop clears $18,000 a month in revenue at one location with a 62% contribution margin. The owner has found a second unit with rent and fixed costs totalling $9,400 a month and wants to sign a five-year lease this week.

           The owner has not calculated what the new location needs to sell to cover itself, and has no reserve beyond two months of operating cash.

           They want your analysis and a recommendation.
           """,
           userRole: "You are a financial consultant.",
           judgeRole: "The judge is the owner of the bubble tea shop.",
           pis: ["FI:009", "FI:005", "FI:004"]),

        rp("fin-receivables", "Fixing a Collection Problem", .finance, .individualSeries, .medium,
           situation: """
           A commercial cleaning company invoices 60 business clients monthly on net-30 terms. Its average collection period has stretched to 68 days, and the owner has twice covered payroll from a personal line of credit. The owner is reluctant to press clients because "they'll go somewhere else."

           The owner wants to know what to change without losing the customer base.
           """,
           userRole: "You are a working-capital advisor.",
           judgeRole: "The judge is the owner of the cleaning company.",
           pis: ["FI:007", "FI:002", "FI:005"]),

        rp("fin-controls", "Closing a Cash Control Gap", .finance, .individualSeries, .medium,
           situation: """
           A garden centre with nine employees has one long-serving bookkeeper who opens the mail, records payments, prepares the deposit, takes it to the bank and reconciles the account. The owner trusts them completely and is offended by the suggestion that anything should change.

           The owner's accountant has asked you to explain why the arrangement is a problem and what can realistically be done in a business this size.
           """,
           userRole: "You are an accounting advisor.",
           judgeRole: "The judge is the owner of the garden centre.",
           pis: ["FI:010", "FI:006", "FI:001"]),

        // MARK: Team Decision Making

        rp("fin-tdm-expansion", "Choosing How to Fund Expansion", .finance, .teamDecisionMaking, .hard,
           situation: """
           A regional courier company needs $1.2 million to buy 15 vehicles and expand into two new cities. It has three options: a bank loan at 8% over seven years, an equity investment from a private investor wanting 30% of the company, or leasing the vehicles at a higher total cost with no ownership.

           The company is profitable, has a debt-to-equity ratio of 0.7, and the two founders are strongly opposed to giving up control — though one is beginning to reconsider.

           Your team must recommend a financing approach and defend it.
           """,
           userRole: "You are a two-person corporate finance team.",
           judgeRole: "The judge is the company's board chair.",
           pis: ["FI:004", "FI:002", "FI:006", "FI:005"]),

        rp("fin-tdm-downturn", "Planning Through a Revenue Decline", .finance, .teamDecisionMaking, .hard,
           situation: """
           A manufacturer's largest customer, representing 38% of revenue, has given notice it will not renew next year. The company has four months of cash, fixed costs of $210,000 a month, and 60 employees. Management is split between cutting costs immediately and investing in sales to replace the account.

           Your team must present a plan for the next twelve months, including what is cut, what is protected, and how the decision will be reviewed.
           """,
           userRole: "You are a two-person financial planning team.",
           judgeRole: "The judge is the company's chief executive.",
           pis: ["FI:005", "FI:006", "FI:002", "FI:004"]),

        rp("fin-tdm-fraud", "Responding to a Suspected Irregularity", .finance, .teamDecisionMaking, .hard,
           situation: """
           A monthly exception report has flagged twelve payments totalling $46,000 to a supplier no one in operations recognises. All twelve were approved by the same manager, who has been with the company eleven years and is currently on vacation.

           Nothing is proven. Handling it badly could destroy a career or destroy the evidence.

           Your team must recommend what the company does in the next week, in what order, and who is told.
           """,
           userRole: "You are a two-person internal audit team.",
           judgeRole: "The judge is the chief financial officer.",
           pis: ["FI:010", "FI:006", "FI:001"]),

        // MARK: Financial Consulting

        rp("fin-fce-retirement", "Advising a Client Who Wants a Guarantee", .finance, .professionalSelling, .medium,
           situation: """
           Your client is 34, earns $71,000, has $12,000 in a savings account and no registered investments. They have told you they want "something with high returns and no risk" and mentioned a cryptocurrency a colleague recommended that "cannot go down."

           You have 15 minutes to understand their situation and give advice they will actually act on.
           """,
           userRole: "You are a financial consultant.",
           judgeRole: "The judge is your client.",
           pis: ["FI:003", "FI:006", "FI:008"]),

        rp("fin-fce-business", "Advising a Business Banking Client", .finance, .professionalSelling, .hard,
           situation: """
           A commercial client operates a seasonal landscaping business. Revenue runs from April to October, but payroll, equipment and insurance run all year. Last winter the owner covered a shortfall on a credit card at 21%.

           The owner is in your branch to ask about "a loan." Your task is to understand the underlying problem and recommend the right structure, which may not be a term loan at all.
           """,
           userRole: "You are a business banking advisor.",
           judgeRole: "The judge is the owner of the landscaping business.",
           pis: ["FI:004", "FI:005", "FI:008", "FI:007"])
    ]
}
