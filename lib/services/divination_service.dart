import 'dart:math';

import '../models/yarrow_simulation.dart';

class DivinationService {
  final Random _random;

  DivinationService({Random? random}) : _random = random ?? Random();

  /// 金錢卦 (三枚銅錢)
  /// 丟六次，每次產生 6, 7, 8, 或 9
  /// 機率：
  /// - 6 (老陰): 1/8
  /// - 7 (少陽): 3/8
  /// - 8 (少陰): 3/8
  /// - 9 (老陽): 1/8
  List<int> generateCoinDivination() {
    List<int> lines = [];
    for (int i = 0; i < 6; i++) {
      lines.add(generateSingleCoin());
    }
    return lines;
  }

  /// 直覺起卦
  /// 作為新手預設流程，不要求使用者先理解數字占、金錢卦或籌策。
  List<int> generateIntuitiveDivination() {
    return generateCoinDivination();
  }

  /// 擲一次三枚銅錢，產生一個爻 (6, 7, 8, 或 9)
  int generateSingleCoin() {
    int sum = 0;
    for (int coin = 0; coin < 3; coin++) {
      // 假設 2 為陰面(字), 3 為陽面(人頭)
      sum += _random.nextBool() ? 3 : 2;
    }
    return sum;
  }

  /// 數字占 (梅花易數中的數字起卦)
  /// 輸入三個數字 (大於0)
  /// number1: 下卦 (除以8取餘數)
  /// number2: 上卦 (除以8取餘數)
  /// number3: 變爻 (除以6取餘數，1~6)
  /// 回傳：包含六個數字(6, 7, 8, 9)的 List
  List<int> generateNumberDivination(int num1, int num2, int num3) {
    // 依先天八卦數：乾1 兌2 離3 震4 巽5 坎6 艮7 坤8
    int lowerTrigramNumber = num1 % 8;
    if (lowerTrigramNumber == 0) lowerTrigramNumber = 8;

    int upperTrigramNumber = num2 % 8;
    if (upperTrigramNumber == 0) upperTrigramNumber = 8;

    // --- 關鍵修正：依照使用者要求的餘數規則定變爻 ---
    // 餘1=初爻, 餘2=二爻, 餘3=三爻, 餘4=四爻, 餘5=五爻, 餘0(整除)=上爻
    int remainder = num3 % 6;
    int changingYaoPosition; // 1 to 6
    if (remainder == 0) {
      changingYaoPosition = 6; // 上爻
    } else {
      changingYaoPosition = remainder;
    }

    // 轉換為 0-based index (0=初爻, 5=上爻)
    int targetIndex = changingYaoPosition - 1;

    // 將八卦數轉換為三爻 (由下而上)
    List<int> lowerLines = _trigramNumberToBinaryLines(lowerTrigramNumber);
    List<int> upperLines = _trigramNumberToBinaryLines(upperTrigramNumber);

    // 組合本卦 (Index 0~2 為下卦, 3~5 為上卦)
    List<int> hexagramLines = [...lowerLines, ...upperLines];

    // 轉換為少陽(7)與少陰(8)
    List<int> linesBase = hexagramLines.map((b) => b == 1 ? 7 : 8).toList();

    // 執行變爻：7(少陽) -> 9(老陽); 8(少陰) -> 6(老陰)
    if (linesBase[targetIndex] == 7) {
      linesBase[targetIndex] = 9;
    } else {
      linesBase[targetIndex] = 6;
    }

    return linesBase;
  }

  /// 籌策模擬：四營十八變，六爻由下而上生成。
  YarrowSimulationResult generateYarrowSimulation() {
    final lineDetails = <YarrowLineDetail>[];
    final lines = <int>[];

    for (int position = 1; position <= 6; position++) {
      final lineDetail = _generateYarrowLine(position);
      lineDetails.add(lineDetail);
      lines.add(lineDetail.inferredValue);
    }

    return YarrowSimulationResult(
      lines: lines,
      detail: YarrowSimulationDetail(lines: lineDetails),
    );
  }

  YarrowLineDetail _generateYarrowLine(int position) {
    var stalks = 49;
    final changes = <YarrowChange>[];

    for (int changeIndex = 1; changeIndex <= 3; changeIndex++) {
      final change = _performYarrowChange(
        stalks: stalks,
        changeIndex: changeIndex,
      );
      changes.add(change);
      stalks = change.after;
    }

    return YarrowLineDetail(position: position, changes: changes);
  }

  YarrowChange _performYarrowChange({
    required int stalks,
    required int changeIndex,
  }) {
    final left = _random.nextInt(stalks - 1) + 1;
    final right = stalks - left;
    const hang = 1;
    final rightAfterHang = right - hang;
    final leftRemainder = _yarrowRemainder(left);
    final rightRemainder = _yarrowRemainder(rightAfterHang);
    final removed = hang + leftRemainder + rightRemainder;

    return YarrowChange(
      changeIndex: changeIndex,
      before: stalks,
      left: left,
      right: right,
      hang: hang,
      leftRemainder: leftRemainder,
      rightRemainder: rightRemainder,
      removed: removed,
      after: stalks - removed,
    );
  }

  int _yarrowRemainder(int stalks) {
    final remainder = stalks % 4;
    return remainder == 0 ? 4 : remainder;
  }

