//
//  PrivacyPolicy.swift
//  LCVI DECA Study App
//
//  The privacy notice, as structured data rather than HTML.
//
//  Why not a web view
//  ------------------
//  The generated policy arrives as HTML full of editor markup and unclosed
//  tags. Rendering it in a WKWebView would mean shipping a second type stack
//  and a second colour scheme inside an app whose whole identity is one
//  typeface pairing (§5), it would ignore Dynamic Type, and it would need the
//  network or a bundled copy anyway. Native blocks cost less and read better.
//
//  ⚠️ KEEP THIS IN STEP WITH THE HOSTED VERSION.
//  App Store Connect needs a public URL, and the text there and the text here
//  must say the same thing. `version` below is what the acceptance is recorded
//  against — bump it whenever the substance changes, and every student is
//  asked to accept again on next launch.
//
//  Where this text departs from the generator's default output, it is because
//  the default asserted things that are not true of this app — sharing with
//  third parties, retention in backup archives, AI processing under agreements
//  with vendors. An inaccurate policy is worse than a short one, so those
//  clauses say what actually happens instead.
//

import Foundation

enum PrivacyPolicy {

    /// Bump on any material change. Acceptance is stored against this, so a
    /// bump re-prompts everyone.
    static let version = 1

    static let lastUpdated = "31 July 2026"
    static let contactEmail = "invisibledeveloper0@gmail.com"

    /// The public copy, served by GitHub Pages from the `web-only` branch and
    /// the same URL given to App Store Connect.
    ///
    /// The full notice is embedded in the app, so this is an alternative
    /// rather than a dependency — nothing breaks offline, which matters for an
    /// app whose whole promise is that it works without a network. It is here
    /// so a student can send the policy to a parent or a teacher without
    /// asking them to install anything.
    static let hostedURL = URL(string: "https://iam-invisible.github.io/Glass-DECA-App/privacy.html")!

    /// The one-screen summary shown above the full notice on the consent gate.
    /// Written to be the part a student actually reads.
    static let summary: [String] = [
        "Everything you do in Glass stays on your phone. Your answers, progress, notes and settings are never sent anywhere.",
        "There is no account, no sign-in, and no way for us to identify you. We collect nothing, so there is nothing for us to lose, sell or hand over.",
        "There are no analytics, no advertising and no tracking of any kind in this app.",
        "AI coaching, where your device supports it, runs entirely on your device. Your writing is never uploaded."
    ]

    struct Section: Identifiable {
        let id: Int
        let title: String
        let blocks: [Block]
    }

    enum Block {
        case paragraph(String)
        case bullets([String])
    }

