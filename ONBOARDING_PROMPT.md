# Prompt — Redesign Glass's onboarding

> Paste this into a fresh Claude Code session in this repo, alongside `@CLAUDE.md`.
> It assumes the reader has not seen the app before.

---

## Your task

Redesign the first-run onboarding for **Glass**, a shipped offline DECA Ontario study app for
high-school students. The current onboarding works but is generic: five `TabView` pages of title +
subtitle + rows. I want something **immersive, distinctive and genuinely hooking** — an opening
that makes a 16-year-old want to start studying, without ever becoming a children's quiz game.

Work in two passes:

1. **Pitch three concepts first**, in prose, before writing any code. One paragraph each: the
   spine of the idea, what the student feels, and what makes it different from every other
   onboarding. Say which you'd ship and why. Do not hedge — pick one.
2. **Then build the one I choose**, complete and compiling.

---

## What the app is, and the feel to hit

Glass is calm, premium and adult. Think a well-made pen, not a mobile game. The name is literal:
the identity is glass — clarity, weight, light passing through something solid.

The app already opens with a launch reveal where the word **"glass" is handwritten** in a monoline
script, stroke by stroke, then floods with light and settles into solid glass tubing. It's timed to
an audio swell that peaks at 2.40 s.

**The strongest creative constraint available to you is that this moment already exists.** Right
now, onboarding starts from a blank slate immediately afterwards, and the handoff is a hard cut.
Treat the reveal as the first beat of onboarding rather than a separate thing that happens before
it. Continuity from that moment is the single biggest available win — but if you have a better
idea, argue for it.

Emotional truth worth using: this app is for someone preparing for a **specific competition on a
specific date**. That's a stronger hook than "let's get you set up."

---

## Hard constraints — do not violate these

1. **iOS 16.0 deployment target. Must run on an iPhone 8.** No iOS 17+ APIs, no SwiftData, no
   `@Observable`, no `ScrollView` `onScrollGeometryChange`, no Metal-heavy effects. Everything must
   degrade or be availability-gated.
2. **No sign-in, no account, no internet requirement, no analytics, no personal data collection.**
   Everything is on-device. The onboarding must *say* this, because it's a real differentiator, but
   must not lecture.
3. **Never use system-drawn controls.** No `Picker`, `.pickerStyle`, `Toggle` without the app's
   style, `Stepper`, `ProgressView`, `List`, or `DatePicker`. iOS 16 and iOS 26 draw those
   differently and the app deliberately owns its controls. Use `AppSegmentedPicker`,
   `AppMenuPicker`, `AppStepper`, `AppToggleStyle` and `ProgressBar` from
   `Components/AppControls.swift` and `Components/LocalAICoachCard.swift`, or add new ones in the
   same spirit.
4. **Never claim the bundled questions are official DECA content.** They're original practice
   items.
5. **Accessibility is not optional.** Full Dynamic Type (no fixed point sizes for text — use
   `@ScaledMetric` for anything that must scale with it), VoiceOver labels and traits, and a real
   Reduce Motion path that is calm rather than broken. A motion-heavy concept must still work with
   motion off.
6. **Performance matters on an A11.** No `.shadow` applied to composited content — put it on the
   background shape. Lazy stacks for anything unbounded. No per-frame blurs over scrolling content.

---

## Design system — use these, don't invent parallel ones

**Type** (`Core/DesignSystem.swift`): display face is `Fraunces-Display`, text face is `Inter`.
Roles: `.appLargeTitle`, `.appTitle`, `.appHeadline`, `.appBody`, `.appCallout`, `.appFootnote`,
`.appCaption`, `.appCaptionBold`, `.appQuestion`, plus `appSans(_:weight:)` and
`numeric(_:weight:)`. A monoline script, `Sacramento-Regular`, exists but is reserved for the
wordmark — do not set UI text in it.

**Colour** (`Palette`): `canvas`, `card`, `cardRaised`, `cardSunken`, `stroke`, `strokeStrong`,
`textPrimary`, `textSecondary`, `textTertiary`, `accent`, `accentSoft`, `success`, `successSoft`,
`danger`, `dangerSoft`, `gold`, `goldSoft`, `inactive`, `shadow`. All are light/dark pairs — every
screen must be checked in both. Accent colours carry meaning: blue = progress, green = correct,
red = wrong, gold = streaks and achievements.

