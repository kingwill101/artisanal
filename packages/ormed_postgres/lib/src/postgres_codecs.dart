import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid_value.dart';

import 'postgres_value_types.dart';

/// Registers PostgreSQL-specific codecs with the global codec registry.
void registerPostgresCodecs() {
  const timestampCodec = _PostgresTimestampCodec();
  const timeCodec = _PostgresTimeCodec();
  const intervalCodec = _PostgresIntervalCodec();
  const intervalValueCodec = _PostgresIntervalValueCodec();
  const jsonMapCodec = _PostgresJsonMapCodec();
  const jsonDynamicMapCodec = _PostgresJsonDynamicMapCodec();
  const jsonListCodec = _PostgresJsonListCodec();
  const uuidValueCodec = _PostgresUuidValueCodec();
  const uuidValueArrayCodec = _PostgresUuidValueArrayCodec();
  const numericDecimalCodec = _PostgresNumericDecimalCodec();
  const byteaCodec = _PostgresByteaCodec();
  const inetCodec = _PostgresInetCodec();
  const cidrCodec = _PostgresCidrCodec();
  const macaddrCodec = _PostgresMacaddrCodec();
  const vectorCodec = _PostgresVectorCodec();
  const bitStringCodec = _PostgresBitStringCodec();
  const moneyCodec = _PostgresMoneyCodec();
  const timeTzCodec = _PostgresTimeTzCodec();
  const lsnCodec = _PostgresLsnCodec();
  const snapshotCodec = _PostgresSnapshotCodec();
  const intRangeCodec = _PostgresIntRangeCodec();
  const dateRangeCodec = _PostgresDateRangeCodec();
  const dateTimeRangeCodec = _PostgresDateTimeRangeCodec();
  const carbonCodec = PostgresCarbonCodec();
  const carbonInterfaceCodec = PostgresCarbonInterfaceCodec();
  const pointCodec = _PostgresTypedValueCodec<Point>(Type.point);
  const lineCodec = _PostgresTypedValueCodec<Line>(Type.line);
  const lineSegmentCodec = _PostgresTypedValueCodec<LineSegment>(
    Type.lineSegment,
  );
  const boxCodec = _PostgresTypedValueCodec<Box>(Type.box);
  const pathCodec = _PostgresTypedValueCodec<Path>(Type.path);
  const polygonCodec = _PostgresTypedValueCodec<Polygon>(Type.polygon);
  const circleCodec = _PostgresTypedValueCodec<Circle>(Type.circle);

  ValueCodecRegistry.instance.registerDriver('postgres', {
    'DateTime': timestampCodec,
    'DateTime?': timestampCodec,
    'Time': timeCodec,
    'Time?': timeCodec,
    'Duration': intervalCodec,
    'Duration?': intervalCodec,
    'Interval': intervalValueCodec,
    'Interval?': intervalValueCodec,
    'Carbon': carbonCodec,
    'Carbon?': carbonCodec,
    'CarbonInterface': carbonInterfaceCodec,
    'CarbonInterface?': carbonInterfaceCodec,
    'UuidValue': uuidValueCodec,
    'UuidValue?': uuidValueCodec,
    'List<UuidValue>': uuidValueArrayCodec,
    'List<UuidValue>?': uuidValueArrayCodec,
    'Decimal': numericDecimalCodec,
    'Decimal?': numericDecimalCodec,
    'Uint8List': byteaCodec,
    'Uint8List?': byteaCodec,
    'TsVector': const IdentityCodec<TsVector>(),
    'TsVector?': const IdentityCodec<TsVector>(),
    'TsQuery': const IdentityCodec<TsQuery>(),
    'TsQuery?': const IdentityCodec<TsQuery>(),
    'IntRange': intRangeCodec,
    'IntRange?': intRangeCodec,
    'DateRange': dateRangeCodec,
    'DateRange?': dateRangeCodec,
    'DateTimeRange': dateTimeRangeCodec,
    'DateTimeRange?': dateTimeRangeCodec,
    'PgInet': inetCodec,
    'PgInet?': inetCodec,
    'PgCidr': cidrCodec,
    'PgCidr?': cidrCodec,
    'PgMacAddress': macaddrCodec,
    'PgMacAddress?': macaddrCodec,
    'PgVector': vectorCodec,
    'PgVector?': vectorCodec,
    'PgBitString': bitStringCodec,
    'PgBitString?': bitStringCodec,
    'PgMoney': moneyCodec,
    'PgMoney?': moneyCodec,
    'PgTimeTz': timeTzCodec,
    'PgTimeTz?': timeTzCodec,
    'LSN': lsnCodec,
    'LSN?': lsnCodec,
    'PgSnapshot': snapshotCodec,
    'PgSnapshot?': snapshotCodec,
    'Point': pointCodec,
    'Point?': pointCodec,
    'Line': lineCodec,
    'Line?': lineCodec,
    'LineSegment': lineSegmentCodec,
    'LineSegment?': lineSegmentCodec,
    'Box': boxCodec,
    'Box?': boxCodec,
    'Path': pathCodec,
    'Path?': pathCodec,
    'Polygon': polygonCodec,
    'Polygon?': polygonCodec,
    'Circle': circleCodec,
    'Circle?': circleCodec,
    'Map<String, Object?>': jsonMapCodec,
    'Map<String, Object?>?': jsonMapCodec,
    'Map<String, dynamic>': jsonDynamicMapCodec,
    'Map<String, dynamic>?': jsonDynamicMapCodec,
    'List<Object?>': jsonListCodec,
    'List<Object?>?': jsonListCodec,
    'List<dynamic>': jsonListCodec,
    'List<dynamic>?': jsonListCodec,
    'List<String>': const _PostgresArrayCodec<String>(Type.textArray),
    'List<int>': const _PostgresArrayCodec<int>(Type.integerArray),
    'List<double>': const _PostgresArrayCodec<double>(Type.doubleArray),
    'List<bool>': const _PostgresArrayCodec<bool>(Type.booleanArray),
    'List<DateTime>': const _PostgresArrayCodec<DateTime>(
      Type.timestampTzArray,
    ),
  });
}

