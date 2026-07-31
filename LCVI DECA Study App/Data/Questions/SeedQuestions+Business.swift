//
//  SeedQuestions+Business.swift
//  LCVI DECA Study App
//
//  Business Management and Administration cluster.
//
//  Sample practice questions written for this app.
//  These are NOT official DECA Ontario or DECA Inc. exam questions — they are
//  original practice items modelled on the style of cluster exams so the app is
//  usable the moment it is installed. Import your own bank from Settings ▸
//  Question Bank Manager to study material from your own class or club.
//

import Foundation

extension SeedQuestions {

    static let businessManagement: [QuestionData] = [
        q("bma-1", .businessManagement, .easy,
          "Which set correctly lists the four functions of management?",
          "Planning, organizing, leading, controlling", "Buying, selling, storing, promoting", "Hiring, training, paying, firing", "Producing, marketing, financing, auditing",
          correct: 0,
          explanation: "Planning sets goals, organizing arranges resources, leading motivates and directs people, and controlling measures results against the plan and corrects deviations. The other options describe specific business activities, not management functions.",
          tags: ["management functions", "strategy"],
          pis: ["BM:002"]),

        q("bma-2", .businessManagement, .medium,
          "Span of control refers to",
          "the number of employees a manager directly supervises.", "the physical size of a company's facilities.", "the length of a manager's employment contract.", "the range of products a company sells.",
          correct: 0,
          explanation: "A narrow span means few direct reports and closer supervision but taller hierarchies. A wide span flattens the organization, reduces management cost, and requires employees capable of working with less direction.",
          tags: ["organizational structure", "operations"],
          pis: ["BM:001"]),

        q("bma-3", .businessManagement, .medium,
          "What is a key advantage of promoting from within rather than hiring externally?",
          "It always costs more than external hiring.", "Internal candidates already understand the company's culture and processes.", "It guarantees a more diverse workforce.", "It removes the need for performance reviews.",
          correct: 1,
          explanation: "Internal promotion shortens onboarding, rewards performance and improves retention because employees see a path forward. External hiring brings fresh perspective and new skills — strong organizations use both deliberately.",
          tags: ["human resources", "recruitment"],
          pis: ["BM:003"]),

        q("bma-4", .businessManagement, .medium,
          "In a matrix organizational structure, an employee typically",
          "reports to no manager at all.", "reports to both a functional manager and a project manager.", "works only on a single product line for their whole career.", "is prohibited from joining project teams.",
          correct: 1,
          explanation: "Matrix structures overlay project teams on functional departments, so staff have dual reporting lines. This improves cross-functional coordination but can create conflicting priorities that require clear escalation rules.",
          tags: ["organizational structure"],
          pis: ["BM:001"]),

        q("bma-5", .businessManagement, .medium,
          "A company publishes a code of conduct that all employees must review annually. The main purpose is to",
          "replace the need for managers.", "set clear expectations for ethical behaviour and decision making.", "guarantee higher profits.", "satisfy customers' warranty claims.",
          correct: 1,
          explanation: "A code of conduct translates values into concrete expectations — conflicts of interest, gifts, confidentiality, harassment — so employees can recognize and resolve ethical questions consistently before they become incidents.",
          tags: ["ethics", "professional development"],
          pis: ["BM:005"]),

        q("bma-6", .businessManagement, .medium,
          "Under Ontario's occupational health and safety framework, a worker who believes a task is unsafe generally has the right to",
          "refuse the work and report it to their supervisor.", "leave the workplace permanently without notice.", "perform the work and bill overtime.", "ignore the hazard if a supervisor insists.",
          correct: 0,
          explanation: "Health and safety law is built on the internal responsibility system: workers have the right to know about hazards, to participate in safety processes, and to refuse work they reasonably believe is unsafe. The refusal triggers an investigation, not termination.",
          tags: ["health and safety", "operations", "Ontario"],
          pis: ["BM:004"]),

        q("bma-7", .businessManagement, .hard,
          "Which element is required for a contract to be legally enforceable?",
          "A notarized signature", "Consideration exchanged by both parties", "A minimum value of $500", "Registration with a government office",
          correct: 1,
          explanation: "A valid contract needs offer, acceptance, consideration (something of value exchanged), capacity, and a lawful purpose. Notarization, a dollar threshold and registration are not general requirements, though some specific contracts have extra formalities.",
          tags: ["business law", "contracts"],
          pis: ["BM:007"]),

        q("bma-8", .businessManagement, .medium,
          "Employees resist a new scheduling system. Which approach is most likely to reduce that resistance?",
          "Implementing the change without warning to avoid debate", "Involving employees early and explaining the reasons for the change", "Removing the employees who ask questions", "Delaying all communication until after launch",
          correct: 1,
          explanation: "Resistance usually comes from uncertainty and loss of control. Early involvement, clear rationale, training and visible leadership support build ownership. Surprise rollouts increase rumours and reduce adoption.",
          tags: ["change management", "leadership"],
          pis: ["BM:008"]),

        q("bma-9", .businessManagement, .easy,
          "A key performance indicator (KPI) is best described as",
          "any number a business collects.", "a measurable value that shows progress toward a specific objective.", "a legal requirement for annual reporting.", "the total revenue of a company.",
          correct: 1,
          explanation: "KPIs are selected deliberately because they track progress toward a stated goal — for example, on-time delivery rate for an operations objective. Collecting numbers without tying them to objectives produces dashboards nobody acts on.",
          tags: ["performance measurement", "information management"],
          pis: ["BM:009"]),

        q("bma-10", .businessManagement, .medium,
          "A manufacturer maps its production process and removes steps that add no value for the customer. This approach is best described as",
          "vertical integration.", "process improvement using lean principles.", "outsourcing.", "diversification.",
          correct: 1,
          explanation: "Lean thinking identifies and eliminates waste — waiting, excess motion, overproduction, defects — so the same output requires fewer resources. Vertical integration and outsourcing change who does the work, not how efficient the process is.",
          tags: ["operations", "efficiency"],
          pis: ["BM:006"])
    ]
}
