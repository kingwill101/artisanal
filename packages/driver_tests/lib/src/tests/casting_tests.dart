import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../models/models.dart';

class _TestEncrypter extends ValueEncrypter {
  const _TestEncrypter();

  @override
  String encrypt(String value) => base64.encode(utf8.encode(value));

  @override
  String decrypt(String value) => utf8.decode(base64.decode(value));
}

void runCastingTests() {
  ormedGroup('Casting', (dataSource) {
    const encrypter = _TestEncrypter();

    setUpAll(() {
      dataSource.codecRegistry.registerEncrypter(encrypter);
    });

    tearDownAll(() {
      dataSource.codecRegistry.clearEncrypter();
    });

    test('casts normalize values on fill and persistence', () async {
      final updatedAt = DateTime.utc(2024, 1, 16, 5, 20, 0);
      final model = CastSample(
        id: 1,
        name: 'Seed',
        isActive: false,
        visits: 0,
        ratio: 0,
        startedOn: DateTime.utc(2024, 1, 1),
        updatedAt: updatedAt,
        amount: Decimal.parse('0.00'),
        status: CastStatus.draft,
        secret: 'seed',
      ).toTracked();

      model.fill({
        'name': 123,
        'is_active': 'true',
        'visits': '12',
        'ratio': '3.14',
        'started_on': '2024-01-10',
        'updated_at': updatedAt.toIso8601String(),
        'amount': '123.45',
        'status': 'active',
        'secret': 'top secret',
      }, registry: dataSource.codecRegistry);

      await dataSource.repo<CastSample>().insert(model);

      final fetched = await dataSource.context
          .query<CastSample>()
          .where('id', 1)
          .first();
      final $CastSample tracked = fetched!.toTracked();

      expect(tracked.name, '123');
      expect(tracked.isActive, isTrue);
      expect(tracked.visits, 12);
      expect(tracked.ratio, closeTo(3.14, 0.0001));
      expect(tracked.startedOn.year, 2024);
      expect(tracked.startedOn.month, 1);
      expect(tracked.startedOn.day, 10);
      expect(tracked.startedOn.hour, 0);
      expect(tracked.startedOn.minute, 0);
      expect(tracked.updatedAt.toUtc(), equals(updatedAt));
      expect(tracked.amount, Decimal.parse('123.45'));
      expect(tracked.status, CastStatus.active);
      expect(tracked.secret, 'top secret');

      final payload = tracked.toArray();
      expect(payload['amount'], '123.45');
      expect(payload['status'], 'active');
      expect(payload['secret'], 'top secret');
      expect(payload['is_active'], true);
    });

    test('casts numeric timestamps to datetime', () async {
      const seconds = 1700000000;
      final expected = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );
      final model = CastSample(
        id: 2,
        name: 'Numeric Timestamp',
        isActive: true,
        visits: 1,
        ratio: 1.2,
        startedOn: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
        amount: Decimal.parse('1.00'),
        status: CastStatus.draft,
        secret: 'secret',
      ).toTracked();

      model.fill({'updated_at': seconds}, registry: dataSource.codecRegistry);
      await dataSource.repo<CastSample>().insert(model);

      final fetched = await dataSource.context
          .query<CastSample>()
          .where('id', 2)
          .first();
      final tracked = fetched!.toTracked();

      expect(tracked.updatedAt.toUtc(), equals(expected));
    });

    test('collection casting ensures typed collections are returned', () async {
      final definition = AdHocModelDefinition(tableName: 'ad_hoc_collections');
      definition.registerColumn(
        const AdHocColumn(name: 'id', isPrimaryKey: true, dartType: 'int'),
      );
      definition.registerColumn(
        const AdHocColumn(
          name: 'tags',
          dartType: 'List<String>',
          codecType: 'json',
        ),
      );
      definition.registerColumn(
        const AdHocColumn(
          name: 'scores',
          dartType: 'List<int>',
          codecType: 'json',
        ),
      );
      definition.registerColumn(
        const AdHocColumn(
          name: 'metadata',
          dartType: 'Map<String, dynamic>',
          codecType: 'json',
        ),
      );

      final schemaDriver = dataSource.context.driver as SchemaDriver;

      // We might need to create the table first
      final dropBuilder = SchemaBuilder();
      dropBuilder.drop('ad_hoc_collections', ifExists: true);
      await schemaDriver.applySchemaPlan(dropBuilder.build());

      final createBuilder = SchemaBuilder();
      createBuilder.create('ad_hoc_collections', (table) {
        table.integer('id').primaryKey();
        table.json('tags').nullable();
        table.json('scores').nullable();
        table.json('metadata').nullable();
      });
      await schemaDriver.applySchemaPlan(createBuilder.build());

      final query = dataSource.context.queryFromDefinition(definition);

      await query.create({
        'id': 1,
        'tags': ['a', 'b', 'c'],
        'scores': [1, 2, 3],
        'metadata': {'key': 'value', 'nested': {'a': 1}},
      });

      final row = await query.where('id', 1).first();
      expect(row, isNotNull);

      // Direct access via [] which uses the decoded value from _AdHocCodec
      final tags = row!['tags'];
      final scores = row['scores'];
      final metadata = row['metadata'];

      expect(tags, equals(['a', 'b', 'c']));
      expect(tags, isA<List<String>>());

      expect(scores, equals([1, 2, 3]));
      expect(scores, isA<List<int>>());

      expect(metadata, equals({'key': 'value', 'nested': {'a': 1}}));
      expect(metadata, isA<Map<String, dynamic>>());
    });
  });
}
