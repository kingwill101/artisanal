// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'src/models/accessor_user.dart';
import 'src/models/active_user.dart';
import 'src/models/article.dart';
import 'src/models/attribute_user.dart';
import 'src/models/author.dart';
import 'src/models/cast_sample.dart';
import 'src/models/comment.dart';
import 'src/models/custom_soft_delete.dart';
import 'src/models/derived_for_factory.dart';
import 'src/models/driver_override_entry.dart';
import 'src/models/driver_override.dart';
import 'src/models/event_model.dart';
import 'src/models/image.dart';
import 'src/models/json_value_record.dart';
import 'src/models/mixed_constructor.dart';
import 'src/models/mutation_target.dart';
import 'src/models/named_constructor_model.dart';
import 'src/models/no_factory.dart';
import 'src/models/nullable_relations_test.dart';
import 'src/models/photo.dart';
import 'src/models/post.dart';
import 'src/models/post_tag.dart';
import 'src/models/predicate_collision.dart';
import 'src/models/scoped_user.dart';
import 'src/models/serial_test.dart';
import 'src/models/settings.dart';
import 'src/models/tag.dart';
import 'src/models/taggable.dart';
import 'src/models/unique_user.dart';
import 'src/models/user.dart';
import 'src/models/user_profile.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [
  AccessorUserOrmDefinition.definition,
  ActiveUserOrmDefinition.definition,
  ArticleOrmDefinition.definition,
  AttributeUserOrmDefinition.definition,
  AuthorOrmDefinition.definition,
  CastSampleOrmDefinition.definition,
  CommentOrmDefinition.definition,
  CustomSoftDeleteOrmDefinition.definition,
  DerivedForFactoryOrmDefinition.definition,
  DriverOverrideEntryOrmDefinition.definition,
  DriverOverrideModelOrmDefinition.definition,
  EventModelOrmDefinition.definition,
  ImageOrmDefinition.definition,
  JsonValueRecordOrmDefinition.definition,
  MixedConstructorModelOrmDefinition.definition,
  MutationTargetOrmDefinition.definition,
  NamedConstructorModelOrmDefinition.definition,
  NoFactoryOrmDefinition.definition,
  NullableRelationsTestOrmDefinition.definition,
  PhotoOrmDefinition.definition,
  PostOrmDefinition.definition,
  PostTagOrmDefinition.definition,
  PredicateCollisionOrmDefinition.definition,
  ScopedUserOrmDefinition.definition,
  SerialTestOrmDefinition.definition,
  SettingOrmDefinition.definition,
  TagOrmDefinition.definition,
  TaggableOrmDefinition.definition,
  UniqueUserOrmDefinition.definition,
  UserOrmDefinition.definition,
  UserProfileOrmDefinition.definition,
];

