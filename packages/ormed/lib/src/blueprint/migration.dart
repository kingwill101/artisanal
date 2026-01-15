import 'dart:async' show FutureOr;
import 'dart:convert';

import 'package:hashlib/hashlib.dart';

import 'schema_builder.dart';
import 'schema_plan.dart';
import 'schema_snapshot.dart';

/// Directions supported by a migration lifecycle.
enum MigrationDirection { up, down }

/// Base contract migrations extend.
abstract class Migration {
  const Migration();

  FutureOr<void> up(SchemaBuilder schema);

  FutureOr<void> down(SchemaBuilder schema);

  /// Builds a plan for the requested direction.
  SchemaPlan plan(
    MigrationDirection direction, {
    SchemaSnapshot? snapshot,
    String? defaultSchema,
    String? tablePrefix,
  }) {
    final builder = SchemaBuilder(
      snapshot: snapshot,
      defaultSchema: defaultSchema,
      tablePrefix: tablePrefix,
    );
    switch (direction) {
      case MigrationDirection.up:
        up(builder);
        break;
      case MigrationDirection.down:
        down(builder);
        break;
    }

    final description = '${direction.name}:${runtimeType.toString()}';
    return builder.build(description: description);
  }
}

/// Value object representing a migration identifier derived from its file name.
class MigrationId {
  const MigrationId(this.timestamp, this.slug);

  factory MigrationId.parse(String value) {
    // Strip "m_" prefix if present (new format)
    var normalized = value;
    if (value.startsWith('m_')) {
      normalized = value.substring(2);
    }

    // New format: m_YYYYMMDDHHMMSS_slug
    // Old format: YYYY_MM_DD_HHMMSS_slug (for backward compatibility)

    // Check if it's the new format (14 consecutive digits followed by underscore)
    final newFormatMatch = RegExp(r'^(\d{14})_(.+)$').firstMatch(normalized);
    if (newFormatMatch != null) {
      final timestampStr = newFormatMatch.group(1)!;
      final slug = newFormatMatch.group(2)!;

      final year = int.tryParse(timestampStr.substring(0, 4));
      final month = int.tryParse(timestampStr.substring(4, 6));
      final day = int.tryParse(timestampStr.substring(6, 8));
      final hour = int.tryParse(timestampStr.substring(8, 10));
      final minute = int.tryParse(timestampStr.substring(10, 12));
      final second = int.tryParse(timestampStr.substring(12, 14));

      if (year == null ||
          month == null ||
          day == null ||
          hour == null ||
          minute == null ||
          second == null) {
        throw FormatException('Invalid migration timestamp in "$value".');
      }

      final timestamp = DateTime.utc(year, month, day, hour, minute, second);
      return MigrationId(timestamp, slug);
    }

    // Fall back to old format: YYYY_MM_DD_HHMMSS_slug
    final segments = normalized.split('_');
    if (segments.length < 5) {
      throw FormatException(
        'Invalid migration id "$value". Expected m_YYYYMMDDHHMMSS_slug or YYYY_MM_DD_HHMMSS_slug format.',
      );
    }

    final year = int.tryParse(segments[0]);
    final month = int.tryParse(segments[1]);
    final day = int.tryParse(segments[2]);
    final time = segments[3];

    if (year == null || month == null || day == null || time.length != 6) {
      throw FormatException('Invalid migration timestamp in "$value".');
    }

    final hour = int.tryParse(time.substring(0, 2));
    final minute = int.tryParse(time.substring(2, 4));
    final second = int.tryParse(time.substring(4, 6));

    if (hour == null || minute == null || second == null) {
      throw FormatException('Invalid migration time in "$value".');
    }

    final timestamp = DateTime.utc(year, month, day, hour, minute, second);
    final slug = segments.sublist(4).join('_');

    return MigrationId(timestamp, slug);
  }

  final DateTime timestamp;
  final String slug;

