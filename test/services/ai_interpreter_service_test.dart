import 'package:flutter_test/flutter_test.dart';
import 'package:changelog/models/hexagram.dart';
import 'package:changelog/services/ai_interpreter_service.dart';

void main() {
  group('AIInterpreterService.buildPrompt', () {
    test('requires a readable fixed template and forbids fragile markdown', () {
      final prompt = AIInterpreterService.buildPrompt(
        question: '我該不該接受這個合作邀請？',
        primaryHexagram: _hexagram(35, '晉', '康侯用錫馬蕃庶，晝日三接。'),
        resultingHexagram: _hexagram(16, '豫', '利建侯行師。'),
        mutualHexagram: _hexagram(39, '蹇', '利西南，不利東北；利見大人，貞吉。'),
        guidance: '一爻變 (六二)：請以【本卦 六二】的爻辭來判斷吉凶。',
        lines: [7, 6, 8, 7, 8, 7],
      );

      expect(prompt, contains('### 卦象一句話'));
      expect(prompt, contains('### 時與位'));
      expect(prompt, contains('### 變動重點'));
      expect(prompt, contains('### 互卦補充'));
      expect(prompt, contains('### 留給你的觀察題'));
      expect(prompt, contains('互卦為：【蹇卦】'));
      expect(prompt, contains('不要使用 Markdown 引用區塊'));
      expect(prompt, contains('不要把粗體放在引號內'));
      expect(prompt, contains('可以明確指出卦象傾向、張力、警訊或正在形成的變化'));
      expect(prompt, contains('不可使用「你應該」「你必須」「立刻去做」'));
    });
  });
}

Hexagram _hexagram(int id, String name, String description) {
  return Hexagram(
    id: id,
    name: name,
    description: description,
    lines: const [
      '初六：測試爻辭。',
      '六二：測試爻辭。',
      '六三：測試爻辭。',
      '九四：測試爻辭。',
      '六五：測試爻辭。',
      '上九：測試爻辭。',
    ],
  );
}
