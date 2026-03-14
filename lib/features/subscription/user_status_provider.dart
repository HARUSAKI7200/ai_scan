// lib/features/subscription/user_status_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum AppPlan { free, lite, pro }

class UserStatus {
  final AppPlan plan;
  final int currentMonthScans;
  final int tickets;
  final String lastScanMonth; // 月またぎのリセット判定用 "yyyy-MM"

  UserStatus({
    required this.plan,
    required this.currentMonthScans,
    required this.tickets,
    required this.lastScanMonth,
  });

  UserStatus copyWith({
    AppPlan? plan,
    int? currentMonthScans,
    int? tickets,
    String? lastScanMonth,
  }) {
    return UserStatus(
      plan: plan ?? this.plan,
      currentMonthScans: currentMonthScans ?? this.currentMonthScans,
      tickets: tickets ?? this.tickets,
      lastScanMonth: lastScanMonth ?? this.lastScanMonth,
    );
  }

  // 無料・有料に応じた今月の上限回数を返す
  int get monthlyLimit {
    switch (plan) {
      case AppPlan.free:
        return 10;
      case AppPlan.lite:
        return 500;
      case AppPlan.pro:
        return 1500;
    }
  }

  // サブスク枠を使い切っているか
  bool get isMonthlyLimitReached => currentMonthScans >= monthlyLimit;
}

final userStatusProvider = StateNotifierProvider<UserStatusNotifier, UserStatus>((ref) {
  return UserStatusNotifier();
});

class UserStatusNotifier extends StateNotifier<UserStatus> {
  UserStatusNotifier()
      : super(UserStatus(
          plan: AppPlan.free,
          currentMonthScans: 0,
          tickets: 0,
          lastScanMonth: DateFormat('yyyy-MM').format(DateTime.now()),
        )) {
    _load();
  }

  static const _keyPlan = 'user_plan';
  static const _keyScans = 'current_month_scans';
  static const _keyTickets = 'user_tickets';
  static const _keyLastMonth = 'last_scan_month';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 月またぎの判定
    final savedMonth = prefs.getString(_keyLastMonth) ?? '';
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    
    int scans = prefs.getInt(_keyScans) ?? 0;
    if (savedMonth != currentMonth) {
      // 月が変わっていたらスキャン回数をリセット
      scans = 0;
      await prefs.setInt(_keyScans, scans);
      await prefs.setString(_keyLastMonth, currentMonth);
    }

    final planString = prefs.getString(_keyPlan) ?? 'free';
    AppPlan plan = AppPlan.free;
    if (planString == 'lite') plan = AppPlan.lite;
    if (planString == 'pro') plan = AppPlan.pro;

    final tickets = prefs.getInt(_keyTickets) ?? 0;

    state = UserStatus(
      plan: plan,
      currentMonthScans: scans,
      tickets: tickets,
      lastScanMonth: currentMonth,
    );
  }

  // スキャン成功時に呼ばれる（回数またはチケットを消費）
  Future<void> consumeScan() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!state.isMonthlyLimitReached) {
      // サブスクの月間枠を消費
      final newScans = state.currentMonthScans + 1;
      await prefs.setInt(_keyScans, newScans);
      state = state.copyWith(currentMonthScans: newScans);
    } else if (state.tickets > 0) {
      // 月間枠を超えていたらチケットを消費
      final newTickets = state.tickets - 1;
      await prefs.setInt(_keyTickets, newTickets);
      state = state.copyWith(tickets: newTickets);
    }
  }

  // --- デバッグ・将来の課金処理用メソッド ---
  Future<void> addTickets(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newTickets = state.tickets + amount;
    await prefs.setInt(_keyTickets, newTickets);
    state = state.copyWith(tickets: newTickets);
  }

  Future<void> updatePlan(AppPlan newPlan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlan, newPlan.name);
    state = state.copyWith(plan: newPlan);
  }
}