Object? _unwrapTypedValue(Object? value) {
  if (value is TypedValue) {
    return value.value;
  }
  return value;
}

final class _PostgresTypedValueCodec<T extends Object> extends ValueCodec<T> {
  const _PostgresTypedValueCodec(this.type);

  final Type<T> type;

  @override
  Object? encode(T? value) {
    if (value == null) {
      return TypedValue<T>(type, null, isSqlNull: true);
    }
    return TypedValue<T>(type, value);
  }

  @override
  T? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is T) return unwrapped;
    throw StateError('Unsupported ${type.runtimeType} value "$value".');
  }
}

class _PostgresTimestampCodec extends ValueCodec<DateTime> {
  const _PostgresTimestampCodec();

  @override
  Object? encode(DateTime? value) {
    if (value == null) {
      return TypedValue<DateTime>(Type.timestampTz, null, isSqlNull: true);
    }
    return TypedValue<DateTime>(Type.timestampTz, value.toUtc());
  }

  @override
  DateTime? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is DateTime) return unwrapped;
    if (unwrapped is String && unwrapped.isNotEmpty) {
      return DateTime.parse(unwrapped);
    }
    throw StateError('Unsupported timestamp value "$value".');
  }
}

class _PostgresTimeCodec extends ValueCodec<Time> {
  const _PostgresTimeCodec();

  @override
  Object? encode(Time? value) {
    if (value == null) {
      return TypedValue<Time>(Type.time, null, isSqlNull: true);
    }
    return TypedValue<Time>(Type.time, value);
  }

