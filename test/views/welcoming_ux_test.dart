import 'package:changelog/views/divination_screen.dart';
import 'package:changelog/views/explanation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome card starts first launch without full instructions', (
    tester,
  ) async {
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FirstLaunchWelcomeSheet(
            onStart: () async => started = true,
            onCompleteAfterHelp: () async {},
          ),
        ),
      ),
    );

    expect(find.text('先問一件正在猶豫的事'), findsOneWidget);
    expect(find.text('ChangeLog 會幫你起卦、整理卦象，並留下日後可回顧的紀錄。'), findsOneWidget);
    expect(find.text('如何起卦？'), findsNothing);

    await tester.tap(find.text('開始'));
    await tester.pump();

    expect(started, isTrue);
  });

  testWidgets('divination home starts with question and hides advanced terms', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DivinationScreen(enableAnimations: false)),
      ),
    );
    await tester.pump();

    expect(find.text('先問一件正在猶豫的事'), findsOneWidget);
    expect(find.text('開始一卦'), findsOneWidget);
    expect(find.text('進階起卦方式'), findsOneWidget);
    expect(find.text('下卦數'), findsNothing);
    expect(find.text('上卦數'), findsNothing);
    expect(find.text('動爻數'), findsNothing);

    final logoBox = tester.widget<SizedBox>(
      find.byKey(const ValueKey('divination-background-logo')),
    );
    expect(logoBox.width, 520);
    expect(logoBox.height, 520);

    final logoAlign = tester.widget<Align>(
      find.byKey(const ValueKey('divination-background-logo-align')),
    );
    expect(logoAlign.alignment, Alignment.center);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
