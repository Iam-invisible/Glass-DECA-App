//
//  TimerControl.swift
//  LCVI DECA Study App
//
//  DECA-style preparation and presentation timers.
//

import Combine
import SwiftUI

@MainActor
final class CountdownTimer: ObservableObject {
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning = false
    @Published private(set) var isFinished = false

    private(set) var total: TimeInterval
    private var ticker: AnyCancellable?
    private var firedMarks: Set<Int> = []

    /// Seconds at which a haptic warning fires.
    var warningMarks: [Int] = [60, 30, 10]

    var onFinish: (() -> Void)?

    init(minutes: Int) {
        self.total = TimeInterval(minutes * 60)
        self.remaining = TimeInterval(minutes * 60)
    }

    var progress: Double {
        total <= 0 ? 0 : max(0, min(1, remaining / total))
    }

    var isCritical: Bool { remaining <= 30 && remaining > 0 }
    var isWarning: Bool { remaining <= 60 && remaining > 30 }

    var display: String {
        let clamped = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", clamped / 60, clamped % 60)
    }

    var elapsed: TimeInterval { max(0, total - remaining) }

    func setMinutes(_ minutes: Int) {
        stop()
        total = TimeInterval(minutes * 60)
        remaining = total
        isFinished = false
        firedMarks.removeAll()
    }

    func start() {
        guard !isRunning, remaining > 0 else { return }
        isRunning = true
        isFinished = false
        Haptics.tap()
        ticker = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        guard isRunning else { return }
        Haptics.tap()
        stop()
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func reset() {
        stop()
        remaining = total
        isFinished = false
        firedMarks.removeAll()
        Haptics.select()
    }

    private func stop() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
    }

    private func tick() {
        remaining = max(0, remaining - 0.1)
        let whole = Int(remaining.rounded())

        if warningMarks.contains(whole), !firedMarks.contains(whole) {
            firedMarks.insert(whole)
            Haptics.warning()
        }

        if remaining <= 0 {
            stop()
            isFinished = true
            Haptics.sessionComplete()
            onFinish?()
        }
    }

    deinit {
        ticker?.cancel()
    }
}

struct TimerControl: View {
    @ObservedObject var timer: CountdownTimer
    var title: String
    var tint: Color = Palette.accent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activeTint: Color {
        if timer.isFinished { return Palette.danger }
        if timer.isCritical { return Palette.danger }
        if timer.isWarning { return Palette.gold }
        return tint
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title.uppercased())
                .font(.appCaptionBold)
                .tracking(0.8)
                .foregroundStyle(Palette.textSecondary)

            ZStack {
                ProgressRing(progress: timer.progress,
                             lineWidth: 10,
                             tint: activeTint,
                             animated: false)
                    .frame(width: 150, height: 150)

                VStack(spacing: 2) {
                    Text(timer.display)
                        .font(.numeric(40))
                        .foregroundStyle(timer.isFinished ? Palette.danger : Palette.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.identity)
                    Text(timer.isFinished ? "Time" : (timer.isRunning ? "Running" : "Paused"))
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .scaleEffect(timer.isCritical && timer.isRunning && !reduceMotion ? 1.02 : 1)
            .animation(timer.isCritical && !reduceMotion
                       ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                       : .default,
                       value: timer.isCritical && timer.isRunning)

            HStack(spacing: 10) {
                Button {
                    timer.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        Text(timer.isRunning ? "Pause" : (timer.remaining < timer.total ? "Resume" : "Start"))
                    }
                    .font(.appCallout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(timer.isRunning ? Palette.gold : activeTint)
                    )
                }
                .buttonStyle(PressableButtonStyle(haptic: false))
                .disabled(timer.remaining <= 0)
                .opacity(timer.remaining <= 0 ? 0.45 : 1)

                Button {
                    timer.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 52, height: 46)
                        .foregroundStyle(Palette.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Palette.cardSunken)
                        )
                }
                .buttonStyle(PressableButtonStyle(haptic: false))
                .accessibilityLabel("Reset timer")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) timer")
        .accessibilityValue("\(timer.display) remaining")
    }
}

/// A compact elapsed-time / countdown label for exam headers.
struct TimerPill: View {
    let text: String
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.appCaptionBold)
                .monospacedDigit()
        }
        .foregroundStyle(isWarning ? Palette.danger : Palette.textSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(isWarning ? Palette.dangerSoft : Palette.cardSunken))
        .accessibilityLabel("Time remaining \(text)")
    }
}
