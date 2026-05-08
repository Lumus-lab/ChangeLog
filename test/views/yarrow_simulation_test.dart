import 'package:changelog/services/storage_service.dart';
import 'package:changelog/views/divination_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('yarrow method shows save-process switch and no manual input', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs, const FlutterSecureStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(
          home: DivinationScreen(enableAnimations: false),
        ),
      ),
    );

    await tester.tap(find.text('進階起卦方式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('籌策'));
    await tester.pumpAndSettle();

    expect(find.text('保存完整過程'), findsOneWidget);
    expect(find.text('模擬四營十八變，逐步得出六爻。'), findsOneWidget);
    expect(find.textContaining('輸入 6, 7, 8, 9'), findsNothing);
  });

  testWidgets(
    'yarrow simulation keeps ritual animation visible through the slower ritual',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs, const FlutterSecureStorage());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const MaterialApp(
            home: DivinationScreen(enableAnimations: false),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, '我該不該接受這個合作邀請？');
      await tester.tap(find.text('進階起卦方式'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('籌策'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('開始一卦'));
      await tester.pump();

      expect(find.text('籌策推演中'), findsOneWidget);
      expect(find.text('略過動畫'), findsOneWidget);
      expect(find.textContaining('完整推演約 48 秒'), findsOneWidget);

      for (var second = 0; second < 47; second++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('籌策推演中'), findsOneWidget);
      expect(find.text('略過動畫'), findsOneWidget);
    },
  );
}