  @override
  Time? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is Time) return unwrapped;
    if (unwrapped is String && unwrapped.isNotEmpty) {
      final parts = unwrapped.split(':');
      if (parts.length < 2) {
        throw FormatException('Invalid time "$unwrapped".');
      }
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final secondsPart = parts.length > 2 ? parts[2] : '0';
      final secondsParts = secondsPart.split('.');
      final second = int.parse(secondsParts[0]);
      final micros = secondsParts.length > 1
          ? int.parse(secondsParts[1].padRight(6, '0').substring(0, 6))
          : 0;
      return Time(hour, minute, second, 0, micros);
    }
    if (unwrapped is UndecodedBytes) {
      return decode(unwrapped.asString);
    }
    throw StateError('Unsupported time value "$value".');
  }
}

class _PostgresIntervalCodec extends ValueCodec<Duration> {
  const _PostgresIntervalCodec();

  @override
  Object? encode(Duration? value) {
    if (value == null) {
      return TypedValue<Interval>(Type.interval, null, isSqlNull: true);
    }
    return TypedValue<Interval>(Type.interval, Interval.duration(value));
  }

  @override
  Duration? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is Duration) return unwrapped;
    if (unwrapped is Interval) {
      final fromMonths = Duration(days: unwrapped.months * 30);
      final fromDays = Duration(days: unwrapped.days);
      final fromMicros = Duration(microseconds: unwrapped.microseconds);
      return fromMonths + fromDays + fromMicros;
    }
    throw StateError('Unsupported interval value "$value".');
  }
}

class _PostgresIntervalValueCodec extends ValueCodec<Interval> {
  const _PostgresIntervalValueCodec();

  @override
  Object? encode(Interval? value) {
    if (value == null) {
      return TypedValue<Interval>(Type.interval, null, isSqlNull: true);
    }
    return TypedValue<Interval>(Type.interval, value);
  }

  @override
  Interval? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is Interval) return unwrapped;
    throw StateError('Unsupported interval value "$value".');
  }
}

class _PostgresUuidValueCodec extends ValueCodec<UuidValue> {
  const _PostgresUuidValueCodec();

  @override
  Object? encode(UuidValue? value) {
    if (value == null) {
      return TypedValue<String>(Type.uuid, null, isSqlNull: true);
    }
    return TypedValue<String>(Type.uuid, value.uuid);
  }

  @override
  UuidValue? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is UuidValue) return unwrapped;
    if (unwrapped is String) return UuidValue.fromString(unwrapped);
    if (unwrapped is UndecodedBytes) {
      return UuidValue.fromString(unwrapped.asString);
    }
    throw StateError('Unsupported UUID value "$value".');
  }
}

class _PostgresUuidValueArrayCodec extends ValueCodec<List<UuidValue>> {
  const _PostgresUuidValueArrayCodec();

  @override
  Object? encode(List<UuidValue>? value) {
    if (value == null) {
      return TypedValue<List<String>>(Type.uuidArray, null, isSqlNull: true);
    }
    return TypedValue<List<String>>(
      Type.uuidArray,
      value.map((entry) => entry.uuid).toList(growable: false),
    );
  }

  @override
  List<UuidValue>? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is List<UuidValue>) {
      return List<UuidValue>.from(unwrapped);
    }
    if (unwrapped is List<String>) {
      return unwrapped.map(UuidValue.fromString).toList(growable: false);
    }
    if (unwrapped is List) {
      return unwrapped
          .map((entry) => UuidValue.fromString(entry.toString()))
          .toList(growable: false);
    }
    throw StateError('Unsupported UUID array value "$value".');
  }
}

class _PostgresNumericDecimalCodec extends ValueCodec<Decimal> {
  const _PostgresNumericDecimalCodec();

  @override
  Object? encode(Decimal? value) {
    if (value == null) {
      return TypedValue<Object>(Type.numeric, null, isSqlNull: true);
    }
    return TypedValue<Object>(Type.numeric, value.toString());
  }

  @override
  Decimal? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is Decimal) return unwrapped;
    if (unwrapped is String) return Decimal.parse(unwrapped);
    if (unwrapped is num) return Decimal.parse(unwrapped.toString());
    if (unwrapped is UndecodedBytes) {
      return Decimal.parse(unwrapped.asString);
    }
    throw StateError('Unsupported numeric value "$value".');
  }
}

