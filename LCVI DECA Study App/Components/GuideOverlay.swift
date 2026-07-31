//
//  GuideOverlay.swift
//  LCVI DECA Study App
//
//  A first-run tour of the real interface.
//
//  Not a deck of screenshots: the guide dims the live screen and cuts a
//  spotlight around the actual element it is talking about, so what the
//  student learns is the thing itself. Views opt in by tagging themselves
//  with `.guideAnchor(_:)`; the anchors bubble up as preferences and the
//  overlay resolves them wherever it is mounted — which is the app root, so
//  the tab bar can be spotlit alongside anything on the Study screen.
//
//  The spotlight *travels*: the cutout shape animates its frame between
//  steps, so attention is led rather than teleported. Skippable from every
//  step, and replayable from Settings.
//

import SwiftUI

// MARK: - Anchors

enum GuideTarget: Int, CaseIterable {
    case goalCard, waysToStudy, tabBar
}

struct GuideAnchorKey: PreferenceKey {
    static var defaultValue: [GuideTarget: Anchor<CGRect>] = [:]
    static func reduce(value: inout [GuideTarget: Anchor<CGRect>],
                       nextValue: () -> [GuideTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Marks this view as a stop on the app guide.
    func guideAnchor(_ target: GuideTarget) -> some View {
        anchorPreference(key: GuideAnchorKey.self, value: .bounds) { [target: $0] }
    }
}

// MARK: - Steps

private struct GuideStep {
    let target: GuideTarget
    let title: String
    let body: String
}

private let guideSteps: [GuideStep] = [
    GuideStep(target: .goalCard,
              title: "Your daily goal",
              body: "The ring fills as you answer questions. Reach your goal and your streak goes up by one. Miss a day and a streak freeze covers you, if you have one."),
    GuideStep(target: .waysToStudy,
              title: "Ways to study",
              body: "Tap any tile to start. A number means how many are waiting for you. An arrow means the tile opens a full screen, like Mock Exams or Roleplay."),
    GuideStep(target: .tabBar,
              title: "The three tabs",
              body: "Study is where you practise. Progress shows your accuracy and stats. Settings has your question bank, reminders, and a button to replay this guide."),
]

// MARK: - Spotlight shape

/// Full-screen dim with a rounded cutout. The rect is animatable, so the
/// spotlight glides from one stop to the next.
private struct Spotlight: Shape {
    var rect: CGRect
    var corner: CGFloat = 24

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>,
                                       AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(rect.origin.x, rect.origin.y),
                             AnimatablePair(rect.size.width, rect.size.height)) }
        set {
            rect = CGRect(x: newValue.first.first, y: newValue.first.second,
                          width: newValue.second.first, height: newValue.second.second)
        }
    }

    func path(in bounds: CGRect) -> Path {
        var p = Path()
        p.addRect(bounds)
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: corner, height: corner),
                         style: .continuous)
        return p
    }
}

// MARK: - Overlay

struct GuideOverlay: View {
    let anchors: [GuideTarget: Anchor<CGRect>]
    let proxy: GeometryProxy
    /// Fired when a stop takes the stage, so the screen underneath can
    /// scroll that element into view — the spotlight then lands on it
    /// wherever the student had scrolled beforehand.
    var onTarget: ((GuideTarget) -> Void)? = nil
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stepIndex = 0
    /// The guide asks before it tours. Declining marks it seen — it stays
    /// one tap away in Settings.
    @State private var accepted = false

    /// Only the stops whose views are actually on screen. If the bank is
    /// empty the tile garden does not exist, and the guide simply moves on.
    private var steps: [GuideStep] {
        guideSteps.filter { anchors[$0.target] != nil }
    }

