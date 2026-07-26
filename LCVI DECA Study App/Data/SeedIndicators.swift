//
//  SeedIndicators.swift
//  LCVI DECA Study App
//
//  A starter set of performance indicator statements grouped by instructional
//  area. These are sample study indicators written for practice inside this
//  app — always check the current DECA Ontario / DECA Inc. competitive event
//  guidelines for the official indicator list used at your competition.
//

import Foundation

enum SeedIndicators {
    static let all: [PerformanceIndicatorData] = marketing + finance + hospitality
        + businessManagement + entrepreneurship + personalFinance

    // MARK: Marketing

    static let marketing: [PerformanceIndicatorData] = [
        .init(code: "MK:001", text: "Explain the concept of marketing strategies",
              instructionalArea: "Marketing", cluster: .marketing),
        .init(code: "MK:002", text: "Explain factors affecting pricing decisions",
              instructionalArea: "Pricing", cluster: .marketing),
        .init(code: "MK:003", text: "Explain the nature of channel-member relationships",
              instructionalArea: "Channel Management", cluster: .marketing),
        .init(code: "MK:004", text: "Identify the elements of the promotional mix",
              instructionalArea: "Promotion", cluster: .marketing),
        .init(code: "MK:005", text: "Explain the role of situation analysis in the marketing planning process",
              instructionalArea: "Market Planning", cluster: .marketing),
        .init(code: "MK:006", text: "Describe methods used to segment a target market",
              instructionalArea: "Market Planning", cluster: .marketing),
        .init(code: "MK:007", text: "Explain the nature of marketing research problems and issues",
              instructionalArea: "Marketing-Information Management", cluster: .marketing),
        .init(code: "MK:008", text: "Explain the concept of product mix and product positioning",
              instructionalArea: "Product/Service Management", cluster: .marketing),
        .init(code: "MK:009", text: "Demonstrate a customer-service mindset",
              instructionalArea: "Customer Relations", cluster: .marketing),
        .init(code: "MK:010", text: "Explain the use of digital and social media in promotion",
              instructionalArea: "Promotion", cluster: .marketing)
    ]

    // MARK: Finance

    static let finance: [PerformanceIndicatorData] = [
        .init(code: "FI:001", text: "Explain the purpose and components of financial statements",
              instructionalArea: "Financial Analysis", cluster: .finance),
        .init(code: "FI:002", text: "Calculate and interpret financial ratios",
              instructionalArea: "Financial Analysis", cluster: .finance),
        .init(code: "FI:003", text: "Explain the time value of money",
              instructionalArea: "Financial-Information Management", cluster: .finance),
        .init(code: "FI:004", text: "Describe sources of short-term and long-term financing",
              instructionalArea: "Financial Analysis", cluster: .finance),
        .init(code: "FI:005", text: "Explain the role of budgeting in financial planning",
              instructionalArea: "Financial Analysis", cluster: .finance),
        .init(code: "FI:006", text: "Describe types of business risk and methods of risk management",
              instructionalArea: "Risk Management", cluster: .finance),
        .init(code: "FI:007", text: "Explain the nature of accounts payable and receivable",
              instructionalArea: "Accounting", cluster: .finance),
        .init(code: "FI:008", text: "Describe the services provided by financial institutions",
              instructionalArea: "Banking Services", cluster: .finance),
        .init(code: "FI:009", text: "Explain the concept of break-even analysis",
              instructionalArea: "Financial Analysis", cluster: .finance),
        .init(code: "FI:010", text: "Explain the purpose of internal controls",
              instructionalArea: "Accounting", cluster: .finance)
    ]

    // MARK: Hospitality and Tourism

    static let hospitality: [PerformanceIndicatorData] = [
        .init(code: "HT:001", text: "Explain the impact of tourism on a local economy",
              instructionalArea: "Tourism", cluster: .hospitality),
        .init(code: "HT:002", text: "Describe front-office procedures in lodging operations",
              instructionalArea: "Lodging", cluster: .hospitality),
        .init(code: "HT:003", text: "Explain revenue management in the hospitality industry",
              instructionalArea: "Pricing", cluster: .hospitality),
        .init(code: "HT:004", text: "Handle guest complaints to build guest loyalty",
              instructionalArea: "Customer Relations", cluster: .hospitality),
        .init(code: "HT:005", text: "Explain food-safety and sanitation requirements",
              instructionalArea: "Food Service", cluster: .hospitality),
        .init(code: "HT:006", text: "Describe the components of a destination marketing plan",
              instructionalArea: "Market Planning", cluster: .hospitality),
        .init(code: "HT:007", text: "Explain the nature of event and meeting planning",
              instructionalArea: "Event Management", cluster: .hospitality),
        .init(code: "HT:008", text: "Describe the role of sustainability in hospitality operations",
              instructionalArea: "Operations", cluster: .hospitality)
    ]

