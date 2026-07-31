# Glass — Master Prompt / Project Brief

> Paste this at the start of a new chat, or reference it with `@MASTER_PROMPT.md`.
> `CLAUDE.md` is a copy of this file and loads automatically in Claude Code.
>
> It exists because chat compaction loses the non-obvious details — the constraints,
> the decisions already made, and the bugs already paid for. Read it before touching code.

---

## 0. How to use this document

You are continuing work on a **shipped, working iOS app that is about to be submitted to the
App Store.** This is not a greenfield project and not a mockup. Everything described below is
already built, builds clean in Debug and Release with zero warnings, and runs.

Before proposing anything, assume the current design is deliberate. Most of it is the result of a
specific request or a specific bug. If something looks wrong, check §8 first — it may already have
been tried and rejected.

**Start here:** §9 is the pre-submission punch list. That is the live work.

---

## 1. What the app is

**Glass** — an offline-first DECA Ontario study app for high-school students.

- Swift + SwiftUI, iOS 16.0 deployment target (must run on iPhone 8)
- **Three panes: Study · Progress · Settings** (this was six tabs until recently — see §4)
- Feel: premium, calm, adult. Explicitly **not** a children's quiz game. Strong motion, haptics,
  full light/dark, full accessibility.
- Bundle ID `com.shailpatel.LCVI-DECA-Study-NewApp`, app group
  `group.com.shailpatel.LCVI-DECA-Study-NewApp` (renamed from `…-App` during App Store Connect
  setup — entitlements, code constants and the developer portal must all agree on this exact
  string), `PRODUCT_NAME = Glass`, Swift 5.0, version 1.0 build 1.
- The Xcode project folder is still named "LCVI DECA Study App" — only the product was renamed.

**Repositories**
- `https://github.com/Iam-invisible/Glass-DECA-App` — main development repo
- `https://github.com/Iam-invisible/Glass-DECA-versions` — version archive, one branch per
  milestone, `main` is a README index

---

## 2. Non-negotiable constraints

1. **No sign-in. No account. No remote APIs. No personal data collection. No internet
   requirement.** All data lives locally. The single exception is the optional local-model
   download (§7), which is opt-in and Wi-Fi-only.
2. **Core Data, not SwiftData** — SwiftData needs iOS 17; this app supports iOS 16 / iPhone 8.
3. **Apple Foundation Models is strictly optional.** Availability-checked, never breaks the app
   when unavailable. Every feature degrades to a working offline path.
4. **The AI must never decide the official correct answer.** Correct answers always come from the
   local question bank. AI is used only for explanation, coaching and feedback.
5. **Never claim the sample questions are official DECA Ontario questions.** They are original
   practice items and must be labelled as sample practice questions. The same applies to the event
   catalogue (§6). `SeedQuestions.swift` carries this disclaimer in its header — keep it there.
6. **Never use system-drawn controls.** iOS 16 and iOS 26 draw them differently. See §5.

---

## 3. How the user wants you to work

- **Do not run, screenshot, or record the iOS Simulator.** The user checks the app on their own
  phone. Simulator sessions burn their usage limit. Verify with `xcodebuild` only.
- **Grep for `warning:` as well as `error:`,** and use `clean build` — incremental builds do not
  re-emit warnings for untouched files. The target sets
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so concurrency warnings appear easily and are
  errors under Swift 6.
- **Just implement it.** Don't ask for confirmation on ordinary design/implementation calls.
- **Tell them when their idea would make things worse, and bring numbers.** Precedent: they asked
  to replace every SF Symbol with icons from reicon.dev; measurement showed that set mixes three
  construction styles (59% fill-24, 35% stroke-24, 4% stroke-18), so the tab bar would have been
  three filled icons and three outlines. Reported with the numbers, and they replied "keep the SF
  symbols its okay."
- **Commit at every good stopping point** and say what was verified and what wasn't. The user
  relies on tags to roll back — see §10.
- The user cannot see your reasoning. Report outcomes plainly.

---

## 4. Architecture facts you can't infer from a quick skim

