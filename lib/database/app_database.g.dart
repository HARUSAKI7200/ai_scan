// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExtractionTemplatesTable extends ExtractionTemplates
    with TableInfo<$ExtractionTemplatesTable, ExtractionTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtractionTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetFieldsJsonMeta =
      const VerificationMeta('targetFieldsJson');
  @override
  late final GeneratedColumn<String> targetFieldsJson = GeneratedColumn<String>(
      'target_fields_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customInstructionMeta =
      const VerificationMeta('customInstruction');
  @override
  late final GeneratedColumn<String> customInstruction =
      GeneratedColumn<String>('custom_instruction', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, targetFieldsJson, customInstruction, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extraction_templates';
  @override
  VerificationContext validateIntegrity(Insertable<ExtractionTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_fields_json')) {
      context.handle(
          _targetFieldsJsonMeta,
          targetFieldsJson.isAcceptableOrUnknown(
              data['target_fields_json']!, _targetFieldsJsonMeta));
    } else if (isInserting) {
      context.missing(_targetFieldsJsonMeta);
    }
    if (data.containsKey('custom_instruction')) {
      context.handle(
          _customInstructionMeta,
          customInstruction.isAcceptableOrUnknown(
              data['custom_instruction']!, _customInstructionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtractionTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtractionTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      targetFieldsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_fields_json'])!,
      customInstruction: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_instruction']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExtractionTemplatesTable createAlias(String alias) {
    return $ExtractionTemplatesTable(attachedDatabase, alias);
  }
}

class ExtractionTemplate extends DataClass
    implements Insertable<ExtractionTemplate> {
  final int id;
  final String name;
  final String targetFieldsJson;
  final String? customInstruction;
  final DateTime createdAt;
  const ExtractionTemplate(
      {required this.id,
      required this.name,
      required this.targetFieldsJson,
      this.customInstruction,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['target_fields_json'] = Variable<String>(targetFieldsJson);
    if (!nullToAbsent || customInstruction != null) {
      map['custom_instruction'] = Variable<String>(customInstruction);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExtractionTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ExtractionTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      targetFieldsJson: Value(targetFieldsJson),
      customInstruction: customInstruction == null && nullToAbsent
          ? const Value.absent()
          : Value(customInstruction),
      createdAt: Value(createdAt),
    );
  }

  factory ExtractionTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtractionTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetFieldsJson: serializer.fromJson<String>(json['targetFieldsJson']),
      customInstruction:
          serializer.fromJson<String?>(json['customInstruction']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'targetFieldsJson': serializer.toJson<String>(targetFieldsJson),
      'customInstruction': serializer.toJson<String?>(customInstruction),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExtractionTemplate copyWith(
          {int? id,
          String? name,
          String? targetFieldsJson,
          Value<String?> customInstruction = const Value.absent(),
          DateTime? createdAt}) =>
      ExtractionTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        targetFieldsJson: targetFieldsJson ?? this.targetFieldsJson,
        customInstruction: customInstruction.present
            ? customInstruction.value
            : this.customInstruction,
        createdAt: createdAt ?? this.createdAt,
      );
  ExtractionTemplate copyWithCompanion(ExtractionTemplatesCompanion data) {
    return ExtractionTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetFieldsJson: data.targetFieldsJson.present
          ? data.targetFieldsJson.value
          : this.targetFieldsJson,
      customInstruction: data.customInstruction.present
          ? data.customInstruction.value
          : this.customInstruction,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtractionTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetFieldsJson: $targetFieldsJson, ')
          ..write('customInstruction: $customInstruction, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, targetFieldsJson, customInstruction, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtractionTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetFieldsJson == this.targetFieldsJson &&
          other.customInstruction == this.customInstruction &&
          other.createdAt == this.createdAt);
}

class ExtractionTemplatesCompanion extends UpdateCompanion<ExtractionTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> targetFieldsJson;
  final Value<String?> customInstruction;
  final Value<DateTime> createdAt;
  const ExtractionTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetFieldsJson = const Value.absent(),
    this.customInstruction = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExtractionTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String targetFieldsJson,
    this.customInstruction = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        targetFieldsJson = Value(targetFieldsJson);
  static Insertable<ExtractionTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? targetFieldsJson,
    Expression<String>? customInstruction,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetFieldsJson != null) 'target_fields_json': targetFieldsJson,
      if (customInstruction != null) 'custom_instruction': customInstruction,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExtractionTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? targetFieldsJson,
      Value<String?>? customInstruction,
      Value<DateTime>? createdAt}) {
    return ExtractionTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetFieldsJson: targetFieldsJson ?? this.targetFieldsJson,
      customInstruction: customInstruction ?? this.customInstruction,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetFieldsJson.present) {
      map['target_fields_json'] = Variable<String>(targetFieldsJson.value);
    }
    if (customInstruction.present) {
      map['custom_instruction'] = Variable<String>(customInstruction.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtractionTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetFieldsJson: $targetFieldsJson, ')
          ..write('customInstruction: $customInstruction, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ScanHistoriesTable extends ScanHistories
    with TableInfo<$ScanHistoriesTable, ScanHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
      'template_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES extraction_templates (id) ON DELETE CASCADE'));
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resultJsonMeta =
      const VerificationMeta('resultJson');
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
      'result_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isExportedMeta =
      const VerificationMeta('isExported');
  @override
  late final GeneratedColumn<bool> isExported = GeneratedColumn<bool>(
      'is_exported', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_exported" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _scannedAtMeta =
      const VerificationMeta('scannedAt');
  @override
  late final GeneratedColumn<DateTime> scannedAt = GeneratedColumn<DateTime>(
      'scanned_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, templateId, imagePath, resultJson, isExported, scannedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_histories';
  @override
  VerificationContext validateIntegrity(Insertable<ScanHistory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('result_json')) {
      context.handle(
          _resultJsonMeta,
          resultJson.isAcceptableOrUnknown(
              data['result_json']!, _resultJsonMeta));
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    if (data.containsKey('is_exported')) {
      context.handle(
          _isExportedMeta,
          isExported.isAcceptableOrUnknown(
              data['is_exported']!, _isExportedMeta));
    }
    if (data.containsKey('scanned_at')) {
      context.handle(_scannedAtMeta,
          scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanHistory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}template_id'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      resultJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result_json'])!,
      isExported: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_exported'])!,
      scannedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}scanned_at'])!,
    );
  }

  @override
  $ScanHistoriesTable createAlias(String alias) {
    return $ScanHistoriesTable(attachedDatabase, alias);
  }
}

class ScanHistory extends DataClass implements Insertable<ScanHistory> {
  final int id;
  final int templateId;
  final String imagePath;
  final String resultJson;
  final bool isExported;
  final DateTime scannedAt;
  const ScanHistory(
      {required this.id,
      required this.templateId,
      required this.imagePath,
      required this.resultJson,
      required this.isExported,
      required this.scannedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['image_path'] = Variable<String>(imagePath);
    map['result_json'] = Variable<String>(resultJson);
    map['is_exported'] = Variable<bool>(isExported);
    map['scanned_at'] = Variable<DateTime>(scannedAt);
    return map;
  }

  ScanHistoriesCompanion toCompanion(bool nullToAbsent) {
    return ScanHistoriesCompanion(
      id: Value(id),
      templateId: Value(templateId),
      imagePath: Value(imagePath),
      resultJson: Value(resultJson),
      isExported: Value(isExported),
      scannedAt: Value(scannedAt),
    );
  }

  factory ScanHistory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanHistory(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
      isExported: serializer.fromJson<bool>(json['isExported']),
      scannedAt: serializer.fromJson<DateTime>(json['scannedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'imagePath': serializer.toJson<String>(imagePath),
      'resultJson': serializer.toJson<String>(resultJson),
      'isExported': serializer.toJson<bool>(isExported),
      'scannedAt': serializer.toJson<DateTime>(scannedAt),
    };
  }

  ScanHistory copyWith(
          {int? id,
          int? templateId,
          String? imagePath,
          String? resultJson,
          bool? isExported,
          DateTime? scannedAt}) =>
      ScanHistory(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        imagePath: imagePath ?? this.imagePath,
        resultJson: resultJson ?? this.resultJson,
        isExported: isExported ?? this.isExported,
        scannedAt: scannedAt ?? this.scannedAt,
      );
  ScanHistory copyWithCompanion(ScanHistoriesCompanion data) {
    return ScanHistory(
      id: data.id.present ? data.id.value : this.id,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      resultJson:
          data.resultJson.present ? data.resultJson.value : this.resultJson,
      isExported:
          data.isExported.present ? data.isExported.value : this.isExported,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanHistory(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('imagePath: $imagePath, ')
          ..write('resultJson: $resultJson, ')
          ..write('isExported: $isExported, ')
          ..write('scannedAt: $scannedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateId, imagePath, resultJson, isExported, scannedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanHistory &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.imagePath == this.imagePath &&
          other.resultJson == this.resultJson &&
          other.isExported == this.isExported &&
          other.scannedAt == this.scannedAt);
}

class ScanHistoriesCompanion extends UpdateCompanion<ScanHistory> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<String> imagePath;
  final Value<String> resultJson;
  final Value<bool> isExported;
  final Value<DateTime> scannedAt;
  const ScanHistoriesCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.isExported = const Value.absent(),
    this.scannedAt = const Value.absent(),
  });
  ScanHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required String imagePath,
    required String resultJson,
    this.isExported = const Value.absent(),
    this.scannedAt = const Value.absent(),
  })  : templateId = Value(templateId),
        imagePath = Value(imagePath),
        resultJson = Value(resultJson);
  static Insertable<ScanHistory> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<String>? imagePath,
    Expression<String>? resultJson,
    Expression<bool>? isExported,
    Expression<DateTime>? scannedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (imagePath != null) 'image_path': imagePath,
      if (resultJson != null) 'result_json': resultJson,
      if (isExported != null) 'is_exported': isExported,
      if (scannedAt != null) 'scanned_at': scannedAt,
    });
  }

  ScanHistoriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? templateId,
      Value<String>? imagePath,
      Value<String>? resultJson,
      Value<bool>? isExported,
      Value<DateTime>? scannedAt}) {
    return ScanHistoriesCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      imagePath: imagePath ?? this.imagePath,
      resultJson: resultJson ?? this.resultJson,
      isExported: isExported ?? this.isExported,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (isExported.present) {
      map['is_exported'] = Variable<bool>(isExported.value);
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<DateTime>(scannedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('imagePath: $imagePath, ')
          ..write('resultJson: $resultJson, ')
          ..write('isExported: $isExported, ')
          ..write('scannedAt: $scannedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExtractionTemplatesTable extractionTemplates =
      $ExtractionTemplatesTable(this);
  late final $ScanHistoriesTable scanHistories = $ScanHistoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [extractionTemplates, scanHistories];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('extraction_templates',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('scan_histories', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ExtractionTemplatesTableCreateCompanionBuilder
    = ExtractionTemplatesCompanion Function({
  Value<int> id,
  required String name,
  required String targetFieldsJson,
  Value<String?> customInstruction,
  Value<DateTime> createdAt,
});
typedef $$ExtractionTemplatesTableUpdateCompanionBuilder
    = ExtractionTemplatesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> targetFieldsJson,
  Value<String?> customInstruction,
  Value<DateTime> createdAt,
});

final class $$ExtractionTemplatesTableReferences extends BaseReferences<
    _$AppDatabase, $ExtractionTemplatesTable, ExtractionTemplate> {
  $$ExtractionTemplatesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScanHistoriesTable, List<ScanHistory>>
      _scanHistoriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.scanHistories,
              aliasName: $_aliasNameGenerator(
                  db.extractionTemplates.id, db.scanHistories.templateId));

  $$ScanHistoriesTableProcessedTableManager get scanHistoriesRefs {
    final manager = $$ScanHistoriesTableTableManager($_db, $_db.scanHistories)
        .filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanHistoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExtractionTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExtractionTemplatesTable> {
  $$ExtractionTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetFieldsJson => $composableBuilder(
      column: $table.targetFieldsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customInstruction => $composableBuilder(
      column: $table.customInstruction,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> scanHistoriesRefs(
      Expression<bool> Function($$ScanHistoriesTableFilterComposer f) f) {
    final $$ScanHistoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scanHistories,
        getReferencedColumn: (t) => t.templateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScanHistoriesTableFilterComposer(
              $db: $db,
              $table: $db.scanHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExtractionTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtractionTemplatesTable> {
  $$ExtractionTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetFieldsJson => $composableBuilder(
      column: $table.targetFieldsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customInstruction => $composableBuilder(
      column: $table.customInstruction,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExtractionTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtractionTemplatesTable> {
  $$ExtractionTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get targetFieldsJson => $composableBuilder(
      column: $table.targetFieldsJson, builder: (column) => column);

  GeneratedColumn<String> get customInstruction => $composableBuilder(
      column: $table.customInstruction, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> scanHistoriesRefs<T extends Object>(
      Expression<T> Function($$ScanHistoriesTableAnnotationComposer a) f) {
    final $$ScanHistoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scanHistories,
        getReferencedColumn: (t) => t.templateId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScanHistoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.scanHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExtractionTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExtractionTemplatesTable,
    ExtractionTemplate,
    $$ExtractionTemplatesTableFilterComposer,
    $$ExtractionTemplatesTableOrderingComposer,
    $$ExtractionTemplatesTableAnnotationComposer,
    $$ExtractionTemplatesTableCreateCompanionBuilder,
    $$ExtractionTemplatesTableUpdateCompanionBuilder,
    (ExtractionTemplate, $$ExtractionTemplatesTableReferences),
    ExtractionTemplate,
    PrefetchHooks Function({bool scanHistoriesRefs})> {
  $$ExtractionTemplatesTableTableManager(
      _$AppDatabase db, $ExtractionTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtractionTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtractionTemplatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtractionTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> targetFieldsJson = const Value.absent(),
            Value<String?> customInstruction = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExtractionTemplatesCompanion(
            id: id,
            name: name,
            targetFieldsJson: targetFieldsJson,
            customInstruction: customInstruction,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String targetFieldsJson,
            Value<String?> customInstruction = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExtractionTemplatesCompanion.insert(
            id: id,
            name: name,
            targetFieldsJson: targetFieldsJson,
            customInstruction: customInstruction,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExtractionTemplatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({scanHistoriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (scanHistoriesRefs) db.scanHistories
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scanHistoriesRefs)
                    await $_getPrefetchedData<ExtractionTemplate,
                            $ExtractionTemplatesTable, ScanHistory>(
                        currentTable: table,
                        referencedTable: $$ExtractionTemplatesTableReferences
                            ._scanHistoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExtractionTemplatesTableReferences(db, table, p0)
                                .scanHistoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.templateId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExtractionTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExtractionTemplatesTable,
    ExtractionTemplate,
    $$ExtractionTemplatesTableFilterComposer,
    $$ExtractionTemplatesTableOrderingComposer,
    $$ExtractionTemplatesTableAnnotationComposer,
    $$ExtractionTemplatesTableCreateCompanionBuilder,
    $$ExtractionTemplatesTableUpdateCompanionBuilder,
    (ExtractionTemplate, $$ExtractionTemplatesTableReferences),
    ExtractionTemplate,
    PrefetchHooks Function({bool scanHistoriesRefs})>;
typedef $$ScanHistoriesTableCreateCompanionBuilder = ScanHistoriesCompanion
    Function({
  Value<int> id,
  required int templateId,
  required String imagePath,
  required String resultJson,
  Value<bool> isExported,
  Value<DateTime> scannedAt,
});
typedef $$ScanHistoriesTableUpdateCompanionBuilder = ScanHistoriesCompanion
    Function({
  Value<int> id,
  Value<int> templateId,
  Value<String> imagePath,
  Value<String> resultJson,
  Value<bool> isExported,
  Value<DateTime> scannedAt,
});

final class $$ScanHistoriesTableReferences
    extends BaseReferences<_$AppDatabase, $ScanHistoriesTable, ScanHistory> {
  $$ScanHistoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ExtractionTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.extractionTemplates.createAlias($_aliasNameGenerator(
          db.scanHistories.templateId, db.extractionTemplates.id));

  $$ExtractionTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager =
        $$ExtractionTemplatesTableTableManager($_db, $_db.extractionTemplates)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ScanHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ScanHistoriesTable> {
  $$ScanHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resultJson => $composableBuilder(
      column: $table.resultJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isExported => $composableBuilder(
      column: $table.isExported, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scannedAt => $composableBuilder(
      column: $table.scannedAt, builder: (column) => ColumnFilters(column));

  $$ExtractionTemplatesTableFilterComposer get templateId {
    final $$ExtractionTemplatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.templateId,
        referencedTable: $db.extractionTemplates,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExtractionTemplatesTableFilterComposer(
              $db: $db,
              $table: $db.extractionTemplates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScanHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanHistoriesTable> {
  $$ScanHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resultJson => $composableBuilder(
      column: $table.resultJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isExported => $composableBuilder(
      column: $table.isExported, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scannedAt => $composableBuilder(
      column: $table.scannedAt, builder: (column) => ColumnOrderings(column));

  $$ExtractionTemplatesTableOrderingComposer get templateId {
    final $$ExtractionTemplatesTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.templateId,
            referencedTable: $db.extractionTemplates,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ExtractionTemplatesTableOrderingComposer(
                  $db: $db,
                  $table: $db.extractionTemplates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$ScanHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanHistoriesTable> {
  $$ScanHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get resultJson => $composableBuilder(
      column: $table.resultJson, builder: (column) => column);

  GeneratedColumn<bool> get isExported => $composableBuilder(
      column: $table.isExported, builder: (column) => column);

  GeneratedColumn<DateTime> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  $$ExtractionTemplatesTableAnnotationComposer get templateId {
    final $$ExtractionTemplatesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.templateId,
            referencedTable: $db.extractionTemplates,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ExtractionTemplatesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.extractionTemplates,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$ScanHistoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScanHistoriesTable,
    ScanHistory,
    $$ScanHistoriesTableFilterComposer,
    $$ScanHistoriesTableOrderingComposer,
    $$ScanHistoriesTableAnnotationComposer,
    $$ScanHistoriesTableCreateCompanionBuilder,
    $$ScanHistoriesTableUpdateCompanionBuilder,
    (ScanHistory, $$ScanHistoriesTableReferences),
    ScanHistory,
    PrefetchHooks Function({bool templateId})> {
  $$ScanHistoriesTableTableManager(_$AppDatabase db, $ScanHistoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> templateId = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<String> resultJson = const Value.absent(),
            Value<bool> isExported = const Value.absent(),
            Value<DateTime> scannedAt = const Value.absent(),
          }) =>
              ScanHistoriesCompanion(
            id: id,
            templateId: templateId,
            imagePath: imagePath,
            resultJson: resultJson,
            isExported: isExported,
            scannedAt: scannedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int templateId,
            required String imagePath,
            required String resultJson,
            Value<bool> isExported = const Value.absent(),
            Value<DateTime> scannedAt = const Value.absent(),
          }) =>
              ScanHistoriesCompanion.insert(
            id: id,
            templateId: templateId,
            imagePath: imagePath,
            resultJson: resultJson,
            isExported: isExported,
            scannedAt: scannedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ScanHistoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (templateId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.templateId,
                    referencedTable:
                        $$ScanHistoriesTableReferences._templateIdTable(db),
                    referencedColumn:
                        $$ScanHistoriesTableReferences._templateIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ScanHistoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScanHistoriesTable,
    ScanHistory,
    $$ScanHistoriesTableFilterComposer,
    $$ScanHistoriesTableOrderingComposer,
    $$ScanHistoriesTableAnnotationComposer,
    $$ScanHistoriesTableCreateCompanionBuilder,
    $$ScanHistoriesTableUpdateCompanionBuilder,
    (ScanHistory, $$ScanHistoriesTableReferences),
    ScanHistory,
    PrefetchHooks Function({bool templateId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExtractionTemplatesTableTableManager get extractionTemplates =>
      $$ExtractionTemplatesTableTableManager(_db, _db.extractionTemplates);
  $$ScanHistoriesTableTableManager get scanHistories =>
      $$ScanHistoriesTableTableManager(_db, _db.scanHistories);
}
