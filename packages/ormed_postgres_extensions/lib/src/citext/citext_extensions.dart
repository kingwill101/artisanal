import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

import '../shared/extension_helpers.dart';

/// Extension keys for citext handlers.
abstract class CitextExtensionKeys {
  static const String equals = 'citext_equals';
}

/// Payload for citext equality checks.
@immutable
class CitextEqualsPayload {
  const CitextEqualsPayload({required this.column, required this.value});

  final String column;
  final String value;
}

/// Driver extension bundle that registers citext handlers.
class CitextExtensions extends DriverExtension {
  const CitextExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.where,
          key: CitextExtensionKeys.equals,
          compile: _compileEquals,
        ),
      ];
}

DriverExtensionFragment _compileEquals(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! CitextEqualsPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected CitextEqualsPayload for ${CitextExtensionKeys.equals}.',
    );
  }

  final column = qualifiedColumn(context, payload.column);
  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: '$column = $placeholder::citext',
    bindings: [payload.value],
  );
}

/// Convenience query helpers for citext extensions.
extension CitextQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> whereCitextEquals(CitextEqualsPayload payload) =>
      whereExtension(CitextExtensionKeys.equals, payload);

  Query<T> orWhereCitextEquals(CitextEqualsPayload payload) =>
      orWhereExtension(CitextExtensionKeys.equals, payload);
}
