//
//  PrivacyPolicyScreen.swift
//  LCVI DECA Study App
//
//  The privacy notice, readable at any time from Settings ▸ About.
//
//  Same `PrivacyPolicyBody` the acceptance gate uses, so the words a student
//  agreed to on their first launch are the words they find months later.
//

import SwiftUI

struct PrivacyPolicyScreen: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                ScrollOffsetProbe()
                ScreenHeader("Privacy notice",
                             eyebrow: "On this phone only",
                             eyebrowSymbol: "lock.shield",
                             subtitle: "We collect nothing. Here is exactly what that means.")

                if let accepted = store.settings.acceptedPrivacyAt {
                    Label("Accepted on \(accepted.formatted(date: .long, time: .omitted))",
                          systemImage: "checkmark.seal.fill")
                        .font(.appCaption)
                        .foregroundStyle(Palette.success)
                }

                PrivacyPolicyBody(showsSummary: false)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .reportsScrollOffset()
        .appCanvas()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
