//
//  StreakAndBadges.swift
//  LCVI DECA Study App
//
//  Streak badge, achievement badges, cluster picker and goal stepper.
//

import SwiftUI

// MARK: - Streak badge

struct StreakBadge: View {
    let streak: Int
    let freezes: Int
    var compact: Bool = false
    /// Pushes the freeze capsule to the trailing edge instead of letting it
    /// sit against the streak text. For a badge given a full-width column,
    /// where hugging its content leaves the rest of the row empty.
    var spread: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayed: Double = 0
    @State private var flamePulse = false

    var body: some View {
        HStack(spacing: compact ? 6 : 10) {
            ZStack {
                Circle()
                    .fill(Palette.goldSoft)
                    .frame(width: compact ? 28 : 36, height: compact ? 28 : 36)
                Image(systemName: "flame.fill")
                    .font(.system(size: compact ? 13 : 17, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                    .scaleEffect(flamePulse ? 1.16 : 1)
            }

            VStack(alignment: .leading, spacing: 1) {
                CountingNumber(value: displayed,
                               font: .numeric(compact ? 16 : 20),
                               color: Palette.textPrimary)
                Text("day streak")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
            }

            if spread { Spacer(minLength: 10) }

            // Always shown, including at zero. Hiding it until you had one
            // meant the capsule appeared out of nowhere on day ten and there
            // was nowhere to look up how many you were holding — a count that
            // only exists when it is non-zero cannot be checked.
            HStack(spacing: 3) {
                Image(systemName: "snowflake")
                    .font(.system(size: 11, weight: .bold))
                Text("\(freezes)/\(StreakRules.maxFreezes)")
                    .font(.appCaptionBold)
                    .monospacedDigit()
            }
            .foregroundStyle(freezes > 0 ? Palette.gold : Palette.textTertiary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Capsule().fill(freezes > 0 ? Palette.goldSoft : Palette.cardSunken))
        }
        .onAppear { animate() }
        .onChange(of: streak) { _ in animate() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streak) day streak")
        .accessibilityValue("\(freezes) of \(StreakRules.maxFreezes) streak freezes")
    }

    private func animate() {
        guard !reduceMotion else {
            displayed = Double(streak)
            return
        }
        withAnimation(.easeOut(duration: 0.8)) { displayed = Double(streak) }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) { flamePulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { flamePulse = false }
        }
    }
}

// MARK: - Achievement badge

struct AchievementBadge: View {
    let status: AchievementStatus
    var size: CGFloat = 72
    /// Compact grids hide the caption so rows stay an even height.
    var showsTitle: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shine = false

    private var tint: Color {
        guard status.isUnlocked else { return Palette.inactive }
        return status.definition.isGold ? Palette.gold : Palette.accent
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(status.isUnlocked
                          ? (status.definition.isGold ? Palette.goldSoft : Palette.accentSoft)
                          : Palette.cardSunken)
                    .frame(width: size, height: size)

                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(status.isUnlocked ? tint.opacity(0.45) : Palette.stroke, lineWidth: 1.5)
                    .frame(width: size, height: size)

                Image(systemName: status.isUnlocked ? status.definition.symbol : "lock.fill")
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(tint)

            }
            .frame(width: size, height: size)
            // The sweep has to be clipped to the badge, otherwise it parks
            // itself alongside as a stray rectangle once the animation ends.
            .overlay {
                if status.isUnlocked && !reduceMotion {
                    LinearGradient(colors: [.clear, .white.opacity(0.35), .clear],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: size, height: size)
                        .offset(x: shine ? size * 1.5 : -size * 1.5)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))

            if showsTitle {
                Text(status.definition.title)
                    .font(.appCaption)
                    .foregroundStyle(status.isUnlocked ? Palette.textPrimary : Palette.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Only stretch when the caption is showing (grid layout). In a row the
        // badge must size to its content, otherwise it takes half the width and
        // floats out of line with the icons on neighbouring cards.
        .frame(maxWidth: showsTitle ? .infinity : nil)
        .onAppear {
            guard status.isUnlocked, !reduceMotion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.9)) {
                withAnimation(.easeInOut(duration: 1.1)) { shine = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.definition.title)
        .accessibilityValue(status.isUnlocked ? "Unlocked" : "Locked. \(status.definition.detail)")
    }
}

// MARK: - Cluster picker

struct ClusterPicker: View {
    @Binding var selection: DECACluster
    var showsBlurb: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            ForEach(DECACluster.allCases) { cluster in
                Button {
                    guard selection != cluster else { return }
                    Haptics.select()
                    withAnimation(Motion.snappy) { selection = cluster }
                } label: {
                    HStack(spacing: 13) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(cluster.tint.opacity(selection == cluster ? 0.2 : 0.12))
                                .frame(width: 38, height: 38)
                            Image(systemName: cluster.symbol)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(cluster.tint)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cluster.displayName)
                                .font(.appCallout.weight(.medium))
                                .foregroundStyle(Palette.textPrimary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            if showsBlurb {
                                Text(cluster.blurb)
                                    .font(.appCaption)
                                    .foregroundStyle(Palette.textSecondary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 4)
                        Image(systemName: selection == cluster ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selection == cluster ? Palette.accent : Palette.strokeStrong)
                    }
                    .padding(13)
                    .frame(minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                            .fill(selection == cluster ? Palette.accentSoft : Palette.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                            .strokeBorder(selection == cluster ? Palette.accent : Palette.stroke,
                                          lineWidth: selection == cluster ? 2 : 1)
                    )
                }
                .buttonStyle(PressableButtonStyle(scale: 0.985, haptic: false))
                .accessibilityAddTraits(selection == cluster ? [.isSelected, .isButton] : .isButton)
            }
        }
    }
}

// MARK: - Goal stepper

struct GoalStepper: View {
    @Binding var goal: Int
    private let presets = [5, 10, 20]

    private var isCustom: Bool { !presets.contains(goal) }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { value in
                    Button {
                        Haptics.select()
                        withAnimation(Motion.snappy) { goal = value }
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(value)")
                                .font(.numeric(20))
                            Text("per day")
                                .font(.appCaption)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .foregroundStyle(goal == value ? Color.white : Palette.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                                .fill(goal == value ? Palette.accent : Palette.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                                .strokeBorder(goal == value ? Color.clear : Palette.stroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PressableButtonStyle(haptic: false))
                    .accessibilityLabel("\(value) questions per day")
                    .accessibilityAddTraits(goal == value ? [.isSelected, .isButton] : .isButton)
                }

                Button {
                    Haptics.select()
                    withAnimation(Motion.snappy) { goal = isCustom ? goal : 15 }
                } label: {
                    VStack(spacing: 2) {
                        Text(isCustom ? "\(goal)" : "•••")
                            .font(.numeric(20))
                        Text("custom")
                            .font(.appCaption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .foregroundStyle(isCustom ? Color.white : Palette.textPrimary)
                    .background(
                        RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                            .fill(isCustom ? Palette.accent : Palette.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                            .strokeBorder(isCustom ? Color.clear : Palette.stroke, lineWidth: 1)
                    )
                }
                .buttonStyle(PressableButtonStyle(haptic: false))
                .accessibilityLabel("Custom goal")
            }

            if isCustom {
                HStack {
                    Text("Custom goal")
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                    Spacer()
                    AppStepper(value: $goal, in: 1...100, step: 1) {
                        Text("\(goal) questions")
                            .font(.appCallout.weight(.medium))
                            .foregroundStyle(Palette.textPrimary)
                            .monospacedDigit()
                    }
                    .fixedSize()
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
