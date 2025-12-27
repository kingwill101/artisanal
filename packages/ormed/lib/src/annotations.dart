/// Annotations and metadata declarations for Ormed.
///
/// Ormed's generator reads these annotations and emits model metadata, codecs,
/// relationships, scopes, and event-handler wiring.
library;

import 'package:meta/meta.dart';

/// Marks a Dart class as an Ormed model.
///
/// The code generator reads `final` public fields from the annotated class and
/// emits a tracked model plus metadata helpers.
///
/// See also: [OrmField], [OrmRelation], [OrmScope], and [OrmEvent].
///
/// ```dart
/// import 'package:ormed/ormed.dart';
///
/// part 'user.orm.dart';
///
/// @OrmModel(
///   table: 'users',
///   // These lists use column names (which usually match field names).
///   hidden: ['password_hash'],
///   casts: {'profile': 'json'},
/// )
/// class User extends Model<User> {
///   const User({
///     required this.id,
///     required this.email,
///     this.profile,
///   });
///
///   @OrmField(isPrimaryKey: true, autoIncrement: true)
///   final int id;
///
///   final String email;
///
///   @OrmField(cast: 'json')
///   final Map<String, Object?>? profile;
/// }
/// ```
@immutable
class OrmModel {
  const OrmModel({
    this.table,
    this.schema,
    this.generateCodec = true,
    this.timestamps = true,
    this.hidden = const [],
    this.visible = const [],
    this.fillable = const [],
    this.guarded = const [],
    this.casts = const {},
    this.appends = const [],
    this.touches = const [],
    this.connection,
    this.softDeletes = false,
    this.softDeletesColumn = 'deleted_at',
    this.driverAnnotations = const [],
    this.primaryKey = const [],
    this.constructor,
  });

  /// The database table/collection name.
  final String? table;

  /// An optional schema or namespace qualifier.
  final String? schema;

  /// Whether the generator should emit codec helpers for this model.
  final bool generateCodec;

  /// Whether automatic timestamps (created_at/updated_at) are enabled.
  final bool timestamps;

  /// Column names that should be hidden when serializing.
  final List<String> hidden;

  /// Column names explicitly visible when a hidden list is defined.
  final List<String> visible;

  /// Column names that can be mass assigned.
  final List<String> fillable;

  /// Column names guarded from mass assignment.
  final List<String> guarded;

  /// Cast hints keyed by column name (for example, `{'profile': 'json'}`).
  ///
  /// Cast keys are resolved via Ormed's codec registry and are used when
  /// serializing/deserializing the model's attribute map.
  ///
  /// If you override [OrmField.columnName], prefer setting [OrmField.cast] on
  /// that field so the cast follows the effective column name.
  final Map<String, String> casts;

  /// Computed attributes to include when serializing via `toArray()`/`toJson()`.
  final List<String> appends;

  /// Relation names to touch when this model is saved.
  final List<String> touches;

  /// A connection/driver name override.
  final String? connection;

  /// Whether the model tracks soft deletes.
  final bool softDeletes;

  /// Column used for soft delete timestamps.
  final String softDeletesColumn;

  /// Driver names that should take control of this model.
  final List<String> driverAnnotations;

  /// Column or field names that define the primary key.
  ///
  /// This is a convenience alternative to annotating fields with
  /// `@OrmField(isPrimaryKey: true)`.
  final List<String> primaryKey;

  /// An optional named constructor to use for code generation.
  ///
  /// If `null`, the generator uses the first generative (non-factory)
  /// constructor it finds.
  final String? constructor;
}

