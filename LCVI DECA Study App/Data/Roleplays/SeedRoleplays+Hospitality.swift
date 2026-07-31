//
//  SeedRoleplays+Hospitality.swift
//  LCVI DECA Study App
//
//  Hospitality and Tourism roleplay scenarios.
//
//  Original practice scenarios modelled on the DECA roleplay format.
//  They are NOT official DECA Ontario or DECA Inc. competition materials.
//

import Foundation

extension SeedRoleplays {

    static let hospitality: [RoleplayPromptData] = [

        // MARK: Principles

        rp("ht-p-checkin", "A Guest Whose Room Is Not Ready", .hospitality, .principles, .easy,
           situation: """
           A guest has arrived at 2:30 p.m. for a 3 p.m. check-in. Their room is still being cleaned, the lobby is busy, and the guest has driven five hours with two tired children.

           Your supervisor wants to see how you handle the next few minutes at the desk.
           """,
           userRole: "You are a front-desk agent at the hotel.",
           judgeRole: "The judge is your front-office supervisor.",
           pis: ["HT:004", "HT:002"]),

        rp("ht-p-safety", "Explaining a Food Safety Rule", .hospitality, .principles, .easy,
           situation: """
           A new kitchen helper at the restaurant where you work has been thawing frozen chicken on the counter because "it's faster and it's always been fine."

           The kitchen manager has asked you to explain why that is a problem and what the correct practice is, without making the new employee defensive.
           """,
           userRole: "You are a senior kitchen staff member.",
           judgeRole: "The judge is the kitchen manager.",
           pis: ["HT:005"]),

        rp("ht-p-tourism", "Explaining Why Visitors Matter Locally", .hospitality, .principles, .easy,
           situation: """
           A town council member has said publicly that tourism "only benefits hotel owners" and has questioned funding the visitor centre.

           The tourism office has asked you to explain, in plain terms, how visitor spending moves through a local economy and what the town would lose if the visitor centre closed.
           """,
           userRole: "You are an assistant at the regional tourism office.",
           judgeRole: "The judge is a member of the town council.",
           pis: ["HT:001", "HT:006"]),

        // MARK: Individual Series

        rp("ht-recovery", "Recovering a Ruined Guest Stay", .hospitality, .individualSeries, .easy,
           situation: """
           A guest arrived at your 180-room hotel for a wedding weekend. Their pre-paid suite was not available, they were moved twice, and housekeeping entered the room without knocking. The guest has posted a one-star review and is now standing at the front desk.

           Your general manager wants you to resolve the situation in person and then recommend what should change so it does not happen again.
           """,
           userRole: "You are the front-office manager of the hotel.",
           judgeRole: "The judge is the hotel's general manager.",
           pis: ["HT:004", "HT:002", "HT:008"]),

        rp("ht-revenue", "Filling Midweek Rooms in the Off-Season", .hospitality, .individualSeries, .hard,
           situation: """
           A lakeside resort runs at 82% occupancy on summer weekends but only 31% on midweek nights from October to April. Fixed costs continue year-round. Ownership has proposed a flat 50% discount on all midweek rates.

           Ownership wants your assessment of that proposal and any alternative approaches to raising off-season RevPAR without damaging the resort's rate integrity.
           """,
           userRole: "You are the revenue manager at the resort.",
           judgeRole: "The judge is a member of the ownership group.",
           pis: ["HT:003", "HT:006", "HT:001"]),

        rp("ht-menu", "Fixing a Menu That Sells the Wrong Things", .hospitality, .individualSeries, .medium,
           situation: """
           A 90-seat restaurant has a food cost of 38% against a 30% target. Menu analysis shows the two best-selling dishes carry the thinnest margins, while three high-margin dishes sell fewer than four portions a night and sit at the bottom of the third page.

           The owner's proposed solution is to raise every price by 8%.

           The owner wants your assessment and a recommendation.
           """,
           userRole: "You are a restaurant operations consultant.",
           judgeRole: "The judge is the restaurant owner.",
           pis: ["HT:003", "HT:005"]),

        rp("ht-sustainability", "Making a Sustainability Claim Real", .hospitality, .individualSeries, .medium,
           situation: """
           A boutique hotel has been advertising itself as "the greenest stay in the region." Its only measures are an opt-out linen programme and paper straws. A guest has publicly challenged the claim, and a review site has flagged it.

           The general manager wants to know whether the claim can be defended, and what the hotel would have to do to make it true.
           """,
           userRole: "You are a sustainability consultant.",
           judgeRole: "The judge is the hotel's general manager.",
           pis: ["HT:008", "HT:006", "HT:004"]),

        rp("ht-event", "Rescuing an Event Two Weeks Out", .hospitality, .individualSeries, .hard,
           situation: """
           A 400-guest awards dinner is booked in 14 days. The contracted audiovisual supplier has gone out of business, the client has added a livestream requirement, and the guaranteed guest count is due in three days at a number the client has not confirmed.

           The director of events wants a plan covering all three problems and the order you would address them in.
           """,
           userRole: "You are the catering and events manager.",
           judgeRole: "The judge is the hotel's director of events.",
           pis: ["HT:007", "HT:004", "HT:003"]),

        // MARK: Team Decision Making

        rp("ht-tdm-overtourism", "Managing a Destination Under Strain", .hospitality, .teamDecisionMaking, .hard,
           situation: """
           A small waterfront town of 4,000 residents receives 900,000 visitors a year, concentrated in ten summer weeks. Parking, water and waste systems are overwhelmed, short-term rentals have pushed housing beyond local wages, and a residents' group is campaigning to cap visitor numbers. Tourism supports roughly 40% of local employment.

           Your team must present a plan that protects both the community and the visitor economy.
           """,
           userRole: "You are a two-person destination management team.",
           judgeRole: "The judge is the chair of the regional tourism board.",
           pis: ["HT:001", "HT:006", "HT:008"]),

        rp("ht-tdm-group", "Deciding on a Large Group Booking", .hospitality, .teamDecisionMaking, .hard,
           situation: """
           A conference organiser wants 120 rooms a night for four nights in your peak season at $149, against a forecast transient rate of $229. They would also spend an estimated $60,000 on catering and meeting space, and they are offering a three-year commitment.

           Your hotel has 240 rooms and forecasts 88% occupancy for those dates without the group.

           Your team must recommend accepting, countering or declining, and show the reasoning.
           """,
           userRole: "You are a two-person revenue and sales team.",
           judgeRole: "The judge is the hotel's general manager.",
           pis: ["HT:003", "HT:007", "HT:001"]),

        rp("ht-tdm-outbreak", "Handling a Suspected Foodborne Illness", .hospitality, .teamDecisionMaking, .hard,
           situation: """
           Four guests who attended the same banquet on Saturday have reported illness. Public health has been notified and will inspect tomorrow. Kitchen temperature logs for Saturday are incomplete. A local reporter has called twice, and 300 guests are booked for a similar banquet on Friday.

           Your team must decide what happens in the kitchen, what is said publicly, and what happens to Friday's event.
           """,
           userRole: "You are a two-person management team.",
           judgeRole: "The judge is the property's general manager.",
           pis: ["HT:005", "HT:004", "HT:007"]),

        // MARK: Hospitality and Tourism Professional Selling

        rp("ht-psell-corporate", "Winning a Corporate Travel Account", .hospitality, .professionalSelling, .medium,
           situation: """
           You are pitching your 220-room property to a company that sends roughly 900 room-nights a year to a competitor two blocks away. The competitor is $12 a night cheaper and the travel manager has said price is the deciding factor.

           Your property has a better meeting space, a shuttle the competitor lacks, and considerably higher guest satisfaction scores.

           You have 15 minutes.
           """,
           userRole: "You are a hotel sales manager.",
           judgeRole: "The judge is the company's corporate travel manager.",
           pis: ["HT:003", "HT:004", "HT:007"]),

        rp("ht-psell-tour", "Selling a Destination Package", .hospitality, .professionalSelling, .hard,
           situation: """
           You represent a regional tour operator. Your prospect is a school board considering a three-day educational trip for 80 students. The board's previous provider was cheaper but left two groups without transport on the final day, and the board is now nervous about the whole idea.

           Your goal is to win the booking by addressing the risk directly rather than avoiding it.
           """,
           userRole: "You are a sales representative for the tour operator.",
           judgeRole: "The judge is the school board's trip coordinator.",
           pis: ["HT:007", "HT:004", "HT:006"])
    ]
}
