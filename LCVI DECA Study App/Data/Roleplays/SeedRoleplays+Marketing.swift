//
//  SeedRoleplays+Marketing.swift
//  LCVI DECA Study App
//
//  Marketing roleplay scenarios.
//
//  Original practice scenarios modelled on the DECA roleplay format.
//  They are NOT official DECA Ontario or DECA Inc. competition materials.
//

import Foundation

extension SeedRoleplays {

    static let marketing: [RoleplayPromptData] = [

        // MARK: Principles — first-year, one clear concept each

        rp("mkt-p-segment", "Choosing Who to Sell To", .marketing, .principles, .easy,
           situation: """
           A family-run ice cream shop near a high school has always advertised to "everyone in town." Sales are flat and the owner is frustrated that the ads do not seem to work.

           The owner has asked you to explain who the shop should actually be targeting and why narrowing the audience could improve results rather than shrink them.
           """,
           userRole: "You are a marketing assistant advising the shop.",
           judgeRole: "The judge is the owner of the ice cream shop.",
           pis: ["MK:006", "MK:001", "MK:004"]),

        rp("mkt-p-promo", "Choosing the Right Promotion", .marketing, .principles, .easy,
           situation: """
           A local bookstore has $800 to spend promoting a weekend author visit. The owner's first instinct is to buy a newspaper advertisement because that is what the shop has always done.

           The owner wants you to explain the elements of the promotional mix and recommend how to spend the $800 to get the most people through the door.
           """,
           userRole: "You are a marketing student helping the bookstore.",
           judgeRole: "The judge is the bookstore owner.",
           pis: ["MK:004", "MK:010", "MK:001"]),

        rp("mkt-p-service", "Turning a Complaint Into a Regular", .marketing, .principles, .easy,
           situation: """
           A customer bought a pair of headphones at your electronics store last week. They stopped working after three days, and when the customer came back an associate told them to contact the manufacturer themselves. The customer is now at the counter, visibly annoyed.

           Your manager wants to see how you handle the customer, and what you would suggest so this does not happen again.
           """,
           userRole: "You are a sales associate at the electronics store.",
           judgeRole: "The judge is your store manager.",
           pis: ["MK:009", "MK:001"]),

        // MARK: Individual Series

        rp("mkt-launch", "Launching a Student Meal Subscription", .marketing, .individualSeries, .medium,
           situation: """
           A campus café chain wants to grow weekday lunch traffic, which has fallen 14% since students began ordering delivery. The owner is considering a prepaid meal subscription: students pay $60 per month for one lunch every weekday.

           Before committing, the owner wants to understand how the subscription should be priced and promoted, which student segments it should target, and what risks the café should plan for.
           """,
           userRole: "You are a marketing consultant hired by the café chain.",
           judgeRole: "The judge is the owner of the café chain.",
           pis: ["MK:002", "MK:006", "MK:010", "MK:001"]),

        rp("mkt-rebrand", "Repositioning a Struggling Retailer", .marketing, .individualSeries, .hard,
           situation: """
           A 30-year-old family sporting-goods store is losing sales to large online retailers. Its customers are loyal but aging, and shoppers under 25 rarely visit. The owner refuses to compete on price.

           The owner has asked for a repositioning plan that explains how the store should be perceived differently, which segments it should pursue, and how promotion should change to support that position.
           """,
           userRole: "You are a marketing strategist hired by the store owner.",
           judgeRole: "The judge is the store owner.",
           pis: ["MK:008", "MK:005", "MK:006", "MK:004"]),

        rp("mkt-social", "Rebuilding a Collapsed Social Presence", .marketing, .individualSeries, .medium,
           situation: """
           A regional bakery chain has 42,000 followers but engagement has fallen 60% in four months. The marketing coordinator posts product photos daily at 9 a.m. Analytics show most of the audience is aged 18–24 and active in the evening, and that the three best-performing posts of the past year were all staff filming behind the counter.

           The owner wants to know whether to keep investing in social media and, if so, what should change.
           """,
           userRole: "You are a digital marketing consultant.",
           judgeRole: "The judge is the owner of the bakery chain.",
           pis: ["MK:010", "MK:004", "MK:007"]),

        rp("mkt-research", "Testing the Evidence Before a Product Decision", .marketing, .individualSeries, .medium,
           situation: """
           A juice company is considering a lower-sugar version of its best-selling drink. The product manager surveyed 40 of the company's most loyal customers, 85% of whom said they would buy it, and now wants to move to full production.

           The vice-president is uneasy about the strength of that evidence and has asked for your assessment of the research and a recommendation on what to do before committing.
           """,
           userRole: "You are a marketing research analyst.",
           judgeRole: "The judge is the vice-president of marketing.",
           pis: ["MK:007", "MK:005", "MK:008"]),

        rp("mkt-channel", "Adding Direct Sales Without Losing Retailers", .marketing, .individualSeries, .hard,
           situation: """
           A snack manufacturer sells through 300 independent grocers. It now wants to sell directly to consumers online at a lower price than the grocers charge. Two of its largest accounts have already heard about the plan and are threatening to drop the line.

           The president wants a recommendation that lets the company reach consumers directly without destroying the retail relationships that produce most of its revenue.
           """,
           userRole: "You are a channel strategy consultant.",
           judgeRole: "The judge is the president of the manufacturer.",
           pis: ["MK:003", "MK:002", "MK:001"]),

        // MARK: Team Decision Making — 30 minutes prep, two competitors

        rp("mkt-tdm-launch", "Taking a Regional Brand National", .marketing, .teamDecisionMaking, .hard,
           situation: """
           A hot sauce company sells strongly in one province through independent grocers and farmers' markets. A national grocery chain has offered shelf space in 400 stores, but requires a 32% lower wholesale price, a new package size, and a $90,000 contribution to in-store promotion.

           The company can accept, negotiate or decline. Accepting would more than double volume but would compress margin and strain a production facility already running at 78% capacity.

           Your team has been asked to evaluate the offer and present a recommendation with the reasoning behind it.
           """,
           userRole: "You are a two-person marketing strategy team.",
           judgeRole: "The judge is the company's founder and CEO.",
           pis: ["MK:003", "MK:002", "MK:001", "MK:005"]),

        rp("mkt-tdm-crisis", "Responding to a Viral Complaint", .marketing, .teamDecisionMaking, .hard,
           situation: """
           A video showing a staff member at one of your 60 franchise locations mishandling food has been viewed 2.4 million times in 36 hours. The franchisee has already dismissed the employee. Head office has said nothing publicly. Comments are spreading to locations with no connection to the incident, and two corporate clients have paused their catering orders.

           Your team must recommend how the brand responds over the next 48 hours, and what it does over the following month to rebuild trust.
           """,
           userRole: "You are a two-person brand communications team.",
           judgeRole: "The judge is the chief marketing officer.",
           pis: ["MK:004", "MK:009", "MK:010", "MK:008"]),

        rp("mkt-tdm-sponsor", "Valuing a Sponsorship Opportunity", .marketing, .teamDecisionMaking, .medium,
           situation: """
           A sports drink brand has been offered the naming rights to a junior hockey arena for $250,000 a year over three years. The arena hosts 140 events annually with average attendance of 2,800, and its audience skews heavily toward families with children aged 8–16 — a segment the brand does not currently reach.

           The same budget could instead fund a national social campaign the brand has already modelled.

           Your team must recommend which investment to make, and how success would be measured either way.
           """,
           userRole: "You are a two-person marketing team.",
           judgeRole: "The judge is the brand's marketing director.",
           pis: ["MK:004", "MK:006", "MK:010", "MK:005"]),

        // MARK: Professional Selling

        rp("mkt-psell-pos", "Selling a Point-of-Sale System", .marketing, .professionalSelling, .medium,
           situation: """
           You sell point-of-sale systems to independent retailers. Your appointment is with the owner of three clothing boutiques who uses a five-year-old system that does not connect between locations, so stock is counted by hand at each store every week.

           The owner told you on the phone that they are "probably fine for now" and that a competitor quoted a price 20% below yours.

           You have 15 minutes to make your case.
           """,
           userRole: "You are a sales representative for the point-of-sale company.",
           judgeRole: "The judge is the owner of the three boutiques.",
           pis: ["MK:009", "MK:002", "MK:001"]),

        rp("mkt-psell-ad", "Selling Advertising to a Reluctant Buyer", .marketing, .professionalSelling, .hard,
           situation: """
           You sell advertising for a regional streaming service with strong local audience data. Your prospect is a family restaurant group that has spent its entire promotional budget on printed flyers for eleven years. The owner says flyers "have always worked" but cannot say how many customers they bring in.

           Your goal is a three-month trial campaign, not a signature on a year-long contract.
           """,
           userRole: "You are an advertising sales representative.",
           judgeRole: "The judge is the owner of the restaurant group.",
           pis: ["MK:004", "MK:007", "MK:009", "MK:010"])
    ]
}
