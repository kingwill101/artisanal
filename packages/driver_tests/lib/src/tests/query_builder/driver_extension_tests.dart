import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

const _demoSelectKey = 'demo_select';
const _demoWhereKey = 'demo_where';
const _demoOrderKey = 'demo_order';
const _demoGroupKey = 'demo_group';
const _demoHavingKey = 'demo_having';
const _demoJoinKey = 'demo_join';
const _missingKey = 'missing_extension';

class _TestDriverExtensions extends DriverExtension {
  const _TestDriverExtensions();

  @override
  List<DriverExtensionHandler> get handlers => [
    DriverExtensionHandler(
      kind: DriverExtensionKind.select,
      key: _demoSelectKey,
      compile: _compileSelect,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: _demoWhereKey,
      compile: _compileWhere,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.orderBy,
      key: _demoOrderKey,
      compile: _compileOrder,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.groupBy,
      key: _demoGroupKey,
      compile: _compileGroup,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.having,
      key: _demoHavingKey,
      compile: _compileHaving,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.join,
      key: _demoJoinKey,
      compile: _compileJoin,
    ),
  ];
}

DriverExtensionFragment _compileSelect(
  DriverExtensionContext context,
  Object? payload,
) {
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'demo_select($placeholder)',
    bindings: [payload],
  );
}

DriverExtensionFragment _compileWhere(
  DriverExtensionContext context,
  Object? payload,
) {
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'demo_where($placeholder)',
    bindings: [payload],
  );
}

DriverExtensionFragment _compileOrder(
  DriverExtensionContext context,
  Object? payload,
) {
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'demo_order($placeholder)',
    bindings: [payload],
  );
}

DriverExtensionFragment _compileGroup(
  DriverExtensionContext context,
  Object? payload,
) {
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'demo_group($placeholder)',
    bindings: [payload],
  );
}

DriverExtensionFragment _compileHaving(
  DriverExtensionContext context,
  Object? payload,
) {
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'demo_having($placeholder)',
    bindings: [payload],
  );
}

DriverExtensionFragment _compileJoin(
  DriverExtensionContext context,
  Object? payload,
) {
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'demo_join($placeholder)',
    bindings: [payload],
  );
}

class _DuplicateExtension extends DriverExtension {
  const _DuplicateExtension();

  @override
  List<DriverExtensionHandler> get handlers => [
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: 'dupe_key',
      compile: _compileWhere,
    ),
    DriverExtensionHandler(
      kind: DriverExtensionKind.where,
      key: 'dupe_key',
      compile: _compileWhere,
    ),
  ];
}

void runDriverExtensionTests() {
  group('Driver extension registry', () {
    test('rejects duplicate extension keys', () {
      expect(
        () => DriverExtensionRegistry(
          driverName: 'test',
          extensions: const [_DuplicateExtension()],
        ),
        throwsA(isA<DriverExtensionConflictError>()),
      );
    });
  });

  ormedGroup('Driver Extensions', (dataSource) {
    final driver = dataSource.options.driver;
    if (driver is! DriverExtensionHost) {
      fail('Driver ${driver.runtimeType} does not support extensions.');
    }
    (driver as DriverExtensionHost).registerExtensions(const [
      _TestDriverExtensions(),
    ]);

    test('compiles custom clause fragments', () {
      final preview = dataSource.context
          .query<Author>()
          .selectExtension(_demoSelectKey, payload: 'alpha', alias: 'score')
          .join('posts', (join) => join.onExtension(_demoJoinKey, 'bravo'))
          .whereExtension(_demoWhereKey, 'charlie')
          .groupByExtension(_demoGroupKey, 'delta')
          .havingExtension(_demoHavingKey, 'echo')
          .orderByExtension(_demoOrderKey, payload: 'foxtrot')
          .toSql();

      final quote = dataSource.options.driver.metadata.identifierQuote;
      expect(preview.sql, contains('demo_select'));
      expect(preview.sql, contains('AS ${quote}score$quote'));
      expect(preview.sql, contains('ON (demo_join'));
      expect(preview.sql, contains('WHERE (demo_where'));
      expect(preview.sql, contains('GROUP BY demo_group'));
      expect(preview.sql, contains('HAVING (demo_having'));
      expect(preview.sql, contains('ORDER BY demo_order'));
      expect(preview.parameters, [
        'alpha',
        'bravo',
        'charlie',
        'delta',
        'echo',
        'foxtrot',
      ]);
    });

    test('missing handler fails compilation', () {
      final plan = dataSource.context
          .query<Author>()
          .whereExtension(_missingKey, 1)
          .debugPlan();
      expect(
        () => dataSource.options.driver.describeQuery(plan),
        throwsA(isA<MissingDriverExtensionError>()),
      );
    });
  });
}
