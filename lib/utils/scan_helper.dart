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
import '../main.dart'; 
import '../features/scan/scan_result_page.dart';
import '../features/home/scan_count_provider.dart';
import '../features/subscription/user_status_provider.dart'; 
import 'gemini_service.dart';
import 'ad_manager.dart';

class ScanHelper {
  static const platform = MethodChannel('com.example.app/camera');

  // ==========================================
  // 【スキャン前の制限チェックと広告フック】
  // ==========================================
  static Future<bool> _checkLimitsAndShowAds(BuildContext context, WidgetRef ref) async {
    final userStatus = ref.read(userStatusProvider);
    debugPrint('[AI_SCAN] 🔵 INFO: 制限チェックを開始。現在のプラン: ${userStatus.plan.name}, 今月のスキャン数: ${userStatus.currentMonthScans}, チケット数: ${userStatus.tickets}');

    // 1. 上限チェック
    if (userStatus.isMonthlyLimitReached && userStatus.tickets <= 0) {
      debugPrint('[AI_SCAN] 🟡 WARN: スキャン上限に達しているためブロックしました。');
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
      return false; 
    }

    // 2. 無料プランの場合、特定回数で動画広告を強制再生
    if (userStatus.plan == AppPlan.free && !userStatus.isMonthlyLimitReached) {
      final nextScanCount = userStatus.currentMonthScans + 1;
      
      if (nextScanCount == 3 || nextScanCount == 6 || nextScanCount == 10) {
        debugPrint('[AI_SCAN] 🔵 INFO: 無料プランの規定回数($nextScanCount回目)に達したため、広告フックを発動します。');
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

        if (wantToWatch != true) {
          debugPrint('[AI_SCAN] 🟡 WARN: ユーザーが広告視聴をキャンセルしました。');
          return false;
        }

        debugPrint('[AI_SCAN] 🔵 INFO: リワード広告の読み込み・表示を開始します...');
        final isRewardEarned = await AdManager.showRewardedAd(context);
        
        if (!isRewardEarned) {
          debugPrint('[AI_SCAN] 🟡 WARN: 広告が最後まで再生されませんでした。');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('広告が最後まで再生されなかったため、キャンセルしました')),
            );
          }
          return false;
        }
        debugPrint('[AI_SCAN] 🟢 SUCCESS: 広告の視聴が完了しました。解析処理へ進みます。');
      }
    }

    return true; 
  }

  static Future<void> startScan(BuildContext context, WidgetRef ref, ExtractionTemplate template) async {
    bool isDialogShowing = false;
    debugPrint('[AI_SCAN] 🔵 INFO: startScan() 開始。対象テンプレート: ${template.name}');

    try {
      final userStatus = ref.read(userStatusProvider);
      final isBatchAllowed = userStatus.plan != AppPlan.free;
      debugPrint('[AI_SCAN] 🔵 INFO: バッチ処理(連続撮影)の許可状態: $isBatchAllowed');

      // 1. ネイティブカメラを起動
      debugPrint('[AI_SCAN] 🔵 INFO: ネイティブカメラ(Kotlin)を起動します...');
      final List<dynamic>? resultPaths = await platform.invokeMethod('startNativeCamera', {
        'is_product_list': false,
        'is_batch_allowed': isBatchAllowed, 
      });

      if (resultPaths == null || resultPaths.isEmpty) {
        debugPrint('[AI_SCAN] 🟡 WARN: カメラ画面がキャンセル・または画像なしで閉じられました。');
        return; 
      }
      debugPrint('[AI_SCAN] 🟢 SUCCESS: ネイティブから ${resultPaths.length} 枚の画像パスを受信しました。');

      List<dynamic> validPaths = resultPaths;
      if (!isBatchAllowed && resultPaths.length > 1) {
        debugPrint('[AI_SCAN] 🟡 WARN: 無料プランで複数枚受信したため、最初の1枚のみに制限します。');
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
      if (!shouldProceed) {
        debugPrint('[AI_SCAN] 🟡 WARN: 制限チェックまたは広告フックにより処理を中断しました。');
        return;
      }

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
        debugPrint('[AI_SCAN] 🔵 INFO: --- ${i + 1}枚目の処理を開始 ---');
        final imagePath = validPaths[i] as String;
        final file = File(imagePath);
        if (!file.existsSync()) {
          debugPrint('[AI_SCAN] 🔴 ERROR: 画像ファイルが存在しません: $imagePath');
          continue;
        }

        // 画像の圧縮処理
        debugPrint('[AI_SCAN] 🔵 INFO: 画像の圧縮を開始します...');
        final targetPath = p.join(tempDir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 80,
          minWidth: 1024,
          minHeight: 1024,
        );

        if (compressedFile == null) {
          debugPrint('[AI_SCAN] 🔴 ERROR: 画像の圧縮に失敗しました。');
          continue;
        }
        final imageBytes = await compressedFile.readAsBytes();
        debugPrint('[AI_SCAN] 🟢 SUCCESS: 画像の圧縮完了。サイズ: ${imageBytes.length} bytes');

        // Gemini APIで解析
        debugPrint('[AI_SCAN] 🔵 INFO: Gemini API(Cloud Functions)へ解析リクエストを送信します。モード: $mode');
        final resultData = await GeminiService.analyzeImage(
          imageBytes: imageBytes,
          targetFields: fields,
          mode: mode,
        );

        if (resultData == null) {
          debugPrint('[AI_SCAN] 🔴 ERROR: Gemini APIからの解析結果が空でした。');
          continue;
        }
        debugPrint('[AI_SCAN] 🟢 SUCCESS: Gemini API解析完了！データを受信しました。');

        // アプリ専用の永続ディレクトリに画像を移動
        final finalImagePath = p.join(appDocDir.path, 'scan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await File(compressedFile.path).copy(finalImagePath);
        debugPrint('[AI_SCAN] 🔵 INFO: 画像をアプリ専用ディレクトリに保存しました: $finalImagePath');

        // データベースに保存
        final historyId = await db.into(db.scanHistories).insert(
          ScanHistoriesCompanion.insert(
            templateId: template.id,
            imagePath: finalImagePath,
            resultJson: jsonEncode(resultData),
          ),
        );
        debugPrint('[AI_SCAN] 🟢 SUCCESS: データベースに履歴を保存しました。(HistoryID: $historyId)');

        // スキャンごとにユーザーの回数・チケットを消費する
        await ref.read(userStatusProvider.notifier).consumeScan();
        await ref.read(scanCountProvider.notifier).increment();

        firstHistoryId ??= historyId;

        // バッチ処理中に上限に達したらそこでループを打ち切る
        final currentStatus = ref.read(userStatusProvider);
        if (currentStatus.isMonthlyLimitReached && currentStatus.tickets <= 0) {
          debugPrint('[AI_SCAN] 🟡 WARN: バッチ処理中にスキャン上限に達したため、残りの処理を中断します。');
          if (context.mounted && validPaths.length > 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('スキャン上限に達したため、残りの処理を中断しました')),
            );
          }
          break;
        }
      }

      // 5. ローディングを閉じて結果画面へ遷移
      debugPrint('[AI_SCAN] 🔵 INFO: 全画像ループ終了。画面遷移の準備を行います。');
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
        debugPrint('[AI_SCAN] 🟢 SUCCESS: 処理完了。ScanResultPage(ID: $firstHistoryId) へ遷移します。');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultPage(historyId: firstHistoryId!),
          ),
        );
      } else {
        debugPrint('[AI_SCAN] 🔴 ERROR: 成功した画像が1枚もありませんでした。');
        throw Exception('処理に成功した画像がありませんでした');
      }

    } catch (e) {
      debugPrint('[AI_SCAN] 🔴 FATAL ERROR: startScan内で例外が発生しました: $e');
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