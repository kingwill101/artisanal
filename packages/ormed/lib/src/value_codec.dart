import 'dart:convert';

import 'package:carbonized/carbonized.dart';
import 'package:decimal/decimal.dart';
import 'package:ormed/src/model/model.dart';

import 'exceptions.dart';

/// Converts between backend driver payloads and Dart values.
abstract class ValueCodec<TDart> {
  const ValueCodec();

  Object? encode(TDart? value);

  TDart? decode(Object? value);
}

/// Encrypts and decrypts string payloads for encrypted casts.
abstract class ValueEncrypter {
  const ValueEncrypter();

  String encrypt(String value);

  String decrypt(String value);
}

class _EncrypterRef {
  _EncrypterRef([this.value]);

  ValueEncrypter? value;
}

/// Handles custom attribute cast logic by key.
abstract class AttributeCastHandler {
  const AttributeCastHandler();

  Object? encode(Object? value, AttributeCastContext context);

  Object? decode(Object? value, AttributeCastContext context);
}

/// Context passed to [AttributeCastHandler] implementations.
class AttributeCastContext {
  const AttributeCastContext({
    required this.cast,
    required this.base,
    required this.arguments,
    required this.registry,
    required this.operation,
    this.field,
  });

  final String cast;
  final String base;
  final List<String> arguments;
  final ValueCodecRegistry registry;
  final CastOperation operation;
  final FieldDefinition? field;
}

enum CastOperation { persist, serialize, hydrate, assign }

/// No-op codec used for primitives.
class IdentityCodec<TDart> extends ValueCodec<TDart> {
  const IdentityCodec();

  @override
  Object? encode(TDart? value) => value;

  @override
  TDart? decode(Object? value) => value as TDart?;
}

/// Codec that normalizes boolean-like values.
class BoolCodec extends ValueCodec<bool> {
  const BoolCodec();

  @override
  Object? encode(bool? value) => value;

  @override
  bool? decode(Object? value) => _coerceBool(value);
}

/// Codec that normalizes integer-like values.
class IntCodec extends ValueCodec<int> {
  const IntCodec();

  @override
  Object? encode(int? value) => value;

  @override
  int? decode(Object? value) => _coerceInt(value);
}

/// Codec that normalizes floating-point values.
class DoubleCodec extends ValueCodec<double> {
  const DoubleCodec();

  @override
  Object? encode(double? value) => value;

  @override
  double? decode(Object? value) => _coerceDouble(value);
}

/// Codec that normalizes string values.
class StringCodec extends ValueCodec<String> {
  const StringCodec();

  @override
  Object? encode(String? value) => value;

  @override
  String? decode(Object? value) => _coerceString(value);
}

/// Codec for date-only values.
class DateCodec extends ValueCodec<DateTime> {
  const DateCodec();

  @override
  Object? encode(DateTime? value) => _coerceDate(value);

  @override
  DateTime? decode(Object? value) => _coerceDate(value);
}

/// Codec for Unix timestamps (seconds since epoch).
class TimestampCodec extends ValueCodec<int> {
  const TimestampCodec();

  @override
  Object? encode(int? value) => value;

  @override
  int? decode(Object? value) => _coerceTimestamp(value);
}

/// Codec for Decimal values.
class DecimalCodec extends ValueCodec<Decimal> {
  const DecimalCodec();

  @override
  Object? encode(Decimal? value) => value?.toString();

  @override
  Decimal? decode(Object? value) => _coerceDecimal(value);
}

/// Codec for JSON encoding/decoding `Map<String, Object?>` fields.
/// Encodes to JSON string for storage, decodes from JSON string to Map.
class JsonCodec extends ValueCodec<Map<String, Object?>> {
  const JsonCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, Object?>) return value;
    if (value is String) {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return decoded.map((key, dynamic entry) => MapEntry(key, entry));
    }
    throw FormatException('Cannot decode $value to Map<String, Object?>');
  }
}

/// Codec for JSON array encoding/decoding List fields.
/// Encodes to JSON string for storage, decodes from JSON string to List.
class JsonArrayCodec extends ValueCodec<List<Object?>> {
  const JsonArrayCodec();

  @override
  Object? encode(List<Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  List<Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is List<Object?>) return value;
    if (value is String) {
      return jsonDecode(value) as List<Object?>;
    }
    throw FormatException('Cannot decode $value to List<Object?>');
  }
}

/// Codec for DateTime fields that handles Carbon type conversion.
/// This ensures that Carbon values stored during operations like soft delete
/// can be properly decoded back to DateTime.
class DateTimeCodec extends ValueCodec<DateTime> {
  const DateTimeCodec();

