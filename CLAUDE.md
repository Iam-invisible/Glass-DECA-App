# Glass — Master Prompt / Project Brief

> Paste this at the start of a new chat, or reference it with `@MASTER_PROMPT.md`.
> It exists because chat compaction loses the non-obvious details — the constraints,
> the decisions already made, and the bugs already paid for. Read it before touching code.

---

## 0. How to use this document

You are continuing work on a shipped, working iOS app. **This is not a greenfield project and not a
mockup.** Everything described below is already built, builds clean, and runs. Your job is
incremental change on top of it.

Before proposing anything, assume the current design is deliberate. Most of it is the result of a
specific request or a specific bug. If something looks wrong, check §7 first — it may already have
been tried and rejected.

---

## 1. What the app is

**Glass** — an offline-first DECA Ontario study app for high-school students.

- Swift + SwiftUI, iOS 16.0 deployment target (must run on iPhone 8)
- Six tabs: **Today, Practice, Mock Exams, Roleplay, Progress, Settings**
- Feel: premium, calm, adult. Explicitly **not** a children's quiz game. Strong motion, haptics,
  full light/dark, full accessibility.
- Bundle ID `com.shailpatel.LCVI-DECA-Study-NewApp`, app group
  `group.com.shailpatel.LCVI-DECA-Study-NewApp` (renamed from `…-App` during App
  Store Connect setup — the entitlements, code constants and portal must all
  agree on this exact string), `PRODUCT_NAME = Glass`, Swift 5.0.
- The Xcode project folder is still named "LCVI DECA Study App" — only the product was renamed.

---

## 2. Non-negotiable constraints

These came from the original spec and have never been relaxed. Do not violate them, and do not
propose a feature that requires violating them.

1. **No sign-in. No account. No internet requirement. No remote APIs. No personal data collection.**
   All data lives locally on the device.
2. **Core Data, not SwiftData** — SwiftData needs iOS 17; this app supports iOS 16 / iPhone 8.
3. **Apple Foundation Models is strictly optional.** It must be availability-checked and must never
   break the app when unavailable. Every feature must degrade to a working offline path.
4. **The AI must never decide the official correct answer.** Correct answers always come from the
   local question bank. AI is used only for explanation, coaching, and feedback.
5. **Never claim the sample questions are official DECA Ontario questions.** They are original
   practice items and must be labelled as sample practice questions. (`SeedQuestions.swift` carries
   this disclaimer in its header — keep it there.)

---

## 3. How the user wants you to work

- **Do not run, screenshot, or record the iOS Simulator.** The user checks the app on their own
  phone. Simulator sessions burn their usage limit. Verify with `xcodebuild` only.
- **Just implement it.** Don't ask for confirmation on ordinary design/implementation calls.
- **Tell them when their idea would make things worse.** Precedent: they asked to replace every SF
  Symbol with icons from reicon.dev. Inspection showed that set mixes three construction styles
  (59% fill-24, 35% stroke-24, 4% stroke-18), so the tab bar would have been three filled icons and
  three outlines. That was reported with the numbers, and the user replied "keep the SF symbols its
  okay." **Bring evidence, not opinions** — this user responds well to measurements.
- Deliver the whole change, then say plainly what was verified and what wasn't.

---

## 4. Architecture facts you can't infer from a quick skim

- **`PBXFileSystemSynchronizedRootGroup`** — the target uses synchronized folders. Any file dropped
  into the target directory compiles automatically. **Never hand-edit `project.pbxproj` to add
  sources or resources.**
- **The Core Data model is built programmatically** in `Models/Persistence.swift` — there is **no
  `.xcdatamodeld` file**. 13 entities, related by **UUID foreign keys rather than Core Data
  relationships**: `CDQuestion`, `CDPracticeSession`, `CDPracticeAnswer`, `CDMockAttempt`,
  `CDMockResult`, `CDMistake`, `CDSRRecord`, `CDPIMastery`, `CDDailyProgress`, `CDRoleplayPrompt`,
  `CDRoleplayResponse`, `CDQuickThinkSession`, `CDAchievementRecord`.
