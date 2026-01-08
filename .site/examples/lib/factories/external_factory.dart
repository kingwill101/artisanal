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

  static Map<String, Object?> _adminState(Map<String, Object?> attributes) =>
      {'name': 'Admin User'};
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
