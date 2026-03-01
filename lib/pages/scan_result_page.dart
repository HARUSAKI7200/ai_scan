// lib/pages/scan_result_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
// driftのインポートを正しい位置（先頭）に移動
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
  Map<String, TextEditingController> _controllers = {};
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

  // データを保存して更新
  Future<void> _saveChanges(ScanHistory history) async {
    final db = ref.read(databaseProvider);
    
    // コントローラーから最新の値を取得してJSONを作る
    Map<String, dynamic> currentData = {};
    _controllers.forEach((key, controller) {
      currentData[key] = controller.text;
    });

    await (db.update(db.scanHistories)..where((t) => t.id.equals(history.id))).write(
      ScanHistoriesCompanion(
        resultJson: drift.Value(jsonEncode(currentData)),
      ),
    );

    setState(() {
      _isEditing = false;
      _loadData(); // 再読み込み
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました')));
    }
  }

  // エクセル出力
  Future<void> _exportExcel(ScanHistory history, String templateName) async {
    try {
      final Map<String, dynamic> data = jsonDecode(history.resultJson);
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Sheet1'];

      // ヘッダー行
      final headers = data.keys.toList();
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // データ行
      final values = headers.map((h) => data[h]?.toString() ?? '').map((v) => TextCellValue(v)).toList();
      sheet.appendRow(values);

      // 保存
      final tempDir = await getTemporaryDirectory();
      final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final file = File(p.join(tempDir.path, fileName));
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        
        // 共有シートを表示
        await Share.shareXFiles([XFile(file.path)], text: '$templateNameのスキャン結果');
        
        // DBのステータス更新
        final db = ref.read(databaseProvider);
        await (db.update(db.scanHistories)..where((t) => t.id.equals(history.id))).write(
          const ScanHistoriesCompanion(isExported: drift.Value(true)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エクセル出力エラー: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScanHistory?>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('データが見つかりません')));
        }

        final history = snapshot.data!;
        final Map<String, dynamic> resultData = jsonDecode(history.resultJson);
        final imageFile = File(history.imagePath);

        // コントローラーの初期化（初回のみ）
        if (_controllers.isEmpty) {
          resultData.forEach((key, value) {
            _controllers[key] = TextEditingController(text: value.toString());
          });
        }

        // テンプレート名を取得するためのサブクエリ（今回は簡易的に非同期で取得せず、渡されていないため汎用名にするか、別途取得が必要）
        const templateName = "スキャン結果"; 

        return Scaffold(
          appBar: AppBar(
            title: const Text('確認・編集'),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveChanges(history),
                ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _exportExcel(history, templateName),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 画像表示エリア
                if (imageFile.existsSync())
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(child: Image.file(imageFile)),
                        ),
                      );
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(imageFile),
                          fit: BoxFit.contain,
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.zoom_in, color: Colors.white),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(
                    height: 100,
                    child: Center(child: Text('画像ファイルが見つかりません')),
                  ),
                
                const SizedBox(height: 24),
                
                // データフォーム
                const Text('抽出データ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                ..._controllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: entry.value,
                      readOnly: !_isEditing,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: const OutlineInputBorder(),
                        filled: !_isEditing, // 編集不可時はグレーアウト
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}