//
//  SeedQuickThink.swift
//  LCVI DECA Study App
//
//  Quick Think prompts: one situation, roughly sixty seconds to answer out loud.
//
//  These are deliberately not miniature roleplays. A roleplay rewards structure
//  built during ten minutes of preparation; Quick Think rewards the thing that
//  actually collapses under pressure — committing to a position immediately and
//  supporting it. Every prompt therefore names a decision the student has to
//  make, not a topic to discuss.
//
//  Selection is cluster-keyed, matching the roleplays. `focus` is shown to the
//  student and is what the written feedback anchors on when no AI is available.
//
//  Original practice prompts written for this app. They are NOT official DECA
//  Ontario or DECA Inc. competition materials.
//

import Foundation

enum SeedQuickThink {

    static let all: [QuickThinkScenario] = marketing + finance + hospitality
        + businessManagement + entrepreneurship + personalFinance

    static func scenarios(for cluster: DECACluster) -> [QuickThinkScenario] {
        all.filter { $0.cluster == cluster }
    }

    // MARK: - Marketing

    static let marketing: [QuickThinkScenario] = [
        .init(id: "qt-mkt-1", cluster: .marketing,
              prompt: "A clothing brand's Instagram engagement has dropped 40% in three months even though it posts daily. In 60 seconds, tell the marketing director what you would investigate first and why.",
              focus: "Promotion diagnosis"),
        .init(id: "qt-mkt-2", cluster: .marketing,
              prompt: "A competitor just cut prices 20% below yours. Your owner wants to match immediately. Give your recommendation and justify it.",
              focus: "Pricing strategy"),
        .init(id: "qt-mkt-3", cluster: .marketing,
              prompt: "You have $2,000 to promote a new smoothie at a store near a high school. Explain how you would spend it and how you would measure success.",
              focus: "Promotional mix"),
        .init(id: "qt-mkt-4", cluster: .marketing,
              prompt: "Your client insists their target market is \"everyone aged 18 to 65.\" Explain in 60 seconds why that will cost them money.",
              focus: "Segmentation"),
        .init(id: "qt-mkt-5", cluster: .marketing,
              prompt: "A product's sales have been flat for two years in a crowded market. Name the life-cycle stage and one action you would take.",
              focus: "Product life cycle"),
        .init(id: "qt-mkt-6", cluster: .marketing,
              prompt: "A survey of your most loyal customers says 90% would buy a new premium line. Your VP wants to launch. What is your concern?",
              focus: "Research validity"),
        .init(id: "qt-mkt-7", cluster: .marketing,
              prompt: "A retailer wants to stock your product but demands exclusive rights in the whole province. Give your answer and your reasoning.",
              focus: "Channel management"),
        .init(id: "qt-mkt-8", cluster: .marketing,
              prompt: "Your brand is known as \"cheap.\" The owner wants to move upmarket without losing current customers. Give your first recommendation.",
              focus: "Positioning"),
        .init(id: "qt-mkt-9", cluster: .marketing,
              prompt: "A one-star review describes a real failure at your store. Draft your public reply out loud.",
              focus: "Reputation management"),
        .init(id: "qt-mkt-10", cluster: .marketing,
              prompt: "An influencer with 900,000 followers wants $12,000 to post about your product. Your product costs $30. Talk through the decision.",
              focus: "Influencer marketing"),
        .init(id: "qt-mkt-11", cluster: .marketing,
              prompt: "Marketing says the campaign delivered 4 million impressions. The owner asks whether it worked. Answer the owner's actual question.",
              focus: "Marketing metrics"),
        .init(id: "qt-mkt-12", cluster: .marketing,
              prompt: "A new competitor has opened across the street with lower prices. Name the two things you would examine before responding at all.",
              focus: "Competitive analysis"),
        .init(id: "qt-mkt-13", cluster: .marketing,
              prompt: "Your company wants to email its full customer list a promotion. Name the requirements you would insist on before it is sent.",
              focus: "Digital compliance"),
        .init(id: "qt-mkt-14", cluster: .marketing,
              prompt: "A loyal customer of eleven years has had one bad experience and is threatening to leave. You have 60 seconds with them.",
              focus: "Customer retention"),
        .init(id: "qt-mkt-15", cluster: .marketing,
              prompt: "Your product is a convenience item selling in 12 stores. The owner wants exclusive distribution to look premium. Respond.",
              focus: "Distribution intensity")
    ]

