// lib/features/home/scan_count_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// アプリ全体からアクセスできる累計スキャン回数のプロバイダー
final scanCountProvider = StateNotifierProvider<ScanCountNotifier, int>((ref) {
  return ScanCountNotifier();
});

class ScanCountNotifier extends StateNotifier<int> {
  // 初期値は0。コンストラクタでただちにローカルストレージからロードします。
  ScanCountNotifier() : super(0) {
    _load();
  }

  static const _key = 'total_scan_count';

  // アプリ起動時にローカルストレージから回数を読み込む
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 0;
  }

  // スキャンが成功するたびに呼ばれ、回数を+1して保存する
  Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_key) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_key, newCount);
    state = newCount; // UIを即座に更新
  }
}