/// Additional metadata for a model field/column.
///
/// Apply this to a model field when you need to override the column name, mark
/// constraints, customize codecs, or tweak attribute rules.
///
/// ```dart
/// @OrmModel(table: 'users')
/// class User extends Model<User> {
///   const User({required this.id, required this.email});
///
///   @OrmField(isPrimaryKey: true, autoIncrement: true)
///   final int id;
///
///   @OrmField(columnName: 'email_address', isUnique: true, isIndexed: true)
///   final String email;
/// }
/// ```
@immutable
class OrmField {
  const OrmField({
    this.columnName,
    this.isPrimaryKey = false,
    this.isNullable,
    this.isUnique = false,
    this.isIndexed = false,
    this.autoIncrement = false,
    this.ignore = false,
    this.codec,
    this.columnType,
    this.defaultValueSql,
    this.driverOverrides = const {},
    this.fillable,
    this.guarded,
    this.hidden,
    this.visible,
    this.cast,
  });

  /// An explicit database column name override.
  final String? columnName;

  /// Whether this column acts as the primary key.
  final bool isPrimaryKey;

  /// A nullable override for schema generation (defaults to Dart nullability).
  final bool? isNullable;

  /// Marks the column as unique.
  final bool isUnique;

  /// Marks the column as indexed.
  final bool isIndexed;

  /// Whether the column auto-increments.
  final bool autoIncrement;

  /// Skip this field entirely.
  final bool ignore;

  /// An optional codec type used for value transformations.
  ///
  /// The value must be a `Type` literal (for example, `UuidCodec`).
  final Type? codec;

  /// Database column type override (e.g., jsonb, uuid).
  final String? columnType;

  /// Default value SQL snippet.
  final String? defaultValueSql;

  /// Driver-specific overrides keyed by adapter metadata name (e.g., 'postgres').
  final Map<String, OrmDriverFieldOverride> driverOverrides;

  /// Whether this column is considered fillable (overrides [OrmModel.fillable]).
  final bool? fillable;

  /// Whether this column is considered guarded (overrides [OrmModel.guarded]).
  final bool? guarded;

  /// Whether this column is hidden when serializing (overrides [OrmModel.hidden]).
  final bool? hidden;

  /// Whether this column is explicitly visible (overrides [OrmModel.visible]).
  final bool? visible;

  /// A cast key to apply to this column (overrides [OrmModel.casts]).
  ///
  /// This is the preferred way to attach casts to a field when the column name
  /// differs from the Dart field name.
  final String? cast;
}

/// Describes driver-specific overrides for a model field.
///
/// This is typically used via [OrmField.driverOverrides] to customize schema or
/// codecs per driver:
///
/// ```dart
/// @OrmField(
///   columnType: 'json',
///   driverOverrides: {
///     // Keys are normalized to lowercase.
///     'postgres': OrmDriverFieldOverride(columnType: 'jsonb'),
///   },
/// )
/// final Map<String, Object?> payload;
/// ```
@immutable
class OrmDriverFieldOverride {
  const OrmDriverFieldOverride({
    this.columnType,
    this.defaultValueSql,
    this.codec,
  });

  /// Driver-specific column type (e.g., jsonb when Postgres is active).
  final String? columnType;

  /// Driver-specific default expression.
  final String? defaultValueSql;

  /// Driver-specific codec type override.
  final Type? codec;
}

/// Marks a model method as a handler for a specific event type.
///
/// The annotated method must be `static` and accept exactly one required
/// positional parameter whose type matches [eventType].
///
/// Usage:
/// ```dart
/// @OrmEvent(ModelCreatedEvent)
/// static void onCreated(ModelCreatedEvent event) {
///   // handle creation
/// }
/// ```
@immutable
class OrmEvent {
  const OrmEvent(this.eventType);

  /// The event type this handler responds to.
  final Type eventType;
}

/// Relationship descriptor applied to fields referencing other models.
///
/// Prefer the named constructors (like [OrmRelation.hasMany]) so the relation
/// kind is explicit at the call site.
///
/// ```dart
/// @OrmModel(table: 'posts')
/// class Post extends Model<Post> {
///   @OrmRelation.belongsTo(target: User, foreignKey: 'author_id')
///   final User? author;
///
///   @OrmRelation.hasMany(target: Comment, foreignKey: 'post_id')
///   final List<Comment> comments;
/// }
/// ```
@immutable
class OrmRelation {
  /// Creates a relation descriptor.
  ///
  /// Most code should use a named constructor such as [OrmRelation.hasOne] or
  /// [OrmRelation.belongsTo].
  const OrmRelation({
    required this.kind,
    this.target,
    this.foreignKey,
    this.localKey,
    this.through,
    this.throughModel,
    this.throughForeignKey,
    this.throughLocalKey,
    this.pivotForeignKey,
    this.pivotRelatedKey,
    this.withPivot = const [],
    this.withTimestamps = false,
    this.pivotModel,
    this.morphType,
    this.morphClass,
  });

