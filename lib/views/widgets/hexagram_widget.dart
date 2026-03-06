import 'package:flutter/material.dart';

/// 將六個數字(6,7,8,9)繪製成直式的六爻圖形 (下爻在最底，上爻在最頂)
class HexagramWidget extends StatelessWidget {
  final List<int> lines; // 長度必須是 6，由下而上的 6, 7, 8, 9
  final double lineWidth;
  final double lineHeight;
  final double spacing;
  final Color yangColor;
  final Color yinColor;
  final Color changingColor;

  const HexagramWidget({
    super.key,
    required this.lines,
    this.lineWidth = 120.0,
    this.lineHeight = 12.0,
    this.spacing = 8.0,
    this.yangColor = Colors.white,
    this.yinColor = Colors.white,
    this.changingColor = Colors.red, // 動爻顏色
  });

  @override
  Widget build(BuildContext context) {
    if (lines.length != 6) {
      return const SizedBox();
    }

    // 陣列 index 0 也就是 input lines 的第一個，代表初爻(最下面)
    // 但在 Column 裡面，我們希望初爻在最下面，上爻在最上面
    // 所以我們需要把陣列反過來繪製
    final reversedLines = lines.reversed.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(6, (index) {
        final lineValue = reversedLines[index];
        final isYang = (lineValue == 7 || lineValue == 9);
        final isChanging = (lineValue == 6 || lineValue == 9);

        final color = isChanging
            ? changingColor
            : (isYang ? yangColor : yinColor);

        // 為了在爻與爻之間產生間距，除了最下面的爻之外，其他都在底部加 spacing
        final padding = EdgeInsets.only(bottom: index == 5 ? 0 : spacing);

        return Padding(
          padding: padding,
          child: isYang ? _buildYangLine(color) : _buildYinLine(color),
        );
      }),
    );
  }

  Widget _buildYangLine(Color color) {
    return Container(
      width: lineWidth,
      height: lineHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(lineHeight / 4),
      ),
    );
  }

  Widget _buildYinLine(Color color) {
    final gapWidth = lineWidth * 0.15;
    final solidWidth = (lineWidth - gapWidth) / 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: solidWidth,
          height: lineHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(lineHeight / 4),
            ),
          ),
        ),
        SizedBox(width: gapWidth),
        Container(
          width: solidWidth,
          height: lineHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(lineHeight / 4),
            ),
          ),
        ),
      ],
    );
  }
}
