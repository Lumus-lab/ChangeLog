import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/yarrow_simulation.dart';

class YarrowDetailSection extends StatelessWidget {
  final String? methodDetailJson;
  final List<int>? rawLines;

  const YarrowDetailSection({
    super.key,
    required this.methodDetailJson,
    this.rawLines,
  });

  bool get hasProcess =>
      methodDetailJson != null && methodDetailJson!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (!hasProcess) {
      return _buildFallback(context, '此紀錄只保存卦象結果，未保存籌策過程。');
    }

    final detail = _parseDetail(methodDetailJson!.trim());
    if (detail == null) {
      return _buildFallback(context, '籌策過程資料無法讀取。');
    }

    return _DetailShell(
      badge: '有過程',
      badgeColor: primary,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: const Text('籌策過程'),
        subtitle: const Text('展開查看分二、掛一、揲四、歸奇的十八變明細。'),
        children: detail.lines.map((line) {
          return ExpansionTile(
            title: Text('第 ${line.position} 爻 · ${line.inferredValue}'),
            children: line.changes.map((change) {
              return ListTile(
                dense: true,
                title: Text('第 ${change.changeIndex} 變'),
                subtitle: Text(
                  '分二：左 ${change.left}，右 ${change.right}；'
                  '掛一：${change.hang}；'
                  '揲四：左餘 ${change.leftRemainder}，右餘 ${change.rightRemainder}；'
                  '歸奇：去 ${change.removed}，餘 ${change.after}',
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  YarrowSimulationDetail? _parseDetail(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final detail = YarrowSimulationDetail.fromJson(decoded);
      if (!_isValidDetail(detail)) {
        return null;
      }
      final canonicalLines = rawLines;
      if (canonicalLines != null &&
          (canonicalLines.length != 6 ||
              !_listEquals(detail.inferredLineValues, canonicalLines))) {
        return null;
      }
      return detail;
    } catch (_) {
      return null;
    }
  }

  bool _isValidDetail(YarrowSimulationDetail detail) {
    if (detail.type != 'yarrow' || detail.version != 1) return false;
    if (detail.lines.length != 6) return false;

    for (var lineIndex = 0; lineIndex < detail.lines.length; lineIndex++) {
      final line = detail.lines[lineIndex];
      if (line.position != lineIndex + 1 || line.changes.length != 3) {
        return false;
      }

      var expectedBefore = 49;
      for (
        var changeIndex = 0;
        changeIndex < line.changes.length;
        changeIndex++
      ) {
        final change = line.changes[changeIndex];
        final rightAfterHang = change.right - change.hang;
        if (change.changeIndex != changeIndex + 1 ||
            change.before != expectedBefore ||
            change.hang != 1 ||
            change.left <= 0 ||
            change.right <= 0 ||
            rightAfterHang < 0 ||
            change.left + change.right != change.before ||
            change.leftRemainder != _yarrowRemainder(change.left) ||
            change.rightRemainder != _yarrowRemainder(rightAfterHang) ||
            change.removed !=
                change.hang + change.leftRemainder + change.rightRemainder ||
            change.after != change.before - change.removed ||
            change.after <= 0 ||
            change.after % 4 != 0) {
          return false;
        }
        expectedBefore = change.after;
      }

      if (![6, 7, 8, 9].contains(line.inferredValue)) return false;
    }

    return true;
  }

  int _yarrowRemainder(int stalks) {
    final remainder = stalks % 4;
    return remainder == 0 ? 4 : remainder;
  }

  bool _listEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  Widget _buildFallback(BuildContext context, String message) {
    return _DetailShell(
      badge: '僅結果',
      badgeColor: Colors.grey,
      child: Text(
        message,
        style: TextStyle(color: Colors.grey[400], height: 1.5),
      ),
    );
  }
}

class _DetailShell extends StatelessWidget {
  final String badge;
  final Color badgeColor;
  final Widget child;

  const _DetailShell({
    required this.badge,
    required this.badgeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grass, size: 18),
              const SizedBox(width: 8),
              const Text('籌策明細', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
