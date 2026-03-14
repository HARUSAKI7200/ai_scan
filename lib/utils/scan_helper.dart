// lib/utils/scan_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../database/app_database.dart';
import '../main.dart'; // databaseProvider
import '../features/scan/scan_result_page.dart';
import '../features/home/scan_count_provider.dart';
import '../features/subscription/user_status_provider.dart'; // ★追加: ユーザー状態
import 'gemini_service.dart';
import 'ad_manager.dart';

class ScanHelper {
  static const platform = MethodChannel('com.example.app/camera');

  // ==========================================
  // 【スキャン前の制限チェックと広告フック】
  // ==========================================
  static Future<bool> _checkLimitsAndShowAds(BuildContext context, WidgetRef ref) async {
    final userStatus = ref.read(userStatusProvider);

    // 1. 上限チェック
    if (userStatus.isMonthlyLimitReached && userStatus.tickets <= 0) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('スキャン上限に達しました'),
          content: Text('今月の無料スキャン回数（${userStatus.monthlyLimit}回）を使い切りました。\n引き続き利用するには、プレミアムプランへの登録またはチケットの購入が必要です。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 課金（プラン・チケット購入）画面へ遷移させる処理を追加
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('プラン購入画面は準備中です')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
              child: const Text('プランを見る'),
            ),
          ],
        ),
      );
      return false; // 解析に進まない
    }

    // 2. 無料プランの場合、特定回数で動画広告を強制再生
    if (userStatus.plan == AppPlan.free && !userStatus.isMonthlyLimitReached) {
      final nextScanCount = userStatus.currentMonthScans + 1;
      
      // 3回目、6回目、10回目で広告表示
      if (nextScanCount == 3 || nextScanCount == 6 || nextScanCount == 10) {
        final wantToWatch = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            title: const Row(
              children: [
                Icon(Icons.play_circle_filled, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('広告視聴のお願い'),
              ],
            ),
            content: Text('AIによる高精度な解析を実行するには、短い動画広告を視聴してください。\n\n(今月 $nextScanCount 回目の利用)'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
                child: const Text('動画を見る'),
              ),
            ],
          ),
        );

        if (wantToWatch != true) return false;

        // 動画リワード広告を再生
        final isRewardEarned = await AdManager.showRewardedAd(context);
        
        if (!isRewardEarned) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('広告が最後まで再生されなかったため、キャンセルしました')),
            );
          }
          return false;
        }
      }
    }

    return true; // 問題なく進める
  }

  static Future<void> startScan(BuildContext context, WidgetRef ref, ExtractionTemplate template) async {
    bool isDialogShowing = false;

    try {
      final userStatus = ref.read(userStatusProvider);
      // 無料プラン以外なら連続撮影(バッチ)を許可
      final isBatchAllowed = userStatus.plan != AppPlan.free;

      // 1. ネイティブカメラを起動
      final List<dynamic>? resultPaths = await platform.invokeMethod('startNativeCamera', {
        'is_product_list': false,
        'is_batch_allowed': isBatchAllowed, // Kotlin側にバッチ可否を伝達
      });

      if (resultPaths == null || resultPaths.isEmpty) {
        return; // キャンセルされた場合
      }

      // 無料プランなのに複数枚返ってきた場合の安全対策（フォールバック）
      List<dynamic> validPaths = resultPaths;
      if (!isBatchAllowed && resultPaths.length > 1) {
        validPaths = [resultPaths.first];
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無料プランでは連続撮影はできません。最初の1枚のみ処理します。')),
          );
        }
      }

      // 2. 解析前の制限チェックと広告フック
      if (!context.mounted) return;
      final shouldProceed = await _checkLimitsAndShowAds(context, ref);
      if (!shouldProceed) return;

      // 3. ローディングダイアログを表示
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('${validPaths.length}枚の書類を処理しています...'),
                ],
              ),
            ),
          ),
        ),
      );
      isDialogShowing = true;

      final tempDir = await getTemporaryDirectory();
      final appDocDir = await getApplicationDocumentsDirectory();
      final db = ref.read(databaseProvider);
      
      final fields = (jsonDecode(template.targetFieldsJson) as List).cast<String>();
      String mode = 'list';
      if (template.customInstruction != null) {
        try {
          final decoded = jsonDecode(template.customInstruction!);
          if (decoded is Map && decoded['mode'] == 'text') {
            mode = 'text';
          }
        } catch (_) {}
      }

      int? firstHistoryId;

      // 4. バッチスキャン（複数枚ループ処理）
      for (int i = 0; i < validPaths.length; i++) {
        final imagePath = validPaths[i] as String;
        final file = File(imagePath);
        if (!file.existsSync()) continue;

        // 画像の圧縮処理
        final targetPath = p.join(tempDir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 80,
          minWidth: 1024,
          minHeight: 1024,
        );

        if (compressedFile == null) continue;
        final imageBytes = await compressedFile.readAsBytes();

        // Gemini APIで解析
        final resultData = await GeminiService.analyzeImage(
          imageBytes: imageBytes,
          targetFields: fields,
          mode: mode,
        );

        if (resultData == null) continue;

        // アプリ専用の永続ディレクトリに画像を移動
        final finalImagePath = p.join(appDocDir.path, 'scan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await File(compressedFile.path).copy(finalImagePath);

        // データベースに保存
        final historyId = await db.into(db.scanHistories).insert(
          ScanHistoriesCompanion.insert(
            templateId: template.id,
            imagePath: finalImagePath,
            resultJson: jsonEncode(resultData),
          ),
        );

        // ★スキャンごとにユーザーの回数・チケットを消費する
        await ref.read(userStatusProvider.notifier).consumeScan();

        // 累計スキャン回数をカウントアップ
        await ref.read(scanCountProvider.notifier).increment();

        firstHistoryId ??= historyId;

        // バッチ処理中に上限に達したらそこでループを打ち切る
        final currentStatus = ref.read(userStatusProvider);
        if (currentStatus.isMonthlyLimitReached && currentStatus.tickets <= 0) {
          if (context.mounted && validPaths.length > 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('スキャン上限に達したため、残りの処理を中断しました')),
            );
          }
          break;
        }
      }

      // 5. ローディングを閉じて結果画面へ遷移
      if (!context.mounted) return;
      if (isDialogShowing) {
        Navigator.pop(context);
        isDialogShowing = false;
      }
      
      if (firstHistoryId != null) {
        if (validPaths.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${validPaths.length}枚の書類を保存しました')),
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultPage(historyId: firstHistoryId!),
          ),
        );
      } else {
        throw Exception('処理に成功した画像がありませんでした');
      }

    } catch (e) {
      if (!context.mounted) return;
      if (isDialogShowing) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red),
      );
    }
  }
}