import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:ormed_cli/src/commands/make/make_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MakeCommand (sql migrations)', () {
    late Directory repoRoot;
    late Directory scratchDir;
    late File ormConfig;

    setUp(() async {
      repoRoot = Directory.current;
      final scratchParent = Directory(
        p.join(repoRoot.path, '.dart_tool', 'ormed_cli_tests'),
      );
      if (!scratchParent.existsSync()) {
        scratchParent.createSync(recursive: true);
      }
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          'make_case_${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..createSync(recursive: true);

      ormConfig = File(p.join(scratchDir.path, 'ormed.yaml'))
        ..writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: database.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
''');

      // Minimal pubspec so findProjectRoot works.
      File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

      // Seed the migrations registry template.
      final registryFile = File(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations.dart'),
      );
      registryFile.parent.createSync(recursive: true);
      registryFile.writeAsStringSync('''
import 'dart:convert';

import 'package:ormed/migrations.dart';

// <ORM-MIGRATION-IMPORTS>
// </ORM-MIGRATION-IMPORTS>

final List<MigrationEntry> _entries = [
  // <ORM-MIGRATION-REGISTRY>
  // </ORM-MIGRATION-REGISTRY>
];

List<MigrationDescriptor> buildMigrations() =>
    MigrationEntry.buildDescriptors(_entries);

void main(List<String> args) {
  if (args.contains('--dump-json')) {
    final payload = buildMigrations().map((m) => m.toJson()).toList();
    print(jsonEncode(payload));
    return;
  }
}
''');

      Directory.current = scratchDir;
    });

    tearDown(() async {
      Directory.current = repoRoot;
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    Future<void> runMake(List<String> args) async {
      final runner = CommandRunner<void>('ormed', 'ORM CLI')
        ..addCommand(MakeCommand());
      await runner.run([
        'make',
        ...args,
        '--config',
        p.relative(ormConfig.path, from: Directory.current.path),
      ]);
    }

    test('creates SQL migration directory and registers it', () async {
      await runMake(['--name', 'create_users_table', '--format', 'sql']);

      final migrationsDir = Directory(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations'),
      );
      expect(migrationsDir.existsSync(), isTrue);

      final createdDir = migrationsDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path)
          .singleWhere(
            (path) => p.basename(path).endsWith('_create_users_table'),
          );

      expect(File(p.join(createdDir, 'up.sql')).existsSync(), isTrue);
      expect(File(p.join(createdDir, 'down.sql')).existsSync(), isTrue);

      final registryText = File(
        p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations.dart'),
      ).readAsStringSync();
      expect(registryText, contains('SqlFileMigration('));
      expect(registryText, contains("downPath: 'migrations/"));
      expect(registryText, contains("upPath: 'migrations/"));
    });

    test(
      'defaults to SQL when ormed.yaml sets migrations.format: sql',
      () async {
        ormConfig.writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: database.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
  format: sql
''');

        await runMake(['--name', 'create_posts_table']);

        final migrationsDir = Directory(
          p.join(scratchDir.path, 'lib', 'src', 'database', 'migrations'),
        );
        final created = migrationsDir.listSync().whereType<Directory>().any(
          (d) => p.basename(d.path).endsWith('_create_posts_table'),
        );
        expect(created, isTrue);
      },
    );
  });
}
