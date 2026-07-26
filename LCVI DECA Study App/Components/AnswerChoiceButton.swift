//
//  AnswerChoiceButton.swift
//  LCVI DECA Study App
//
//  The single most-used control in the app: a large, high-contrast answer row
//  with distinct neutral / selected / correct / wrong states.
//

import SwiftUI

enum AnswerChoiceState: Equatable {
    case neutral
    case selected
    case correct
    case wrong
    case dimmed
}

struct AnswerChoiceButton: View {
    let letter: String
    let text: String
    let state: AnswerChoiceState
    var isLocked: Bool = false
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var checkScale: CGFloat = 0.4
    @State private var shake: CGFloat = 0

    private var foreground: Color {
        switch state {
        case .correct: return Palette.success
        case .wrong:   return Palette.danger
        case .selected: return Palette.accent
        case .dimmed:  return Palette.textTertiary
        case .neutral: return Palette.textPrimary
        }
    }

    private var fill: Color {
        switch state {
        case .correct: return Palette.successSoft
        case .wrong:   return Palette.dangerSoft
        case .selected: return Palette.accentSoft
        case .dimmed, .neutral: return Palette.card
        }
    }

    private var border: Color {
        switch state {
        case .correct:  return Palette.success
        case .wrong:    return Palette.danger
        case .selected: return Palette.accent
        case .dimmed:   return Palette.stroke
        case .neutral:  return Palette.stroke
        }
    }

    private var borderWidth: CGFloat {
        switch state {
        case .neutral, .dimmed: return 1
        default: return 2
        }
    }

    private var trailingSymbol: String? {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .wrong:   return "xmark.circle.fill"
        default:       return nil
        }
    }

    var body: some View {
        Button(action: {
            guard !isLocked else { return }
            action()
        }) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(state == .neutral || state == .dimmed
                              ? Palette.cardSunken
                              : foreground.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Text(letter)
                        .font(.appSans(14, weight: .bold))
                        .foregroundStyle(state == .neutral || state == .dimmed
                                         ? Palette.textSecondary : foreground)
                }

                Text(text)
                    .font(.appCallout)
                    .foregroundStyle(state == .dimmed ? Palette.textSecondary : Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let trailingSymbol {
                    Image(systemName: trailingSymbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(foreground)
                        .scaleEffect(checkScale)
                        .onAppear {
                            if reduceMotion {
                                checkScale = 1
                            } else {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.55)) {
                                    checkScale = 1
                                }
                            }
                        }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: borderWidth)
            )
            .opacity(state == .dimmed ? 0.62 : 1)
            .offset(x: shake)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.985, haptic: false))
        .disabled(isLocked)
        .onChange(of: state) { newValue in
            guard newValue == .wrong, !reduceMotion else { return }
            withAnimation(.spring(response: 0.16, dampingFraction: 0.3)) { shake = -7 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.4)) { shake = 0 }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Option \(letter). \(text)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(state == .selected ? [.isSelected, .isButton] : .isButton)
    }

    private var accessibilityValue: String {
        switch state {
        case .correct:  return "Correct answer"
        case .wrong:    return "Your answer, incorrect"
        case .selected: return "Selected"
        default:        return ""
        }
    }
}

// MARK: - Feedback banner

struct AnimatedFeedbackBanner: View {
    let isCorrect: Bool
    var title: String? = nil
    var message: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tint: Color { isCorrect ? Palette.success : Palette.danger }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isCorrect ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title ?? (isCorrect ? "Correct" : "Not quite"))
                    .font(.appBodyMedium)
                    .foregroundStyle(Palette.textPrimary)
                if let message {
                    Text(message)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(isCorrect ? Palette.successSoft : Palette.dangerSoft)
        )
        .transition(reduceMotion
                    ? .opacity
                    : .asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                  removal: .opacity))
        .accessibilityElement(children: .combine)
    }
}
