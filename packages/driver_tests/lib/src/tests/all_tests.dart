import 'advanced_query_tests.dart';
import 'driver_override_tests.dart';
import 'factory_inheritance_tests.dart';
import 'join_tests.dart';
import 'mutation_tests.dart';
import 'model_event_cancel_tests.dart';
import 'partial_entity_tests.dart';
import 'query_builder_tests.dart';
import 'query_tests.dart';
import 'repository_input_variations_tests.dart';
import 'repository_tests.dart';
import 'transaction_tests.dart';
import 'mixed_constructor_tests.dart';

/// Runs all driver tests against the provided [dataSource].
void runAllDriverTests() {
  runDriverQueryTests();
  runDriverJoinTests();
  runDriverAdvancedQueryTests();
  runDriverMutationTests();
  runDriverOverrideTests();
  runModelEventCancelTests();
  runDriverTransactionTests();
  runDriverJoinTests();
  runDriverOverrideTests();
  runDriverQueryBuilderTests();
  runDriverRepositoryTests();
  runRepositoryInputVariationsTests();
  runDriverFactoryInheritanceTests();
  runPartialEntityTests();
  runMixedConstructorTests();
}
