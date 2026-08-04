//
//  TodayPanel.swift
//  LCVI DECA Study App
//
//  The day — both goals and the streak — as one object.
//
//  They used to be two separate dials sitting side by side, each with its own
//  ring and its own full-width button. Once the cards came off, that read as
//  two unrelated widgets that happened to be adjacent: two big empty rings
//  competing for the eye and two heavy buttons competing for the thumb, with
//  nothing saying they were the same thought.
//
//  One object fixes the relationship rather than the styling. The day is one
//  segmented track, and both goals are obviously parts of it.
//
//  That track was a 176pt ring inside a 244pt bloom, and it is now a bar. The
//  ring's argument was never its size — it was that one object means one day,
//  and a segment per item says what a single question is worth, which a smooth
//  arc cannot. A bar keeps both and costs about 150pt against 243pt, on a
//  screen where an iPhone 8 shows roughly 500pt above the fold. What went is
//  the empty middle the figure used to sit in, not the figure.
//
//  The figure answers the question a student actually has, which is "what is
//  left", not "what have I done". Done-versus-goal is already on the cards
//  below, so repeating it here would spend the most prominent line on the
//  screen saying something twice.
//
//  The streak sits inside this panel rather than under it. Left outside it was
//  a bare line in a different visual language directly beneath a composed
//  panel, which read as something that had fallen off. It is the third fact
//  about today, so it belongs in the thing that states today.
//
//  The two goal rows carry the app's card treatment — opaque fill, gradient
//  border, shape shadow — tinted rather than plain. They used to be a flat
//  wash of tint with no edge, which is not a surface the rest of the app uses
//  anywhere: everything else that groups content has a border catching the
//  light field. They read as untreated rather than as deliberately quiet.
//
//  The streak is the one card here that is not a control and not about today,
//  so it stops borrowing the goal rows' vocabulary and gets its own: the wider
//  card radius, a gold gradient rather than a flat tint, a bloom behind the
//  flame, the count set as a figure instead of a sentence, and a ten-segment
//  track for the freeze it is working toward. That last one is the reason the
//  card earns its extra height — "3 days to your next freeze" is a sentence
//  you have to read, and seven of ten lit is a fact you can see.
//

import SwiftUI

struct TodayPanel: View {
    let questionsDone: Int
    let questionsGoal: Int
    let quickThinkDone: Int
    let quickThinkGoal: Int
    /// False for events with no roleplay component — then the day is one run
    /// of segments and one card, not a hollowed-out version of the pair.
    let showsQuickThink: Bool
    let streak: Int
    let freezes: Int
    let daysUntilNextFreeze: Int
    /// Non-nil when a streak the student just earned is waiting to be shown.
    /// Study only passes it through once nothing is covering the screen.
    var pendingCelebration: Int? = nil
    var onCelebrated: () -> Void = {}
    let onQuestions: () -> Void
    let onQuickThink: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Drives the collect animation.
    ///
    /// Two values rather than one, because they have to end differently. The
    /// flame and the border swell and settle back, so they animate in both
    /// directions. The ripple only ever travels outwards — running one value
    /// back down to zero would have played it in reverse, contracting and
    /// brightening, so it is torn down instead of animated home.
    @State private var collectPhase: Double = 0
    @State private var ripplePhase: Double = 0
    @State private var showsRipple = false
    @State private var isCollecting = false

    private var questionsMet: Bool { questionsDone >= max(1, questionsGoal) }
    private var quickThinkMet: Bool { quickThinkDone >= max(1, quickThinkGoal) }
    private var allMet: Bool { questionsMet && (!showsQuickThink || quickThinkMet) }

