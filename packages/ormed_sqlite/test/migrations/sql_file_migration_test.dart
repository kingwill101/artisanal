import 'dart:io';

import 'package:ormed/migrations.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('SqlFileMigration', () {
    late SqliteDriverAdapter driver;
    late SqlMigrationLedger ledger;

    setUp(() async {
      driver = SqliteDriverAdapter.inMemory();
      ledger = SqlMigrationLedger(driver);
    });

    tearDown(() async {
      await driver.close();
    });

    test('applies and rolls back sql migrations', () async {
      final dir = await Directory.systemTemp.createTemp(
        'ormed_sql_file_migration',
      );
      addTearDown(() async => dir.delete(recursive: true));

      final up = File('${dir.path}/up.sql')
        ..writeAsStringSync('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  email TEXT NOT NULL
);
''');
      final down = File('${dir.path}/down.sql')
        ..writeAsStringSync('DROP TABLE users;');

      final id = MigrationId.parse('m_20250101000000_create_users_table');
      final descriptors = [
        MigrationDescriptor.fromMigration(
          id: id,
          migration: SqlFileMigration(
            upPath: up.uri.toString(),
            downPath: down.uri.toString(),
          ),
        ),
      ];

      final runner = MigrationRunner(
        schemaDriver: driver,
        ledger: ledger,
        migrations: descriptors,
      );

      await runner.applyAll();
      expect(await SchemaInspector(driver).hasTable('users'), isTrue);

      await runner.rollback();
      expect(await SchemaInspector(driver).hasTable('users'), isFalse);
    });

    test('throws checksum mismatch when sql changes after apply', () async {
      final dir = await Directory.systemTemp.createTemp(
        'ormed_sql_file_migration_checksum',
      );
      addTearDown(() async => dir.delete(recursive: true));

      final up = File('${dir.path}/up.sql')
        ..writeAsStringSync('CREATE TABLE t (id INTEGER PRIMARY KEY);');
      final down = File('${dir.path}/down.sql')
        ..writeAsStringSync('DROP TABLE t;');

      final id = MigrationId.parse('m_20250101000001_create_t');
      MigrationDescriptor buildDescriptor() =>
          MigrationDescriptor.fromMigration(
            id: id,
            migration: SqlFileMigration(
              upPath: up.uri.toString(),
              downPath: down.uri.toString(),
            ),
          );

      final runner = MigrationRunner(
        schemaDriver: driver,
        ledger: ledger,
        migrations: [buildDescriptor()],
      );
      await runner.applyAll();

      // Change the SQL after the migration is applied.
      up.writeAsStringSync(
        'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT);',
      );

      final second = MigrationRunner(
        schemaDriver: driver,
        ledger: ledger,
        migrations: [buildDescriptor()],
      );
      await expectLater(() => second.applyAll(), throwsA(isA<StateError>()));
    });
  });
}
