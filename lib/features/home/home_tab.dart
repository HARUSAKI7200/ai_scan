// lib/features/home/home_tab.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../database/app_database.dart';
import '../templates/templates_tab.dart'; // templatesStreamProvider
import '../../utils/scan_helper.dart';

// 絶対に減らない累計スキャン回数を取得するプロバイダーをインポート
import 'scan_count_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    // テンプレート一覧の取得
    final templatesAsync = ref.watch(templatesStreamProvider);
    
    // 履歴の数ではなく、SharedPreferencesに保存された「累計スキャン回数」を取得する
    final totalScanCount = ref.watch(scanCountProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('AI Scan Excel', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF1E293B)),
            onPressed: () {
              // TODO: 設定画面へ
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // リフレッシュ処理が必要ならここに書く
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ヘッダー・サマリーカード ---
                _buildGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '総スキャン回数',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$totalScanCount',
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.0),
                                ),
                                const SizedBox(width: 8),
                                // ★修正: TextStyleのpaddingを削除し、Paddingウィジェットで包みました
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6.0),
                                  child: Text(
                                    '回',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(Icons.document_scanner, color: Colors.white, size: 36),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 32),

                // --- クイックスキャン セクション ---
                const Text(
                  'クイックスキャン',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 16),

                // テンプレートリストの表示
                templatesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('エラー: $err')),
                  data: (templates) {
                    if (templates.isEmpty) {
                      return _buildGlassCard(
                        child: const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'テンプレートがありません。\n下のタブから作成してください。',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 300.ms);
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _buildGlassCard(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            // 共通のScanHelperを呼び出す
                            onTap: () => ScanHelper.startScan(context, ref, template),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Color(0xFF667EEA), size: 28),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    template.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fade(delay: (300 + (50 * index)).ms).scale(curve: Curves.easeOutBack);
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 100), // ボトムナビゲーションバーの裏に隠れないための余白
              ],
            ),
          ),
        ),
      ),
    );
  }
}