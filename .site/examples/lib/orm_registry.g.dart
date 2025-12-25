// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'models/attribute_metadata_examples.dart';
import 'models/admin.dart';
import 'models/driver_overrides_examples.dart';
import 'events/model_events.dart';
import 'models/relations/has_many_through.dart';
import 'models/factory_inheritance.dart';
import 'soft_deletes.dart';
import 'models/comment.dart';
import 'models/field_examples.dart';
import 'generated_code_usage.dart';
import 'models/factory_user.dart';
import 'models/casting_examples.dart';
import 'models/log_model.dart';
import 'models/relations/polymorphic.dart';
import 'models/post.dart';
import 'models/relations/belongs_to.dart';
import 'models/relations/belongs_to_many.dart';
import 'models/product.dart';
import 'models/relations/has_one.dart';
import 'models/model_scopes.dart';
import 'models/soft_delete_model.dart';
import 'models/timestamp_model.dart';
import 'models/user.dart';
import 'models/relations/has_many.dart';
import 'best_practices/best_practices.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [
  AccountOrmDefinition.definition,
  AdminOrmDefinition.definition,
  AuditedEventOrmDefinition.definition,
  AuditedUserOrmDefinition.definition,
  AuthorPostOrmDefinition.definition,
  AuthorWithCommentsOrmDefinition.definition,
  BaseItemOrmDefinition.definition,
  CombinedPostOrmDefinition.definition,
  CombinedPostTzOrmDefinition.definition,
  CommentOrmDefinition.definition,
  ContactOrmDefinition.definition,
  DocumentOrmDefinition.definition,
  DriverOverrideExampleOrmDefinition.definition,
  EventUserOrmDefinition.definition,
  FactoryUserOrmDefinition.definition,
  FieldCastSettingsOrmDefinition.definition,
  ItemWithAutoIncrementOrmDefinition.definition,
  ItemWithIntPKOrmDefinition.definition,
  ItemWithUuidPKOrmDefinition.definition,
  LinkOrmDefinition.definition,
  LogOrmDefinition.definition,
  MorphPhotoOrmDefinition.definition,
  MorphPostPhotosOrmDefinition.definition,
  MorphPostTagsOrmDefinition.definition,
  MorphTagOrmDefinition.definition,
  MorphUserOrmDefinition.definition,
  PostOrmDefinition.definition,
  PostAuthorOrmDefinition.definition,
  PostCommentOrmDefinition.definition,
  PostWithAuthorOrmDefinition.definition,
  PostWithTagsOrmDefinition.definition,
  ProductOrmDefinition.definition,
  ProfileOrmDefinition.definition,
  ScopedUserOrmDefinition.definition,
  SettingsOrmDefinition.definition,
  SoftDeleteArticleTzOrmDefinition.definition,
  SoftDeletePostOrmDefinition.definition,
  SpecialItemOrmDefinition.definition,
  TagOrmDefinition.definition,
  TimestampArticleTzOrmDefinition.definition,
  TimestampPostOrmDefinition.definition,
  UserOrmDefinition.definition,
  UserPostOrmDefinition.definition,
  UserWithPostsOrmDefinition.definition,
  UserWithProfileOrmDefinition.definition,
  ValidatedUserOrmDefinition.definition,
];

