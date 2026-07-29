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
                    withAnimation(Motion.gentle.delay(Double(index) * 0.055)) {
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
