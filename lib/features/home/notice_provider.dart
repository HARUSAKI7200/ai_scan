// lib/features/home/notice_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// お知らせデータを表現するモデルクラス
class AppNotice {
  final String id;
  final String title;
  final String message;
  final String type; // 'info'(青), 'warning'(黄), 'error'(赤: 障害等)
  final bool isActive;
  final DateTime createdAt;

  AppNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });

  factory AppNotice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotice(
      id: doc.id,
      title: data['title'] as String? ?? 'お知らせ',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'info',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Firestoreから有効なお知らせをリアルタイム取得するプロバイダー
final activeNoticesProvider = StreamProvider<List<AppNotice>>((ref) {
  return FirebaseFirestore.instance
      .collection('notices')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => AppNotice.fromFirestore(doc)).toList();
  });
});

// ==========================================
// 追加: 通知の既読管理（赤ポチ用）
// ==========================================

/// ユーザーが最後に通知一覧画面を開いた日時を保存・管理するプロバイダー
final lastReadTimeProvider = StateNotifierProvider<LastReadTimeNotifier, DateTime>((ref) {
  return LastReadTimeNotifier();
});

class LastReadTimeNotifier extends StateNotifier<DateTime> {
  // 初期値は過去の日時（1970年）にしておくことで、初回はすべて未読扱いにする
  LastReadTimeNotifier() : super(DateTime.fromMillisecondsSinceEpoch(0)) {
    _load();
  }

  static const _key = 'last_notice_read_time';

  // ローカルストレージから前回開いた日時を読み込む
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_key);
    if (millis != null) {
      state = DateTime.fromMillisecondsSinceEpoch(millis);
    }
  }

  // 通知画面を開いた時に呼び出し、現在時刻を「最後に読んだ時間」として保存する
  Future<void> updateReadTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_key, now.millisecondsSinceEpoch);
    state = now;
  }
}

/// 「未読のお知らせがあるか」を判定するプロバイダー
final hasUnreadNoticeProvider = Provider<bool>((ref) {
  final noticesAsync = ref.watch(activeNoticesProvider);
  final lastReadTime = ref.watch(lastReadTimeProvider);

  return noticesAsync.maybeWhen(
    data: (notices) {
      if (notices.isEmpty) return false;
      // リストの先頭（一番新しい通知）の日時が、最後に開いた日時より新しければ「未読あり」
      final latestNoticeTime = notices.first.createdAt;
      return latestNoticeTime.isAfter(lastReadTime);
    },
    orElse: () => false,
  );
});