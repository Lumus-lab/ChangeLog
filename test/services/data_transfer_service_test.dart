import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:changelog/models/divination_record.dart';

/// 測試 DataTransferService 的 JSON 序列化邏輯
void main() {
  group('DivinationRecord JSON round-trip', () {
    DivinationRecord createSampleRecord() {
      final record = DivinationRecord(
        createdAt: DateTime(2026, 3, 10, 12, 0, 0),
        question: '這個專案可以上架嗎？',
        method: '金錢卦',
        rawHexagramNumbersStr: jsonEncode([9, 7, 8, 7, 6, 8]),
        primaryHexagramId: 1,
        resultingHexagramId: 44,
        changingLinesStr: jsonEncode([0, 4]),
        methodDetailJson: '{"type":"yarrow","version":1,"lines":[]}',
        interpretation: '使用者自己的解讀',
        actionTaken: '繼續開發',
        actualOutcome: '順利上架',
        isResolved: true,
      );
      record.aiInterpretation = 'AI 解卦結果：乾卦轉姤卦...';
      return record;
    }

    Map<String, dynamic> recordToExportMap(DivinationRecord r) {
      return {
        'id': r.id,
        'createdAt': r.createdAt.toIso8601String(),
        'question': r.question,
        'method': r.method,
        'rawHexagramNumbersStr': r.rawHexagramNumbersStr,
        'primaryHexagramId': r.primaryHexagramId,
        'resultingHexagramId': r.resultingHexagramId,
        'changingLinesStr': r.changingLinesStr,
        'methodDetailJson': r.methodDetailJson,
        'interpretation': r.interpretation,
        'aiInterpretation': r.aiInterpretation,
        'actionTaken': r.actionTaken,
        'actualOutcome': r.actualOutcome,
        'isResolved': r.isResolved,
      };
    }

    DivinationRecord importFromMap(Map<String, dynamic> item) {
      final record = DivinationRecord(
        createdAt: DateTime.parse(item['createdAt']),
        question: item['question'] ?? '未命名紀錄',
        method: item['method'] ?? '未知',
        rawHexagramNumbersStr: item['rawHexagramNumbersStr'],
        primaryHexagramId: item['primaryHexagramId'] ?? 1,
        resultingHexagramId: item['resultingHexagramId'],
        changingLinesStr: item['changingLinesStr'],
        methodDetailJson: item['methodDetailJson'],
        interpretation: item['interpretation'],
        actionTaken: item['actionTaken'],
        actualOutcome: item['actualOutcome'],
        isResolved: item['isResolved'] ?? false,
      );
      record.aiInterpretation = item['aiInterpretation'];
      return record;
    }

    test('export map contains all fields including aiInterpretation', () {
      final record = createSampleRecord();
      final map = recordToExportMap(record);

      expect(map.containsKey('aiInterpretation'), isTrue);
      expect(map['aiInterpretation'], 'AI 解卦結果：乾卦轉姤卦...');
      expect(map['question'], '這個專案可以上架嗎？');
      expect(map['primaryHexagramId'], 1);
      expect(map['resultingHexagramId'], 44);
      expect(map['isResolved'], true);
    });

    test('round-trip preserves all data', () {
      final original = createSampleRecord();
      final map = recordToExportMap(original);

      final jsonStr = jsonEncode(map);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = importFromMap(decoded);

      expect(restored.question, original.question);
      expect(restored.method, original.method);
      expect(restored.primaryHexagramId, original.primaryHexagramId);
      expect(restored.resultingHexagramId, original.resultingHexagramId);
      expect(restored.interpretation, original.interpretation);
      expect(restored.aiInterpretation, original.aiInterpretation);
      expect(restored.actionTaken, original.actionTaken);
      expect(restored.actualOutcome, original.actualOutcome);
      expect(restored.isResolved, original.isResolved);
      expect(restored.rawHexagramNumbersStr, original.rawHexagramNumbersStr);
      expect(restored.changingLinesStr, original.changingLinesStr);
      expect(restored.methodDetailJson, original.methodDetailJson);
    });

    test('import handles missing aiInterpretation gracefully', () {
      final map = {
        'createdAt': '2026-03-10T12:00:00.000',
        'question': '測試問題',
        'method': '金錢卦',
        'primaryHexagramId': 1,
        'isResolved': false,
      };

      final record = importFromMap(map);
      expect(record.aiInterpretation, isNull);
      expect(record.question, '測試問題');
    });

    test('import handles null optional fields gracefully', () {
      final map = {
        'createdAt': '2026-03-10T12:00:00.000',
        'question': null,
        'method': null,
        'primaryHexagramId': null,
        'isResolved': null,
      };

      final record = importFromMap(map);
      expect(record.question, '未命名紀錄');
      expect(record.method, '未知');
      expect(record.primaryHexagramId, 1);
      expect(record.isResolved, false);
    });
  });
}
