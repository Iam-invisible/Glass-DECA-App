//
//  CelebrationOverlay.swift
//  LCVI DECA Study App
//
//  Goal completion, streak freezes and achievement unlocks.
//
//  The badge is launched up from the bottom of an opaque screen, spins with
//  decaying angular momentum, bounces to a stop, then grows and presents itself.
//  Haptics are scored to the same beats: a launch thump, one impact per bounce
//  with decreasing energy, and a success tone when it settles.
//
//  Tap anywhere to dismiss. Reduce Motion collapses the whole thing to a fade.
//

import SwiftUI

struct CelebrationOverlay: View {
    let event: AppEvent
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation state
    @State private var backdrop: Double = 0
    @State private var offsetY: CGFloat = 560
    @State private var spin: Double = 0
    @State private var tilt: Double = 15
    @State private var scale: CGFloat = 0.72
    @State private var glow: Double = 0
    @State private var ringScale: CGFloat = 0.55
    @State private var ringOpacity: Double = 0
    @State private var textShown = false
    @State private var hintShown = false
    @State private var shineX: CGFloat = -1
    @State private var dismissing = false
    @State private var sequence: Task<Void, Never>?
    /// The event id the current choreography belongs to. SwiftUI reuses this
    /// view when one queued event replaces another, which keeps every `@State`
    /// above — including `dismissing` — so the run has to be re-armed by hand.
    @State private var startedFor: String?

    private let badgeSize: CGFloat = 132
    /// Fifteen turns. Kept in one place so the animation and the motion blur
    /// can't drift apart.
    private let totalSpin: Double = 15 * 360

    // MARK: - Content per event

    private var symbol: String {
        switch event {
        case .goalCompleted:        return "checkmark.circle.fill"
        case .freezeEarned:         return "snowflake"
        case .achievement(let def): return def.symbol
        }
    }

    private var tint: Color {
        switch event {
        case .goalCompleted:        return Palette.success
        case .freezeEarned:         return Palette.gold
        case .achievement(let def): return def.isGold ? Palette.gold : Palette.accent
        }
    }

    private var eyebrow: String {
        switch event {
        case .goalCompleted: return "DAILY GOAL"
        case .freezeEarned:  return "REWARD EARNED"
        case .achievement:   return "ACHIEVEMENT UNLOCKED"
        }
    }

    private var title: String {
        switch event {
        case .goalCompleted:        return "Daily goal complete"
        case .freezeEarned:         return "Streak freeze earned"
        case .achievement(let def): return def.title
        }
    }

    private var message: String {
        switch event {
        case .goalCompleted(let streak):
            return streak > 1
                ? "That's \(streak) days in a row. Keep it going."
                : "Your streak has started. Come back tomorrow."
        case .freezeEarned(let total):
            return total == 1
                ? "You now have 1 freeze. It protects your streak if you miss a day."
                : "You now have \(total) freezes. Each one protects your streak for a missed day."
        case .achievement(let def):
            return def.detail
        }
    }

    /// Gold events get one extra beat of celebration at the end.
    private var isGold: Bool {
        switch event {
        case .goalCompleted:        return false
        case .freezeEarned:         return true
        case .achievement(let def): return def.isGold
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            background
            badgeStack
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .onAppear(perform: run)
        .onChange(of: event.id) { _ in run() }
        .onDisappear { sequence?.cancel() }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits([.isModal, .isButton])
        .accessibilityLabel("\(eyebrow.capitalized). \(title). \(message)")
        .accessibilityHint("Double tap to continue")
        .accessibilityAction { dismiss() }
    }

    private var background: some View {
        ZStack {
            // Fully opaque — the badge gets the whole screen to itself.
            Palette.canvas
            RadialGradient(colors: [tint.opacity(0.30 * glow), .clear],
                           center: .center,
                           startRadius: 8,
                           endRadius: 340)
        }
        .opacity(backdrop)
        .ignoresSafeArea()
    }

    private var badgeStack: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack {
                expandingRings
                badge
            }
            .offset(y: offsetY)

            Spacer(minLength: 0)
                .frame(height: 26)

            caption
                .opacity(textShown ? 1 : 0)
                .offset(y: textShown ? 0 : 18)

            Spacer(minLength: 0)

            Text("Tap anywhere to continue")
                .font(.appFootnote)
                .foregroundStyle(Palette.textTertiary)
                .opacity(hintShown ? 1 : 0)
                .padding(.bottom, 34)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Badge

    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: badgeSize * 0.28, style: .continuous)
                .fill(isGold ? Palette.goldSoft : tint.opacity(0.16))

            RoundedRectangle(cornerRadius: badgeSize * 0.28, style: .continuous)
                .strokeBorder(tint.opacity(0.55), lineWidth: 2)

            Image(systemName: symbol)
                .font(.system(size: badgeSize * 0.42, weight: .semibold))
                .foregroundStyle(tint)