class _PostgresByteaCodec extends ValueCodec<Uint8List> {
  const _PostgresByteaCodec();

  @override
  Object? encode(Uint8List? value) {
    if (value == null) {
      return TypedValue<List<int>>(Type.byteArray, null, isSqlNull: true);
    }
    return TypedValue<List<int>>(Type.byteArray, value);
  }

  @override
  Uint8List? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is Uint8List) return unwrapped;
    if (unwrapped is List<int>) return Uint8List.fromList(unwrapped);
    if (unwrapped is UndecodedBytes) return unwrapped.bytes;
    throw StateError('Unsupported bytea value "$value".');
  }
}

class _PostgresInetCodec extends ValueCodec<PgInet> {
  const _PostgresInetCodec();

  @override
  Object? encode(PgInet? value) => value?.value;

  @override
  PgInet? decode(Object? value) {
    if (value == null) return null;
    if (value is PgInet) return value;
    if (value is String) return PgInet.parse(value);
    if (value is UndecodedBytes) return PgInet.parse(value.asString);
    throw StateError('Unsupported inet value "$value".');
  }
}

class _PostgresCidrCodec extends ValueCodec<PgCidr> {
  const _PostgresCidrCodec();

  @override
  Object? encode(PgCidr? value) => value?.value;

  @override
  PgCidr? decode(Object? value) {
    if (value == null) return null;
    if (value is PgCidr) return value;
    if (value is String) return PgCidr.parse(value);
    if (value is UndecodedBytes) return PgCidr.parse(value.asString);
    throw StateError('Unsupported cidr value "$value".');
  }
}

class _PostgresMacaddrCodec extends ValueCodec<PgMacAddress> {
  const _PostgresMacaddrCodec();

  @override
  Object? encode(PgMacAddress? value) => value?.value;

  @override
  PgMacAddress? decode(Object? value) {
    if (value == null) return null;
    if (value is PgMacAddress) return value;
    if (value is String) return PgMacAddress.parse(value);
    if (value is UndecodedBytes) return PgMacAddress.parse(value.asString);
    throw StateError('Unsupported macaddr value "$value".');
  }
}

class _PostgresBitStringCodec extends ValueCodec<PgBitString> {
  const _PostgresBitStringCodec();

  @override
  Object? encode(PgBitString? value) => value?.bits;

  @override
  PgBitString? decode(Object? value) {
    if (value == null) return null;
    if (value is PgBitString) return value;
    if (value is String) return PgBitString.parse(value);
    if (value is UndecodedBytes) return PgBitString.parse(value.asString);
    throw StateError('Unsupported bit string value "$value".');
  }
}

class _PostgresMoneyCodec extends ValueCodec<PgMoney> {
  const _PostgresMoneyCodec();

  @override
  Object? encode(PgMoney? value) => value?.toDecimalString();

  @override
  PgMoney? decode(Object? value) {
    if (value == null) return null;
    if (value is PgMoney) return value;
    if (value is String) return PgMoney.parse(value);
    if (value is num) return PgMoney.fromCents(value.toInt());
    if (value is UndecodedBytes) return PgMoney.parse(value.asString);
    throw StateError('Unsupported money value "$value".');
  }
}

class _PostgresTimeTzCodec extends ValueCodec<PgTimeTz> {
  const _PostgresTimeTzCodec();

  @override
  Object? encode(PgTimeTz? value) => value?.toPgString();

  @override
  PgTimeTz? decode(Object? value) {
    if (value == null) return null;
    if (value is PgTimeTz) return value;
    if (value is String) return PgTimeTz.parse(value);
    if (value is UndecodedBytes) return PgTimeTz.parse(value.asString);
    throw StateError('Unsupported timetz value "$value".');
  }
}

class _PostgresLsnCodec extends ValueCodec<LSN> {
  const _PostgresLsnCodec();

  @override
  Object? encode(LSN? value) => value?.toString();

  @override
  LSN? decode(Object? value) {
    if (value == null) return null;
    if (value is LSN) return value;
    if (value is String) return LSN.fromString(value);
    if (value is UndecodedBytes) return LSN.fromString(value.asString);
    throw StateError('Unsupported pg_lsn value "$value".');
  }
}

