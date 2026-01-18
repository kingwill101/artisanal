import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

class CachingDriver extends InMemoryQueryExecutor {
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

  test('flushOnWrite invalidates cached results after mutations', () async {
    final context = QueryContext(
      registry: registry,
      driver: CachingDriver(),
      cacheInvalidationPolicy: QueryCacheInvalidationPolicy.flushOnWrite,
    );

    await context.query<Author>().remember(const Duration(minutes: 5)).get();
    expect(context.queryCacheStats.totalEntries, greaterThan(0));

    await context.query<Author>().update({'name': 'Updated'});
    expect(context.queryCacheStats.totalEntries, equals(0));
  });
}