    // MARK: - Finance

    static let finance: [QuickThinkScenario] = [
        .init(id: "qt-fin-1", cluster: .finance,
              prompt: "A client's sales rose 20% but net income fell. Explain two likely reasons and what you would check in the financial statements.",
              focus: "Financial analysis"),
        .init(id: "qt-fin-2", cluster: .finance,
              prompt: "A small business owner asks whether to lease or buy a $50,000 delivery vehicle. Explain the trade-off in plain language.",
              focus: "Financing decisions"),
        .init(id: "qt-fin-3", cluster: .finance,
              prompt: "Your client wants to invest their entire emergency fund in one stock because a friend recommended it. Respond professionally.",
              focus: "Risk management"),
        .init(id: "qt-fin-4", cluster: .finance,
              prompt: "A profitable business cannot make payroll on Friday. Explain to the owner how both things can be true at once.",
              focus: "Profit versus cash"),
        .init(id: "qt-fin-5", cluster: .finance,
              prompt: "A company's current ratio is 3.5, well above its industry. The owner is delighted. Give your assessment.",
              focus: "Ratio interpretation"),
        .init(id: "qt-fin-6", cluster: .finance,
              prompt: "Fixed costs are $60,000, the price is $80 and variable cost is $50. State the break-even volume and what it means for the plan.",
              focus: "Break-even analysis"),
        .init(id: "qt-fin-7", cluster: .finance,
              prompt: "One employee opens the mail, records payments, makes the deposit and reconciles the account. Explain the risk to the owner who trusts them.",
              focus: "Internal controls"),
        .init(id: "qt-fin-8", cluster: .finance,
              prompt: "A client is offered 2/10 net 30 on a $20,000 invoice and asks whether taking the discount is worth it. Answer.",
              focus: "Credit terms"),
        .init(id: "qt-fin-9", cluster: .finance,
              prompt: "Average collection has stretched from 32 days to 71. Name your first three actions and what you would not do.",
              focus: "Receivables"),
        .init(id: "qt-fin-10", cluster: .finance,
              prompt: "A seasonal business wants a five-year term loan to cover a two-month winter shortfall. Give your recommendation.",
              focus: "Matching principle"),
        .init(id: "qt-fin-11", cluster: .finance,
              prompt: "A department overspent its budget by 9%. The manager says volume was higher than planned. How do you evaluate that claim?",
              focus: "Budget variance"),
        .init(id: "qt-fin-12", cluster: .finance,
              prompt: "A business has a debt-to-equity ratio of 2.4 and sales are softening. Explain to the board why that combination concerns you.",
              focus: "Leverage"),
        .init(id: "qt-fin-13", cluster: .finance,
              prompt: "A machine costs $120,000 and saves $30,000 a year. State the payback period and one limitation of judging by it alone.",
              focus: "Capital budgeting"),
        .init(id: "qt-fin-14", cluster: .finance,
              prompt: "A client asks why they should insure against a fire that has a 1% chance of happening. Answer using expected loss.",
              focus: "Risk transfer"),
        .init(id: "qt-fin-15", cluster: .finance,
              prompt: "An owner wants to raise money by selling 40% of the company rather than borrowing. Lay out the trade-off in 60 seconds.",
              focus: "Debt versus equity")
    ]

    // MARK: - Hospitality and Tourism