  /// Creates a `hasOne` relation.
  const OrmRelation.hasOne({Type? target, String? foreignKey, String? localKey})
    : this(
        kind: RelationKind.hasOne,
        target: target,
        foreignKey: foreignKey,
        localKey: localKey,
      );

  /// Creates a `hasMany` relation.
  const OrmRelation.hasMany({
    Type? target,
    String? foreignKey,
    String? localKey,
  }) : this(
         kind: RelationKind.hasMany,
         target: target,
         foreignKey: foreignKey,
         localKey: localKey,
       );

  /// Creates a `hasOneThrough` relation.
  ///
  /// [throughModel] is the intermediate model class.
  /// [foreignKey] is the related model's foreign key referencing [throughModel].
  /// [throughForeignKey] is the intermediate model's foreign key referencing
  /// the parent model.
  /// [throughLocalKey] is the intermediate model key referenced by [foreignKey].
  const OrmRelation.hasOneThrough({
    Type? target,
    Type? throughModel,
    String? foreignKey,
    String? localKey,
    String? throughForeignKey,
    String? throughLocalKey,
  }) : this(
         kind: RelationKind.hasOneThrough,
         target: target,
         foreignKey: foreignKey,
         localKey: localKey,
         throughModel: throughModel,
         throughForeignKey: throughForeignKey,
         throughLocalKey: throughLocalKey,
       );

  /// Creates a `hasManyThrough` relation.
  ///
  /// [throughModel] is the intermediate model class.
  /// [foreignKey] is the related model's foreign key referencing [throughModel].
  /// [throughForeignKey] is the intermediate model's foreign key referencing
  /// the parent model.
  /// [throughLocalKey] is the intermediate model key referenced by [foreignKey].
  const OrmRelation.hasManyThrough({
    Type? target,
    Type? throughModel,
    String? foreignKey,
    String? localKey,
    String? throughForeignKey,
    String? throughLocalKey,
  }) : this(
         kind: RelationKind.hasManyThrough,
         target: target,
         foreignKey: foreignKey,
         localKey: localKey,
         throughModel: throughModel,
         throughForeignKey: throughForeignKey,
         throughLocalKey: throughLocalKey,
       );

  /// Creates a `belongsTo` relation.
  const OrmRelation.belongsTo({
    Type? target,
    String? foreignKey,
    String? localKey,
  }) : this(
         kind: RelationKind.belongsTo,
         target: target,
         foreignKey: foreignKey,
         localKey: localKey,
       );

  /// Creates a `manyToMany` relation.
  ///
  /// Use [through] for the pivot/join table and provide pivot key overrides as
  /// needed.
  const OrmRelation.manyToMany({
    Type? target,
    String? through,
    String? pivotForeignKey,
    String? pivotRelatedKey,
    String? foreignKey,
    String? localKey,
    List<String> withPivot = const [],
    bool withTimestamps = false,
    Type? pivotModel,
  }) : this(
         kind: RelationKind.manyToMany,
         target: target,
         through: through,
         pivotForeignKey: pivotForeignKey,
         pivotRelatedKey: pivotRelatedKey,
         foreignKey: foreignKey,
         localKey: localKey,
         withPivot: withPivot,
         withTimestamps: withTimestamps,
         pivotModel: pivotModel,
       );

  /// Creates a `morphOne` relation.
  const OrmRelation.morphOne({
    Type? target,
    String? morphType,
    String? morphClass,
    String? foreignKey,
    String? localKey,
  }) : this(
         kind: RelationKind.morphOne,
         target: target,
         morphType: morphType,
         morphClass: morphClass,
         foreignKey: foreignKey,
         localKey: localKey,
       );

