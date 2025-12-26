// Examples for casting documentation.
// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';

part 'casting_examples.orm.dart';

// #region casts-model-level
@OrmModel(
  table: 'settings',
  casts: {
    // Stored as JSON string, read as Map<String, Object?>
    'metadata': 'json',
    // Stored/read as DateTime (or parsed from ISO-8601 string)
    'createdAt': 'datetime',
  },
)
class Settings extends Model<Settings> {
  const Settings({required this.id, this.metadata, this.createdAt});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final Map<String, Object?>? metadata;
  final DateTime? createdAt;
}
// #endregion casts-model-level

// #region casts-field-level
@OrmModel(table: 'field_cast_settings')
class FieldCastSettings extends Model<FieldCastSettings> {
  const FieldCastSettings({required this.id, this.metadata});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(cast: 'json')
  final Map<String, Object?>? metadata;
}
// #endregion casts-field-level

// #region casts-custom-codec
class UriCodec extends ValueCodec<Uri> {
  const UriCodec();

  @override
  Object? encode(Uri? value) => value?.toString();

  @override
  Uri? decode(Object? value) =>
      value == null ? null : Uri.parse(value as String);
}
// #endregion casts-custom-codec

// #region casts-custom-use
@OrmModel(table: 'links', casts: {'website': 'uri'})
class Link extends Model<Link> {
  const Link({required this.id, this.website});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final Uri? website;
}
// #endregion casts-custom-use

// #region casts-custom-register
DataSource buildDataSource(DriverAdapter driver) {
  return DataSource(
    DataSourceOptions(
      driver: driver,
      entities: [
        SettingsOrmDefinition.definition,
        FieldCastSettingsOrmDefinition.definition,
        LinkOrmDefinition.definition,
      ],
      codecs: {'uri': const UriCodec()},
    ),
  );
}
// #endregion casts-custom-register

// #region casts-custom-handler
class UppercaseCastHandler extends AttributeCastHandler {
  const UppercaseCastHandler();

  @override
  Object? encode(Object? value, AttributeCastContext context) {
    final text = value?.toString();
    return text?.toUpperCase();
  }

  @override
  Object? decode(Object? value, AttributeCastContext context) {
    return value?.toString();
  }
}
// #endregion casts-custom-handler

// #region casts-custom-handler-ops
class MaskOnSerializeCastHandler extends AttributeCastHandler {
  const MaskOnSerializeCastHandler();

  @override
  Object? encode(Object? value, AttributeCastContext context) {
    final text = value?.toString();
    if (context.operation == CastOperation.serialize) {
      return text == null ? null : '***';
    }
    return text;
  }

  @override
  Object? decode(Object? value, AttributeCastContext context) {
    return value?.toString();
  }
}
// #endregion casts-custom-handler-ops

// #region casts-custom-handler-register
void registerCastHandlers(DataSource dataSource) {
  dataSource.codecRegistry.registerCastHandler(
    key: 'upper',
    handler: const UppercaseCastHandler(),
  );
}
// #endregion casts-custom-handler-register

// #region casts-enum-encrypted
enum AccountStatus { active, disabled }

@OrmModel(table: 'accounts')
class Account extends Model<Account> {
  const Account({required this.id, required this.status, required this.secret});

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(cast: 'enum')
  final AccountStatus status;

  @OrmField(cast: 'encrypted')
  final String secret;
}
// #endregion casts-enum-encrypted

// #region casts-encrypted-register
class ExampleEncrypter extends ValueEncrypter {
  const ExampleEncrypter();

  @override
  String encrypt(String value) => base64.encode(utf8.encode(value));

  @override
  String decrypt(String value) => utf8.decode(base64.decode(value));
}

void registerEncrypter(DataSource dataSource) {
  dataSource.codecRegistry.registerEncrypter(const ExampleEncrypter());
}
// #endregion casts-encrypted-register

// #region casts-arguments
@OrmModel(
  table: 'invoices',
  casts: {
    'amount': 'decimal:2',
    'metadata': 'encrypted:json',
  },
)
class Invoice extends Model<Invoice> {
  const Invoice({required this.id, this.amount, this.metadata});

  @OrmField(isPrimaryKey: true)
  final int id;

  final Decimal? amount;
  final Map<String, Object?>? metadata;
}
// #endregion casts-arguments
