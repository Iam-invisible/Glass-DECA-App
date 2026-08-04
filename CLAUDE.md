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

**First three commands of any session**, before proposing anything:

```bash
git status --short && git log --oneline -8
python3 Scripts/check_questions.py && python3 Scripts/check_roleplays.py
xcodebuild -project "LCVI DECA Study App.xcodeproj" -scheme "LCVI DECA Study App" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug clean build 2>&1 | grep -E "error:|warning:|BUILD" | grep -viE "AppIntents|metadata extraction"
```

Branches may be ahead of their remotes; §10 has the inventory and what each branch is for.

---

## 1. What the app is

**Glass** — an offline-first DECA Ontario study app for high-school students.

- Swift + SwiftUI, **iOS 16.4** deployment target. It was 16.0; llama.cpp's XCFramework is
  built for 16.4 and binds at launch, so a 16.0 target would have failed to start on 16.0–16.3.
  The iPhone 8 requirement survives — that device runs iOS 16.7.
- **Four panes: Study · Progress · Shop · Settings** (six tabs → three → four; see §4 and §6)
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
- **Write UI copy plainly. No poetry.** This was asked for explicitly after the onboarding and
  the walkthrough drifted into a register that sounded good and told a student nothing —
  "Your corner crew" for a reminder toggle, "freezes protect it when life happens" for a rule
  the student then had to work out themselves. Headings name the action; body text says what
  the control does and what changes as a result. The one exception is the intro prologue's
  three lines, which are a title sequence and were kept deliberately.

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
- **Choices are shuffled per presentation** (`Models/ChoiceOrder.swift`). The bank's order is
  canonical and never moves; `presented(salt:)` deals a throwaway copy carrying the map back.
  Shuffled in exactly two places — `PracticeRunner.init` (every practice route arrives as a
  `BuiltSession`) and `MockExamService.buildExam` — and converted back in exactly two —
  `AppStore.recordAnswer` and `saveAttempt`. No schema change, and review screens re-fetch from
  the bank so they read canonical. See §8.37.
- **`AppStore`** (`Services/AppStore.swift`) is the single coordination point injected as
  `@EnvironmentObject`. Services are plain types it owns.
- **Launch flow** in `RootView`, in order: `IntroView` → **privacy consent gate** (shown while
  `!settings.hasAcceptedCurrentPrivacyPolicy`) → `OnboardingView` → `main`. The gate sits after
  the intro so its choreography is never interrupted, and before onboarding because onboarding's
  first act has the student answering a real question, which is using the app.
- **Navigation intents** live on `AppStore`: `requestedTab`, `wantsQuestionBank`,
  `wantsMistakeNotebook`, `wantsMockExam`, `showGuide`, `guideFocus`. Consumed with a
  **reset-then-act** pattern — flip local state *after* mount, because a `navigationDestination`
  already true at first render does not push reliably on iOS 16.