class _PostgresSnapshotCodec extends ValueCodec<PgSnapshot> {
  const _PostgresSnapshotCodec();

  @override
  Object? encode(PgSnapshot? value) => value?.toString();

  @override
  PgSnapshot? decode(Object? value) {
    if (value == null) return null;
    if (value is PgSnapshot) return value;
    if (value is String) return PgSnapshot.parse(value);
    if (value is UndecodedBytes) return PgSnapshot.parse(value.asString);
    throw StateError('Unsupported snapshot value "$value".');
  }
}

class _PostgresVectorCodec extends ValueCodec<PgVector> {
  const _PostgresVectorCodec();

  @override
  Object? encode(PgVector? value) => value?.toString();

  @override
  PgVector? decode(Object? value) {
    if (value == null) return null;
    if (value is PgVector) return value;
    if (value is String) return PgVector.parse(value);
    if (value is UndecodedBytes) return PgVector.parse(value.asString);
    throw StateError('Unsupported vector value "$value".');
  }
}

class _PostgresIntRangeCodec extends ValueCodec<IntRange> {
  const _PostgresIntRangeCodec();

  @override
  Object? encode(IntRange? value) {
    if (value == null) {
      return TypedValue<IntRange>(Type.integerRange, null, isSqlNull: true);
    }
    return TypedValue<IntRange>(Type.integerRange, value);
  }

  @override
  IntRange? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is IntRange) return unwrapped;
    throw StateError('Unsupported int range value "$value".');
  }
}

class _PostgresDateRangeCodec extends ValueCodec<DateRange> {
  const _PostgresDateRangeCodec();

  @override
  Object? encode(DateRange? value) {
    if (value == null) {
      return TypedValue<DateRange>(Type.dateRange, null, isSqlNull: true);
    }
    return TypedValue<DateRange>(Type.dateRange, value);
  }

  @override
  DateRange? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is DateRange) return unwrapped;
    throw StateError('Unsupported date range value "$value".');
  }
}

class _PostgresDateTimeRangeCodec extends ValueCodec<DateTimeRange> {
  const _PostgresDateTimeRangeCodec();

  @override
  Object? encode(DateTimeRange? value) {
    if (value == null) {
      return TypedValue<DateTimeRange>(
        Type.timestampTzRange,
        null,
        isSqlNull: true,
      );
    }
    return TypedValue<DateTimeRange>(Type.timestampTzRange, value);
  }

  @override
  DateTimeRange? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is DateTimeRange) return unwrapped;
    throw StateError('Unsupported datetime range value "$value".');
  }
}

class _PostgresJsonMapCodec extends ValueCodec<Map<String, Object?>> {
  const _PostgresJsonMapCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) {
      return TypedValue<Object>(Type.jsonb, null, isSqlNull: true);
    }
    return TypedValue<Object>(Type.jsonb, value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is Map<String, Object?>) {
      return Map<String, Object?>.from(unwrapped);
    }
    if (unwrapped is Map) {
      return unwrapped.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    if (unwrapped is String && unwrapped.isNotEmpty) {
      final decoded = jsonDecode(unwrapped);
      if (decoded is Map) {
        return decoded.map((key, dynamic v) => MapEntry(key.toString(), v));
      }
    }
    throw StateError('Expected JSON map but received "$value".');
  }
}

class _PostgresJsonDynamicMapCodec extends ValueCodec<Map<String, dynamic>> {
  const _PostgresJsonDynamicMapCodec();

  @override
  Object? encode(Map<String, dynamic>? value) {
    if (value == null) {
      return TypedValue<Object>(Type.jsonb, null, isSqlNull: true);
    }
    return TypedValue<Object>(Type.jsonb, value);
  }

