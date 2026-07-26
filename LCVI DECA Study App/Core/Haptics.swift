//
//  Haptics.swift
//  LCVI DECA Study App
//
//  Central haptic vocabulary. UIKit generators are used so the app works
//  identically on iOS 16 (iPhone 8) and on current devices.
//

import UIKit
import SwiftUI

@MainActor
enum Haptics {
    /// Toggled from Settings; persisted alongside the rest of user settings.
    static var enabled: Bool = true

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notice = UINotificationFeedbackGenerator()

    static func prepare() {
        guard enabled else { return }
        light.prepare()
        medium.prepare()
        selection.prepare()
        notice.prepare()
    }

    /// Light tap — selecting an answer, tapping a row.
    static func tap() {
        guard enabled else { return }
        light.impactOccurred(intensity: 0.7)
    }

    /// Direct impact control, used to score animation beats such as a badge
    /// landing and bouncing.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle,
                       intensity: CGFloat = 1.0) {
        guard enabled else { return }
        switch style {
        case .light, .soft:  light.impactOccurred(intensity: intensity)
        case .heavy, .rigid: heavy.impactOccurred(intensity: intensity)
        default:             medium.impactOccurred(intensity: intensity)
        }
    }

    static func select() {
        guard enabled else { return }
        selection.selectionChanged()
    }

    /// Correct answer / achievement unlocked.
    static func success() {
        guard enabled else { return }
        notice.notificationOccurred(.success)
    }

    /// Wrong answer.
    static func error() {
        guard enabled else { return }
        notice.notificationOccurred(.error)
    }

    static func warning() {
        guard enabled else { return }
        notice.notificationOccurred(.warning)
    }

    /// Finishing a session.
    static func sessionComplete() {
        guard enabled else { return }
        medium.impactOccurred()
    }

    /// Daily goal reached — a short rising pattern.
    static func celebrate() {
        guard enabled else { return }
        notice.notificationOccurred(.success)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 130_000_000)
            guard enabled else { return }
            medium.impactOccurred(intensity: 0.8)
            try? await Task.sleep(nanoseconds: 110_000_000)
            guard enabled else { return }
            heavy.impactOccurred(intensity: 1.0)
        }
    }

    /// Stronger celebration — streak freeze earned.
    static func bigCelebrate() {
        guard enabled else { return }
        Task { @MainActor in
            for i in 0..<3 {
                guard enabled else { return }
                heavy.impactOccurred(intensity: 0.6 + Double(i) * 0.2)
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
            guard enabled else { return }
            notice.notificationOccurred(.success)
        }
    }
}

/// Button style that pairs a spring press animation with a light haptic.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var haptic: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? scale : 1))
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed && haptic { Haptics.tap() }
            }
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
