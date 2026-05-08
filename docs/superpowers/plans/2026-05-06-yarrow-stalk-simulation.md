# Yarrow Stalk Simulation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current manual "籌策" entry with a real yarrow-stalk simulation that animates a generated six-line process, optionally saves structured process detail, and shows yarrow detail in records.

**Architecture:** Add a typed yarrow simulation model and generation API in the service layer, store the final six-line result only in the existing `rawHexagramNumbersStr` field, and store optional process detail in a new generic `methodDetailJson` record field. The UI generates the full simulation before animation, plays that immutable process with a skip option, then passes the same result/detail into the existing result and record flows.

**Tech Stack:** Flutter, Riverpod, ObjectBox, SharedPreferences, `flutter_animate`, Flutter unit/widget tests.

---

## File Map

- Create `lib/models/yarrow_simulation.dart`: typed model for yarrow changes, line details, full detail JSON, and generated result.
- Modify `lib/services/divination_service.dart`: add deterministic-testable yarrow generation while keeping existing hexagram calculation APIs.
- Modify `test/services/divination_service_test.dart`: add tests for yarrow invariants and update old manual-yarrow tests.
- Modify `lib/models/divination_record.dart`: add optional `methodDetailJson` only; keep `rawHexagramNumbersStr` as the canonical six-line result.
- Regenerate `lib/objectbox.g.dart` and `lib/objectbox-model.json`: ObjectBox schema update for `methodDetailJson`.
- Modify `lib/services/data_transfer_service.dart` and `test/services/data_transfer_service_test.dart`: include `methodDetailJson` in backup/restore.
- Modify `lib/services/storage_service.dart`: persist the "保存完整過程" preference.
- Modify `lib/views/divination_screen.dart`: replace manual yarrow text input with yarrow simulation entry, preference switch, animation/progress state, and skip action.
- Modify `lib/views/divination_result_screen.dart`: accept optional `methodDetailJson` and save it to records.
- Modify `lib/views/record_detail_screen.dart`: show `有過程` / `僅結果` labels and expandable yarrow detail.
- Create `lib/views/widgets/yarrow_detail_section.dart`: reusable display for yarrow process detail.
- Add or update widget tests under `test/views/`: verify yarrow UI labels and result-detail forwarding.

---

### Task 1: Add Typed Yarrow Simulation Models

**Files:**
- Create: `lib/models/yarrow_simulation.dart`
- Test: `test/services/divination_service_test.dart`

- [ ] **Step 1: Add model tests before implementation**

Append this import and group to `test/services/divination_service_test.dart`:

```dart
import 'dart:convert';
import 'package:changelog/models/yarrow_simulation.dart';
```

```dart
  group('YarrowSimulationDetail JSON', () {
    test('round-trips structured process detail without storing line values', () {
      final detail = YarrowSimulationDetail(
        lines: [
          YarrowLineDetail(
            position: 1,
            changes: [
              YarrowChange(
                changeIndex: 1,
                before: 49,
                left: 24,
                right: 25,
                hang: 1,
                leftRemainder: 4,
                rightRemainder: 4,
                removed: 9,
                after: 40,
              ),
              YarrowChange(
                changeIndex: 2,
                before: 40,
                left: 19,
                right: 21,
                hang: 1,
                leftRemainder: 3,
                rightRemainder: 4,
                removed: 8,
                after: 32,
              ),
              YarrowChange(
                changeIndex: 3,
                before: 32,
                left: 16,
                right: 16,
                hang: 1,
                leftRemainder: 4,
                rightRemainder: 3,
                removed: 8,
                after: 24,
              ),
            ],
          ),
        ],
      );

      final encoded = jsonEncode(detail.toJson());
      expect(encoded, isNot(contains('"value"')));

      final decoded = YarrowSimulationDetail.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(decoded.type, 'yarrow');
      expect(decoded.version, 1);
      expect(decoded.lines.single.position, 1);
      expect(decoded.lines.single.inferredValue, 6);
      expect(decoded.inferredLineValues, [6]);
    });
  });
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `flutter test test/services/divination_service_test.dart`

Expected: FAIL because `lib/models/yarrow_simulation.dart` and model classes do not exist.

- [ ] **Step 3: Create `lib/models/yarrow_simulation.dart`**

```dart
class YarrowChange {
  final int changeIndex;
  final int before;
  final int left;
  final int right;
  final int hang;
  final int leftRemainder;
  final int rightRemainder;
  final int removed;
  final int after;

