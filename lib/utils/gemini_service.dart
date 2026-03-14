// lib/utils/gemini_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GeminiService {
  static Future<Map<String, dynamic>?> analyzeImage({
    required Uint8List imageBytes,
    required List<String> targetFields,
    String mode = 'list', 
  }) async {
    try {
      debugPrint('[AI_SCAN] 🔵 INFO: GeminiService.analyzeImage() 開始');
      
      // 1. 画像データをBase64エンコード
      final base64Image = base64Encode(imageBytes);
      final mimeType = _guessMimeType(imageBytes);
      debugPrint('[AI_SCAN] 🔵 INFO: 画像のエンコード完了 (mimeType: $mimeType, base64Length: ${base64Image.length})');

      // 2. Cloud Functions のインスタンス取得
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable('analyzeImage');

      // 3. セキュアなシステムプロンプトの構築
      String instruction = '';
      if (mode == 'text') {
        instruction = '''
画像内のすべての文字を、見た目のレイアウト（改行位置、空白、インデント、段落）を完全に維持したまま正確に読み取ってください。
特に以下の点に注意してください：
1. 画像上の物理的な「行の終わり」と「実際の改行位置」を完全に一致させ、必ず改行文字（\\n）を挿入してください。
2. 文字の配置やスペース（空白）も忠実に再現してください。AIの推測で文章を繋げたり、改行を削除したりしないでください。
3. 出力は必ず以下のJSON形式のみとしてください。Markdown記法（```json など）は絶対に含めないでください。
{"text": "読み取った全文（見たままの改行を含む）"}
''';
        debugPrint('[AI_SCAN] 🔵 INFO: 全文モード用のプロンプトを構築しました。');
      } else {
        final fieldsStr = targetFields.join(', ');
        instruction = '画像内の表やリストのデータをすべて読み取り、指定された抽出項目 [$fieldsStr] に従って、必ずJSONの配列（リスト）形式 "[{...}, {...}]" で出力してください。';
        debugPrint('[AI_SCAN] 🔵 INFO: リストモード用のプロンプトを構築しました。対象項目: $fieldsStr');
      }

      // 4. 関数を実行して結果を待機
      debugPrint('[AI_SCAN] 🔵 INFO: Cloud Functions (analyzeImage) を呼び出します...');
      final response = await callable.call({
        'base64Image': base64Image,
        'mimeType': mimeType,
        'targetFields': targetFields,
        'customInstruction': instruction,
        'mode': mode,
      });

      debugPrint('[AI_SCAN] 🟢 SUCCESS: Cloud Functions から応答を受信しました。');
      
      final resultData = response.data as Map<dynamic, dynamic>;
      final resultJsonString = resultData['resultJsonString'] as String;
      
      debugPrint('[AI_SCAN] 🔵 INFO: 受け取ったJSON文字列: $resultJsonString');

      final dynamic decodedJson = jsonDecode(resultJsonString);

      // 5. 結果のパース
      if (mode == 'text') {
        if (decodedJson is Map && decodedJson.containsKey('text')) {
          debugPrint('[AI_SCAN] 🟢 SUCCESS: 全文モードのパース成功');
          return {'text': decodedJson['text']};
        } else {
          debugPrint('[AI_SCAN] 🟡 WARN: 全文モードのフォーマットが不正なためフォールバックします');
          return {'text': decodedJson.toString()}; 
        }
      } else {
        if (decodedJson is List) {
          final List<Map<String, dynamic>> items = decodedJson.map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          }).toList();
          debugPrint('[AI_SCAN] 🟢 SUCCESS: リストモードのパース成功 (${items.length}件のアイテム)');
          return {'items': items};
        } else if (decodedJson is Map) {
          debugPrint('[AI_SCAN] 🟡 WARN: リストが期待されましたがMapが返されたため、Listでラップします');
          return {'items': [Map<String, dynamic>.from(decodedJson)]};
        }
        debugPrint('[AI_SCAN] 🔴 ERROR: リストモードのパースに失敗しました（空のリストを返します）');
        return {'items': []};
      }

    } on FirebaseFunctionsException catch (e) {
      debugPrint('[AI_SCAN] 🔴 ERROR: Firebase Functions Error [${e.code}]: ${e.message}');
      throw Exception('Firebase Functions Error [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('[AI_SCAN] 🔴 FATAL ERROR: GeminiService 内で予期せぬエラー: $e');
      throw Exception('予期せぬエラーが発生しました: $e');
    }
  }

  static String _guessMimeType(Uint8List imageBytes) {
    if (imageBytes.length >= 4) {
      if (imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && imageBytes[2] == 0x4E && imageBytes[3] == 0x47) {
        return 'image/png';
      }
    }
    return 'image/jpeg';
  }
}