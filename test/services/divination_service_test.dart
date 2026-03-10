import 'package:flutter_test/flutter_test.dart';
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

  group('generateNumberDivination', () {
    test('produces exactly 6 lines with one changing line', () {
      final lines = service.generateNumberDivination(168, 399, 825);
      expect(lines.length, 6);

      final changingCount = lines.where((v) => v == 6 || v == 9).length;
      expect(changingCount, 1, reason: '數字占 always has exactly one changing line');
    });

    test('all values are in {6, 7, 8, 9}', () {
      final lines = service.generateNumberDivination(100, 200, 300);
      for (final val in lines) {
        expect(val, isIn([6, 7, 8, 9]));
      }
    });

    test('remainder 0 means 上爻 (index 5) is changing', () {
      final lines = service.generateNumberDivination(100, 200, 6);
      expect(lines[5] == 6 || lines[5] == 9, isTrue,
          reason: 'Index 5 (上爻) should be the changing line when num3 divisible by 6');
    });

    test('remainder 1 means 初爻 (index 0) is changing', () {
      final lines = service.generateNumberDivination(100, 200, 7);
      expect(lines[0] == 6 || lines[0] == 9, isTrue,
          reason: 'Index 0 (初爻) should be the changing line when num3 % 6 == 1');
    });
  });

  group('generateYarrowDivination', () {
    test('returns null for invalid input length', () {
      expect(service.generateYarrowDivination([6, 7, 8]), isNull);
      expect(service.generateYarrowDivination([6, 7, 8, 9, 7, 8, 7]), isNull);
    });

    test('returns input for valid 6-element list with values in {6,7,8,9}', () {
      final input = [6, 7, 8, 9, 7, 8];
      final result = service.generateYarrowDivination(input);
      expect(result, input);
    });
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
}
