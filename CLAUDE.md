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

`CosteReunionApp.swift` is just the `@main` entry point hosting `ContentView`. The code is split by responsibility:

- `MeetingCostModel.swift` — the `@Observable` model: all domain state and calculations.
- `Models/` — `Attendee` (Codable) and `LedgerEntry` value types.
- `ContentView.swift` — main screen (timer, controls); owns UI-only state.
- `Views/` — `AttendeesView`, `BreakdownView`, `MeetingRoomBackground`.

The Xcode project uses **file-system-synchronized groups**, so any file added under `CosteReunion/` is compiled into the target automatically — no `.pbxproj` edits needed.

Key design decisions worth knowing before editing:

- **Domain state lives in `MeetingCostModel`, UI state in the view.** The model holds `attendees`, `segmentStart`, `savedTime`, `ledger` and the actions. `ContentView` keeps only presentation state (`showingAttendees`, `showingBreakdown`) and side effects that need UIKit. Keep the model free of UIKit/SwiftUI. `AttendeesView`/`BreakdownView` stay decoupled (they take a `Binding`/plain data, not the model).

- **Time is derived from the wall clock, never accumulated.** `segmentStart: Date?` marks when the current running segment began (`nil` = paused). `savedTime` holds the total of already-closed segments. Elapsed time and cost are computed on read via `currentTime(at:)` / `currentCost(at:)` against `TimelineView`'s `context.date`. Don't introduce a per-second timer that increments counters — it drifts.

- **Per-person cost survives roster changes.** `ledger: [UUID: LedgerEntry]` records each attendee's accumulated cost across closed segments, keyed by attendee `id`. This is what lets someone leave mid-meeting without losing their contribution. `closeSegment(using:)` distributes the in-progress segment across a given attendee list and immediately starts a fresh segment.

- **Roster edits close the current segment first.** `ContentView`'s `.onChange(of: model.attendees)` calls `closeSegment(using: oldValue)` so the segment in progress is billed against the *old* roster/rates before the new ones take effect. When changing this flow, preserve the "close with old list, then apply new" ordering.

- **Attendees are persisted, the meeting is not.** The roster (names + rates) is saved to `UserDefaults` as JSON on every change via a `didSet` on `MeetingCostModel.attendees`, and reloaded in `init()` (falling back to a default list). The running timer and `ledger` are intentionally *not* persisted — reopening the app starts a fresh meeting. `Attendee.id` is a `var` (not `let`) so Codable actually decodes it and IDs stay stable across launches.

- **Screen wake lock**: `ContentView`'s `.onChange(of: model.isRunning)` toggles `UIApplication.shared.isIdleTimerDisabled` so the screen stays on while running.

- **Background image**: `MeetingRoomBackground` uses the `meetingRoom` asset if present, else a gradient fallback. The app forces `.preferredColorScheme(.dark)` for legibility over the darkened photo.

- **App icon**: `Assets.xcassets/AppIcon.appiconset` holds single-size 1024px light/dark/tinted PNGs (a clock + € motif).
