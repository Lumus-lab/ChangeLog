import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/database_provider.dart';
import 'repositories/objectbox_service.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);
  await dotenv.load(fileName: ".env");
  final objectBox = await ObjectBoxService.create();

  runApp(
    ProviderScope(
      overrides: [objectBoxProvider.overrideWithValue(objectBox)],
      child: const ChangeLogApp(),
    ),
  );
}

class ChangeLogApp extends StatelessWidget {
  const ChangeLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFFD000);
    const backgroundColor = Color(0xFF0D0D10);
    const surfaceColor = Color(0xFF19191D);

    return MaterialApp(
      title: 'ChangeLog 易經',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          onPrimary: Colors.black87,
          secondary: primaryColor,
          surface: surfaceColor,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryColor),
          titleTextStyle: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 10,
          shadowColor: primaryColor.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black87,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
