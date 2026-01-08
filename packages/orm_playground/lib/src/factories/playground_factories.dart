import 'package:ormed/ormed.dart';

import '../models/user.dart';
import '../models/user.orm.dart';

const _userFactory = PlaygroundUserFactory();

class PlaygroundUserFactory extends ModelFactoryDefinition<User> {
  const PlaygroundUserFactory();

  @override
  Map<String, Object?> defaults() => const {
        'active': true,
      };

  @override
  Map<String, StateTransformer<User>> get states => const {
        'admin': _adminState,
        'guest': _guestState,
        'inactive': _inactiveState,
      };

  @override
  void configure(ModelFactoryBuilder<User> builder) {
    builder
      ..withGenerator('email', _emailGenerator)
      ..withGenerator('name', _nameGenerator);
  }

  static Object? _emailGenerator(
    FieldDefinition field,
    ModelFactoryGenerationContext<User> context,
  ) {
    final suffix = context.random.nextInt(9000) + 1000;
    return 'user_$suffix@playground.dev';
  }

  static Object? _nameGenerator(
    FieldDefinition field,
    ModelFactoryGenerationContext<User> context,
  ) {
    final suffix = context.random.nextInt(90) + 10;
    return 'Playground User $suffix';
  }

  static Map<String, Object?> _adminState(Map<String, Object?> attributes) =>
      const {
        'email': 'playground@routed.dev',
        'name': 'Playground Admin',
        'active': true,
      };

  static Map<String, Object?> _guestState(Map<String, Object?> attributes) =>
      const {
        'email': 'guest@routed.dev',
        'name': 'Guest Author',
        'active': true,
      };

  static Map<String, Object?> _inactiveState(Map<String, Object?> attributes) =>
      const {
        'active': false,
      };
}

void registerPlaygroundFactories() {
  ModelFactoryRegistry.register<User>(UserOrmDefinition.definition);
  ModelFactoryRegistry.registerFactory<User>(_userFactory);
}

ModelFactoryBuilder<User> adminUserFactory() =>
    _userFactory.stateNamed('admin');

ModelFactoryBuilder<User> guestUserFactory() =>
    _userFactory.stateNamed('guest');

ModelFactoryBuilder<User> inactiveUserFactory() =>
    _userFactory.stateNamed('inactive');
