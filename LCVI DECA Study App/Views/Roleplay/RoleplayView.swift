//
//  RoleplayView.swift
//  LCVI DECA Study App
//
//  Roleplay prompt list, filtered to the student's cluster by default.
//

import SwiftUI

struct RoleplayView: View {
    @EnvironmentObject private var store: AppStore

    @State private var prompts: [RoleplayPromptData] = []
    @State private var showAllClusters = false
    @State private var practiceCounts: [UUID: Int] = [:]
    @State private var showingQuickThink = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.stackSpacing) {
                    quickThinkCard.appearIn(0)

                    SectionHeader(title: "Roleplay scenarios",
                                  subtitle: showAllClusters
                                    ? "All clusters"
                                    : store.settings.cluster.displayName,
                                  actionTitle: showAllClusters ? "My cluster" : "Show all") {
                        withAnimation(Motion.snappy) { showAllClusters.toggle() }
                        reload()
                    }
                    .appearIn(1)

                    if prompts.isEmpty {
                        EmptyStateView(systemImage: "person.wave.2",
                                       title: "No roleplays yet",
                                       message: "Roleplay scenarios for your cluster will appear here.")
                            .appCard()
                    } else {
                        ForEach(Array(prompts.enumerated()), id: \.element.id) { index, prompt in
                            NavigationLink {
                                RoleplayDetailView(prompt: prompt)
                            } label: {
                                RoleplayCard(prompt: prompt,
                                             practiceCount: practiceCounts[prompt.id] ?? 0)
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
                            .appearIn(min(index + 2, 8))
                        }
                    }

                    Text("Sample practice scenarios written for this app — not official DECA Ontario roleplay materials.")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .appCanvas()
            .navigationTitle("Roleplay")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear(perform: reload)
        .fullScreenCover(isPresented: $showingQuickThink) {
            QuickThinkView().environmentObject(store)
        }
    }

    private var quickThinkCard: some View {
        Button {
            Haptics.tap()
            showingQuickThink = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.accentSoft)
                        .frame(width: 48, height: 48)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Quick Think")
                        .font(.appBodyMedium)
                        .foregroundStyle(Palette.textPrimary)
                    Text("A short scenario, a short timer, and instant feedback on your answer.")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .appCard()
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
        .accessibilityElement(children: .combine)
    }

    private func reload() {
        prompts = store.bank.roleplays(for: showAllClusters ? nil : store.settings.cluster)
        if prompts.isEmpty && !showAllClusters {
            prompts = store.bank.roleplays()
        }
        var counts: [UUID: Int] = [:]
        for response in store.roleplayResponses() {
            guard let id = response.promptID else { continue }
            counts[id, default: 0] += 1
        }
        practiceCounts = counts
    }
}

// MARK: - Card

struct RoleplayCard: View {
    let prompt: RoleplayPromptData
    var practiceCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                TagPill(text: prompt.cluster.shortName,
                        color: prompt.cluster.tint,
                        soft: prompt.cluster.tint.opacity(0.13),
                        icon: prompt.cluster.symbol)
                TagPill(text: prompt.difficulty.title,
                        color: prompt.difficulty.color,
                        soft: prompt.difficulty.color.opacity(0.13))
                Spacer(minLength: 0)
                if practiceCount > 0 {
                    TagPill(text: "\(practiceCount)×",
                            color: Palette.success, soft: Palette.successSoft, icon: "checkmark")
                }
            }

            Text(prompt.title)
                .font(.appHeadline)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(prompt.eventType)
                .font(.appFootnote)
                .foregroundStyle(Palette.textSecondary)

            if !prompt.performanceIndicators.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Performance indicators", systemImage: "target")
                        .font(.appCaptionBold)
                        .foregroundStyle(Palette.gold)
                    Text(prompt.performanceIndicators.joined(separator: " · "))
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 14) {
                Label("\(prompt.prepMinutes) min prep", systemImage: "hourglass")
                Label("\(prompt.presentMinutes) min present", systemImage: "person.wave.2")
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .font(.appCaption)
            .foregroundStyle(Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
        .accessibilityElement(children: .combine)
    }
}
