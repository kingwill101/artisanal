import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:hashlib/hashlib.dart';
import 'package:ormed/src/blueprint/table_blueprint.dart';

/// High-level operations supported by the schema planner.
enum SchemaMutationOperation {
  createTable,
  alterTable,
  dropTable,
  renameTable,
  createCollection,
  dropCollection,
  createIndex,
  dropIndex,
  modifyValidator,
  rawSql,
  createDatabase,
  dropDatabase,
}

/// A mutation emitted by the schema builder.
class SchemaMutation {
  SchemaMutation._({
    required this.operation,
    this.blueprint,
    this.dropOptions,
    this.rename,
    this.sql,
    this.parameters = const [],
    this.documentPayload,
  }) : table = blueprint?.table ?? dropOptions?.table ?? rename?.from;

  factory SchemaMutation.createTable(TableBlueprint blueprint) =>
      SchemaMutation._(
        operation: SchemaMutationOperation.createTable,
        blueprint: blueprint,
      );

  factory SchemaMutation.createDatabase({
    required String name,
    Map<String, Object?>? options,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.createDatabase,
    documentPayload: {'name': name, if (options != null) 'options': options},
  );

  factory SchemaMutation.dropDatabase({
    required String name,
    bool ifExists = false,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.dropDatabase,
    documentPayload: {'name': name, 'ifExists': ifExists},
  );

  factory SchemaMutation.createCollection({
    required String collection,
    Map<String, Object?>? validator,
    Map<String, Object?>? options,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.createCollection,
    documentPayload: {
      'collection': collection,
      if (validator != null) 'validator': validator,
      if (options != null) 'options': options,
    },
  );

  factory SchemaMutation.dropCollection({required String collection}) =>
      SchemaMutation._(
        operation: SchemaMutationOperation.dropCollection,
        documentPayload: {'collection': collection},
      );

  factory SchemaMutation.createIndex({
    required String collection,
    required Map<String, Object?> keys,
    Map<String, Object?>? options,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.createIndex,
    documentPayload: {
      'collection': collection,
      'keys': keys,
      if (options != null) 'options': options,
    },
  );

  factory SchemaMutation.dropIndex({
    required String collection,
    required String name,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.dropIndex,
    documentPayload: {'collection': collection, 'name': name},
  );

  factory SchemaMutation.modifyValidator({
    required String collection,
    required Map<String, Object?> validator,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.modifyValidator,
    documentPayload: {'collection': collection, 'validator': validator},
  );

  factory SchemaMutation.alterTable(TableBlueprint blueprint) =>
      SchemaMutation._(
        operation: SchemaMutationOperation.alterTable,
        blueprint: blueprint,
      );

  factory SchemaMutation.dropTable({
    required String table,
    bool ifExists = false,
    bool cascade = false,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.dropTable,
    dropOptions: DropTableOptions(
      table: table,
      ifExists: ifExists,
      cascade: cascade,
    ),
  );

  factory SchemaMutation.renameTable({
    required String from,
    required String to,
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.renameTable,
    rename: RenameTableOptions(from: from, to: to),
  );

  factory SchemaMutation.rawSql(
    String sql, {
    List<Object?> parameters = const [],
  }) => SchemaMutation._(
    operation: SchemaMutationOperation.rawSql,
    sql: sql,
    parameters: parameters,
  );

  final SchemaMutationOperation operation;
  final TableBlueprint? blueprint;
  final DropTableOptions? dropOptions;
  final RenameTableOptions? rename;
  final String? sql;
  final List<Object?> parameters;
  final String? table;
  final Map<String, Object?>? documentPayload;

  Map<String, Object?> toJson() => {
    'operation': operation.name,
    if (table != null) 'table': table,
    if (blueprint != null) 'blueprint': blueprint!.toJson(),
    if (dropOptions != null) 'drop': dropOptions!.toJson(),
    if (rename != null) 'rename': rename!.toJson(),
    if (sql != null) 'sql': sql,
    if (parameters.isNotEmpty) 'parameters': parameters,
    if (documentPayload != null) 'payload': documentPayload,
  };

  factory SchemaMutation.fromJson(Map<String, Object?> json) {
    final operation = SchemaMutationOperation.values.byName(
      json['operation'] as String,
    );
    switch (operation) {
      case SchemaMutationOperation.createTable:
      case SchemaMutationOperation.alterTable:
        final blueprintJson = json['blueprint'] as Map<String, Object?>;
        final blueprint = TableBlueprint.fromJson(blueprintJson);
        return SchemaMutation._(operation: operation, blueprint: blueprint);
      case SchemaMutationOperation.dropTable:
        return SchemaMutation._(
          operation: operation,
          dropOptions: DropTableOptions.fromJson(
            json['drop'] as Map<String, Object?>,
          ),
        );
      case SchemaMutationOperation.renameTable:
        return SchemaMutation._(
          operation: operation,
          rename: RenameTableOptions.fromJson(
            json['rename'] as Map<String, Object?>,
          ),
        );
      case SchemaMutationOperation.rawSql:
        return SchemaMutation._(
          operation: operation,
          sql: json['sql'] as String,
          parameters: (json['parameters'] as List?)?.toList() ?? const [],
        );
      case SchemaMutationOperation.createCollection:
      case SchemaMutationOperation.dropCollection:
      case SchemaMutationOperation.createIndex:
      case SchemaMutationOperation.dropIndex:
      case SchemaMutationOperation.modifyValidator:
      case SchemaMutationOperation.createDatabase:
      case SchemaMutationOperation.dropDatabase:
        return SchemaMutation._(
          operation: operation,
          documentPayload:
              (json['payload'] as Map?)?.cast<String, Object?>() ?? const {},
        );
    }
  }
}

class DropTableOptions {
  const DropTableOptions({
    required this.table,
    this.ifExists = false,
    this.cascade = false,
  });

  final String table;
  final bool ifExists;
  final bool cascade;

  Map<String, Object?> toJson() => {
    'table': table,
    if (ifExists) 'ifExists': true,
    if (cascade) 'cascade': true,
  };

  factory DropTableOptions.fromJson(Map<String, Object?> json) =>
      DropTableOptions(
        table: json['table'] as String,
        ifExists: json['ifExists'] as bool? ?? false,
        cascade: json['cascade'] as bool? ?? false,
      );
}

class RenameTableOptions {
  const RenameTableOptions({required this.from, required this.to});

  final String from;
  final String to;

  Map<String, Object?> toJson() => {'from': from, 'to': to};

  factory RenameTableOptions.fromJson(Map<String, Object?> json) =>
      RenameTableOptions(
        from: json['from'] as String,
        to: json['to'] as String,
      );
}

/// Immutable collection of schema mutations.
class SchemaPlan {
  SchemaPlan({required List<SchemaMutation> mutations, this.description})
    : mutations = List.unmodifiable(mutations);

  final List<SchemaMutation> mutations;
  final String? description;

  Map<String, Object?> toJson() => {
    if (description != null) 'description': description,
    'mutations': mutations.map((mutation) => mutation.toJson()).toList(),
  };

  factory SchemaPlan.fromJson(Map<String, Object?> json) => SchemaPlan(
    description: json['description'] as String?,
    mutations: (json['mutations'] as List)
        .map((entry) => SchemaMutation.fromJson(entry as Map<String, Object?>))
        .toList(),
  );

  String checksum() => _sha1(jsonEncode(toJson()));

  @override
  bool operator ==(Object other) =>
      other is SchemaPlan &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

String _sha1(String input) => sha1.string(input).toString();
