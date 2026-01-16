// External factory examples for documentation.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/factory_user.dart';
import '../models/factory_user.orm.dart';
import '../orm_registry.g.dart';

// #region factory-external-definition
class FactoryUserFactory extends ModelFactoryDefinition<FactoryUser> {
  const FactoryUserFactory();

  @override
  Map<String, Object?> defaults() => {
    'email': 'factory@example.com',
    'name': 'Factory User',
  };

  @override
  Map<String, StateTransformer<FactoryUser>> get states => {
    'admin': _adminState,
  };

  static Map<String, Object?> _adminState(Map<String, Object?> attributes) => {
    'name': 'Admin User',
  };
}
// #endregion factory-external-definition

// #region factory-external-registration
void registerExternalFactories() {
  registerOrmFactories();
  ModelFactoryRegistry.registerFactory<FactoryUser>(const FactoryUserFactory());
}
// #endregion factory-external-registration

// #region factory-external-usage
void useExternalFactory() {
  final user = Model.factory<FactoryUser>().make();
}
// #endregion factory-external-usage

// #region factory-external-state
void useExternalFactoryState() {
  final admin = ModelFactoryRegistry.externalFactoryFor<FactoryUser>()!
      .stateNamed('admin')
      .make();
}
// #endregion factory-external-state

// #region factory-external-with-hooks
class UserFactoryWithHooks extends ModelFactoryDefinition<FactoryUser> {
  const UserFactoryWithHooks();

  @override
  Map<String, Object?> defaults() => {
    'email': 'user@example.com',
    'name': 'Test User',
  };

  @override
  void configure(ModelFactoryBuilder<FactoryUser> builder) {
    // Setup callbacks for all instances created with this factory
    builder
        .afterMaking((user) {
          // Normalize email to lowercase
          user.setAttribute(
            'email',
            user.getAttribute('email').toString().toLowerCase(),
          );
        })
        .afterCreating((user) async {
          // Could send welcome email, setup profile, etc.
          print('User created with ID: ${user.id}');
        });
  }
}
// #endregion factory-external-with-hooks

// #region factory-external-multiple-states
class FactoryUserWithStates extends ModelFactoryDefinition<FactoryUser> {
  const FactoryUserWithStates();

  @override
  Map<String, Object?> defaults() => {
    'email': 'pending@example.com',
    'name': 'Pending User',
  };

  @override
  Map<String, StateTransformer<FactoryUser>> get states => {
    'pending': (attrs) => {
      'email': 'pending@example.com',
      'name': 'Pending User',
    },
    'active': (attrs) => {'email': 'active@example.com', 'name': 'Active User'},
    'suspended': (attrs) => {
      'email': 'suspended@example.com',
      'name': 'Suspended User',
    },
  };
}

void useMultipleStates() {
  // final pendingUser = ModelFactoryRegistry.externalFactoryFor<FactoryUser>()!
  //     .stateNamed('pending')
  //     .make();
  //
  // final activeUser = ModelFactoryRegistry.externalFactoryFor<FactoryUser>()!
  //     .stateNamed('active')
  //     .make();
}
// #endregion factory-external-multiple-states

// #region factory-external-composition
class AdminUserFactory extends ModelFactoryDefinition<FactoryUser> {
  const AdminUserFactory();

  @override
  Map<String, Object?> defaults() => {
    ...const FactoryUserFactory().defaults(),
    'role': 'admin',
    'active': true,
  };
}

class InactiveUserFactory extends ModelFactoryDefinition<FactoryUser> {
  const InactiveUserFactory();

  @override
  Map<String, Object?> defaults() => {
    ...const FactoryUserFactory().defaults(),
    'active': false,
  };
}

void useComposedFactories() {
  // final admin = Model.factory<FactoryUser>(
  //   definition: const AdminUserFactory(),
  // ).make();
  //
  // final inactive = Model.factory<FactoryUser>(
  //   definition: const InactiveUserFactory(),
  // ).make();
}
// #endregion factory-external-composition

// #region factory-external-custom-generator
class EmailGeneratorFactory extends ModelFactoryDefinition<FactoryUser> {
  const EmailGeneratorFactory();

  @override
  Map<String, Object?> defaults() => {'name': 'Test User'};

  @override
  ModelFactoryBuilder<FactoryUser> builder() {
    return super.builder().withGenerator('email', (field, context) {
      // Generate deterministic emails based on seed
      final index = context.seed ?? 0;
      return 'user_$index@test.example.com';
    });
  }
}
// #endregion factory-external-custom-generator

// #region factory-external-organization
// Recommended file structure:
// lib/
//   factories/
//     user_factory.dart
//     admin_factory.dart
//     post_factory.dart
//     comment_factory.dart
//   tests/
//     factories_test.dart
//
// In test setUp:
// void setUp() {
//   registerOrmFactories();
//   ModelFactoryRegistry.registerFactory<User>(const UserFactory());
//   ModelFactoryRegistry.registerFactory<Admin>(const AdminFactory());
//   // ... etc
// }
// #endregion factory-external-organization