    static let hospitality: [QuickThinkScenario] = [
        .init(id: "qt-ht-1", cluster: .hospitality,
              prompt: "A tour group of 40 arrives two hours early and the rooms are not ready. Describe how you handle the next 15 minutes.",
              focus: "Guest relations"),
        .init(id: "qt-ht-2", cluster: .hospitality,
              prompt: "Your restaurant's online rating has fallen from 4.6 to 4.1 in one month. Explain your first three actions.",
              focus: "Service quality"),
        .init(id: "qt-ht-3", cluster: .hospitality,
              prompt: "A conference client asks for a 30% discount because a competitor hotel offered one. Give your response and reasoning.",
              focus: "Revenue management"),
        .init(id: "qt-ht-4", cluster: .hospitality,
              prompt: "You can sell tonight's last room for $89 now, or hold it for a possible $220 walk-in. Decide out loud and justify it.",
              focus: "Perishable inventory"),
        .init(id: "qt-ht-5", cluster: .hospitality,
              prompt: "A cook has been thawing chicken on the counter for months with no incident. Explain the problem to them without alienating them.",
              focus: "Food safety"),
        .init(id: "qt-ht-6", cluster: .hospitality,
              prompt: "A guest is furious about noise from a wedding that runs until 11 p.m. You cannot stop the wedding. Handle it.",
              focus: "Service recovery"),
        .init(id: "qt-ht-7", cluster: .hospitality,
              prompt: "A group wants 90 rooms at $120 on your busiest weekend, when transient demand would pay $210. Talk through the decision.",
              focus: "Displacement analysis"),
        .init(id: "qt-ht-8", cluster: .hospitality,
              prompt: "Residents say tourism has made their town unaffordable. You represent the tourism board. Respond honestly.",
              focus: "Community impact"),
        .init(id: "qt-ht-9", cluster: .hospitality,
              prompt: "Your hotel advertises itself as sustainable but only offers a towel reuse card. A journalist asks you to justify it.",
              focus: "Sustainability claims"),
        .init(id: "qt-ht-10", cluster: .hospitality,
              prompt: "The audiovisual supplier for tomorrow's 300-person banquet has just cancelled. State your next four moves in order.",
              focus: "Event contingency"),
        .init(id: "qt-ht-11", cluster: .hospitality,
              prompt: "A client guaranteed 250 covers and 210 arrived. They are refusing to pay for 250. Explain the contract to them.",
              focus: "Event contracts"),
        .init(id: "qt-ht-12", cluster: .hospitality,
              prompt: "Your food cost is 38% against a 30% target. The owner wants to raise every menu price 8%. Give your assessment.",
              focus: "Cost control"),
        .init(id: "qt-ht-13", cluster: .hospitality,
              prompt: "Occupancy is 92% but RevPAR is flat year over year. Explain to ownership what that combination tells you.",
              focus: "Performance metrics"),
        .init(id: "qt-ht-14", cluster: .hospitality,
              prompt: "A guest with a mobility need has arrived and the accessible room was given away. Handle the next five minutes.",
              focus: "Accessibility"),
        .init(id: "qt-ht-15", cluster: .hospitality,
              prompt: "Two thirds of your bookings now come through online travel agencies at 18% commission. Give the owner your view.",
              focus: "Distribution cost")
    ]

    // MARK: - Business Management and Administration

    static let businessManagement: [QuickThinkScenario] = [
        .init(id: "qt-bma-1", cluster: .businessManagement,
              prompt: "Two team leads are in open conflict and their departments have stopped sharing information. Outline how you would address it.",
              focus: "Leadership"),
        .init(id: "qt-bma-2", cluster: .businessManagement,
              prompt: "Turnover among new hires in their first 90 days has doubled. Explain what you would examine and one change you would make.",
              focus: "Human resources"),
        .init(id: "qt-bma-3", cluster: .businessManagement,
              prompt: "An employee reports that a manager asked them to falsify a delivery log. Explain your immediate response.",
              focus: "Business ethics"),
        .init(id: "qt-bma-4", cluster: .businessManagement,
              prompt: "A worker refuses a task they believe is unsafe and the supervisor tells them to do it anyway. State what happens next.",
              focus: "Health and safety"),
        .init(id: "qt-bma-5", cluster: .businessManagement,
              prompt: "A policy is being ignored by almost every employee. Your director wants stricter enforcement. Give your recommendation.",
              focus: "Policy design"),
        .init(id: "qt-bma-6", cluster: .businessManagement,
              prompt: "Staff are resisting new software that management chose without consulting them. Describe how you would recover the rollout.",
              focus: "Change management"),
        .init(id: "qt-bma-7", cluster: .businessManagement,
              prompt: "A manager wants to measure the support team on calls per hour alone. Explain what will happen and what you would add.",
              focus: "Performance measurement"),
        .init(id: "qt-bma-8", cluster: .businessManagement,
              prompt: "An interviewer asks a candidate whether they have young children. Explain the problem and what you do about it.",
              focus: "Employment law"),
        .init(id: "qt-bma-9", cluster: .businessManagement,
              prompt: "A purchasing manager's sibling owns a company bidding on your contract. State what should happen.",
              focus: "Conflict of interest"),
        .init(id: "qt-bma-10", cluster: .businessManagement,
              prompt: "Your production line's slowest step is finishing, but the owner keeps buying more cutting machines. Explain the error.",
              focus: "Operational efficiency"),
        .init(id: "qt-bma-11", cluster: .businessManagement,
              prompt: "A high performer is openly rude to junior staff. Their manager says results are what matter. Respond.",
              focus: "Culture and leadership"),
        .init(id: "qt-bma-12", cluster: .businessManagement,
              prompt: "An employee requests accommodation for a disability and the manager says it is too expensive. Explain the obligation.",
              focus: "Human rights"),
        .init(id: "qt-bma-13", cluster: .businessManagement,
              prompt: "Your company depends on one supplier for a critical part. The supplier is reliable. Explain why you are still concerned.",
              focus: "Risk and continuity"),
        .init(id: "qt-bma-14", cluster: .businessManagement,
              prompt: "A department head wants to hire someone exactly like themselves \"because it works.\" Give your view in 60 seconds.",
              focus: "Recruitment"),
        .init(id: "qt-bma-15", cluster: .businessManagement,
              prompt: "Management has set a goal to \"improve customer service this year.\" Rewrite it out loud so it can actually be managed.",
              focus: "Goal setting")
    ]