  @override
  Object? encode(DateTime? value) => value;

  @override
  DateTime? decode(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Carbon) return value.toDateTime();
    if (value is String) return DateTime.parse(value);
    return null;
  }
}

/// Codec for Carbon/CarbonInterface fields.
///
/// Returns **immutable** Carbon instances to prevent accidental mutation
/// of model state when chaining date methods like `subDay()`.
///
/// Example:
/// ```dart
/// // Safe - returns a new Carbon instance
/// final yesterday = model.publishedAt?.subDay();
///
/// // Model's publishedAt is unchanged because it's immutable
/// print(model.publishedAt); // Still the original date
/// ```
class CarbonCodec extends ValueCodec<CarbonInterface> {
  const CarbonCodec();

  @override
  Object? encode(CarbonInterface? value) {
    if (value == null) return null;
    return value.toDateTime();
  }

  @override
  CarbonInterface? decode(Object? value) {
    if (value == null) return null;
    if (value is CarbonInterface) return value.toImmutable();
    if (value is DateTime) return Carbon.fromDateTime(value).toImmutable();
    if (value is String) return Carbon.parse(value).toImmutable();
    return null;
  }
}

/// Registry that resolves codecs per field/type, with driver-specific overlays.
class ValueCodecRegistry {
  ValueCodecRegistry._(
    this._codecs,
    this._driverCodecs, {
    String? activeDriver,
    _EncrypterRef? encrypterRef,
    Map<String, AttributeCastHandler> castHandlers =
        const <String, AttributeCastHandler>{},
  }) : _activeDriver = activeDriver,
       _encrypterRef = encrypterRef ?? _EncrypterRef(),
       _castHandlers = castHandlers;

  static final ValueCodecRegistry _instance = ValueCodecRegistry._(
    Map<String, ValueCodec<dynamic>>.from(_defaultCodecs),
    <String, Map<String, ValueCodec<dynamic>>>{},
    encrypterRef: _EncrypterRef(),
    castHandlers: <String, AttributeCastHandler>{},
  );

  /// Global singleton instance of the codec registry.
  static ValueCodecRegistry get instance => _instance;

  final Map<String, ValueCodec<dynamic>> _codecs;
  final Map<String, Map<String, ValueCodec<dynamic>>> _driverCodecs;
  final String? _activeDriver;
  final _EncrypterRef _encrypterRef;
  final Map<String, AttributeCastHandler> _castHandlers;

  /// Clone the registry with additional codecs. Driver overlays are copied.
  ValueCodecRegistry fork({
    Map<String, ValueCodec<dynamic>> codecs = const {},
    ValueEncrypter? encrypter,
    Map<String, AttributeCastHandler>? castHandlers,
  }) => ValueCodecRegistry._(
    {..._codecs, ...codecs},
    _cloneDriverCodecs(_driverCodecs),
    activeDriver: _activeDriver,
    encrypterRef: _EncrypterRef(encrypter ?? _encrypterRef.value),
    castHandlers:
        castHandlers ?? Map<String, AttributeCastHandler>.from(_castHandlers),
  );

  /// Returns a view scoped to [driver]. Registrations become driver-specific.
  ValueCodecRegistry forDriver(String driver) {
    final normalized = _normalizeDriver(driver);
    return ValueCodecRegistry._(
      _codecs,
      _driverCodecs,
      activeDriver: normalized,
      encrypterRef: _encrypterRef,
      castHandlers: _castHandlers,
    );
  }

  /// Returns the encrypter used for encrypted casts, when configured.
  ValueEncrypter? get encrypter => _encrypterRef.value;

  /// Registers an encrypter for encrypted casts.
  void registerEncrypter(ValueEncrypter encrypter) {
    _encrypterRef.value = encrypter;
  }

  /// Clears any configured encrypter.
  void clearEncrypter() {
    _encrypterRef.value = null;
  }

  /// Register or override a codec for a given type key.
  void registerCodec({
    required String key,
    required ValueCodec<dynamic> codec,
  }) {
    final driver = _activeDriver;
    if (driver != null) {
      final overlay = _driverCodecs.putIfAbsent(
        driver,
        () => <String, ValueCodec<dynamic>>{},
      );
      overlay[key] = codec;

      return;
    }
    _codecs[key] = codec;
  }

  /// Convenience helper to register by using a [Type] token (e.g., `JsonCodec`).
  void registerCodecFor(Type codecType, ValueCodec<dynamic> codec) {
    registerCodec(key: codecType.toString(), codec: codec);
  }