  /// 將八卦數轉換成三爻 (0下, 1中, 2上)
  List<int> _trigramNumberToBinaryLines(int number) {
    switch (number) {
      case 1:
        return [1, 1, 1]; // 乾 ☰ (陽陽陽)
      case 2:
        return [1, 1, 0]; // 兌 ☱ (陽陽陰)
      case 3:
        return [1, 0, 1]; // 離 ☲ (陽陰陽)
      case 4:
        return [1, 0, 0]; // 震 ☳ (陽陰陰)
      case 5:
        return [0, 1, 1]; // 巽 ☴ (陰陽陽)
      case 6:
        return [0, 1, 0]; // 坎 ☵ (陰陽陰)
      case 7:
        return [0, 0, 1]; // 艮 ☶ (陰陰陽)
      case 8:
        return [0, 0, 0]; // 坤 ☷ (陰陰陰)
      default:
        return [1, 1, 1];
    }
  }

  /// 根據 6, 7, 8, 9 算出本卦 (Primary Hexagram) 的 ID (1-64)
  /// 這裡採用通用的二進位映射或查表法
  int calculatePrimaryHexagramId(List<int> lines) {
    return _linesToHexagramId(lines, isResulting: false);
  }

  /// 根據 6, 7, 8, 9 算出之卦 (Resulting Hexagram) 的 ID
  /// 若無變爻 (也就是沒有 6 且沒有 9)，回傳 null
  int? calculateResultingHexagramId(List<int> lines) {
    if (!lines.contains(6) && !lines.contains(9)) {
      return null;
    }
    return _linesToHexagramId(lines, isResulting: true);
  }

  /// 根據本卦計算互卦 (又稱核卦)。
  /// 互卦取本卦第 2、3、4 爻為下卦，第 3、4、5 爻為上卦。
  int calculateMutualHexagramId(List<int> lines) {
    if (lines.length != 6) {
      throw ArgumentError.value(lines, 'lines', '互卦計算需要剛好六爻');
    }

    final primaryBinaryLines = lines
        .map((line) => (line == 7 || line == 9) ? 1 : 0)
        .toList();
    final mutualLines = [
      primaryBinaryLines[1],
      primaryBinaryLines[2],
      primaryBinaryLines[3],
      primaryBinaryLines[2],
      primaryBinaryLines[3],
      primaryBinaryLines[4],
    ];

    return _lookupHexagramId(mutualLines);
  }

  /// 通用的 Hexagram 計算
  int _linesToHexagramId(List<int> lines, {required bool isResulting}) {
    List<int> binaryLines = lines.map((l) {
      if (!isResulting) {
        // 本卦: 7(陽), 9(陽), 8(陰), 6(陰)
        return (l == 7 || l == 9) ? 1 : 0;
      } else {
        // 變卦: 7(陽不受影響), 9(陽變陰), 8(陰不受影響), 6(陰變陽)
        return (l == 7 || l == 6) ? 1 : 0;
      }
    }).toList();

    return _lookupHexagramId(binaryLines);
  }

  // 二進位轉 64 卦 ID (通行本序)
  // 初爻為最低位 (index 0)
  int _lookupHexagramId(List<int> binaryLines) {
    // 格式化為字串進行查表，比如 [1, 1, 1, 1, 1, 1] 為 "111111"
    String binaryStr = binaryLines.join();
    return _kingWenMap[binaryStr] ?? 1;
  }

  /// 通行本六十四卦與二進位(由下而上)的對應表
  static const Map<String, int> _kingWenMap = {
    '111111': 1, // 乾
    '000000': 2, // 坤
    '100010': 3, // 屯
    '010001': 4, // 蒙
    '111010': 5, // 需
    '010111': 6, // 訟
    '010000': 7, // 師
    '000010': 8, // 比
    '111011': 9, // 小畜
    '110111': 10, // 履
    '111000': 11, // 泰
    '000111': 12, // 否
    '101111': 13, // 同人
    '111101': 14, // 大有
    '001000': 15, // 謙
    '000100': 16, // 豫
    '100110': 17, // 隨
    '011001': 18, // 蠱
    '110000': 19, // 臨
    '000011': 20, // 觀
    '100101': 21, // 噬嗑
    '101001': 22, // 賁
    '000001': 23, // 剝
    '100000': 24, // 復
    '100111': 25, // 无妄
    '111001': 26, // 大畜
    '100001': 27, // 頤
    '011110': 28, // 大過
    '010010': 29, // 坎
    '101101': 30, // 離
    '001110': 31, // 咸
    '011100': 32, // 恆
    '001111': 33, // 遯
    '111100': 34, // 大壯
    '000101': 35, // 晉
    '101000': 36, // 明夷
    '101011': 37, // 家人
    '110101': 38, // 睽
    '001010': 39, // 蹇
    '010100': 40, // 解
    '110001': 41, // 損
    '100011': 42, // 益
    '111110': 43, // 夬
    '011111': 44, // 姤
    '000110': 45, // 萃
    '011000': 46, // 升
    '010110': 47, // 困
    '011010': 48, // 井
    '101110': 49, // 革
    '011101': 50, // 鼎
    '100100': 51, // 震
    '001001': 52, // 艮
    '001011': 53, // 漸
    '110100': 54, // 歸妹
    '101100': 55, // 豐
    '001101': 56, // 旅
    '011011': 57, // 巽
    '110110': 58, // 兌
    '010011': 59, // 渙
    '110010': 60, // 節
    '110011': 61, // 中孚
    '001100': 62, // 小過
    '101010': 63, // 既濟
    '010101': 64, // 未濟
  };
}
