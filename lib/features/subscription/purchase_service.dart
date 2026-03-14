// lib/features/subscription/purchase_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_status_provider.dart';

/// 課金処理を統括するサービスクラス
/// ★現在はストア設定前のため、モック（ダミー）として動作します。
/// ストア登録後、この中身を `purchases_flutter` (RevenueCat) の呼び出しに変更します。
class PurchaseService {
  
  /// サブスクリプションプラン（ライト・プロ）の購入処理
  static Future<bool> purchaseSubscription(BuildContext context, WidgetRef ref, AppPlan plan) async {
    // 実際の通信を模したローディング表示
    await _simulateNetworkDelay(context);

    // 成功したと仮定して、アプリ内のユーザー状態を更新
    await ref.read(userStatusProvider.notifier).updatePlan(plan);

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

  /// チケット（消費型アイテム）の購入処理
  static Future<bool> purchaseTickets(BuildContext context, WidgetRef ref, int amount) async {
    // 実際の通信を模したローディング表示
    await _simulateNetworkDelay(context);

    // 成功したと仮定して、アプリ内のチケット数を増加
    await ref.read(userStatusProvider.notifier).addTickets(amount);

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

  /// 現在のサブスクリプションを解約する（無料プランに戻す）デバッグ用機能
  static Future<bool> cancelSubscription(BuildContext context, WidgetRef ref) async {
    await _simulateNetworkDelay(context);
    await ref.read(userStatusProvider.notifier).updatePlan(AppPlan.free);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無料プランに戻りました', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    return true;
  }

  /// 擬似的なネットワーク遅延（ローディングダイアログ）
  static Future<void> _simulateNetworkDelay(BuildContext context) async {
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

    // 1.5秒待機
    await Future.delayed(const Duration(milliseconds: 1500));

    // ダイアログを閉じる
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