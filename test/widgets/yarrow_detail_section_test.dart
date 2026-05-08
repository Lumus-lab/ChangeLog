import 'dart:convert';

import 'package:changelog/models/yarrow_simulation.dart';
import 'package:changelog/views/widgets/yarrow_detail_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders result-only fallback when detail json is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: YarrowDetailSection(methodDetailJson: null)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('籌策明細'), findsOneWidget);
    expect(find.text('僅結果'), findsOneWidget);
    expect(find.text('此紀錄只保存卦象結果，未保存籌策過程。'), findsOneWidget);
  });

  testWidgets(
    'renders a fallback instead of throwing for invalid detail json',
    (tester) async {
      const invalidDetails = [
        '   ',
        '{',
        '[]',
        '{"type":"yarrow"}',
        '{"lines":[]}',
        '{"lines":[{"position":1,"changes":[]}]}',
      ];

      for (final invalidDetail in invalidDetails) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: YarrowDetailSection(methodDetailJson: invalidDetail),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('籌策明細'), findsOneWidget);
        expect(find.text('僅結果'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == '此紀錄只保存卦象結果，未保存籌策過程。' ||
                    widget.data == '籌策過程資料無法讀取。'),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('renders valid yarrow process detail with traditional terms', (
    tester,
  ) async {
    final detailJson = jsonEncode(
      YarrowSimulationDetail(
        lines: List.generate(
          6,
          (index) =>
              YarrowLineDetail(position: index + 1, changes: _validChanges),
        ),
      ).toJson(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: YarrowDetailSection(methodDetailJson: detailJson),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('有過程'), findsOneWidget);
    expect(find.text('籌策過程'), findsOneWidget);

    await tester.tap(find.text('籌策過程'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 爻 · 6'));
    await tester.pumpAndSettle();

    expect(find.text('第 1 變'), findsOneWidget);
    expect(
      find.text('分二：左 24，右 25；掛一：1；揲四：左餘 4，右餘 4；歸奇：去 9，餘 40'),
      findsOneWidget,
    );
  });

  testWidgets('falls back when detail values differ from canonical raw lines', (
    tester,
  ) async {
    final detailJson = jsonEncode(
      YarrowSimulationDetail(
        lines: List.generate(
          6,
          (index) =>
              YarrowLineDetail(position: index + 1, changes: _validChanges),
        ),
      ).toJson(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YarrowDetailSection(
            methodDetailJson: detailJson,
            rawLines: const [7, 7, 7, 7, 7, 7],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('僅結果'), findsOneWidget);
    expect(find.text('籌策過程資料無法讀取。'), findsOneWidget);
    expect(find.text('有過程'), findsNothing);
  });

  testWidgets('falls back when change arithmetic is internally inconsistent', (
    tester,
  ) async {
    final invalidChanges = [
      const YarrowChange(
        changeIndex: 1,
        before: 49,
        left: 24,
        right: 25,
        hang: 1,
        leftRemainder: 4,
        rightRemainder: 4,
        removed: 5,
        after: 40,
      ),
      _validChanges[1],
      _validChanges[2],
    ];
    final detailJson = jsonEncode(
      YarrowSimulationDetail(
        lines: List.generate(
          6,
          (index) =>
              YarrowLineDetail(position: index + 1, changes: invalidChanges),
        ),
      ).toJson(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YarrowDetailSection(
            methodDetailJson: detailJson,
            rawLines: const [6, 6, 6, 6, 6, 6],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('僅結果'), findsOneWidget);
    expect(find.text('籌策過程資料無法讀取。'), findsOneWidget);
    expect(find.text('有過程'), findsNothing);
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
