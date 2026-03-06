class ZhuxiInterpreterService {
  /// 根據朱熹《易學啟蒙》規則，回傳應該優先閱讀的文本建議。
  /// [lines] 是由下而上的六個爻 (包含 6, 7, 8, 9)
  /// 回傳字串，包含閱讀建議與對應的爻/卦辭
  String getInterpretationGuidance(List<int> lines) {
    List<int> changingIndices = [];
    for (int i = 0; i < lines.length; i++) {
      if (lines[i] == 6 || lines[i] == 9) {
        changingIndices.add(i); // 0-based
      }
    }

    int changingCount = changingIndices.length;

    switch (changingCount) {
      case 0:
        return "六爻皆靜 (無動爻)：請以【本卦卦辭】來判斷吉凶。";
      case 1:
        return "一爻動：請以【本卦動爻】的爻辭來判斷吉凶。";
      case 2:
        return "兩爻動：請以【本卦的兩個動爻】之爻辭來判斷，但主要以【位置較高的動爻 (上動爻)】為主。";
      case 3:
        return "三爻動：請綜合參考【本卦卦辭】與【變卦卦辭】，且以【本卦卦辭】為主。";
      case 4:
        return "四爻動：請以【變卦的兩個靜爻】(沒有變的爻) 的爻辭來判斷，且主要以【位置較低的靜爻 (下靜爻)】為主。";
      case 5:
        return "五爻動：請以【變卦的唯一靜爻】之爻辭來判斷。";
      case 6:
        // 特例：乾卦與坤卦
        bool isAllYang = lines.every((l) => l == 9);
        bool isAllYin = lines.every((l) => l == 6);
        if (isAllYang) {
          return "六爻皆變：此為乾卦變成坤卦，請看乾卦的【用九】辭。";
        } else if (isAllYin) {
          return "六爻皆變：此為坤卦變成乾卦，請看坤卦的【用六】辭。";
        } else {
          return "六爻皆變：請以【變卦卦辭】來判斷吉凶。";
        }
      default:
        return "未知的爻變情形。";
    }
  }
}
