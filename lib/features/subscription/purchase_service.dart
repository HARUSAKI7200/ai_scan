// lib/features/subscription/purchase_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_status_provider.dart';

class PurchaseService {
  
  static Future<bool> purchaseSubscription(BuildContext context, WidgetRef ref, AppPlan plan) async {
    debugPrint('[AI_SCAN] 🔵 INFO: サブスクリプション購入処理を開始します。対象プラン: ${plan.name}');
    await _simulateNetworkDelay(context);

    await ref.read(userStatusProvider.notifier).updatePlan(plan);
    debugPrint('[AI_SCAN] 🟢 SUCCESS: サブスクリプション購入完了。プランを更新しました。');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getPlanName(plan)} に登録しました！', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
        ),
      );
    }
    return true;
  }

  static Future<bool> purchaseTickets(BuildContext context, WidgetRef ref, int amount) async {
    debugPrint('[AI_SCAN] 🔵 INFO: チケット購入処理を開始します。枚数: $amount');
    await _simulateNetworkDelay(context);

    await ref.read(userStatusProvider.notifier).addTickets(amount);
    debugPrint('[AI_SCAN] 🟢 SUCCESS: チケット購入完了。現在の保有枚数: ${ref.read(userStatusProvider).tickets}');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('チケットを $amount 枚購入しました！', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
        ),
      );
    }
    return true;
  }

  static Future<bool> cancelSubscription(BuildContext context, WidgetRef ref) async {
    debugPrint('[AI_SCAN] 🔵 INFO: サブスクリプションの解約(無料化)処理を開始します。');
    await _simulateNetworkDelay(context);
    
    await ref.read(userStatusProvider.notifier).updatePlan(AppPlan.free);
    debugPrint('[AI_SCAN] 🟢 SUCCESS: 無料プランへのダウングレードが完了しました。');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無料プランに戻りました', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    return true;
  }

  static Future<void> _simulateNetworkDelay(BuildContext context) async {
    debugPrint('[AI_SCAN] 🔵 INFO: 決済サーバーとの通信をシミュレート中...');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('決済処理中...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  static String _getPlanName(AppPlan plan) {
    switch (plan) {
      case AppPlan.free: return '無料プラン';
      case AppPlan.lite: return 'ライトプラン';
      case AppPlan.pro: return 'プロプラン';
    }
  }
}