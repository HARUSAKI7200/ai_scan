// lib/features/home/notice_list_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'notice_provider.dart';

class NoticeListPage extends ConsumerStatefulWidget {
  const NoticeListPage({super.key});

  @override
  ConsumerState<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends ConsumerState<NoticeListPage> {
  @override
  void initState() {
    super.initState();
    // 画面がビルドされた直後に、既読時間を「今」に更新する（赤ポチを消す）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lastReadTimeProvider.notifier).updateReadTime();
    });
  }

  // すりガラスのカードを作成する共通メソッド
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // 通知カードのUI構築
  Widget _buildNoticeItem(AppNotice notice) {
    Color iconColor;
    IconData iconData;

    switch (notice.type) {
      case 'error': // 障害等
        iconColor = Colors.red.shade600;
        iconData = Icons.error_outline;
        break;
      case 'warning': // 警告
        iconColor = Colors.orange.shade700;
        iconData = Icons.warning_amber_rounded;
        break;
      case 'info': // 通常
      default:
        iconColor = Colors.blue.shade600;
        iconData = Icons.info_outline;
        break;
    }

    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(notice.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(activeNoticesProvider);

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
        appBar: AppBar(
          title: const Text('お知らせ'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: noticesAsync.when(
          data: (notices) {
            if (notices.isEmpty) {
              return const Center(
                child: Text(
                  '現在お知らせはありません',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                return _buildNoticeItem(notices[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'お知らせの取得に失敗しました:\n$err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}