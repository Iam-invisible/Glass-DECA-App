//
//  EventTag.swift
//  LCVI DECA Study App
//
//  The student's competitive event, said the way they say it: the cluster's
//  icon and the code out loud — "EIP", "HTDM".
//
//  This is not the eyebrow ScreenHeader removed. That one carried scope — the
//  cluster filter, "All clusters", an attempt count — which was chrome about
//  the screen. This carries what the student signed up to compete in, which is
//  the one piece of context both of these screens are actually about.
//
//  Undecided is a first-class answer (§6), so it falls back to the cluster
//  rather than showing an empty slot or a placeholder. The two read as
//  different kinds of thing on purpose: "EIP" is an event, "ENTREPRENEURSHIP"
//  plainly is not, so nobody has to wonder whether they picked one.
//

import SwiftUI

struct EventTag: View {
    let event: DECAEvent?
    let cluster: DECACluster

    /// What VoiceOver says. The code is an initialism and would be spelled out
    /// letter by letter, which tells a student nothing they did not already
    /// know from the screen they are on.
    private var spoken: String {
        if let event { return "Your event: \(event.name)" }
        return "Your cluster: \(cluster.displayName)"
    }

    private var label: String {
        (event?.code ?? cluster.shortName).uppercased()
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: cluster.symbol)
                .font(.system(size: 11, weight: .semibold))
                // The tint is the one place a cluster's colour is worth
                // spending here. It is small, it is not next to anything that
                // means correct or wrong, and the symbol already carries the
                // identity on its own if the colour cannot be told apart.
                .foregroundStyle(cluster.tint)

            Text(label)
                .font(.appCaptionBold)
                .tracking(0.9)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}
