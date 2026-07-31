//
//  SeedQuestions+Hospitality.swift
//  LCVI DECA Study App
//
//  Hospitality and Tourism cluster.
//
//  Sample practice questions written for this app.
//  These are NOT official DECA Ontario or DECA Inc. exam questions — they are
//  original practice items modelled on the style of cluster exams so the app is
//  usable the moment it is installed. Import your own bank from Settings ▸
//  Question Bank Manager to study material from your own class or club.
//

import Foundation

extension SeedQuestions {

    static let hospitality: [QuestionData] = [
        q("ht-1", .hospitality, .hard,
          "A 200-room hotel sells 150 rooms at an average daily rate of $180. What is its RevPAR for the night?",
          "$180.00", "$135.00", "$120.00", "$150.00",
          correct: 1,
          explanation: "RevPAR (revenue per available room) = occupancy × average daily rate = 75% × $180 = $135. Equivalently, total room revenue ($27,000) ÷ total available rooms (200) = $135. RevPAR is stronger than ADR alone because it accounts for empty rooms.",
          tags: ["revenue management", "lodging", "calculation"],
          pis: ["HT:003"]),

        q("ht-2", .hospitality, .medium,
          "Why do hotels deliberately accept more reservations than they have rooms?",
          "To increase the average daily rate", "To offset expected cancellations and no-shows", "Because provincial law requires it", "To reduce housekeeping costs",
          correct: 1,
          explanation: "Controlled overbooking compensates for predictable cancellations and no-shows so the hotel does not run with unsold, unrecoverable inventory. Hotels manage the risk with walk policies that relocate and compensate displaced guests.",
          tags: ["lodging", "revenue management"],
          pis: ["HT:003", "HT:002"]),

        q("ht-3", .hospitality, .medium,
          "The night audit in a lodging property is primarily responsible for",
          "cleaning guest rooms after late checkout.", "balancing the day's guest accounts and posting room charges.", "negotiating group rates with tour operators.", "inspecting kitchen sanitation.",
          correct: 1,
          explanation: "The night audit closes the business day: it verifies postings, reconciles guest folios against departmental revenue, posts room and tax charges, and produces reports management uses the next morning.",
          tags: ["lodging", "front office"],
          pis: ["HT:002"]),

        q("ht-4", .hospitality, .medium,
          "A guest complains loudly that their room was not ready at check-in. What should the front-desk agent do first?",
          "Explain the hotel's check-in policy in detail", "Listen fully and acknowledge the guest's frustration", "Offer a free night immediately", "Direct the guest to the manager",
          correct: 1,
          explanation: "Effective service recovery starts with listening and empathizing so the guest feels heard. Jumping to policy sounds defensive, and leading with a large giveaway skips diagnosis. Apologize, then solve, then follow up.",
          tags: ["customer relations", "service recovery"],
          pis: ["HT:004"]),

        q("ht-5", .hospitality, .medium,
          "Which practice best reduces the risk of foodborne illness in a commercial kitchen?",
          "Storing raw chicken on the shelf above ready-to-eat salad", "Keeping hot food between 4°C and 60°C for service", "Cooling cooked food quickly and storing it below 4°C", "Thawing frozen meat on the counter at room temperature",
          correct: 2,
          explanation: "The temperature danger zone is roughly 4°C to 60°C, where bacteria multiply fastest. Cooling food quickly and holding it below 4°C limits growth. Raw proteins are stored below ready-to-eat foods, and thawing is done under refrigeration or cold running water.",
          tags: ["food safety", "food service"],
          pis: ["HT:005"]),

        q("ht-6", .hospitality, .medium,
          "A tourist spends money at a hotel; the hotel then pays local staff who spend that income in nearby shops. This chain of spending illustrates",
          "the multiplier effect.", "seasonality.", "the balance of trade.", "carrying capacity.",
          correct: 0,
          explanation: "The tourism multiplier effect describes how one visitor dollar circulates through a local economy, generating additional income and jobs beyond the original transaction. It is a central argument in destination economic-impact studies.",
          tags: ["tourism", "economics"],
          pis: ["HT:001"]),

        q("ht-7", .hospitality, .easy,
          "A destination marketing organization (DMO) primarily works to",
          "operate hotels and restaurants in a region.", "promote a region as a travel destination.", "regulate airline ticket pricing.", "certify food-handler training.",
          correct: 1,
          explanation: "DMOs — often called tourism boards or visitor bureaus — market a city or region to travellers and meeting planners. They coordinate branding, campaigns and visitor services rather than operating individual businesses.",
          tags: ["tourism", "destination marketing"],
          pis: ["HT:006"]),

        q("ht-8", .hospitality, .medium,
          "An airline raises fares for a flight as the departure date approaches and seats become scarce. This is an application of",
          "cost-plus pricing.", "dynamic revenue management.", "penetration pricing.", "bundle pricing.",
          correct: 1,
          explanation: "Revenue management adjusts price continuously based on forecast demand, remaining inventory and time until the perishable service expires. Cost-plus ignores demand, and penetration pricing sets a low introductory price.",
          tags: ["revenue management", "pricing"],
          pis: ["HT:003"]),

        q("ht-9", .hospitality, .medium,
          "When planning a large outdoor conference, why does an event planner prepare a contingency plan?",
          "To reduce the number of attendees", "To lower the venue deposit", "To manage risks such as weather, vendor failure or power loss", "To satisfy accounting standards",
          correct: 2,
          explanation: "Contingency planning identifies what could disrupt the event and pre-arranges backup venues, vendors, equipment and communication plans. It protects attendee experience and limits financial exposure when something goes wrong.",
          tags: ["event management", "risk"],
          pis: ["HT:007"]),

        q("ht-10", .hospitality, .easy,
          "A hotel offers guests the option to skip daily linen changes. This programme primarily supports",
          "revenue management goals.", "sustainability and cost-reduction goals.", "front-office training goals.", "food-safety compliance.",
          correct: 1,
          explanation: "Opt-out linen programmes reduce water, energy, detergent and labour, which lowers operating costs while supporting environmental commitments. Many properties also promote it as part of their guest-facing sustainability story.",
          tags: ["sustainability", "operations"],
          pis: ["HT:008"])
    ]
}
