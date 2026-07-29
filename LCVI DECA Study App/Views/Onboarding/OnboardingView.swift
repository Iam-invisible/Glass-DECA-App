//
//  OnboardingView.swift
//  LCVI DECA Study App
//
//  Four acts in one scene.
//
//  The intro writes the word; this is the film that follows it. The old
//  onboarding was a settings form — it collected a cluster, a goal and a
//  reminder time and explained nothing. This one teaches the app by making
//  the student *do* it: the first act is a real question, answered with the
//  real sounds and haptics, before a single thing has been configured. Every
//  setup choice still happens, but each lives inside the act that gives it
//  meaning — and the scene itself responds, retinting to the cluster the
//  student picks.
//
//  Act I    Try it        — answer one question; feel the core loop
//  Act II   Your event    — pick a cluster; the light field takes its colour
//  Act III  Your pace     — set the daily goal around the ring from Study
//  Act IV   Your coach    — reminders, AI status, and the no-account promise
//
//  Everything the old flow collected is still collected: cluster, goal,
//  reminders + time + permission, and the AI/coach status (with the local
//  model offer on devices Apple Intelligence does not reach). Skip is always
//  present and finishes with the same defaults.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Acts

    private enum Act: Int, CaseIterable {
        case prologue, tryIt, event, pace, coach

        /// The four configurable chapters — the prologue is a title
        /// sequence, not a step, so the progress track ignores it.
        static let chapters: [Act] = [.tryIt, .event, .pace, .coach]
    }

    @State private var act: Act = .prologue
    /// +1 advancing, -1 going back — the transition travels with the story.
    @State private var direction: CGFloat = 1

    // MARK: Collected setup (identical to the old flow)

    @State private var cluster: DECACluster = .marketing
    @State private var goal = 10
    @State private var wantsReminders = false
    @State private var reminderHour = 18
    @State private var reminderMinute = 30
    @State private var permissionRequested = false
    @State private var permissionGranted = false

    // MARK: Act I state

    @State private var pickedChoice: Int? = nil

    // MARK: Prologue state

    @State private var prologueLine = 0
    @State private var prologueSequence: Task<Void, Never>?
    private static let prologueLines = [
        "You've got a competition coming.",
        "Between now and that day, one thing is yours to control.",
        "How you practice."
    ]

    var body: some View {
        ZStack {
            IntroBackdrop(opacity: 1, drift: true)

            // The scene answers Act II: once a cluster is chosen the light
            // field takes on its colour. Colour is animatable, so switching
            // clusters glides rather than snaps.
            Circle()
                .fill(cluster.tint.opacity(act.rawValue >= Act.event.rawValue ? 0.16 : 0))
                .frame(width: 340, height: 340)
                .blur(radius: 70)
                .offset(x: 90, y: -240)
                .animation(reduceMotion ? nil : Motion.gentle, value: cluster)
                .animation(reduceMotion ? nil : Motion.gentle, value: act)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 10)

                ZStack {
                    actContent
                        .id(act)
                        .transition(actTransition)
                }
                .animation(reduceMotion ? .easeOut(duration: 0.18) : Motion.page, value: act)
            }
        }
    }

    // MARK: - Chrome

    /// Four thin segments filling as the story advances, and a Skip that is
    /// never hidden — the film is skippable at every frame.
    private var topBar: some View {
        HStack(spacing: 12) {
            if act.rawValue > Act.tryIt.rawValue {
                Button {
                    Haptics.tap()
                    go(to: Act(rawValue: act.rawValue - 1) ?? .tryIt)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.cardSunken))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            HStack(spacing: 5) {
                ForEach(Act.chapters, id: \.rawValue) { a in
                    Capsule()
                        .fill(a.rawValue <= act.rawValue ? Palette.accent : Palette.cardSunken)
                        .frame(height: 3)
                        .animation(reduceMotion ? nil : Motion.snappy, value: act)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(max(act.rawValue, 1)) of \(Act.chapters.count)")

            Button("Skip") {
                Haptics.tap()
                finish()
            }
            .font(.appFootnote.weight(.medium))
            .foregroundStyle(Palette.textTertiary)
            .accessibilityHint("Starts the app with marketing, ten questions a day and no reminders")
        }
        .frame(minHeight: 36)
    }

    private var actTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func go(to next: Act) {
        direction = next.rawValue > act.rawValue ? 1 : -1
        withAnimation(reduceMotion ? .easeOut(duration: 0.18) : Motion.page) { act = next }
    }

    @ViewBuilder
    private var actContent: some View {
        switch act {
        case .prologue: prologueAct
        case .tryIt: tryItAct
        case .event: eventAct
        case .pace:  paceAct
        case .coach: coachAct
        }
    }

    // MARK: - Prologue

    /// A title sequence, not a screen: three lines arrive on the light field
    /// in authored time, earlier lines dimming as the next takes the room.
    /// A tap advances a beat; the sequence also plays itself, so a student
    /// who never taps still reaches the first question.
    private var prologueAct: some View {
        VStack {
            Spacer()

            // The picture track. Each line has a scene, drawn from the app's
            // own vocabulary — the podium, the path, the ring — swapped with
            // the line it belongs to.
            ZStack {
                if prologueLine > 0 {
                    prologueScene(for: prologueLine - 1)
                        .id(prologueLine)
                        .transition(reduceMotion ? .opacity
                                    : .opacity.combined(with: .scale(scale: 0.92)))
                }
            }
            .frame(height: 150)
            .animation(reduceMotion ? .easeOut(duration: 0.2) : Motion.gentle, value: prologueLine)

            VStack(spacing: 18) {
                ForEach(Array(Self.prologueLines.enumerated()), id: \.offset) { index, line in
                    if index < prologueLine {
                        Text(line)
                            .font(.appTitle)
                            .foregroundStyle(index == prologueLine - 1
                                             ? Palette.textPrimary : Palette.textTertiary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(reduceMotion ? .opacity
                                        : .opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .padding(.horizontal, 34)
            .animation(reduceMotion ? .easeOut(duration: 0.2) : Motion.gentle, value: prologueLine)
            Spacer()
            Text("Tap to continue")
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
                .opacity(prologueLine > 0 ? 0.8 : 0)
                .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { advancePrologue() }
        .onAppear(perform: runPrologue)
        .onDisappear { prologueSequence?.cancel() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.prologueLines.joined(separator: " "))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to continue")
    }

    private func runPrologue() {
        guard prologueSequence == nil else { return }
        prologueSequence = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            while prologueLine < Self.prologueLines.count {
                guard !Task.isCancelled else { return }
                prologueLine += 1
                // Long enough for the line's scene to play out underneath it.
                try? await Task.sleep(nanoseconds: 2_800_000_000)
            }
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            go(to: .tryIt)
        }
    }

    @ViewBuilder
    private func prologueScene(for index: Int) -> some View {
        switch index {
        case 0:  PodiumScene()
        case 1:  JourneyScene()
        default: LoopScene()
        }
    }

    private func advancePrologue() {
        Haptics.tap()
        if prologueLine >= Self.prologueLines.count {
            prologueSequence?.cancel()
            go(to: .tryIt)
        } else {
            // Jump the sequence forward; the running task keeps pacing the
            // lines that remain.
            prologueLine += 1
            if prologueLine >= Self.prologueLines.count {
                prologueSequence?.cancel()
                prologueSequence = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_600_000_000)
                    guard !Task.isCancelled else { return }
                    go(to: .tryIt)
                }
            }
        }
    }

    // MARK: - Act I · Try it

    /// The hook: the app's entire reason to exist, experienced before a
    /// single setting is touched. One real sample question with the real
    /// feedback — sound, haptic, explanation — then the manifesto line.
    private var tryItAct: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                chapter("CHAPTER I", line: "Start with one question.",
                        detail: "This is the whole app in one tap.")

                demoCard.appearBeat(1.1)

                if pickedChoice != nil {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(pickedChoice == Self.demoCorrect
                             ? "That feedback loop — answer, verdict, why — is the whole app. Practice adapts to what you miss, mock exams time you like the real thing, and roleplays coach your delivery."
                             : "No penalty here — missed questions go to your Mistake Notebook and come back until you own them. That loop is the whole app.")
                            .font(.appFootnote)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        PrimaryButton(title: "Set up my prep", systemImage: "arrow.right") {
                            go(to: .event)
                        }
                    }
                    .transition(reduceMotion ? .opacity
                                : .opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .animation(reduceMotion ? nil : Motion.gentle, value: pickedChoice)
        }
    }

    // A real seed question, hardcoded so this screen owes nothing to the
    // database. Original practice material, like everything bundled.
    private static let demoQuestion = "A sportswear brand divides its market into groups aged 13–18, 19–34, and 35+. Which segmentation base is being used?"
    private static let demoChoices = ["Psychographic", "Geographic", "Demographic", "Behavioural"]
    private static let demoCorrect = 2
    private static let demoExplanation = "Age is a demographic variable — alongside income, gender and education. Psychographic uses lifestyle and values, geographic uses location, and behavioural uses purchase patterns."

    private var demoCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 6) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.accent)
                Text("Sample · Marketing")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)
            }

            Text(Self.demoQuestion)
                .font(.appQuestion)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(Self.demoChoices.indices, id: \.self) { index in
                    demoChoice(index)
                }
            }

            if pickedChoice != nil {
                VStack(alignment: .leading, spacing: 5) {
                    Text(pickedChoice == Self.demoCorrect ? "Correct" : "Not quite — it's Demographic")
                        .font(.appHeadline)
                        .foregroundStyle(pickedChoice == Self.demoCorrect ? Palette.success : Palette.danger)
                    Text(Self.demoExplanation)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(reduceMotion ? .opacity
                            : .opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .appCard(padding: 17)
    }

    private func demoChoice(_ index: Int) -> some View {
        let answered = pickedChoice != nil
        let isCorrect = index == Self.demoCorrect
        let isPicked = index == pickedChoice

        let tint: Color = !answered ? Palette.stroke
            : isCorrect ? Palette.success
            : isPicked ? Palette.danger
            : Palette.stroke

        return Button {
            guard pickedChoice == nil else { return }
            pickedChoice = index
            if index == Self.demoCorrect {
                Haptics.success()
                SoundEffects.correct()
            } else {
                Haptics.error()
                SoundEffects.wrong()
            }
        } label: {
            HStack(spacing: 10) {
                Text(["A", "B", "C", "D"][index])
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textTertiary)
                Text(Self.demoChoices[index])
                    .font(.appCallout.weight(answered && isCorrect ? .semibold : .regular))
                    .foregroundStyle(Palette.textPrimary)
                Spacer(minLength: 0)
                if answered && (isCorrect || isPicked) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isCorrect ? Palette.success : Palette.danger)
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(answered && isCorrect ? Palette.successSoft
                          : answered && isPicked ? Palette.dangerSoft
                          : Palette.cardSunken)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(tint, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .animation(reduceMotion ? nil : Motion.snappy, value: pickedChoice)
        .accessibilityLabel(Self.demoChoices[index])
    }

    // MARK: - Act II · Your event

    private var eventAct: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                chapter("CHAPTER II", line: "Every competitor has an event.",
                        detail: "Yours decides the questions, roleplays and indicators you see first. Watch the room take its colour — and switch any time in Settings.")

                VStack(spacing: 8) {
                    ForEach(Array(DECACluster.allCases.enumerated()), id: \.element) { index, item in
                        clusterRow(item).appearBeat(0.75 + Double(index) * 0.09, distance: 12)
                    }
                }

                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    go(to: .pace)
                }
                .padding(.top, 4)
                .appearBeat(1.4)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
    }

    private func clusterRow(_ item: DECACluster) -> some View {
        let selected = cluster == item
        return Button {
            Haptics.select()
            withAnimation(reduceMotion ? nil : Motion.quick) { cluster = item }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? .white : item.tint)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(selected ? item.tint : item.tint.opacity(0.13)))
                Text(item.displayName)
                    .font(.appCallout.weight(selected ? .semibold : .regular))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(selected ? item.tint : Palette.inactive)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(selected ? item.tint.opacity(0.09) : Palette.cardSunken)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(selected ? item.tint.opacity(0.45) : Palette.stroke, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.displayName)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Act III · Your pace

    /// The goal is set around the same ring the student will see every day on
    /// Study — the onboarding teaches the app's most important gauge by
    /// letting them play with it.
    private var paceAct: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                chapter("CHAPTER III", line: "Set your pace.",
                        detail: "Small and daily beats heroic and rare. This ring is your home screen — it fills as you answer, and streaks build one day at a time.")

                VStack(spacing: 14) {
                    ZStack {
                        ProgressRing(progress: Double(min(goal, 30)) / 30.0,
                                     lineWidth: 12,
                                     tint: Palette.accent)
                            .frame(width: 120, height: 120)
                        VStack(spacing: 0) {
                            CountingNumber(value: Double(goal),
                                           font: .numeric(34),
                                           color: Palette.textPrimary)
                            Text("a day")
                                .font(.appCaption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(goal) questions a day")

                    HStack(spacing: 8) {
                        ForEach([5, 10, 20, 30], id: \.self) { value in
                            goalChip(value)
                        }
                    }

                    AppStepper(value: $goal, in: 1...100) {
                        Text("Fine-tune")
                            .font(.appCaption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                .appCard(padding: 17)
                .appearBeat(0.8)

                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    go(to: .coach)
                }
                .padding(.top, 4)
                .appearBeat(1.15)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
    }

    private func goalChip(_ value: Int) -> some View {
        let selected = goal == value
        return Button {
            Haptics.select()
            withAnimation(reduceMotion ? nil : Motion.snappy) { goal = value }
        } label: {
            Text("\(value)")
                .font(.appFootnote.weight(.semibold))
                .foregroundStyle(selected ? .white : Palette.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(selected ? Palette.accent : Palette.cardSunken)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(value) questions a day")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Act IV · Your coach

    private var coachAct: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                chapter("CHAPTER IV", line: "Your corner crew.",
                        detail: "A quiet daily nudge if you want one, and coaching that never needs a server. If you've already hit your goal, the reminder stays quiet.")

                VStack(spacing: 13) {
                    Toggle(isOn: $wantsReminders) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Remind me daily")
                                .font(.appBodyMedium)
                                .foregroundStyle(Palette.textPrimary)
                            Text(permissionRequested && !permissionGranted
                                 ? "Notifications are turned off in iOS Settings."
                                 : "You'll be asked for permission once.")
                                .font(.appCaption)
                                .foregroundStyle(permissionRequested && !permissionGranted
                                                 ? Palette.danger : Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .onChange(of: wantsReminders) { newValue in
                        guard newValue else { return }
                        Task {
                            permissionGranted = await store.notifications.requestAuthorization()
                            permissionRequested = true
                            if !permissionGranted { wantsReminders = false }
                        }
                    }

                    if wantsReminders {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What time?")
                                .font(.appCaption)
                                .foregroundStyle(Palette.textSecondary)
                            HStack(spacing: 8) {
                                timeChip(16, 0)
                                timeChip(17, 30)
                                timeChip(18, 30)
                                timeChip(20, 0)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .appCard(padding: 17)
                .animation(reduceMotion ? nil : Motion.snappy, value: wantsReminders)
                .appearBeat(0.8)

                AIStatusCard(availability: store.ai.availability)
                    .appearBeat(1.0)

                if !store.ai.availability.isUsable {
                    LocalAICoachCard(service: store.localModel)
                        .appCard()
                        .appearBeat(1.15)
                }

                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(symbol: "lock.shield",
                               title: "No account. No tracking.",
                               detail: "Every question, answer and statistic stays on this phone. The app never needs the internet.")
                }
                .appCard(padding: 15)
                .appearBeat(1.3)

                PrimaryButton(title: "Start studying", systemImage: "checkmark") {
                    Haptics.success()
                    finish()
                }
                .padding(.top, 4)
                .appearBeat(1.5)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
    }

    private func timeChip(_ hour: Int, _ minute: Int) -> some View {
        let selected = reminderHour == hour && reminderMinute == minute
        return Button {
            Haptics.select()
            withAnimation(reduceMotion ? nil : Motion.quick) {
                reminderHour = hour; reminderMinute = minute
            }
        } label: {
            Text(String(format: "%d:%02d", hour, minute))
                .font(.appFootnote.weight(.semibold))
                .foregroundStyle(selected ? .white : Palette.textPrimary)
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(selected ? Palette.accent : Palette.cardSunken)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "%d:%02d", hour, minute))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Shared act chrome

    /// A chapter head: numbered kicker, a serif line big enough to carry the
    /// screen, and its meaning underneath — centred, staged in two beats.
    private func chapter(_ numeral: String, line: String, detail: String) -> some View {
        VStack(spacing: 9) {
            Text(numeral)
                .font(.appCaptionBold)
                .tracking(1.8)
                .foregroundStyle(Palette.textTertiary)
                .appearBeat(0.15)
            Text(line)
                .font(.appTitle)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .appearBeat(0.3)
            Text(detail)
                .font(.appFootnote)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .appearBeat(0.55)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Completion

    private func finish() {
        store.settings.cluster = cluster
        store.settings.dailyGoal = goal
        store.settings.remindersEnabled = wantsReminders && permissionGranted
        store.settings.reminderHour = reminderHour
        store.settings.reminderMinute = reminderMinute
        store.settings.hasOnboarded = true
        store.refresh()
        Task { await store.syncNotifications() }
        // The guide opens right on top of the home screen the student has
        // just arrived at — after a beat, so Study's cascade lands first.
        if !store.settings.hasSeenGuide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                store.showGuide = true
            }
        }
    }
}

// MARK: - Prologue scenes

/// "You've got a competition coming." — a podium rises, gold in the middle.
private struct PodiumScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            step(height: 52, tint: Palette.accent.opacity(0.45), delay: 0.25)
            step(height: 84, tint: Palette.gold, delay: 0.05, glows: true)
            step(height: 36, tint: Palette.accent.opacity(0.3), delay: 0.45)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !reduceMotion else { up = true; return }
            withAnimation(Motion.bouncy) { up = true }
        }
        .accessibilityHidden(true)
    }

    private func step(height: CGFloat, tint: Color, delay: Double, glows: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(tint)
            .frame(width: 40, height: up ? height : 8)
            .shadow(color: glows ? Palette.gold.opacity(up ? 0.55 : 0) : .clear, radius: 10, y: 2)
            .animation(reduceMotion ? nil : Motion.bouncy.delay(delay), value: up)
    }
}

/// "Between now and that day…" — a path draws itself from here to the flag,
/// a point of light travelling its length.
private struct JourneyScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    private struct HLine: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                // Where the student is standing.
                Circle()
                    .fill(Palette.accent)
                    .frame(width: 9, height: 9)
                    .position(x: 5, y: geo.size.height / 2)

                HLine()
                    .trim(from: 0, to: drawn ? 1 : 0)
                    .stroke(
                        LinearGradient(colors: [Palette.accent, Palette.gold],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )

                // The travelling light — the same motif as the ring's tip.
                Circle()
                    .fill(.white)
                    .frame(width: 7, height: 7)
                    .shadow(color: Palette.gold.opacity(0.9), radius: 4)
                    .position(x: drawn ? w - 4 : 5, y: geo.size.height / 2)
                    .opacity(drawn ? 0 : 1)

                // Competition day.
                Image(systemName: "flag.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                    .position(x: w - 8, y: geo.size.height / 2 - 17)
                    .opacity(drawn ? 1 : 0)
                    .scaleEffect(drawn ? 1 : 0.4, anchor: .bottom)
                    .animation(reduceMotion ? nil : Motion.bouncy.delay(1.35), value: drawn)
            }
        }
        .frame(width: 230, height: 60)
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !reduceMotion else { drawn = true; return }
            withAnimation(.easeInOut(duration: 1.5).delay(0.2)) { drawn = true }
        }
        .accessibilityHidden(true)
    }
}

/// "How you practice." — the goal ring fills to full: the exact gauge the
/// student meets on the Study home an act later.
private struct LoopScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filled = false

    var body: some View {
        ZStack {
            ProgressRing(progress: filled ? 1 : 0.02,
                         lineWidth: 9,
                         tint: Palette.accent)
                .frame(width: 84, height: 84)
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Palette.success)
                .opacity(filled ? 1 : 0)
                .scaleEffect(filled ? 1 : 0.5)
                .animation(reduceMotion ? nil : Motion.bouncy.delay(1.0), value: filled)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !reduceMotion else { filled = true; return }
            // The ring runs its own spring; this just sets it in motion a
            // breath after the line lands.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { filled = true }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Pieces shared with Settings

struct FeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appCallout.weight(.medium))
                    .foregroundStyle(Palette.textPrimary)
                Text(detail)
                    .font(.appCaption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Shared by onboarding and Settings so the wording never drifts.
struct AIStatusCard: View {
    let availability: AIAvailability

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: availability.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(availability.tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(availability.title)
                    .font(.appBodyMedium)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(availability.detail)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }
}
