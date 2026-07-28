# Prompt — Build a live web preview of Glass

> Paste this into a new Claude Code session, in an **empty folder** (not the iOS repo).
> Read the "What this actually is" section first — it corrects a common wrong assumption.

---

## What this actually is

Glass is a **SwiftUI iOS app**. SwiftUI cannot run in a browser, and Vercel cannot execute an iOS
binary. So this is **not** "hosting the app" — it is building a **faithful web replica** of it: a
separate Next.js site that reimplements the app's screens in HTML/CSS/JS so anyone can click
through it from a link.

Be honest about that in the UI. A small line reading *"Interactive preview — a web recreation of
the iOS app"* is required. Never imply the visitor is running the real build.

The tradeoff to accept: the replica will drift from the iOS app as that app changes. Keep the
design tokens in one file so re-syncing is editing constants, not hunting through components.

---

## Your task

Build a Next.js site that presents Glass inside a phone frame, running as a clickable prototype,
and deploy it to Vercel's free tier.

**Stack:** Next.js (App Router) + TypeScript. No backend, no database, no auth — all state is
client-side React. Static export is fine.

---

## Device frame — and why there are two

The frame must be **switchable**, because the single hardest requirement of the real app is that
it looks *the same* on the oldest supported phone and the newest:

| Preset | Logical points | Scale | Top safe area | Bottom safe area |
|---|---|---|---|---|
| **iPhone 17** | 402 × 874 | @3x | 59 pt (Dynamic Island) | 34 pt (home indicator) |
| **iPhone 8** | 375 × 667 | @2x | 20 pt (status bar) | 0 pt (home button) |

Put a visible toggle between them. Being able to flip an iPhone 17 to an iPhone 8 and watch the
layout hold is the single most useful thing this site can do.

Verify those numbers against Apple's current device specs before hardcoding them — device metrics
change and I don't want invented values baked in.

Draw a realistic but restrained device shell: correct corner radius, Dynamic Island on the 17,
a status bar with a plausible time / signal / Wi-Fi / battery, and the home indicator. On a
desktop viewport, centre the phone on a neutral backdrop. On a real phone, drop the frame and let
the app fill the screen.

---

## Design system — match it exactly

**Fonts.** Unlike a sandboxed artifact, this site *can* load the real faces. Use `next/font/google`:

- **Instrument Serif** (400) — display only
- **Manrope** (400, 500, 600) — everything else

That means the type will be exact rather than approximated. Do not substitute.

| Role | Face | Size |
|---|---|---|
| appLargeTitle | Instrument Serif | 38 |
| appTitle | Instrument Serif | 26 |
| appQuestion | Manrope 600 | 20 |
| appHeadline | Manrope 600 | 17 |
| appBody | Manrope 400 | 17 |
| appCallout | Manrope 400 | 16 |
| appFootnote | Manrope 400 | 13 |
| appCaption | Manrope 400 | 12 |

**Colour** — light / dark pairs. The site must support **both**, following the OS preference with
a manual override:

| Token | Light | Dark |
|---|---|---|
| canvas | `#F4F6FA` | `#0D1219` |
| card | `#FFFFFF` | `#161E29` |
| cardSunken | `#EDF1F7` | `#111823` |
| stroke | `#E2E8F0` | `#27313F` |
| strokeStrong | `#CBD5E1` | `#33404F` |
| textPrimary | `#0F1B2D` | `#F2F5F9` |
| textSecondary | `#53627A` | `#9AA8BC` |
| textTertiary | `#8A97AB` | `#6C7A8D` |
| accent | `#2563EB` | `#5B8DEF` |
| accentSoft | `#E4EDFF` | `#1B2942` |
| success | `#12855C` | `#34C793` |
| gold | `#B07407` | `#E8B14A` |
| danger | `#C8342F` | `#F2645F` |
| inactive | `#B4BECC` | `#3C4757` |

Accents carry meaning only — blue = progress, green = correct, red = wrong, gold = streaks and
achievements. Never decorative.

**Spacing.** Gutter 18. Card radius 18, control radius 14. Row min-height 52. Stack spacing 14,
section spacing 24. Cards are an opaque fill, a 1px `stroke` border, and a *soft* shadow on the
shape.

**Motion.** Springs, not linear easing: `snappy` ≈ 340 ms / damping .78 · `gentle` ≈ 500 ms / .85 ·
`bouncy` ≈ 420 ms / .60 · `quick` ≈ 180 ms ease-out. Framer Motion is a reasonable way to get
spring physics; plain CSS transitions are acceptable if you keep the feel. **Honour
`prefers-reduced-motion`.**

---

## What to build

**1. The launch reveal.** The word *"glass"* is handwritten in a monoline script (Sacramento),
stroke by stroke, then floods with light into solid glass tubing.

The iOS version works by running a wide round-capped stroke along the pen's centreline and using
it as a **mask** over the real letterforms — so what appears is always the true letter shape, and
the mask only decides how much has been written. Do the same in SVG: a `<path>` of the centreline
animated with `stroke-dasharray` / `stroke-dashoffset`, used as a `<mask>` over the filled word.
Tracing the glyph outline instead draws the *edges* of the letters, which is wrong.

Roughly 2.3 s to write, then the fill blooms. Skippable on tap.

**2. Onboarding** — one continuous scrolling surface, not a carousel. Each question opens as a
card, is answered, then collapses into a compact summary line that stays visible; the next opens
beneath. The column itself is the progress indicator. Every answered step is reopenable. Steps:
DECA cluster (six options), daily question goal (1–100, default 10), daily reminder (on/off plus a
time), and AI coaching status. Skippable in one tap.

**3. The six tabs**, reachable from a floating capsule tab bar: **Today, Practice, Mock Exams,
Roleplay, Progress, Settings.** Each opens with its own large Instrument Serif header carrying an
"eyebrow" line above it stating what the screen is scoped to.

Populate with believable sample data — a streak, a partly-filled daily goal ring, some cluster
accuracy percentages, a couple of mock exam scores. Make at least **one flow genuinely
interactive** end to end: answering a practice question, seeing right/wrong, and reading the
explanation. A prototype where nothing responds is a screenshot with extra steps.

**Do not invent features.** The app has: practice with spaced repetition, mock exams, roleplay
scenarios with a rubric, Quick Think drills, a mistake notebook, streaks and achievements, a
progress dashboard, and on-device-only AI explanations. No accounts, no sync, no social features,
no leaderboards.

---

## Constraints

- **Never claim the sample questions are official DECA content.** They are original practice items.
- **The privacy claim is a feature, state it:** no account, no tracking, works offline.
- Keep it **fast** — this gets opened on phones over mobile data. Static, no heavy libraries,
  images optimised.
- **Accessible:** real focus states, keyboard navigation through the prototype, sensible landmarks
  and labels, and contrast that holds in both themes.
- Everything is **client-side**; no data leaves the browser, and nothing is persisted server-side.

---

## Deploy

Target: **Vercel free tier**, deployed from GitHub at
`https://github.com/Iam-invisible/Glass-DECA-App` (create it if it doesn't exist yet).

Vercel's free Hobby tier is for non-commercial use, builds on push to the default branch, and
gives a `*.vercel.app` URL. Set the project root correctly if the web app lives in a subfolder of
that repo rather than at its root.

Confirm the build passes locally (`next build`) before pushing, and tell me plainly what you
verified and what you couldn't.

---

## What to hand back

1. The running site, with the device toggle working and at least one interactive flow.
2. The deployed URL.
3. A one-paragraph note on where the replica knowingly differs from the iOS app — the places you
   approximated, and what would drift first as the real app changes.
