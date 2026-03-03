// lib/pages/home_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // MethodChannel
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../main.dart'; // databaseProvider
import '../utils/gemini_service.dart';
import 'scan_result_page.dart';

// ネイティブチャンネルの定義
const platform = MethodChannel('com.example.app/camera');
const imagePlatform = MethodChannel('com.example.app/image_processing');

// テンプレートリストを取得するStreamProvider
final templatesStreamProvider = StreamProvider<List<ExtractionTemplate>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.extractionTemplates)
        ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)]))
      .watch();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIスキャン'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
        data: (templates) {
          if (templates.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildTemplateList(context, ref, templates);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTemplateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新規テンプレート'),
      ),
    );
  }

  // --- スキャン処理のコアロジック ---
  Future<void> _startScan(BuildContext context, WidgetRef ref, ExtractionTemplate template) async {
    try {
      // 1. ネイティブカメラを起動
      // 引数は必要に応じて調整。ここではシンプルに。
      final List<dynamic>? result = await platform.invokeMethod('startNativeCamera', {'is_product_list': false});
      
      if (result == null || result.isEmpty) {
        return; // キャンセルされた場合
      }

      final String rawImagePath = result.first as String; // 最初の1枚を使用

      // ローディング表示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      // 2. 画像補正 (OpenCV)
      // ネイティブ側で自動クロップを実行
      final String? croppedPath = await imagePlatform.invokeMethod('autoCropImage', {'imagePath': rawImagePath});
      final String finalImagePath = croppedPath ?? rawImagePath;
      final File imageFile = File(finalImagePath);

      // 3. Geminiで解析
      final List<String> fields = (jsonDecode(template.targetFieldsJson) as List).cast<String>();
      final imageBytes = await imageFile.readAsBytes();

      final Map<String, dynamic>? extractedData = await GeminiService.analyzeImage(
        imageBytes: imageBytes,
        targetFields: fields,
        customInstruction: template.customInstruction,
      );

      if (extractedData == null) {
        throw Exception('AIによる解析に失敗しました');
      }

      // 4. DBに履歴保存
      final db = ref.read(databaseProvider);
      final id = await db.into(db.scanHistories).insert(
        ScanHistoriesCompanion.insert(
          templateId: template.id,
          imagePath: finalImagePath,
          resultJson: jsonEncode(extractedData),
        ),
      );

      // 5. 結果画面へ遷移
      if (context.mounted) {
        Navigator.pop(context); // ローディングを閉じる
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScanResultPage(historyId: id)),
        );
      }

    } catch (e) {
      if (context.mounted) {
        // ローディングが出ていれば閉じる（安全策）
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラ―: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // データがない時の表示
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'テンプレートがありません',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '「+」ボタンから\n読み取りたい書類の設定を作ってください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _createSampleTemplate(context, ref),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('サンプル（領収書）を作成'),
          ),
        ],
      ),
    );
  }

  // テンプレートリストの表示
  Widget _buildTemplateList(BuildContext context, WidgetRef ref, List<ExtractionTemplate> templates) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final fields = (jsonDecode(template.targetFieldsJson) as List).cast<String>();

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _startScan(context, ref, template),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteTemplate(context, ref, template);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('削除', style: TextStyle(color: Colors.red))]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('抽出項目:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: fields.map((f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.blue[50],
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startScan(context, ref, template),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('スキャン開始'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 簡易的なテンプレート作成ダイアログ
  Future<void> _showAddTemplateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final fieldsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規テンプレート作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'テンプレート名',
                hintText: '例: 請求書, 日報',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fieldsController,
              decoration: const InputDecoration(
                labelText: '抽出する項目 (カンマ区切り)',
                hintText: '例: 日付, 会社名, 金額',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final fieldsText = fieldsController.text.trim();
              
              if (name.isEmpty || fieldsText.isEmpty) {
                return;
              }

              final fields = fieldsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

              final db = ref.read(databaseProvider);
              await db.into(db.extractionTemplates).insert(
                ExtractionTemplatesCompanion.insert(
                  name: name,
                  targetFieldsJson: jsonEncode(fields),
                ),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('テンプレートを作成しました')),
                );
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  // サンプルデータ作成
  Future<void> _createSampleTemplate(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.into(db.extractionTemplates).insert(
      ExtractionTemplatesCompanion.insert(
        name: '領収書 (サンプル)',
        targetFieldsJson: jsonEncode(['日付', '支払先', '合計金額', '登録番号']),
        customInstruction: drift.Value('日付はyyyy/MM/dd形式で抽出してください。'),
      ),
    );
  }

  // テンプレート削除
  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref, ExtractionTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('テンプレート「${template.name}」を削除しますか？\nこれまでのスキャン履歴も削除されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.extractionTemplates)..where((t) => t.id.equals(template.id))).go();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('削除しました')),
        );
      }
    }
  }
}