  /// Creates a `morphMany` relation.
  const OrmRelation.morphMany({
    Type? target,
    String? morphType,
    String? morphClass,
    String? foreignKey,
    String? localKey,
  }) : this(
         kind: RelationKind.morphMany,
         target: target,
         morphType: morphType,
         morphClass: morphClass,
         foreignKey: foreignKey,
         localKey: localKey,
       );

  /// Creates a `morphTo` relation.
  ///
  /// [foreignKey] is the morph id column on the parent model.
  /// [morphType] is the morph type/discriminator column on the parent model.
  /// [localKey] is the target key on related models (defaults to their primary key).
  const OrmRelation.morphTo({
    String? foreignKey,
    String? morphType,
    String? localKey,
  }) : this(
         kind: RelationKind.morphTo,
         foreignKey: foreignKey,
         localKey: localKey,
         morphType: morphType,
       );

  /// Creates a `morphToMany` relation.
  ///
  /// Use [through] for the pivot/join table and provide pivot key overrides
  /// as needed. [morphType] and [morphClass] describe the polymorphic pivot.
  const OrmRelation.morphToMany({
    Type? target,
    String? through,
    String? pivotForeignKey,
    String? pivotRelatedKey,
    String? foreignKey,
    String? localKey,
    String? morphType,
    String? morphClass,
    List<String> withPivot = const [],
    bool withTimestamps = false,
    Type? pivotModel,
  }) : this(
         kind: RelationKind.morphToMany,
         target: target,
         through: through,
         pivotForeignKey: pivotForeignKey,
         pivotRelatedKey: pivotRelatedKey,
         foreignKey: foreignKey,
         localKey: localKey,
         morphType: morphType,
         morphClass: morphClass,
         withPivot: withPivot,
         withTimestamps: withTimestamps,
         pivotModel: pivotModel,
       );

  /// Creates a `morphedByMany` relation.
  ///
  /// Use [through] for the pivot/join table and provide pivot key overrides
  /// as needed. [morphType] and [morphClass] describe the polymorphic pivot.
  const OrmRelation.morphedByMany({
    Type? target,
    String? through,
    String? pivotForeignKey,
    String? pivotRelatedKey,
    String? foreignKey,
    String? localKey,
    String? morphType,
    String? morphClass,
    List<String> withPivot = const [],
    bool withTimestamps = false,
    Type? pivotModel,
  }) : this(
         kind: RelationKind.morphedByMany,
         target: target,
         through: through,
         pivotForeignKey: pivotForeignKey,
         pivotRelatedKey: pivotRelatedKey,
         foreignKey: foreignKey,
         localKey: localKey,
         morphType: morphType,
         morphClass: morphClass,
         withPivot: withPivot,
         withTimestamps: withTimestamps,
         pivotModel: pivotModel,
       );

  /// The relationship kind (for example, [RelationKind.hasMany]).
  final RelationKind kind;

  /// The related model type (for example, `User`).
  final Type? target;

  /// The foreign key column name used by this relation.
  final String? foreignKey;

  /// The local key column name used by this relation.
  final String? localKey;

  /// The join/pivot table for many-to-many relations.
  final String? through;

  /// The intermediate model class for through relations.
  final Type? throughModel;

  /// Foreign key on the through model pointing back to the parent.
  final String? throughForeignKey;

  /// Key on the through model referenced by the related model's foreign key.
  final String? throughLocalKey;

  /// The owner key column name on the pivot table.
  final String? pivotForeignKey;

  /// The related key column name on the pivot table.
  final String? pivotRelatedKey;

  /// Additional pivot columns to select when eager loading.
  final List<String> withPivot;

  /// Whether to automatically manage pivot timestamps (created_at/updated_at).
  final bool withTimestamps;

  /// Optional pivot model type for many-to-many relations.
  final Type? pivotModel;

