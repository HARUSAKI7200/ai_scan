// lib/features/scan/scan_result_page.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui'; 
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' hide Border; 
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../database/app_database.dart';
import '../../main.dart'; 

enum ExportFormat { text, pdf, word, excel, csv, image }
enum ExportAction { save, share }

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
  
  // 各行の「要確認フラグ（低信頼度）」を管理するリスト
  List<bool> _needsReviewList = [];

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
      for (int i = 0; i < _controllersList.length; i++) {
        Map<String, dynamic> rowData = {};
        _controllersList[i].forEach((key, controller) {
          rowData[key] = controller.text;
        });
        // 保存時に要確認フラグ状態も保持させる
        rowData['_needsReview'] = _needsReviewList[i];
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

  Future<void> _markAsExported(ScanHistory history) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.scanHistories)..where((t) => t.id.equals(history.id))).write(const ScanHistoriesCompanion(isExported: drift.Value(true)));
    setState(() {
      _loadData();
    });
  }

  // ==========================================
  // 【各種フォーマット処理群（保存・共有）】
  // ==========================================

  // --- テキスト ---
  Future<void> _saveAsTextFile(String text, String templateName, ScanHistory history) async {
    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.txt';
    final bytes = Uint8List.fromList(utf8.encode(text)); 
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'テキストを保存', fileName: fileName, type: FileType.custom, allowedExtensions: ['txt'], bytes: bytes, 
    );
    if (outputFile != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テキストを保存しました')));
      await _markAsExported(history);
    }
  }

  Future<void> _shareText(String text, String templateName, ScanHistory history) async {
    await Share.share(text, subject: '$templateNameのスキャン結果');
    await _markAsExported(history);
  }

  // --- PDF ---
  Future<Uint8List> _generatePdfBytes(String text) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load('assets/fonts/NotoSansJP-Bold.ttf');
    final ttfBold = pw.Font.ttf(boldFontData);
    final textLines = text.split('\n');

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (pw.Context context) => [
          ...textLines.map((line) => pw.Text(line.isEmpty ? ' ' : line, style: pw.TextStyle(font: ttf, fontSize: 12))),
        ],
      ),
    );
    return await pdf.save();
  }

  Future<void> _saveAsPdfFile(String text, String templateName, ScanHistory history) async {
    final bytes = await _generatePdfBytes(text);
    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'PDFを保存', fileName: fileName, type: FileType.custom, allowedExtensions: ['pdf'], bytes: bytes, 
    );
    if (outputFile != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDFを保存しました')));
      await _markAsExported(history);
    }
  }

  Future<void> _sharePdfFile(String text, String templateName, ScanHistory history) async {
    final bytes = await _generatePdfBytes(text);
    final tempDir = await getTemporaryDirectory();
    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '$templateNameのPDFファイル');
    await _markAsExported(history);
  }

  // --- Word ---
  String _generateWordHtml(String text, String templateName) {
    final escapedText = const HtmlEscape().convert(text).replaceAll('\n', '<br>');
    return '''
      <html xmlns:w="urn:schemas-microsoft-com:office:word">
      <head><meta charset="utf-8"><title>$templateName</title></head>
      <body><p>$escapedText</p></body>
      </html>
    ''';
  }

  Future<void> _saveAsWordFile(String text, String templateName, ScanHistory history) async {
    final htmlContent = _generateWordHtml(text, templateName);
    final bytes = Uint8List.fromList(utf8.encode(htmlContent)); 
    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.doc';
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Wordを保存', fileName: fileName, type: FileType.custom, allowedExtensions: ['doc'], bytes: bytes, 
    );
    if (outputFile != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wordを保存しました')));
      await _markAsExported(history);
    }
  }

  Future<void> _shareWordFile(String text, String templateName, ScanHistory history) async {
    final htmlContent = _generateWordHtml(text, templateName);
    final tempDir = await getTemporaryDirectory();
    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.doc';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsString(htmlContent);
    await Share.shareXFiles([XFile(file.path)], text: '$templateNameのWordファイル');
    await _markAsExported(history);
  }

  // --- Excel ---
  Uint8List? _generateExcelBytes(ScanHistory history) {
    if (_controllersList.isEmpty) return null;

    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];
    sheet.appendRow(_headers.map((h) => TextCellValue(h)).toList());

    for (var rowControllers in _controllersList) {
      final values = _headers.map((h) => TextCellValue(rowControllers[h]?.text ?? '')).toList();
      sheet.appendRow(values);
    }
    final fileBytes = excel.save();
    return fileBytes != null ? Uint8List.fromList(fileBytes) : null;
  }

  Future<void> _saveAsExcelFile(ScanHistory history, String templateName) async {
    final bytes = _generateExcelBytes(history);
    if (bytes == null) throw Exception('出力するデータがありません');

    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Excelを保存', fileName: fileName, type: FileType.custom, allowedExtensions: ['xlsx'], bytes: bytes, 
    );
    if (outputFile != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excelを保存しました')));
      await _markAsExported(history);
    }
  }

  Future<void> _shareExcel(ScanHistory history, String templateName) async {
    final bytes = _generateExcelBytes(history);
    if (bytes == null) throw Exception('出力するデータがありません');

    final tempDir = await getTemporaryDirectory();
    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '$templateNameのスキャン結果');
    await _markAsExported(history);
  }

  // --- CSV ---
  String? _generateCsvString() {
    if (_controllersList.isEmpty) return null;
    
    String escapeCsv(String input) {
      if (input.contains(',') || input.contains('\n') || input.contains('"')) {
        return '"${input.replaceAll('"', '""')}"';
      }
      return input;
    }

    final buffer = StringBuffer();
    // ヘッダー行
    buffer.writeln(_headers.map(escapeCsv).join(','));
    // データ行
    for (var rowControllers in _controllersList) {
      final rowStr = _headers.map((h) => escapeCsv(rowControllers[h]?.text ?? '')).join(',');
      buffer.writeln(rowStr);
    }
    return buffer.toString();
  }

  Future<void> _saveAsCsvFile(ScanHistory history, String templateName) async {
    final csvString = _generateCsvString();
    if (csvString == null) throw Exception('出力するデータがありません');
    
    // Excelで開いた時の文字化け防止のためBOM(Byte Order Mark)を付与
    final bytes = utf8.encode(csvString);
    final bom = [0xEF, 0xBB, 0xBF];
    final finalBytes = Uint8List.fromList([...bom, ...bytes]);

    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'CSVを保存', fileName: fileName, type: FileType.custom, allowedExtensions: ['csv'], bytes: finalBytes, 
    );
    if (outputFile != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSVを保存しました')));
      await _markAsExported(history);
    }
  }

  Future<void> _shareCsvFile(ScanHistory history, String templateName) async {
    final csvString = _generateCsvString();
    if (csvString == null) throw Exception('出力するデータがありません');

    final bytes = utf8.encode(csvString);
    final bom = [0xEF, 0xBB, 0xBF];
    final finalBytes = Uint8List.fromList([...bom, ...bytes]);

    final tempDir = await getTemporaryDirectory();
    final fileName = '${templateName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(finalBytes);
    await Share.shareXFiles([XFile(file.path)], text: '$templateNameのCSVファイル');
    await _markAsExported(history);
  }

  // --- 画像 ---
  Future<void> _saveImageFile(ScanHistory history, String templateName) async {
    final sourceFile = File(history.imagePath);
    if (!sourceFile.existsSync()) throw Exception('画像ファイルが見つかりません');
    final ext = p.extension(history.imagePath).replaceAll('.', '');
    final extension = ext.isEmpty ? 'jpg' : ext;
    final fileName = '${templateName}_画像_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.$extension';
    final bytes = await sourceFile.readAsBytes(); 
    final outputFile = await FilePicker.platform.saveFile(dialogTitle: '画像を保存', fileName: fileName, type: FileType.image, bytes: bytes);
    if (outputFile != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('画像を保存しました')));
    }
  }

  Future<void> _shareImageFile(ScanHistory history, String templateName) async {
    final sourceFile = File(history.imagePath);
    if (!sourceFile.existsSync()) throw Exception('画像ファイルが見つかりません');
    await Share.shareXFiles([XFile(sourceFile.path)], text: '$templateNameの画像');
  }

  // ==========================================
  // 【フロー統括メソッド】
  // ==========================================
  Future<void> _executeExport(ExportFormat format, ExportAction action, ScanHistory history, String templateName) async {
    // ★広告フック（_showAdOrConsumeTicketPlaceholder）を削除し、直接出力処理を実行します
    try {
      switch (format) {
        case ExportFormat.text:
          if (action == ExportAction.save) await _saveAsTextFile(_textController!.text, templateName, history);
          else await _shareText(_textController!.text, templateName, history);
          break;
        case ExportFormat.pdf:
          if (action == ExportAction.save) await _saveAsPdfFile(_textController!.text, templateName, history);
          else await _sharePdfFile(_textController!.text, templateName, history);
          break;
        case ExportFormat.word:
          if (action == ExportAction.save) await _saveAsWordFile(_textController!.text, templateName, history);
          else await _shareWordFile(_textController!.text, templateName, history);
          break;
        case ExportFormat.excel:
          if (action == ExportAction.save) await _saveAsExcelFile(history, templateName);
          else await _shareExcel(history, templateName);
          break;
        case ExportFormat.csv:
          if (action == ExportAction.save) await _saveAsCsvFile(history, templateName);
          else await _shareCsvFile(history, templateName);
          break;
        case ExportFormat.image:
          if (action == ExportAction.save) await _saveImageFile(history, templateName);
          else await _shareImageFile(history, templateName);
          break;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('出力中にエラーが発生しました: $e')));
    }
  }

  // ==========================================
  // 【UI・ビルド処理群】
  // ==========================================

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

  Widget _buildDialogOption({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportMenu(BuildContext context, bool isTextMode, ScanHistory history, String templateName) {
    if (isTextMode && (_textController == null || _textController!.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('出力するテキストがありません')));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int step = 1; 
        ExportFormat? selectedFormat;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step == 1 ? '保存形式を選択' : 'アクションを選択',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 24),
                        
                        if (step == 1) ...[
                          if (isTextMode) ...[
                            _buildDialogOption(
                              icon: Icons.text_snippet, color: const Color(0xFF667EEA), title: 'テキストファイル (.txt)',
                              onTap: () => setState(() { selectedFormat = ExportFormat.text; step = 2; }),
                            ),
                            _buildDialogOption(
                              icon: Icons.picture_as_pdf, color: Colors.redAccent, title: 'PDFファイル (.pdf)',
                              onTap: () => setState(() { selectedFormat = ExportFormat.pdf; step = 2; }),
                            ),
                            _buildDialogOption(
                              icon: Icons.description, color: Colors.blueAccent, title: 'Wordファイル (.doc)',
                              onTap: () => setState(() { selectedFormat = ExportFormat.word; step = 2; }),
                            ),
                          ] else ...[
                            _buildDialogOption(
                              icon: Icons.table_chart, color: Colors.green, title: 'Excelファイル (.xlsx)',
                              onTap: () => setState(() { selectedFormat = ExportFormat.excel; step = 2; }),
                            ),
                            _buildDialogOption(
                              icon: Icons.grid_on, color: Colors.teal, title: 'CSVファイル (.csv)',
                              onTap: () => setState(() { selectedFormat = ExportFormat.csv; step = 2; }),
                            ),
                          ],
                          _buildDialogOption(
                            icon: Icons.image, color: Colors.orange, title: '元のスキャン画像 (.jpg)',
                            onTap: () => setState(() { selectedFormat = ExportFormat.image; step = 2; }),
                          ),
                        ] 
                        else ...[
                          _buildDialogOption(
                            icon: Icons.save_alt, color: const Color(0xFF667EEA), title: '端末に保存 (フォルダ選択)',
                            onTap: () {
                              Navigator.pop(context);
                              _executeExport(selectedFormat!, ExportAction.save, history, templateName);
                            },
                          ),
                          _buildDialogOption(
                            icon: Icons.share, color: Colors.green, title: '他のアプリへ送信・共有',
                            onTap: () {
                              Navigator.pop(context);
                              _executeExport(selectedFormat!, ExportAction.share, history, templateName);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() => step = 1),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                            child: const Text('戻る', style: TextStyle(fontSize: 16)),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      _headers = firstItem.keys.where((k) => k != '_needsReview').toList();
                      
                      for (var item in itemsList) {
                        final Map<String, dynamic> rowData = item as Map<String, dynamic>;
                        Map<String, TextEditingController> rowControllers = {};
                        for (var key in _headers) {
                          rowControllers[key] = TextEditingController(text: rowData[key]?.toString() ?? '');
                        }
                        _controllersList.add(rowControllers);
                        // 要確認フラグの読み込み（なければfalse）
                        _needsReviewList.add(rowData['_needsReview'] == true);
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
                              onPressed: _isEditing ? null : () => _showExportMenu(context, isTextMode, history, templateName),
                              icon: const Icon(Icons.ios_share),
                              label: const Text('出力・保存'),
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
                                    columns: [
                                      const DataColumn(label: Text('状態', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                      ..._headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))),
                                    ],
                                    rows: List.generate(_controllersList.length, (index) {
                                      final rowControllers = _controllersList[index];
                                      final isNeedsReview = _needsReviewList[index];
                                      return DataRow(
                                        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                          if (isNeedsReview) return Colors.redAccent.withOpacity(0.15);
                                          return null;
                                        }),
                                        cells: [
                                          DataCell(
                                            IconButton(
                                              icon: Icon(
                                                isNeedsReview ? Icons.flag : Icons.flag_outlined,
                                                color: isNeedsReview ? Colors.redAccent : Colors.grey,
                                              ),
                                              onPressed: _isEditing ? () {
                                                setState(() {
                                                  _needsReviewList[index] = !_needsReviewList[index];
                                                });
                                              } : null,
                                              tooltip: '要確認フラグを切り替え',
                                            ),
                                          ),
                                          ..._headers.map((h) {
                                            return DataCell(
                                              Container(
                                                constraints: const BoxConstraints(minWidth: 140, maxWidth: 250),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: TextField(
                                                  controller: rowControllers[h],
                                                  readOnly: !_isEditing,
                                                  maxLines: null, 
                                                  keyboardType: TextInputType.multiline, 
                                                  style: TextStyle(
                                                    color: isNeedsReview ? Colors.red.shade900 : const Color(0xFF1E293B),
                                                    fontWeight: isNeedsReview ? FontWeight.bold : FontWeight.normal,
                                                  ),
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
                                          }),
                                        ],
                                      );
                                    }),
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