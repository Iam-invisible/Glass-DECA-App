//
//  SeedQuestions+Personal.swift
//  LCVI DECA Study App
//
//  Personal Financial Literacy cluster.
//
//  Sample practice questions written for this app.
//  These are NOT official DECA Ontario or DECA Inc. exam questions — they are
//  original practice items modelled on the style of cluster exams so the app is
//  usable the moment it is installed. Import your own bank from Settings ▸
//  Question Bank Manager to study material from your own class or club.
//

import Foundation

extension SeedQuestions {

    static let personalFinance: [QuestionData] = [
        q("pfl-1", .personalFinancialLiteracy, .easy,
          "A student earns $1,400 per month and has expenses of $1,150. The $250 difference is best described as a",
          "budget deficit.", "budget surplus.", "fixed expense.", "liability.",
          correct: 1,
          explanation: "A surplus occurs when income exceeds expenses, and it can be directed toward savings, investing or debt repayment. A deficit is the reverse and must be covered by savings or borrowing.",
          tags: ["budgeting", "money management"],
          pis: ["PF:001"]),

        q("pfl-2", .personalFinancialLiteracy, .medium,
          "Which factor generally has the largest impact on a consumer's credit score?",
          "The number of bank accounts held", "Payment history", "Annual income", "Employment length",
          correct: 1,
          explanation: "Payment history — whether bills are paid on time — carries the greatest weight, followed by credit utilization. Income and employment are not part of the score itself, although lenders consider them separately when approving credit.",
          tags: ["credit", "debt"],
          pis: ["PF:002"]),

        q("pfl-3", .personalFinancialLiteracy, .medium,
          "The relationship between risk and return in investing means that",
          "higher potential returns generally come with higher risk of loss.", "all investments carry identical risk.", "government bonds return more than stocks.", "risk can be eliminated through diversification.",
          correct: 0,
          explanation: "Investors demand extra expected return to accept extra uncertainty. Diversification reduces company-specific risk but cannot remove market-wide risk, so it lowers volatility rather than eliminating it.",
          tags: ["investing", "risk"],
          pis: ["PF:003"]),

        q("pfl-4", .personalFinancialLiteracy, .hard,
          "In Canada, which statement best distinguishes a TFSA from an RRSP?",
          "Contributions to a TFSA are tax-deductible; RRSP withdrawals are tax-free.", "TFSA withdrawals are generally tax-free; RRSP contributions are generally tax-deductible.", "Both accounts allow unlimited annual contributions.", "Neither account allows the holder to invest in stocks.",
          correct: 1,
          explanation: "A TFSA is funded with after-tax dollars and qualified withdrawals are not taxed. An RRSP gives a deduction on contribution and defers tax until withdrawal, typically in retirement when income may be lower. Both have annual contribution limits and can hold a range of investments.",
          tags: ["investing", "Canada", "taxes"],
          pis: ["PF:004", "PF:005"]),

        q("pfl-5", .personalFinancialLiteracy, .easy,
          "Gross pay differs from net pay because net pay",
          "includes overtime but not base salary.", "is the amount remaining after deductions such as income tax and CPP.", "is always higher than gross pay.", "excludes all employer contributions.",
          correct: 1,
          explanation: "Gross pay is total earnings before deductions. Net pay — take-home pay — is what remains after income tax, Canada Pension Plan contributions, Employment Insurance premiums and any voluntary deductions.",
          tags: ["income", "taxes", "Canada"],
          pis: ["PF:005"]),

        q("pfl-6", .personalFinancialLiteracy, .medium,
          "An insurance deductible is",
          "the monthly amount paid to keep a policy active.", "the amount the policyholder pays out of pocket before coverage applies.", "the maximum the insurer will ever pay.", "a government rebate on premiums.",
          correct: 1,
          explanation: "The deductible is the policyholder's share of a claim. Choosing a higher deductible usually lowers the premium but increases out-of-pocket cost when a loss occurs — a direct trade-off between certainty and monthly cost.",
          tags: ["insurance", "risk"],
          pis: ["PF:006"]),

        q("pfl-7", .personalFinancialLiteracy, .hard,
          "Using the Rule of 72, approximately how long will it take an investment earning 6% annually to double?",
          "6 years", "9 years", "12 years", "15 years",
          correct: 2,
          explanation: "The Rule of 72 estimates doubling time as 72 ÷ annual rate = 72 ÷ 6 = 12 years. It is a quick approximation of compound growth and works the same way in reverse for estimating how quickly compounding debt grows.",
          tags: ["compound interest", "saving", "calculation"],
          pis: ["PF:007"]),

        q("pfl-8", .personalFinancialLiteracy, .medium,
          "Which statement about grants and student loans is accurate?",
          "Both must be repaid with interest.", "Grants generally do not need to be repaid; loans do.", "Loans are always interest-free in Canada.", "Grants must be repaid only if the student graduates.",
          correct: 1,
          explanation: "Grants and scholarships are non-repayable aid based on need or merit. Loans must be repaid, usually beginning after studies end, so students should exhaust grant and scholarship options before borrowing.",
          tags: ["education financing", "Canada"],
          pis: ["PF:008"]),

        q("pfl-9", .personalFinancialLiteracy, .medium,
          "Financial planners commonly recommend an emergency fund covering",
          "one week of expenses.", "three to six months of essential expenses.", "five years of expenses.", "the value of all owned assets.",
          correct: 1,
          explanation: "Three to six months of essential expenses held in an accessible account covers job loss, medical costs or major repairs without resorting to high-interest credit. The right size depends on income stability and fixed obligations.",
          tags: ["saving", "money management"],
          pis: ["PF:001", "PF:007"]),

        q("pfl-10", .personalFinancialLiteracy, .medium,
          "Paying only the minimum payment on a credit card each month usually results in",
          "a lower credit score immediately.", "paying substantially more in interest over time.", "the balance being forgiven after one year.", "no interest being charged.",
          correct: 1,
          explanation: "Minimum payments cover mostly interest, so the principal falls slowly and total interest paid grows dramatically. Paying the statement balance in full each month avoids interest entirely on purchases.",
          tags: ["credit", "debt", "interest"],
          pis: ["PF:002", "PF:007"])
    ]
}
