# Prompt — Design Glass's onboarding (mockups)

> Paste this into a **Claude design session** (claude.ai, not Claude Code).
> The deliverable is visual mockups, not shipping code.

---

## Your task

Design the first-run onboarding for **Glass**, an offline DECA competition-prep app for
high-school students, and hand it to me as **interactive HTML mockups I can click through**.

I want something **immersive, distinctive and genuinely hooking** — an opening that makes a
16-year-old want to start studying. Amaze me. But read the constraints before you get clever:
half the ideas that would amaze me are unbuildable, and an unbuildable mockup is worth nothing.

**Give me three concepts.** Different in kind, not three skins of one idea. For each: a short
rationale, then the mockup. End by telling me which you'd ship and why, without hedging.

---

## What the app is

Glass is calm, premium and adult. A well-made pen, not a mobile game. It's for a student
preparing for a **real competition on a real date** — that pressure is the emotional truth
available to you, and it's a far stronger hook than "let's get you set up."

The name is literal: clarity, weight, light through something solid.

**The app already opens with a launch reveal**: the word *"glass"* is handwritten in a monoline
script, stroke by stroke, then floods with light and settles into solid glass tubing, timed to an
audio swell peaking at 2.40 s. Right now onboarding starts from a blank slate immediately after
and the handoff is a hard cut.

**That reveal is the strongest creative material you have.** Treat it as the first beat of
onboarding rather than a separate thing that happens before it. If you have a better idea, argue
for it — but at least one of your three concepts should exploit this.

---

## The design system — use it exactly

**Colour.** Light / dark pairs. Every mockup must be shown in **both**.

| Token | Light | Dark |
|---|---|---|
| canvas | `#F4F6FA` | `#0D1219` |
| card | `#FFFFFF` | `#161E29` |
| cardSunken | `#EDF1F7` | `#111823` |
| stroke | `#E2E8F0` | `#27313F` |
| textPrimary | `#0F1B2D` | `#F2F5F9` |
| textSecondary | `#53627A` | `#9AA8BC` |
| textTertiary | `#8A97AB` | `#6C7A8D` |
| accent | `#2563EB` | `#5B8DEF` |
| accentSoft | `#E4EDFF` | `#1B2942` |
| success | `#12855C` | `#34C793` |
| gold | `#B07407` | `#E8B14A` |
| danger | `#C8342F` | `#F2645F` |

Accents carry meaning only — blue = progress, green = correct, red = wrong, gold = streaks and
achievements. Don't use them decoratively.

**Type.** The app uses **Instrument Serif** for display and **Manrope** for everything else.
Artifacts can't load web fonts, so substitute — and say in your notes that you did:

```css
--display: Didot, "Bodoni 72", "Playfair Display", Georgia, serif;  /* ≈ Instrument Serif */
--text: -apple-system, "SF Pro Text", "Helvetica Neue", sans-serif; /* ≈ Manrope */
```

Instrument Serif is high-contrast with thick-to-thin modulation — that contrast *is* the brand
idea, because the app is called Glass. Didot is the closest thing installed on a Mac.

Sizes in use: display 38 and 26; body 17; callout 16; footnote 13; caption 12; question 20
semibold. Manrope has a tall x-height, so `-apple-system` will read slightly smaller — nudge up
a point if it looks off.

**Spacing.** Gutter 18. Card radius 18, control radius 14. Row min-height 52. Stack spacing 14,
section spacing 24.

**Motion.** Springs, not linear easing. Approximate these:
`snappy` ≈ 340 ms / damping .78 · `gentle` ≈ 500 ms / .85 · `bouncy` ≈ 420 ms / .60 ·
`quick` ≈ 180 ms ease-out. Motion should reveal structure, not decorate it.

---

## Everything onboarding must collect

Design freely, but none of this may be lost:

1. **Welcome** — establish what the app is, and the offline / no-account promise.
2. **DECA cluster** — one of six: Marketing, Finance, Hospitality & Tourism, Business Management &
   Administration, Entrepreneurship, Personal Financial Literacy.
3. **Daily question goal** — 1 to 100, default 10.
4. **Daily reminder** — on/off plus a time (default 18:30). Needs an iOS permission prompt, and
   must survive the student denying it.
5. **AI coaching status** — on-device only. On phones without Apple Intelligence, an *optional*
   ~808 MB local model download, which must state **"Wi-Fi needed for the download only"**, the
   size, and a "Built with Llama" attribution.

Plus: **skippable in one tap** with sane defaults; every choice **reversible later** and said so;
progress always legible; **under 45 seconds** for a fast reader.

---

## Hard constraints — an idea that breaks these is unusable