- **Four panes.** `Study` absorbed the old Today + Practice launchers. Mock Exams, Roleplay and
  the Library (the old Practice tab's browse section) keep their entire screens and are **pushed
  from Study's tiles**. `Shop` was added later (§6a). Nothing was deleted in either restructure —
  the map was redrawn.
- **Two overlay layers use the same host-claiming trick**, and they must stay in step.
  `CelebrationLayer` and `BunnyLayer` both exist because a `fullScreenCover` draws above anything
  the root can (§8.4): each full-screen flow calls `.celebrationLayer(isFullScreen: true)` **and**
  `.bunnyLayer(isFullScreen: true)`, and the root stands down while `store.fullScreenLayers > 0`.
  The host sets are currently identical — four flows — and a new full-screen flow should claim
  both or neither.
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
  shared app group, and bundles its own copies of the app's fonts. `WidgetSnapshot` is
  **duplicated verbatim** in both targets — the extension cannot import the app. Its decoder is
  hand-written with `decodeIfPresent` so a payload from an older build still decodes rather than
  throwing and blanking every widget.
- **Deep links** are `decastudy://` and the switch in `LCVI_DECA_Study_AppApp.swift` is the only
  reader: `practice`, `cram`, `review`, `mistakes`, `quickthink`. Keep in step with `WidgetLink`.
- **Files worth knowing about**: `Models/InputSanitizer.swift` (§8.26),
  `Data/PrivacyPolicy.swift` (notice as structured data, plus `version` and `hostedURL`),
  `Components/PrivacyPolicyBody.swift` (shared by the gate and Settings so the two cannot
  disagree), `Services/LlamaCoachEngine.swift`, and `Scripts/check_questions.py` /
  `Scripts/check_roleplays.py` (§11).

---

## 5. Design system

**Typography** — `Core/DesignSystem.swift`, fonts in `LCVI DECA Study App/Fonts/`, registered via
`UIAppFonts` in `Config/App-Info.plist`. The widget bundles its own copies in
`DECAStudyWidget/Fonts/` registered in `Config/DECAStudyWidget-Info.plist`.

- **Display: Michroma** — extended geometric, replacing Instrument Serif. A serif at 19–22pt read
  as body text set larger and the heading level stopped announcing itself; Michroma's wide
  letterforms cannot be confused with the Manrope beneath them.
  **Its width governs every display size.** Michroma averages 0.719 em per lowercase letter
  against Instrument Serif's 0.392 — 1.87× — so the old 38/26/22 ladder overflowed. Any future
  display face needs the ladder re-derived from its own width, never inherited.
- **Michroma Bold is generated, not shipped by the foundry.** Michroma has one cut and no variable
  axis, so `Michroma-Bold.ttf` was produced by stroking every outline 95/2048 em with a round join
  and unioning it back — stem 0.094 em → 0.141 em. Advances are untouched, so it drops in without
  moving layout. Michroma declares no Reserved Font Name, so the OFL permits it. **Do not try to
  get bold with `.weight(.bold)`** — see §8.27.
- **Text: Manrope** (Regular / Medium / SemiBold) — chosen on measurement, not taste: largest
  x-height of 14 candidates (0.540) and second most compact, and it ships `tnum`.
- **Script: Sacramento** — intro wordmark only. Never set UI text in it.
- Roles: `.appLargeTitle` (32), `.appTitle` (22), `.appSectionTitle` (19) and `.appTileTitle` (16)
  — all four Michroma **Bold** — plus `.appHeadline`, `.appBody`, `.appBodyMedium`, `.appCallout`,
  `.appFootnote`, `.appCaption`, `.appCaptionBold`, `.appQuestion`, `appSans(_:weight:)` and
  `numeric(_:weight:)` in Manrope.
  `appTileTitle` exists because `ModeTile` borrowed `appSectionTitle` and Michroma is wide enough
  that "Mock Exams" overflowed an iPhone SE tile: three of six tiles were being shrunk by
  `minimumScaleFactor` and three were not, so one grid rendered its labels at four sizes. 16 is the
  largest that clears the box outright.
- **The hierarchy rule: serif is always a heading, Manrope is always content.**
- OFL licences ship alongside every font. Keep them.

**Colour — blue-grey** (`Palette`, `Core/DesignSystem.swift`). Light/dark pairs.

A warm-paper palette (`#FAF7F2` surfaces, warm dark `#14110D`) was built and then **reverted on
request** — the original blue-grey is what ships. `git show 2d9d758` is the warm version if it is
ever wanted back.

Reverting restored three cluster-tint collisions that the warm palette had fixed, and they are
worth knowing rather than rediscovering. Measured as RGB distance over the 0–441 range:
marketing's tint **is** the accent, byte-identical in both schemes; hospitality's dark tint **is**
the streak gold, byte-identical; personal finance sits 7.1% from the correct-answer green.
Accents carry meaning here — blue = progress, green = correct, red = wrong, gold = streaks — so
those two zeros are a legibility bug, not a taste one. Left in place because the revert was the
request; the six tints can be nudged off the accents without touching the surfaces.

The accent — and only the accent — is themeable from the Shop. `Palette.accentTheme` is a `var`
set at launch from settings, and `accent`/`accentSoft` are computed from it. The meaning colours
stay fixed: a student able to repaint "correct" as red would be buying a legibility bug. The
widget keeps its own accent and does not follow the theme.

The palette is duplicated in three more places that do not import the app and must be changed
in the same commit: `DECAStudyWidget/WidgetShared.swift`, `web/app.css` plus the `CLUSTERS` list
in `web/app.js`, and the hosted privacy page on `gh-pages`. `AmbientCanvas` needs nothing — it
derives from `Palette`.

`strokeGlint` is the lighter top edge of a card's gradient border.

**Spacing** — `Metrics`: gutter 18, cardRadius 18, controlRadius 14, rowMinHeight 52,
**headerGap 10, stackSpacing 14, sectionSpacing 32**.

The last three are a hierarchy, not three numbers: `headerGap` binds a `SectionHeader` to what it
names, `stackSpacing` separates peers inside a group, `sectionSpacing` separates groups. **Keep
header < peer < section.** A screen that uses one gap everywhere is the failure mode — the eye has
nothing to group by and a heading floats as far from its own content as from the section above.

**Cards group lists; single figures float.** Study's today panel, Progress's today block and the
week chart are all off their cards; the sections that are lists of rows kept theirs.

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

**Study (home)** — an **`EventTag`** (the cluster's icon and the event code the student says out
loud, "EIP") above the header, then **`TodayPanel`**: the day as one segmented semicircle with the
figure seated in its well, then a card per goal, then the streak card. The ring is
cut into a segment per item — questions first, then Quick Think — because a smooth track says how
far through you are and segments say what one question is worth. The figure beside it shows what
is **left**, not what is done, tinted to whichever goal is still open.

It was a 176pt ring inside a 244pt bloom, about 243pt of the roughly 500pt an iPhone 8 shows above
the fold, spent on a number the line under the title and both cards already stated. The ring's
argument was never its size — one object means one day, and a segment per item says what a
question is worth. `SegmentedDayArc` keeps both for 125pt — half a ring, because the bottom
half was holding nothing and the well is where the figure goes. The figure is set at
60pt rather than the 46pt it used inside a ring, centred, over the same bloom the ring sat in — a
`background` rather than a stack child, so 230pt of wash costs nothing in layout — and 26pt of
clear space beneath it. Isolation and size are what make it lead; the ring's diameter never was. The daily goal goes to 100, so the gap is a
share of one segment rather than a fixed slice — every segment keeps 70% of its own span at any
count, and the arc never degrades into a dotted line.

The arc insets by half its line width before trimming. `.stroke` centres the line on the path
(§8.18), so uninset it paints 7pt of arc above its own frame and into the header. Below that a `ModeTile`
garden of six squares (Review Due, Mistakes, Mock Exams, Roleplay, Exam Cram, Bookmarks) plus a
full-width **Library** banner, then one insight card. Tile affordance rule: **a count means it
launches, a chevron means it navigates.** Both goal targets are still set with steppers in
Settings. `GoalDial` was deleted; `TodayPanel` + `SegmentedGoalRing` replaced it.

The header states where the day stands — "Start today", "Keep going", "Nearly there", "Done
today" — rather than the time of day, which is the one fact on that screen the status bar already
carries. The line beneath it names what is left across *both* goals, and leads with the streak when
there is one to protect. All four titles hold one line at 32pt Michroma to at least 134% Dynamic
Type on an iPhone 8, which is what stops the header changing height as the day is worked through;
"Done for today" reads better and wraps at 112%.

The two goal cards carry the app's card treatment — opaque fill, gradient border, shape shadow —
tinted to their goal rather than filled flat, because a bare wash of tint was a surface nothing
else in the app uses. `appCard` can't express it and shouldn't learn to: its fill is one colour,
and a translucent tint would put the shadow through the card instead of under it. The tint tracks
the goal, never whether it is met — the glyph reports that.

The **streak card** is deliberately not a third goal card: wider radius, gold gradient, a bloom
behind the flame, the count set as a figure, and a ten-segment track for the freeze it is working
toward. It animates once when a streak is collected — flame pop, a ripple that only ever travels
outward, and the border brightening. `AppStore.pendingStreakCelebration` holds the moment rather
than firing it, because a streak always advances inside a `fullScreenCover`; Study passes it to
the panel only while `fullScreenLayers == 0`, so it plays to somebody.

**Progress** — the analytics pane: accuracy, PI mastery, cluster breakdowns, achievements. Carries
the same `EventTag` above its title.

`EventTag` is the *only* thing that may sit above a `ScreenHeader` title. The eyebrow that used to
live there carried scope — the cluster filter, "All clusters", an attempt count — and was removed
everywhere as chrome. The event is different: it is what the student is training for, and these
are the two screens about how that is going. Undecided falls back to the cluster name, which reads
as plainly not an event code. Measured against the coin HUD on an iPhone 8: 246.5pt of clear
space, the widest tag is 149.9pt, and it still clears at the largest Dynamic Type caption step.

**Shop** — what coins buy. See §6a.

**Settings** — cluster, competitive event (`EventPicker`), both daily goal steppers, reminders,
AI status + local coach, question bank manager, import/export, appearance, intro style (the locked
one carries a padlock and routes to the Shop), replay guide, and **Erase everything** — which now
also deletes the 808 MB model and resets the wallet, and says so.

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

---

## 6a. Coins, the Shop, and the bunny

**Coins are minted in exactly four places**, all in `AppStore`, and never bought with money —
that would mean StoreKit, receipts and a restore path, and restore needs an account the app does
not have. Rates live in `CoinRate` beside the prices they have to be read against: **1** per
answer, **3** for a correct one, **15** a daily goal, **50** a ten-day streak mark, **25** an
achievement. About **39 a day** at a 10-question goal and ~70% accuracy. Tapping the balance opens
`CoinGuideOverlay`, which reads every figure from `CoinRate` rather than repeating it.

**The coin badge is a HUD** pinned in `RootView` on Study, Progress and Shop — not Settings,
where a balance reads as a nag.

**The Shop sells only cosmetics.** The moment a purchase changes what questions you get or how
they are marked, it stops being a reward and becomes a tax on learning. Five categories:
companion, icons, themes, intros, sounds.

- **Icons** — one free glass **G** on solid black, plus two *packs* and a standalone. A pack is an
  item with `unlocks`, bought once, granting its members; members are priced 0 and hidden behind
  `packMember` until their pack is owned, and the pack itself disappears from the list once bought.
  Pastel pack 700 (Rose/Mint/Lilac), Glow pack 900 (Cyan/Magenta/Amber/Violet), Rainbow 1200 —
  white glass with a Google-arc halo. All generated by `Scripts`-adjacent Python in the scratchpad;
  the letter spans `G_WIDTH = 0.60` of the canvas, one constant so the family cannot drift.
- **Themes** recolour the accent only. **Intros** drive `introStyleRaw`; Etched is the free default
  and Script is bought. **Sounds** are a filename suffix with per-file fallback, so a half-populated
  pack degrades to the default tone rather than to silence.
- **Every shop row opens `ShopPreviewOverlay` before it can be bought** — the real icon masked at
  Apple's 22.37% corner, the theme on a real ring and button, the intro's own lettering, the sound
  played out loud. Buying happens in that card. Tapping a swatch and being charged was the thing
  this replaced.
- **Promo codes** in `PromoCode`: `GLASSUNLOCK` owns everything and tops up, `GLASSRESET` puts it
  all back. Not a security boundary — see §8.30.

**The bunny** (`Bunny.swift`, `BunnyCompanionView`) is a 600-coin companion in the bottom-right of
every screen. 22 sprites in `Resources/Bunny/`. Three events carry *what happened* rather than just
that it happened — `correctAnswer(run:)`, `wrongAnswer(run:)`, `mockFinished(percent:)` — so a run
of three earns the big face and one right answer does not, and a mock scored 12% does not draw the
same face as one scored 95%. Two rules it must keep: **celebration climbs with the size of the
thing**, and **nothing aimed at the student is ever harsher than concern**. It never appears on the
intro, the privacy gate or onboarding, and never takes a touch.

---

**Web preview** — `index.html` + `web/` at the repo root: a static recreation of the app for
browser viewing, deployed from the `web-only` branch. Not part of the iOS target.

---

## 7. The local AI coach — read before touching

`LocalModelService` offers an optional **808 MB** download of Llama 3.2 1B Instruct (Q4_K_M),
Wi-Fi enforced at the socket, SHA-256 pinned, excluded from backup, deletable. It is offered
**only** where Apple Intelligence is unavailable.

**Both tiers now work.** `CoachEngineFactory` builds the engine, `AppStore` attaches it whenever
the model file is present, and `FoundationModelFeedbackService.generate()` falls through to it
when Apple's model is out of reach — so explanations, roleplay coaching and Quick Think feedback
all reach it through the funnel they already used. Weights are freed on `.background`, not
`.inactive`, because dropping a gigabyte every time someone opens Control Centre would cost more
than holding it.

`AIAvailability` gained a sixth case, `.localCoachAvailable`, so Settings can say the local coach
is running instead of reporting the device unsupported while AI visibly works. The five required
status strings (§4) are untouched.

**The runtime is in and compiling.** `mattt/llama.swift`, pinned at exactly `2.10199.0`, product
`LlamaSwift`, added to the app target. **Not `ggml-org/llama.cpp`** — that repo has no
`Package.swift` and Xcode refuses it; that wrong URL sat in this brief for months. llama.swift
wraps llama.cpp's own precompiled XCFramework, so nothing builds from source and the C API is
upstream's. Its minor version *is* llama.cpp's build number (`2.10199.0` ≙ `b10199`), which is
why the pin is exact — "up to next major" would accept any future llama.cpp build.

`LlamaCoachEngine` is guarded by `#if canImport(LlamaSwift) || canImport(llama)`, so a direct
XCFramework drop-in also works.

**The offer is gated on `CoachEngineFactory.canRunLocalModel`**, not on a hand-set flag. No
runtime linked means no offer, because a student who downloaded 808 MB and got nothing back is a
feature that does not function — a plausible App Review rejection. Adding the package switches
the offer back on by itself, and a model stranded by an earlier build is deleted on launch.

**Never executed on hardware.** It compiles and the Swift wiring is sound, but no `llama_*` call
has ever run. Device testing has to answer four things: does the GGUF load, is a 1B model's
output actually usable, is first-token latency short enough that a student waits, and does the
app survive ~1 GB resident on a 4 GB phone.

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
23. **`.kicker()` and `.appKicker` do not exist.** §5 of this brief listed them as design-system
    roles for years and they were never in the code. Eyebrow text is `.appCaptionBold`.
24. **llama's sampler chain is `UnsafeMutablePointer<llama_sampler>?`, not `OpaquePointer`.**
    The model and context handles really are opaque; the sampler is typed *and* optional.
    Mixing them up was the only thing that failed to compile on the first llama build.
25. **An annotated tag is a tag object wrapping a commit, and a branch must point at a commit.**
    `git push versions refs/tags/X:refs/heads/X` therefore sends the wrong object type. GitHub
    rejects it with an unexplained `! [remote rejected] (failed)` and **`--dry-run` does not
    catch it**, because the check is server-side. Dereference with `^{}` — see §10.
26. **`bank.add`/`bank.update` sanitise; nothing else may write a question.** An imported
    `correctIndex` of 5, or three choices instead of four, decodes happily and then indexes out
    of bounds in `explainAnswer` — tapping "Explain with AI" crashed the app. `InputSanitizer`
    fixes this at that one boundary, which is why all four write paths must keep going through
    those two methods.
27. **`Font.custom(...).weight(.bold)` does nothing on a single-weight family.** Weight resolves
    *within* a family, and a family of one resolves back to itself — no synthesis, no warning, no
    changed pixels. It compiled and looked deliberate for a whole commit. Michroma Bold had to be
    generated (§5).
28. **A zero-height view is still a stack child and collects spacing on both sides.** Cost twice:
    `ScrollOffsetProbe` as the first item of a `VStack(spacing: 32)` pushed every screen's header
    down by a full section gap (now applied as `.scrollOffsetProbe()`, an overlay), and a `VStack`
    wrapping two failed `if`s would have left 48pt of empty column. Guard the *contents* before
    building the container, not after.
29. **`Path.intersection` is iOS 17.** The floor is 16.4, so half-ellipses are built from a
    transformed unit arc instead (`HalfEllipse` in `HamsterAvatar`).
30. **Swift stores string literals of ≤15 UTF-8 bytes inline, not in `__TEXT,__cstring`.** So
    `strings` will not print `GLASSUNLOCK`, but that is an accident of length rather than
    protection — a 16-byte code *would* be plain text, and either way a debugger finds it in
    minutes. Verified against the Release binary. Never gate anything behind a promo code that
    would matter if bypassed.
31. **`isReady` must mean "loaded *or loadable*".** `LlamaCoachEngine` reported only "loaded", and
    since `isUsable` gates `generate()`, `generate()` is the only caller of `loadIfNeeded()`, and
    `loadIfNeeded()` was the only thing that set the flag, it could never become true on any
    device. A student downloaded 808 MB and Quick Think still offered the self-check. A failed load
    latches so a corrupt model reports unavailable rather than promising AI and returning nothing.
32. **Xcode `pngcrush`es loose alternate-icon PNGs into Apple's CgBI variant.** iOS reads it
    natively; PIL and most tools cannot. A bundled alternate icon that looks corrupt is not.
33. **`actool` merges its primary icon into a hand-written `CFBundleIcons` dict.** With a manual
    `CFBundleAlternateIcons` present, `CFBundleIconName` lands *nested* under `CFBundlePrimaryIcon`
    rather than at the top level. Check the nested path before concluding the primary icon is
    missing.
34. **A local `AVAudioPlayer` is deallocated the moment the function returns** and never makes a
    sound. `SoundEffects.preview` holds its own player in a property — its own, so auditioning a
    pack in the Shop cannot evict the cached cues or leave the wrong pack loaded.
35. **Swift's `Hasher` is salted per process, so `hashValue` differs between launches.** Anything
    that has to reproduce a result later — a shuffle a review screen replays, a deterministic
    seed — needs its own stable digest. `UUID.stableSeed` in `ChoiceOrder.swift` is FNV-1a over
    the sixteen bytes for exactly this reason. `SystemRandomNumberGenerator` cannot be seeded at
    all, hence `SplitMix64`.
36. **Fixing "the correct answer is the longest" by lengthening one distractor creates a worse
    tell.** It drops the longest rate below chance and parks the answer at second-longest, which
    a student reads as "never the longest" — a free elimination — or "always in the middle",
    which narrows four options to two. Hospitality went 87% → 8% longest and 61% second before
    this was caught. The measure that does not lie is the *rank* spread, and it has to be levelled
    in all four directions at once. Terminology questions have a floor: the BCG cells are "cash
    cow", "star", "question mark" and "dog", and padding those to match wrecks the question.
37. **A presented question is not a storable question.** `QuestionData.canonicalOrder` records the
    shuffle applied for one presentation and is deliberately outside `CodingKeys`, so an export
    carries the bank's order rather than one student's deal. The two funnels that persist an
    index — `AppStore.recordAnswer` and `MockExamService.saveAttempt` — call `.canonical()` and
    `.canonicalIndex(for:)` first. Writing a presented copy straight to Core Data would reorder
    the stored choices and silently invalidate every earlier answer's `selectedIndex`.

---

## 9. Pre-submission punch list — the live work

**Still open**

1. **Fill in `[INSERT YOUR LEGAL OR TRADING NAME]`.** Still live and **publicly visible** on
   `gh-pages` at `index.html:110`, and in `~/Desktop/Glass-Privacy-Notice.pdf`. The in-app copy
   does not carry it. Should match the seller name in App Store Connect.
2. **The local AI coach has been run on hardware exactly once, and it failed.** Two bugs were
   found and fixed from that one report (§8.31, plus the engine only being attached at launch or
   on foreground). **It has not been re-tested since.** The three questions §7 has always asked are
   still open: does the GGUF load, is first-token latency short enough that a student waits, and
   does a 4 GB phone survive ~1 GB resident. An iPhone 12 is the device it failed on.
3. **Everything added since `v9-pre-michroma` is unverified on device** — roughly forty commits,
   including a whole fourth tab. Highest risk first:
   - The Shop end to end: buy, preview, apply an alternate icon, redeem a promo code.
   - Michroma at every size, and the generated bold, on a real panel.
   - The tab bar at 10pt clearance, which deliberately lets the home indicator graze the capsule.
   - The coin HUD clearing every screen title.
   - The Core Data lightweight migration adding four `rationale*` attributes — still never
     exercised old-build-over-new.
4. **Check App Store metadata for DECA trademark exposure.** The in-app disclaimer is solid; the
   store listing is a separate surface. Avoid "DECA" leading the app name, subtitle or keywords.
5. **One open catalogue question.** Whether Series, Principles and Team Decision Making run their
   roleplay *at regionals*. Left as exam + roleplay at both levels — the error that over-prepares.
   Worth one question to an advisor. Flagged in `DECAEvents.swift`'s header.

**Closed since `v9-pre-michroma`**

- Instrument Serif → Michroma, with a generated bold and a width-derived size ladder.
- The warm paper palette, reverted on request.
- A spacing hierarchy (`headerGap`/`stackSpacing`/`sectionSpacing`) and a de-carding pass.
- The PI heatmap folded into the indicator list; the recent-achievement card removed.
- Coins, the Shop, packs, promo codes, previews, and the bunny companion.
- The app icon rebuilt as the glass G, with two packs and a rainbow.
- Intro audio now stops when the intro is skipped; freezes cap at two.
- "Erase everything" now erases the model and the wallet, and says so.
- The local coach's two activation bugs.
- Both answer tells: choices now shuffle per presentation, and all 600 questions were
  rebalanced so length no longer points at the answer. `check_questions.py` gates both.

**Candidate for removal**

- The **intro style toggle** is now a shop item rather than a free setting, which gives the second
  intro a reason to exist. This is closed unless the shop item is dropped.

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
| `v9-pre-michroma` | The last build with Instrument Serif and the warm paper palette. **Local only — not yet pushed to either remote.** |

Branch `rebrand-glass-edge` parks an abandoned cyan rebrand the user rejected — do not
resurrect it without asking. Current work is on `v7-events-goals`.

**Branches, and what each is for.** Three of these are deployment branches rather than code, and
being "behind" the app is correct for them, not staleness:

| Branch | Purpose |
|---|---|
| `v7-events-goals` | **Current work.** Everything below is downstream of it. |
| `main` | 54+ commits behind. Has no `index.html` and no `web/` — the preview never lived here. |
| `gh-pages` | **Orphan, no shared history.** Serves the privacy notice and nothing else, so the published URL cannot land on a stale app preview. `index.html` is canonical; `privacy.html` redirects to it; `.nojekyll` skips Jekyll. |
| `web-only` | The interactive preview, deployed separately. Older than the app — it will not show the 600 questions or the warm palette. Refresh before linking it publicly as a demo. |
| `rebrand-glass-edge` | Abandoned. Do not resurrect without asking. |

GitHub Pages serves **`gh-pages` at root** → `https://iam-invisible.github.io/Glass-DECA-App/`,
which is the URL compiled into `PrivacyPolicy.hostedURL` and given to App Store Connect. Pointing
Pages at `web-only` instead puts the preview at the privacy URL — that was tried and reverted.

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
`correctIndex`, which compiles perfectly and teaches the wrong answer.

It also gates the **shape** of the choices, which is a tell rather than an error and so is
invisible to everything else. The bank once answered B in 502 of 600 questions and put the
longest choice on the right answer often enough that "always pick the longest" scored **80.5%**.
The gate is the correct answer's length *rank* — longest, second, third, shortest — which has to
come out near 25% each; each figure is also the score of "always pick the Nth longest", so the
table reads as what a student could get without reading. Gating on the longest rate alone is not
enough and is how the bank acquired a second tell while the first was being fixed (§8.36). `check_roleplays.py` fails
if a cluster collapses back to a single event format, which is the regression the roleplay
rebuild existed to fix.

---

## 12. Current state

Four panes, Michroma throughout with a generated bold, the blue-grey palette, a spacing hierarchy,
a coin economy with a Shop that previews before it charges, a reacting companion, and an app icon
family built from the same letterform.

Debug and Release both build clean with zero warnings, and both content validators pass.
Uncommitted work: none. Unpushed: check `git status` and both remotes (§10) — `v9-pre-michroma`
in particular is local only.

**Nothing since `v5-immersive` has had a full device pass**, and about forty commits have landed
since `v9-pre-michroma` alone. The single hardware report so far — an iPhone 12 — found two real
bugs in the local AI coach, which is a fair indication of what a proper pass would turn up.

Five things worth knowing before touching this again:

- **Copy is plain, deliberately.** See §3. Do not let it drift back.
- **Distractors are the teaching surface.** The rationales name the *specific* error — "65% is
  markup on cost, not on selling price". Anything added to the bank should hold that bar.
- **Content selection is cluster-keyed, never event-keyed.** Ontario's 50 events map onto 6
  clusters; authoring per event produces near-duplicates rather than variety.
- **The shop must stay cosmetic**, and the bunny must never be harsher than concern (§6a). Both
  are one bad commit away from making a study app feel like it is judging the student.
- **The hamster is parked, not deleted.** `ShopFeatures.hamsterEnabled = false` gates a complete,
  working vector avatar with 24 cosmetics across five slots. Flipping it back on restores the
  character; it is off only because the app ships without artwork for it. A prompt for generating
  that artwork, matching the existing anchor coordinates, was written and is worth reusing.
