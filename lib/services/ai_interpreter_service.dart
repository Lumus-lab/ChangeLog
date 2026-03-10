import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/hexagram.dart';
import '../services/storage_service.dart';
import '../constants/ai_config.dart';

class NoAdCreditsException implements Exception {
  final String message;
  NoAdCreditsException([this.message = '無免費解卦額度，請觀看廣告以獲取次數。']);
  @override
  String toString() => message;
}

class AIInterpreterService {
  final StorageService _storage;

  final String _workerUrl = dotenv.env['WORKER_URL'] ??
      (throw StateError('WORKER_URL 未在 .env 中設定，請確認 .env 檔案包含 WORKER_URL。'));
  final String _appId = 'com.lumusxlab.changelog';

  AIInterpreterService(this._storage);

  Future<String> interpret({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
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
  String _buildPrompt({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    required String guidance,
    required List<int> lines,
  }) {
    final promptBuffer = StringBuffer();
    promptBuffer.writeln(
      '你是一位深研《易經》哲學的引導者。你的目標不是「算命」或「給予指令」，而是透過卦象中蘊含的「時」與「位」的智慧，引發使用者深度思考，從而發現自己的路。',
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
          final name = _getYaoName(idx, lines[idx]);
          promptBuffer.writeln('- $name：${primaryHexagram.lines[idx]}');
        }
      }
    }

    if (resultingHexagram != null) {
      promptBuffer.writeln(
        '之卦為：【${resultingHexagram.name}卦】（卦辭：${resultingHexagram.description}）',
      );
    }
    promptBuffer.writeln('根據傳統朱熹解卦法則，目前的觀測重心為：「$guidance」');

    promptBuffer.writeln('\n請遵循以下原則進行解析：');
    promptBuffer.writeln('1. **絕對不要給予直接的建議或下一步該怎麼做的指令。** 你的任務是解釋現狀的「動態性質」。');
    promptBuffer.writeln(
      '2. **著重於分析「時 (Timing)」與「位 (Position, Status)」**。根據上述變爻的「位置」與「爻辭」內容，解析目前的情境是屬於積蓄力量、等待時機、還是該順勢而為？使用者的內在狀態與外在環境處於什麼樣的相對位置？',
    );
    promptBuffer.writeln(
      '3. **啟發與發現**。用客觀、富有哲理且溫和的白話，解析卦象如何對映使用者的問題，最後提出一個「反思性的提問」，讓使用者自己決定下一步。',
    );
    promptBuffer.writeln('4. **格式規範**：');
    promptBuffer.writeln('   - 不要自我介紹。');
    promptBuffer.writeln('   - 開場請用：「針對您求問的『$question』，目前的卦象呈現為『${primaryHexagram.name}』...」');
    promptBuffer.writeln('   - 使用標準 Markdown 格式（**粗體**、### 標題）。');
    promptBuffer.writeln('   - 最後必須提出一個「反思性提問」，讓使用者自己決定下一步。');
    promptBuffer.writeln('5. **篇幅限制**。解析字數請控制在 350 字以內，格式簡潔易讀。');

    return promptBuffer.toString();
  }

  Future<String> _interpretDirectly({
    required String apiKey,
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    required String guidance,
    required List<int> lines,
  }) async {
    final model = GenerativeModel(
      model: AIConfig.geminiModel,
      apiKey: apiKey,
    );

    final prompt = _buildPrompt(
      question: question,
      primaryHexagram: primaryHexagram,
      resultingHexagram: resultingHexagram,
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
    required String guidance,
    required List<int> lines,
  }) async {
    final prompt = _buildPrompt(
      question: question,
      primaryHexagram: primaryHexagram,
      resultingHexagram: resultingHexagram,
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

  String _getYaoName(int index, int value) {
    final bool isYang = (value == 7 || value == 9);
    final String type = isYang ? "九" : "六";

    switch (index) {
      case 0:
        return "初$type";
      case 1:
        return "$type二";
      case 2:
        return "$type三";
      case 3:
        return "$type四";
      case 4:
        return "$type五";
      case 5:
        return "上$type";
      default:
        return "";
    }
  }
}