**Spacing** (`Metrics`): `gutter` 18, `cardRadius` 18, `controlRadius` 14, `rowMinHeight` 52,
`stackSpacing` 14, `sectionSpacing` 24.

**Motion** (`Core/Motion.swift`): `Motion.snappy`, `.gentle`, `.bouncy`, `.quick`, `.reveal`,
`.page`. Also `PageShift`, `AnyTransition.page(direction:)`, `CountingNumber`, and `appearIn(_:)`
for staggered entrances. A modifier only re-evaluates per frame if it conforms to `Animatable` —
anything that animates along a curve or counts must conform.

**Feedback**: `Haptics` (`tap`, `select`, `impact`, `success`, `celebrate`) and `SoundEffects`
(`.correct`, `.wrong`, `.celebration`, `.intro`). Audio is `.ambient` + `.mixWithOthers` and must
never interrupt the student's music. Use both sparingly and deliberately — one well-placed haptic
beats five.

**Existing pieces to reuse or replace knowingly**: `OnboardingPage`, `OnboardingTitle`,
`FeatureRow`, `InfoBanner`, `AIStatusCard`, `ClusterPicker`, `GoalStepper`, `PrimaryButton`,
`SectionHeader`, `EmptyStateView`, `appCard()`, `appCanvas()`.

---

## Everything the onboarding must still accomplish

Redesign freely, but nothing here may be lost. Write each of these to `store.settings` on
completion, exactly as `finish()` does today:

| Must collect / do | Writes to | Notes |
|---|---|---|
| Welcome + what the app is | — | Must establish the offline, no-account promise |
| **DECA cluster** | `settings.cluster` | 6 options: marketing, finance, hospitality, businessManagement, entrepreneurship, personalFinancialLiteracy. Defaults to marketing |
| **Daily question goal** | `settings.dailyGoal` | 1…100, default 10 |
| **Daily reminder** on/off + time | `settings.remindersEnabled`, `settings.reminderDate` | Requests notification permission; must handle denial gracefully. Default 18:30 |
| **AI coaching status** | — | Show `store.ai.availability` via `AIStatusCard` |
| **Local AI coach download** | via `store.localModel` | **Only when Apple Intelligence is unavailable.** Show `LocalAICoachCard`. Must state "Wi-Fi needed for the download only", the ~808 MB size, and carry the "Built with Llama" attribution |
| Mark complete | `settings.hasOnboarded = true` | Then `store.refresh()` and `syncNotifications()` |

Also required regardless of concept:

- **Skippable.** A student who wants to start immediately must be able to, with sane defaults.
- **Reversible.** Every choice is editable later in Settings — say so, so nothing feels final.
- **Progress must be legible.** The student should always know how far in they are.
- **Fast.** Target under 45 seconds for someone who reads quickly.

---

## Creative direction

**Aim for:** a sense of place; one genuinely memorable moment rather than five decorated screens;
type doing the heavy lifting (you have Fraunces, use it); depth through light and material rather
than through drop shadows; motion that reveals structure rather than decorating it. Consider making
the student *do* something in the first ten seconds instead of reading.

**Avoid:** mascots, confetti, emoji as iconography, "Let's get started!", progress dots as the only
sense of progress, carousels of stock illustration, gamified XP language, anything that would
embarrass a 17-year-old showing it to a teacher.

**The bar:** if the concept could be dropped into any other study app by swapping the copy, it
isn't distinctive enough. It should only make sense for *this* app, with *this* name.

---

## How to work

- Read `CLAUDE.md` first — §7 lists bugs already paid for. Don't rediscover them.
- The project uses synchronized folders; **never hand-edit `project.pbxproj`.** Drop files into the
  target directory and they compile.
- **Do not run, screenshot, or record the iOS Simulator.** Verify with `xcodebuild` only, Debug
  *and* Release, and grep for **warnings as well as errors** — the target sets
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so concurrency warnings appear easily and are errors
  under Swift 6. Use `clean build` for a true warning count.
- Preserve the existing onboarding on a branch before replacing it.
- **Tell me when an idea of mine would make the app worse, and bring numbers.** I respond to
  measurements, not opinions.
- Deliver the whole change, then say plainly what you verified and what you couldn't.

---

## What to hand back

1. The three concepts, and your pick with reasoning.
2. After I choose: the complete implementation, compiling in Debug and Release with zero warnings.
3. A short note on what remains unverified because you couldn't run it.
