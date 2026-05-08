import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/hexagram.dart';
import '../services/storage_service.dart';
import '../constants/ai_config.dart';
import '../utils/yao_utils.dart';

class NoAdCreditsException implements Exception {
  final String message;
  NoAdCreditsException([this.message = '無免費解卦額度，請觀看廣告以獲取次數。']);
  @override
  String toString() => message;
}

class AIInterpreterService {
  final StorageService _storage;

  final String _workerUrl =
      dotenv.env['WORKER_URL'] ??
      (throw StateError('WORKER_URL 未在 .env 中設定，請確認 .env 檔案包含 WORKER_URL。'));
  final String _appId = 'com.lumusxlab.changelog';

  AIInterpreterService(this._storage);

  Future<String> interpret({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    Hexagram? mutualHexagram,
    required String guidance,
    required List<int> lines,
  }) async {
    // 1. Check for BYOK API Key
    final byokKey = await _storage.getByokApiKey();

    if (byokKey != null && byokKey.isNotEmpty) {
      // 專業模式：自備 API Key (BYOK) - Direct Connection
      return _interpretDirectly(
        apiKey: byokKey,
        question: question,
        primaryHexagram: primaryHexagram,
        resultingHexagram: resultingHexagram,
        mutualHexagram: mutualHexagram,
        guidance: guidance,
        lines: lines,
      );
    } else {
      // 預設模式：Cloudflare Worker (檢查廣告額度)
      if (_storage.adCredits <= 0) {
        throw NoAdCreditsException();
      }

      try {
        final result = await _interpretViaWorker(
          question: question,
          primaryHexagram: primaryHexagram,
          resultingHexagram: resultingHexagram,
          mutualHexagram: mutualHexagram,
          guidance: guidance,
          lines: lines,
        );
        // Deduct 1 credit upon success
        await _storage.deductAdCredit();
        return result;
      } catch (e) {
        throw Exception('雲端解卦發生錯誤：$e');
      }
    }
  }

  /// 組裝統一的 AI prompt（BYOK 與 Worker 共用）
  static String buildPrompt({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    Hexagram? mutualHexagram,
    required String guidance,
    required List<int> lines,
  }) {
    final promptBuffer = StringBuffer();
    promptBuffer.writeln(
      '你是一位深研《易經》哲學的引導者。你的目標不是「算命」或「給予指令」，而是透過卦象中蘊含的「時」與「位」的智慧，協助使用者看清目前情境的結構、張力與可觀察的變化。',
    );
    promptBuffer.writeln('使用者目前的具體困惑是：「$question」');
    promptBuffer.writeln(
      '得出的本卦為：【${primaryHexagram.name}卦】（卦辭：${primaryHexagram.description}）',
    );

    // 列出動爻及其爻辭，加強 AI 對「位」的認知
    List<int> changingIndices = [];
    for (int i = 0; i < lines.length; i++) {
      if (lines[i] == 6 || lines[i] == 9) {
        changingIndices.add(i);
      }
    }

    if (changingIndices.isNotEmpty) {
      promptBuffer.writeln('變爻資訊：');
      for (var idx in changingIndices) {
        if (idx >= 0 && idx < primaryHexagram.lines.length) {
          final name = getYaoName(idx, lines[idx]);
          promptBuffer.writeln('- $name：${primaryHexagram.lines[idx]}');
        }
      }
    }

    if (resultingHexagram != null) {
      promptBuffer.writeln(
        '之卦為：【${resultingHexagram.name}卦】（卦辭：${resultingHexagram.description}）',
      );
    }
    if (mutualHexagram != null) {
      promptBuffer.writeln(
        '互卦為：【${mutualHexagram.name}卦】（卦辭：${mutualHexagram.description}）。互卦只作補充視角，用來觀察事情的內在結構或隱藏動因，不可凌駕本卦、變爻、之卦與朱熹解卦法則。',
      );
    }
    promptBuffer.writeln('根據傳統朱熹解卦法則，目前的觀測重心為：「$guidance」');

    promptBuffer.writeln('\n請遵循以下原則進行解析：');
    promptBuffer.writeln('1. 不要給予直接的建議或下一步該怎麼做的指令。不可使用「你應該」「你必須」「立刻去做」這類命令語。');
    promptBuffer.writeln(
      '2. 可以明確指出卦象傾向、張力、警訊或正在形成的變化，但要用「這卦比較像是在提醒...」「目前關鍵可能是...」「可觀察的是...」這類觀察語氣。',
    );
    promptBuffer.writeln(
      '3. 著重於分析「時 (Timing)」與「位 (Position, Status)」。根據變爻的位置與爻辭，說明目前情境是偏向蓄勢、受阻、調整、等待、推進，或正在轉折。',
    );
    promptBuffer.writeln('4. 互卦若存在，請放在「互卦補充」段落，只能作為輔助，不要讓互卦成為主判斷。');
    promptBuffer.writeln('5. 格式規範：');
    promptBuffer.writeln('   - 不要自我介紹。');
    promptBuffer.writeln('   - 僅使用以下 Markdown 標題，且順序不可改：');
    promptBuffer.writeln('     ### 卦象一句話');
    promptBuffer.writeln('     ### 時與位');
    promptBuffer.writeln('     ### 變動重點');
    if (mutualHexagram != null) {
      promptBuffer.writeln('     ### 互卦補充');
    }
    promptBuffer.writeln('     ### 留給你的觀察題');
    promptBuffer.writeln('   - 每個標題下只寫 1 到 2 句，段落間留一個空行。');
    promptBuffer.writeln('   - 不要使用 Markdown 引用區塊，也就是不要使用 >。');
    promptBuffer.writeln(
      '   - 可以使用粗體，但不要把粗體放在引號內，也不要輸出「**文字**」或 "**文字**" 這類引號與粗體混用格式。',
    );
    promptBuffer.writeln('   - 最後必須提出一個反思性提問，讓使用者自己決定下一步。');
    promptBuffer.writeln('6. 篇幅限制。解析字數請控制在 450 字以內，格式簡潔易讀。');

    return promptBuffer.toString();
  }

  Future<String> _interpretDirectly({
    required String apiKey,
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    Hexagram? mutualHexagram,
    required String guidance,
    required List<int> lines,
  }) async {
    final model = GenerativeModel(model: AIConfig.geminiModel, apiKey: apiKey);

    final prompt = buildPrompt(
      question: question,
      primaryHexagram: primaryHexagram,
      resultingHexagram: resultingHexagram,
      mutualHexagram: mutualHexagram,
      guidance: guidance,
      lines: lines,
    );

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? '無法產生解析，請稍後再試。';
    } catch (e) {
      throw Exception('直連 Google 解卦發生錯誤：$e\n請檢查您的 API Key 是否有效。');
    }
  }

  Future<String> _interpretViaWorker({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    Hexagram? mutualHexagram,
    required String guidance,
    required List<int> lines,
  }) async {
    final prompt = buildPrompt(
      question: question,
      primaryHexagram: primaryHexagram,
      resultingHexagram: resultingHexagram,
      mutualHexagram: mutualHexagram,
      guidance: guidance,
      lines: lines,
    );

    // Call Cloudflare Worker — 直接傳完整 prompt，Worker 只負責轉發
    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {
        'Content-Type': 'application/json',
        'app-id': _appId,
      },
      body: jsonEncode({
        'prompt': prompt,
        'adToken': 'placeholder-token',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['interpretation'] != null) {
        return data['interpretation'];
      }
      throw Exception('無效的回傳格式');
    } else {
      throw Exception('HTTP Status ${response.statusCode}: ${response.body}');
    }
  }
}