  /// Register all codecs for a specific driver.
  /// This is typically called during driver initialization.
  void registerDriver(String driver, Map<String, ValueCodec<dynamic>> codecs) {
    final normalized = _normalizeDriver(driver);
    final overlay = _driverCodecs.putIfAbsent(
      normalized,
      () => <String, ValueCodec<dynamic>>{},
    );
    overlay.addAll(codecs);
  }

  /// Unregister all codecs for a specific driver.
  /// Primarily used for testing cleanup.
  void unregisterDriver(String driver) {
    final normalized = _normalizeDriver(driver);
    _driverCodecs.remove(normalized);
  }

  /// Clear all registered codecs (both global and driver-specific).
  /// Resets to default codecs only. Primarily used for testing cleanup.
  void clearAll() {
    _codecs.clear();
    _codecs.addAll(_defaultCodecs);
    _driverCodecs.clear();
    _encrypterRef.value = null;
    _castHandlers.clear();
  }

  /// Registers a custom cast handler for [key].
  void registerCastHandler({
    required String key,
    required AttributeCastHandler handler,
  }) {
    _castHandlers[_normalizeCastKey(key)] = handler;
  }

  /// Removes a custom cast handler for [key].
  void unregisterCastHandler(String key) {
    _castHandlers.remove(_normalizeCastKey(key));
  }

  AttributeCastHandler? _castHandlerFor(String key) =>
      _castHandlers[_normalizeCastKey(key)];

  Object? encodeField(FieldDefinition field, Object? value) {
    final castKey = field.codecTypeForDriver(_activeDriver);
    if (castKey != null) {
      return encodeCast(
        castKey,
        value,
        field: field,
        operation: CastOperation.persist,
      );
    }
    return _codecFor(field).encode(value);
  }

  T? decodeField<T>(FieldDefinition field, Object? value) {
    final castKey = field.codecTypeForDriver(_activeDriver);
    if (castKey != null) {
      return decodeCast<T>(castKey, value, field: field);
    }
    return _codecFor(field).decode(value) as T?;
  }

  /// Encodes [value] using the codec registered under [key].
  Object? encodeByKey(String key, Object? value) {
    final codec = _codecForKey(key);
    if (codec == null) {
      return value;
    }
    return codec.encode(value);
  }

  /// Encodes [value] using Laravel-style cast semantics when applicable.
  Object? encodeCast(
    String key,
    Object? value, {
    FieldDefinition? field,
    CastOperation operation = CastOperation.persist,
  }) {
    if (value == null) return null;
    final parsed = _parseCastKey(key);
    final handler = _castHandlerFor(parsed.base);
    if (handler != null) {
      return handler.encode(
        value,
        AttributeCastContext(
          cast: parsed.raw,
          base: parsed.base,
          arguments: parsed.args,
          registry: this,
          operation: operation,
          field: field,
        ),
      );
    }
    switch (parsed.normalizedBase) {
      case 'bool':
      case 'boolean':
        return _coerceBool(value);
      case 'int':
      case 'integer':
        return _coerceInt(value);
      case 'real':
      case 'float':
      case 'double':
        return _coerceDouble(value);
      case 'string':
        return _coerceString(value);
      case 'date':
        final date = _coerceDate(value);
        if (date == null) return null;
        if (operation == CastOperation.persist) {
          final driverCodec = _driverCodecForKey('date');
          if (driverCodec != null) {
            return driverCodec.encode(date);
          }
        }
        return date;
      case 'datetime':
        return _coerceDateTime(value);
      case 'timestamp':
        return _coerceTimestamp(value);
      case 'decimal':
        final decimal = _coerceDecimal(value);
        if (decimal == null) return null;
        final scale = parsed.scale;
        return scale == null
            ? decimal.toString()
            : decimal.toStringAsFixed(scale);
      case 'enum':
        return _encodeEnum(value, field);
      case 'encrypted':
        if (operation == CastOperation.serialize) return value;
        return _encodeEncrypted(parsed, value, field, this);
    }
    final codec = _codecForKey(key);
    if (codec == null) {
      if (field == null) return value;
      throw CodecNotFound(key, field);
    }
    return codec.encode(value);
  }

  /// Decodes [value] using the codec registered under [key].
  T? decodeByKey<T>(String key, Object? value) {
    final codec = _codecForKey(key);
    if (codec == null) {
      return value as T?;
    }
    return codec.decode(value) as T?;
  }

