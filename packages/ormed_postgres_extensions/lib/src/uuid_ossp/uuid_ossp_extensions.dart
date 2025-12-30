import 'package:ormed/ormed.dart';

/// Extension keys for uuid-ossp handlers.
abstract class UuidOsspExtensionKeys {
  static const String v4 = 'uuid_ossp_v4';
  static const String v1 = 'uuid_ossp_v1';
}

/// Driver extension bundle that registers uuid-ossp handlers.
class UuidOsspExtensions extends DriverExtension {
  const UuidOsspExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.select,
          key: UuidOsspExtensionKeys.v4,
          compile: _compileV4,
        ),
        DriverExtensionHandler(
          kind: DriverExtensionKind.select,
          key: UuidOsspExtensionKeys.v1,
          compile: _compileV1,
        ),
      ];
}

DriverExtensionFragment _compileV4(
  DriverExtensionContext context,
  Object? payload,
) {
  return DriverExtensionFragment(sql: 'uuid_generate_v4()');
}

DriverExtensionFragment _compileV1(
  DriverExtensionContext context,
  Object? payload,
) {
  return DriverExtensionFragment(sql: 'uuid_generate_v1()');
}

/// Convenience query helpers for uuid-ossp extensions.
extension UuidOsspQueryExtensions<T extends OrmEntity> on Query<T> {
  Query<T> selectUuidOsspV4({String? alias}) => selectExtension(
        UuidOsspExtensionKeys.v4,
        alias: alias,
      );

  Query<T> selectUuidOsspV1({String? alias}) => selectExtension(
        UuidOsspExtensionKeys.v1,
        alias: alias,
      );
}
