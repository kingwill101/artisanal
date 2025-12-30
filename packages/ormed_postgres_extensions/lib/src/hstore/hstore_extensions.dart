import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

import '../shared/extension_helpers.dart';

/// Extension keys for hstore handlers.
abstract class HstoreExtensionKeys {
  static const String hasKey = 'hstore_has_key';
  static const String contains = 'hstore_contains';
  static const String get = 'hstore_get';
}

/// Payload for `column ? key`.
@immutable
class HstoreHasKeyPayload {
  const HstoreHasKeyPayload({required this.column, required this.key});

  final String column;
  final String key;
}

/// Payload for `column @> hstore`.
@immutable
class HstoreContainsPayload {
  const HstoreContainsPayload({required this.column, required this.entries});

  final String column;
  final Map<String, String?> entries;
}

/// Payload for selecting a key value from hstore.
@immutable
class HstoreGetPayload {
  const HstoreGetPayload({required this.column, required this.key});

  final String column;
  final String key;
}

/// Driver extension bundle that registers hstore handlers.
class HstoreExtensions extends DriverExtension {
  const HstoreExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: HstoreExtensionKeys.hasKey,
      compile: _compileHasKey,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: HstoreExtensionKeys.contains,
      compile: _compileContains,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.select,
      key: HstoreExtensionKeys.get,
      compile: _compileGet,
    ),
  ];
}

DriverExtensionFragment _compileHasKey(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! HstoreHasKeyPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected HstoreHasKeyPayload for ${HstoreExtensionKeys.hasKey}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: 'exist($column, $placeholder)',
    bindings: [payload.key],
  );
}

DriverExtensionFragment _compileContains(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! HstoreContainsPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected HstoreContainsPayload for ${HstoreExtensionKeys.contains}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: '$column @> $placeholder::hstore',
    bindings: [_hstoreLiteral(payload.entries)],
  );
}

DriverExtensionFragment _compileGet(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! HstoreGetPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected HstoreGetPayload for ${HstoreExtensionKeys.get}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: '$column -> $placeholder',
    bindings: [payload.key],
  );
}

String _hstoreLiteral(Map<String, String?> entries) {
  final pairs = entries.entries
      .map((entry) {
        final key = _escape(entry.key);
        final value = entry.value == null
            ? 'NULL'
            : '"${_escape(entry.value!)}"';
        return '"$key"=>$value';
      })
      .join(',');
  return pairs;
}

String _escape(String value) {
  return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

/// Convenience query helpers for hstore extensions.
extension HstoreQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> whereHstoreHasKey(HstoreHasKeyPayload payload) =>
      whereExtension(HstoreExtensionKeys.hasKey, payload);

  Query<T> orWhereHstoreHasKey(HstoreHasKeyPayload payload) =>
      orWhereExtension(HstoreExtensionKeys.hasKey, payload);

  Query<T> whereHstoreContains(HstoreContainsPayload payload) =>
      whereExtension(HstoreExtensionKeys.contains, payload);

  Query<T> orWhereHstoreContains(HstoreContainsPayload payload) =>
      orWhereExtension(HstoreExtensionKeys.contains, payload);

  Query<T> selectHstoreGet(HstoreGetPayload payload, {String? alias}) =>
      selectExtension(HstoreExtensionKeys.get, payload: payload, alias: alias);
}
