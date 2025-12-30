import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('QueryGrammar substituteBindingsIntoRawSql', () {
    final grammar = _PreviewGrammar();

    test('escapes values and replaces placeholders', () {
      final sql =
          "SELECT * FROM users WHERE id = ? AND name = ? AND active = ?";
      final rendered = grammar.substituteBindingsIntoRawSql(sql, [
        42,
        "O'Connor",
        true,
      ]);
      expect(
        rendered,
        "SELECT * FROM users WHERE id = 42 AND name = 'O''Connor' AND active = 1",
      );
    });

    test('ignores placeholders inside string literals', () {
      const sql = "SELECT '?' AS literal, ? AS value";
      final rendered = grammar.substituteBindingsIntoRawSql(sql, [7]);
      expect(rendered, "SELECT '?' AS literal, 7 AS value");
    });
  });

  group('QueryGrammar tablePrefix', () {
    final grammar = _PreviewGrammar();

    test('applies prefix to unqualified table names', () {
      final definition = ModelDefinition<AdHocRow>(
        modelName: 'User',
        tableName: 'users',
        fields: const [],
        codec: const _AdHocCodec(),
      );
      final plan = QueryPlan(definition: definition, tablePrefix: 'app_');
      final compilation = grammar.compileSelect(plan);
      expect(compilation.sql, contains('FROM app_users'));
    });

    test('does not prefix schema-qualified tables', () {
      final definition = ModelDefinition<AdHocRow>(
        modelName: 'User',
        tableName: 'users',
        schema: 'public',
        fields: const [],
        codec: const _AdHocCodec(),
      );
      final plan = QueryPlan(definition: definition, tablePrefix: 'app_');
      final compilation = grammar.compileSelect(plan);
      expect(compilation.sql, contains('FROM public.users'));
    });

    test('applies prefix to join targets', () {
      final definition = ModelDefinition<AdHocRow>(
        modelName: 'User',
        tableName: 'users',
        fields: const [],
        codec: const _AdHocCodec(),
      );
      final plan = QueryPlan(
        definition: definition,
        tablePrefix: 'app_',
        joins: [
          JoinDefinition(
            type: JoinType.inner,
            target: JoinTarget.table('roles'),
            conditions: const [
              JoinCondition.column(
                left: 'users.role_id',
                operator: '=',
                right: 'roles.id',
              ),
            ],
          ),
        ],
      );
      final compilation = grammar.compileSelect(plan);
      expect(compilation.sql, contains('JOIN app_roles'));
    });
  });
}

class _PreviewGrammar extends QueryGrammar {}

class _AdHocCodec extends ModelCodec<AdHocRow> {
  const _AdHocCodec();

  @override
  Map<String, Object?> encode(AdHocRow model, ValueCodecRegistry registry) =>
      Map<String, Object?>.from(model);

  @override
  AdHocRow decode(Map<String, Object?> data, ValueCodecRegistry registry) =>
      AdHocRow(data);
}
