part of 'query.dart';

typedef QueryHook = void Function(QueryPlan plan);
typedef MutationHook = void Function(MutationPlan plan);
typedef TransactionHook = FutureOr<void> Function();
typedef TransactionOutcomeHook = FutureOr<void> Function(
  TransactionOutcome outcome,
  TransactionScope scope,
);
typedef QueryLogHook = void Function(QueryLogEntry entry);
typedef ExecutingStatementCallback =
    void Function(ExecutingStatement statement);
typedef LongRunningQueryCallback = void Function(LongRunningQueryEvent event);

enum ExecutingStatementType { query, mutation }

enum TransactionOutcome { committed, rolledBack }

enum TransactionScope { root, savepoint }

class ExecutingStatement {
  ExecutingStatement({
    required this.type,
    required this.preview,
    this.queryPlan,
    this.mutationPlan,
    this.connectionName,
    this.connectionDatabase,
    this.connectionTablePrefix,
  });

  final ExecutingStatementType type;
  final StatementPreview preview;
  final QueryPlan? queryPlan;
  final MutationPlan? mutationPlan;
  final String? connectionName;
  final String? connectionDatabase;
  final String? connectionTablePrefix;

  String get sql => preview.sql;

  List<Object?> get parameters => preview.parameters;

  List<List<Object?>> get parameterSets => preview.parameterSets;

  String get sqlWithBindings => preview.sqlWithBindings;
}

class LongRunningQueryEvent {
  LongRunningQueryEvent({
    required this.statement,
    required this.duration,
    this.error,
  });

  final ExecutingStatement statement;
  final Duration duration;
  final Object? error;
}

/// Structured representation of a logged query or mutation.
class QueryLogEntry {
  QueryLogEntry({
    required this.type,
    required this.preview,
    required this.duration,
    required this.success,
    this.model,
    this.table,
    this.rowCount,
    this.error,
    this.includeParameters = true,
  });

  final String type;
  final StatementPreview preview;
  final Duration duration;
  final bool success;
  final String? model;
  final String? table;
  final int? rowCount;
  final Object? error;
  final bool includeParameters;

  QueryLogEntry withoutParameters() => QueryLogEntry(
    type: type,
    preview: preview,
    duration: duration,
    success: success,
    model: model,
    table: table,
    rowCount: rowCount,
    error: error,
    includeParameters: false,
  );

  List<Object?> get parameters =>
      includeParameters ? preview.parameters : const [];

  List<List<Object?>> get parameterSets =>
      includeParameters ? preview.parameterSets : const [];

  String get sql => preview.sqlWithBindings;

  Map<String, Object?> toMap() => {
    'type': type,
    'sql': sql,
    'statement_payload': preview.payload.toJson(),
    'duration_ms': duration.inMicroseconds / 1000,
    'success': success,
    if (model != null) 'model': model,
    if (table != null) 'table': table,
    if (parameters.isNotEmpty) 'parameters': parameters,
    if (parameterSets.isNotEmpty) 'parameter_sets': parameterSets,
    if (rowCount != null) 'row_count': rowCount,
    if (error != null) 'error': error.toString(),
  };
}