  /// Decodes [value] using Laravel-style cast semantics when applicable.
  T? decodeCast<T>(
    String key,
    Object? value, {
    FieldDefinition? field,
    CastOperation operation = CastOperation.hydrate,
  }) {
    if (value == null) return null;
    final parsed = _parseCastKey(key);
    final handler = _castHandlerFor(parsed.base);
    if (handler != null) {
      return handler.decode(
        value,
        AttributeCastContext(
          cast: parsed.raw,
          base: parsed.base,
          arguments: parsed.args,
          registry: this,
          operation: operation,
          field: field,
        ),
      ) as T?;
    }
    switch (parsed.normalizedBase) {
      case 'bool':
      case 'boolean':
        return _coerceBool(value) as T?;
      case 'int':
      case 'integer':
        return _coerceInt(value) as T?;
      case 'real':
      case 'float':
      case 'double':
        return _coerceDouble(value) as T?;
      case 'string':
        return _coerceString(value) as T?;
      case 'date':
        return _coerceDate(value) as T?;
      case 'datetime':
        return _coerceDateTime(value) as T?;
      case 'timestamp':
        return _coerceTimestamp(value) as T?;
      case 'decimal':
        return _coerceDecimal(value) as T?;
      case 'enum':
        return _decodeEnum(value, field) as T?;
      case 'encrypted':
        if (operation == CastOperation.assign) {
          return value as T?;
        }
        return _decodeEncrypted(parsed, value, field, this) as T?;
    }
    final codec = _codecForKey(key);
    if (codec == null) {
      if (field == null) return value as T?;
      throw CodecNotFound(key, field);
    }
    return codec.decode(value) as T?;
  }

  ValueCodec<dynamic>? _driverCodecForKey(String key) {
    final driver = _activeDriver;
    if (driver == null) return null;
    return _driverCodecs[driver]?[key];
  }

  ValueCodec<dynamic>? _codecForKey(String key) {
    final driverCodec = _driverCodecForKey(key);
    if (driverCodec != null) {
      return driverCodec;
    }
    return _codecs[key];
  }

  Object? encodeValue(Object? value) {
    if (value == null) {
      return null;
    }
    final codec = _codecForKey(value.runtimeType.toString());
    if (codec == null) {
      return value;
    }
    return codec.encode(value);
  }

  ValueCodec<dynamic> _codecFor(FieldDefinition field) {
    final driver = _activeDriver;
    final key = field.codecTypeForDriver(driver) ?? field.dartType;
    ValueCodec<dynamic>? codec = _codecForKey(key);
    if (codec == null) {
      throw CodecNotFound(key, field);
    }
    return codec;
  }
}

Map<String, Map<String, ValueCodec<dynamic>>> _cloneDriverCodecs(
  Map<String, Map<String, ValueCodec<dynamic>>> source,
) {
  if (source.isEmpty) return <String, Map<String, ValueCodec<dynamic>>>{};
  final copy = <String, Map<String, ValueCodec<dynamic>>>{};
  source.forEach((driver, codecs) {
    copy[driver] = Map<String, ValueCodec<dynamic>>.from(codecs);
  });
  return copy;
}

String _normalizeDriver(String driver) {
  final normalized = driver.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(driver, 'driver', 'must not be empty');
  }
  return normalized.toLowerCase();
}

String _normalizeCastKey(String key) => key.trim().toLowerCase();

/// Default codecs available in all registries.
///
/// Basic types use IdentityCodec (no conversion).
/// Cast keys support Laravel-style @OrmField(cast: 'json') syntax:
/// - 'json' / 'object': Encodes Map to JSON string, decodes JSON string to Map
/// - 'array': Encodes List to JSON string, decodes JSON string to List
Map<String, ValueCodec<dynamic>> get _defaultCodecs => const {
  // Basic types
  'Object': IdentityCodec<Object?>(),
  'Object?': IdentityCodec<Object?>(),
  'String': IdentityCodec<String>(),
  'string': StringCodec(),
  'int': IntCodec(),
  'integer': IntCodec(),
  'double': DoubleCodec(),
  'float': DoubleCodec(),
  'real': DoubleCodec(),
  'num': IdentityCodec<num>(),
  'bool': BoolCodec(),
  'boolean': BoolCodec(),
  'DateTime': DateTimeCodec(),
  'datetime': DateTimeCodec(), // Lowercase alias
  'date': DateCodec(),
  'timestamp': TimestampCodec(),
  'Carbon': CarbonCodec(),
  'CarbonInterface': CarbonCodec(),
  'decimal': DecimalCodec(),
  'Map<String, Object?>': IdentityCodec<Map<String, Object?>>(),
  'Map<String, dynamic>': IdentityCodec<Map<String, dynamic>>(),
  'List<Object?>': IdentityCodec<List<Object?>>(),
  'List<dynamic>': IdentityCodec<List<dynamic>>(),

  // Common cast keys (Laravel-style)
  'json': JsonCodec(),
  'array': JsonArrayCodec(),
  'object': JsonCodec(), // Alias for json
};

