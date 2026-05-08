# Isolated Yarrow App Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and launch the integration worktree as a temporary isolated macOS app without touching the main workspace or preserving test-only identity changes.

**Architecture:** Temporarily change only the macOS product name, bundle identifier, and release sandbox entitlement in the integration worktree, build the app, verify the built app identity, launch it once, then restore the original app identity and entitlement.

**Tech Stack:** Flutter macOS build, macOS bundle metadata, git diff verification.

---

### Task 1: Temporary Identity

**Files:**
- Modify temporarily: `macos/Runner/Configs/AppInfo.xcconfig`
- Modify temporarily: `macos/Runner/Release.entitlements`

- [ ] Change `PRODUCT_NAME` from `changelog` to `changelog-yarrow-test`.
- [ ] Change `PRODUCT_BUNDLE_IDENTIFIER` from `com.lumusxlab.changelog` to `com.lumusxlab.changelog.yarrowtest`.
- [ ] Change `com.apple.security.app-sandbox` from `true` to `false` for this preview build only.
- [ ] Confirm the diff contains only this temporary preview change plus existing animation work.

### Task 2: Isolated Build And Launch

**Commands:**
- `flutter build macos`
- `defaults read build/macos/Build/Products/Release/changelog-yarrow-test.app/Contents/Info CFBundleIdentifier`
- `open -n build/macos/Build/Products/Release/changelog-yarrow-test.app`

- [ ] Build the temporary isolated app.
- [ ] Verify the app bundle id is `com.lumusxlab.changelog.yarrowtest`.
- [ ] Launch the app once for a smoke test.

### Task 3: Restore Reviewable Source State

**Files:**
- Restore: `macos/Runner/Configs/AppInfo.xcconfig`
- Restore: `macos/Runner/Release.entitlements`

- [ ] Restore `PRODUCT_NAME = changelog`.
- [ ] Restore `PRODUCT_BUNDLE_IDENTIFIER = com.lumusxlab.changelog`.
- [ ] Restore `com.apple.security.app-sandbox` to `true`.
- [ ] Run `git diff -- macos/Runner/Configs/AppInfo.xcconfig macos/Runner/Release.entitlements` and confirm it is empty.
- [ ] Run `git status --short --branch` and confirm no macOS preview file remains modified.
- [ ] Run `flutter analyze` and `flutter test`.
