// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'src/models/genre.dart';
import 'src/models/movie.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [
  GenreOrmDefinition.definition,
  MovieOrmDefinition.definition,
];

ModelRegistry buildOrmRegistry() => ModelRegistry()
  ..registerAll(_$ormModelDefinitions)
  ..registerTypeAlias<Genre>(_$ormModelDefinitions[0])
  ..registerTypeAlias<Movie>(_$ormModelDefinitions[1])
  ;

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    registerTypeAlias<Genre>(_$ormModelDefinitions[0]);
    registerTypeAlias<Movie>(_$ormModelDefinitions[1]);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using [Model.factory<T>()] to ensure definitions are available.
void registerOrmFactories() {
}

/// Combined setup: registers both model registry and factories.
/// Returns a ModelRegistry with all generated models registered.
ModelRegistry buildOrmRegistryWithFactories() {
  registerOrmFactories();
  return buildOrmRegistry();
}

/// Registers generated model event handlers.
void registerModelEventHandlers({EventBus? bus}) {
  // No model event handlers were generated.
}

/// Registers generated model scopes into a [ScopeRegistry].
void registerModelScopes({ScopeRegistry? scopeRegistry}) {
  // No model scopes were generated.
}

/// Bootstraps generated ORM pieces: registry, factories, event handlers, and scopes.
ModelRegistry bootstrapOrm({ModelRegistry? registry, EventBus? bus, ScopeRegistry? scopes, bool registerFactories = true, bool registerEventHandlers = true, bool registerScopes = true}) {
  final reg = registry ?? buildOrmRegistry();
  if (registry != null) {
    reg.registerGeneratedModels();
  }
  if (registerFactories) {
    registerOrmFactories();
  }
  if (registerEventHandlers) {
    registerModelEventHandlers(bus: bus);
  }
  if (registerScopes) {
    registerModelScopes(scopeRegistry: scopes);
  }
  return reg;
}
