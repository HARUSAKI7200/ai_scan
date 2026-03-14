// lib/features/history/history_tab.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../database/app_database.dart';
import '../../main.dart'; // databaseProvider
import '../scan/scan_result_page.dart'; 

class ScanHistoryWithTemplate {
  final ScanHistory history;
  final String templateName;
  ScanHistoryWithTemplate({required this.history, required this.templateName});
}

final scanHistoriesProvider = StreamProvider<List<ScanHistoryWithTemplate>>((ref) {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.scanHistories).join([
    drift.innerJoin(
      db.extractionTemplates,
      db.extractionTemplates.id.equalsExp(db.scanHistories.templateId),
    ),
  ])..orderBy([drift.OrderingTerm(expression: db.scanHistories.scannedAt, mode: drift.OrderingMode.desc)]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return ScanHistoryWithTemplate(
        history: row.readTable(db.scanHistories),
        templateName: row.readTable(db.extractionTemplates).name,
      );
    }).toList();
  });
});

final cacheSizeProvider = Provider<String>((ref) {
  final historiesAsync = ref.watch(scanHistoriesProvider);
  
  return historiesAsync.when(
    data: (histories) {
      int totalBytes = 0;
      for (final item in histories) {
        final file = File(item.history.imagePath);
        if (file.existsSync()) {
          totalBytes += file.lengthSync();
        }
      }
      if (totalBytes == 0) return "0.0 MB";
      
      final mb = totalBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    },
    loading: () => "計算中...",
    error: (_, __) => "エラー",
  );
});

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {}; 
  
  // ★追加: 検索機能用コントローラー
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
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

  Future<void> _deleteSingleHistory(ScanHistory history) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text('削除確認'),
        content: const Text('このスキャン履歴を削除しますか？\n端末に保存されている元の画像ファイルも完全に削除されます。'),
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
      _executeDeletion([history]);
    }
  }

  Future<void> _deleteSelectedHistories(List<ScanHistoryWithTemplate> allHistories) async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text('一括削除の確認'),
        content: Text('${_selectedIds.length}件のスキャン履歴を削除しますか？\n関連する画像ファイルもすべて削除され、元に戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('一括削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final targetsToDelete = allHistories
          .where((item) => _selectedIds.contains(item.history.id))
          .map((item) => item.history)
          .toList();
      
      await _executeDeletion(targetsToDelete);
      _clearSelection(); 
    }
  }

  Future<void> _executeDeletion(List<ScanHistory> targets) async {
    final db = ref.read(databaseProvider);
    
    for (final history in targets) {
      try {
        final file = File(history.imagePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('画像削除エラー: $e');
      }
      await (db.delete(db.scanHistories)..where((t) => t.id.equals(history.id))).go();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${targets.length}件の履歴と画像を削除しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historiesAsync = ref.watch(scanHistoriesProvider);
    final cacheSize = ref.watch(cacheSizeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: const Color(0xFF667EEA).withOpacity(0.1), 
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length}件 選択中', style: const TextStyle(fontSize: 18)),
              actions: [
                TextButton(
                  onPressed: () {
                    final allHistories = historiesAsync.value ?? [];
                    setState(() {
                      if (_selectedIds.length == allHistories.length) {
                        _selectedIds.clear(); 
                      } else {
                        _selectedIds.addAll(allHistories.map((e) => e.history.id));
                      }
                    });
                  },
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E293B)),
                  child: const Text('すべて選択'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _deleteSelectedHistories(historiesAsync.value ?? []),
                ),
              ],
            )
          : AppBar(
              title: const Text('スキャン履歴'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('長押しで複数選択して一括削除できます')),
                    );
                  },
                )
              ],
            ),
      body: Column(
        children: [
          // ★追加: 検索・フィルタリングUI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildGlassCard(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'テンプレート名やテキストで検索...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF667EEA)),
                  suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ).animate().fade().slideY(begin: -0.1, end: 0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.storage, size: 20, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(
                  '現在の画像保存容量: ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                Text(
                  cacheSize,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA), fontSize: 16),
                ),
              ],
            ).animate().fade().slideX(begin: -0.1),
          ),
          
          Expanded(
            child: historiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
              data: (allHistories) {
                // ★追加: 検索クエリによるフィルタリング適用
                final histories = _searchQuery.isEmpty 
                    ? allHistories 
                    : allHistories.where((item) {
                        final templateMatch = item.templateName.toLowerCase().contains(_searchQuery);
                        final resultMatch = item.history.resultJson.toLowerCase().contains(_searchQuery);
                        return templateMatch || resultMatch;
                      }).toList();

                if (histories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildGlassCard(
                        child: const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                '一致する履歴がありません',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade().slideY(begin: 0.1, end: 0),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100, top: 8, left: 16, right: 16),
                  itemCount: histories.length,
                  itemBuilder: (context, index) {
                    final item = histories[index];
                    final history = item.history;
                    final imageFile = File(history.imagePath);
                    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(history.scannedAt);
                    
                    final isSelected = _selectedIds.contains(history.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildGlassCard(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onLongPress: () {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedIds.add(history.id);
                            });
                            HapticFeedback.lightImpact(); 
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(history.id);
                                  if (_selectedIds.isEmpty) _isSelectionMode = false;
                                } else {
                                  _selectedIds.add(history.id);
                                }
                              });
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScanResultPage(historyId: history.id),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF667EEA).withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                if (_isSelectionMode) ...[
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedIds.add(history.id);
                                        } else {
                                          _selectedIds.remove(history.id);
                                          if (_selectedIds.isEmpty) _isSelectionMode = false;
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF667EEA),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? const Color(0xFF667EEA) : Colors.white, width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageFile.existsSync()
                                        ? Image.file(imageFile, fit: BoxFit.cover)
                                        : const Icon(Icons.image_not_supported, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.templateName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 14, color: Color(0xFF475569)),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                if (!_isSelectionMode)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (history.isExported)
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, color: Colors.green, size: 16),
                                        ),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            _deleteSingleHistory(history);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 20),
                                                SizedBox(width: 8),
                                                Text('削除', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fade(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}