- **Stable IDs**: seed content uses `UUID.stable("question-\(key)")` (`Data/StableID.swift`) so
  re-seeding never duplicates rows.
- **`AppStore`** (`Services/AppStore.swift`) is the single coordination point injected as
  `@EnvironmentObject`. Services are plain types it owns.
- **Foundation Models** is gated by `#if canImport(FoundationModels)` **and**
  `if #available(iOS 26.0, *)`. Uses `SystemLanguageModel.default.availability`,
  `LanguageModelSession(instructions:)`, `session.respond(to:)`.
- **Five required AI status strings** shown in Settings (exact text, in
  `FoundationModelFeedbackService.swift`): "AI Feedback Available", "Apple Intelligence Not
  Enabled", "This Device Does Not Support AI Feedback", "Local Model Still Downloading", "AI
  Feedback Temporarily Unavailable".
- **Seed content**: 60 sample questions, 12 roleplays, 53 performance indicators, across six
  clusters (marketing, finance, hospitality, businessManagement, entrepreneurship,
  personalFinancialLiteracy).
- **Widget** (`DECAStudyWidget/`) reads a snapshot written by `WidgetDataService` through the shared
  app group. It renders out-of-process.

---

## 5. Design system

**Typography** — `Core/DesignSystem.swift`, files in `LCVI DECA Study App/Fonts/`, registered via
`UIAppFonts` in `Config/App-Info.plist`.

- Display: `Fraunces-Display` (variable font instanced to wght 650, SOFT 18, WONK 1, `opsz` left
  variable)
- Body: `Inter-Regular` / `Inter-Medium` / `Inter-SemiBold`
- Semantic roles: `.appLargeTitle`, `.appTitle`, `.appHeadline`, `.appBody`, `.appCallout`,
  `.appFootnote`, `.appCaption`, `.appCaptionBold`, `.appQuestion`, plus `appSans(_:weight:)` and
  `numeric(_:weight:)`.
- OFL licences ship alongside the fonts. Keep them.

**Motion** — `Core/Motion.swift`: `Motion.page`, `PageShift`, `AnyTransition.page(direction:)`,
`CountingNumber`, `AppearTransition`. Tab changes set `direction` **before** committing the tab so
the transition knows which way to travel.

**Audio** — `Core/SoundEffects.swift`, files in `Resources/`. Session is `.ambient` +
`.mixWithOthers` so it never interrupts the user's music. Volumes were level-matched by A-weighted
loudness, not by peak:

| Cue | File | Volume |
|---|---|---|
| `.correct` | `answer-correct.m4a` | 1.00 |
| `.wrong` | `answer-wrong.wav` | 0.45 |
| `.celebration` | `badge-celebration.m4a` | 0.60 |
| `.intro` | `app-intro.m4a` | 1.00 |

**Liquid Glass** — floating capsule tab bar in `RootView.swift`. iOS 26 uses
`.glassEffect(.regular, in: .capsule)`; iOS 16–25 falls back to `.ultraThinMaterial` in the same
capsule so layout is identical.

**Intro scene** — `Views/Onboarding/IntroView.swift`. "Glass" is traced in Fraunces then filled as
solid glass tubing. Choreography is timed to the audio peak at 2.40 s: backdrop 0.6 s; trace starts
0.30 s over 2.0 s; at 2.30 s a medium impact haptic + spring fill/bloom/scale; +0.22 s success
haptic + 1.0 s sweep; +2.0 s finish. Reduce Motion skips the tracing entirely.

---

## 6. Feature inventory

Practice sessions with spaced repetition · custom practice builder · mistake notebook · timed mock
exams with review · roleplay scenarios with rubric + optional AI coaching · Quick Think drills ·
progress dashboard with PI mastery · streaks and achievement badges with a celebration animation ·
question bank manager with bulk import/export · home screen widgets · local notifications.