    var body: some View {
        // The day leads and everything else reads as support beneath it. The
        // gap is part of what makes it lead: isolation is most of what the
        // ring's 244pt of bloom was buying, and at a tighter gap the first
        // card crowds the figure closely enough to read as a peer of it
        // rather than as support.
        VStack(spacing: 26) {
            dayBar
            goals
            streakCard
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
        .onChange(of: pendingCelebration) { new in
            if new != nil { collect() }
        }
        .onAppear {
            // Covers the cold case: the app was killed between earning the
            // streak and coming back to look at it.
            if pendingCelebration != nil { collect() }
        }
    }

    /// Plays the collect animation once, then hands the pending value back so
    /// it cannot fire twice for the same streak.
    private func collect() {
        guard !isCollecting else { return }
        isCollecting = true

        guard !reduceMotion else {
            // Nothing to watch, so nothing to wait for.
            isCollecting = false
            onCelebrated()
            return
        }

        collectPhase = 0
        ripplePhase = 0
        showsRipple = true

        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
            collectPhase = 1
        }
        withAnimation(.easeOut(duration: 0.9)) {
            ripplePhase = 1
        }

        // The ripple is fully transparent by the time it is pulled, so this
        // removes nothing the eye can see.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            showsRipple = false
            ripplePhase = 0
        }
        // Clearing the pending value is what ends the animation, so it has to
        // outlast every part of it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(Motion.gentle) { collectPhase = 0 }
            isCollecting = false
            onCelebrated()
        }
    }

    private var goals: some View {
        Group {
            VStack(spacing: 10) {
                goalRow(title: "Questions",
                        symbol: "list.bullet",
                        tint: Palette.accent,
                        done: questionsDone,
                        goal: questionsGoal,
                        met: questionsMet,
                        action: onQuestions)

                if showsQuickThink {
                    goalRow(title: "Quick Think",
                            symbol: "brain.head.profile",
                            tint: Palette.gold,
                            done: quickThinkDone,
                            goal: quickThinkGoal,
                            met: quickThinkMet,
                            action: onQuickThink)
                }
            }
        }
    }

    // MARK: Streak

    /// Its own object, not a third goal row. It is deliberately not a button:
    /// nothing here starts anything, and the wider radius against the two
    /// control-radius rows above is what says so without an affordance that
    /// lies.
    private var streakCard: some View {
        VStack(spacing: 11) {
            HStack(spacing: 12) {
                flame

                VStack(alignment: .leading, spacing: -2) {
                    // A figure rather than a sentence. The number is the whole
                    // point of the card and it was previously set at body
                    // weight in the middle of a line of prose.
                    CountingNumber(value: Double(streak),
                                   font: .numeric(30),
                                   color: streak > 0 ? Palette.gold : Palette.textTertiary)
                    Text("day streak")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textSecondary)
                }

                Spacer(minLength: 8)

                freezeCapsule
            }

            freezeTrack
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(streakSurface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streak) day streak, \(freezes) of \(StreakRules.maxFreezes) freezes")
        .accessibilityValue(streakDetail)
    }

    /// The flame, with a bloom behind it and a ripple that leaves the card on
    /// collect. The bloom is the same recipe as the ring's wash — a blurred
    /// static circle — so it costs one cached pass rather than a live blur.
    private var flame: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Palette.gold.opacity(0.34), .clear],
                                     center: .center, startRadius: 1, endRadius: 30))
                .frame(width: 66, height: 66)
                .blur(radius: 6)
                .opacity(streak > 0 ? 1 : 0.35)
                .scaleEffect(1 + collectPhase * 0.4)

            // The ripple: a ring that expands past the glyph and fades as it
            // goes. Drawn only while collecting, so the home screen is not
            // carrying a permanently animating layer.
            if showsRipple {
                Circle()
                    .strokeBorder(Palette.gold.opacity(0.55 * (1 - ripplePhase)), lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(1 + ripplePhase * 1.6)
            }

            Circle()
                .fill(Palette.gold.opacity(streak > 0 ? 0.18 : 0.10))
                .frame(width: 40, height: 40)

            Image(systemName: "flame.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(streak > 0 ? Palette.gold : Palette.textTertiary)
                // Overshoots and settles. The spring in `collect()` is what
                // makes this a pop rather than a swell.
                .scaleEffect(1 + collectPhase * 0.35)
                .rotationEffect(.degrees(collectPhase * 8))
        }
        .frame(width: 44, height: 44)
    }

    private var freezeCapsule: some View {
        HStack(spacing: 3) {
            Image(systemName: "snowflake")
                .font(.system(size: 11, weight: .bold))
            Text("\(freezes)/\(StreakRules.maxFreezes)")
                .font(.appCaptionBold)
                .monospacedDigit()
        }
        .foregroundStyle(freezes > 0 ? Palette.gold : Palette.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(freezes > 0 ? Palette.goldSoft : Palette.cardSunken))
    }

    /// Ten segments, one per day between earned freezes. Lit segments are the
    /// days already banked. At the freeze cap there is nothing being worked
    /// toward, so the track states that instead of filling a bar that means
    /// nothing.
    private var freezeTrack: some View {
        VStack(alignment: .leading, spacing: 6) {
            if freezes < StreakRules.maxFreezes {
                HStack(spacing: 3) {
                    ForEach(0..<StreakRules.daysPerFreeze, id: \.self) { day in
                        Capsule()
                            .fill(day < bankedDays ? Palette.gold : Palette.cardSunken)
                            .frame(height: 4)
                            // The segment that just landed lifts clear of the
                            // rest, so the animation says which day was won.
                            .scaleEffect(y: day == bankedDays - 1 ? 1 + collectPhase * 1.6 : 1)
                    }
                }
            }

            Text(streakDetail)
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    /// Days banked toward the next freeze. A streak sitting exactly on a
    /// multiple of ten has just earned one and starts the next track empty.
    private var bankedDays: Int {
        guard streak > 0 else { return 0 }
        return streak % StreakRules.daysPerFreeze
    }

    /// Gold, and a wider radius than the rows above. The border brightens
    /// while collecting, which is what makes the whole card — rather than one
    /// glyph inside it — the thing that reacts.
    private var streakSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Palette.shadow.opacity(0.05), radius: 10, x: 0, y: 4)

            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(colors: [Palette.gold.opacity(streak > 0 ? 0.13 : 0.05),
                                            Palette.gold.opacity(0.03)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [Palette.gold.opacity(0.30 + collectPhase * 0.55),
                                            Palette.gold.opacity(0.10 + collectPhase * 0.30)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        }
    }

    private var streakDetail: String {
        if streak == 0 { return "Answer today to start one" }
        if freezes >= StreakRules.maxFreezes { return "Freezes full" }
        return daysUntilNextFreeze == 1
            ? "1 day to your next freeze"
            : "\(daysUntilNextFreeze) days to your next freeze"
    }

    // MARK: The day

    /// The day as a figure and one bar.
    ///
    /// This was a 176pt ring inside a 244pt bloom — about 243pt of the screen,
    /// which is most of what an iPhone 8 shows above the fold, spent on a
    /// number that the line under the title and the two cards beneath were
    /// already stating. The ring's own argument was never its size: it was
    /// that one object means one day, and a segment per item says what a
    /// single question is worth. A bar keeps both of those and costs 150pt.
    ///
    /// The figure stays large and stays the hero. What went is the empty
    /// middle it used to sit in.
    private var dayBar: some View {
        ZStack(alignment: .bottom) {
            SegmentedDayArc(sections: sections)
            // Seated in the arc's well, so the shape and the number read as one
            // object. The arc's inner edge is 118pt from centre, and the widest
            // the figure ever gets — a three-digit goal — is 102pt at the top
            // of the well where 128pt is clear, so it never touches the stroke.
            headline
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .background {
            // The bloom the ring used to sit in, kept. It is what says "this is
            // the important part" without drawing a box.
            //
            // In `background` rather than a stack child on purpose: a 230pt
            // circle as a child would set the block's height to 230pt and hand
            // back the space this format exists to save. As a background it
            // overflows visually and costs nothing in layout.
            Circle()
                .fill(RadialGradient(colors: [heroTint.opacity(0.20), .clear],
                                     center: .center, startRadius: 2, endRadius: 115))
                .frame(width: 230, height: 230)
                .blur(radius: 12)
                .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }

    /// Whichever goal the figure is currently counting down.
    private var heroTint: Color {
        if allMet { return Palette.success }
        return questionsMet ? Palette.gold : Palette.accent
    }

    /// What is still owed, in the units of whichever goal is still open. The
    /// tint matches that goal's segments, so the number is always attributable
    /// to part of the bar without a label saying which.
    /// Centred and set large. Freed from the ring, the figure has to carry the
    /// hero position on its own, so it is bigger than the 46pt it was inside
    /// one — the ring was doing half that work.
    @ViewBuilder
    private var headline: some View {
        if allMet {
            VStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Palette.success)
                Text(showsQuickThink ? "Both goals met" : "Goal met for today")
                    .font(.appCallout)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        } else {
            let onQuestionsStill = !questionsMet
            let remaining = onQuestionsStill
                ? max(0, questionsGoal - questionsDone)
                : max(0, quickThinkGoal - quickThinkDone)
            VStack(spacing: -2) {
                CountingNumber(value: Double(remaining),
                               font: .numeric(60),
                               color: heroTint)
                Text(onQuestionsStill
                     ? "question\(remaining == 1 ? "" : "s") left today"
                     : "quick think\(remaining == 1 ? "" : "s") left today")
                    .font(.appCallout)
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    /// Questions first, then Quick Think, so the ring reads clockwise in the
    /// order the day is usually done.
    private var sections: [SegmentedGoalRing.Section] {
        var out: [SegmentedGoalRing.Section] = []
        let qGoal = max(1, questionsGoal)
        for i in 0..<qGoal {
            out.append(.init(tint: questionsMet ? Palette.success : Palette.accent,
                             isFilled: i < questionsDone))
        }
        guard showsQuickThink else { return out }
        let tGoal = max(1, quickThinkGoal)
        for i in 0..<tGoal {
            out.append(.init(tint: quickThinkMet ? Palette.success : Palette.gold,
                             isFilled: i < quickThinkDone))
        }
        return out
    }

    // MARK: Rows

    /// The app's card treatment, carrying a tint.
    ///
    /// `appCard` cannot do this and should not be taught to: its fill is one
    /// colour, and a translucent tint would put the shadow *through* the card
    /// rather than under it — the whole reason `CardBackground` puts the
    /// shadow on an opaque shape. So the tint sits as a wash over an opaque
    /// base here, and the border picks the tint up rather than the neutral
    /// glint, which is what keeps these reading as the questions card and the
    /// Quick Think card rather than as two identical grey panels.
    private func tintedCard(_ tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Palette.shadow.opacity(0.05), radius: 8, x: 0, y: 3)

            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                .fill(tint.opacity(0.09))

            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [tint.opacity(0.34), tint.opacity(0.12)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        }
    }

    /// The whole row is the control. Two full-width buttons were the heaviest
    /// thing on the screen and neither was the point; a tinted glyph carries
    /// the affordance and doubles as the key linking the row to its arc.
    private func goalRow(title: String,
                         symbol: String,
                         tint: Color,
                         done: Int,
                         goal: Int,
                         met: Bool,
                         action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    Circle().fill(tint.opacity(met ? 0.14 : 0.18))
                    Image(systemName: met ? "checkmark" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(met ? Palette.success : tint)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.appBodyMedium)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(done) of \(goal)")
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Tinted to the goal, not to whether it is met: the card keeps
            // being the questions card all day. The glyph turning green with
            // a checkmark is what reports the state, and having the whole
            // surface change colour underneath it said the same thing twice.
            .background(tintedCard(tint))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98, haptic: false))
        .accessibilityLabel("\(title), \(done) of \(goal)")
        .accessibilityHint(met ? "Goal met. Double tap for more."
                               : "Double tap to start.")
    }
}
