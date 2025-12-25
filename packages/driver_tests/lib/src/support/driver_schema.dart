library;

import 'package:driver_tests/orm_registry.g.dart';
import 'package:ormed/ormed.dart';

import '../migrations/migrations.dart';

/// Migration entries used in driver tests
final List<MigrationEntry> driverTestMigrationEntries = [
  MigrationEntry(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 1), 'create_users_table'),
    migration: const CreateUsersTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 2),
      'create_user_profiles_table',
    ),
    migration: const CreateUserProfilesTable(),
  ),
  MigrationEntry(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 3), 'create_authors_table'),
    migration: const CreateAuthorsTable(),
  ),
  MigrationEntry(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 4), 'create_posts_table'),
    migration: const CreatePostsTable(),
  ),
  MigrationEntry(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 5), 'create_tags_table'),
    migration: const CreateTagsTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 6),
      'create_post_tags_table',
    ),
    migration: const CreatePostTagsTable(),
  ),
  MigrationEntry(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 7), 'create_articles_table'),
    migration: const CreateArticlesTable(),
  ),
  MigrationEntry(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 8), 'create_photos_table'),
    migration: const CreatePhotosTable(),
  ),
  MigrationEntry(
    id: MigrationId(DateTime.utc(2023, 1, 1, 0, 0, 9), 'create_images_table'),
    migration: const CreateImagesTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 10),
      'create_comments_table',
    ),
    migration: const CreateCommentsTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 11),
      'create_driver_override_entries_table',
    ),
    migration: const CreateDriverOverrideEntriesTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 12),
      'create_settings_table',
    ),
    migration: const CreateSettingsTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 13),
      'create_serial_tests_table',
    ),
    migration: const CreateSerialTestsTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 14),
      'create_mutation_targets_table',
    ),
    migration: const CreateMutationTargetsTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 15),
      'create_derived_for_factories_table',
    ),
    migration: const CreateDerivedForFactoriesTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 16),
      'create_custom_soft_delete_models_table',
    ),
    migration: const CreateCustomSoftDeleteModelsTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 17),
      'create_scoped_users_table',
    ),
    migration: const CreateScopedUsersTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 18),
      'create_nullable_relations_test_table',
    ),
    migration: const CreateNullableRelationsTestTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 19),
      'create_mixed_constructors_table',
    ),
    migration: const CreateMixedConstructorsTable(),
  ),
  MigrationEntry(
    id: MigrationId(
      DateTime.utc(2023, 1, 1, 0, 0, 20),
      'create_taggables_table',
    ),
    migration: const CreateTaggablesTable(),
  ),
];

/// Create a test schema manager for driver tests
///
/// This creates a configured [TestSchemaManager] with all driver test
/// migrations and model definitions.
///
/// Example:
/// ```dart
/// final manager = createDriverTestSchemaManager(driver);
/// await manager.setup();
/// ```
TestSchemaManager createDriverTestSchemaManager(
  SchemaDriver driver, {
  String? schema,
}) {
  // Build migration descriptors with optional schema support
  final migrations = driverTestMigrationEntries.map((entry) {
    return MigrationDescriptor.fromMigration(
      id: entry.id,
      migration: entry.migration,
      defaultSchema: schema,
    );
  }).toList();

  return TestSchemaManager(
    schemaDriver: driver,
    modelDefinitions: generatedOrmModelDefinitions,
    migrations: migrations,
    ledgerTable: 'orm_migrations',
  );
}

/// Reset the driver test schema by tearing down and setting up again
///
/// This is equivalent to dropping all migrations and re-applying them.
/// Uses [TestSchemaManager] internally.
///
/// Example:
/// ```dart
/// await resetDriverTestSchema(driver);
/// ```
Future<void> resetDriverTestSchema(
  SchemaDriver driver, {
  String? schema,
}) async {
  final manager = createDriverTestSchemaManager(driver, schema: schema);
  await manager.teardown();
  await manager.setup();
}

/// Drop the driver test schema completely
///
/// This rolls back all applied migrations and purges any remaining tables.
/// Uses [TestSchemaManager] internally.
///
/// Example:
/// ```dart
/// await dropDriverTestSchema(driver);
/// ```
Future<void> dropDriverTestSchema(SchemaDriver driver, {String? schema}) async {
  final manager = createDriverTestSchemaManager(driver, schema: schema);
  await manager.teardown();
  await manager.purge();
}