class _CastKey {
  const _CastKey({
    required this.raw,
    required this.base,
    required this.normalizedBase,
    required this.args,
  });

  final String raw;
  final String base;
  final String normalizedBase;
  final List<String> args;

  int? get scale {
    if (args.isEmpty) return null;
    final parsed = int.tryParse(args.first.trim());
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
}

_CastKey _parseCastKey(String cast) {
  final trimmed = cast.trim();
  final parts = trimmed.split(':');
  final base = parts.first.trim();
  final args = parts.length > 1
      ? parts.sublist(1).map((part) => part.trim()).toList(growable: false)
      : const <String>[];
  return _CastKey(
    raw: trimmed,
    base: base,
    normalizedBase: base.toLowerCase(),
    args: args,
  );
}

bool? _coerceBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (const {'1', 'true', 't', 'yes', 'y', 'on'}.contains(normalized)) {
      return true;
    }
    if (const {'0', 'false', 'f', 'no', 'n', 'off'}.contains(normalized)) {
      return false;
    }
  }
  return null;
}

int? _coerceInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _coerceDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? _coerceString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

DateTime? _coerceDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is CarbonInterface) return value.toDateTime();
  if (value is String) return DateTime.parse(value);
  return null;
}

DateTime? _coerceDate(Object? value) {
  final dateTime = _coerceDateTime(value);
  if (dateTime == null) return null;
  if (dateTime.isUtc) {
    return DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
  }
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

int? _coerceTimestamp(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final dateTime = _coerceDateTime(value);
  if (dateTime == null) return null;
  return dateTime.millisecondsSinceEpoch ~/ 1000;
}

Decimal? _coerceDecimal(Object? value) {
  if (value == null) return null;
  if (value is Decimal) return value;
  if (value is num) return Decimal.parse(value.toString());
  if (value is String) return Decimal.parse(value.trim());
  throw StateError('Unsupported Decimal value "$value".');
}

Object? _encodeEnum(Object? value, FieldDefinition? _field) {
  if (value == null) return null;
  if (value is Enum) return value.name;
  return value;
}

Object? _decodeEnum(Object? value, FieldDefinition? field) {
  if (value == null) return null;
  if (value is Enum) return value;
  final rawValues = field?.enumValues;
  if (rawValues is! List) {
    return value;
  }
  final enumValues = <Enum>[];
  for (final entry in rawValues) {
    if (entry is Enum) {
      enumValues.add(entry);
    }
  }
  if (enumValues.isEmpty) {
    return value;
  }
  if (value is String) {
    for (final entry in enumValues) {
      if (entry.name == value || entry.toString().split('.').last == value) {
        return entry;
      }
    }
    return value;
  }
  if (value is int && value >= 0 && value < enumValues.length) {
    return enumValues[value];
  }
  return value;
}

Object? _encodeEncrypted(
  _CastKey cast,
  Object? value,
  FieldDefinition? field,
  ValueCodecRegistry registry,
) {
  final encrypter = registry.encrypter;
  if (encrypter == null) {
    throw StateError('No encrypter registered for encrypted casts.');
  }
  final payload = cast.args.isEmpty
      ? value
      : registry.encodeCast(cast.args.join(':'), value, field: field);
  if (payload == null) return null;
  if (payload is! String) {
    throw StateError('Encrypted casts require string payloads.');
  }
  return encrypter.encrypt(payload);
}

Object? _decodeEncrypted(
  _CastKey cast,
  Object? value,
  FieldDefinition? field,
  ValueCodecRegistry registry,
) {
  final encrypter = registry.encrypter;
  if (encrypter == null) {
    throw StateError('No encrypter registered for encrypted casts.');
  }
  if (value == null) return null;
  if (value is! String) {
    throw StateError('Encrypted casts require string payloads.');
  }
  final decrypted = encrypter.decrypt(value);
  if (cast.args.isEmpty) return decrypted;
  return registry.decodeCast(cast.args.join(':'), decrypted, field: field);
}
