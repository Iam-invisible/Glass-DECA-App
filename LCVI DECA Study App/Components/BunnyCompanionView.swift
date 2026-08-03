//
//  BunnyCompanionView.swift
//  LCVI DECA Study App
//
//  The bunny, sitting in the HUD beside the coin balance.
//
//  It lives next to the coins rather than floating loose because the two are
//  the same kind of thing — persistent, non-interactive, always-there — and a
//  character wandering over content would be in the way on a screen whose job
//  is reading questions.
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

    /// Sized to the widest sprite's aspect (the ones carrying a speech bubble
    /// are ~1.35:1) so a narrow face does not shift the coin badge beside it
    /// when the mood changes.
    private let size = CGSize(width: 46, height: 34)

    var body: some View {
        Image(mood.imageName)
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
