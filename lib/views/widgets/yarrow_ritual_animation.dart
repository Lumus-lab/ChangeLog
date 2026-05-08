import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/yarrow_simulation.dart';

class YarrowRitualAnimation extends StatefulWidget {
  final YarrowSimulationResult simulation;
  final int visibleLineCount;
  final bool enableAnimations;
  final double? progressOverride;

  const YarrowRitualAnimation({
    super.key,
    required this.simulation,
    required this.visibleLineCount,
    required this.enableAnimations,
    this.progressOverride,
  });

  @override
  State<YarrowRitualAnimation> createState() => _YarrowRitualAnimationState();
}

class _YarrowRitualAnimationState extends State<YarrowRitualAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _syncController();
  }

  @override
  void didUpdateWidget(YarrowRitualAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibleLineCount != widget.visibleLineCount) {
      _controller.value = 0;
    }
    _syncController();
  }

  void _syncController() {
    if (widget.enableAnimations && widget.progressOverride == null) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final lineIndex = widget.visibleLineCount.clamp(0, 5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = (widget.progressOverride ?? _controller.value).clamp(
          0.0,
          0.999,
        );
        final frame = _RitualFrame.fromProgress(
          lineIndex: lineIndex,
          progress: progress,
          detail: widget.simulation.detail,
        );

        return Column(
          children: [
            Text(
              '大衍之數五十',
              style: TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('yarrow-ritual-canvas'),
              width: double.infinity,
              height: 280,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _YarrowRitualPainter(
                        primary: primary,
                        surface: surface,
                        frame: frame,
                      ),
                    ),
                  ),
                  const _ZoneLabel(text: '太極不用', left: 0.42, top: 0.04),
                  const _ZoneLabel(text: '左堆', left: 0.30, top: 0.43),
                  const _ZoneLabel(text: '右堆', left: 0.66, top: 0.43),
                  const _ZoneLabel(text: '手指', left: 0.74, top: 0.14),
                  const _ZoneLabel(text: '歸奇', left: 0.13, top: 0.15),
                  Positioned(
                    left: 16,
                    bottom: 12,
                    child: _HexagramPreview(
                      lines: widget.simulation.lines
                          .take(widget.visibleLineCount)
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '第 ${lineIndex + 1} 爻 · 第 ${frame.change.changeIndex} 變',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              frame.phaseText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  final String text;
  final double left;
  final double top;

  const _ZoneLabel({required this.text, required this.left, required this.top});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * left,
                top: constraints.maxHeight * top,
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HexagramPreview extends StatelessWidget {
  final List<int> lines;

  const _HexagramPreview({required this.lines});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const positionNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本卦成形中',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
          const SizedBox(height: 4),
          ...List.generate(lines.length, (visualIndex) {
            final index = lines.length - 1 - visualIndex;
            final line = lines[index];
            final isYang = line == 7 || line == 9;
            return Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${positionNames[index]} $line',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ),
                  Expanded(
                    child: _LineMark(
                      isYang: isYang,
                      changing: line == 6 || line == 9,
                    ),
                  ),
                  if (line == 6 || line == 9)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.circle, size: 5, color: primary),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LineMark extends StatelessWidget {
  final bool isYang;
  final bool changing;

  const _LineMark({required this.isYang, required this.changing});

  @override
  Widget build(BuildContext context) {
    final color = changing
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade300;
    if (isYang) {
      return Container(height: 5, decoration: _lineDecoration(color));
    }
    return Row(
      children: [
        Expanded(
          child: Container(height: 5, decoration: _lineDecoration(color)),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(height: 5, decoration: _lineDecoration(color)),
        ),
      ],
    );
  }

  BoxDecoration _lineDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1.5),
    );
  }
}

class _RitualFrame {
  final YarrowChange change;
  final int phaseIndex;
  final double phaseProgress;

  const _RitualFrame({
    required this.change,
    required this.phaseIndex,
    required this.phaseProgress,
  });

  String get phaseText {
    return switch (phaseIndex) {
      0 => '分二以象兩：左 ${change.left}，右 ${change.right}',
      1 => '掛一以象三：取一策置於手指',
      2 =>
        '揲四以象四時：左右各四策一列；左餘 ${change.leftRemainder}，右餘 ${change.rightRemainder}',
      3 => '歸奇於扐：去 ${change.removed} 策，留 ${change.after} 策續變',
      _ => '合策再變：收回餘策，續推下一變',
    };
  }

  static _RitualFrame fromProgress({
    required int lineIndex,
    required double progress,
    required YarrowSimulationDetail detail,
  }) {
    final line = detail.lines[lineIndex.clamp(0, detail.lines.length - 1)];
    final scaled = progress * 15;
    final stage = scaled.floor().clamp(0, 14);
    return _RitualFrame(
      change: line.changes[(stage ~/ 5).clamp(0, line.changes.length - 1)],
      phaseIndex: stage % 5,
      phaseProgress: scaled - stage,
    );
  }
}

class _YarrowRitualPainter extends CustomPainter {
  final Color primary;
  final Color surface;
  final _RitualFrame frame;

  const _YarrowRitualPainter({
    required this.primary,
    required this.surface,
    required this.frame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [surface.withValues(alpha: 0.95), const Color(0xFF111114)],
      ).createShader(rect);
    final bounds = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(bounds, background);

    canvas.save();
    canvas.clipRRect(bounds);
    _drawZones(canvas, size);
    _drawStalks(canvas, size);
    canvas.restore();
  }

  void _drawZones(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primary.withValues(alpha: 0.14);
    for (final zone in [
      _point(size, 0.50, 0.12),
      _point(size, 0.36, 0.56),
      _point(size, 0.72, 0.56),
      _point(size, 0.78, 0.24),
      _point(size, 0.18, 0.24),
    ]) {
      canvas.drawCircle(zone, size.shortestSide * 0.08, paint);
    }
  }

  void _drawStalks(Canvas canvas, Size size) {
    final total = frame.change.before.clamp(24, 49);
    final stickPaint = Paint()
      ..color = primary.withValues(alpha: 0.82)
      ..strokeWidth = math.max(2.2, size.width * 0.006)
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = stickPaint.strokeWidth + 1.5
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < total; index++) {
      final from = _stalkPosition(size, index, frame, frame.phaseIndex - 1);
      final to = _stalkPosition(size, index, frame, frame.phaseIndex);
      final eased = Curves.easeOutCubic.transform(frame.phaseProgress);
      final center = Offset.lerp(from, to, eased)!;
      final angle = frame.phaseIndex == 2 || frame.phaseIndex == 3
          ? 0.0
          : _angle(index, frame.phaseIndex, frame.phaseProgress);
      final baseLength = frame.phaseIndex == 2 || frame.phaseIndex == 3
          ? 0.105
          : 0.17 + (index % 4) * 0.01;
      final length = size.shortestSide * baseLength;
      final delta = Offset(math.sin(angle), -math.cos(angle)) * length / 2;
      canvas.drawLine(
        center - delta + const Offset(1, 1),
        center + delta + const Offset(1, 1),
        shadowPaint,
      );
      canvas.drawLine(center - delta, center + delta, stickPaint);
    }

    final taijiPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.7)
      ..strokeWidth = stickPaint.strokeWidth
      ..strokeCap = StrokeCap.round;
    final taiji = _point(size, 0.50, 0.12);
    canvas.drawLine(
      taiji + Offset(0, -size.shortestSide * 0.07),
      taiji + Offset(0, size.shortestSide * 0.07),
      taijiPaint,
    );
  }

  Offset _stalkPosition(
    Size size,
    int index,
    _RitualFrame frame,
    int phaseIndex,
  ) {
    if (phaseIndex < 0) return _pile(size, index, 49, _point(size, 0.50, 0.64));

    final change = frame.change;
    final leftEnd = change.left;
    final handEnd = change.left + change.hang;
    final leftKeptEnd = change.left - change.leftRemainder;
    final rightStart = change.left;
    final rightAfterHangStart = rightStart + change.hang;
    final rightRemainderStart = change.before - change.rightRemainder;

    return switch (phaseIndex) {
      0 =>
        index < leftEnd
            ? _pile(size, index, change.left, _point(size, 0.36, 0.58))
            : _pile(
                size,
                index - leftEnd,
                change.right,
                _point(size, 0.72, 0.58),
              ),
      1 =>
        index < leftEnd
            ? _pile(size, index, change.left, _point(size, 0.36, 0.58))
            : index < handEnd
            ? _line(
                size,
                index - leftEnd,
                change.hang,
                _point(size, 0.78, 0.24),
              )
            : _pile(
                size,
                index - handEnd,
                change.right - change.hang,
                _point(size, 0.72, 0.58),
              ),
      2 =>
        index < leftKeptEnd
            ? _group(size, index, leftKeptEnd, _point(size, 0.36, 0.55))
            : index < leftEnd
            ? _line(
                size,
                index - leftKeptEnd,
                change.removed,
                _point(size, 0.78, 0.24),
              )
            : index < rightAfterHangStart
            ? _line(
                size,
                change.leftRemainder + index - rightStart,
                change.removed,
                _point(size, 0.78, 0.24),
              )
            : index < rightRemainderStart
            ? _group(
                size,
                index - rightAfterHangStart,
                change.right - change.hang - change.rightRemainder,
                _point(size, 0.72, 0.55),
              )
            : _line(
                size,
                change.leftRemainder +
                    change.hang +
                    index -
                    rightRemainderStart,
                change.removed,
                _point(size, 0.78, 0.24),
              ),
      3 =>
        _isRemovedStalk(index, change)
            ? _pile(
                size,
                _removedSlot(index, change),
                change.removed,
                _point(size, 0.18, 0.24),
              )
            : index < leftKeptEnd
            ? _group(size, index, leftKeptEnd, _point(size, 0.36, 0.55))
            : _group(
                size,
                index - rightAfterHangStart,
                change.right - change.hang - change.rightRemainder,
                _point(size, 0.72, 0.55),
              ),
      _ =>
        index < change.after
            ? _pile(size, index, change.after, _point(size, 0.50, 0.58))
            : _pile(
                size,
                index - change.after,
                change.removed,
                _point(size, 0.18, 0.24),
              ),
    };
  }

  Offset _point(Size size, double x, double y) {
    return Offset(size.width * x, size.height * y);
  }

  bool _isRemovedStalk(int index, YarrowChange change) {
    final leftRemainderStart = change.left - change.leftRemainder;
    final hangStart = change.left;
    final rightRemainderStart = change.before - change.rightRemainder;
    return (index >= leftRemainderStart && index < change.left) ||
        (index >= hangStart && index < hangStart + change.hang) ||
        index >= rightRemainderStart;
  }

  int _removedSlot(int index, YarrowChange change) {
    final leftRemainderStart = change.left - change.leftRemainder;
    final hangStart = change.left;
    final rightRemainderStart = change.before - change.rightRemainder;
    if (index < change.left) return index - leftRemainderStart;
    if (index < hangStart + change.hang) {
      return change.leftRemainder + index - hangStart;
    }
    return change.leftRemainder + change.hang + index - rightRemainderStart;
  }

  Offset _pile(Size size, int index, int count, Offset origin) {
    final seed = index * 12.9898 + count * 78.233;
    final radius = size.shortestSide * (0.02 + (index % 7) * 0.012);
    return origin +
        Offset(math.sin(seed) * radius * 1.45, math.cos(seed * 1.7) * radius);
  }

  Offset _line(Size size, int index, int count, Offset origin) {
    final spacing = size.width * 0.016;
    return origin + Offset((index - (count - 1) / 2) * spacing, 0);
  }

  Offset _group(Size size, int index, int count, Offset origin) {
    const stalksPerRow = 4;
    const maxRowsPerColumn = 4;
    final logicalRow = index ~/ stalksPerRow;
    final column = logicalRow ~/ maxRowsPerColumn;
    final row = logicalRow % maxRowsPerColumn;
    final col = index % stalksPerRow;
    final totalRows = math.max(1, (count / stalksPerRow).ceil());
    final columns = math.max(1, (totalRows / maxRowsPerColumn).ceil());
    final rowsInColumn = column == columns - 1
        ? totalRows - column * maxRowsPerColumn
        : maxRowsPerColumn;
    return origin +
        Offset(
          (column - (columns - 1) / 2) * size.width * 0.076 +
              (col - 1.5) * size.width * 0.024,
          (row - (rowsInColumn - 1) / 2) * size.height * 0.082,
        );
  }

  double _angle(int index, int phaseIndex, double phaseProgress) {
    return math.sin(index * 1.9 + phaseIndex + phaseProgress * math.pi) * 0.42;
  }

  @override
  bool shouldRepaint(covariant _YarrowRitualPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.surface != surface ||
        oldDelegate.frame != frame;
  }
}
