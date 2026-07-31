//
//  SeedQuestions+Entrepreneurship.swift
//  LCVI DECA Study App
//
//  Entrepreneurship cluster.
//
//  Sample practice questions written for this app.
//  These are NOT official DECA Ontario or DECA Inc. exam questions — they are
//  original practice items modelled on the style of cluster exams so the app is
//  usable the moment it is installed. Import your own bank from Settings ▸
//  Question Bank Manager to study material from your own class or club.
//

import Foundation

extension SeedQuestions {

    static let entrepreneurship: [QuestionData] = [
        q("ent-1", .entrepreneurship, .easy,
          "The executive summary of a business plan should",
          "list every financial assumption in detail.", "concisely present the concept, market opportunity and financial need.", "be written before any research is done.", "contain only the founder's biography.",
          correct: 1,
          explanation: "The executive summary is written last but read first. In roughly one page it must state what the business does, who it serves, why it will win, and what is being asked of the reader — usually funding.",
          tags: ["business plan", "planning"],
          pis: ["EN:001"]),

        q("ent-2", .entrepreneurship, .medium,
          "The main purpose of a feasibility study is to determine whether",
          "the founder enjoys the industry.", "a business concept is workable and likely to be profitable.", "competitors will approve of the venture.", "the business qualifies for a trademark.",
          correct: 1,
          explanation: "A feasibility study tests the concept against market demand, operational requirements, competition and financial projections before significant money is committed. It is a go/no-go decision tool that precedes the full business plan.",
          tags: ["feasibility", "planning"],
          pis: ["EN:002"]),

        q("ent-3", .entrepreneurship, .medium,
          "An experienced businessperson invests their own money in an early-stage venture in exchange for equity and often provides mentorship. This investor is called",
          "a commercial banker.", "an angel investor.", "a bondholder.", "a franchisee.",
          correct: 1,
          explanation: "Angel investors are individuals who fund very early companies with personal capital, typically before venture-capital firms are interested. Banks lend debt that must be repaid regardless of success; bondholders are lenders, not owners.",
          tags: ["financing", "start-up capital"],
          pis: ["EN:003"]),

        q("ent-4", .entrepreneurship, .medium,
          "The most significant disadvantage of a sole proprietorship is that",
          "profits must be shared with partners.", "the owner has unlimited personal liability for business debts.", "it requires the most complex registration process.", "it cannot hire employees.",
          correct: 1,
          explanation: "In a sole proprietorship there is no legal separation between owner and business, so personal assets are exposed to business debts and lawsuits. Incorporation creates a separate legal entity and limits that liability.",
          tags: ["ownership", "business law"],
          pis: ["EN:004"]),

        q("ent-5", .entrepreneurship, .medium,
          "A new meal-kit company succeeds because it is the only provider offering same-day delivery in its city. This is best described as its",
          "break-even point.", "competitive advantage.", "market segment.", "distribution channel.",
          correct: 1,
          explanation: "A competitive advantage is the specific reason customers choose you over alternatives, and it must be difficult for rivals to copy quickly. Identifying and defending it is central to positioning a new venture.",
          tags: ["competitive advantage", "strategy"],
          pis: ["EN:005"]),

        q("ent-6", .entrepreneurship, .medium,
          "Why do founders often launch a minimum viable product (MVP) rather than a fully featured product?",
          "It removes the need for customer feedback.", "It tests core assumptions quickly with less time and money at risk.", "It guarantees the product will be profitable.", "It avoids the need for a business plan.",
          correct: 1,
          explanation: "An MVP includes just enough functionality to learn whether customers actually want the solution. Learning early is cheaper than building a full product on untested assumptions, and the feedback shapes what gets built next.",
          tags: ["product development", "MVP"],
          pis: ["EN:006"]),

        q("ent-7", .entrepreneurship, .medium,
          "A successful local bakery wants to expand across the province with limited capital of its own. Which growth strategy best fits that constraint?",
          "Franchising the concept to independent operators", "Opening company-owned stores funded by cash flow", "Reducing prices to increase volume", "Discontinuing its most popular product",
          correct: 0,
          explanation: "Franchising lets franchisees supply the capital and local management while the franchisor earns fees and royalties and protects brand standards. It trades some control for much faster, less capital-intensive expansion.",
          tags: ["growth", "franchising"],
          pis: ["EN:007"]),

        q("ent-8", .entrepreneurship, .hard,
          "A founder creates a distinctive logo and name for their venture. Which form of intellectual property protection applies?",
          "Patent", "Copyright", "Trademark", "Trade secret",
          correct: 2,
          explanation: "Trademarks protect brand identifiers such as names, logos and slogans that distinguish a source of goods or services. Patents protect inventions, copyright protects original creative works, and trade secrets protect confidential business information.",
          tags: ["intellectual property", "business law"],
          pis: ["EN:008"]),

        q("ent-9", .entrepreneurship, .medium,
          "A start-up is profitable on paper but cannot pay its suppliers this month. The most likely cause is",
          "a negative gross margin.", "a cash-flow timing problem.", "excessive owner equity.", "a lack of trademarks.",
          correct: 1,
          explanation: "Profit is recorded when a sale is made; cash arrives when the customer actually pays. If receivables are collected slowly while payables come due quickly, a profitable business can still run out of cash — the most common cause of start-up failure.",
          tags: ["cash flow", "financing"],
          pis: ["EN:003", "FI:007"]),

        q("ent-10", .entrepreneurship, .easy,
          "Before launching, an entrepreneur surveys 200 potential customers about pricing and features. This activity primarily helps the founder",
          "avoid paying business taxes.", "validate demand and refine the offer.", "secure a patent.", "hire employees faster.",
          correct: 1,
          explanation: "Customer discovery replaces assumptions with evidence about who the buyer is, what problem they will pay to solve, and what price they accept. That evidence drives both the product roadmap and the financial projections in the plan.",
          tags: ["market research", "validation"],
          pis: ["EN:002", "EN:005"])
    ]
}
