import 'dart:io';

import 'package:ormed/migrations.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationSqlExporter', () {
    test(
      'renders and writes up/down sql files from schema plan previews',
      () async {
        final driver = SqliteDriverAdapter.inMemory();
        addTearDown(() async => driver.close());

        final exporter = MigrationSqlExporter(driver);

        final descriptor = MigrationDescriptor.fromMigration(
          id: MigrationId.parse('m_20250101000000_demo'),
          migration: _RawSqlMigration(),
        );

        final out = await Directory.systemTemp.createTemp('ormed_sql_exporter');
        addTearDown(() async => out.delete(recursive: true));

        await exporter.exportDescriptor(descriptor, outputRoot: out);

        final dir = Directory('${out.path}/${descriptor.id}');
        expect(dir.existsSync(), isTrue);

        final upSql = File('${dir.path}/up.sql').readAsStringSync();
        final downSql = File('${dir.path}/down.sql').readAsStringSync();

        expect(upSql, contains('CREATE TABLE'));
        expect(downSql, contains('DROP TABLE'));
        expect(upSql.endsWith('\n'), isTrue);
      },
    );
  });
}

class _RawSqlMigration extends Migration {
  @override
  void down(SchemaBuilder schema) {
    schema.raw('DROP TABLE demo;');
  }

  @override
  void up(SchemaBuilder schema) {
    schema.raw('CREATE TABLE demo (id INTEGER PRIMARY KEY);');
  }
}
