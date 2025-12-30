import 'package:meta/meta.dart';
import 'package:ormed/ormed.dart';

/// Extension keys for pgcrypto handlers.
abstract class PgcryptoExtensionKeys {
  static const String digest = 'pgcrypto_digest';
  static const String genRandomUuid = 'pgcrypto_gen_random_uuid';
}

/// Payload for digest selection.
@immutable
class PgcryptoDigestPayload {
  const PgcryptoDigestPayload({required this.value, required this.algorithm});

  final String value;
  final String algorithm;
}

/// Driver extension bundle that registers pgcrypto handlers.
class PgcryptoExtensions extends DriverExtension {
  const PgcryptoExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.select,
          key: PgcryptoExtensionKeys.digest,
          compile: _compileDigest,
        ),
        DriverExtensionHandler(
          kind: DriverExtensionKind.select,
          key: PgcryptoExtensionKeys.genRandomUuid,
          compile: _compileGenRandomUuid,
        ),
      ];
}

DriverExtensionFragment _compileDigest(
  DriverExtensionContext context,
  Object? payload,
) {
  if (payload is! PgcryptoDigestPayload) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Expected PgcryptoDigestPayload for ${PgcryptoExtensionKeys.digest}.',
    );
  }

  final placeholder = context.grammar.parameterPlaceholder();

  return DriverExtensionFragment(
    sql: "encode(digest($placeholder, $placeholder), 'hex')",
    bindings: [payload.value, payload.algorithm],
  );
}

DriverExtensionFragment _compileGenRandomUuid(
  DriverExtensionContext context,
  Object? payload,
) {
  return DriverExtensionFragment(sql: 'gen_random_uuid()');
}

/// Convenience query helpers for pgcrypto extensions.
extension PgcryptoQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> selectPgcryptoDigest(
    PgcryptoDigestPayload payload, {
    String? alias,
  }) =>
      selectExtension(
        PgcryptoExtensionKeys.digest,
        payload: payload,
        alias: alias,
      );

  Query<T> selectPgcryptoGenRandomUuid({String? alias}) => selectExtension(
        PgcryptoExtensionKeys.genRandomUuid,
        alias: alias,
      );
}
