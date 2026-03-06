import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/hexagram.dart';

class AIInterpreterService {
  Future<String> interpret({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    required String guidance,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key 尚未設定。請確認 .env 檔案中是否包含 GEMINI_API_KEY。');
    }

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: apiKey,
    );

    final promptBuffer = StringBuffer();
    promptBuffer.writeln('你是一位精通《易經》與現代心理學的解卦大師。');
    promptBuffer.writeln('使用者想問的具體問題是：「$question」');
    promptBuffer.writeln(
      '算出的本卦是：【${primaryHexagram.name}卦】（卦辭：${primaryHexagram.description}）',
    );
    if (resultingHexagram != null) {
      promptBuffer.writeln(
        '變卦為：【${resultingHexagram.name}卦】（卦辭：${resultingHexagram.description}）',
      );
    }
    promptBuffer.writeln('根據傳統朱熹解卦法則，目前的解卦重心為：「$guidance」');

    promptBuffer.writeln(
      '\n請以「解卦大師」的口吻，用溫和、客觀、且現代人容易理解的白話文，結合使用者的問題，給予約 300 字以內的指引與實質建議。',
    );

    try {
      final content = [Content.text(promptBuffer.toString())];
      final response = await model.generateContent(content);
      return response.text ?? '無法產生解析，請稍後再試。';
    } catch (e) {
      throw Exception('AI 解卦過程中發生錯誤：$e');
    }
  }
}