ModelRegistry buildOrmRegistry() => ModelRegistry()
  ..registerAll(_$ormModelDefinitions)
  ..registerTypeAlias<AccessorUser>(_$ormModelDefinitions[0])
  ..registerTypeAlias<ActiveUser>(_$ormModelDefinitions[1])
  ..registerTypeAlias<Article>(_$ormModelDefinitions[2])
  ..registerTypeAlias<AttributeUser>(_$ormModelDefinitions[3])
  ..registerTypeAlias<Author>(_$ormModelDefinitions[4])
  ..registerTypeAlias<CastSample>(_$ormModelDefinitions[5])
  ..registerTypeAlias<Comment>(_$ormModelDefinitions[6])
  ..registerTypeAlias<CustomSoftDelete>(_$ormModelDefinitions[7])
  ..registerTypeAlias<DerivedForFactory>(_$ormModelDefinitions[8])
  ..registerTypeAlias<DriverOverrideEntry>(_$ormModelDefinitions[9])
  ..registerTypeAlias<DriverOverrideModel>(_$ormModelDefinitions[10])
  ..registerTypeAlias<EventModel>(_$ormModelDefinitions[11])
  ..registerTypeAlias<Image>(_$ormModelDefinitions[12])
  ..registerTypeAlias<JsonValueRecord>(_$ormModelDefinitions[13])
  ..registerTypeAlias<MixedConstructorModel>(_$ormModelDefinitions[14])
  ..registerTypeAlias<MutationTarget>(_$ormModelDefinitions[15])
  ..registerTypeAlias<NamedConstructorModel>(_$ormModelDefinitions[16])
  ..registerTypeAlias<NoFactory>(_$ormModelDefinitions[17])
  ..registerTypeAlias<NullableRelationsTest>(_$ormModelDefinitions[18])
  ..registerTypeAlias<Photo>(_$ormModelDefinitions[19])
  ..registerTypeAlias<Post>(_$ormModelDefinitions[20])
  ..registerTypeAlias<PostTag>(_$ormModelDefinitions[21])
  ..registerTypeAlias<PredicateCollision>(_$ormModelDefinitions[22])
  ..registerTypeAlias<ScopedUser>(_$ormModelDefinitions[23])
  ..registerTypeAlias<SerialTest>(_$ormModelDefinitions[24])
  ..registerTypeAlias<Setting>(_$ormModelDefinitions[25])
  ..registerTypeAlias<Tag>(_$ormModelDefinitions[26])
  ..registerTypeAlias<Taggable>(_$ormModelDefinitions[27])
  ..registerTypeAlias<UniqueUser>(_$ormModelDefinitions[28])
  ..registerTypeAlias<User>(_$ormModelDefinitions[29])
  ..registerTypeAlias<UserProfile>(_$ormModelDefinitions[30]);

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    registerTypeAlias<AccessorUser>(_$ormModelDefinitions[0]);
    registerTypeAlias<ActiveUser>(_$ormModelDefinitions[1]);
    registerTypeAlias<Article>(_$ormModelDefinitions[2]);
    registerTypeAlias<AttributeUser>(_$ormModelDefinitions[3]);
    registerTypeAlias<Author>(_$ormModelDefinitions[4]);
    registerTypeAlias<CastSample>(_$ormModelDefinitions[5]);
    registerTypeAlias<Comment>(_$ormModelDefinitions[6]);
    registerTypeAlias<CustomSoftDelete>(_$ormModelDefinitions[7]);
    registerTypeAlias<DerivedForFactory>(_$ormModelDefinitions[8]);
    registerTypeAlias<DriverOverrideEntry>(_$ormModelDefinitions[9]);
    registerTypeAlias<DriverOverrideModel>(_$ormModelDefinitions[10]);
    registerTypeAlias<EventModel>(_$ormModelDefinitions[11]);
    registerTypeAlias<Image>(_$ormModelDefinitions[12]);
    registerTypeAlias<JsonValueRecord>(_$ormModelDefinitions[13]);
    registerTypeAlias<MixedConstructorModel>(_$ormModelDefinitions[14]);
    registerTypeAlias<MutationTarget>(_$ormModelDefinitions[15]);
    registerTypeAlias<NamedConstructorModel>(_$ormModelDefinitions[16]);
    registerTypeAlias<NoFactory>(_$ormModelDefinitions[17]);
    registerTypeAlias<NullableRelationsTest>(_$ormModelDefinitions[18]);
    registerTypeAlias<Photo>(_$ormModelDefinitions[19]);
    registerTypeAlias<Post>(_$ormModelDefinitions[20]);
    registerTypeAlias<PostTag>(_$ormModelDefinitions[21]);
    registerTypeAlias<PredicateCollision>(_$ormModelDefinitions[22]);
    registerTypeAlias<ScopedUser>(_$ormModelDefinitions[23]);
    registerTypeAlias<SerialTest>(_$ormModelDefinitions[24]);
    registerTypeAlias<Setting>(_$ormModelDefinitions[25]);
    registerTypeAlias<Tag>(_$ormModelDefinitions[26]);
    registerTypeAlias<Taggable>(_$ormModelDefinitions[27]);
    registerTypeAlias<UniqueUser>(_$ormModelDefinitions[28]);
    registerTypeAlias<User>(_$ormModelDefinitions[29]);
    registerTypeAlias<UserProfile>(_$ormModelDefinitions[30]);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using [Model.factory<T>()] to ensure definitions are available.
void registerOrmFactories() {
  ModelFactoryRegistry.registerIfAbsent<ActiveUser>(
    ActiveUserOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Article>(
    ArticleOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<AttributeUser>(
    AttributeUserOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Author>(AuthorOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<Comment>(
    CommentOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<CustomSoftDelete>(
    CustomSoftDeleteOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<DerivedForFactory>(
    DerivedForFactoryOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<DriverOverrideEntry>(
    DriverOverrideEntryOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<EventModel>(
    EventModelOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Image>(ImageOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<JsonValueRecord>(
    JsonValueRecordOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<MutationTarget>(
    MutationTargetOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<NamedConstructorModel>(
    NamedConstructorModelOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<NullableRelationsTest>(
    NullableRelationsTestOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Photo>(PhotoOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<Post>(PostOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<PostTag>(
    PostTagOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<PredicateCollision>(
    PredicateCollisionOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<SerialTest>(
    SerialTestOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Setting>(
    SettingOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Tag>(TagOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<Taggable>(
    TaggableOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<UniqueUser>(
    UniqueUserOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<User>(UserOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<UserProfile>(
    UserProfileOrmDefinition.definition,
  );
}

/// Combined setup: registers both model registry and factories.
/// Returns a ModelRegistry with all generated models registered.
ModelRegistry buildOrmRegistryWithFactories() {
  registerOrmFactories();
  return buildOrmRegistry();
}

/// Registers generated model event handlers.
void registerModelEventHandlers({EventBus? bus}) {
  final busInstance = bus ?? EventBus.instance;
  registerEventModelEventHandlers(busInstance);
  registerPostEventHandlers(busInstance);
}

/// Registers generated model scopes into a [ScopeRegistry].
void registerModelScopes({ScopeRegistry? scopeRegistry}) {
  final scopeRegistryInstance = scopeRegistry ?? ScopeRegistry.instance;
  registerScopedUserScopes(scopeRegistryInstance);
}

/// Bootstraps generated ORM pieces: registry, factories, event handlers, and scopes.
ModelRegistry bootstrapOrm({
  ModelRegistry? registry,
  EventBus? bus,
  ScopeRegistry? scopes,
  bool registerFactories = true,
  bool registerEventHandlers = true,
  bool registerScopes = true,
}) {
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
