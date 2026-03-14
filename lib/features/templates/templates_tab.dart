// lib/features/templates/templates_tab.dart

import 'dart:convert';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_animate/flutter_animate.dart';

import '../../database/app_database.dart';
import '../../main.dart'; 
import '../../utils/scan_helper.dart';
import 'template_create_page.dart'; 

final templatesStreamProvider = StreamProvider<List<ExtractionTemplate>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.extractionTemplates)
        ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)]))
      .watch();
});

class TemplatesTab extends ConsumerWidget {
  const TemplatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('テンプレート管理'),
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
    );
  }

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
          child: _buildGlassCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => ScanHelper.startScan(context, ref, template),
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
                            color: Colors.white.withOpacity(0.6), 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.8)),
                          ),
                          child: Text(modeText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: modeText == '表形式' ? Colors.green.shade700 : Colors.orange.shade800)),
                        ),
                        // ★ 編集・複製メニューの追加
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Color(0xFF475569)),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TemplateCreatePage(templateToEdit: template, isDuplicate: false)),
                              );
                            } else if (value == 'duplicate') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TemplateCreatePage(templateToEdit: template, isDuplicate: true)),
                              );
                            } else if (value == 'delete') {
                              _deleteTemplate(context, ref, template);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('編集')])),
                            const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, color: Colors.orange, size: 20), SizedBox(width: 8), Text('複製')])),
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
                        onPressed: () => ScanHelper.startScan(context, ref, template),
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
        backgroundColor: Colors.white.withOpacity(0.9), 
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