//
//  TiltCard.swift
//  LCVI DECA Study App
//
//  Gives a view the weight of a physical card: it leans toward wherever you are
//  touching it, and a highlight slides across the face as it turns.
//
//  Two rotations rather than one. A single `rotation3DEffect` about a combined
//  axis turns the card around a slanted line, which reads as a wobble; stacking
//  a pitch and a yaw turns it about the two axes a hand actually uses.
//
//  The highlight is what sells it. Rotation alone reads as a picture being
//  moved, because nothing about the surface changes as it turns. A specular
//  blob tracking the touch is the cue that says the face is catching light,
//  and it costs one masked gradient.
//

import SwiftUI

struct TiltCard<Content: View>: View {
    /// What starts the lean.
    enum Activation {
        /// Leans the moment a finger lands. For a card that owns the screen.
        case touch
        /// Leans only after a short hold. Required inside a `ScrollView`: a
        /// zero-distance drag claims the touch immediately, and a list of cards
        /// that each did that would be a list you could not scroll.
        case press
    }

    /// Degrees at the very edge of the card.
    var maxAngle: Double = 14
    var activation: Activation = .touch
    /// The card's own corner radius, so the highlight is masked to its shape
    /// rather than to a rectangle behind it.
    var cornerRadius: CGFloat = 20
    /// Called when the touch was a tap rather than a drag. Without this the
    /// gesture would swallow taps — a card that cannot be dismissed by
    /// tapping the obvious thing in the middle of the screen.
    var onTap: (() -> Void)? = nil

    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Touch position relative to the centre, each axis running -1 to 1.
    @State private var lean: CGSize = .zero
    @State private var touching = false
    /// Where the highlight sits, in the card's own coordinates.
    @State private var glint: CGPoint = .zero
    /// The card's own size, measured from a background probe.
    @State private var measured: CGSize = .zero

    /// Below this a touch counts as a tap, not a drag. Loose enough to survive
    /// the few points a finger moves while pressing.
    private static var tapSlop: CGFloat { 10 }

    var body: some View {
        content()
            .overlay {
                if touching && !reduceMotion {
                    RadialGradient(colors: [.white.opacity(0.45), .clear],
                                   center: .center,
                                   startRadius: 1,
                                   endRadius: max(measured.width, measured.height) * 0.55)
                        .frame(width: measured.width * 1.4, height: measured.height * 1.4)
                        .position(glint)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            // Pitch first, then yaw. Applied the other way round the yaw would
            // turn the already-pitched card about a tilted axis, which is the
            // wobble this is avoiding.
            .rotation3DEffect(.degrees(lean.height * maxAngle),
                              axis: (x: 1, y: 0, z: 0), perspective: 0.65)
            .rotation3DEffect(.degrees(-lean.width * maxAngle),
                              axis: (x: 0, y: 1, z: 0), perspective: 0.65)
            // A card being handled comes slightly toward you.
            .scaleEffect(touching && !reduceMotion ? 1.04 : 1)
            .animation(reduceMotion ? nil : .interactiveSpring(response: 0.28,
                                                               dampingFraction: 0.7),
                       value: lean)
            .animation(reduceMotion ? nil : Motion.gentle, value: touching)
            // Measured from a background rather than by wrapping everything in
            // a GeometryReader. A GeometryReader as the root would expand to
            // whatever space it is offered, which is right for a fixed-size
            // badge and wrong for a list row that should size to its own text.
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { measured = geo.size }
                        .onChange(of: geo.size) { measured = $0 }
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .gesture(tiltGesture())
            // In press mode the sequence never fires for a quick tap, so the
            // tap needs its own recogniser. In touch mode the drag already
            // reports it and a second one would double-fire.
            .onTapGesture { if activation == .press { onTap?() } }
    }

    /// Erased to `AnyGesture` so the two activations can share one return type.
    /// `map` throws the value away for the same reason — a sequenced gesture
    /// and a drag do not otherwise agree on what they produce.
    private func tiltGesture() -> AnyGesture<Void> {
        switch activation {
        case .touch:
            // Zero minimum distance so the lean starts on contact rather than
            // after the finger has already travelled.
            return AnyGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { apply($0.location) }
                    .onEnded { value in
                        release()
                        let travelled = hypot(value.translation.width, value.translation.height)
                        if travelled < Self.tapSlop { onTap?() }
                    }
                    .map { _ in () }
            )

        case .press:
            return AnyGesture(
                LongPressGesture(minimumDuration: 0.16)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        guard case .second(true, let drag) = value else { return }
                        if let drag {
                            apply(drag.location)
                        } else if !touching {
                            // Picked up but not yet moved. The lift and the
                            // tap both land here, which is what tells a student
                            // the card is now theirs to turn.
                            touching = true
                            Haptics.tap()
                        }
                    }
                    .onEnded { _ in release() }
                    .map { _ in () }
            )
        }
    }

    private func apply(_ location: CGPoint) {
        guard !reduceMotion, measured.width > 0, measured.height > 0 else { return }
        touching = true
        glint = location
        lean = CGSize(width: clamp((location.x - measured.width / 2) / (measured.width / 2)),
                      height: clamp((location.y - measured.height / 2) / (measured.height / 2)))
    }

    private func release() {
        touching = false
        lean = .zero
    }

    /// The touch can land outside the frame once a finger slides off the edge,
    /// and an unclamped value would keep tilting past the intended limit.
    private func clamp(_ value: CGFloat) -> CGFloat {
        min(1, max(-1, value))
    }
}
