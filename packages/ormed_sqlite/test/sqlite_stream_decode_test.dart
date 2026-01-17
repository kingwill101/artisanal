import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'support/sqlite_test_harness.dart';

class CountingCodec extends ValueCodec<String> {
  const CountingCodec(this.onDecode);

  final void Function() onDecode;

  @override
  Object? encode(String? value) => value;

  @override
  String? decode(Object? value) {
    onDecode();
    return value?.toString();
  }
}

Future<void> main() async {
  final harness = await createSqliteTestHarness();

  tearDownAll(() async {
    await harness.dispose();
  });

  ormedGroup('SQLite streaming decode', (dataSource) {
    test('stream decodes rows lazily', () async {
      var decodeCount = 0;
      final codec = CountingCodec(() => decodeCount++);
      dataSource.codecRegistry.registerCodec(
        key: 'CountingCodec',
        codec: codec,
      );
      dataSource.connection.driver.codecs.registerCodec(
        key: 'CountingCodec',
        codec: codec,
      );

      final table = 'stream_decode_${DateTime.now().microsecondsSinceEpoch}';
      final driver = dataSource.connection.driver;
      await driver.executeRaw(
        'CREATE TABLE $table (id INTEGER, payload TEXT)',
      );
      await driver.executeRaw(
        'INSERT INTO $table (id, payload) VALUES (?, ?)',
        [1, 'alpha'],
      );
      await driver.executeRaw(
        'INSERT INTO $table (id, payload) VALUES (?, ?)',
        [2, 'beta'],
      );
      await driver.executeRaw(
        'INSERT INTO $table (id, payload) VALUES (?, ?)',
        [3, 'gamma'],
      );

      try {
        final columns = const [
          AdHocColumn(name: 'id', columnName: 'id'),
          AdHocColumn(
            name: 'payload',
            columnName: 'payload',
            codecType: 'CountingCodec',
          ),
        ];

        final first = await dataSource.context
            .table(table, columns: columns)
            .orderBy('id')
            .streamRows()
            .first;

        expect(first.model['payload'], 'alpha');
        expect(decodeCount, equals(2));
      } finally {
        await driver.executeRaw('DROP TABLE IF EXISTS $table');
      }
    });
  });
}
