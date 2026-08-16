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

/// One place the widget can be added, and the taps that get it there.
private struct HowTo: Identifiable {
    let place: String
    let steps: [String]
    var id: String { place }
}

private struct GuideStep {
    /// `nil` means there is nothing on screen to point at. The widget lives in
    /// iOS, not in this app, so that step dims the screen and centres its card
    /// instead of hunting for an anchor that will never exist.
    let target: GuideTarget?
    let title: String
    let body: String
    var howTo: [HowTo] = []
}

private let guideSteps: [GuideStep] = [
    GuideStep(target: .goalCard,
              title: "Your daily goal",
              body: "The ring fills as you answer questions. Reach your goal and your streak goes up by one. Miss a day and a streak freeze covers you, if you have one."),
    GuideStep(target: .waysToStudy,
              title: "Ways to study",
              body: "Tap any tile to start. A number means how many are waiting for you. An arrow means the tile opens a full screen, like Mock Exams or Roleplay."),
    // Four, not three: the Shop pane arrived after this copy was written and
    // the guide kept counting the old tab bar.
    GuideStep(target: .tabBar,
              title: "The four tabs",
              body: "Study is where you practise. Progress shows your accuracy and stats. Shop is what your coins buy. Settings has your question bank, reminders, and a button to replay this guide."),
    // Last on purpose. It is the one feature a student can own without ever
    // opening the app again, and the only one they cannot stumble across from
    // inside it — nothing in Glass links to the iOS widget gallery.
    GuideStep(target: nil,
              title: "Add the daily fact",
              body: "One fact from your cluster every day, without opening the app. Add it once and it changes on its own. Both widgets are called Daily fact.",
              howTo: [
                HowTo(place: "Home Screen", steps: [
                    "Touch and hold an empty part of the screen until the icons wobble.",
                    "Tap the plus button, then search for Glass.",
                    "Pick Daily fact and add it.",
                ]),
                HowTo(place: "Lock Screen", steps: [
                    "Touch and hold the Lock Screen, then tap Customise.",
                    "Tap the space under the clock.",
                    "Pick Glass, then Daily fact.",
                ]),
              ]),
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
    /// Anchorless steps are always kept — there is nothing to miss.
    private var steps: [GuideStep] {
        guideSteps.filter { $0.target == nil || anchors[$0.target!] != nil }
    }

    var body: some View {
        let available = steps
        if available.isEmpty {
            Color.clear.onAppear(perform: onFinish)
        } else if !accepted {
            invitation
        } else {
            let step = available[min(stepIndex, available.count - 1)]
            let rect: CGRect? = step.target
                .flatMap { anchors[$0] }
                .map { proxy[$0].insetBy(dx: -6, dy: -6) }

            ZStack {
                // No ignoresSafeArea here: the host GeometryReader already
                // spans the full screen, and expanding this view separately
                // would shift the shape's origin away from the space the
                // anchors were resolved in — every cutout would land high by
                // exactly the top inset. One space for resolving and drawing.
                // An anchorless step has no cutout, so the dim is a plain fill
                // rather than an even-odd path with a zero rect — which would
                // punch a stray hole at the origin.
                Spotlight(rect: rect ?? .zero)
                    .fill(Color.black.opacity(0.55),
                          style: FillStyle(eoFill: rect != nil))
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
                Text("Four steps, about a minute. It points out your daily goal, the ways to study, what each tab does, and how to put the daily fact on your Lock Screen. You can replay it any time from Settings.")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "Start the tour", systemImage: "arrow.right") {
                    Haptics.tap()
                    if let first = steps.first?.target { onTarget?(first) }
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

    private func card(for step: GuideStep, near rect: CGRect?, in available: [GuideStep]) -> some View {
        let screen = proxy.size
        // No rect means no element to sit beside, so the card takes the middle.
        let below = rect.map { $0.midY < screen.height * 0.55 }
        let index = available.firstIndex(where: { $0.title == step.title }) ?? 0

        return VStack {
            if let rect, below == true { Spacer().frame(height: min(rect.maxY + 18, screen.height - 260)) }
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

                ForEach(step.howTo) { how in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(how.place.uppercased())
                            // §8.23: eyebrow text is `.appCaptionBold`.
                            .font(.appCaptionBold)
                            .tracking(0.8)
                            .foregroundStyle(Palette.accent)
                        ForEach(Array(how.steps.enumerated()), id: \.offset) { i, line in
                            HStack(alignment: .top, spacing: 9) {
                                Text("\(i + 1)")
                                    .font(.appCaption.weight(.semibold))
                                    .foregroundStyle(Palette.accent)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(Palette.accentSoft))
                                Text(line)
                                    .font(.appCaption)
                                    .foregroundStyle(Palette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.top, 3)
                    .accessibilityElement(children: .combine)
                }

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

            if let rect, below == false { Spacer().frame(height: max(screen.height - rect.minY + 18, 120)) }
            else { Spacer() }
        }
        .animation(reduceMotion ? nil : Motion.gentle, value: stepIndex)
    }

    private func advance(in available: [GuideStep]) {
        if stepIndex >= available.count - 1 {
            finish()
        } else {
            Haptics.tap()
            // Only ask the screen to scroll when the next stop is something on
            // it. The widget step has nothing to bring into view.
            if let next = available[stepIndex + 1].target { onTarget?(next) }
            withAnimation(reduceMotion ? nil : Motion.gentle) { stepIndex += 1 }
        }
    }

    private func finish() {
        Haptics.success()
        onFinish()
    }
}
