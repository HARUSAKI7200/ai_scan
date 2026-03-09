// lib/pages/scan_result_page.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // ★追加: すりガラス効果用
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' hide Border; 
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;

import '../database/app_database.dart';
import '../main.dart'; // databaseProvider

class ScanResultPage extends ConsumerStatefulWidget {
  final int historyId;

  const ScanResultPage({super.key, required this.historyId});

  @override
  ConsumerState<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends ConsumerState<ScanResultPage> {
  late Future<ScanHistory?> _historyFuture;
  
  List<Map<String, TextEditingController>> _controllersList = [];
  List<String> _headers = [];
  TextEditingController? _textController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final db = ref.read(databaseProvider);
    _historyFuture = (db.select(db.scanHistories)..where((t) => t.id.equals(widget.historyId))).getSingleOrNull();
  }

  Future<void> _saveChanges(ScanHistory history) async {
    FocusScope.of(context).unfocus();
    final db = ref.read(databaseProvider);
    
    String newJsonString;
    if (_textController != null) {
      newJsonString = jsonEncode({'text': _textController!.text});
    } else {
      List<Map<String, dynamic>> updatedItems = [];
      for (var rowControllers in _controllersList) {
        Map<String, dynamic> rowData = {};
        rowControllers.forEach((key, controller) {
          rowData[key] = controller.text;
        });
        updatedItems.add(rowData);
      }
      newJsonString = jsonEncode({'items': updatedItems});
    }

    await (db.update(db.scanHistories)..where((t) => t.id.equals(history.id))).write(
      ScanHistoriesCompanion(resultJson: drift.Value(newJsonString)),
    );

    setState(() {
      _isEditing = false;
      _loadData();
    });

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました')));
  }

