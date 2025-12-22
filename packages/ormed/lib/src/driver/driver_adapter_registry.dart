/// Provides a centralized registry for creating [DriverAdapter] instances.
library;

import '../orm_project_config.dart';
import 'driver_adapter.dart';

/// Signature for a factory that creates a [DriverAdapter] from a [DriverConfig].
typedef DriverAdapterFactory = DriverAdapter Function(DriverConfig config);

/// Registry of [DriverAdapter] factories keyed by driver type.
class DriverAdapterRegistry {
  DriverAdapterRegistry._();

  static final Map<String, DriverAdapterFactory> _factories = {};

  /// Registers a [factory] for the given [driverType].
  static void register(String driverType, DriverAdapterFactory factory) {
    _factories[driverType.toLowerCase()] = factory;
  }

  /// Creates a [DriverAdapter] for the given [config].
  ///
  /// Throws [StateError] if no factory is registered for the driver type.
  static DriverAdapter create(DriverConfig config) {
    final factory = _factories[config.type.toLowerCase()];
    if (factory == null) {
      throw StateError(
        'No DriverAdapter factory registered for driver type "${config.type}". '
        'Make sure you have imported the driver package and called its registration method.',
      );
    }
    return factory(config);
  }

  /// Whether a factory is registered for [driverType].
  static bool contains(String driverType) =>
      _factories.containsKey(driverType.toLowerCase());
}
