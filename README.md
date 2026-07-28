# Glass — interactive web preview

A faithful web recreation of **Glass**, an offline DECA Ontario study app for iPhone.

**Live:** https://glass-deca-app.vercel.app

## What this branch is

Only the website. It is a static site — no build step, no dependencies, no backend — so
Vercel serves it straight from the repository root.

It is **not** the iOS app. SwiftUI cannot run in a browser, so this recreates the app's
screens in HTML, CSS and JavaScript. Haptics, notifications, the home-screen widget and
the on-device AI coaching can't exist on the web, and are represented rather than real.

It does reuse the real material: all 60 sample questions come from the app's own question
bank, and the launch reveal uses the same handwriting path the iOS version does — a stroke
running along the pen's centreline, masking a Sacramento outline, so what appears is always
the true letterform.

## The iOS app

The Swift source lives on the other branches of this repository:

| Ref | What it is |
|---|---|
| `type-and-onboarding-revamp` | Current — Instrument Serif + Manrope, rebuilt onboarding |
| `ios26-consistency` | Custom controls for iOS 16 / iOS 26 consistency |
| `v1-baseline` (tag) | The app before the control rework |
| `v2-revamp` (tag) | The app after the type and onboarding revamp |

## Files

    index.html      the page and the device shell
    web/app.css     design tokens copied from the app's DesignSystem.swift
    web/app.js      screens, navigation and the practice flow
    web/data.json   question bank, pen path and baked glyph outline

## Notes

Sample questions are original practice items written for this app. They are **not** official
DECA Ontario or DECA Inc. competition content.

Nothing is stored or transmitted — all state is in memory, which matches the app's own
no-account, no-tracking promise.