  /// The discriminator/type column name for polymorphic relations.
  final String? morphType;

  /// The discriminator/class value for polymorphic relations.
  final String? morphClass;
}

/// Marks an instance getter or method as an attribute accessor.
///
/// Accessors customize how an attribute value is exposed. Prefer annotating a
/// Dart getter for ergonomic access:
///
/// ```dart
/// @OrmAccessor()
/// String get fullName => '${getAttribute('first_name')} ${getAttribute('last_name')}';
/// ```
///
/// Provide [attribute] to override the inferred column name.
@immutable
class OrmAccessor {
  const OrmAccessor({this.attribute});

  /// Column name or attribute key to associate with this accessor.
  final String? attribute;
}

/// Marks an instance setter or method as an attribute mutator.
///
/// Mutators transform values before they are stored in the attribute map.
/// Provide [attribute] to override the inferred column name.
@immutable
class OrmMutator {
  const OrmMutator({this.attribute});

  /// Column name or attribute key to associate with this mutator.
  final String? attribute;
}

/// Marks a static model method as a query scope.
///
/// A scope must accept `Query<T>` as its first required positional parameter.
/// Set [global] to `true` to have the scope applied automatically to all
/// queries for the model; otherwise it is registered as a local scope that can
/// be invoked explicitly.
///
/// ```dart
/// @OrmScope(global: true)
/// static Query<$User> active(Query<$User> query) =>
///     query.whereEquals('active', true);
/// ```
@immutable
class OrmScope {
  const OrmScope({this.identifier, this.global = false});

  /// Optional explicit identifier used when registering the scope.
  /// Defaults to the method name.
  final String? identifier;

  /// Whether this scope is registered as a global scope.
  final bool global;
}

/// Supported relationship kinds mirrored after Eloquent/GORM semantics.
enum RelationKind {
  /// One-to-one relation where the related model holds the foreign key.
  hasOne,

  /// One-to-many relation where the related model holds the foreign key.
  hasMany,

  /// One-to-one relation through an intermediate model.
  hasOneThrough,

  /// One-to-many relation through an intermediate model.
  hasManyThrough,

  /// Inverse relation where this model holds the foreign key.
  belongsTo,

  /// Many-to-many relation through a pivot/join table.
  manyToMany,

  /// Polymorphic one-to-one relation.
  morphOne,

  /// Polymorphic one-to-many relation.
  morphMany,

  /// Polymorphic inverse relation.
  morphTo,

  /// Polymorphic many-to-many relation.
  morphToMany,

  /// Polymorphic inverse many-to-many relation.
  morphedByMany,
}

/// Marks a field as the soft-delete column for a model.
///
/// Only a single field may be annotated with [OrmSoftDelete] per model.
///
/// ```dart
/// @OrmModel(table: 'posts')
/// class Post extends Model<Post> with SoftDeletes {
///   const Post({required this.id, this.deletedAt});
///
///   final int id;
///
///   @OrmSoftDelete(columnName: 'deleted_at')
///   final DateTime? deletedAt;
/// }
/// ```
@immutable
class OrmSoftDelete {
  const OrmSoftDelete({this.columnName = 'deleted_at'});

  /// Column used to store soft delete timestamps.
  final String columnName;
}

/// Marker annotation used to flag the driver that should handle this model.
@immutable
class DriverModel {
  const DriverModel(this.driverName);

  /// The driver name (for example, `'sqlite'`).
  final String driverName;
}

/// Marker annotation that enables factory support for a model.
///
/// Apply `@HasFactory()` to your model when you want the generator to emit
/// the factory helper class and register the definition with the factory
/// registry. This is an alternative to using the `ModelFactoryCapable` mixin.
@immutable
class HasFactory {
  const HasFactory();
}

/// Convenience constant for `@HasFactory()`.
///
/// ```dart
/// @hasFactory
/// @OrmModel(table: 'users')
/// class User extends Model<User> {
///   const User({required this.id});
///   final int id;
/// }
/// ```
const hasFactory = HasFactory();
