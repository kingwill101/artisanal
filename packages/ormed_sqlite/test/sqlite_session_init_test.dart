import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  test('session and init options apply on connect', () async {
    final adapter = SqliteDriverAdapter.custom(
      config: const DatabaseConfig(
        driver: 'sqlite',
        options: {
          'memory': true,
          'session': {'foreign_keys': true},
          'init': ['PRAGMA busy_timeout = 5000'],
        },
      ),
    );

    final foreignKeys = await adapter.queryRaw('PRAGMA foreign_keys');
    expect(foreignKeys.first.values.first, 1);

    final busyTimeout = await adapter.queryRaw('PRAGMA busy_timeout');
    expect(busyTimeout.first.values.first, 5000);

    await adapter.close();
  });
}
