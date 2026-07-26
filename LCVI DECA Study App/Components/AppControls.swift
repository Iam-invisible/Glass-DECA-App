//
//  AppControls.swift
//  LCVI DECA Study App
//
//  Replacements for the system controls whose appearance Apple changed
//  between iOS 16 and iOS 26.
//
//  Why these exist
//  ---------------
//  The app supports iOS 16 (iPhone 8 tops out at 16.7) and also runs on
//  iOS 26. In between, Apple redrew every inline control: segmented pickers
//  became tall glass capsules, switches changed geometry and knob shading,
//  steppers were split into separate glass buttons. Those controls are drawn
//  by the OS, so the same code produced two visibly different apps.
//
//  Raising the deployment target cannot fix that — the disagreement comes
//  from the *newest* OS, so the only floor that yields one look is a floor of
//  26, which would exclude every device this app is actually for. The fix is
//  to draw the controls ourselves, which is already the pattern the floating
//  tab bar in `RootView` uses.
//
//  What is deliberately NOT here
//  -----------------------------
//  Alerts, confirmation dialogs, sheets, the share sheet and the file
//  importer stay native. They are OS modals: users read them as correct on
//  whichever OS they are on, and reimplementing them would cost focus
//  handling, hardware keyboard support and VoiceOver behaviour for no visual
//  gain. The same goes for the popup half of a menu picker — only its inline
//  label is drawn here.
//
//  Accessibility is ours now
//  -------------------------
//  A custom control inherits none of UIKit's semantics, so every one of these
//  sets its own traits, labels and values, keeps a 44pt hit target, honours
//  Reduce Motion, and sizes with Dynamic Type rather than in fixed points.
//

import SwiftUI

// MARK: - Toggle

/// The app's switch. Applied once at the root, so every `Toggle` in the app
/// picks it up through the environment rather than needing 17 call sites
/// changed — and so a new `Toggle` written later can't accidentally be a
/// system one.
struct AppToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric(relativeTo: .body) private var trackWidth: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = 30

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
            track(configuration)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            withAnimation(reduceMotion ? nil : Motion.snappy) {
                configuration.isOn.toggle()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityAction {
            configuration.isOn.toggle()
        }
    }

    private func track(_ configuration: Configuration) -> some View {
        let knob = trackHeight - 4
        return ZStack(alignment: configuration.isOn ? .trailing : .leading) {
            Capsule(style: .continuous)
                .fill(configuration.isOn ? Palette.accent : Palette.inactive.opacity(0.45))
            Capsule(style: .continuous)
                .strokeBorder(Palette.shadow.opacity(0.06), lineWidth: 1)
            Circle()
                .fill(.white)
                .frame(width: knob, height: knob)
                .shadow(color: Palette.shadow.opacity(0.22), radius: 2, y: 1)
                .padding(2)
        }
        .frame(width: trackWidth, height: trackHeight)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

extension ToggleStyle where Self == AppToggleStyle {
    static var app: AppToggleStyle { AppToggleStyle() }
}

// MARK: - Segmented picker

/// The app's segmented control.
///
/// `PickerStyle` is not a protocol third parties can implement, so unlike the
/// toggle this cannot be applied through the environment — the call sites have
/// to use it directly.
struct AppSegmentedPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var namespace
    @ScaledMetric(relativeTo: .callout) private var height: CGFloat = 36

    init(_ title: String,
         selection: Binding<Value>,
         options: [Value],
         label: @escaping (Value) -> String) {
        self.title = title
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    guard !isSelected else { return }
                    Haptics.select()
                    withAnimation(reduceMotion ? nil : Motion.snappy) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.appFootnote)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Palette.textPrimary : Palette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .frame(height: height - 6)
                        .background {
                            if isSelected {
                                // One capsule shared across the options, so it
                                // travels to the new selection instead of
                                // cross-fading in place.
                                Capsule(style: .continuous)
                                    .fill(Palette.card)
                                    .shadow(color: Palette.shadow.opacity(0.10), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                            }
                        }
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(option))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .frame(height: height)
        .background(
            Capsule(style: .continuous).fill(Palette.cardSunken)
        )
        .overlay(
            Capsule(style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

extension AppSegmentedPicker where Value: CaseIterable & Hashable, Value.AllCases == [Value] {
    init(_ title: String, selection: Binding<Value>, label: @escaping (Value) -> String) {
        self.init(title, selection: selection, options: Array(Value.allCases), label: label)
    }
}

// MARK: - Menu picker

/// A dropdown whose *inline* row we draw and whose popup stays native.
struct AppMenuPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    init(_ title: String,
         selection: Binding<Value>,
         options: [Value],
         label: @escaping (Value) -> String) {
        self.title = title
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        Menu {
            // The popup is system chrome, like an alert — left alone on purpose.
            ForEach(options, id: \.self) { option in
                Button {
                    Haptics.select()
                    selection = option
                } label: {
                    if option == selection {
                        Label(label(option), systemImage: "checkmark")
                    } else {
                        Text(label(option))
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(label(selection))
                    .font(.appCallout)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(.horizontal, 13)
            .frame(minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(Palette.cardSunken)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .accessibilityLabel(title)
        .accessibilityValue(label(selection))
    }
}

// MARK: - Stepper

/// The app's stepper. Holding a button repeats, which is the one behaviour
/// people miss most when a system stepper is replaced.
struct AppStepper<Label: View>: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    @ViewBuilder var label: () -> Label

    @Environment(\.isEnabled) private var isEnabled
    @State private var repeater: Task<Void, Never>?

    init(value: Binding<Int>,
         in range: ClosedRange<Int>,
         step: Int = 1,
         @ViewBuilder label: @escaping () -> Label) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
    }

    var body: some View {
        HStack(spacing: 12) {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                button(systemImage: "minus", delta: -step, enabled: value > range.lowerBound)
                Rectangle()
                    .fill(Palette.stroke)
                    .frame(width: 1, height: 20)
                button(systemImage: "plus", delta: step, enabled: value < range.upperBound)
            }
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(Palette.cardSunken)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: bump(step)
            case .decrement: bump(-step)
            @unknown default: break
            }
        }
    }

    private func button(systemImage: String, delta: Int, enabled: Bool) -> some View {
        Button {
            bump(delta)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(enabled ? Palette.accent : Palette.inactive)
                // 44pt of touch target without 44pt of visible chrome.
                .frame(width: 44, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled || !isEnabled)
        .accessibilityHidden(true)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in startRepeating(delta) }
        )
        .onDisappear { stopRepeating() }
        // Any touch ending anywhere stops the repeat.
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in stopRepeating() }
        )
    }

    private func bump(_ delta: Int) {
        let next = min(max(value + delta, range.lowerBound), range.upperBound)
        guard next != value else { return }
        Haptics.select()
        value = next
    }

    private func startRepeating(_ delta: Int) {
        stopRepeating()
        repeater = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 90_000_000)
                if Task.isCancelled { return }
                let next = min(max(value + delta, range.lowerBound), range.upperBound)
                if next == value { return }
                value = next
            }
        }
    }

    private func stopRepeating() {
        repeater?.cancel()
        repeater = nil
    }
}

extension AppStepper where Label == EmptyView {
    init(value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1) {
        self.init(value: value, in: range, step: step) { EmptyView() }
    }
}
