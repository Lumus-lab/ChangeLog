import 'package:objectbox/objectbox.dart';
import 'dart:convert';

@Entity()
class DivinationRecord {
  @Id()
  int id = 0;

  /// 起卦時間
  @Property(type: PropertyType.date)
  DateTime createdAt;

  /// 占卜事項 / 動機 (為什麼要算這個卦？)
  String question;

  /// 起卦方式 (數字占 / 金錢卦 / 籌策)
  String method;

  /// 紀錄起卦時的六個原始數值 (存成 JSON 字串 "[6, 7, 8, 9, 7, 8]")
  String? rawHexagramNumbersStr;

  /// 本卦 (Primary Hexagram) 1~64的ID或名稱
  int primaryHexagramId;

  /// 之卦 (Relating Hexagram) 1~64的ID或名稱 (若無變爻則為null)
  int? resultingHexagramId;

  /// 變爻位置 (例如: "[2, 5]" 代表第二爻和第五爻變)
  String? changingLinesStr;

  /// 自己如何解卦 (解讀與心得)
  String? interpretation;

  /// AI 輔助解卦紀錄
  String? aiInterpretation;

  /// 決定怎麼做 (Action Plan)
  String? actionTaken;

  /// 事後驗證 (過一陣子之後這件事情實際發展如何)
  String? actualOutcome;

  /// 使用者是否標記為「已驗證/已結案」
  bool isResolved;

  DivinationRecord({
    this.id = 0,
    required this.createdAt,
    required this.question,
    required this.method,
    this.rawHexagramNumbersStr,
    required this.primaryHexagramId,
    this.resultingHexagramId,
    this.changingLinesStr,
    this.interpretation,
    this.actionTaken,
    this.actualOutcome,
    this.isResolved = false,
  });

  // 便利的 Getter / Setter 讓業務邏輯能直接操作 List<int>
  List<int>? get rawHexagramNumbers {
    if (rawHexagramNumbersStr == null) return null;
    final List<dynamic> decoded = jsonDecode(rawHexagramNumbersStr!);
    return decoded.cast<int>();
  }

  set rawHexagramNumbers(List<int>? value) {
    if (value == null) {
      rawHexagramNumbersStr = null;
    } else {
      rawHexagramNumbersStr = jsonEncode(value);
    }
  }

  List<int> get changingLines {
    if (changingLinesStr == null) return [];
    final List<dynamic> decoded = jsonDecode(changingLinesStr!);
    return decoded.cast<int>();
  }

  set changingLines(List<int> value) {
    changingLinesStr = jsonEncode(value);
  }
}
