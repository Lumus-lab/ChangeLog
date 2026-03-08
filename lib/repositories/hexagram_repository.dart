import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hexagram.dart';

class HexagramRepository {
  List<Hexagram> _hexagrams = [];

  /// 載入 64 卦資料
  Future<void> loadHexagrams() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/hexagrams.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString);

    // 載入 彖傳
    final String tuanString = await rootBundle.loadString(
      'assets/data/tuan.json',
    );
    final Map<String, dynamic> tuanMap = jsonDecode(tuanString);

    _hexagrams = jsonList.map((json) {
      final hexagramJson = Map<String, dynamic>.from(json);
      // 從 tuan.json 中讀取對應的 彖傳
      final id = hexagramJson['id'] as int;
      hexagramJson['tuan'] = tuanMap['iching__$id'];
      return Hexagram.fromJson(hexagramJson);
    }).toList();
  }

  /// 取得所有卦
  List<Hexagram> getAll() => _hexagrams;

  /// 根據 ID (1~64) 取得卦
  Hexagram? getById(int id) {
    if (id < 1 || id > 64) return null;
    try {
      return _hexagrams.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根據名稱取得卦
  Hexagram? getByName(String name) {
    try {
      return _hexagrams.firstWhere((h) => h.name == name);
    } catch (e) {
      return null;
    }
  }
}
