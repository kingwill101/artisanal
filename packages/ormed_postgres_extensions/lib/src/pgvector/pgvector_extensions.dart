import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

/// Extension keys for pgvector handlers.
abstract class PgvectorExtensionKeys {
  static const String distance = 'pgvector_distance';
  static const String within = 'pgvector_within';
}

/// Supported pgvector distance metrics.
enum PgvectorDistanceMetric { l2, cosine, innerProduct }

/// Payload for ordering by vector distance.
@immutable
class PgvectorDistancePayload {
  const PgvectorDistancePayload({
    required this.column,
    required this.vector,
    this.metric = PgvectorDistanceMetric.l2,
  });

  final String column;
  final List<num> vector;
  final PgvectorDistanceMetric metric;
}

/// Payload for filtering by vector distance.
@immutable
class PgvectorWithinPayload {
  const PgvectorWithinPayload({
    required this.column,
    required this.vector,
    required this.maxDistance,
    this.metric = PgvectorDistanceMetric.l2,
  });

  final String column;
  final List<num> vector;
  final double maxDistance;
  final PgvectorDistanceMetric metric;
}

/// Driver extension bundle that registers pgvector handlers.
class PgvectorExtensions extends DriverExtension {
  const PgvectorExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.orderBy,
          key: PgvectorExtensionKeys.distance,
          compile: _compileDistance,
        ),
        DriverExtensionHandler(
          kind: DriverExtensionKind.where,
          key: PgvectorExtensionKeys.within,
          compile: _compileWithin,
        ),
      ];
}

DriverExtensionFragment _compileDistance(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PgvectorDistancePayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PgvectorDistancePayload for ${PgvectorExtensionKeys.distance}.',
    );
  }

  final column = _qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();
  final operator = _metricOperator(payload.metric);

  final sql = '($column $operator $placeholder::vector)';

  return DriverExtensionFragment(
    sql: sql,
    bindings: [_vectorLiteral(payload.vector)],
  );
}

DriverExtensionFragment _compileWithin(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PgvectorWithinPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PgvectorWithinPayload for ${PgvectorExtensionKeys.within}.',
    );
  }

  final column = _qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();
  final operator = _metricOperator(payload.metric);

  final sql = '($column $operator $placeholder::vector) <= $placeholder';

  return DriverExtensionFragment(
    sql: sql,
    bindings: [_vectorLiteral(payload.vector), payload.maxDistance],
  );
}

String _metricOperator(PgvectorDistanceMetric metric) {
  switch (metric) {
    case PgvectorDistanceMetric.l2:
      return '<->';
    case PgvectorDistanceMetric.cosine:
      return '<=>';
    case PgvectorDistanceMetric.innerProduct:
      return '<#>';
  }
}

String _vectorLiteral(List<num> vector) {
  final values = vector.map((value) => value.toString()).join(',');
  return '[$values]';
}

String _qualifiedColumn(DriverExtensionContext context, String column) {
  if (column.contains('.')) {
    return column
        .split('.')
        .map(context.grammar.wrapIdentifier)
        .join('.');
  }
  return '${context.tableIdentifier}.${context.grammar.wrapIdentifier(column)}';
}

/// Convenience query helpers for pgvector extensions.
extension PgvectorQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> wherePgvectorWithin(PgvectorWithinPayload payload) =>
      whereExtension(PgvectorExtensionKeys.within, payload);

  Query<T> orWherePgvectorWithin(PgvectorWithinPayload payload) =>
      orWhereExtension(PgvectorExtensionKeys.within, payload);

  Query<T> orderByPgvectorDistance(
    PgvectorDistancePayload payload, {
    bool descending = false,
  }) =>
      orderByExtension(
        PgvectorExtensionKeys.distance,
        payload: payload,
        descending: descending,
      );
}
