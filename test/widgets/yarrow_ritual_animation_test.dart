import 'package:changelog/models/yarrow_simulation.dart';
import 'package:changelog/views/widgets/yarrow_ritual_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders ritual zones and current yarrow change', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YarrowRitualAnimation(
            simulation: _simulation,
            visibleLineCount: 0,
            enableAnimations: false,
            progressOverride: 0.50,
          ),
        ),
      ),
    );

    expect(find.text('大衍之數五十'), findsOneWidget);
    expect(find.text('太極不用'), findsOneWidget);
    expect(find.text('左堆'), findsOneWidget);
    expect(find.text('右堆'), findsOneWidget);
    expect(find.text('手指'), findsOneWidget);
    expect(find.text('歸奇'), findsOneWidget);
    expect(find.text('第 1 爻 · 第 2 變'), findsOneWidget);
    expect(find.textContaining('四策一列'), findsOneWidget);
  });

  testWidgets('uses a taller bounded canvas for grouped stalks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YarrowRitualAnimation(
            simulation: _simulation,
            visibleLineCount: 0,
            enableAnimations: false,
            progressOverride: 0.50,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('yarrow-ritual-canvas'))).height,
      280,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('describes remaining stalks without calling them remainders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YarrowRitualAnimation(
            simulation: _simulation,
            visibleLineCount: 0,
            enableAnimations: false,
            progressOverride: 0.22,
          ),
        ),
      ),
    );

    expect(find.textContaining('去 9 策'), findsOneWidget);
    expect(find.textContaining('留 40 策'), findsOneWidget);
    expect(find.textContaining('餘 40'), findsNothing);
  });

  testWidgets('renders completed line preview from canonical lines', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YarrowRitualAnimation(
            simulation: _simulation,
            visibleLineCount: 2,
            enableAnimations: false,
            progressOverride: 0,
          ),
        ),
      ),
    );

    expect(find.text('本卦成形中'), findsOneWidget);
    expect(find.text('初爻 6'), findsOneWidget);
    expect(find.text('二爻 7'), findsOneWidget);
    expect(find.text('三爻'), findsNothing);

    final firstLineTop = tester.getTopLeft(find.text('初爻 6')).dy;
    final secondLineTop = tester.getTopLeft(find.text('二爻 7')).dy;
    expect(firstLineTop, greaterThan(secondLineTop));
  });
}

const _validChanges = [
  YarrowChange(
    changeIndex: 1,
    before: 49,
    left: 24,
    right: 25,
    hang: 1,
    leftRemainder: 4,
    rightRemainder: 4,
    removed: 9,
    after: 40,
  ),
  YarrowChange(
    changeIndex: 2,
    before: 40,
    left: 20,
    right: 20,
    hang: 1,
    leftRemainder: 4,
    rightRemainder: 3,
    removed: 8,
    after: 32,
  ),
  YarrowChange(
    changeIndex: 3,
    before: 32,
    left: 16,
    right: 16,
    hang: 1,
    leftRemainder: 4,
    rightRemainder: 3,
    removed: 8,
    after: 24,
  ),
];

final _simulation = YarrowSimulationResult(
  lines: const [6, 7, 8, 9, 6, 7],
  detail: YarrowSimulationDetail(
    lines: List.generate(
      6,
      (index) => YarrowLineDetail(position: index + 1, changes: _validChanges),
    ),
  ),
);
