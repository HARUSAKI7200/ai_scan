import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';

class GeminiService {
  /// Firebase Cloud Functions を経由して画像解析を行う
  static Future<Map<String, dynamic>?> analyzeImage({
    required Uint8List imageBytes,
    required List<String> targetFields,
    String? customInstruction,
  }) async {
    try {
      // 1. 画像データをBase64エンコード
      final base64Image = base64Encode(imageBytes);
      final mimeType = _guessMimeType(imageBytes);

      // 2. Cloud Functions のインスタンス取得（リージョンを asia-northeast1 に指定）
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      
      // 3. 呼び出す関数名 'analyzeImage' を指定
      final callable = functions.httpsCallable('analyzeImage');

      // 4. 関数を実行して結果を待機
      final response = await callable.call({
        'base64Image': base64Image,
        'mimeType': mimeType,
        'targetFields': targetFields,
        'customInstruction': customInstruction,
      });

      final resultData = response.data as Map<dynamic, dynamic>;
      final resultJsonString = resultData['resultJsonString'] as String;

      final dynamic decodedJson = jsonDecode(resultJsonString);

      // AIがリスト（配列）で返してきた場合の対処
      if (decodedJson is List) {
        if (decodedJson.isNotEmpty) {
          return decodedJson.first as Map<String, dynamic>;
        } else {
          return {};
        }
      }

      // AIが辞書で返してきた場合（通常）
      return decodedJson as Map<String, dynamic>;

    } on FirebaseFunctionsException catch (e) {
      throw Exception('Firebase Functions Error [${e.code}]: ${e.message}');
    } catch (e) {
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