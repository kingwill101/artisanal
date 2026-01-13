import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';

/// A simple mock driver for unit testing core ormed logic.
class MockDriver extends InMemoryQueryExecutor {
  MockDriver({super.codecRegistry});

  @override
  DriverMetadata get metadata => const DriverMetadata(
        name: 'mock',
        capabilities: {
          DriverCapability.joins,
          DriverCapability.sqlPreviews,
          DriverCapability.advancedQueryBuilders,
        },
      );
}

/// Helper to bootstrap a generic ORM context for tests.
QueryContext mockContext() {
  final registry = bootstrapOrm();
  return QueryContext(
    registry: registry,
    driver: MockDriver(),
  );
}