  const YarrowChange({
    required this.changeIndex,
    required this.before,
    required this.left,
    required this.right,
    required this.hang,
    required this.leftRemainder,
    required this.rightRemainder,
    required this.removed,
    required this.after,
  });

  factory YarrowChange.fromJson(Map<String, dynamic> json) {
    return YarrowChange(
      changeIndex: json['changeIndex'] as int,
      before: json['before'] as int,
      left: json['left'] as int,
      right: json['right'] as int,
      hang: json['hang'] as int,
      leftRemainder: json['leftRemainder'] as int,
      rightRemainder: json['rightRemainder'] as int,
      removed: json['removed'] as int,
      after: json['after'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'changeIndex': changeIndex,
        'before': before,
        'left': left,
        'right': right,
        'hang': hang,
        'leftRemainder': leftRemainder,
        'rightRemainder': rightRemainder,
        'removed': removed,
        'after': after,
      };
}

class YarrowLineDetail {
  final int position;
  final List<YarrowChange> changes;

  const YarrowLineDetail({
    required this.position,
    required this.changes,
  });

  int get inferredValue {
    if (changes.length != 3) {
      throw StateError('A yarrow line must contain exactly three changes.');
    }
    final after = changes.last.after;
    if (after % 4 != 0) {
      throw StateError('Final yarrow stalk count must be divisible by 4.');
    }
    return after ~/ 4;
  }

  factory YarrowLineDetail.fromJson(Map<String, dynamic> json) {
    final changesJson = json['changes'] as List<dynamic>;
    return YarrowLineDetail(
      position: json['position'] as int,
      changes: changesJson
          .map((item) => YarrowChange.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position,
        'changes': changes.map((change) => change.toJson()).toList(),
      };
}

class YarrowSimulationDetail {
  final String type;
  final int version;
  final List<YarrowLineDetail> lines;

  const YarrowSimulationDetail({
    this.type = 'yarrow',
    this.version = 1,
    required this.lines,
  });

  List<int> get inferredLineValues =>
      lines.map((line) => line.inferredValue).toList();

  factory YarrowSimulationDetail.fromJson(Map<String, dynamic> json) {
    final linesJson = json['lines'] as List<dynamic>;
    return YarrowSimulationDetail(
      type: json['type'] as String? ?? 'yarrow',
      version: json['version'] as int? ?? 1,
      lines: linesJson
          .map((item) => YarrowLineDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'version': version,
        'lines': lines.map((line) => line.toJson()).toList(),
      };
}

class YarrowSimulationResult {
  final List<int> lines;
  final YarrowSimulationDetail detail;

  const YarrowSimulationResult({
    required this.lines,
    required this.detail,
  });
}
```

- [ ] **Step 4: Run test and verify it passes**

Run: `flutter test test/services/divination_service_test.dart`

Expected: PASS for the new JSON group; old tests still pass.

- [ ] **Step 5: Commit**

```bash
git add lib/models/yarrow_simulation.dart test/services/divination_service_test.dart
git commit -m "feat: add yarrow simulation models"
```

---

### Task 2: Implement Yarrow Generation in DivinationService

**Files:**
- Modify: `lib/services/divination_service.dart`
- Test: `test/services/divination_service_test.dart`

- [ ] **Step 1: Add failing generation tests**

Add `import 'dart:math';` to `test/services/divination_service_test.dart`.

Replace the old `generateYarrowDivination` group with:

```dart
  group('generateYarrowSimulation', () {
    test('produces six valid line values and full eighteen-change detail', () {
      final service = DivinationService(random: Random(1));
      final result = service.generateYarrowSimulation();

      expect(result.lines.length, 6);
      expect(result.detail.lines.length, 6);
      expect(result.detail.inferredLineValues, result.lines);

      for (final line in result.detail.lines) {
        expect(line.position, inInclusiveRange(1, 6));
        expect(line.changes.length, 3);
        for (final change in line.changes) {
          expect(change.hang, 1);
          expect(change.removed,
              change.hang + change.leftRemainder + change.rightRemainder);
          expect(change.after, change.before - change.removed);
          expect(change.left + change.right, change.before);
          expect(change.leftRemainder, inInclusiveRange(1, 4));
          expect(change.rightRemainder, inInclusiveRange(1, 4));
        }
        expect(line.inferredValue, isIn([6, 7, 8, 9]));
      }
    });

    test('does not duplicate final line values inside method detail JSON', () {
      final service = DivinationService(random: Random(2));
      final result = service.generateYarrowSimulation();

      expect(result.detail.toJson().toString(), isNot(contains('value')));
      expect(result.detail.inferredLineValues, result.lines);
    });
  });
```

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test test/services/divination_service_test.dart`

Expected: FAIL because `DivinationService(random:)` and `generateYarrowSimulation()` do not exist.

- [ ] **Step 3: Modify `DivinationService`**

At the top of `lib/services/divination_service.dart`, add:

```dart
import '../models/yarrow_simulation.dart';
```

Replace the field declaration:

```dart
final _random = Random();
```

with:

```dart
final Random _random;

DivinationService({Random? random}) : _random = random ?? Random();
```

Replace the current manual-yarrow method:

```dart
/// 籌策 (手動輸入 6,7,8,9 的陣列，需剛好六個由下而上)
List<int>? generateYarrowDivination(List<int> userLines) {
  if (userLines.length != 6) return null;
  return userLines.toList();
}
```

with:

```dart
/// 籌策模擬：四營十八變，六爻由下而上生成。
YarrowSimulationResult generateYarrowSimulation() {
  final lineDetails = <YarrowLineDetail>[];
  final lines = <int>[];

  for (int position = 1; position <= 6; position++) {
    final lineDetail = _generateYarrowLine(position);
    lineDetails.add(lineDetail);
    lines.add(lineDetail.inferredValue);
  }

  return YarrowSimulationResult(
    lines: lines,
    detail: YarrowSimulationDetail(lines: lineDetails),
  );
}

YarrowLineDetail _generateYarrowLine(int position) {
  var stalks = 49;
  final changes = <YarrowChange>[];

  for (int changeIndex = 1; changeIndex <= 3; changeIndex++) {
    final change = _performYarrowChange(
      stalks: stalks,
      changeIndex: changeIndex,
    );
    changes.add(change);
    stalks = change.after;
  }

  return YarrowLineDetail(position: position, changes: changes);
}

YarrowChange _performYarrowChange({
  required int stalks,
  required int changeIndex,
}) {
  final left = _random.nextInt(stalks - 1) + 1;
  final right = stalks - left;
  const hang = 1;
  final rightAfterHang = right - hang;
  final leftRemainder = _yarrowRemainder(left);
  final rightRemainder = _yarrowRemainder(rightAfterHang);
  final removed = hang + leftRemainder + rightRemainder;

  return YarrowChange(
    changeIndex: changeIndex,
    before: stalks,
    left: left,
    right: right,
    hang: hang,
    leftRemainder: leftRemainder,
    rightRemainder: rightRemainder,
    removed: removed,
    after: stalks - removed,
  );
}

int _yarrowRemainder(int stalks) {
  final remainder = stalks % 4;
  return remainder == 0 ? 4 : remainder;
}
```

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/services/divination_service_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/divination_service.dart test/services/divination_service_test.dart
git commit -m "feat: simulate yarrow stalk divination"
```

---

### Task 3: Add Method Detail Storage and Transfer Support

**Files:**
- Modify: `lib/models/divination_record.dart`
- Modify: `lib/services/data_transfer_service.dart`
- Modify: `test/services/data_transfer_service_test.dart`
- Generated: `lib/objectbox.g.dart`
- Generated: `lib/objectbox-model.json`

- [ ] **Step 1: Add failing data transfer test expectations**

In `test/services/data_transfer_service_test.dart`, update the test record setup to include:

```dart
methodDetailJson: '{"type":"yarrow","version":1,"lines":[]}',
```

Update the export map expectation helper to include:

```dart
'methodDetailJson': r.methodDetailJson,
```

Update restore assertions:

```dart
expect(restored.methodDetailJson, original.methodDetailJson);
```

- [ ] **Step 2: Run data transfer tests and verify failure**

Run: `flutter test test/services/data_transfer_service_test.dart`

Expected: FAIL because `methodDetailJson` does not exist.

- [ ] **Step 3: Add `methodDetailJson` to `DivinationRecord`**

In `lib/models/divination_record.dart`, add this field after `changingLinesStr`:

```dart
  /// 起卦方式的結構化明細，例如籌策十八變。六爻結果仍以 rawHexagramNumbersStr 為唯一來源。
  String? methodDetailJson;
```

Update constructor parameters:

```dart
    this.methodDetailJson,
```

Place it after `this.changingLinesStr,`.

- [ ] **Step 4: Include `methodDetailJson` in export/import**

In `lib/services/data_transfer_service.dart`, add this to the export map after `changingLinesStr`:

```dart
'methodDetailJson': r.methodDetailJson,
```

Add this to the `DivinationRecord` constructor in import after `changingLinesStr`:

```dart
methodDetailJson: item['methodDetailJson'],
```

- [ ] **Step 5: Regenerate ObjectBox files**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/objectbox.g.dart` and `lib/objectbox-model.json` update with `methodDetailJson`.

- [ ] **Step 6: Run focused tests**

Run: `flutter test test/services/data_transfer_service_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/models/divination_record.dart lib/services/data_transfer_service.dart test/services/data_transfer_service_test.dart lib/objectbox.g.dart lib/objectbox-model.json
git commit -m "feat: store method detail with records"
```

---

### Task 4: Persist Yarrow Detail Preference

**Files:**
- Modify: `lib/services/storage_service.dart`
- Test: `test/views/yarrow_simulation_test.dart` in Task 8 verifies the preference appears in the yarrow UI. A dedicated `StorageService` unit test is not added because this repo does not currently have a storage-service test harness.

- [ ] **Step 1: Add preference API to StorageService**

In `lib/services/storage_service.dart`, add key:

```dart
static const _kSaveYarrowProcessDetail = 'save_yarrow_process_detail';
```

Add methods near the first-launch section:

```dart
bool get saveYarrowProcessDetail {
  return _prefs.getBool(_kSaveYarrowProcessDetail) ?? true;
}

Future<void> setSaveYarrowProcessDetail(bool value) async {
  await _prefs.setBool(_kSaveYarrowProcessDetail, value);
}
```

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze`

Expected: no new analyzer errors from `storage_service.dart`.

- [ ] **Step 3: Commit**

```bash
git add lib/services/storage_service.dart
git commit -m "feat: remember yarrow detail preference"
```

---

### Task 5: Pass Method Detail Through Result Saving

**Files:**
- Modify: `lib/views/divination_result_screen.dart`

- [ ] **Step 1: Add constructor fields**

In `DivinationResultScreen`, add:

```dart
final String? methodDetailJson;
```

Update constructor:

```dart
    this.methodDetailJson,
```

- [ ] **Step 2: Save method detail when creating records**

In both places that create `DivinationRecord` in `divination_result_screen.dart`, add:

```dart
methodDetailJson: methodDetailJson,
```

The first creation should become:

```dart
final newRecord = DivinationRecord(
  createdAt: DateTime.now(),
  question: question,
  method: method,
  primaryHexagramId: primaryId,
  resultingHexagramId: resultingId,
  methodDetailJson: methodDetailJson,
);
```

The second "僅保存卦象文字，不使用 AI" creation should use the same additional argument.

- [ ] **Step 3: Preserve changing-lines behavior**

The AI path already calculates `movingLines` and assigns `newRecord.changingLines`. The non-AI path currently does not. Add the same moving-line calculation before `recordsNotifier.addRecord(newRecord)` in the non-AI path:

```dart
final movingLines = <int>[];
for (int i = 0; i < lines.length; i++) {
  if (lines[i] == 6 || lines[i] == 9) {
    movingLines.add(i + 1);
  }
}
newRecord.changingLines = movingLines;
```

This is not yarrow-specific, but keeps saved records consistent while touching the save flow.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`

Expected: no new errors from `DivinationResultScreen`.

- [ ] **Step 5: Commit**

```bash
git add lib/views/divination_result_screen.dart
git commit -m "feat: save method detail from result flow"
```

---

### Task 6: Replace Manual Yarrow Input With Simulation Flow

**Files:**
- Modify: `lib/views/divination_screen.dart`

- [ ] **Step 1: Add imports and state**

Add imports:

```dart
import 'dart:convert';
import '../models/yarrow_simulation.dart';
import '../services/storage_service.dart';
```

Remove:

```dart
final TextEditingController _yarrowCtrl = TextEditingController();
```

Add state fields:

```dart
bool _saveYarrowProcessDetail = true;
YarrowSimulationResult? _activeYarrowSimulation;
int _visibleYarrowLineCount = 0;
bool _isYarrowAnimating = false;
```

Remove `_yarrowCtrl.dispose()` and `_yarrowCtrl.clear()`.

- [ ] **Step 2: Initialize yarrow preference**

Add to `initState`:

```dart
@override
void initState() {
  super.initState();
  _saveYarrowProcessDetail =
      ref.read(storageServiceProvider).saveYarrowProcessDetail;
}
```

If `initState` does not exist yet, add it above `dispose()`.

- [ ] **Step 3: Reset yarrow animation state**

Add helper:

```dart
void _resetYarrowState() {
  _activeYarrowSimulation = null;
  _visibleYarrowLineCount = 0;
  _isYarrowAnimating = false;
}
```

Call `_resetYarrowState()` inside `_resetForm()` and when switching segmented methods.

- [ ] **Step 4: Route yarrow selection to simulation**

In `_startDivination`, replace the current `_selectedMethod == 2` manual input branch with:

```dart
    } else {
      await _handleYarrowSimulation(question);
      return;
    }
```

Add method:

```dart
Future<void> _handleYarrowSimulation(String question) async {
  final divService = ref.read(divinationServiceProvider);
  final simulation = divService.generateYarrowSimulation();
  final methodDetailJson = _saveYarrowProcessDetail
      ? jsonEncode(simulation.detail.toJson())
      : null;

  setState(() {
    _activeYarrowSimulation = simulation;
    _visibleYarrowLineCount = 0;
    _isYarrowAnimating = true;
  });

  for (int i = 1; i <= simulation.lines.length; i++) {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || !_isYarrowAnimating) return;
    setState(() => _visibleYarrowLineCount = i);
  }

  if (!mounted) return;
  setState(() => _isYarrowAnimating = false);
  _showResultDialog(
    simulation.lines,
    question,
    '籌策',
    methodDetailJson: methodDetailJson,
  );
}
```

- [ ] **Step 5: Add skip action**

Add:

```dart
void _skipYarrowAnimation() {
  final simulation = _activeYarrowSimulation;
  final question = _questionController.text.trim();
  if (simulation == null || question.isEmpty) return;

  final methodDetailJson = _saveYarrowProcessDetail
      ? jsonEncode(simulation.detail.toJson())
      : null;

  setState(() {
    _visibleYarrowLineCount = simulation.lines.length;
    _isYarrowAnimating = false;
  });

  _showResultDialog(
    simulation.lines,
    question,
    '籌策',
    methodDetailJson: methodDetailJson,
  );
}
```

Update `_showResultDialog` signature:

```dart
void _showResultDialog(
  List<int> lines,
  String question,
  String method, {
  String? methodDetailJson,
}) async {
```

Pass the value into `DivinationResultScreen`:

```dart
methodDetailJson: methodDetailJson,
```

- [ ] **Step 6: Show yarrow animation instead of generic animation**

In `build`, change the body child selection to:

```dart
child: _isYarrowAnimating
    ? _buildYarrowAnimationView()
    : _isAnimating
        ? _buildAnimationView()
        : _buildMainForm(primary),
```

Add `_buildYarrowAnimationView()`:

```dart
Widget _buildYarrowAnimationView() {
  final simulation = _activeYarrowSimulation;
  final primary = Theme.of(context).colorScheme.primary;
  final visibleLines = simulation == null
      ? <int>[]
      : simulation.lines.take(_visibleYarrowLineCount).toList();

  return Center(
    key: const ValueKey('yarrow-animating'),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '籌策推演中',
            style: GoogleFonts.notoSansTc(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '分二 · 掛一 · 揲四 · 歸奇',
            style: TextStyle(color: Colors.grey[300], fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildYarrowStalksMock(primary),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            children: List.generate(6, (index) {
              final hasValue = index < visibleLines.length;
              return Chip(
                label: Text(hasValue ? '${visibleLines[index]}' : '·'),
                backgroundColor: hasValue
                    ? primary.withValues(alpha: 0.18)
                    : Theme.of(context).colorScheme.surface,
              );
            }),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _skipYarrowAnimation,
            icon: const Icon(Icons.skip_next),
            label: const Text('略過動畫'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildYarrowStalksMock(Color primary) {
  return Container(
    height: 140,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: primary.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStalkBundle(7, primary),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('分', style: TextStyle(color: primary, fontSize: 22)),
        ),
        _buildStalkBundle(6, primary),
      ],
    ),
  ).animateIfEnabled(
    widget.enableAnimations,
    (child) => child.animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1400.ms, color: Colors.white24),
  );
}

Widget _buildStalkBundle(int count, Color primary) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      count,
      (index) => Container(
        width: 6,
        height: 70 + ((index % 3) * 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 7: Replace yarrow input UI**

In `_buildMethodInput()`, replace the `_selectedMethod == 2` card with:

```dart
      return Card(
        key: const ValueKey(2),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.grass,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '模擬四營十八變，逐步得出六爻。',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('保存完整過程'),
                subtitle: const Text('關閉時僅保存卦象結果。'),
                value: _saveYarrowProcessDetail,
                onChanged: (value) async {
                  setState(() => _saveYarrowProcessDetail = value);
                  await ref
                      .read(storageServiceProvider)
                      .setSaveYarrowProcessDetail(value);
                },
              ),
            ],
          ),
        ),
      );
```

Update `_buildMethodHint()` yarrow text:

```dart
_ => '籌策：模擬傳統分二、掛一、揲四、歸奇的起卦過程。',
```

- [ ] **Step 8: Run analyzer**

Run: `flutter analyze`

Expected: no new analyzer errors from `divination_screen.dart`.

- [ ] **Step 9: Commit**

```bash
git add lib/views/divination_screen.dart
git commit -m "feat: add yarrow simulation entry flow"
```

---

### Task 7: Display Yarrow Detail in Record Detail

**Files:**
- Create: `lib/views/widgets/yarrow_detail_section.dart`
- Modify: `lib/views/record_detail_screen.dart`

- [ ] **Step 1: Create reusable detail widget**

Create `lib/views/widgets/yarrow_detail_section.dart`:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/yarrow_simulation.dart';

class YarrowDetailSection extends StatelessWidget {
  final String? methodDetailJson;

  const YarrowDetailSection({super.key, required this.methodDetailJson});

  bool get hasProcess => methodDetailJson != null && methodDetailJson!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (!hasProcess) {
      return _DetailShell(
        badge: '僅結果',
        badgeColor: Colors.grey,
        child: Text(
          '此紀錄只保存卦象結果，未保存籌策過程。',
          style: TextStyle(color: Colors.grey[400], height: 1.5),
        ),
      );
    }

    final detail = YarrowSimulationDetail.fromJson(
      jsonDecode(methodDetailJson!) as Map<String, dynamic>,
    );

    return _DetailShell(
      badge: '有過程',
      badgeColor: primary,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: const Text('籌策過程'),
        subtitle: const Text('展開查看分二、掛一、揲四、歸奇的十八變明細。'),
        children: detail.lines.map((line) {
          return ExpansionTile(
            title: Text('第 ${line.position} 爻 · ${line.inferredValue}'),
            children: line.changes.map((change) {
              return ListTile(
                dense: true,
                title: Text('第 ${change.changeIndex} 變'),
                subtitle: Text(
                  '分二：左 ${change.left}，右 ${change.right}；'
                  '掛一：${change.hang}；'
                  '揲四：左餘 ${change.leftRemainder}，右餘 ${change.rightRemainder}；'
                  '歸奇：去 ${change.removed}，餘 ${change.after}',
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailShell extends StatelessWidget {
  final String badge;
  final Color badgeColor;
  final Widget child;

  const _DetailShell({
    required this.badge,
    required this.badgeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grass, size: 18),
              const SizedBox(width: 8),
              const Text(
                '籌策明細',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Insert widget into record detail**

In `lib/views/record_detail_screen.dart`, add import:

```dart
import 'widgets/yarrow_detail_section.dart';
```

After the hexagram/result card and before AI interpretation, insert:

```dart
            if (widget.record.method == '籌策') ...[
              YarrowDetailSection(
                methodDetailJson: widget.record.methodDetailJson,
              ),
              const SizedBox(height: 32),
            ],
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`

Expected: no new errors from record detail or widget.

- [ ] **Step 4: Commit**

```bash
git add lib/views/widgets/yarrow_detail_section.dart lib/views/record_detail_screen.dart
git commit -m "feat: show yarrow process detail in records"
```

---

### Task 8: Add UI Regression Tests

**Files:**
- Modify: `test/views/welcoming_ux_test.dart` or create `test/views/yarrow_simulation_test.dart`

- [ ] **Step 1: Add yarrow UI test file**

Create `test/views/yarrow_simulation_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:changelog/services/storage_service.dart';
import 'package:changelog/views/divination_screen.dart';

void main() {
  testWidgets('yarrow method shows save-process switch and no manual input',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs, const FlutterSecureStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: DivinationScreen(enableAnimations: false),
        ),
      ),
    );