    static let sections: [Section] = [
        Section(id: 1, title: "What information do we collect?", blocks: [
            .paragraph("We do not collect any personal information."),
            .paragraph("Glass never asks for your name, email address, phone number, mailing address, date of birth or any other detail that could identify you. There is no account to create and no sign-in."),
            .paragraph("The app stores the following on your own device, and only on your own device:"),
            .bullets([
                "Your chosen cluster and competitive event",
                "Your daily goals and reminder preferences",
                "Your answers, practice history, mistakes and progress",
                "Any study material you write or import yourself",
                "Display preferences such as theme, sound and haptics"
            ]),
            .paragraph("None of this is transmitted to us or to anyone else. We have no server and no way to see it."),
            .paragraph("We do not process sensitive information, and we do not collect any information from third parties.")
        ]),

        Section(id: 2, title: "How do we process your information?", blocks: [
            .paragraph("Because we do not collect your information, we do not process it."),
            .paragraph("The data listed above is used by the app, on your device, to do the things you asked it to do — track your progress, schedule the reminders you set, and show your statistics. It is never sent to us and never leaves your device unless you deliberately export it yourself.")
        ]),

        Section(id: 3, title: "What legal bases do we rely on?", blocks: [
            .paragraph("Legal bases such as consent, contract or legitimate interest apply to the processing of personal information. As we do not collect or process any personal information, none is relied upon."),
            .paragraph("If you are in the European Economic Area, the United Kingdom, Switzerland or Canada, this means there is no processing of your personal data to consent to, object to, or withdraw consent from.")
        ]),

        Section(id: 4, title: "When and with whom do we share your information?", blocks: [
            .paragraph("We never share your information, because we never receive it."),
            .paragraph("There are no service providers, analytics companies, advertisers, or data brokers involved in this app. No third party receives anything about you or your use of Glass.")
        ]),

        Section(id: 5, title: "Do we offer AI-based features?", blocks: [
            .paragraph("Yes. Where your device supports it, Glass can generate written coaching and explanations on your practice work."),
            .paragraph("All of this runs entirely on your own device. Your questions, answers, roleplay transcripts and notes are never sent to us, to any AI provider, or to any other third party, and are never used to train any model."),
            .paragraph("These features are optional and can be switched off in Settings. Where a device cannot run them, the app shows written guidance instead and every feature remains usable."),
            .paragraph("AI-generated feedback is intended as study practice and may contain errors. Correct answers shown in the app always come from the app's own study material, never from an AI model.")
        ]),

        Section(id: 6, title: "How long do we keep your information?", blocks: [
            .paragraph("We keep nothing, because we receive nothing."),
            .paragraph("The data on your device stays there for as long as you keep the app installed. Deleting Glass removes all of it. You can also erase your progress at any time from Settings.")
        ]),

        Section(id: 7, title: "What are your privacy rights?", blocks: [
            .paragraph("Privacy laws give you rights over personal information a company holds about you — to access it, correct it, delete it, or obtain a copy. We hold nothing about you, so there is nothing for us to access, correct, delete or provide."),
            .paragraph("You have complete and direct control over everything the app stores. You can view it, change it, export it, or delete it at any time from within the app, without asking us and without telling us."),
            .paragraph("If you are in the United Kingdom or the European Economic Area and you are unhappy with how we have handled your privacy, you may contact us at the address below, and you also have the right to complain to your national data protection authority.")
        ]),

        Section(id: 8, title: "Controls for do-not-track features", blocks: [
            .paragraph("Glass does not track you across apps or websites, and contains no technology capable of doing so. There is therefore nothing for a Do-Not-Track signal to disable.")
        ]),

        Section(id: 9, title: "Do residents of the United States have specific rights?", blocks: [
            .paragraph("Residents of several US states have rights to know about, access, correct, delete and opt out of the sale or sharing of their personal information."),
            .paragraph("We have not collected any personal information in the preceding twelve months, in any category — no identifiers, no commercial information, no biometric or geolocation data, no internet activity, no education records, and no inferences drawn from any of these."),
            .paragraph("We have never sold or shared personal information, and we will not do so in future.")
        ]),

        Section(id: 10, title: "Do we make updates to this notice?", blocks: [
            .paragraph("Yes. We may update this notice to stay accurate and to comply with relevant laws. The date at the top shows when it last changed."),
            .paragraph("If we make a material change, the app will ask you to review and accept the updated notice the next time you open it.")
        ]),

        Section(id: 11, title: "How can you contact us?", blocks: [
            .paragraph("If you have questions or concerns about this notice, or about privacy in Glass, you can email us at \(contactEmail)."),
            .paragraph("Because we hold no information about you, we cannot look up an account or identify you from an email. Please describe your question directly.")
        ]),

        Section(id: 12, title: "About DECA", blocks: [
            .paragraph("Glass is an independent study aid. It is not affiliated with, endorsed by, or sponsored by DECA Inc. or DECA Ontario."),
            .paragraph("All questions, scenarios and event information in the app are original material created for study purposes, and are not official DECA examination content. Competitive event details are provided in good faith and should be confirmed against current DECA Ontario guidelines.")
        ])
    ]
}
