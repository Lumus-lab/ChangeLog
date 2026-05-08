# Welcoming Professional UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make ChangeLog's first-run and home divination flow feel welcoming to beginners while preserving professional divination, result, record, AI, and study capabilities.

**Architecture:** Keep the existing Flutter/Riverpod structure and make the UX change at the view layer, with one small service API for default divination. First launch uses a short welcome sheet that can open the full help center without marking onboarding complete prematurely. The home screen defaults to question-first divination, while advanced methods remain discoverable in a collapsed section.

**Tech Stack:** Flutter, Riverpod, flutter_test, existing `DivinationService`, `StorageService`, and Material 3 dark theme.

---

### Task 1: Default Beginner Divination Path

**Files:**
- Modify: `lib/services/divination_service.dart`
- Test: `test/services/divination_service_test.dart`

- [x] **Step 1: Write the failing test**

```dart
group('generateIntuitiveDivination', () {
  test('produces exactly 6 valid lines without requiring method inputs', () {
    final lines = service.generateIntuitiveDivination();

    expect(lines.length, 6);
    for (final val in lines) {
      expect(val, isIn([6, 7, 8, 9]));
    }
  });
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/divination_service_test.dart`

Expected: FAIL with `The method 'generateIntuitiveDivination' isn't defined for the type 'DivinationService'`.

- [x] **Step 3: Implement minimal service method**

```dart
List<int> generateIntuitiveDivination() {
  return generateCoinDivination();
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/divination_service_test.dart`

Expected: PASS.

### Task 2: Welcome Card and Help Center

**Files:**
- Modify: `lib/views/explanation_screen.dart`
- Modify: `lib/views/home_screen.dart`
- Test: `test/views/welcoming_ux_test.dart`

- [x] **Step 1: Write widget tests**

```dart
testWidgets('welcome card starts first launch without full instructions', (tester) async {
  var started = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FirstLaunchWelcomeSheet(
          onStart: () async => started = true,
          onCompleteAfterHelp: () async {},
        ),
      ),
    ),
  );

  expect(find.text('先問一件正在猶豫的事'), findsOneWidget);
  expect(find.text('ChangeLog 會幫你起卦、整理卦象，並留下日後可回顧的紀錄。'), findsOneWidget);
  expect(find.text('如何起卦？'), findsNothing);

  await tester.tap(find.text('開始'));
  await tester.pump();

  expect(started, isTrue);
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/views/welcoming_ux_test.dart`

Expected: FAIL because `FirstLaunchWelcomeSheet` does not exist.

- [x] **Step 3: Implement welcome sheet and first-launch routing**

Create `FirstLaunchWelcomeSheet` in `explanation_screen.dart` with:
- title `先問一件正在猶豫的事`
- body `ChangeLog 會幫你起卦、整理卦象，並留下日後可回顧的紀錄。`
- primary action `開始`
- secondary action `查看完整說明`

Update `HomeScreen._checkFirstLaunch()` to call `ExplanationScreen.showWelcome(...)` and mark first launch complete only from `onStart` or when the user declines returning to the welcome card after help.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/views/welcoming_ux_test.dart`

Expected: PASS.

### Task 3: Question-First Home UX

**Files:**
- Modify: `lib/views/divination_screen.dart`
- Test: `test/views/welcoming_ux_test.dart`

- [x] **Step 1: Write widget test**

```dart
testWidgets('divination home starts with question and hides advanced terms', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: DivinationScreen()),
    ),
  );
  await tester.pump();

  expect(find.text('先問一件正在猶豫的事'), findsOneWidget);
  expect(find.text('開始一卦'), findsOneWidget);
  expect(find.text('進階起卦方式'), findsOneWidget);
  expect(find.text('下卦數'), findsNothing);
  expect(find.text('上卦數'), findsNothing);
  expect(find.text('動爻數'), findsNothing);
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/views/welcoming_ux_test.dart`

Expected: FAIL because the current form starts with a large logo and exposes method terms.

- [x] **Step 3: Implement the question-first layout**

Update `DivinationScreen` to:
- render a low-opacity rotating background logo behind the form
- show headline `先問一件正在猶豫的事`
- show question input before method controls
- make the primary button say `開始一卦`
- keep `進階起卦方式` collapsed by default
- use `generateIntuitiveDivination()` when advanced mode is collapsed
- keep number, coin, and yarrow methods inside the advanced section with one-line hints

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/views/welcoming_ux_test.dart`

Expected: PASS.

### Task 4: Contextual Terminology Hints

**Files:**
- Modify: `lib/views/divination_result_screen.dart`
- Modify: `lib/views/record_detail_screen.dart`

- [x] **Step 1: Add result page hints**

Add short helper text for:
- `朱熹解卦法則：協助判斷應優先閱讀哪些卦爻辭。`
- `本卦：目前情境的主象。`
- `之卦：有變爻時，象徵事情可能轉向的方向。`
- `變爻：這次卦象中特別需要留意的變動位置。`

- [x] **Step 2: Add record page hints**

Add helper text to:
- interpretation: `記下你現在的理解，不必一次寫完整。`
- action plan: `把卦象帶來的提醒轉成可觀察的行動。`
- outcome: `過一段時間回來記錄實際發展。`

- [x] **Step 3: Run analyzer**

Run: `flutter analyze`

Expected: no new analyzer errors.

### Task 5: Full Verification

**Files:**
- Verify all modified files.

- [x] **Step 1: Run focused tests**

Run: `flutter test test/services/divination_service_test.dart test/views/welcoming_ux_test.dart`

Expected: PASS.

- [x] **Step 2: Run full test suite**

Run: `flutter test`

Expected: PASS.

- [x] **Step 3: Run analyzer**

Run: `flutter analyze`

Expected: no errors.
