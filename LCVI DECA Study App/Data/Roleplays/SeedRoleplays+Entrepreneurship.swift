//
//  SeedRoleplays+Entrepreneurship.swift
//  LCVI DECA Study App
//
//  Entrepreneurship roleplay scenarios.
//
//  Original practice scenarios modelled on the DECA roleplay format.
//  They are NOT official DECA Ontario or DECA Inc. competition materials.
//

import Foundation

extension SeedRoleplays {

    static let entrepreneurship: [RoleplayPromptData] = [

        // MARK: Principles

        rp("ent-p-idea", "Where a Business Idea Comes From", .entrepreneurship, .principles, .easy,
           situation: """
           A classmate wants to start a business but says they "can't think of an idea." They have been waiting for inspiration and are getting discouraged.

           Your business teacher has asked you to explain where workable business ideas actually come from and to walk the classmate through how to find one.
           """,
           userRole: "You are a student entrepreneur mentoring a classmate.",
           judgeRole: "The judge is your business teacher.",
           pis: ["EN:002", "EN:005"]),

        rp("ent-p-ownership", "Choosing a Form of Ownership", .entrepreneurship, .principles, .easy,
           situation: """
           Two friends are starting a lawn-care business together. They plan to operate as a partnership with no written agreement because "we trust each other" and they want to avoid legal fees.

           Their parents have asked you to explain the forms of ownership available and what the friends are exposing themselves to.
           """,
           userRole: "You are a small-business advisor.",
           judgeRole: "The judge is a parent of one of the founders.",
           pis: ["EN:004", "EN:001"]),

        rp("ent-p-advantage", "Why Would Anyone Buy From You?", .entrepreneurship, .principles, .easy,
           situation: """
           A student plans to open a bubble tea stand two doors down from an established shop. Asked why customers would choose them, their answer is "because we'll work harder and care more."

           Your teacher wants you to explain why that answer will not survive a judge's questioning, and help the student find something stronger.
           """,
           userRole: "You are a peer mentor in the school's entrepreneurship club.",
           judgeRole: "The judge is your business teacher.",
           pis: ["EN:005", "EN:002"]),

        // MARK: Individual Series

        rp("ent-pitch", "Pitching a Repair Café Franchise", .entrepreneurship, .individualSeries, .medium,
           situation: """
           You have run a successful electronics repair shop for three years, with $410,000 in annual revenue and 22% net margin. You want to open five more locations across the province but have only $60,000 of your own capital.

           You have a meeting with a potential investor who wants to understand the concept, the competitive advantage, how growth would be financed, and what they would receive in return.
           """,
           userRole: "You are the founder of the repair shop.",
           judgeRole: "The judge is a potential angel investor.",
           pis: ["EN:003", "EN:005", "EN:007", "EN:001"]),

        rp("ent-mvp", "Testing a Concept Before Building It", .entrepreneurship, .individualSeries, .easy,
           situation: """
           Two students want to build an app that matches high-school tutors with younger students. They have quoted $45,000 for full development and want to borrow the money from a family member before any customer has used the product.

           The family member has asked you to advise the founders on how to test the concept first and what evidence would justify the investment.
           """,
           userRole: "You are a small-business advisor.",
           judgeRole: "The judge is the family member considering the loan.",
           pis: ["EN:006", "EN:002", "EN:005"]),

        rp("ent-runway", "Four Months of Cash Left", .entrepreneurship, .individualSeries, .hard,
           situation: """
           A subscription meal-prep start-up has $96,000 in the bank and burns $24,000 a month. Revenue is growing 6% monthly but churn is 11%, so roughly half of new customers are replacing departing ones. The founder wants to spend $40,000 on advertising to accelerate growth.

           An advisor has asked you to review the plan before the money is committed.
           """,
           userRole: "You are a start-up financial advisor.",
           judgeRole: "The judge is the company's founder.",
           pis: ["EN:003", "EN:007", "EN:006"]),

        rp("ent-ip", "Protecting What the Business Has Built", .entrepreneurship, .individualSeries, .medium,
           situation: """
           A founder has developed a distinctive recipe, a brand name now used on packaging in 40 stores, and a piece of software written by a freelancer with no written contract. A larger competitor has just launched a product with a very similar name.

           The founder wants to know what is protected, what is not, and what to do first.
           """,
           userRole: "You are an intellectual property advisor.",
           judgeRole: "The judge is the founder.",
           pis: ["EN:008", "EN:005", "EN:004"]),

        rp("ent-pivot", "Deciding Whether to Pivot", .entrepreneurship, .individualSeries, .hard,
           situation: """
           A venture built a scheduling tool for hair salons. After 14 months it has 60 paying salons and flat growth. Meanwhile, 40% of its usage comes from a handful of dog-grooming businesses that found the product on their own and use it far more intensively.

           The founder is emotionally attached to the salon market and has told you the grooming users are "a distraction."

           They have asked for your honest read.
           """,
           userRole: "You are a start-up advisor.",
           judgeRole: "The judge is the venture's founder.",
           pis: ["EN:002", "EN:006", "EN:005", "EN:007"]),

        // MARK: Team Decision Making

        rp("ent-tdm-scale", "Scaling Before the Model Is Proven", .entrepreneurship, .teamDecisionMaking, .hard,
           situation: """
           A three-city delivery start-up has been offered $2 million to expand to twelve cities within a year. Its customer acquisition cost is $140 and first-year customer value is $120 — the model loses money on every customer today. The founders believe scale will fix the economics through density.

           Your team must recommend whether to take the money, on what terms, and what would have to be true first.
           """,
           userRole: "You are a two-person venture advisory team.",
           judgeRole: "The judge is the lead investor.",
           pis: ["EN:007", "EN:003", "EN:002"]),

        rp("ent-tdm-founders", "A Founder Wants to Leave", .entrepreneurship, .teamDecisionMaking, .hard,
           situation: """
           Eight months into a venture, one of three equal co-founders wants to leave to return to school. There is no vesting agreement, so they would keep a third of the company permanently. The remaining founders are furious, and an investor has made a term sheet conditional on resolving the cap table.

           Your team must recommend how this is handled, what is offered, and what the company should have had in place.
           """,
           userRole: "You are a two-person advisory team.",
           judgeRole: "The judge is one of the remaining co-founders.",
           pis: ["EN:004", "EN:003", "EN:001"]),

        rp("ent-tdm-social", "Balancing Mission and Survival", .entrepreneurship, .teamDecisionMaking, .medium,
           situation: """
           A social enterprise employs and trains people facing barriers to employment, funding itself through a commercial catering arm. A corporate client has offered a contract worth 45% of annual revenue, but requires volumes that would mean hiring experienced staff from outside the programme.

           Taking it funds the mission. Taking it also dilutes the mission.

           Your team must recommend a decision and how the trade-off is managed.
           """,
           userRole: "You are a two-person social enterprise advisory team.",
           judgeRole: "The judge is the enterprise's executive director.",
           pis: ["EN:004", "EN:007", "EN:002", "EN:005"])
    ]
}
