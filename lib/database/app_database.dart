// lib/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// --- テーブル定義 ---

/// 抽出テンプレートテーブル
/// ユーザーが定義した「読み取りたい項目」や「プロンプト」を保存します
class ExtractionTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // テンプレート名（例: "領収書", "日報", "現場点検シート"）
  TextColumn get name => text()();
  
  // 抽出したい項目リストをJSON形式で保存 (例: ["日付", "合計金額", "店名"])
  TextColumn get targetFieldsJson => text()();
  
  // Geminiへの追加指示（任意）
  TextColumn get customInstruction => text().nullable()();
  
  // 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// スキャン履歴テーブル
/// 撮影した画像と、AIが抽出した結果を保存します
class ScanHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // どのテンプレートを使ってスキャンしたか
  IntColumn get templateId => integer().references(ExtractionTemplates, #id, onDelete: KeyAction.cascade)();
  
  // 保存された画像のパス
  TextColumn get imagePath => text()();
  
  // AI抽出結果をJSON形式で保存 (例: {"日付": "2024/01/01", "金額": "1000"})
  TextColumn get resultJson => text()();
  
  // CSV/Excelエクスポート済みかどうか
  BoolColumn get isExported => boolean().withDefault(const Constant(false))();
  
  // スキャン日時
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}

// --- データベースクラス ---

@DriftDatabase(tables: [ExtractionTemplates, ScanHistories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // アプリ名に合わせてDBファイル名も変更
    final file = File(p.join(dbFolder.path, 'ai_scan_db.sqlite'));
    return NativeDatabase(file);
  });
}