import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

class WarningDriver extends InMemoryQueryExecutor {
  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'in_memory',
    requiresPrimaryKeyForQueryUpdate: false,
    queryUpdateRowIdentifier: QueryRowIdentifier(
      column: 'rowid',
      expression: 'rowid',
    ),
    capabilities: {
      DriverCapability.joins,
      DriverCapability.insertUsing,
      DriverCapability.adHocQueryUpdates,
      DriverCapability.schemaIntrospection,
      DriverCapability.advancedQueryBuilders,
      DriverCapability.sqlPreviews,
    },
  );
}

void main() {
  final registry = bootstrapOrm();

  test('emits warning when using fallback row identifier', () async {
    final context = QueryContext(registry: registry, driver: WarningDriver());
    final warnings = <QueryWarning>[];
    context.onWarning(warnings.add);

    await context.table('widgets').where('rowid', 1).update({'name': 'ok'});

    expect(warnings, isNotEmpty);
    expect(warnings.first.message, contains('fallback row identifier'));
  });
}
