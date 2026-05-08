import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:changelog/models/yarrow_simulation.dart';
import 'package:changelog/services/divination_service.dart';

void main() {
  late DivinationService service;

  setUp(() {
    service = DivinationService();
  });

  group('generateCoinDivination', () {
    test('produces exactly 6 lines', () {
      final lines = service.generateCoinDivination();
      expect(lines.length, 6);
    });

    test('all values are in {6, 7, 8, 9}', () {
      for (int i = 0; i < 100; i++) {
        final lines = service.generateCoinDivination();
        for (final val in lines) {
          expect(val, isIn([6, 7, 8, 9]));
        }
      }
    });

    test('generateSingleCoin produces values in {6, 7, 8, 9}', () {
      for (int i = 0; i < 200; i++) {
        expect(service.generateSingleCoin(), isIn([6, 7, 8, 9]));
      }
    });
  });

  group('generateIntuitiveDivination', () {
    test('produces exactly 6 valid lines without requiring method inputs', () {
      final lines = service.generateIntuitiveDivination();

      expect(lines.length, 6);
      for (final val in lines) {
        expect(val, isIn([6, 7, 8, 9]));
      }
    });
  });

  group('generateNumberDivination', () {
    test('produces exactly 6 lines with one changing line', () {
      final lines = service.generateNumberDivination(168, 399, 825);
      expect(lines.length, 6);

      final changingCount = lines.where((v) => v == 6 || v == 9).length;
      expect(
        changingCount,
        1,
        reason: '數字占 always has exactly one changing line',
      );
    });

    test('all values are in {6, 7, 8, 9}', () {
      final lines = service.generateNumberDivination(100, 200, 300);
      for (final val in lines) {
        expect(val, isIn([6, 7, 8, 9]));
      }
    });

    test('remainder 0 means 上爻 (index 5) is changing', () {
      final lines = service.generateNumberDivination(100, 200, 6);
      expect(
        lines[5] == 6 || lines[5] == 9,
        isTrue,
        reason:
            'Index 5 (上爻) should be the changing line when num3 divisible by 6',
      );
    });

    test('remainder 1 means 初爻 (index 0) is changing', () {
      final lines = service.generateNumberDivination(100, 200, 7);
      expect(
        lines[0] == 6 || lines[0] == 9,
        isTrue,
        reason: 'Index 0 (初爻) should be the changing line when num3 % 6 == 1',
      );
    });
  });

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
          expect(
            change.removed,
            change.hang + change.leftRemainder + change.rightRemainder,
          );
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

  group('YarrowSimulationDetail JSON', () {
    test(
      'round-trips structured process detail without storing line values',
      () {
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
      },
    );
  });

  group('calculatePrimaryHexagramId', () {
    test('all yang (乾) returns hexagram 1', () {
      final id = service.calculatePrimaryHexagramId([7, 7, 7, 7, 7, 7]);
      expect(id, 1);
    });

    test('all yin (坤) returns hexagram 2', () {
      final id = service.calculatePrimaryHexagramId([8, 8, 8, 8, 8, 8]);
      expect(id, 2);
    });

    test('treats 9 as yang, 6 as yin for primary hexagram', () {
      final id = service.calculatePrimaryHexagramId([9, 9, 9, 9, 9, 9]);
      expect(id, 1);

      final id2 = service.calculatePrimaryHexagramId([6, 6, 6, 6, 6, 6]);
      expect(id2, 2);
    });
  });

  group('calculateResultingHexagramId', () {
    test('no changing lines returns null', () {
      final result = service.calculateResultingHexagramId([7, 8, 7, 8, 7, 8]);
      expect(result, isNull);
    });

    test('changing lines produce a different hexagram', () {
      // [9, 7, 7, 7, 7, 7] → 本卦 = 乾(1), 初爻老陽變陰 → 之卦 ≠ 1
      final result = service.calculateResultingHexagramId([9, 7, 7, 7, 7, 7]);
      expect(result, isNotNull);
      expect(result, isNot(1));
    });
  });

  group('calculateMutualHexagramId', () {
    test('all yang keeps 乾 as mutual hexagram', () {
      final id = service.calculateMutualHexagramId([7, 7, 7, 7, 7, 7]);
      expect(id, 1);
    });

    test('uses lines 2-4 as lower trigram and lines 3-5 as upper trigram', () {
      // 既濟 [陽, 陰, 陽, 陰, 陽, 陰] 的互卦：
      // 下互 = 2,3,4 爻 = 陰陽陰；上互 = 3,4,5 爻 = 陽陰陽；
      // 合成 [陰, 陽, 陰, 陽, 陰, 陽] = 未濟。
      final id = service.calculateMutualHexagramId([7, 8, 7, 8, 7, 8]);
      expect(id, 64);
    });
  });
}
