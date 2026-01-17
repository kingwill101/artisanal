import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

void main() {
  test('session and init options apply on connect', () async {
    final url =
        Platform.environment['MYSQL_URL'] ??
        'mysql://root:secret@localhost:6605/orm_test';
    final connectionInfo = MySqlConnectionInfo.fromUrl(
      url,
      secureByDefault: true,
    );

    final adapter = MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {
          'url': url,
          'ssl': connectionInfo.secure,
          'session': {'sql_notes': 0},
          'init': ["SET time_zone = '+02:00'"],
        },
      ),
    );

    final rows = await adapter.queryRaw(
      'SELECT @@sql_notes AS sql_notes, @@time_zone AS time_zone',
    );
    final row = rows.first;
    final sqlNotesValue = row['sql_notes'];
    final sqlNotes = sqlNotesValue is int
        ? sqlNotesValue
        : int.tryParse(sqlNotesValue.toString());
    expect(sqlNotes, 0);

    expect(row['time_zone'], '+02:00');

    await adapter.close();
  });

  test('rejects invalid session option keys', () async {
    final url =
        Platform.environment['MYSQL_URL'] ??
        'mysql://root:secret@localhost:6605/orm_test';
    final connectionInfo = MySqlConnectionInfo.fromUrl(
      url,
      secureByDefault: true,
    );

    final adapter = MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {
          'url': url,
          'ssl': connectionInfo.secure,
          'session': {'sql_notes;DROP': 0},
        },
      ),
    );
    try {
      await expectLater(
        () => adapter.queryRaw('SELECT 1'),
        throwsA(isA<ArgumentError>()),
      );
    } finally {
      await adapter.close();
    }
  });

  test('rejects session option keys not in allowlist', () async {
    final url =
        Platform.environment['MYSQL_URL'] ??
        'mysql://root:secret@localhost:6605/orm_test';
    final connectionInfo = MySqlConnectionInfo.fromUrl(
      url,
      secureByDefault: true,
    );

    final adapter = MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {
          'url': url,
          'ssl': connectionInfo.secure,
          'session': {'sql_notes': 0},
          'sessionAllowlist': ['sql_mode'],
        },
      ),
    );
    try {
      await expectLater(
        () => adapter.queryRaw('SELECT 1'),
        throwsA(isA<ArgumentError>()),
      );
    } finally {
      await adapter.close();
    }
  });

  test('accepts allowlisted session option keys', () async {
    final url =
        Platform.environment['MYSQL_URL'] ??
        'mysql://root:secret@localhost:6605/orm_test';
    final connectionInfo = MySqlConnectionInfo.fromUrl(
      url,
      secureByDefault: true,
    );

    final adapter = MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {
          'url': url,
          'ssl': connectionInfo.secure,
          'session': {'sql_notes': 0},
          'sessionAllowlist': ['sql_notes'],
        },
      ),
    );

    final rows = await adapter.queryRaw('SELECT @@sql_notes AS sql_notes');
    final sqlNotesValue = rows.first['sql_notes'];
    final sqlNotes = sqlNotesValue is int
        ? sqlNotesValue
        : int.tryParse(sqlNotesValue.toString());
    expect(sqlNotes, 0);

    await adapter.close();
  });
}