  @override
  Map<String, dynamic>? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is Map<String, dynamic>) {
      return Map<String, dynamic>.from(unwrapped);
    }
    if (unwrapped is Map) {
      return unwrapped.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    if (unwrapped is String && unwrapped.isNotEmpty) {
      final decoded = jsonDecode(unwrapped);
      if (decoded is Map) {
        return decoded.map((key, dynamic v) => MapEntry(key.toString(), v));
      }
    }
    throw StateError('Expected JSON map but received "$value".');
  }
}

class _PostgresJsonListCodec extends ValueCodec<List<Object?>> {
  const _PostgresJsonListCodec();

  @override
  Object? encode(List<Object?>? value) {
    if (value == null) {
      return TypedValue<Object>(Type.jsonb, null, isSqlNull: true);
    }
    return TypedValue<Object>(Type.jsonb, value);
  }

  @override
  List<Object?>? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is List<Object?>) {
      return List<Object?>.from(unwrapped);
    }
    if (unwrapped is List) {
      return unwrapped.cast<Object?>();
    }
    if (unwrapped is String && unwrapped.isNotEmpty) {
      final decoded = jsonDecode(unwrapped);
      if (decoded is List) {
        return decoded.cast<Object?>();
      }
    }
    throw StateError('Expected JSON array but received "$value".');
  }
}

class _PostgresArrayCodec<T> extends ValueCodec<List<T>> {
  const _PostgresArrayCodec(this._type);

  final Type<List<T>> _type;

  @override
  Object? encode(List<T>? value) {
    if (value == null) return null;
    return TypedValue<List<T>>(_type, value);
  }

  @override
  List<T>? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;
    if (unwrapped is List<T>) {
      return List<T>.from(unwrapped);
    }
    if (unwrapped is List) {
      return unwrapped.cast<T>();
    }
    throw StateError('Expected Postgres array but received "$value".');
  }
}

/// Codec for Carbon instances with timezone-aware decoding.
/// Encodes to UTC TIMESTAMP WITH TIME ZONE, decodes to configured timezone.
class PostgresCarbonCodec extends ValueCodec<Carbon> {
  const PostgresCarbonCodec();

  @override
  Object? encode(Carbon? value) {
    if (value == null) {
      return TypedValue<DateTime>(Type.timestampTz, null, isSqlNull: true);
    }
    // Convert to DateTime then to UTC
    final dateTime = value.toDateTime();
    return TypedValue<DateTime>(Type.timestampTz, dateTime.toUtc());
  }

  @override
  Carbon? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;

    // Handle DateTime from postgres package
    if (unwrapped is DateTime) {
      final utcDateTime = unwrapped.isUtc ? unwrapped : unwrapped.toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone)
          as Carbon;
    }

    // Handle string parsing (fallback)
    if (unwrapped is String && unwrapped.isNotEmpty) {
      final utcDateTime = DateTime.parse(unwrapped).toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone)
          as Carbon;
    }

    throw StateError('Unsupported Carbon value "$value".');
  }
}

/// Codec for CarbonInterface instances with timezone-aware decoding.
/// Encodes to UTC TIMESTAMP WITH TIME ZONE, decodes to configured timezone.
class PostgresCarbonInterfaceCodec extends ValueCodec<CarbonInterface> {
  const PostgresCarbonInterfaceCodec();

  @override
  Object? encode(CarbonInterface? value) {
    if (value == null) {
      return TypedValue<DateTime>(Type.timestampTz, null, isSqlNull: true);
    }
    // CarbonInterface implements DateTime
    final dt = value as DateTime;
    return TypedValue<DateTime>(Type.timestampTz, dt.toUtc());
  }

  @override
  CarbonInterface? decode(Object? value) {
    final unwrapped = _unwrapTypedValue(value);
    if (unwrapped == null) return null;

    // Handle DateTime from postgres package
    if (unwrapped is DateTime) {
      final utcDateTime = unwrapped.isUtc ? unwrapped : unwrapped.toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone);
    }

    // Handle string parsing (fallback)
    if (unwrapped is String && unwrapped.isNotEmpty) {
      final utcDateTime = DateTime.parse(unwrapped).toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone);
    }

    throw StateError('Unsupported CarbonInterface value "$value".');
  }
}
