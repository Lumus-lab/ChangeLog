import 'package:flutter/material.dart';
import '../../models/hexagram.dart';
import '../hexagram_detail_screen.dart';
import 'hexagram_widget.dart';

/// 共用的卦象欄位 Widget（本卦 / 之卦）
/// 點擊可跳轉到 HexagramDetailScreen
class HexagramColumn extends StatelessWidget {
  final String title;
  final Hexagram hexagram;
  final List<int> originalLines;
  final bool isResulting;

  const HexagramColumn({
    super.key,
    required this.title,
    required this.hexagram,
    required this.originalLines,
    this.isResulting = false,
  });

  @override
  Widget build(BuildContext context) {
    // 若是變卦，需要把 6→7, 9→8 以確保只畫出靜態陰陽
    final drawnLines = isResulting
        ? originalLines.map((l) => (l == 6 || l == 7) ? 7 : 8).toList()
        : originalLines;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HexagramDetailScreen(hexagram: hexagram),
          ),
        );
      },
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 12),
          Text(
            hexagram.name,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          HexagramWidget(
            lines: drawnLines,
            lineWidth: 80,
            lineHeight: 12,
            spacing: 8,
            yangColor: Colors.white,
            yinColor: Colors.white,
            changingColor: isResulting ? Colors.white : Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            '點擊查看詳細',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
