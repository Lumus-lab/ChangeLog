# Yarrow Follow-Ups Design

**Goal:** Preserve the remaining yarrow animation and macOS release issues for the next working session, with clear boundaries between quick visual polish and platform release work.

**Current State:** The yarrow ritual animation is a native Flutter widget driven by `YarrowSimulationResult.detail`. The app can be previewed with a temporary non-sandbox macOS build, but the formal sandboxed release path still needs ObjectBox storage/signing work.

## Follow-Up 1: Animation Speed Control

The default yarrow flow is intentionally slower for learning and debugging: six lines at eight seconds each, about forty-eight seconds total. A future speed control should expose at least two modes:

- `Slow`: current teaching/debug cadence.
- `Fast`: faster preview or fast-forward cadence for users who already understand the ritual.

The speed value should come from one source of truth. `DivinationScreen` should use it for line reveal timing and duration copy, while `YarrowRitualAnimation` should use it for per-line controller duration. Tests should assert both the visible copy and the moment when the animation remains on screen or completes.

## Follow-Up 2: Visual QA Against Reference

Compare the Flutter widget with `/Users/phenix/Documents/ChangeLog-app/籌策.html` after a stable preview launch. The review should check:

- grouped four-stalk rows remain readable without leaving the rounded border,
- left/right grouped areas do not obscure the lower-left hexagram preview,
- labels remain aligned with the visual zones on narrow and wide macOS windows,
- the `分二 / 掛一 / 揲四 / 歸奇` progression still reads like the reference.

This should stay as visual polish, not a rewrite of yarrow simulation data.

## Follow-Up 3: Production macOS Sandbox And ObjectBox

The black screen seen in the formal sandbox release path appears separate from animation rendering. The observed failure was `OBX_ERROR 10199 / Operation not permitted` during ObjectBox startup under macOS sandboxing.

The production fix should investigate ObjectBox storage location, App Group container setup, signing profile behavior, and release entitlements together. The non-sandbox preview build is only a diagnostic path and must not be left in source.

## Acceptance Criteria

- Speed control changes are covered by targeted widget/view tests and do not change yarrow line generation.
- Visual QA produces either small layout fixes or screenshots/notes showing acceptable behavior.
- Production macOS release can launch with sandbox enabled without ObjectBox permission errors.
- `macos/Runner/Configs/AppInfo.xcconfig` and `macos/Runner/Release.entitlements` keep the formal app name, bundle id, and sandbox setting unless the active task is explicitly a temporary preview build.
