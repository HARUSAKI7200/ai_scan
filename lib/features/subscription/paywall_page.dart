// lib/features/subscription/paywall_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_status_provider.dart';
import 'purchase_service.dart';

class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  Widget _buildGlassCard({required Widget child, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.8),
              width: borderColor != null ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String price,
    required String scans,
    required AppPlan planType,
    required AppPlan currentPlan,
    required List<String> features,
    bool isPopular = false,
  }) {
    final isCurrent = currentPlan == planType;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: _buildGlassCard(
            borderColor: isPopular ? const Color(0xFF667EEA) : null,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          ' / 月',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.document_scanner, size: 18, color: Color(0xFF667EEA)),
                        const SizedBox(width: 8),
                        Text(
                          '毎月 $scans スキャン',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f, style: const TextStyle(color: Color(0xFF1E293B)))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: isCurrent
                        ? OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              disabledForegroundColor: const Color(0xFF667EEA),
                              side: const BorderSide(color: Color(0xFF667EEA), width: 2),
                            ),
                            child: const Text('現在のプラン', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton(
                            onPressed: () => PurchaseService.purchaseSubscription(context, ref, planType),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPopular ? const Color(0xFF667EEA) : Colors.grey.shade800,
                            ),
                            child: const Text('このプランを選択', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: 0,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF9A9E).withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: const Text(
                '一番人気',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTicketCard({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_activity, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text(
                  '追加スキャンチケット',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '「今月だけスキャン上限を超えてしまいそう…」という方に。月をまたいでも繰り越して使えます。',
              style: TextStyle(color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('100 スキャン', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text('買い切り（期限なし）', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => PurchaseService.purchaseTickets(context, ref, 100),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('購入 (¥500)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatus = ref.watch(userStatusProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0C3FC), 
            Color(0xFF8EC5FC), 
            Color(0xFFE0C3FC), 
          ],
          stops: [0.0, 0.5, 1.0], 
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('プラン変更'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              const Text(
                'AIの力で、すべての書類を\nエクセルへ自動変換',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              
              // プロプラン
              _buildPlanCard(
                context: context,
                ref: ref,
                title: 'プロプラン',
                price: '¥980',
                scans: '1500回',
                planType: AppPlan.pro,
                currentPlan: userStatus.plan,
                isPopular: true,
                features: [
                  '動画広告の完全非表示',
                  '複数枚の連続スキャン (バッチ処理)',
                  '毎月 1500枚 までのスキャン枠',
                  'CSV/Excel 出力機能の解放',
                ],
              ),
              const SizedBox(height: 24),

              // ライトプラン
              _buildPlanCard(
                context: context,
                ref: ref,
                title: 'ライトプラン',
                price: '¥480',
                scans: '500回',
                planType: AppPlan.lite,
                currentPlan: userStatus.plan,
                features: [
                  '動画広告の完全非表示',
                  '複数枚の連続スキャン (バッチ処理)',
                  '毎月 500枚 までのスキャン枠',
                  'CSV/Excel 出力機能の解放',
                ],
              ),
              const SizedBox(height: 32),

              const Divider(color: Colors.white, thickness: 1.5),
              const SizedBox(height: 24),

              // チケット購入
              _buildTicketCard(context: context, ref: ref),

              const SizedBox(height: 48),

              // （デバッグ用）無料プランに戻す
              if (userStatus.plan != AppPlan.free)
                TextButton(
                  onPressed: () => PurchaseService.cancelSubscription(context, ref),
                  child: const Text('（テスト用）無料プランに戻す', style: TextStyle(color: Colors.redAccent)),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}