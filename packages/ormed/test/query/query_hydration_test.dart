import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

class PreviewDriver extends InMemoryQueryExecutor {
  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'preview',
    capabilities: {
      DriverCapability.joins,
      DriverCapability.sqlPreviews,
      DriverCapability.advancedQueryBuilders,
    },
  );
}

void main() {
  final registry = bootstrapOrm();

  QueryContext context() =>
      QueryContext(registry: registry, driver: PreviewDriver());

  test('withoutAutoHydration disables auto-hydration in the plan', () {
    final plan = context()
        .query<Author>()
        .selectRaw('id')
        .groupBy(['id'])
        .withoutAutoHydration()
        .debugPlan();
    expect(plan.disableAutoHydration, isTrue);
  });
}
