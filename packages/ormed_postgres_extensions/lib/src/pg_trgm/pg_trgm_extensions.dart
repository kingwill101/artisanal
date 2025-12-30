import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

import '../shared/extension_helpers.dart';

/// Extension keys for pg_trgm handlers.
abstract class PgTrgmExtensionKeys {
  static const String similarity = 'pg_trgm_similarity';
  static const String similarityOrder = 'pg_trgm_similarity_order';
}

/// Payload for similarity filtering.
@immutable
class PgTrgmSimilarityPayload {
  const PgTrgmSimilarityPayload({
    required this.column,
    required this.value,
    this.threshold,
  });

  final String column;
  final String value;
  final double? threshold;
}

/// Payload for similarity ordering.
@immutable
class PgTrgmOrderPayload {
  const PgTrgmOrderPayload({
    required this.column,
    required this.value,
  });

  final String column;
  final String value;
}

/// Driver extension bundle that registers pg_trgm handlers.
class PgTrgmExtensions extends DriverExtension {
  const PgTrgmExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.where,
          key: PgTrgmExtensionKeys.similarity,
          compile: _compileSimilarity,
        ),
        DriverExtensionHandler(
          kind: DriverExtensionKind.orderBy,
          key: PgTrgmExtensionKeys.similarityOrder,
          compile: _compileSimilarityOrder,
        ),
      ];
}

DriverExtensionFragment _compileSimilarity(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PgTrgmSimilarityPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PgTrgmSimilarityPayload for ${PgTrgmExtensionKeys.similarity}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  if (payload.threshold != null) {
    return DriverExtensionFragment(
      sql: 'similarity($column, $placeholder) >= $placeholder',
      bindings: [payload.value, payload.threshold],
    );
  }

  return DriverExtensionFragment(
    sql: '$column % $placeholder',
    bindings: [payload.value],
  );
}

DriverExtensionFragment _compileSimilarityOrder(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PgTrgmOrderPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PgTrgmOrderPayload for ${PgTrgmExtensionKeys.similarityOrder}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: 'similarity($column, $placeholder)',
    bindings: [payload.value],
  );
}

/// Convenience query helpers for pg_trgm extensions.
extension PgTrgmQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> wherePgTrgmSimilarity(PgTrgmSimilarityPayload payload) =>
      whereExtension(PgTrgmExtensionKeys.similarity, payload);

  Query<T> orWherePgTrgmSimilarity(PgTrgmSimilarityPayload payload) =>
      orWhereExtension(PgTrgmExtensionKeys.similarity, payload);

  Query<T> orderByPgTrgmSimilarity(
    PgTrgmOrderPayload payload, {
    bool descending = true,
  }) =>
      orderByExtension(
        PgTrgmExtensionKeys.similarityOrder,
        payload: payload,
        descending: descending,
      );
}