  Future<void> _exportData(ScanHistory history, String templateName) async {
    if (_textController != null) {
      final text = _textController!.text;
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('共有するテキストがありません')));
        return;
      }
      await Share.share(text, subject: '$templateNameのスキャン結果');
      final db = ref.read(databaseProvider);
      await (db.update(db.scanHistories)..where((t) => t.id.equals(history.id))).write(const ScanHistoriesCompanion(isExported: drift.Value(true)));
    } else {
      try {
        final Map<String, dynamic> resultData = jsonDecode(history.resultJson);
        final List<dynamic> itemsList = resultData.containsKey('items') ? resultData['items'] : [resultData];
        if (itemsList.isEmpty) throw Exception('出力するデータがありません');

        final excel = Excel.createExcel();
        final Sheet sheet = excel['Sheet1'];
        final Map<String, dynamic> firstItem = itemsList.first as Map<String, dynamic>;
        final headers = firstItem.keys.toList();
        sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

        for (var item in itemsList) {
          final Map<String, dynamic> rowData = item as Map<String, dynamic>;
          final values = headers.map((h) => rowData[h]?.toString() ?? '').map((v) => TextCellValue(v)).toList();
          sheet.appendRow(values);
        }

        final tempDir = await getTemporaryDirectory();
        final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
        final file = File(p.join(tempDir.path, fileName));
        
        final fileBytes = excel.save();
        if (fileBytes != null) {
          await file.writeAsBytes(fileBytes);
          await Share.shareXFiles([XFile(file.path)], text: '$templateNameのスキャン結果');
          final db = ref.read(databaseProvider);
          await (db.update(db.scanHistories)..where((t) => t.id.equals(history.id))).write(const ScanHistoriesCompanion(isExported: drift.Value(true)));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エクセル出力エラー: $e')));
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_textController != null) {
      await Clipboard.setData(ClipboardData(text: _textController!.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テキストをコピーしました')));
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    for (var row in _controllersList) {
      row.forEach((_, c) => c.dispose());
    }
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: -5)],
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
              Color(0xFFE0C3FC), 
              Color(0xFF8EC5FC), 
              Color(0xFFE0C3FC), 
            ],
            stops: [0.0, 0.5, 1.0], 
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, // Scaffoldを透明に
          appBar: AppBar(
            title: const Text('確認・編集'),
            backgroundColor: Colors.transparent, 
            elevation: 0,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, size: 26),
                  tooltip: '編集する',
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: SafeArea(
            child: FutureBuilder<ScanHistory?>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.data == null) return const Center(child: Text('データが見つかりません'));

                final history = snapshot.data!;
                final Map<String, dynamic> resultData = jsonDecode(history.resultJson);
                final imageFile = File(history.imagePath);

                if (_controllersList.isEmpty && _textController == null) {
                  if (resultData.containsKey('text')) {
                    _textController = TextEditingController(text: resultData['text']?.toString() ?? '');
                  } else {
                    final List<dynamic> itemsList = resultData.containsKey('items') ? resultData['items'] : [resultData];
                    if (itemsList.isNotEmpty) {
                      final firstItem = itemsList.first as Map<String, dynamic>;
                      _headers = firstItem.keys.toList();
                      for (var item in itemsList) {
                        final Map<String, dynamic> rowData = item as Map<String, dynamic>;
                        Map<String, TextEditingController> rowControllers = {};
                        for (var key in _headers) {
                          rowControllers[key] = TextEditingController(text: rowData[key]?.toString() ?? '');
                        }
                        _controllersList.add(rowControllers);
                      }
                    }
                  }
                }

                const templateName = "スキャン結果"; 
                final isTextMode = _textController != null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isEditing ? null : () => _exportData(history, templateName),
                              icon: Icon(isTextMode ? Icons.share : Icons.table_chart),
                              label: Text(isTextMode ? 'テキストを共有' : 'エクセルで出力'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isTextMode ? Colors.orange.shade400 : Colors.green.shade500,
                              ),
                            ),
                          ),
                          if (isTextMode) ...[
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _copyToClipboard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667EEA),
                              ),
                              child: const Icon(Icons.copy),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (imageFile.existsSync())
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: InteractiveViewer(child: Image.file(imageFile)))));
                          },
                          // ★ 画像エリアをすりガラスカードでラッピング
                          child: _buildGlassCard(
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(image: FileImage(imageFile), fit: BoxFit.contain),
                              ),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                  child: const Icon(Icons.zoom_in, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('抽出データ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          if (!_isEditing)
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _isEditing = true),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('編集する'),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E293B), side: const BorderSide(color: Color(0xFF1E293B))),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => _saveChanges(history),
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('保存'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ★ フォーム/表エリアをすりガラスカードでラッピング
                      _buildGlassCard(
                        child: isTextMode
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _textController,
                                readOnly: !_isEditing,
                                maxLines: null, 
                                minLines: 10,   
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: _isEditing,
                                  fillColor: Colors.white.withOpacity(0.5),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            )
                          : _headers.isNotEmpty
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.white.withOpacity(0.4)),
                                  child: DataTable(
                                    dataRowMinHeight: 56,
                                    dataRowMaxHeight: double.infinity,
                                    headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.3)),
                                    columnSpacing: 24,
                                    columns: _headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))).toList(),
                                    rows: _controllersList.map((rowControllers) {
                                      return DataRow(
                                        cells: _headers.map((h) {
                                          return DataCell(
                                            Container(
                                              constraints: const BoxConstraints(minWidth: 140, maxWidth: 250),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: TextField(
                                                controller: rowControllers[h],
                                                readOnly: !_isEditing,
                                                maxLines: null, 
                                                keyboardType: TextInputType.multiline, 
                                                style: const TextStyle(color: Color(0xFF1E293B)),
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  focusedBorder: _isEditing ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF667EEA))) : InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.all(12),
                                                  filled: _isEditing,
                                                  fillColor: Colors.white.withOpacity(0.6),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              )
                            : const Padding(padding: EdgeInsets.all(24.0), child: Text('データがありません')),
                      ),
                      const SizedBox(height: 300), 
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}