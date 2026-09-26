# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**CosteReunion** ("Coste de Reunión") is a single-purpose iOS app: it shows in real time how much a meeting is costing based on each attendee's hourly rate. UI language is Spanish. Requires iOS 17+.

## Build & Test

This is an Xcode project (`CosteReunion.xcodeproj`, scheme `CosteReunion`). Prefer the `xcode-tools` MCP commands over the command line:

- **Build**: `BuildProject`
- **All tests**: `RunAllTests` — **Some tests**: `RunSomeTests` / `GetTestList` to pick individual tests
- **Fast diagnostics** (per-file, no full build): `XcodeRefreshCodeIssuesInFile`
- **Try a snippet in context**: `RunCodeSnippet`

Tests use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`) — not XCTest. UI tests use XCUIAutomation. Test targets: `CosteReunionTests`, `CosteReunionUITests`.

## Architecture

The entire app lives in `CosteReunion/ContentView.swift`. `CosteReunionApp.swift` is just the `@main` entry point hosting `ContentView`. There is no persistence, networking, or external dependency.

Key design decisions worth knowing before editing:

- **Time is derived from the wall clock, never accumulated.** `segmentStart: Date?` marks when the current running segment began (`nil` = paused). `savedTime` holds the total of already-closed segments. Elapsed time and cost are computed on read via `currentTime(at:)` / `currentCost(at:)` against `TimelineView`'s `context.date`. Don't introduce a per-second timer that increments counters — it drifts.

- **Per-person cost survives roster changes.** `ledger: [UUID: LedgerEntry]` records each attendee's accumulated cost across closed segments, keyed by attendee `id`. This is what lets someone leave mid-meeting without losing their contribution. `closeSegment(using:)` distributes the in-progress segment across a given attendee list and immediately starts a fresh segment.

- **Roster edits close the current segment first.** `.onChange(of: attendees)` calls `closeSegment(using: oldValue)` so the segment in progress is billed against the *old* roster/rates before the new ones take effect. When changing this flow, preserve the "close with old list, then apply new" ordering.

- **The three view structs** are `ContentView` (timer + controls), `AttendeesView` (edit names/rates, presented as a sheet, binds `$attendees`), and `BreakdownView` (per-person totals + `ShareLink`, shown on pause).

- **Screen wake lock**: `UIApplication.shared.isIdleTimerDisabled` is toggled with the timer so the screen stays on while running.

- **Background image**: `MeetingRoomBackground` uses the `meetingRoom` asset if present, else a gradient fallback. The app forces `.preferredColorScheme(.dark)` for legibility over the darkened photo.