    var body: some View {
        let available = steps
        if available.isEmpty {
            Color.clear.onAppear(perform: onFinish)
        } else if !accepted {
            invitation
        } else {
            let step = available[min(stepIndex, available.count - 1)]
            let rect = anchors[step.target].map { proxy[$0].insetBy(dx: -6, dy: -6) }
                ?? .zero

            ZStack {
                // No ignoresSafeArea here: the host GeometryReader already
                // spans the full screen, and expanding this view separately
                // would shift the shape's origin away from the space the
                // anchors were resolved in — every cutout would land high by
                // exactly the top inset. One space for resolving and drawing.
                Spotlight(rect: rect)
                    .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
                    .animation(reduceMotion ? nil : Motion.gentle, value: rect)
                    // The dim is the tap target for "next" — but the card's
                    // buttons are the accessible path.
                    .contentShape(Rectangle())
                    .onTapGesture { advance(in: available) }

                card(for: step, near: rect, in: available)
            }
            .transition(.opacity)
        }
    }

    /// The ask. A full dim and one centred card — no spotlight yet, because
    /// nothing has been pointed at.
    private var invitation: some View {
        ZStack {
            Color.black.opacity(0.55)
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick tour?")
                    .font(.appTitle)
                    .foregroundStyle(Palette.textPrimary)
                Text("Three steps, about thirty seconds. It points out your daily goal, the ways to study, and what each tab does. You can replay it any time from Settings.")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "Start the tour", systemImage: "arrow.right") {
                    Haptics.tap()
                    onTarget?(steps.first?.target ?? .goalCard)
                    withAnimation(reduceMotion ? nil : Motion.gentle) { accepted = true }
                }
                .padding(.top, 2)
                Button("Not now") { onFinish() }
                    .font(.appFootnote.weight(.medium))
                    .foregroundStyle(Palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
            .padding(17)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .fill(Palette.card)
                    .shadow(color: Palette.shadow.opacity(0.3), radius: 24, y: 8)
            )
            .padding(.horizontal, 34)
        }
        .transition(.opacity)
    }

    private func card(for step: GuideStep, near rect: CGRect, in available: [GuideStep]) -> some View {
        let screen = proxy.size
        let below = rect.midY < screen.height * 0.55
        let index = available.firstIndex(where: { $0.target == step.target }) ?? 0

        return VStack {
            if below { Spacer().frame(height: min(rect.maxY + 18, screen.height - 260)) }
            else { Spacer() }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    ForEach(available.indices, id: \.self) { i in
                        Capsule()
                            .fill(i <= index ? Palette.accent : Palette.cardSunken)
                            .frame(width: i == index ? 18 : 8, height: 4)
                            .animation(reduceMotion ? nil : Motion.snappy, value: stepIndex)
                    }
                    Spacer()
                    Button("Skip guide") { finish() }
                        .font(.appFootnote.weight(.medium))
                        .foregroundStyle(Palette.textTertiary)
                }

                Text(step.title)
                    .font(.appTitle)
                    .foregroundStyle(Palette.textPrimary)
                Text(step.body)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(title: index == available.count - 1 ? "Got it" : "Next",
                              systemImage: index == available.count - 1 ? "checkmark" : "arrow.right") {
                    advance(in: available)
                }
                .padding(.top, 2)
            }
            .padding(17)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .fill(Palette.card)
                    .shadow(color: Palette.shadow.opacity(0.3), radius: 24, y: 8)
            )
            .padding(.horizontal, Metrics.gutter)
            .accessibilityElement(children: .contain)

            if !below { Spacer().frame(height: max(screen.height - rect.minY + 18, 120)) }
            else { Spacer() }
        }
        .animation(reduceMotion ? nil : Motion.gentle, value: stepIndex)
    }

    private func advance(in available: [GuideStep]) {
        if stepIndex >= available.count - 1 {
            finish()
        } else {
            Haptics.tap()
            onTarget?(available[stepIndex + 1].target)
            withAnimation(reduceMotion ? nil : Motion.gentle) { stepIndex += 1 }
        }
    }

    private func finish() {
        Haptics.success()
        onFinish()
    }
}