    // MARK: - Entrepreneurship

    static let entrepreneurship: [QuickThinkScenario] = [
        .init(id: "qt-ent-1", cluster: .entrepreneurship,
              prompt: "You have 60 seconds with an investor in an elevator. Pitch a business that delivers fresh school lunches to secondary students.",
              focus: "Pitching"),
        .init(id: "qt-ent-2", cluster: .entrepreneurship,
              prompt: "Your start-up has four months of cash left and sales are below plan. Describe the decisions you would make this week.",
              focus: "Cash management"),
        .init(id: "qt-ent-3", cluster: .entrepreneurship,
              prompt: "A large competitor has copied your main product feature. Explain how you would protect and grow your position.",
              focus: "Competitive advantage"),
        .init(id: "qt-ent-4", cluster: .entrepreneurship,
              prompt: "A founder says their advantage is that they \"work harder than everyone else.\" Explain why an investor will not accept that.",
              focus: "Defensibility"),
        .init(id: "qt-ent-5", cluster: .entrepreneurship,
              prompt: "Ninety percent of surveyed people said they would buy your product. None have paid anything. Explain what you actually know.",
              focus: "Validation"),
        .init(id: "qt-ent-6", cluster: .entrepreneurship,
              prompt: "Your customer acquisition cost is $180 and first-year customer value is $150. The founder wants to spend more on ads. Respond.",
              focus: "Unit economics"),
        .init(id: "qt-ent-7", cluster: .entrepreneurship,
              prompt: "Two founders are splitting equity 50/50 with no vesting. Explain the risk before they sign.",
              focus: "Founder agreements"),
        .init(id: "qt-ent-8", cluster: .entrepreneurship,
              prompt: "An investor offers $250,000 for 20%. State the implied valuation and one question you would ask before accepting.",
              focus: "Valuation"),
        .init(id: "qt-ent-9", cluster: .entrepreneurship,
              prompt: "A freelancer built your core software with no written contract. Explain the problem and what you do about it now.",
              focus: "Intellectual property"),
        .init(id: "qt-ent-10", cluster: .entrepreneurship,
              prompt: "Most of your product's usage comes from a customer group you never targeted. Talk through what you would do.",
              focus: "Pivoting"),
        .init(id: "qt-ent-11", cluster: .entrepreneurship,
              prompt: "A founder wants to build every feature before launching. Make the case for shipping something smaller first.",
              focus: "Minimum viable product"),
        .init(id: "qt-ent-12", cluster: .entrepreneurship,
              prompt: "Your business is growing 15% a month and losing money on every customer. Explain to the founder why that is dangerous.",
              focus: "Scaling"),
        .init(id: "qt-ent-13", cluster: .entrepreneurship,
              prompt: "A customer describes your problem as \"annoying but liveable.\" Explain what that tells you about the business.",
              focus: "Customer pain"),
        .init(id: "qt-ent-14", cluster: .entrepreneurship,
              prompt: "Two friends are starting a partnership with no written agreement because they trust each other. Give your advice.",
              focus: "Forms of ownership"),
        .init(id: "qt-ent-15", cluster: .entrepreneurship,
              prompt: "A social enterprise is offered a contract that funds the mission but dilutes it. Talk through how you would decide.",
              focus: "Mission and trade-offs")
    ]

