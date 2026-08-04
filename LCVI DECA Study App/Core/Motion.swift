//
//  Motion.swift
//  LCVI DECA Study App
//
//  Shared animation curves plus Reduce Motion helpers.
//

import SwiftUI

enum Motion {
    static let snappy = Animation.spring(response: 0.34, dampingFraction: 0.78)
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.85)
    static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.6)
    static let quick  = Animation.easeOut(duration: 0.18)
    static let reveal = Animation.spring(response: 0.45, dampingFraction: 0.82)
    /// Tab changes. Deliberately damped — a bouncy page swap reads as cheap,
    /// and this fires dozens of times a session.
    static let page = Animation.spring(response: 0.38, dampingFraction: 0.88)

    /// Returns `nil` (i.e. no animation) when Reduce Motion is on.
    static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

/// Fades + slides content in with a stagger index, honouring Reduce Motion.
struct AppearTransition: ViewModifier {
    let index: Int
    var distance: CGFloat = 14
    /// An authored delay in seconds. When set it replaces the index stagger —
    /// this is what turns a list entrance into a story beat.
    var delay: Double? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : distance)
            // A breath of scale under the rise reads as settling *forward*
            // into the light rather than sliding on a flat plane.
            .scaleEffect(shown || reduceMotion ? 1 : 0.985)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(Motion.gentle.delay(delay ?? Double(index) * 0.055)) {
                        shown = true
                    }
                }
            }
    }
}

extension View {
    /// Gentle staggered entrance used by dashboard/section cards.
    func appearIn(_ index: Int, distance: CGFloat = 14) -> some View {
        modifier(AppearTransition(index: index, distance: distance))
    }

    /// A story beat: appears after an authored number of seconds, with a
    /// slightly longer rise than a list stagger. For choreographed scenes —
    /// onboarding chapters — where the timing is the point.
    func appearBeat(_ seconds: Double, distance: CGFloat = 18) -> some View {
        modifier(AppearTransition(index: 0, distance: distance, delay: seconds))
    }

    /// A band of light crossing the view over and over, for work that is
    /// running with no progress to report.
    ///
    /// A spinner says "busy". This says "busy *on this*", because the light
    /// travels across the thing being worked on — which is the whole reason it
    /// exists on a local model's answer, where the wait is long enough that a
    /// student starts wondering whether they actually tapped anything.
    func shimmering(_ active: Bool,
                    period: Double = 1.5,
                    pause: Double = 0.55) -> some View {
        modifier(Shimmer(active: active, period: period, pause: pause))
    }
}

/// A repeating shine, masked to whatever it is applied to.
///
/// The band is masked by the content rather than drawn over it, so it lights
/// the glyphs themselves and never washes the space between them. That mask is
/// also what keeps the sweep from parking beside the view as a stray rectangle
/// once it travels past the edge (§8.14) — no outer `clipped()` is needed, and
/// adding one would silently crop any caller whose content overflows on
/// purpose.
struct Shimmer: ViewModifier {
    let active: Bool
    let period: Double
    /// Dead time between passes. Without it the band is continuous, which
    /// reads as a loading skeleton — a thing that is missing — rather than as
    /// attention moving across a thing that is present.
    let pause: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay {
            if active && !reduceMotion {
                GeometryReader { geo in
                    LinearGradient(colors: [.clear,
                                            .white.opacity(0.75),
                                            .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.45)
                        .offset(x: phase * geo.size.width)
                        .blur(radius: 3)
                }
                // The mask goes on the full-size container, never on the band:
                // masking a view already narrowed by `.frame` makes the mask
                // lay itself out inside that narrow box.
                .mask(content)
                .allowsHitTesting(false)
                .task(id: active) {
                    while !Task.isCancelled {
                        phase = -1
                        withAnimation(.easeInOut(duration: period)) { phase = 1.1 }
                        try? await Task.sleep(nanoseconds:
                            UInt64((period + pause) * 1_000_000_000))
                    }
                }
            }
        }
    }
}

/// A number that animates from its previous value to the new one.
struct CountingNumber: View, Animatable {
    var value: Double
    var format: (Double) -> String
    var font: Font
    var color: Color

    init(value: Double,
         font: Font = .numeric(34),
         color: Color = Palette.textPrimary,
         format: @escaping (Double) -> String = { String(Int($0.rounded())) }) {
        self.value = value
        self.font = font
        self.color = color
        self.format = format
    }

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(format(value))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
    }
}

// MARK: - Page transition

/// One frame of the tab-change motion: the page tips and recedes in depth
/// while it travels sideways.
struct PageShift: ViewModifier {
    var offset: CGFloat
    var scale: CGFloat
    var angle: Double
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotation3DEffect(.degrees(angle),
                              axis: (x: 0, y: 1, z: 0),
                              anchor: .center,
                              perspective: 0.55)
            .offset(x: offset)
            .opacity(opacity)
    }
}

extension AnyTransition {
    /// A directional depth-card swap.
    ///
    /// The incoming page swings in from the side you're travelling toward while
    /// the outgoing one recedes the opposite way, so moving right along the tab
    /// bar always moves the content left. That spatial consistency is what makes
    /// it read as navigation rather than decoration.
    ///
    /// - Parameter direction: `1` when moving to a tab on the right, `-1` left.
    static func page(direction: CGFloat) -> AnyTransition {
        let travel: CGFloat = 68
        let tip: Double = 12

        return .asymmetric(
            insertion: .modifier(
                active: PageShift(offset: travel * direction,
                                  scale: 0.93,
                                  angle: -tip * Double(direction),
                                  opacity: 0),
                identity: PageShift(offset: 0, scale: 1, angle: 0, opacity: 1)
            ),
            removal: .modifier(
                active: PageShift(offset: -travel * direction,
                                  scale: 0.93,
                                  angle: tip * Double(direction),
                                  opacity: 0),
                identity: PageShift(offset: 0, scale: 1, angle: 0, opacity: 1)
            )
        )
    }
}