ModelRegistry buildOrmRegistry() => ModelRegistry()
  ..registerAll(_$ormModelDefinitions)
  ..registerTypeAlias<Account>(_$ormModelDefinitions[0])
  ..registerTypeAlias<Admin>(_$ormModelDefinitions[1])
  ..registerTypeAlias<AuditedEvent>(_$ormModelDefinitions[2])
  ..registerTypeAlias<AuditedUser>(_$ormModelDefinitions[3])
  ..registerTypeAlias<AuthorPost>(_$ormModelDefinitions[4])
  ..registerTypeAlias<AuthorWithComments>(_$ormModelDefinitions[5])
  ..registerTypeAlias<BaseItem>(_$ormModelDefinitions[6])
  ..registerTypeAlias<CombinedPost>(_$ormModelDefinitions[7])
  ..registerTypeAlias<CombinedPostTz>(_$ormModelDefinitions[8])
  ..registerTypeAlias<Comment>(_$ormModelDefinitions[9])
  ..registerTypeAlias<Contact>(_$ormModelDefinitions[10])
  ..registerTypeAlias<Document>(_$ormModelDefinitions[11])
  ..registerTypeAlias<DriverOverrideExample>(_$ormModelDefinitions[12])
  ..registerTypeAlias<EventUser>(_$ormModelDefinitions[13])
  ..registerTypeAlias<FactoryUser>(_$ormModelDefinitions[14])
  ..registerTypeAlias<FieldCastSettings>(_$ormModelDefinitions[15])
  ..registerTypeAlias<ItemWithAutoIncrement>(_$ormModelDefinitions[16])
  ..registerTypeAlias<ItemWithIntPK>(_$ormModelDefinitions[17])
  ..registerTypeAlias<ItemWithUuidPK>(_$ormModelDefinitions[18])
  ..registerTypeAlias<Link>(_$ormModelDefinitions[19])
  ..registerTypeAlias<Log>(_$ormModelDefinitions[20])
  ..registerTypeAlias<MorphPhoto>(_$ormModelDefinitions[21])
  ..registerTypeAlias<MorphPostPhotos>(_$ormModelDefinitions[22])
  ..registerTypeAlias<MorphPostTags>(_$ormModelDefinitions[23])
  ..registerTypeAlias<MorphTag>(_$ormModelDefinitions[24])
  ..registerTypeAlias<MorphUser>(_$ormModelDefinitions[25])
  ..registerTypeAlias<Post>(_$ormModelDefinitions[26])
  ..registerTypeAlias<PostAuthor>(_$ormModelDefinitions[27])
  ..registerTypeAlias<PostComment>(_$ormModelDefinitions[28])
  ..registerTypeAlias<PostWithAuthor>(_$ormModelDefinitions[29])
  ..registerTypeAlias<PostWithTags>(_$ormModelDefinitions[30])
  ..registerTypeAlias<Product>(_$ormModelDefinitions[31])
  ..registerTypeAlias<Profile>(_$ormModelDefinitions[32])
  ..registerTypeAlias<ScopedUser>(_$ormModelDefinitions[33])
  ..registerTypeAlias<Settings>(_$ormModelDefinitions[34])
  ..registerTypeAlias<SoftDeleteArticleTz>(_$ormModelDefinitions[35])
  ..registerTypeAlias<SoftDeletePost>(_$ormModelDefinitions[36])
  ..registerTypeAlias<SpecialItem>(_$ormModelDefinitions[37])
  ..registerTypeAlias<Tag>(_$ormModelDefinitions[38])
  ..registerTypeAlias<TimestampArticleTz>(_$ormModelDefinitions[39])
  ..registerTypeAlias<TimestampPost>(_$ormModelDefinitions[40])
  ..registerTypeAlias<User>(_$ormModelDefinitions[41])
  ..registerTypeAlias<UserPost>(_$ormModelDefinitions[42])
  ..registerTypeAlias<UserWithPosts>(_$ormModelDefinitions[43])
  ..registerTypeAlias<UserWithProfile>(_$ormModelDefinitions[44])
  ..registerTypeAlias<ValidatedUser>(_$ormModelDefinitions[45])
  ;

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    registerTypeAlias<Account>(_$ormModelDefinitions[0]);
    registerTypeAlias<Admin>(_$ormModelDefinitions[1]);
    registerTypeAlias<AuditedEvent>(_$ormModelDefinitions[2]);
    registerTypeAlias<AuditedUser>(_$ormModelDefinitions[3]);
    registerTypeAlias<AuthorPost>(_$ormModelDefinitions[4]);
    registerTypeAlias<AuthorWithComments>(_$ormModelDefinitions[5]);
    registerTypeAlias<BaseItem>(_$ormModelDefinitions[6]);
    registerTypeAlias<CombinedPost>(_$ormModelDefinitions[7]);
    registerTypeAlias<CombinedPostTz>(_$ormModelDefinitions[8]);
    registerTypeAlias<Comment>(_$ormModelDefinitions[9]);
    registerTypeAlias<Contact>(_$ormModelDefinitions[10]);
    registerTypeAlias<Document>(_$ormModelDefinitions[11]);
    registerTypeAlias<DriverOverrideExample>(_$ormModelDefinitions[12]);
    registerTypeAlias<EventUser>(_$ormModelDefinitions[13]);
    registerTypeAlias<FactoryUser>(_$ormModelDefinitions[14]);
    registerTypeAlias<FieldCastSettings>(_$ormModelDefinitions[15]);
    registerTypeAlias<ItemWithAutoIncrement>(_$ormModelDefinitions[16]);
    registerTypeAlias<ItemWithIntPK>(_$ormModelDefinitions[17]);
    registerTypeAlias<ItemWithUuidPK>(_$ormModelDefinitions[18]);
    registerTypeAlias<Link>(_$ormModelDefinitions[19]);
    registerTypeAlias<Log>(_$ormModelDefinitions[20]);
    registerTypeAlias<MorphPhoto>(_$ormModelDefinitions[21]);
    registerTypeAlias<MorphPostPhotos>(_$ormModelDefinitions[22]);
    registerTypeAlias<MorphPostTags>(_$ormModelDefinitions[23]);
    registerTypeAlias<MorphTag>(_$ormModelDefinitions[24]);
    registerTypeAlias<MorphUser>(_$ormModelDefinitions[25]);
    registerTypeAlias<Post>(_$ormModelDefinitions[26]);
    registerTypeAlias<PostAuthor>(_$ormModelDefinitions[27]);
    registerTypeAlias<PostComment>(_$ormModelDefinitions[28]);
    registerTypeAlias<PostWithAuthor>(_$ormModelDefinitions[29]);
    registerTypeAlias<PostWithTags>(_$ormModelDefinitions[30]);
    registerTypeAlias<Product>(_$ormModelDefinitions[31]);
    registerTypeAlias<Profile>(_$ormModelDefinitions[32]);
    registerTypeAlias<ScopedUser>(_$ormModelDefinitions[33]);
    registerTypeAlias<Settings>(_$ormModelDefinitions[34]);
    registerTypeAlias<SoftDeleteArticleTz>(_$ormModelDefinitions[35]);
    registerTypeAlias<SoftDeletePost>(_$ormModelDefinitions[36]);
    registerTypeAlias<SpecialItem>(_$ormModelDefinitions[37]);
    registerTypeAlias<Tag>(_$ormModelDefinitions[38]);
    registerTypeAlias<TimestampArticleTz>(_$ormModelDefinitions[39]);
    registerTypeAlias<TimestampPost>(_$ormModelDefinitions[40]);
    registerTypeAlias<User>(_$ormModelDefinitions[41]);
    registerTypeAlias<UserPost>(_$ormModelDefinitions[42]);
    registerTypeAlias<UserWithPosts>(_$ormModelDefinitions[43]);
    registerTypeAlias<UserWithProfile>(_$ormModelDefinitions[44]);
    registerTypeAlias<ValidatedUser>(_$ormModelDefinitions[45]);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using [Model.factory<T>()] to ensure definitions are available.
void registerOrmFactories() {
  ModelFactoryRegistry.registerIfAbsent<BaseItem>(BaseItemOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<FactoryUser>(FactoryUserOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<SpecialItem>(SpecialItemOrmDefinition.definition);
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
  registerAuditedUserEventHandlers(busInstance);
}

/// Registers generated model scopes into a [ScopeRegistry].
void registerModelScopes({ScopeRegistry? scopeRegistry}) {
  final scopeRegistryInstance = scopeRegistry ?? ScopeRegistry.instance;
  registerScopedUserScopes(scopeRegistryInstance);
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
