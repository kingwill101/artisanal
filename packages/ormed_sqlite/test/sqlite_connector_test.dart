import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invalid session option keys', () async {
    final connector = SqliteConnector();
    final endpoint = DatabaseEndpoint(
      driver: 'sqlite',
      options: const {
        'memory': true,
        'session': {'busy_timeout;DROP': 1000},
      },
    );
    expect(
      () => connector.connect(endpoint, ConnectionRole.primary),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('accepts allowlisted session option keys', () async {
    final connector = SqliteConnector();
    final endpoint = DatabaseEndpoint(
      driver: 'sqlite',
      options: const {
        'memory': true,
        'session': {'busy_timeout': 1000},
        'sessionAllowlist': ['busy_timeout'],
      },
    );
    final handle = await connector.connect(endpoint, ConnectionRole.primary);
    await handle.close();
  });
}