    await tester.tap(find.text('進階起卦方式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('籌策'));
    await tester.pumpAndSettle();

    expect(find.text('保存完整過程'), findsOneWidget);
    expect(find.text('模擬四營十八變，逐步得出六爻。'), findsOneWidget);
    expect(find.textContaining('輸入 6, 7, 8, 9'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test and adjust providers if needed**

Run: `flutter test test/views/yarrow_simulation_test.dart`

Expected: PASS. If it fails because the app requires other providers, add the same overrides used by existing view tests in `test/views/welcoming_ux_test.dart`.

- [ ] **Step 3: Commit**

```bash
git add test/views/yarrow_simulation_test.dart
git commit -m "test: cover yarrow simulation entry UI"
```

---

### Task 9: Full Verification

**Files:**
- All files touched above

- [ ] **Step 1: Run service tests**

Run:

```bash
flutter test test/services/divination_service_test.dart test/services/data_transfer_service_test.dart
```

Expected: all tests pass.

- [ ] **Step 2: Run view tests**

Run:

```bash
flutter test test/views/welcoming_ux_test.dart test/views/yarrow_simulation_test.dart
```

Expected: all tests pass.

- [ ] **Step 3: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no analyzer errors.

- [ ] **Step 4: Run full test suite**

Run:

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Manual smoke test**

Run the app and verify:

```bash
flutter run -d macos
```

Manual checks:

- Open `進階起卦方式`.
- Select `籌策`.
- Confirm `保存完整過程` appears and defaults on.
- Enter a question.
- Press `開始一卦` or the yarrow action button.
- Confirm yarrow animation shows traditional terms and accumulating line values.
- Press `略過動畫` and confirm it navigates to the same generated result.
- Save without AI.
- Open the record and confirm `有過程` appears.
- Turn off `保存完整過程`, repeat, and confirm new record shows `僅結果`.

- [ ] **Step 6: Final commit if verification required touch-ups**

```bash
git status --short
git add docs/superpowers/plans/2026-05-06-yarrow-stalk-simulation.md
git commit -m "fix: complete yarrow simulation verification"
```

---

## Self-Review

- Spec coverage:
  - Real yarrow simulation: Task 2.
  - One-click six-line generation and skip animation: Task 6.
  - Traditional terms with readable state: Task 6.
  - Optional structured process saving: Tasks 3, 4, 5, 6.
  - `rawHexagramNumbersStr` as canonical result source: Tasks 1, 3, 5.
  - `有過程` / `僅結果` labels: Task 7.
  - Backup/restore support: Task 3.
  - Tests and verification: Tasks 1, 2, 3, 8, 9.
- Placeholder scan: no placeholder tokens or unspecified implementation steps should remain.
- Type consistency:
  - `YarrowSimulationDetail`, `YarrowLineDetail`, `YarrowChange`, and `YarrowSimulationResult` are introduced before use.
  - `methodDetailJson` is a nullable `String?` on records and is passed unchanged through result/save/export/import flows.
  - Final line values remain in `rawHexagramNumbersStr`, while yarrow detail only stores process data.