- **`PBXFileSystemSynchronizedRootGroup`** — the target uses synchronized folders. Any file
  dropped into the target directory compiles automatically. **Never hand-edit `project.pbxproj`
  to add sources or resources.** (This is also why llama.cpp can't be added from outside Xcode.)
- **The Core Data model is built programmatically** in `Models/Persistence.swift` — there is **no
  `.xcdatamodeld` file**. 13 entities related by **UUID foreign keys rather than Core Data
  relationships**: `CDQuestion`, `CDPracticeSession`, `CDPracticeAnswer`, `CDMockAttempt`,
  `CDMockResult`, `CDMistake`, `CDSRRecord`, `CDPIMastery`, `CDDailyProgress`, `CDRoleplayPrompt`,
  `CDRoleplayResponse`, `CDQuickThinkSession`, `CDAchievementRecord`.
- **Stable IDs**: seed content uses `UUID.stable("question-\(key)")` (`Data/StableID.swift`) so
  re-seeding never duplicates rows.
- **`AppStore`** (`Services/AppStore.swift`) is the single coordination point injected as
  `@EnvironmentObject`. Services are plain types it owns.
- **Navigation intents** live on `AppStore`: `requestedTab`, `wantsQuestionBank`,
  `wantsMistakeNotebook`, `wantsMockExam`, `showGuide`, `guideFocus`. Consumed with a
  **reset-then-act** pattern — flip local state *after* mount, because a `navigationDestination`
  already true at first render does not push reliably on iOS 16.
- **Three panes.** `Study` absorbed the old Today + Practice launchers. Mock Exams, Roleplay and
  the Library (the old Practice tab's browse section) keep their entire screens and are **pushed
  from Study's tiles**. Nothing was deleted in that restructure — the map was redrawn.
- **Foundation Models** is gated by `#if canImport(FoundationModels)` **and**
  `if #available(iOS 26.0, *)`.
- **Five required AI status strings** shown in Settings (exact text, in
  `FoundationModelFeedbackService.swift`): "AI Feedback Available", "Apple Intelligence Not
  Enabled", "This Device Does Not Support AI Feedback", "Local Model Still Downloading", "AI
  Feedback Temporarily Unavailable".
- **Seed content**: 600 sample questions (100 per cluster, each carrying a rationale for
  *every* option), 71 roleplays, 90 Quick Think prompts, 53 performance indicators, six
  clusters. One file per cluster under `Data/Questions/` and `Data/Roleplays/`; the parent
  `SeedQuestions.swift` / `SeedRoleplays.swift` hold only the aggregate and the builder.
  Both builders are **internal, not private** — the cluster files are extensions in their
  own files, and a `private` helper is invisible to them.
- **`refreshSampleContent()`** exists because `seedIfNeeded` only ever *inserts*: the stable
  IDs that stop duplicates also stop updates, so a corrected explanation would never reach
  an existing install. It runs on a seed-version bump, rewrites rows still flagged
  `isSample`, and preserves bookmarks.
- **Widget** (`DECAStudyWidget/`) reads a snapshot written by `WidgetDataService` through the
  shared app group, and bundles its own copies of the app's fonts.

---

## 5. Design system

**Typography** — `Core/DesignSystem.swift`, fonts in `LCVI DECA Study App/Fonts/`, registered via
`UIAppFonts` in `Config/App-Info.plist`. The widget bundles its own copies in
`DECAStudyWidget/Fonts/` registered in `Config/DECAStudyWidget-Info.plist`.

- **Display: Instrument Serif** — high-contrast serif; the thick-to-thin modulation is the point,
  because the app is called Glass. One weight by design.
- **Text: Manrope** (Regular / Medium / SemiBold) — chosen on measurement, not taste: largest
  x-height of 14 candidates (0.540) and second most compact, and it ships `tnum`.
- **Script: Sacramento** — intro wordmark only. Never set UI text in it.
- Roles: `.appLargeTitle` (38), `.appTitle` (26), `.appSectionTitle` (22), `.appHeadline`,
  `.appBody`, `.appCallout`, `.appFootnote`, `.appCaption`, `.appCaptionBold`, `.appQuestion`,
  `.appKicker` + `.kicker()`, plus `appSans(_:weight:)` and `numeric(_:weight:)`.
- **The hierarchy rule: serif is always a heading, Manrope is always content.**
- OFL licences ship alongside every font. Keep them.

**Colour** — `Palette`. Light/dark pairs. Accents carry meaning only: blue = progress,
green = correct, red = wrong, gold = streaks and achievements, grey = inactive. `strokeGlint` is
the lighter top edge of a card's gradient border.

**Spacing** — `Metrics`: gutter 18, cardRadius 18, controlRadius 14, rowMinHeight 52,
stackSpacing 14, sectionSpacing 24.

**Motion** — `Core/Motion.swift`: `Motion.page/.snappy/.gentle/.bouncy/.quick/.reveal`,
`PageShift`, `AnyTransition.page(direction:)`, `CountingNumber`, `AppearTransition`,
`appearIn(_:)` (index stagger, 55 ms apart) and **`appearBeat(_:)`** (authored delay in seconds,
for choreographed scenes). Tab changes set `direction` **before** committing the tab.

**Ambience** — `AmbientCanvas` puts the intro's drifting light pools behind every screen via
`appCanvas()`. Static circles whose *offset* animates, so Core Animation blurs once and caches;
this is the same recipe the intro backdrop already ships on an iPhone 8.

**Audio** — `Core/SoundEffects.swift`. Session is `.ambient` + `.mixWithOthers`. Volumes were
level-matched by A-weighted loudness, not peak:

| Cue | File | Volume |
|---|---|---|
| `.correct` | `answer-correct.m4a` | 1.00 |
| `.wrong` | `answer-wrong.wav` | 0.45 |
| `.celebration` | `badge-celebration.m4a` | 0.60 |
| `.intro` | `app-intro.m4a` | 1.00 |

**Intro scenes** — `Views/Onboarding/`. Two, selectable in Settings:
- `IntroScriptView` (default) — "glass" handwritten along a baked pen path, then flooded as glass.
- `IntroClassicView` — "Glass" traced in the display serif, then filled: reads as etching.

`GlassScriptPath.swift` holds 560 baked points derived offline: the word is rasterised at 900pt,
skeletonised, and the skeleton walked as a graph taking **the branch with the least undrawn ink
beyond it** — the rule that makes a hand finish a loop before travelling on. Points are spaced by
**ink revealed**, not distance, because a quarter of the route is retracing and even spacing made
the word appear to stall. Choreography: backdrop 0.6 s; writing 0.18 → 2.30 s; glass floods on the
audio's 2.40 s peak with a medium impact; success haptic + sweep 0.22 s later.

**Custom controls** — `Components/AppControls.swift`: `AppToggleStyle` (applied once at the root,
propagates through the environment), `AppSegmentedPicker`, `AppMenuPicker`, `AppStepper`. Built
from primitives only, because iOS 16 and iOS 26 draw system controls differently. Alerts,
confirmation dialogs, sheets, the share sheet and the file importer stay **native on purpose**.

**Screen chrome** — `ScreenHeader` (serif title + tracked-uppercase eyebrow) replaces system
large titles on all root screens, which also removed the largest remaining iOS 16/26 divergence.
`StatusBarScrim` fades in only once content scrolls under the status bar, driven by
`ScrollOffsetProbe` + `.reportsScrollOffset()` preferences.

---

## 6. Feature inventory

**Study (home)** — greeting with the student's event code; two `GoalDial`s side by side
(Questions and Quick Think) showing today's ring and a compact start button; a slim streak card;
a `ModeTile` garden of six squares (Review Due, Mistakes, Mock Exams, Roleplay, Exam Cram,
Bookmarks) plus a full-width **Library** banner; insight cards. Tile affordance rule: **a count
means it launches, a chevron means it navigates.** Dials report only — both targets are set with
steppers in Settings.

**Progress** — the analytics pane: accuracy, PI mastery, cluster breakdowns, achievements.

**Settings** — cluster, competitive event (`EventPicker`), both daily goal steppers, reminders,
AI status + local coach, question bank manager, import/export, appearance, intro style, replay
guide.

**Onboarding** — a prologue title sequence (three lines, each with its own animated scene: a
podium rising, a path drawing itself to a flag, the goal ring filling) then five chapters: Try it
(answer a real question with real sound and haptics before anything is configured), Your event
(cluster), Which event exactly (`EventPicker`), Your pace (goals), Your corner crew (reminders +
AI). Skip present on every frame; acts travel directionally.

**App guide** — `GuideOverlay`. Asks first ("Want a quick tour?"), then spotlights the real UI
with an animated cutout that travels between three stops, scrolling each into view first.
Views opt in with `.guideAnchor(_:)`; anchors resolve at the app root. Replayable from Settings.

**Competitive events** — `Data/DECAEvents.swift`. 50 events keyed by the code students say out
loud, each modelling `regional` and `provincial` components **separately**, because some events
are not the same competition twice (Integrated Marketing Campaign and the professional selling
events advance out of regionals on a cluster exam and do not present until provincials). The
cluster **leads** — the picker only offers that cluster's events and refuses others by name,
offering an explicit switch. "Undecided" is a first-class answer. The catalogue already shapes
the app: the Quick Think dial and goal are hidden for events with no roleplay.

**Also**: practice with spaced repetition, custom practice builder, mistake notebook, timed mock
exams with review, roleplay scenarios with rubric + optional AI coaching, Quick Think drills,
streaks and achievement badges with a celebration animation, question bank manager with bulk
import/export, home screen widgets, local notifications.

**Web preview** — `index.html` + `web/` at the repo root: a static recreation of the app for
browser viewing, deployed from the `web-only` branch. Not part of the iOS target.

---

## 7. The local AI coach — read before touching

`LocalModelService` offers an optional **808 MB** download of Llama 3.2 1B Instruct (Q4_K_M),
Wi-Fi enforced at the socket, SHA-256 pinned, excluded from backup, deletable. It is offered
**only** where Apple Intelligence is unavailable.

**The consumption side is now wired.** `CoachEngineFactory` builds the engine, `AppStore`
attaches it whenever the model file is present, and `FoundationModelFeedbackService.generate()`
falls through to it when Apple's model is out of reach — so explanations, roleplay coaching and
Quick Think feedback all reach it through the funnel they already used. Weights are freed on
`.background`, not `.inactive`, because dropping a gigabyte every time someone opens Control
Centre would cost more than holding it.

`AIAvailability` gained a sixth case, `.localCoachAvailable`, so Settings can say the local coach
is running instead of reporting the device unsupported while AI visibly works. The five required
status strings (§4) are untouched.

**What is still missing is the runtime.** `LlamaCoachEngine` is written but has never been
compiled — no llama package is in the project, so `canImport` is false and the factory returns
`StubCoachEngine`. See §9 item 1 for the correct package URL, and note that the one this brief
carried for months was wrong.

---

## 8. Gotchas already paid for — do not rediscover these

1. **`import Combine` is required explicitly** (`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`).
2. **Don't add `@retroactive Identifiable` to `UUID`.** Wrap it (see `AttemptReview`).
3. **A view reused across queued events keeps its `@State`.** Fixed with a `startedFor` guard,
   `.onChange(of: event.id)`, an unanimated `resetState()`, and `.id(event.id)`.
4. **`fullScreenCover` covers overlays.** Hence `CelebrationLayer` + `AppStore.fullScreenLayers`.
5. **`NavigationStack` swallows a parent's `safeAreaInset`** — hence the `bottomBarInset`
   environment key consumed by `appCanvas()`.
6. **`Glass.clear` is too transparent for labels.** Use `.regular`.
7. **`UIFontMetrics.scaledFont` inside a `static let` caches forever and kills Dynamic Type.**
   Use `Font.custom(_:size:relativeTo:)`.
8. **Google's static Manrope instances all report the PostScript name `ManropeExtraLight-*`.**
   `Font.custom` resolves by PostScript name, so all three weights would collapse to one. The name
   tables were rewritten by hand. Same class of problem as instancing Fraunces previously.
9. **`SwiftUI.StrokeStyle` argument order is `lineWidth, lineCap, lineJoin`.**
10. **A modifier's `body` only re-evaluates per frame if it conforms to `Animatable`** — why
    `TopSpin`, `CountingNumber`, `TracedGlyph`, `PenStroke` and `PenTip` conform.
11. **Nested `ObservableObject`s don't propagate.** Fixed with a `settingsBridge` piping
    `settings.objectWillChange` into `store.objectWillChange`.
12. **Widgets can't sample the wallpaper.** The system paints glass *behind* them, so the widget
    must leave `containerBackground` translucent.
13. **`CFBundleName` derives from `PRODUCT_NAME`.** A stale widget label is a SpringBoard cache.
14. **A shine sweep offset outside a view's bounds needs `.clipShape`.**
15. **`.frame(maxWidth: .infinity)` makes a badge greedy inside rows.** Gate it.
16. **Intro audio is deliberately not stopped on dismiss** — the player lives on `SoundEffects`.
17. **Glass letterforms are filled *and* stroked with a round join**, not stroked outlines.
    Stroking the contour alone gives hollow balloon letters. `inflate` is the tuning knob.
18. **A ring's tip highlight belongs at radius `min/2`, not `(min - lineWidth)/2`.** `.stroke`
    centres the line on the circle's path; the border-inset radius leaves a stray dot beside the
    arc. Hit once in the app and pre-empted in the widget.
19. **Resolve anchors and draw overlays in the same coordinate space.** The guide's cutouts landed
    high by exactly the top inset because the host resolved in safe-area space while the shape
    expanded with `ignoresSafeArea()`. The *hosting* `GeometryReader` should ignore the safe area;
    nothing inside should expand separately.
20. **`UserDefaults(suiteName:)` does NOT return nil when the process lacks the App Group
    entitlement.** It returns an object whose store failed to open, and every access logs
    "invalid reuse after initialization failure". Probe
    `containerURL(forSecurityApplicationGroupIdentifier:)` instead — that does return nil.
21. **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** means plain types are implicitly main-actor.
    Constants read from `nonisolated` delegate callbacks or `Task.detached` need `nonisolated`.
22. **`getBBox()` on SVG `<text>` returns the font's layout box, not tight ink bounds** — fitting
    to it scaled the web wordmark unevenly. Bake the glyph outline instead. (Web preview only.)

---

## 9. Pre-submission punch list — the live work

**Still open — and all four are things only you can do**

1. **No llama runtime in the project.** `File ▸ Add Package Dependencies… ▸
   `https://github.com/mattt/llama.swift`, add the **`LlamaSwift`** product to the app target.

   **Do not use `https://github.com/ggml-org/llama.cpp`** — it has no `Package.swift` and Xcode
   refuses it. That URL was in this brief for months and is wrong. `llama.swift` wraps the
   *official* precompiled XCFramework from llama.cpp's own releases, so nothing builds from
   source and the C API is upstream's, unmodified. Its versions track upstream builds
   (`2.10199.0` ≙ llama.cpp `b10199`). Adding llama.cpp's XCFramework directly also works and
   needs no third party.

   Everything else is written: `LlamaCoachEngine` sits behind
   `#if canImport(LlamaSwift) || canImport(llama)` so either route lights it up,
   `CoachEngineFactory` picks it up automatically, and the AI service already falls through to
   it. **The raw `llama_*` calls have never been compiled** — that C API renames things between
   revisions, so expect to fix call sites on the first build and **pin an exact version, not a
   branch.**
2. **Run the whole app end to end on device.** Nothing since `v5-immersive` has run on hardware
   and a great deal has changed. Riskiest: first-launch flow, guide spotlight geometry,
   back-navigation from the pushed Mock Exams / Roleplay / Library, and the Core Data lightweight
   migration that adds the four `rationale*` attributes.
3. **Check App Store metadata for DECA trademark exposure** — the in-app disclaimer is solid, the
   store listing is a separate surface.
4. **One open catalogue question.** Whether Series, Principles and Team Decision Making run their
   roleplay *at regionals* or advance on the exam alone. Ontario's own pages point both ways and
   it varies by area, so they are left as exam + roleplay at both levels — the error that
   over-prepares. Worth one question to an advisor. Flagged in `DECAEvents.swift`'s header.

**Closed since v7-events**

- **Privacy manifests** shipped for both targets, `plutil`-verified in a Release build. Only two
  required-reason categories exist anywhere in the tree: `UserDefaults` and one disk-space call.
- **App Group was a false alarm.** `CODE_SIGN_ENTITLEMENTS` was already set for both targets in
  both configurations. An empty entitlement dict is what a *simulator* build always shows.
  Confirmed working on the user's own device — the widgets update.
- **The 808 MB download now has something to run it.** `LocalCoachEngine` had no constructor
  anywhere in the app, which is why the download could never have produced behaviour. See item 1
  for the only remaining step.
- **Event catalogue corrected** against Ontario's published list. `EBP` and `ISP` were not real
  codes; `IBP` was filed under Independent rather than *International* Business Plan; `EIB`,
  `EFB`, `EBG` and `PEN` were missing; `QSRM` is not offered in Ontario. Most importantly, IMC
  and the professional selling events were modelled as having **no exam anywhere** when a cluster
  exam is the only thing that advances them out of regionals.
- **Content is no longer the gap.** 600 questions, 71 roleplays, 90 Quick Think prompts. At a
  10/day goal the bundled bank now lasts two months rather than six days.

**Candidate for removal**

- The **intro style toggle** exists because two intros were built, not because users need the
  choice. Picking one and deleting the setting removes a row and a test surface. The user has
  said explicitly not to remove the intros — this refers to the *toggle*, not either intro.

---

## 10. Versions and rollback

The user relies on tags to roll back and asks for saves explicitly. Never skip a requested save.

| Tag | What it holds |
|---|---|
| `v1-baseline` | Original — Fraunces + Inter, system controls, six tabs |
| `v2-revamp` | Instrument Serif + Manrope, rebuilt onboarding, custom controls |
| `v3-good` | + web preview, local AI coach, screen headers, status-bar scrim |
| `v4-buttons` | + every dead-end instruction became a one-tap route |
| `v5-immersive` | + ambient light field, glass panes, serif hierarchy, ring tip light. **Last device-confirmed version.** |
| `v7-events` | + three panes, cinematic onboarding, app guide, widget restyle, events + dual goals |
| `v8-content` | + 600 questions with per-option reasoning, 71 roleplays, 90 Quick Thinks, privacy manifests, large widget, corrected event catalogue, local coach wired |

Branch `rebrand-glass-edge` parks an abandoned cyan rebrand the user rejected — do not
resurrect it without asking. Current work is on `v7-events-goals`.

**Note:** the version branches in the archive repo share names with these tags, which makes bare
refs ambiguous — push with fully-qualified refspecs (`refs/heads/v5-immersive:refs/heads/…`).

**Second, separate trap when the milestone exists only as a tag** (v7-events onward — the earlier
ones have local branches of the same name, which is why they were never hit by this). An
annotated tag is a *tag object* wrapping a commit, and a branch must point at a commit, so
`refs/tags/X:refs/heads/X` sends the wrong object type. GitHub rejects it with an unexplained
`! [remote rejected] (failed)` and **`git push --dry-run` does not catch it**, because the
validation is server-side. Dereference with `^{}`, quoted so zsh leaves the braces alone:

```bash
git push versions 'v8-content^{}:refs/heads/v8-content'
```

---

## 11. Build and verify

```bash
xcodebuild -project "LCVI DECA Study App.xcodeproj" -scheme "LCVI DECA Study App" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug clean build 2>&1 | grep -E "error:|warning:|BUILD" | grep -viE "AppIntents|metadata extraction"
```

Run **both** Debug and Release, always with `clean`, always grepping warnings. Filter out
`AppIntents` metadata noise; it's expected. **Build only. Do not launch the simulator** (§3).

**Also run the content validators.** They catch what a compiler cannot, and at this volume that
matters more than it sounds:

```bash
python3 Scripts/check_questions.py && python3 Scripts/check_roleplays.py
```

`check_questions.py` fails on a duplicate stable key (a collision silently *drops* a question at
seed time), a `why` array that isn't exactly four entries, a `correctIndex` out of range, and —
the one that earns its keep — a `"Correct."` rationale sitting at a different index than
`correctIndex`, which compiles perfectly and teaches the wrong answer. `check_roleplays.py` fails
if a cluster collapses back to a single event format, which is the regression the roleplay
rebuild existed to fix.

---

## 12. Current state

Three panes, cinematic onboarding with a scored prologue, a spotlight app guide, a competitive
event catalogue that shapes the UI, dual daily goals, an ambient light field behind every screen —
and, as of `v8-content`, a bank that can actually sustain the retention curve the app was built
around: 600 questions where every option is explained, not just the correct one.

Debug and Release both build clean with zero warnings, and both content validators pass.

**Nothing since `v5-immersive` has been run on a physical device.** That is now the largest
unverified surface in the project by a wide margin, and it is §9 item 2 for a reason.

Two things worth knowing before touching this again:

- **Distractors are the teaching surface.** The rationales name the *specific* error — "65% is
  markup on cost, not on selling price", "$9,000 is subtracting 10% where present value requires
  dividing by 1.10". Anything added to the bank should hold that bar; filler distractors would
  quietly undo the reason the bank was rewritten.
- **Content selection is cluster-keyed, never event-keyed.** Ontario's 50 events map onto 6
  clusters, so authoring per event produces near-duplicates rather than variety. Roleplays are
  written per cluster × event *format* instead, which is what gives a student Principles, Series,
  Team Decision Making and Professional Selling shapes rather than the same case repeatedly.