**It must be buildable in SwiftUI on iOS 16, on an iPhone 8.** This is the one that kills most
"amazing" ideas, so design against it from the start:

- **No WebGL, no 3D, no particle systems, no video, no physics.** An A11 has no headroom, and none
  of it maps to SwiftUI cleanly.
- **Blur is expensive.** One or two small blurred elements is fine. A full-width blurred bar that
  sits over scrolling content is not — that measurably hurts frame rate on this hardware.
- Effects must have a SwiftUI equivalent: shapes, gradients, masks, opacity, offset, scale,
  rotation, `trim` on a path, spring animation. If you'd need a CSS filter chain or a canvas loop
  to draw it, it isn't buildable.
- **No system-drawn controls.** Everything is custom-drawn, because iOS 16 and iOS 26 render
  system pickers, switches and steppers differently.

**Accessibility isn't optional.** Full Dynamic Type — show me one frame at a large text size and
prove the layout survives. Real touch targets (44 pt). A **Reduce Motion** version of any
motion-heavy concept that is calm rather than broken.

---

## One design, every phone — this is the requirement that kills ideas

It has to look **the same** on an iPhone 8 as on an iPhone 15 or 17. Not "adapted." Not a
small-screen variant. The same design, the same composition, the same proportions — just
rendered into a different amount of room.

The screens are not close:

| | iPhone 8 | iPhone 15 / 17 |
|---|---|---|
| Points | **375 × 667** | 393 × 852 · 402 × 874 |
| Aspect | 16 : 9 | 19.5 : 9 |
| Top safe area | **20 pt** (status bar) | 59 pt (Dynamic Island) |
| Bottom safe area | **0 pt** (home button) | 34 pt (home indicator) |
| Render scale | **@2x, 326 ppi** | @3x, 460 ppi |

The height gap is the killer: a modern phone has **31% more vertical room**. So:

- **Design at 375 × 667 first**, then check it at 393 × 852. Doing it the other way round produces
  a composition that only works tall and has to be mutilated to fit short — which is exactly the
  "adapted" outcome I don't want.
- **Never build a screen that must fit exactly one viewport.** No hero that fills the phone, no
  element pinned to the bottom of the fold, no "one question per screen, perfectly centred" — all
  of those look composed on a 15 and cramped or clipped on an 8. Let content flow and scroll, and
  make the composition read the same whether or not it all fits at once.
- **Extra height must not become dead space.** If the 15 just shows the same thing with a large
  empty gap, the design is tuned to the small phone rather than genuinely fluid. Growth should go
  somewhere deliberate — breathing room around the type, more of the next section visible — not
  into a void.
- **Never hardcode safe areas.** Top is 20 pt on an 8 and 59 pt on a 15; bottom is 0 and 34. Read
  them; don't assume a notch exists or doesn't.
- **Watch hairlines at @2x.** The iPhone 8 renders at 326 ppi against 460. Very thin strokes and
  high-contrast serif hairlines that look crisp on a 15 can go faint or break up on an 8. If a
  detail depends on sub-point precision, it will not survive.
- **Sizing should be relative, not absolute.** Proportions, spacing scales and flexible frames —
  not offsets measured from the bottom of a 852-point screen.

**Truthfulness.** Never imply the bundled questions are official DECA content — they're original
practice items. Don't invent features the app doesn't have.

---

## Creative direction

**Aim for:** a sense of place. One genuinely memorable moment rather than five decorated screens.
Type doing the heavy lifting. Depth from light and material, not drop shadows. Make the student
*do* something in the first ten seconds instead of reading. Consider what the app knows at the end
that it didn't at the start, and show it back to them.

**Avoid:** mascots. Confetti. Emoji as iconography. "Let's get started!" Progress dots as the only
sense of progress. Carousels of stock illustration. Gamified XP language. Anything that would
embarrass a 17-year-old showing it to a teacher.

**The bar:** if the concept could be dropped into any other study app by swapping the copy, it
isn't distinctive enough. It should only make sense for *this* app, with *this* name.

---

## What to hand back

For each of the three concepts:

1. **One paragraph** — the spine of the idea, what the student feels, why it's different.
2. **An interactive HTML mockup** — clickable through the whole flow, with the real motion, shown
   **side by side at 375 × 667 and 393 × 852**, in **both light and dark**. Put the two sizes next
   to each other in the same artifact so the comparison is unavoidable; if they don't read as the
   same design, the concept isn't finished.
3. **One frame at large Dynamic Type**, at 375 × 667 — the hardest case — showing the layout holds.
4. **A note on cost** — anything you're unsure is buildable in SwiftUI on an iPhone 8, flag it
   yourself rather than letting me find out later.

Then: which one you'd ship, and what you'd cut from it first if it turned out too expensive.
