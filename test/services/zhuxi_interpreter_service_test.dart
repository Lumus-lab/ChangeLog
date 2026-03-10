import 'package:flutter_test/flutter_test.dart';
import 'package:changelog/services/zhuxi_interpreter_service.dart';

void main() {
  late ZhuxiInterpreterService service;

  setUp(() {
    service = ZhuxiInterpreterService();
  });

  group('getInterpretationGuidance', () {
    test('0 變爻 → 以本卦卦辭判斷', () {
      final result = service.getInterpretationGuidance([7, 8, 7, 8, 7, 8]);
      expect(result, contains('本卦卦辭'));
      expect(result, contains('六爻皆靜'));
    });

    test('1 變爻 → 以本卦該爻爻辭判斷', () {
      // index 0 = 初爻, value 9 = 老陽 → 初九
      final result = service.getInterpretationGuidance([9, 7, 8, 7, 8, 7]);
      expect(result, contains('一爻變'));
      expect(result, contains('初九'));
      expect(result, contains('爻辭'));
    });

    test('1 變爻 (六二) → 正確爻名', () {
      // index 1 = 二爻, value 6 = 老陰 → 六二
      final result = service.getInterpretationGuidance([7, 6, 8, 7, 8, 7]);
      expect(result, contains('六二'));
    });

    test('2 變爻 → 以上面那個變爻為主', () {
      // index 0 (初九) 和 index 3 (九四)
      final result = service.getInterpretationGuidance([9, 7, 8, 9, 8, 7]);
      expect(result, contains('兩爻變'));
      expect(result, contains('九四'));
      expect(result, contains('為主'));
    });

    test('3 變爻 → 綜合本卦卦辭與之卦卦辭', () {
      final result = service.getInterpretationGuidance([9, 6, 9, 7, 8, 7]);
      expect(result, contains('三爻變'));
      expect(result, contains('本卦卦辭'));
      expect(result, contains('之卦卦辭'));
    });

    test('4 變爻 → 以之卦的兩個靜爻判斷', () {
      final result = service.getInterpretationGuidance([9, 6, 9, 6, 8, 7]);
      expect(result, contains('四爻變'));
      expect(result, contains('之卦'));
      expect(result, contains('靜爻'));
    });

    test('5 變爻 → 以之卦的唯一靜爻判斷', () {
      final result = service.getInterpretationGuidance([9, 6, 9, 6, 9, 7]);
      expect(result, contains('五爻變'));
      expect(result, contains('之卦'));
      expect(result, contains('靜爻'));
    });

    test('6 變爻 (全陽 → 乾) → 用九', () {
      final result = service.getInterpretationGuidance([9, 9, 9, 9, 9, 9]);
      expect(result, contains('六爻皆變'));
      expect(result, contains('用九'));
    });

    test('6 變爻 (全陰 → 坤) → 用六', () {
      final result = service.getInterpretationGuidance([6, 6, 6, 6, 6, 6]);
      expect(result, contains('六爻皆變'));
      expect(result, contains('用六'));
    });

    test('6 變爻 (非全陽全陰) → 以之卦卦辭判斷', () {
      final result = service.getInterpretationGuidance([9, 6, 9, 6, 9, 6]);
      expect(result, contains('六爻皆變'));
      expect(result, contains('之卦卦辭'));
    });
  });
}
