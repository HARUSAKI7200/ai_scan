// lib/features/settings/settings_tab.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'how_to_use_page.dart';
import '../subscription/user_status_provider.dart';
import '../subscription/paywall_page.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
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

  String _getPlanName(AppPlan plan) {
    switch (plan) {
      case AppPlan.free: return '無料プラン';
      case AppPlan.lite: return 'ライトプラン';
      case AppPlan.pro: return 'プロプラン';
    }
  }

  Color _getPlanColor(AppPlan plan) {
    switch (plan) {
      case AppPlan.free: return Colors.grey.shade700;
      case AppPlan.lite: return Colors.blue.shade700;
      case AppPlan.pro: return const Color(0xFF667EEA);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatus = ref.watch(userStatusProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('設定・利用状況'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ------------------------------------
          // 現在のステータス＆アップグレード導線
          // ------------------------------------
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('現在のご利用プラン', style: TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPlanColor(userStatus.plan).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getPlanColor(userStatus.plan)),
                        ),
                        child: Text(
                          _getPlanName(userStatus.plan),
                          style: TextStyle(fontWeight: FontWeight.bold, color: _getPlanColor(userStatus.plan), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // スキャン回数
                  Row(
                    children: [
                      const Icon(Icons.document_scanner_outlined, color: Color(0xFF1E293B), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('今月のスキャン枠', style: TextStyle(color: Color(0xFF1E293B)))),
                      Text(
                        '${userStatus.currentMonthScans} / ${userStatus.monthlyLimit} 回',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // チケット数
                  Row(
                    children: [
                      const Icon(Icons.local_activity_outlined, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('保有追加チケット', style: TextStyle(color: Color(0xFF1E293B)))),
                      Text(
                        '${userStatus.tickets} 枚',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Paywallへの導線ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PaywallPage()),
                        );
                      },
                      icon: const Icon(Icons.star, color: Colors.amber),
                      label: Text(
                        userStatus.plan == AppPlan.free ? 'プレミアムプランに登録' : 'プラン変更 / チケット購入',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B), // ダーク系のボタンで目立たせる
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text('サポート・情報', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          ),
          
          // ------------------------------------
          // 各種ページへのリンク
          // ------------------------------------
          _buildGlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFF1E293B)),
                  title: const Text('アプリの使い方'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HowToUsePage()),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.5)),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Color(0xFF1E293B)),
                  title: const Text('利用規約'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.5)),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF1E293B)),
                  title: const Text('プライバシーポリシー'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}