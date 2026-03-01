// lib/utils/gemini_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// APIキー (本来はセキュアな場所から取得すべきですが、現状の構成に従います)
const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

// 使用モデル: Gemini 1.5 Flash (高速・安価・高性能)
const modelName = 'gemini-1.5-flash';

class GeminiService {
  /// 汎用的な画像解析メソッド
  /// [imageBytes]: 画像データ
  /// [targetFields]: 抽出したい項目のリスト (例: ["日付", "金額", "店名"])
  /// [customInstruction]: 追加の指示 (任意)
  static Future<Map<String, dynamic>?> analyzeImage({
    required Uint8List imageBytes,
    required List<String> targetFields,
    String? customInstruction,
  }) async {
    if (geminiApiKey.isEmpty) {
      throw Exception('Gemini APIキーが設定されていません。--dart-define=GEMINI_API_KEY=... を指定してください。');
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$geminiApiKey');

    final mimeType = _guessMimeType(imageBytes);
    final base64Image = base64Encode(imageBytes);

    // 1. 動的なJSONスキーマの構築
    final responseSchema = _buildDynamicSchema(targetFields);

    // 2. システムプロンプトの構築
    final systemPrompt = _buildSystemPrompt(targetFields, customInstruction);

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": systemPrompt},
            {
              "inline_data": {
                "mime_type": mimeType,
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "response_mime_type": "application/json",
        "response_schema": responseSchema,
        "temperature": 0.0, // 事実抽出なので創造性は不要
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Gemini API Error: ${response.statusCode}\nBody: ${response.body}');
      }

      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      
      // レスポンスの解析
      final candidates = responseData['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String;
          return jsonDecode(text) as Map<String, dynamic>;
        }
      }
      return null;

    } catch (e) {
      // エラーハンドリングは呼び出し元で行うため再スロー
      rethrow;
    }
  }

  /// JSONスキーマの構築
  static Map<String, dynamic> _buildDynamicSchema(List<String> fields) {
    return {
      "type": "OBJECT",
      "properties": {
        for (var field in fields)
          field: {"type": "STRING"}
      },
      "required": fields,
    };
  }

  /// プロンプトの構築
  static String _buildSystemPrompt(List<String> fields, String? customInstruction) {
    final fieldsStr = fields.join(', ');
    
    return '''
あなたは高精度なAI-OCRアシスタントです。
提供された画像から、以下の項目を正確に読み取り、JSON形式で出力してください。

### 抽出対象項目
$fieldsStr

### 基本ルール
1. 画像に記載されている通りに正確に読み取ってください。
2. 項目が見つからない、または判読不能な場合は、空文字 "" を出力してください（nullは禁止）。
3. 推測で値を補完しないでください。

${customInstruction != null && customInstruction.isNotEmpty ? "### 追加指示\n$customInstruction" : ""}
''';
  }

  static String _guessMimeType(Uint8List imageBytes) {
    if (imageBytes.length >= 12) {
      if (imageBytes[0] == 0x52 && imageBytes[1] == 0x49 && imageBytes[2] == 0x46 && imageBytes[3] == 0x46) {
        return 'image/webp';
      }
      if (imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && imageBytes[2] == 0x4E && imageBytes[3] == 0x47) {
        return 'image/png';
      }
    }
    // デフォルトはJPEG扱い
    return 'image/jpeg';
  }
}