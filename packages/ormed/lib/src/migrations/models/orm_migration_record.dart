import 'package:ormed/ormed.dart';

part 'orm_migration_record.orm.dart';

/// Internal model used to track applied migrations in the database.
@OrmModel(table: 'orm_migrations')
class OrmMigrationRecord extends Model<OrmMigrationRecord> {
  /// Creates a new [OrmMigrationRecord].
  const OrmMigrationRecord({
    required this.id,
    required this.checksum,
    required this.appliedAt,
    required this.batch,
  });

  /// The unique identifier for the migration (usually the filename).
  @OrmField(isPrimaryKey: true)
  final String id;

  /// The MD5 checksum of the migration file at the time it was applied.
  @OrmField()
  final String checksum;

  /// The timestamp when the migration was applied.
  @OrmField(columnName: 'applied_at')
  final DateTime appliedAt;

  /// The batch number in which this migration was applied.
  @OrmField()
  final int batch;
}
