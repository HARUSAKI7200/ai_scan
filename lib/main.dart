// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/app_database.dart';
import 'pages/home_page.dart';

// データベースのプロバイダー
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 画面の向きを固定（スマホ利用を想定して縦向きメインだが、必要に応じて解放）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: AiScanApp()));
}

class AiScanApp extends StatelessWidget {
  const AiScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Scan Excel',
      debugShowCheckedModeBanner: false,
      
      // テーマ設定: 清潔感のあるビジネスライクなデザイン
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        // ★修正: cardThemeの設定を削除（型エラー回避のため）
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),

      // 日本語化対応
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],

      home: const HomePage(),
    );
  }
}