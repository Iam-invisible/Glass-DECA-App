//
//  CoreComponents.swift
//  LCVI DECA Study App
//
//  Reusable building blocks: rings, buttons, cards, headers and empty states.
//

import SwiftUI

// MARK: - Progress ring

struct ProgressRing: View {
    var progress: Double            // 0...1
    var lineWidth: CGFloat = 12
    var tint: Color = Palette.accent
    var track: Color = Palette.cardSunken
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Double = 0

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: shown)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [tint.opacity(0.75), tint]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // The tip of the arc is a point of light. It rides the same
            // animated state as the trim, so the spring carries both, and it
            // glows just enough to read as the lit end of a glass tube.
            //
            // Radius is min/2, not (min - lineWidth)/2: the arc is drawn with
            // .stroke, which centres the line on the circle's path, so the
            // stroke centreline sits at min/2. The border-inset radius put
            // the dot 5.5pt inside the arc — a stray dot beside the tube
            // instead of the highlight nested in its rounded cap.
            if shown > 0.01 {
                GeometryReader { geo in
                    let r = min(geo.size.width, geo.size.height) / 2
                    Circle()
                        .fill(.white)
                        .frame(width: lineWidth * 0.42, height: lineWidth * 0.42)
                        .shadow(color: tint.opacity(0.9), radius: 3)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2 - r)
                        .rotationEffect(.degrees(360 * shown))
                }
            }
        }
        .onAppear { animate(to: clamped) }
        .onChange(of: clamped) { animate(to: $0) }
        .accessibilityHidden(true)
    }

    private func animate(to value: Double) {
        guard animated, !reduceMotion else { shown = value; return }
        withAnimation(.spring(response: 0.85, dampingFraction: 0.85)) { shown = value }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appSectionTitle)
                    .foregroundStyle(Palette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(actionTitle) {
                    Haptics.tap()
                    action()
                }
                .font(.appFootnote.weight(.semibold))
                .foregroundStyle(Palette.accent)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = Palette.accent
    var isProminent: Bool = true
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.appBodyMedium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(isProminent ? Color.white : tint)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(isProminent ? tint : tint.opacity(0.12))
            )
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 15, weight: .semibold))
                }
                Text(title).font(.appCallout.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .foregroundStyle(Palette.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
    }
}

/// A large tappable row used for menus and lists of practice modes.
struct NavigationRowCard: View {
    let title: String
    let subtitle: String
    var systemImage: String
    var tint: Color = Palette.accent
    var badge: String? = nil
    var badgeTint: Color = Palette.accent
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.appBodyMedium)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if let badge {
                    Text(badge)
                        .font(.appCaptionBold)
                        .foregroundStyle(badgeTint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(badgeTint.opacity(0.14)))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .frame(minHeight: Metrics.rowMinHeight)
            .appCard()
        }
        .buttonStyle(PressableButtonStyle(haptic: false))
        .accessibilityElement(children: .combine)
        .accessibilityHint(subtitle)
    }
}

// MARK: - Stat card

struct StatCard: View {
    let title: String
    let value: String
    var caption: String? = nil
    var systemImage: String? = nil
    var tint: Color = Palette.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Text(value)
                .font(.numeric(24))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let caption {
                Text(caption)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.textTertiary)
            Text(title)
                .font(.appHeadline)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.appCallout)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, 4)
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Indicator bar

struct PerformanceIndicatorBar: View {
    let code: String
    let text: String
    let value: Double         // 0...1
    var detail: String? = nil
    var tint: Color? = nil

    private var barColor: Color { tint ?? MasteryBand.from(score: value).color }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(code)
                    .font(.appCaptionBold)
                    .foregroundStyle(barColor)
                Text(text)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Text("\(Int(value * 100))%")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.cardSunken)
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(4, geo.size.width * min(max(value, 0), 1)))
                }
            }
            .frame(height: 7)
            if let detail {
                Text(detail)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(code), \(text)")
        .accessibilityValue("\(Int(value * 100)) percent mastery")
    }
}

// MARK: - Horizontal accuracy bar

struct LabeledBar: View {
    let label: String
    let value: Double
    var caption: String? = nil
    var tint: Color = Palette.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.appFootnote.weight(.medium))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(caption ?? "\(Int(value * 100))%")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.cardSunken)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(4, geo.size.width * min(max(value, 0), 1)))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(caption ?? "\(Int(value * 100)) percent")
    }
}

// MARK: - Info banner

struct InfoBanner: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var tint: Color = Palette.accent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.appFootnote.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                if let message {
                    Text(message)
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.10))
        )
        .accessibilityElement(children: .combine)
    }
}
