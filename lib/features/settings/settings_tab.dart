// lib/features/settings/settings_tab.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ★ 今後のサブスクリプション導線
          _buildGlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.star, color: Colors.amber, size: 32),
              title: const Text('プレミアムプランに登録', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('スキャン回数無制限＆広告非表示'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: ここでPaywall画面を開く
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('課金機能は準備中です')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('アプリの使い方'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.5)),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('利用規約'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.5)),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('プライバシーポリシー'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}