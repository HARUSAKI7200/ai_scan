// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'database/app_database.dart';
import 'features/main_navigation_page.dart'; // ★ HomePageから変更

// データベースのプロバイダー
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ステータスバーの色を透明に設定
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: AiScanApp()));
}

class AiScanApp extends StatelessWidget {
  const AiScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // グラスモーフィズムに合う、少し青みがかったアクセントカラー
    const accentColor = Color(0xFF667EEA); 

    return MaterialApp(
      title: 'AI Scan Excel',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        useMaterial3: true,
        // ★ 背景は各画面でグラデーションを描画するため透明に設定
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'NotoSansJP',
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          primary: accentColor,
          // すりガラス感を邪魔しないように表面色も透明ベースに
          surface: Colors.transparent, 
        ),
        
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0, 
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E293B),
          titleTextStyle: TextStyle(
            fontFamily: 'NotoSansJP',
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // ボタンも少し丸みを帯びたリッチなデザインに
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4, 
            shadowColor: accentColor.withOpacity(0.5),
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          // 入力フォーム自体も少し透けさせる
          fillColor: Colors.white.withOpacity(0.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accentColor, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],

      // ★ 起動画面を MainNavigationPage に変更
      home: const MainNavigationPage(),
    );
  }
}