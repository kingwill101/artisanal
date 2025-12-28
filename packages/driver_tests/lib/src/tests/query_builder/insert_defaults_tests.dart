import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

class _AdHocCodec extends ModelCodec<AdHocRow> {
  const _AdHocCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}

void runInsertDefaultsTests() {
  ormedGroup('Insert Defaults', (dataSource) {
    test('omits defaulted columns when values are not provided', () async {
      try {
        await dataSource.context.driver.executeRaw(
          'DELETE FROM insert_defaults',
        );
      } catch (_) {
        await dataSource.context
            .table(
              'insert_defaults',
              columns: const [AdHocColumn(name: 'id', isPrimaryKey: true)],
            )
            .delete();
      }

      final definition = ModelDefinition<AdHocRow>(
        modelName: 'InsertDefaultsRow',
        tableName: 'insert_defaults',
        fields: const [
          FieldDefinition(
            name: 'id',
            columnName: 'id',
            dartType: 'String',
            resolvedType: 'String',
            isPrimaryKey: true,
            isNullable: false,
          ),
          FieldDefinition(
            name: 'createdAt',
            columnName: 'created_at',
            dartType: 'DateTime',
            resolvedType: 'DateTime',
            isNullable: false,
          ),
          FieldDefinition(
            name: 'updatedAt',
            columnName: 'updated_at',
            dartType: 'DateTime',
            resolvedType: 'DateTime',
            isNullable: false,
          ),
        ],
        codec: const _AdHocCodec(),
        metadata: const ModelAttributesMetadata(timestamps: false),
      );

      final query = Query<AdHocRow>(
        definition: definition,
        context: dataSource.context,
        ignoreAllGlobalScopes: true,
      );

      await query.insertManyInputsRaw([
        {'id': 'default-test'},
      ]);

      final row = await dataSource.context
          .table('insert_defaults')
          .where('id', 'default-test')
          .first();

      expect(row, isNotNull);
      expect(row!['created_at'], isNotNull);
      expect(row['updated_at'], isNotNull);
    });
  });
}