  /// Generate filename in new format: m_YYYYMMDDHHMMSS_slug.dart
  String toFileName() => 'm_${_formatTimestampCompact(timestamp)}_$slug';

  @override
  String toString() => toFileName();

  @override
  bool operator ==(Object other) {
    return other is MigrationId &&
        other.timestamp == timestamp &&
        other.slug == slug;
  }

  @override
  int get hashCode => Object.hash(timestamp, slug);
}

/// Snapshot of a compiled migration ready to be logged inside the ledger.
class MigrationDescriptor {
  MigrationDescriptor({
    required this.id,
    required this.up,
    required this.down,
    required this.checksum,
  });

  factory MigrationDescriptor.fromMigration({
    required MigrationId id,
    required Migration migration,
    String? defaultSchema,
    String? tablePrefix,
  }) {
    final upPlan = migration.plan(
      MigrationDirection.up,
      defaultSchema: defaultSchema,
      tablePrefix: tablePrefix,
    );
    final downPlan = migration.plan(
      MigrationDirection.down,
      defaultSchema: defaultSchema,
      tablePrefix: tablePrefix,
    );
    final checksum = _checksumForPlans(upPlan, downPlan);
    return MigrationDescriptor(
      id: id,
      up: upPlan,
      down: downPlan,
      checksum: checksum,
    );
  }

  final MigrationId id;
  final SchemaPlan up;
  final SchemaPlan down;
  final String checksum;

  Map<String, Object?> toJson() => {
    'id': id.toString(),
    'checksum': checksum,
    'up': up.toJson(),
    'down': down.toJson(),
  };

  factory MigrationDescriptor.fromJson(Map<String, Object?> json) {
    final id = MigrationId.parse(json['id'] as String);
    final up = SchemaPlan.fromJson(json['up'] as Map<String, Object?>);
    final down = SchemaPlan.fromJson(json['down'] as Map<String, Object?>);
    return MigrationDescriptor(
      id: id,
      checksum: json['checksum'] as String,
      up: up,
      down: down,
    );
  }
}

String _checksumForPlans(SchemaPlan up, SchemaPlan down) {
  final payload = jsonEncode({'up': up.toJson(), 'down': down.toJson()});
  return sha1.string(payload).toString();
}

/// Format timestamp as YYYYMMDDHHMMSS (14 digits, no separators)
String _formatTimestampCompact(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$year$month$day$hour$minute$second';
}

/// Ties a [MigrationId] to a [Migration] instance.
///
/// Used to register migrations with their IDs for proper ordering.
/// The CLI generates these automatically in migrations.dart file.
///
/// Example:
/// ```dart
/// final entries = [
///   MigrationEntry(
///     id: MigrationId.parse('m_20251130100953_create_users'),
///     migration: const CreateUsersTable(),
///   ),
///   MigrationEntry(
///     id: MigrationId.parse('m_20251130101500_add_index'),
///     migration: const AddEmailIndex(),
///   ),
/// ];
///
/// // Convert to descriptors (sorted by timestamp)
/// final descriptors = MigrationEntry.buildDescriptors(entries);
/// ```
class MigrationEntry {
  const MigrationEntry({required this.id, required this.migration});

  final MigrationId id;
  final Migration migration;

  /// Convert a list of entries to migration descriptors.
  ///
  /// Migrations are sorted by their ID timestamp (oldest first),
  /// ensuring they run in the correct dependency order.
  static List<MigrationDescriptor> buildDescriptors(
    List<MigrationEntry> entries,
  ) {
    // Sort by timestamp (oldest first)
    final sorted = List<MigrationEntry>.from(entries)
      ..sort((a, b) => a.id.timestamp.compareTo(b.id.timestamp));

    return List.unmodifiable(
      sorted.map(
        (entry) => MigrationDescriptor.fromMigration(
          id: entry.id,
          migration: entry.migration,
        ),
      ),
    );
  }
}