            // Shine sweep once it has presented itself.
            RoundedRectangle(cornerRadius: badgeSize * 0.28, style: .continuous)
                .fill(
                    LinearGradient(colors: [.clear, .white.opacity(0.45), .clear],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .offset(x: shineX * badgeSize * 1.6)
                .allowsHitTesting(false)
        }
        .frame(width: badgeSize, height: badgeSize)
        .clipShape(RoundedRectangle(cornerRadius: badgeSize * 0.28, style: .continuous))
        .modifier(TopSpin(angle: spin, total: totalSpin))
        .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .shadow(color: tint.opacity(0.35 * glow), radius: 26, y: 10)
        .scaleEffect(scale)
    }

    private var expandingRings: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .strokeBorder(tint.opacity(ringOpacity * (index == 0 ? 1 : 0.55)), lineWidth: 2)
                    .frame(width: badgeSize * 1.25, height: badgeSize * 1.25)
                    .scaleEffect(ringScale + CGFloat(index) * 0.28)
            }
        }
        .allowsHitTesting(false)
    }

    private var caption: some View {
        VStack(spacing: 9) {
            Text(eyebrow)
                .font(.appCaptionBold)
                .tracking(1.4)
                .foregroundStyle(tint)

            Text(title)
                .font(.appLargeTitle)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            Text(message)
                .font(.appCallout)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Choreography

    private func run() {
        guard startedFor != event.id else { return }
        startedFor = event.id
        sequence?.cancel()
        resetState()

        SoundEffects.celebration()

        guard !reduceMotion else {
            offsetY = 0
            // A whole number of turns renders identically to 0 and leaves the
            // blur at rest.
            spin = totalSpin
            tilt = 0
            withAnimation(.easeOut(duration: 0.22)) {
                backdrop = 1
                scale = 1.12
                glow = 1
                textShown = true
                hintShown = true
            }
            Haptics.success()
            return
        }

        sequence = Task { @MainActor in
            // Launch —––––––––––––––––––––––––––––––––––––––––––––––––––––––
            withAnimation(.easeOut(duration: 0.20)) { backdrop = 1 }
            // Fifteen turns, landing on an exact multiple of 360° so the badge
            // finishes facing forward. The curve is deliberately flatter than a
            // stock ease-out: a steeper one front-loads two thirds of the turns
            // into the first ~120ms, where they're too fast to see at all.
            withAnimation(.timingCurve(0.2, 0.55, 0.3, 1.0, duration: 1.0)) { spin = totalSpin }
            withAnimation(.easeOut(duration: 0.32)) {
                offsetY = -70          // overshoot above centre
                scale = 1.0
            }
            Haptics.impact(.medium, intensity: 0.75)

            // Fall to the first landing ––––––––––––––––––––––––––––––––––––
            try? await sleep(0.32)
            withAnimation(.easeIn(duration: 0.16)) { offsetY = 0 }

            // Bounce 1 — the heaviest hit
            try? await sleep(0.16)
            Haptics.impact(.heavy, intensity: 1.0)
            withAnimation(.easeOut(duration: 0.14)) { offsetY = -44 }
            try? await sleep(0.14)
            withAnimation(.easeIn(duration: 0.12)) { offsetY = 0 }

            // Bounce 2
            try? await sleep(0.12)
            Haptics.impact(.medium, intensity: 0.7)
            withAnimation(.easeOut(duration: 0.09)) { offsetY = -18 }
            try? await sleep(0.09)
            withAnimation(.easeIn(duration: 0.08)) { offsetY = 0 }

            // Bounce 3
            try? await sleep(0.08)
            Haptics.impact(.light, intensity: 0.5)
            withAnimation(.easeOut(duration: 0.06)) { offsetY = -6 }
            try? await sleep(0.06)
            withAnimation(.easeIn(duration: 0.05)) { offsetY = 0 }

            // Settle
            try? await sleep(0.05)
            Haptics.impact(.light, intensity: 0.3)

            // Present —––––––––––––––––––––––––––––––––––––––––––––––––––––
            try? await sleep(0.05)
            Haptics.success()
            withAnimation(.spring(response: 0.30, dampingFraction: 0.5)) {
                scale = 1.28
                glow = 1
                tilt = 0        // the top settles upright as it presents itself
            }
            withAnimation(.easeOut(duration: 0.52)) {
                ringScale = 1.5
                ringOpacity = 0.9
            }
            withAnimation(.easeOut(duration: 0.52).delay(0.06)) { ringOpacity = 0 }

            try? await sleep(0.18)
            withAnimation(.spring(response: 0.36, dampingFraction: 0.75)) { scale = 1.12 }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { textShown = true }

            // Shine + a final flourish for gold rewards
            try? await sleep(0.14)
            shineX = -1
            withAnimation(.easeInOut(duration: 0.7)) { shineX = 1 }
            if isGold {
                Haptics.impact(.heavy, intensity: 0.55)
            }

            try? await sleep(0.4)
            withAnimation(.easeIn(duration: 0.3)) { hintShown = true }
        }
    }

    private func sleep(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Puts every animated property back to its pre-launch value. Explicitly
    /// unanimated: a dismissal may still be in flight when the next event
    /// arrives, and we don't want the reset to inherit its curve.
    private func resetState() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            backdrop = 0
            offsetY = 560
            spin = 0
            tilt = 15
            scale = 0.72
            glow = 0
            ringScale = 0.55
            ringOpacity = 0
            textShown = false
            hintShown = false
            shineX = -1
            dismissing = false
        }
    }

    private func dismiss() {
        guard !dismissing else { return }
        dismissing = true
        sequence?.cancel()
        SoundEffects.stop(.celebration)
        Haptics.tap()

        guard !reduceMotion else {
            onDismiss()
            return
        }
        withAnimation(.easeIn(duration: 0.22)) {
            backdrop = 0
            scale = 0.86
            offsetY = 40
            textShown = false
            hintShown = false
            glow = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: onDismiss)
    }
}

