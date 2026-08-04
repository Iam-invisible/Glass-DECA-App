//
//  BunnyCompanionView.swift
//  LCVI DECA Study App
//
//  The bunny, in the bottom-right corner of every screen.
//
//  Hosting works the same way `CelebrationLayer` does, and for the same
//  reason: a `fullScreenCover` draws above anything the root view can, so an
//  overlay attached to the root is invisible during a practice session or a
//  mock — which is precisely when right and wrong answers fire. Each
//  full-screen flow claims the layer while it is up and the root stands down,
//  so there is exactly one bunny on screen at any moment.
//
//  It never takes a touch. A decorative companion that swallows a tap on the
//  control underneath it is a bug, so the layer is `allowsHitTesting(false)`
//  and overlapping something is merely cosmetic.
//

import SwiftUI

struct BunnyCompanionView: View {
    /// The last event, or nil for idle. Set by `AppStore.react(_:)`.
    let event: BunnyEvent?
    /// Bumped by the store on every reaction. `BunnyEvent` is not Equatable
    /// and the same event twice in a row must still re-fire — two correct
    /// answers should not leave the face frozen — so the view keys off this
    /// counter rather than off the event itself.
    let token: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var mood: BunnyMood = .content
    @State private var hop: CGFloat = 0
    @State private var shake: CGFloat = 0
    @State private var idleBob = false
    @State private var lastHandled: Int = -1

    /// Sized to the widest sprite's aspect — the ones carrying a speech bubble
    /// are ~1.35:1 — so a mood change never resizes the frame. Larger than it
    /// was in the HUD: free-floating in a corner it has room, and the faces
    /// carry more detail than a 34pt box could show.
    private let size = CGSize(width: 64, height: 47)

    var body: some View {
        sprite
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .offset(y: -hop + (idleBob && !reduceMotion ? -1.5 : 0))
            .modifier(RefusalShake(progress: shake, amplitude: 7, oscillations: 3))
            // Cross-fade rather than a hard swap: the sprites differ enough
            // that a cut reads as a flicker.
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.14), value: mood)
            .onAppear { startIdleBob() }
            .onChange(of: token) { _ in respond() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Bunny companion, \(mood.rawValue)")
    }

    /// Resolved through `UIImage(named:)` rather than `Image(_:)` so a missing
    /// file is visible instead of silent. The sprites are loose PNGs at the
    /// bundle root, not asset-catalog entries, and a name that fails to
    /// resolve draws nothing at all — which looks identical to the companion
    /// not being owned, and would send you looking in the wrong place.
    private var sprite: Image {
        if let ui = UIImage(named: mood.imageName) { return Image(uiImage: ui) }
        return Image(systemName: "questionmark.square.dashed")
    }

    private func respond() {
        guard let event, token != lastHandled else { return }
        lastHandled = token

        mood = event.moods.randomElement() ?? .content

        if !reduceMotion {
            if event.hop > 0 {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) { hop = event.hop }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.6)) { hop = 0 }
                }
            }
            if event.shakes {
                shake = 0
                withAnimation(.linear(duration: 0.5)) { shake = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = 0 }
            }
        }

        guard event.duration > 0 else { return }
        let firedAt = token
        DispatchQueue.main.asyncAfter(deadline: .now() + event.duration) {
            // Only settle if nothing else happened in the meantime, or a fast
            // run of answers would keep yanking the face back to idle.
            guard firedAt == lastHandled else { return }
            mood = BunnyEvent.idle.moods.randomElement() ?? .neutral
        }
    }

    /// A slow 1.5pt rise and fall. Enough that the corner is not dead, small
    /// enough that it never pulls the eye off a question.
    private func startIdleBob() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
            idleBob = true
        }
    }
}


// MARK: - Hosting

/// Puts the bunny in the bottom-right of whatever is currently on top.
///
/// `isFullScreen` mirrors `CelebrationLayer`: anything presented in a
/// `fullScreenCover` passes true, claims the layer for as long as it is up,
/// and the root suppresses its own copy so there are never two.
struct BunnyLayer: ViewModifier {
    @EnvironmentObject private var store: AppStore
    let isFullScreen: Bool

    private var hosts: Bool {
        isFullScreen ? true : store.fullScreenLayers == 0
    }

    /// Bought *and* switched on. Owning it is not the same as wanting it on
    /// screen — the switch is in the Shop, on the row it was bought from.
    private var showsCompanion: Bool {
        store.settings.ownedAppItemIDs.contains(BunnyCompanion.itemID)
            && store.settings.companionEnabled
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                if hosts, showsCompanion {
                    BunnyCompanionView(event: store.bunnyEvent, token: store.bunnyToken)
                        .padding(.trailing, Metrics.gutter)
                        // Clears the floating tab bar at the root; a full-screen
                        // flow has no tab bar but does have its own controls
                        // down there, so it keeps a smaller berth.
                        .padding(.bottom, isFullScreen ? 22 : AppTabBar.contentHeight + 12)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(9)
                }
            }
    }
}

extension View {
    /// Marks this view as the host for the bunny. Pass `isFullScreen: true`
    /// from anything presented in a `fullScreenCover`.
    func bunnyLayer(isFullScreen: Bool = false) -> some View {
        modifier(BunnyLayer(isFullScreen: isFullScreen))
    }
}
