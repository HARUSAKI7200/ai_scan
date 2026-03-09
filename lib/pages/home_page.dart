// lib/pages/home_page.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // ★追加: すりガラスのぼかし効果(ImageFilter)に必要
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_animate/flutter_animate.dart';

import '../database/app_database.dart';
import '../main.dart'; 
import '../utils/gemini_service.dart';
import 'scan_result_page.dart';
import 'template_create_page.dart'; 

const platform = MethodChannel('com.example.app/camera');
const imagePlatform = MethodChannel('com.example.app/image_processing');

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

    // ★ 鮮やかなオーロラグラデーション背景
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
        appBar: AppBar(
          title: const Text('AIスキャン'),
        ),
        body: templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
          data: (templates) {
            if (templates.isEmpty) return _buildEmptyState(context, ref);
            return _buildTemplateList(context, ref, templates);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplateCreatePage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('新規テンプレート'),
        ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  // ★ 追加: すりガラス（グラスモーフィズム）のカードを作る専用ウィジェット
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // ここで背景を強めにぼかす
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35), // 半透明の白
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5), // ガラスの縁の光の反射を表現
            // ほんのりドロップシャドウ
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

  Future<void> _startScan(BuildContext context, WidgetRef ref, ExtractionTemplate template) async {
    try {
      final List<dynamic>? result = await platform.invokeMethod('startNativeCamera', {'is_product_list': false});
      if (result == null || result.isEmpty) return; 

      final String rawImagePath = result.first as String; 

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      final String? croppedPath = await imagePlatform.invokeMethod('autoCropImage', {'imagePath': rawImagePath});
      final String finalImagePath = croppedPath ?? rawImagePath;
      final File imageFile = File(finalImagePath);

      String scanMode = 'list';
      if (template.customInstruction != null) {
        try {
          final decoded = jsonDecode(template.customInstruction!);
          if (decoded is Map && decoded.containsKey('mode')) {
            scanMode = decoded['mode'];
          }
        } catch (_) {}
      }

      final List<String> fields = (jsonDecode(template.targetFieldsJson) as List).cast<String>();
      final imageBytes = await imageFile.readAsBytes();

      final Map<String, dynamic>? extractedData = await GeminiService.analyzeImage(
        imageBytes: imageBytes,
        targetFields: fields,
        mode: scanMode,
      );

      if (extractedData == null) throw Exception('AIによる解析に失敗しました');

      final db = ref.read(databaseProvider);
      final id = await db.into(db.scanHistories).insert(
        ScanHistoriesCompanion.insert(
          templateId: template.id,
          imagePath: finalImagePath,
          resultJson: jsonEncode(extractedData),
        ),
      );

      if (context.mounted) {
        Navigator.pop(context); 
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScanResultPage(historyId: id)),
        );
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラ―: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.document_scanner_outlined, size: 80, color: Colors.indigo.withOpacity(0.6)),
                const SizedBox(height: 16),
                const Text('テンプレートがありません', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                const Text('「+」ボタンから\n読み取りたい書類の設定を作ってください', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF475569))),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _createSampleTemplate(context, ref),
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('サンプルを作成'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
    );
  }

  Widget _buildTemplateList(BuildContext context, WidgetRef ref, List<ExtractionTemplate> templates) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 8, left: 16, right: 16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final fields = (jsonDecode(template.targetFieldsJson) as List).cast<String>();
        
        String modeText = '表形式';
        if (template.customInstruction != null) {
          try {
            final decoded = jsonDecode(template.customInstruction!);
            if (decoded is Map && decoded['mode'] == 'text') modeText = '全文形式';
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          // ★ 既存のCardを削除し、GlassCardでラッピング
          child: _buildGlassCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _startScan(context, ref, template),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(template.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6), // ラベルも半透明に
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.8)),
                          ),
                          child: Text(modeText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: modeText == '表形式' ? Colors.green.shade700 : Colors.orange.shade800)),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Color(0xFF475569)),
                          onSelected: (value) { if (value == 'delete') _deleteTemplate(context, ref, template); },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('削除', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      ],
                    ),
                    Divider(color: Colors.white.withOpacity(0.5), thickness: 1.5, height: 24),
                    if (fields.isNotEmpty && modeText == '表形式') ...[
                      const Text('抽出項目:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: fields.map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.7)),
                          ),
                          child: Text(f, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                        )).toList(),
                      ),
                    ] else ...[
                      const Text('抽出項目: なし (全文をそのまま読み取ります)', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startScan(context, ref, template),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('スキャン開始'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 400.ms, delay: (50 * index).ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: (50 * index).ms, curve: Curves.easeOutQuad);
      },
    );
  }

  Future<void> _createSampleTemplate(BuildContext context, WidgetRef ref) async {
    final instructionData = {'mode': 'list'};
    final db = ref.read(databaseProvider);
    await db.into(db.extractionTemplates).insert(
      ExtractionTemplatesCompanion.insert(
        name: '領収書 (サンプル)',
        targetFieldsJson: jsonEncode(['日付', '支払先', '合計金額', '登録番号']),
        customInstruction: drift.Value(jsonEncode(instructionData)),
      ),
    );
  }

  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref, ExtractionTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9), // ダイアログも少し透けさせる
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
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
    }
  }
}