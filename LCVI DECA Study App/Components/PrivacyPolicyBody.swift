//
//  PrivacyPolicyBody.swift
//  LCVI DECA Study App
//
//  The notice itself, rendered once and reused by both places it appears: the
//  acceptance gate on first launch and the always-available copy in Settings.
//
//  Sharing the view is the point. A student who accepts something on day one
//  and looks for it again in March must find the same words, and two copies of
//  this text would eventually disagree.
//

import SwiftUI

struct PrivacyPolicyBody: View {
    /// The gate shows the plain-language summary above the numbered sections;
    /// Settings shows only the notice, since by then it has been read once.
    var showsSummary: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
            if showsSummary { summaryCard }

            ForEach(PrivacyPolicy.sections) { section in
                VStack(alignment: .leading, spacing: 9) {
                    Text("\(section.id). \(section.title)")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.accent)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                        switch block {
                        case let .paragraph(text):
                            Text(text)
                                .font(.appFootnote)
                                .foregroundStyle(Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                        case let .bullets(items):
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(items, id: \.self) { item in
                                    HStack(alignment: .top, spacing: 7) {
                                        Text("•")
                                            .font(.appFootnote)
                                            .foregroundStyle(Palette.textTertiary)
                                        Text(item)
                                            .font(.appFootnote)
                                            .foregroundStyle(Palette.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Last updated \(PrivacyPolicy.lastUpdated).")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)

                // The notice above is the whole thing, so this is a way to
                // share it rather than a way to read it — a student showing a
                // parent or an advisor what the app does with their work.
                Link(destination: PrivacyPolicy.hostedURL) {
                    HStack(spacing: 5) {
                        Text("Read this online")
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.appCaption)
                    .foregroundStyle(Palette.accent)
                }
                .accessibilityHint("Opens the same notice in your browser, where it can be shared")
            }
            .padding(.top, 4)
        }
    }

    /// The part a student will actually read. Everything below it is the same
    /// commitments said again at length, which is what a notice has to do.
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("The short version", systemImage: "lock.shield.fill")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.success)

            ForEach(PrivacyPolicy.summary, id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.success)
                        .padding(.top, 2)
                    Text(line)
                        .font(.appCallout)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 17)
    }
}
