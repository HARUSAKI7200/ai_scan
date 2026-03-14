// lib/features/templates/template_create_page.dart

import 'dart:convert';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../database/app_database.dart';
import '../../main.dart'; 

class TemplateCreatePage extends ConsumerStatefulWidget {
  final ExtractionTemplate? templateToEdit;
  final bool isDuplicate; // trueなら新規作成扱い（複製）、falseなら上書き保存（編集）

  const TemplateCreatePage({
    super.key, 
    this.templateToEdit,
    this.isDuplicate = false,
  });

  @override
  ConsumerState<TemplateCreatePage> createState() => _TemplateCreatePageState();
}

class _TemplateCreatePageState extends ConsumerState<TemplateCreatePage> {
  final _nameController = TextEditingController();
  final _fieldsController = TextEditingController();
  
  String _selectedMode = 'list'; // 'list' or 'text'

  @override
  void initState() {
    super.initState();
    // 編集・複製の場合は初期値をセット
    if (widget.templateToEdit != null) {
      _nameController.text = widget.isDuplicate 
          ? '${widget.templateToEdit!.name} のコピー' 
          : widget.templateToEdit!.name;
      
      try {
        final fields = jsonDecode(widget.templateToEdit!.targetFieldsJson) as List;
        _fieldsController.text = fields.join(', ');
      } catch (_) {}

      if (widget.templateToEdit!.customInstruction != null) {
        try {
          final decoded = jsonDecode(widget.templateToEdit!.customInstruction!);
          if (decoded is Map && decoded['mode'] == 'text') {
            _selectedMode = 'text';
          }
        } catch (_) {}
      }
    }
  }

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

    if (widget.templateToEdit != null && !widget.isDuplicate) {
      // 編集（更新）
      await (db.update(db.extractionTemplates)..where((t) => t.id.equals(widget.templateToEdit!.id))).write(
        ExtractionTemplatesCompanion(
          name: drift.Value(name),
          targetFieldsJson: drift.Value(jsonEncode(fields)),
          customInstruction: drift.Value(jsonEncode(instructionData)),
        ),
      );
    } else {
      // 新規作成 または 複製
      await db.into(db.extractionTemplates).insert(
        ExtractionTemplatesCompanion.insert(
          name: name,
          targetFieldsJson: jsonEncode(fields),
          customInstruction: drift.Value(jsonEncode(instructionData)),
        ),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.templateToEdit != null && !widget.isDuplicate ? 'テンプレートを更新しました' : 'テンプレートを作成しました')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fieldsController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.templateToEdit != null && !widget.isDuplicate;
    final appBarTitle = widget.isDuplicate ? 'テンプレートを複製' : (isEditMode ? 'テンプレート編集' : '新規テンプレート設定');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0C3FC), 
              Color(0xFF8EC5FC), 
              Color(0xFFE0C3FC), 
            ],
            stops: [0.0, 0.5, 1.0], 
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, 
          appBar: AppBar(
            title: Text(appBarTitle),
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
                        child: Text(isEditMode ? '更新する' : 'この内容で作成する', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 80), 
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