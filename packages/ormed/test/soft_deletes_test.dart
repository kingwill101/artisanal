import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('SoftDeletes mixin', () {
    late ValueCodecRegistry registry;

    setUp(() {
      registry = ValueCodecRegistry.instance;
    });

    test('uses custom column overrides from metadata', () {
      final definition = CustomSoftDeleteOrmDefinition.definition;
      final removedOn = DateTime.utc(2024, 2, 10, 12, 30);

      final model = definition.fromMap({
        'id': 42,
        'title': 'Archived',
        'removed_on': removedOn,
      }, registry: registry);

      expect(model.deletedAt?.toUtc().toDateTime(), equals(removedOn));
      final attrs = model as ModelAttributes;
      expect(
        attrs.getAttribute<DateTime?>('removed_on')?.toUtc(),
        equals(removedOn),
      );
      expect(attrs.getSoftDeleteColumn(), equals('removed_on'));
    });

    test('applies soft delete scope to late-registered models', () async {
      final registry = ModelRegistry()..registerGeneratedModels();
      final driver = InMemoryQueryExecutor();
      final context = QueryContext(registry: registry, driver: driver);

      // Register AFTER context creation
      registry.register(CustomSoftDeleteOrmDefinition.definition);

      // Add test data with deleted and non-deleted records
      driver.register(CustomSoftDeleteOrmDefinition.definition, [
        $CustomSoftDelete(id: 1, title: 'Active'),
        $CustomSoftDelete(id: 2, title: 'Deleted')
          ..setAttribute('removed_on', DateTime.utc(2024)),
      ]);

      // Query should filter out soft-deleted records
      final results = await context.query<CustomSoftDelete>().get();
      expect(results, hasLength(1));
      expect(results.first.title, 'Active');
    });
  });
}
