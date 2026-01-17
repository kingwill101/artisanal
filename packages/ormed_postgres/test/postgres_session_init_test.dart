import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  test('session and init options apply on connect', () async {
    final url =
        Platform.environment['POSTGRES_URL'] ??
        'postgres://postgres:postgres@localhost:6543/orm_test';

    final adapter = PostgresDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'postgres',
        options: {
          'url': url,
          'session': {'search_path': 'public'},
          'init': ["SET application_name = 'ormed_init'"],
        },
      ),
    );

    final searchPath = await adapter.queryRaw('SHOW search_path');
    final searchPathValue = searchPath.first.values.first.toString();
    expect(searchPathValue, contains('public'));

    final applicationName = await adapter.queryRaw('SHOW application_name');
    expect(applicationName.first.values.first, 'ormed_init');

    await adapter.close();
  });

  test('rejects invalid session option keys', () async {
    final url =
        Platform.environment['POSTGRES_URL'] ??
        'postgres://postgres:postgres@localhost:6543/orm_test';

    final adapter = PostgresDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'postgres',
        options: {
          'url': url,
          'session': {'search_path;DROP': 'public'},
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
        Platform.environment['POSTGRES_URL'] ??
        'postgres://postgres:postgres@localhost:6543/orm_test';

    final adapter = PostgresDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'postgres',
        options: {
          'url': url,
          'session': {'search_path': 'public'},
          'sessionAllowlist': ['application_name'],
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
        Platform.environment['POSTGRES_URL'] ??
        'postgres://postgres:postgres@localhost:6543/orm_test';

    final adapter = PostgresDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'postgres',
        options: {
          'url': url,
          'session': {'search_path': 'public'},
          'sessionAllowlist': ['search_path'],
        },
      ),
    );

    final searchPath = await adapter.queryRaw('SHOW search_path');
    final searchPathValue = searchPath.first.values.first.toString();
    expect(searchPathValue, contains('public'));

    await adapter.close();
  });
}
