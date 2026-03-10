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
import 'gemini_service.dart';
// ★追加: 累計スキャン回数を管理するプロバイダーをインポート
import '../features/home/scan_count_provider.dart';

class ScanHelper {
  static const platform = MethodChannel('com.example.ai_scan/camera');

  static Future<void> startScan(BuildContext context, WidgetRef ref, ExtractionTemplate template) async {
    try {
      // 1. ネイティブカメラを起動
      final List<dynamic>? resultPaths = await platform.invokeMethod('startCamera', {
        'mode': 'document',
      });

      if (resultPaths == null || resultPaths.isEmpty) {
        return; // キャンセルされた場合
      }

      final imagePath = resultPaths.first as String;
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('画像ファイルが見つかりません');
      }

      // 2. ローディングダイアログを表示
      if (!context.mounted) return;
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
                  Text('AIが書類を読み取っています...'),
                ],
              ),
            ),
          ),
        ),
      );

      // 3. 画像の圧縮処理
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedFile == null) {
        throw Exception('画像の圧縮に失敗しました');
      }

      final imageBytes = await compressedFile.readAsBytes();

      // 4. Gemini APIで解析
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

      final resultData = await GeminiService.analyzeImage(
        imageBytes: imageBytes,
        targetFields: fields,
        mode: mode,
      );

      if (resultData == null) {
        throw Exception('解析結果が空でした');
      }

      // 5. アプリ専用の永続ディレクトリに画像を移動（キャッシュクリアで消えないように）
      final appDocDir = await getApplicationDocumentsDirectory();
      final finalImagePath = p.join(appDocDir.path, 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(compressedFile.path).copy(finalImagePath);

      // 6. データベースに保存
      final db = ref.read(databaseProvider);
      final historyId = await db.into(db.scanHistories).insert(
        ScanHistoriesCompanion.insert(
          templateId: template.id,
          imagePath: finalImagePath,
          resultJson: jsonEncode(resultData),
        ),
      );

      // ★追加: 累計スキャン回数をカウントアップして保存！
      await ref.read(scanCountProvider.notifier).increment();

      // 7. ローディングを閉じて結果画面へ遷移
      if (!context.mounted) return;
      Navigator.pop(context); // ダイアログを閉じる
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultPage(historyId: historyId),
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // ダイアログを閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }
}