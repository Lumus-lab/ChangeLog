# Yarrow Ritual Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static yarrow placeholder with a native Flutter ritual animation inspired by `籌策.html`.

**Architecture:** Add a focused widget that renders the animation from `YarrowSimulationResult.detail`, so visuals follow the already-generated result and never reroll. Keep `DivinationScreen` responsible only for timing, skip, and navigation.

**Tech Stack:** Flutter widgets, `CustomPainter`, widget tests, existing yarrow simulation models.

---

### Task 1: Animation Widget Contract

**Files:**
- Create: `test/widgets/yarrow_ritual_animation_test.dart`
- Create: `lib/views/widgets/yarrow_ritual_animation.dart`

- [ ] Write tests for visible ritual labels, current line/change text, revealed-line preview, and disabled animation behavior.
- [ ] Run `flutter test test/widgets/yarrow_ritual_animation_test.dart` and confirm it fails before implementation.
- [ ] Implement `YarrowRitualAnimation` with deterministic phase selection from elapsed progress.
- [ ] Run the targeted widget test until it passes.

### Task 2: Divination Screen Integration

**Files:**
- Modify: `lib/views/divination_screen.dart`
- Test: `test/views/yarrow_simulation_test.dart`

- [ ] Replace `_buildYarrowStalksMock()` usage with `YarrowRitualAnimation`.
- [ ] Use an 8-second per-line reveal cadence, so the default learning/debug flow remains visible for about 48 seconds.
- [ ] Remove now-unused mock stalk helpers.
- [ ] Run `flutter test test/views/yarrow_simulation_test.dart`.

### Task 3: Verification And Isolated Manual App Pass

**Files:**
- No source changes required for isolation unless manually testing with a temporary bundle id.

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter build macos`.
- [ ] For later manual testing, use a temporary macOS bundle id such as `com.lumusxlab.changelog.yarrowtest`, then revert that temporary identity change before review.

### Follow-Up Spec Items

These are intentionally left out of the quick animation fix because they need product and platform decisions:

- [ ] Add a user-facing animation speed control with at least slow/default and fast-forward options. The timing should be controlled by one source of truth shared by `DivinationScreen`, `YarrowRitualAnimation`, and tests.
- [ ] Resolve production macOS sandbox startup for ObjectBox. Current investigation points to `OBX_ERROR 10199 / Operation not permitted` under sandboxed release launch; likely follow-up includes App Group storage, development signing checks, and a separate release-build verification plan.
- [ ] Do a visual QA pass against `籌策.html` once the app can be launched in a stable preview mode, checking grouped stalk density, border clipping, and hexagram preview overlap on narrow and wide macOS window sizes.
