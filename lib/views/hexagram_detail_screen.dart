import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/hexagram.dart';

import 'widgets/hexagram_widget.dart';

class HexagramDetailScreen extends StatelessWidget {
  final Hexagram hexagram;

  const HexagramDetailScreen({super.key, required this.hexagram});

  List<int> _getHexagramLines() {
    // 從爻辭中解析陰陽屬性 (前六爻)
    // 陽爻為 7 (少陽), 陰爻為 8 (少陰)
    return hexagram.lines.take(6).map((line) {
      if (line.contains('九')) return 7;
      if (line.contains('六')) return 8;
      return 7; // 預設為陽
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final drawnLines = _getHexagramLines();

    return Scaffold(
      appBar: AppBar(title: Text('第 ${hexagram.id} 卦')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Name on Left, Hexagram on Right
            Center(
              child: Hero(
                tag: 'hexagram_id_${hexagram.id}',
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left: Name
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hexagram.name,
                            style: TextStyle(
                              fontSize: 64,
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${hexagram.name}卦',
                            style: TextStyle(
                              fontSize: 18,
                              color: primary.withValues(alpha: 0.7),
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                      // Divider
                      Container(
                        height: 100,
                        width: 1,
                        color: primary.withValues(alpha: 0.3),
                      ),
                      // Right: Hexagram Graphic
                      HexagramWidget(
                        lines: drawnLines,
                        lineWidth: 100,
                        lineHeight: 14,
                        spacing: 10,
                        yangColor: primary,
                        yinColor: primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              context,
              '卦辭',
              hexagram.description,
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
            if (hexagram.tuan != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                '彖傳',
                hexagram.tuan!,
              ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),
            ],
            if (hexagram.greatImage != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                '大象傳',
                hexagram.greatImage!,
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
            ],
            const SizedBox(height: 32),
            Text(
              '爻辭',
              style: TextStyle(
                color: primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            ...List.generate(hexagram.lines.length, (index) {
              return _buildLineCard(
                context,
                primary,
                _getLineName(index),
                hexagram.lines[index],
                (hexagram.smallImages != null &&
                        index < hexagram.smallImages!.length)
                    ? hexagram.smallImages![index]
                    : null,
              )
                  .animate()
                  .fadeIn(delay: (400 + (50 * index)).ms)
                  .slideY(begin: 0.1, end: 0);
            }),
            if (hexagram.useLine != null) ...[
              const SizedBox(height: 12),
              _buildLineCard(
                context,
                primary,
                hexagram.id == 1 ? '用九' : '用六',
                hexagram.useLine!,
                hexagram.useLineSmallImage,
                isSpecial: true,
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
            ],
            if (hexagram.wenYan != null) ...[
              const SizedBox(height: 32),
              _buildSection(
                context,
                '文言傳',
                hexagram.wenYan!,
              ).animate().fadeIn(delay: 800.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineCard(
    BuildContext context,
    Color primary,
    String label,
    String content,
    String? smallImage, {
    bool isSpecial = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSpecial
              ? Colors.amber.withValues(alpha: 0.5)
              : primary.withValues(alpha: 0.2),
          width: isSpecial ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSpecial
                    ? Colors.amber.withValues(alpha: 0.2)
                    : primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSpecial ? Colors.amber[700] : primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  if (smallImage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '象曰：$smallImage',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLineName(int index) {
    const names = ['初', '二', '三', '四', '五', '上'];
    if (index >= 0 && index < names.length) {
      return '${names[index]}爻';
    }
    return '未知爻';
  }
}
