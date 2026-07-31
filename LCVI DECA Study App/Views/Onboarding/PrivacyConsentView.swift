//
//  PrivacyConsentView.swift
//  LCVI DECA Study App
//
//  The one gate in the app: the privacy notice, shown once before anything
//  else happens.
//
//  Why here and not somewhere else
//  -------------------------------
//  It sits after the intro and before onboarding. The intro is a scored,
//  choreographed thirty seconds (§5) and interrupting it with a legal wall
//  would waste the one moment the app has to make an impression. But
//  onboarding's first act has the student answering a real question, with real
//  sound and haptics — that is using the app, so consent belongs in front of
//  it, not after.
//
//  Why it does not force a scroll to the bottom
//  --------------------------------------------
//  Requiring a scroll before the button enables is a common pattern and a bad
//  one: it teaches people to flick to the end without reading, which is the
//  opposite of informed. The summary is placed first, in large type, saying
//  the four things that actually matter. The full notice is directly below for
//  anyone who wants it, and it is in Settings forever afterwards.
//

import SwiftUI

struct PrivacyConsentView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onAccept: () -> Void

    var body: some View {
        ZStack {
            IntroBackdrop(opacity: 1, drift: true)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                        header
                        PrivacyPolicyBody(showsSummary: true)
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }

                footer
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Before you start")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.accent)

            Text("Your privacy")
                .font(.appLargeTitle)
                .foregroundStyle(Palette.textPrimary)

            Text("Glass keeps everything on your phone. Please read this and accept it to continue.")
                .font(.appCallout)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appearBeat(0.05)
    }

    /// Pinned rather than scrolled with the content, so the student is never
    /// hunting for the button — and so it is obvious that accepting is the
    /// thing being asked.
    private var footer: some View {
        VStack(spacing: 10) {
            Divider().overlay(Palette.stroke)

            Text("By continuing you confirm you have read this notice.")
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            PrimaryButton(title: "Accept and continue", systemImage: "checkmark.shield") {
                Haptics.success()
                store.settings.acceptPrivacyPolicy()
                withAnimation(reduceMotion ? .easeOut(duration: 0.18) : Motion.page) {
                    onAccept()
                }
            }
            .accessibilityHint("Accepts the privacy notice and starts setting up the app")
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.regularMaterial)
    }
}
