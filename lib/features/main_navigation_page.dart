// lib/features/main_navigation_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ★ 各タブのファイルをインポート（後ほど作成します）
import 'home/home_tab.dart';
import 'history/history_tab.dart';
import 'templates/templates_tab.dart';
import 'settings/settings_tab.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;

  // ★ 4つのタブ画面をリストで保持
  final List<Widget> _pages = const [
    HomeTab(),
    HistoryTab(),
    TemplatesTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // ★ 鮮やかなオーロラグラデーション背景をベース全体に適用
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0C3FC), // 淡い紫
            Color(0xFF8EC5FC), // スカイブルー
            Color(0xFFE0C3FC), // 淡い紫
          ],
          stops: [0.0, 0.5, 1.0], 
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // IndexedStack を使うことで、タブを切り替えても各画面の状態（スクロール位置など）を保持します
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        // ★ すりガラス風のボトムナビゲーションバー
        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: const Color(0xFF667EEA), // アクセントカラー
                unselectedItemColor: Colors.grey.shade500,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'ホーム',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: '履歴',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.file_copy_outlined),
                    activeIcon: Icon(Icons.file_copy),
                    label: 'テンプレ',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: '設定',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}