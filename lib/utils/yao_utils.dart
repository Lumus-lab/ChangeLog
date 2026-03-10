/// 將爻的 index (0-based) 與數值轉換為傳統爻名
/// 例如：index=0, value=9 → "初九"；index=4, value=8 → "六五"
String getYaoName(int index, int value) {
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
