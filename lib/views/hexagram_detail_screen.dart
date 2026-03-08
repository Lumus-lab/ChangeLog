import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/hexagram.dart';

class HexagramDetailScreen extends StatelessWidget {
  final Hexagram hexagram;

  const HexagramDetailScreen({super.key, required this.hexagram});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text('第 ${hexagram.id} 卦')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Hero(
                tag: 'hexagram_id_${hexagram.id}',
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    hexagram.name,
                    style: TextStyle(
                      fontSize: 48,
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
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
              return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: primary.withValues(alpha: 0.2)),
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
                              color: primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getLineName(index),
                              style: TextStyle(
                                color: primary,
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
                                  hexagram.lines[index],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                if (hexagram.smallImages != null &&
                                    index < hexagram.smallImages!.length) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '象曰：${hexagram.smallImages![index]}',
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
                  )
                  .animate()
                  .fadeIn(delay: (400 + (50 * index)).ms)
                  .slideY(begin: 0.1, end: 0);
            }),
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

  String _getLineName(int index) {
    const names = ['初', '二', '三', '四', '五', '上'];
    if (index >= 0 && index < names.length) {
      return '${names[index]}爻'; // 這裡先簡化，待結合陰陽屬性後可變初九/初六
    }
    return '未知爻';
  }
}
