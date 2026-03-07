import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/hexagram.dart';
import '../services/storage_service.dart';

class NoAdCreditsException implements Exception {
  final String message;
  NoAdCreditsException([this.message = '無免費解卦額度，請觀看廣告以獲取次數。']);
  @override
  String toString() => message;
}

class AIInterpreterService {
  final StorageService _storage;

  // You would configure your actual Cloudflare Worker URL in .env or as a constant
  final String _workerUrl =
      dotenv.env['WORKER_URL'] ??
      'https://iching-gemini-proxy.your-subdomain.workers.dev';
  final String _appId = 'com.lumuslab.changelog';

  AIInterpreterService(this._storage);

  Future<String> interpret({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    required String guidance,
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
        );
        // Deduct 1 credit upon success
        await _storage.deductAdCredit();
        return result;
      } catch (e) {
        throw Exception('雲端解卦發生錯誤：$e');
      }
    }
  }

  Future<String> _interpretDirectly({
    required String apiKey,
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    required String guidance,
  }) async {
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
      throw Exception('直連 Google 解卦發生錯誤：$e\n請檢查您的 API Key 是否有效。');
    }
  }

  Future<String> _interpretViaWorker({
    required String question,
    required Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    required String guidance,
  }) async {
    // Call Cloudflare Worker
    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {
        'Content-Type': 'application/json',
        'app-id': _appId, // For basic Worker verification
      },
      body: jsonEncode({
        'question': question,
        'primaryHex': primaryHexagram.name,
        'resultingHex': resultingHexagram?.name,
        'guidance': guidance,
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
