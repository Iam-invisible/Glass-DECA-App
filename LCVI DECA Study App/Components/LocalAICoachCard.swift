//
//  LocalAICoachCard.swift
//  LCVI DECA Study App
//
//  The offer to download a local AI coach, shown only to students whose
//  device cannot run Apple's on-device model.
//
//  Used in onboarding and again in Settings, so a student who says no at
//  first can change their mind, and one who says yes can reclaim the space.
//

import SwiftUI

struct LocalAICoachCard: View {
    @ObservedObject var service: LocalModelService
    /// Observed directly rather than reached through `AppStore`: nested
    /// `ObservableObject`s don't propagate (§8.11), and `AppStore` bridges
    /// only `settings` and `localModel`, not `ai`.
    @ObservedObject var ai: FoundationModelFeedbackService
    /// Onboarding introduces the idea; Settings just manages it.
    var showsIntroCopy: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            switch service.state {
            case .deviceTooSmall:
                // Never offered — downloading 770 MB this phone cannot load
                // would be a straightforward waste of a student's data.
                InfoBanner(systemImage: "checkmark.circle",
                           title: "The app is fully usable without AI",
                           message: "This phone doesn't have enough memory to run a local model. Practice, mock exams, roleplays and progress all work offline, with written explanations and a manual rubric.",
                           tint: Palette.success)

            case .notDownloaded:
                offer

            case let .downloading(progress, received):
                downloading(progress: progress, received: received)

            case .verifying:
                statusRow("Checking the download…", systemImage: "checkmark.shield")

            case .ready:
                ready

            case let .failed(message):
                VStack(alignment: .leading, spacing: 12) {
                    InfoBanner(systemImage: "exclamationmark.triangle",
                               title: "Download didn't finish",
                               message: message,
                               tint: Palette.gold)
                    downloadButton(title: "Try again")
                }
            }
        }
        .animation(reduceMotion ? nil : Motion.snappy, value: service.state)
        .animation(reduceMotion ? nil : Motion.snappy, value: ai.localCoachFailedToLoad)
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 11) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Local AI coach")
                    .font(.appCallout.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text("Optional — adds explanations and roleplay coaching to this phone.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var offer: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsIntroCopy {
                Text("Your phone can't run Apple Intelligence, but it can run a smaller model on its own. Download it once and coaching works offline from then on.")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 9) {
                factRow(systemImage: "wifi",
                        text: "Wi-Fi needed for the download only. After that it runs offline and never connects again.")
                factRow(systemImage: "internaldrive",
                        text: "About \(LocalModelCatalog.approximateMegabytes) MB of space. You can delete it any time in Settings.")
                factRow(systemImage: "lock.shield",
                        text: "Still no account and no tracking — the download sends nothing about you.")
            }

            downloadButton(title: "Download AI coach (\(LocalModelCatalog.approximateMegabytes) MB)")
            attribution
        }
    }

    private func downloading(progress: Double, received: Int64) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            ProgressBar(progress: progress)

            HStack {
                Text("\(Int(progress * 100))% — \(received / 1_000_000) of \(LocalModelCatalog.approximateMegabytes) MB")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
                    .monospacedDigit()
                Spacer()
                Button("Cancel") {
                    Haptics.tap()
                    service.cancelDownload()
                }
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(Palette.accent)
            }

            Text("Keep Glass open while this downloads.")
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Downloading AI coach")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }

    /// `service.state` is about the *file* — it reaches `.ready` on presence
    /// and a hash match alone. Whether the model actually runs is a separate
    /// question that only the engine can answer, so the green line is claimed
    /// only while the engine has not failed. Reporting "installed and running"
    /// on a phone whose engine had already latched a failed load left the
    /// student a green tick here and an "unavailable" status one screen over.
    private var ready: some View {
        VStack(alignment: .leading, spacing: 12) {
            if ai.localCoachFailedToLoad {
                InfoBanner(systemImage: "exclamationmark.triangle",
                           title: "AI coach didn't start",
                           message: "The download finished, but this phone couldn't load the model. Explanations and roleplay feedback are written instead. Everything else works as normal.",
                           tint: Palette.gold)
            } else {
                statusRow("AI coach installed and running on this phone.",
                          systemImage: "checkmark.circle.fill",
                          tint: Palette.success)
            }
            deleteButton
            attribution
        }
    }

    /// Shared by both `ready` states: a coach that failed to start is the case
    /// where reclaiming the space matters most, and this is the only route to
    /// `deleteModel()`.
    private var deleteButton: some View {
        Button {
            Haptics.tap()
            service.deleteModel()
        } label: {
            Text("Delete AI coach (frees \(LocalModelCatalog.approximateMegabytes) MB)")
                .font(.appFootnote.weight(.medium))
                .foregroundStyle(Palette.danger)
        }
        .buttonStyle(.plain)
    }

    private func downloadButton(title: String) -> some View {
        PrimaryButton(title: title, systemImage: "arrow.down.circle.fill") {
            service.startDownload()
        }
    }

    private var attribution: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalModelCatalog.attribution)
                .font(.appCaptionBold)
                .foregroundStyle(Palette.textSecondary)
            Text(LocalModelCatalog.licenceNote)
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }

    private func factRow(systemImage: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 18)
            Text(text)
                .font(.appCaption)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func statusRow(_ text: String,
                           systemImage: String,
                           tint: Color = Palette.accent) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.appFootnote)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// Drawn rather than a `ProgressView`, for the same reason as everything in
/// `AppControls`: the system bar looks different on iOS 16 and iOS 26.
struct ProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.cardSunken)
                Capsule()
                    .fill(Palette.accent)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: 8)
        .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 1))
    }
}
