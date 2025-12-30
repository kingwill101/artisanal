import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

import '../shared/extension_helpers.dart';

/// Extension keys for ltree handlers.
abstract class LtreeExtensionKeys {
  static const String contains = 'ltree_contains';
  static const String matches = 'ltree_matches';
}

/// Payload for ltree containment checks.
@immutable
class LtreeContainsPayload {
  const LtreeContainsPayload({required this.column, required this.path});

  final String column;
  final String path;
}

/// Payload for ltree lquery matching.
@immutable
class LtreeMatchesPayload {
  const LtreeMatchesPayload({required this.column, required this.query});

  final String column;
  final String query;
}

/// Driver extension bundle that registers ltree handlers.
class LtreeExtensions extends DriverExtension {
  const LtreeExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: LtreeExtensionKeys.contains,
      compile: _compileContains,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: LtreeExtensionKeys.matches,
      compile: _compileMatches,
    ),
  ];
}

DriverExtensionFragment _compileContains(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! LtreeContainsPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected LtreeContainsPayload for ${LtreeExtensionKeys.contains}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: '$column <@ $placeholder::ltree',
    bindings: [payload.path],
  );
}

DriverExtensionFragment _compileMatches(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! LtreeMatchesPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected LtreeMatchesPayload for ${LtreeExtensionKeys.matches}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: '$column ~ $placeholder::lquery',
    bindings: [payload.query],
  );
}

/// Convenience query helpers for ltree extensions.
extension LtreeQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> whereLtreeContains(LtreeContainsPayload payload) =>
      whereExtension(LtreeExtensionKeys.contains, payload);

  Query<T> orWhereLtreeContains(LtreeContainsPayload payload) =>
      orWhereExtension(LtreeExtensionKeys.contains, payload);

  Query<T> whereLtreeMatches(LtreeMatchesPayload payload) =>
      whereExtension(LtreeExtensionKeys.matches, payload);

  Query<T> orWhereLtreeMatches(LtreeMatchesPayload payload) =>
      orWhereExtension(LtreeExtensionKeys.matches, payload);
}