    // MARK: - Personal Financial Literacy

    static let personalFinance: [QuickThinkScenario] = [
        .init(id: "qt-pfl-1", cluster: .personalFinancialLiteracy,
              prompt: "A friend says they only ever pay the minimum on their credit card because it keeps their score high. Correct them respectfully.",
              focus: "Credit management"),
        .init(id: "qt-pfl-2", cluster: .personalFinancialLiteracy,
              prompt: "Explain to a 16-year-old why starting to invest at 18 instead of 28 matters, using a concrete example.",
              focus: "Compound growth"),
        .init(id: "qt-pfl-3", cluster: .personalFinancialLiteracy,
              prompt: "A client earning $52,000 wants to buy a $45,000 car with 84-month financing. Give your professional advice.",
              focus: "Spending decisions"),
        .init(id: "qt-pfl-4", cluster: .personalFinancialLiteracy,
              prompt: "Someone turns down a raise because it will \"push them into a higher bracket and cost them money.\" Correct the misunderstanding.",
              focus: "Income tax"),
        .init(id: "qt-pfl-5", cluster: .personalFinancialLiteracy,
              prompt: "A client wants to close their oldest credit card because they never use it. Explain what will happen to their score.",
              focus: "Credit scores"),
        .init(id: "qt-pfl-6", cluster: .personalFinancialLiteracy,
              prompt: "A 25-year-old has $5,000 in savings at 1.5% and $5,000 on a card at 21%. Tell them what to do and why.",
              focus: "Debt prioritisation"),
        .init(id: "qt-pfl-7", cluster: .personalFinancialLiteracy,
              prompt: "Explain the difference between a TFSA and an RRSP to someone who has always assumed they are the same thing.",
              focus: "Registered accounts"),
        .init(id: "qt-pfl-8", cluster: .personalFinancialLiteracy,
              prompt: "A client received a text saying their account will be frozen in two hours unless they verify a link. Advise them.",
              focus: "Fraud awareness"),
        .init(id: "qt-pfl-9", cluster: .personalFinancialLiteracy,
              prompt: "Someone wants to keep their emergency fund invested in stocks \"so it grows.\" Give your recommendation.",
              focus: "Emergency funds"),
        .init(id: "qt-pfl-10", cluster: .personalFinancialLiteracy,
              prompt: "An investment promises 15% a year guaranteed with no risk. Explain to a friend why you would not put money in.",
              focus: "Risk and return"),
        .init(id: "qt-pfl-11", cluster: .personalFinancialLiteracy,
              prompt: "A freelancer's income swings between $1,800 and $6,400 a month. Give them a budgeting approach that works.",
              focus: "Variable income"),
        .init(id: "qt-pfl-12", cluster: .personalFinancialLiteracy,
              prompt: "Compare a $58,000 job with no benefits to a $53,000 job with benefits and a pension match. Reach a conclusion.",
              focus: "Total compensation"),
        .init(id: "qt-pfl-13", cluster: .personalFinancialLiteracy,
              prompt: "A 24-year-old with no dependants is being sold whole life insurance at $180 a month. Give your second opinion.",
              focus: "Insurance needs"),
        .init(id: "qt-pfl-14", cluster: .personalFinancialLiteracy,
              prompt: "A student is choosing between borrowing the maximum offered and borrowing only what they need. Advise them.",
              focus: "Education financing"),
        .init(id: "qt-pfl-15", cluster: .personalFinancialLiteracy,
              prompt: "Someone got a raise and their savings did not change at all. Explain what happened and what to do about it.",
              focus: "Lifestyle inflation")
    ]
}