    // MARK: Business Management and Administration

    static let businessManagement: [PerformanceIndicatorData] = [
        .init(code: "BM:001", text: "Explain the nature of organizational structure",
              instructionalArea: "Operations", cluster: .businessManagement),
        .init(code: "BM:002", text: "Describe the functions of management",
              instructionalArea: "Strategic Management", cluster: .businessManagement),
        .init(code: "BM:003", text: "Explain the recruitment and selection process",
              instructionalArea: "Human Resources Management", cluster: .businessManagement),
        .init(code: "BM:004", text: "Describe the nature of workplace health and safety regulations",
              instructionalArea: "Operations", cluster: .businessManagement),
        .init(code: "BM:005", text: "Explain the role of business ethics in decision making",
              instructionalArea: "Professional Development", cluster: .businessManagement),
        .init(code: "BM:006", text: "Describe methods of improving operational efficiency",
              instructionalArea: "Operations", cluster: .businessManagement),
        .init(code: "BM:007", text: "Explain the nature of contracts and business law",
              instructionalArea: "Business Law", cluster: .businessManagement),
        .init(code: "BM:008", text: "Describe approaches to change management",
              instructionalArea: "Strategic Management", cluster: .businessManagement),
        .init(code: "BM:009", text: "Explain the use of key performance indicators",
              instructionalArea: "Information Management", cluster: .businessManagement)
    ]

    // MARK: Entrepreneurship

    static let entrepreneurship: [PerformanceIndicatorData] = [
        .init(code: "EN:001", text: "Explain the components of a business plan",
              instructionalArea: "Business Planning", cluster: .entrepreneurship),
        .init(code: "EN:002", text: "Assess the feasibility of a business concept",
              instructionalArea: "Business Planning", cluster: .entrepreneurship),
        .init(code: "EN:003", text: "Describe sources of start-up capital",
              instructionalArea: "Financing", cluster: .entrepreneurship),
        .init(code: "EN:004", text: "Explain forms of business ownership",
              instructionalArea: "Business Law", cluster: .entrepreneurship),
        .init(code: "EN:005", text: "Identify a venture's competitive advantage",
              instructionalArea: "Market Planning", cluster: .entrepreneurship),
        .init(code: "EN:006", text: "Explain the value of a minimum viable product",
              instructionalArea: "Product Development", cluster: .entrepreneurship),
        .init(code: "EN:007", text: "Describe strategies for scaling a small business",
              instructionalArea: "Growth Management", cluster: .entrepreneurship),
        .init(code: "EN:008", text: "Explain the role of intellectual property protection",
              instructionalArea: "Business Law", cluster: .entrepreneurship)
    ]

    // MARK: Personal Financial Literacy

    static let personalFinance: [PerformanceIndicatorData] = [
        .init(code: "PF:001", text: "Explain the components of a personal budget",
              instructionalArea: "Money Management", cluster: .personalFinancialLiteracy),
        .init(code: "PF:002", text: "Describe the factors that affect a credit score",
              instructionalArea: "Credit and Debt", cluster: .personalFinancialLiteracy),
        .init(code: "PF:003", text: "Explain the relationship between risk and return",
              instructionalArea: "Investing", cluster: .personalFinancialLiteracy),
        .init(code: "PF:004", text: "Describe types of savings and investment vehicles",
              instructionalArea: "Investing", cluster: .personalFinancialLiteracy),
        .init(code: "PF:005", text: "Explain how income tax affects take-home pay",
              instructionalArea: "Earning Income", cluster: .personalFinancialLiteracy),
        .init(code: "PF:006", text: "Describe the purpose of insurance in managing personal risk",
              instructionalArea: "Insuring", cluster: .personalFinancialLiteracy),
        .init(code: "PF:007", text: "Explain the effect of compound interest on savings and debt",
              instructionalArea: "Saving", cluster: .personalFinancialLiteracy),
        .init(code: "PF:008", text: "Evaluate the costs and benefits of post-secondary financing options",
              instructionalArea: "Earning Income", cluster: .personalFinancialLiteracy)
    ]

    static func indicators(for cluster: DECACluster) -> [PerformanceIndicatorData] {
        all.filter { $0.cluster == cluster }
    }

    static func text(forCode code: String) -> String? {
        all.first { $0.code == code }?.text
    }
}
