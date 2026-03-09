// lib/pages/template_create_page.dart

import 'dart:convert';
import 'dart:ui'; // ★追加: すりガラス効果用
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../database/app_database.dart';
import '../main.dart'; // databaseProvider

class TemplateCreatePage extends ConsumerStatefulWidget {
  const TemplateCreatePage({super.key});

  @override
  ConsumerState<TemplateCreatePage> createState() => _TemplateCreatePageState();
}

class _TemplateCreatePageState extends ConsumerState<TemplateCreatePage> {
  final _nameController = TextEditingController();
  final _fieldsController = TextEditingController();
  
  String _selectedMode = 'list'; // 'list' or 'text'

  Future<void> _saveTemplate() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テンプレート名を入力してください')),
      );
      return;
    }

    List<String> fields = [];
    if (_selectedMode == 'list') {
      fields = _fieldsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (fields.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('抽出する項目を入力してください')),
        );
        return;
      }
    }

    final instructionData = {
      'mode': _selectedMode,
    };

    final db = ref.read(databaseProvider);
    await db.into(db.extractionTemplates).insert(
      ExtractionTemplatesCompanion.insert(
        name: name,
        targetFieldsJson: jsonEncode(fields),
        customInstruction: drift.Value(jsonEncode(instructionData)),
      ),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テンプレートを作成しました')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fieldsController.dispose();
    super.dispose();
  }

  // ★ 追加: すりガラスのカードを作る専用ウィジェット
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      // ★ 鮮やかなオーロラグラデーション背景
      child: Container(
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
          backgroundColor: Colors.transparent, // Scaffoldを透明に
          appBar: AppBar(
            title: const Text('新規テンプレート設定'),
            backgroundColor: Colors.transparent, 
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.check, size: 28),
                onPressed: _saveTemplate,
                tooltip: '保存',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            // ★ フォーム全体をすりガラスカードで包む
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('基本設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'テンプレート名',
                        hintText: '例: 領収書, 議事録',
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text('読み取りモード設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('表・リスト読み取りモード', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('領収書や一覧表から複数行のデータを抽出します'),
                            value: 'list',
                            groupValue: _selectedMode,
                            activeColor: const Color(0xFF667EEA),
                            onChanged: (value) {
                              setState(() {
                                FocusScope.of(context).unfocus();
                                _selectedMode = value!;
                              });
                            },
                          ),
                          Divider(height: 1, color: Colors.white.withOpacity(0.5), thickness: 1.5),
                          RadioListTile<String>(
                            title: const Text('全文読み取りモード', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('契約書や日報などのテキストを全文抽出します'),
                            value: 'text',
                            groupValue: _selectedMode,
                            activeColor: const Color(0xFF667EEA),
                            onChanged: (value) {
                              setState(() {
                                FocusScope.of(context).unfocus();
                                _selectedMode = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_selectedMode == 'list') ...[
                      const Text('抽出項目設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fieldsController,
                        decoration: const InputDecoration(
                          labelText: '抽出する項目 (カンマ区切り)',
                          hintText: '例: 日付, 会社名, 金額',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveTemplate,
                        child: const Text('この内容で作成する', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 80), // キーボード用余白
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}