# Glass

**Glass** — an offline-first DECA Ontario study companion for iPhone. No sign-in, no network
requests, no analytics — every question, answer and statistic stays on the device.

## Requirements

| | |
|---|---|
| Deployment target | **iOS 16.0** (covers iPhone 8, whose last OS is 16.7.x) |
| Language | Swift 5 / SwiftUI |
| Persistence | Core Data with a **programmatic** model (no SwiftData, no `.xcdatamodeld`) |
| Optional AI | Apple **Foundation Models** (`SystemLanguageModel`), iOS 26+ only, availability-checked |
| Widgets | WidgetKit extension, `DECAStudyWidget` |
| Notifications | `UserNotifications`, local only |

## Targets

- **LCVI DECA Study App** — the app.
- **DECAStudyWidget** — home-screen widgets (daily progress, streak, questions
  remaining, quick launch).

Both use `PBXFileSystemSynchronizedRootGroup`, so any `.swift` file dropped into
`LCVI DECA Study App/` or `DECAStudyWidget/` is compiled automatically.

## Project layout

```
LCVI DECA Study App/
  Core/          design system, haptics, motion
  Models/        domain value types, Core Data stack, settings, streak state
  Data/          bundled sample questions, roleplays, indicators, Quick Think
  Services/      one service per concern + AppStore (the coordination point)
  Components/    reusable UI (rings, answer buttons, badges, timers…)
  Views/         Onboarding, Today, Practice, MockExam, Roleplay, Progress, Settings
DECAStudyWidget/ widget bundle + a self-contained copy of the shared snapshot type
Config/          entitlements + Info.plist fragments for both targets
```

`AppStore` owns the persistence stack and every service. `AppStore.recordAnswer`
is the single pipeline every answered question flows through — spaced repetition,
indicator mastery, the Mistake Notebook, daily progress, streaks, achievements
and the widget snapshot all update from that one call.

## AI rules enforced in code

`FoundationModelFeedbackService` is the only place that touches the model.

- The **correct answer never comes from the model.** It is read from the local
  question bank and handed to the model as a stated fact; the model only explains.
- Every entry point returns `nil` on failure, and each caller has an offline
  fallback (stored explanation, or a manual rubric / structured self-check).
- Availability is re-checked on launch, on foreground and from Settings, and maps
  to the five statuses shown in Settings ▸ AI feedback.
- On iOS 16–25, or any device without Apple Intelligence, the framework is never
  called and the app behaves exactly as it does with AI disabled.

## App Group (widgets)

The app and the widget share `group.com.shailpatel.LCVI-DECA-Study-App`
(`Config/App.entitlements`, `Config/Widget.entitlements`). The app writes a small
JSON snapshot there; the widget reads it.

If automatic signing can't create that App Group for your team, the app still
builds and runs — `UserDefaults(suiteName:)` falls back to the app's own defaults
and the widget shows placeholder content. To drop widgets entirely, remove
`CODE_SIGN_ENTITLEMENTS` from both targets.

The Core Data store deliberately lives in Application Support, **not** in the
group container, so changing entitlements can never strand a student's progress.

## Deep links

The app registers `decastudy://` (`Config/App-Info.plist`):

- `decastudy://practice` → Daily Practice
- `decastudy://cram` → Exam Cram

## Content

The bundled questions, roleplay scenarios, Quick Think prompts and performance
indicators are **original sample practice material written for this app**. They
are not official DECA Ontario or DECA Inc. competition content — check the current
competitive event guidelines for your event. Students can replace or extend the
bank from Settings ▸ Question Bank Manager (manual entry, bulk paste, CSV, JSON)
and export a backup at any time.

## Verifying on an iPhone 8-sized screen

There is no iPhone 8 simulator runtime for iOS 26, but iPhone SE (3rd generation)
has the identical 375×667 layout:

```bash
xcrun simctl create "iPhone SE 3" com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation com.apple.CoreSimulator.SimRuntime.iOS-26-5
```