---

## 7. Gotchas already paid for — do not rediscover these

1. **`import Combine` is required explicitly.** The project sets
   `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`, so transitive imports don't leak.
2. **Don't add `@retroactive Identifiable` to `UUID`.** Wrap it (see `AttemptReview`).
3. **A view reused across queued events keeps its `@State`.** The celebration overlay locked the app
   because stale state survived. Fixed with a `startedFor` guard, `.onChange(of: event.id)`, an
   unanimated `resetState()`, and `.id(event.id)`.
4. **`fullScreenCover` covers overlays.** Hence `CelebrationLayer` + `AppStore.fullScreenLayers`.
5. **`NavigationStack` swallows a parent's `safeAreaInset`.** The floating tab bar cut off content
   until the inset was applied *inside* the stack, via the `bottomBarInset` environment key
   consumed by `appCanvas()`.
6. **`Glass.clear` is too transparent for labels** — content scrolling underneath collides with tab
   text. Use `.regular`.
7. **`UIFontMetrics.scaledFont` inside a `static let` caches forever and silently kills Dynamic
   Type.** Use `Font.custom(_:size:relativeTo:)` with baked static weights instead.
8. **Instancing Fraunces with `updateFontNames=True` fails** (wght 650 / SOFT 18 aren't named STAT
   values). Use `updateFontNames=False` and set name IDs 1/2/3/4/6/16/17 manually.
9. **`SwiftUI.StrokeStyle` argument order is `lineWidth, lineCap, lineJoin`.** Reversing the last
   two is a compile error.
10. **A modifier's `body` only re-evaluates per frame if the modifier conforms to `Animatable`.**
    This is why `TopSpin`, `CountingNumber`, and `TracedGlyph` conform.
11. **Nested `ObservableObject`s don't propagate.** Views observe `AppStore`, so a change to
    `UserSettings` alone never redrew — "Replay intro" silently did nothing. Fixed with a
    `settingsBridge` that pipes `settings.objectWillChange` into `store.objectWillChange`.
12. **Widgets can't sample the wallpaper.** The system paints glass *behind* them, so the widget
    must leave `containerBackground` translucent rather than drawing its own glass.
13. **`CFBundleName` derives from `PRODUCT_NAME`.** A stale widget label on the home screen is a
    SpringBoard cache, not a bug.
14. **A shine sweep offset outside a view's bounds needs `.clipShape`,** or it paints a stray
    rectangle beside the content.
15. **`.frame(maxWidth: .infinity)` makes a badge greedy inside rows** and breaks alignment. Gate it:
    `maxWidth: showsTitle ? .infinity : nil`.
16. **Intro audio is deliberately not stopped on dismiss.** The player lives on `SoundEffects`, not
    on the view, so the swell resolves under the Today tab instead of being cut mid-phrase.
17. **Glass letterforms are filled and inflated, not stroked outlines.** Stroking the glyph *contour*
    produces hollow balloon letters. The current `solid(_:)` helper fills the glyph **and** strokes
    it with a round join to swell the silhouette; shading and highlight are blurred contour passes
    offset down-right / up-left and masked inside. `inflate` is the single tuning knob.

---

## 8. Build and verify

```bash
xcodebuild -project "LCVI DECA Study App.xcodeproj" -scheme "LCVI DECA Study App" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build 2>&1 | grep -E "error:|BUILD"
```

Check **Release** too — it catches things Debug doesn't. Filter out `AppIntents` metadata warnings;
they're expected noise. **Build only. Do not launch the simulator** (see §3).

---

## 9. Current state

Everything above is implemented and both configurations build clean. Most recent work: the intro
scene's wordmark was reworked from stroked outlines to solid inflated glass tubing, and the intro
audio was allowed to play to completion after dismissal.