// MARK: - Top spin

/// Spins a view about its vertical axis, the way a top spins on a table, with
/// synthetic motion blur.
///
/// Conforming to `Animatable` is what makes this work: SwiftUI re-evaluates the
/// modifier body on every frame of the animation, so both the mirror correction
/// and the blur can track the live angle. A plain `rotation3DEffect` would show
/// the reversed back face for half of every turn, flipping the badge's symbol.
///
/// SwiftUI has no motion blur, so this does what an offline renderer does: it
/// samples the badge at several angles *behind* the current one and composites
/// them into a smear. That's what stops a very fast spin from strobing — the
/// gaps between sampled frames get filled in rather than left as hard jumps.
struct TopSpin: ViewModifier, Animatable {
    /// Current angle in degrees.
    var angle: Double
    /// Where the spin ends. Used to infer how fast it's currently turning.
    var total: Double
    /// Number of composited samples, including the leading face.
    var samples: Int = 7
    /// How far behind the leading face the smear reaches, at full speed.
    var smearArc: Double = 96

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    /// The spin decays toward `total`, so distance-to-go is a good stand-in for
    /// angular velocity — no need to differentiate the timing curve.
    private var speed: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, total - angle) / 720)
    }

    func body(content: Content) -> some View {
        let speed = self.speed

        return ZStack {
            if speed > 0.02 {
                ForEach(1..<samples, id: \.self) { index in
                    let t = Double(index) / Double(samples - 1)
                    face(content, at: angle - t * smearArc * speed)
                        // Trailing samples fade out, so the smear reads as a
                        // wake behind the badge rather than N stacked copies.
                        .opacity(0.42 * speed * (1 - t))
                }
            }
            face(content, at: angle)
        }
        // Softens the discrete steps between samples into a continuous blur.
        .blur(radius: speed * 2.5)
    }

    @ViewBuilder
    private func face(_ content: Content, at faceAngle: Double) -> some View {
        let normalized = (faceAngle.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        // Between 90° and 270° we're looking at the back of the badge, so
        // pre-mirror the artwork to cancel the reversal out.
        let showingBack = normalized > 90 && normalized < 270

        content
            .scaleEffect(x: showingBack ? -1 : 1, y: 1)
            .rotation3DEffect(.degrees(faceAngle),
                              axis: (x: 0, y: 1, z: 0),
                              perspective: 0.55)
    }
}

// MARK: - Hosting

/// Hosts celebration overlays for one presentation layer.
///
/// A `fullScreenCover` renders above everything the root view can draw, so an
/// overlay attached to the root is invisible while a practice session or mock
/// exam is on screen — which is exactly when most achievements unlock. Each
/// full-screen flow therefore claims the layer while it's presented, and the
/// root stands down, so there is always exactly one visible host (and one set
/// of haptics).
struct CelebrationLayer: ViewModifier {
    @EnvironmentObject private var store: AppStore
    let isFullScreen: Bool

    private var hosts: Bool {
        isFullScreen ? true : store.fullScreenLayers == 0
    }

    func body(content: Content) -> some View {
        content
            .onAppear { if isFullScreen { store.fullScreenLayers += 1 } }
            .onDisappear { if isFullScreen { store.fullScreenLayers = max(0, store.fullScreenLayers - 1) } }
            .overlay(alignment: .center) {
                if hosts, let event = store.eventQueue.first {
                    CelebrationOverlay(event: event) {
                        store.dismissCurrentEvent()
                    }
                    // Distinct identity per event, so a queued follow-up gets a
                    // clean view rather than the previous one's leftover state.
                    .id(event.id)
                    .zIndex(10)
                }
            }
    }
}

extension View {
    /// Marks this view as the host for celebration overlays. Pass
    /// `isFullScreen: true` from anything presented in a `fullScreenCover`.
    func celebrationLayer(isFullScreen: Bool = false) -> some View {
        modifier(CelebrationLayer(isFullScreen: isFullScreen))
    }
}
