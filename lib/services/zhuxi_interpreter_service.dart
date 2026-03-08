class ZhuxiInterpreterService {
  /// 根據朱熹《易學啟蒙》規則，回傳應該優先閱讀的文本建議。
  /// [lines] 是由下而上的六個爻 (包含 6, 7, 8, 9)
  /// 回傳字串，包含閱讀建議與對應的爻/卦辭
  String getInterpretationGuidance(List<int> lines) {
    List<int> changingIndices = [];
    List<int> staticIndices = [];
    for (int i = 0; i < lines.length; i++) {
      if (lines[i] == 6 || lines[i] == 9) {
        changingIndices.add(i); // 0-based
      } else {
        staticIndices.add(i);
      }
    }

    int changingCount = changingIndices.length;

    switch (changingCount) {
      case 0:
        return "六爻皆靜 (無動爻)：請以【本卦卦辭】來判斷吉凶。";
      case 1:
        final name = _getYaoName(changingIndices[0]);
        return "一爻動 ($name 發動)：請以【本卦 $name】的爻辭來判斷吉凶。";
      case 2:
        final lower = _getYaoName(changingIndices[0]);
        final upper = _getYaoName(changingIndices[1]);
        return "兩爻動 ($lower, $upper 發動)：請以【本卦的兩個動爻】之爻辭來判斷，但主要以位置較高的【$upper】為主。";
      case 3:
        return "三爻動：請綜合參考【本卦卦辭】與【變卦卦辭】，且以【本卦卦辭】為主。";
      case 4:
        // 取兩個靜爻
        final lower = _getYaoName(staticIndices[0]);
        final upper = _getYaoName(staticIndices[1]);
        return "四爻動：請以【變卦的兩個靜爻】($lower, $upper) 的爻辭來判斷，且主要以位置較低的【$lower】為主。";
      case 5:
        final name = _getYaoName(staticIndices[0]);
        return "五爻動：請以【變卦的唯一靜爻 ($name)】之爻辭來判斷。";
      case 6:
        // 特例：乾卦與坤卦
        bool isAllYang = lines.every((l) => l == 9);
        bool isAllYin = lines.every((l) => l == 6);
        if (isAllYang) {
          return "六爻皆變：此為乾卦變成坤卦，請直接看乾卦的【用九】辭。";
        } else if (isAllYin) {
          return "六爻皆變：此為坤卦變成乾卦，請直接看坤卦的【用六】辭。";
        } else {
          return "六爻皆變：請以【變卦卦辭】來判斷吉凶。";
        }
      default:
        return "未知的爻變情形。";
    }
  }

  String _getYaoName(int index) {
    if (index == 0) return "初爻";
    if (index == 1) return "二爻";
    if (index == 2) return "三爻";
    if (index == 3) return "四爻";
    if (index == 4) return "五爻";
    if (index == 5) return "上爻";
    return "";
  }
}
