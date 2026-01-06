import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

const String _mockOrmedPackage = r'''
library ormed;

abstract class OrmEntity {
  const OrmEntity();
}

class Query<T> {
  Query<T> where(
    Object fieldOrCallback, [
    Object? value,
    Object? extra,
  ]) =>
      this;
  Query<T> whereTyped(PredicateCallback<T> callback) => this;
  Query<T> whereEquals(String field, Object? value) => this;
  Query<T> whereNotEquals(String field, Object? value) => this;
  Query<T> whereIn(String field, List<Object?> values) => this;
  Query<T> whereNotIn(String field, List<Object?> values) => this;
  Query<T> whereNull(String field) => this;
  Query<T> whereNotNull(String field) => this;
  Query<T> whereLike(
    String field,
    Object? value, {
    bool caseInsensitive = false,
  }) =>
      this;
  Query<T> whereNotLike(
    String field,
    Object? value, {
    bool caseInsensitive = false,
  }) =>
      this;
  Query<T> whereBetween(String field, Object? lower, Object? upper) => this;
  Query<T> whereNotBetween(String field, Object? lower, Object? upper) => this;
  Query<T> whereColumn(String first, String second) => this;
  Query<T> orWhere(
    Object fieldOrCallback, [
    Object? value,
    Object? extra,
  ]) =>
      this;
  Query<T> orWhereEquals(String field, Object? value) => this;
  Query<T> orWhereNotEquals(String field, Object? value) => this;
  Query<T> orWhereIn(String field, List<Object?> values) => this;
  Query<T> orWhereNotIn(String field, List<Object?> values) => this;
  Query<T> orWhereNull(String field) => this;
  Query<T> orWhereNotNull(String field) => this;
  Query<T> orWhereLike(String field, Object? value) => this;
  Query<T> orWhereNotLike(String field, Object? value) => this;
  Query<T> orWhereBetween(String field, Object? lower, Object? upper) => this;
  Query<T> orWhereNotBetween(String field, Object? lower, Object? upper) => this;
  Query<T> orderBy(String field, {bool descending = false}) => this;
  Query<T> groupBy(List<String> columns) => this;
  Query<T> having(String field, PredicateOperator operator, Object? value) =>
      this;
  Query<T> select(List<String> columns) => this;
  Query<T> distinct([Iterable<String> columns = const []]) => this;
  Query<T> limit(int? value) => this;
  Query<T> offset(int? value) => this;
  Query<T> withRelation(
    String relation, [
    PredicateCallback<dynamic>? constraint,
  ]) =>
      this;
  Query<T> withRelationTyped<TRelated>(
    String relation, [
    PredicateCallback<TRelated>? constraint,
  ]) =>
      this;
  Query<T> whereHas(String relation, [PredicateCallback<dynamic>? constraint]) =>
      this;
  Query<T> whereHasTyped<TRelated>(
    String relation, [
    PredicateCallback<TRelated>? constraint,
  ]) =>
      this;
  Query<T> orWhereHas(String relation, [PredicateCallback<dynamic>? constraint]) =>
      this;
  Query<T> orWhereHasTyped<TRelated>(
    String relation, [
    PredicateCallback<TRelated>? constraint,
  ]) =>
      this;
  Query<T> withTrashed() => this;
  Query<T> onlyTrashed() => this;
  Future<int> update(Map<String, Object?> values) async => 0;
  Future<int> delete() async => 0;
  Future<List<T>> updateInputs(List<Object> inputs, {Object? where}) async => <T>[];
  Future<List<T>> updateInputsRaw(List<Object> inputs, {Object? where}) async => <T>[];
  Future<List<T>> insertManyInputs(List<Object> inputs) async => <T>[];
  Future<int> insertManyInputsRaw(List<Object> inputs) async => 0;
  Query<T> whereRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> orWhereRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> orderByRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> groupByRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> havingRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> orHavingRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> selectRaw(String sql, {String? alias}) => this;
  Future<List<T>> get() async => <T>[];
  Future<List<Object?>> rows() async => const <Object?>[];
  Future<List<P>> getPartial<P extends PartialEntity<T>>(
    P Function(Map<String, Object?>) factory,
  ) async => <P>[];
}

class PredicateBuilder<T> {
  PredicateBuilder<T> where(String field, Object? value) => this;
  PredicateBuilder<T> whereEquals(String field, Object? value) => this;
  PredicateBuilder<T> whereIn(String field, List<Object?> values) => this;
  PredicateBuilder<T> whereBetween(String field, Object? lower, Object? upper) =>
      this;
  PredicateBuilder<T> whereRaw(String sql, [List<Object?> bindings = const []]) =>
      this;
}

class JoinBuilder {
  JoinBuilder whereRaw(String sql, [List<Object?> bindings = const []]) => this;
  JoinBuilder orWhereRaw(String sql, [List<Object?> bindings = const []]) => this;
}

typedef PredicateCallback<T> = void Function(PredicateBuilder<T>);

enum PredicateOperator { equals, greaterThan }

class Model<T> implements OrmEntity {
  const Model();
  static Query<TModel> query<TModel extends OrmEntity>({
    String? connection,
  }) =>
      Query<TModel>();
  static Future<List<TModel>> all<TModel extends OrmEntity>({
    String? connection,
  }) async =>
      <TModel>[];
  R withoutTimestamps<R>(R Function() callback) => callback();
}

mixin ModelFactoryCapable {}

abstract class InsertDto<T extends OrmEntity> {
  Map<String, Object?> toMap();
}

abstract class UpdateDto<T extends OrmEntity> {
  Map<String, Object?> toMap();
}

abstract class PartialEntity<T extends OrmEntity> implements OrmEntity {
  const PartialEntity();
  T toEntity();
  Map<String, Object?> toMap();
}

class ModelCompanion<T extends Model<T>> {
  const ModelCompanion();
  Future<List<T>> all({String? connection}) async => <T>[];
}

class Repository<T> {
  Future<T> insert(Object model) async => throw UnimplementedError();
  Future<List<T>> insertMany(List<Object> inputs) async => <T>[];
  Future<int> insertOrIgnore(Object model) async => 0;
  Future<int> insertOrIgnoreMany(List<Object> inputs) async => 0;
  Future<T> update(Object model, {Object? where}) async =>
      throw UnimplementedError();
  Future<List<T>> updateMany(List<Object> inputs, {Object? where}) async =>
      <T>[];
  Future<MutationResult> updateManyRaw(List<Object> inputs, {Object? where}) async =>
      const MutationResult(affectedRows: 0);
}

class MutationResult {
  const MutationResult({required this.affectedRows});
  final int affectedRows;
}

class FieldDefinition {
  const FieldDefinition({
    required this.name,
    required this.columnName,
    required this.dartType,
    required this.resolvedType,
    required this.isPrimaryKey,
    required this.isNullable,
    required this.isUnique,
    required this.isIndexed,
    required this.autoIncrement,
    this.defaultValueSql,
  });

  final String name;
  final String columnName;
  final String dartType;
  final String resolvedType;
  final bool isPrimaryKey;
  final bool isNullable;
  final bool isUnique;
  final bool isIndexed;
  final bool autoIncrement;
  final String? defaultValueSql;
}

enum RelationKind { hasMany, belongsToMany }

class RelationDefinition {
  const RelationDefinition({
    required this.name,
    required this.kind,
    required this.targetModel,
    this.foreignKey,
    this.localKey,
    this.pivotColumns = const [],
    this.pivotModel,
    this.pivotForeignKey,
    this.pivotRelatedKey,
    this.pivotTimestamps = false,
  });

  final String name;
  final RelationKind kind;
  final String targetModel;
  final String? foreignKey;
  final String? localKey;
  final List<String> pivotColumns;
  final String? pivotModel;
  final String? pivotForeignKey;
  final String? pivotRelatedKey;
  final bool pivotTimestamps;
}

class ModelAttributesMetadata {
  const ModelAttributesMetadata({
    this.timestamps = true,
    this.softDeletes = false,
    this.softDeleteColumn = 'deleted_at',
  });

  final bool timestamps;
  final bool softDeletes;
  final String softDeleteColumn;
}

class ModelDefinition<T> {
  const ModelDefinition({
    required this.modelName,
    required this.tableName,
    required this.fields,
    required this.relations,
    this.metadata = const ModelAttributesMetadata(),
    this.softDeleteColumn,
  });

  final String modelName;
  final String tableName;
  final List<FieldDefinition> fields;
  final List<RelationDefinition> relations;
  final ModelAttributesMetadata metadata;
  final String? softDeleteColumn;
}
''';

const String _ormFixture = r'''
const FieldDefinition _$UserIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$UserEmailField = FieldDefinition(
  name: 'email',
  columnName: 'email_address',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UserAgeField = FieldDefinition(
  name: 'age',
  columnName: 'age',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UserCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$UserUpdatedAtField = FieldDefinition(
  name: 'updatedAt',
  columnName: 'updated_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$UserPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.hasMany,
  targetModel: 'Post',
  foreignKey: 'user_id',
  localKey: 'id',
);

final ModelDefinition<$User> _$UserDefinition = ModelDefinition(
  modelName: 'User',
  tableName: 'users',
  fields: const [
    _$UserIdField,
    _$UserEmailField,
    _$UserAgeField,
    _$UserCreatedAtField,
    _$UserUpdatedAtField,
  ],
  relations: const [
    _$UserPostsRelation,
  ],
  metadata: ModelAttributesMetadata(
    timestamps: true,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
);

const FieldDefinition _$PostIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$PostTitleField = FieldDefinition(
  name: 'title',
  columnName: 'title',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostUserIdField = FieldDefinition(
  name: 'userId',
  columnName: 'user_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostIsPublishedField = FieldDefinition(
  name: 'isPublished',
  columnName: 'is_published',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostRatingField = FieldDefinition(
  name: 'rating',
  columnName: 'rating',
  dartType: 'double',
  resolvedType: 'double',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$PostCommentsRelation = RelationDefinition(
  name: 'comments',
  kind: RelationKind.hasMany,
  targetModel: 'Comment',
  foreignKey: 'post_id',
  localKey: 'id',
);

const RelationDefinition _$PostTagsRelation = RelationDefinition(
  name: 'tags',
  kind: RelationKind.belongsToMany,
  targetModel: 'Tag',
  pivotColumns: ['label'],
  pivotModel: 'PostTag',
  pivotForeignKey: 'post_id',
  pivotRelatedKey: 'tag_id',
);

final ModelDefinition<$Post> _$PostDefinition = ModelDefinition(
  modelName: 'Post',
  tableName: 'posts',
  fields: const [
    _$PostIdField,
    _$PostTitleField,
    _$PostUserIdField,
    _$PostIsPublishedField,
    _$PostRatingField,
  ],
  relations: const [
    _$PostCommentsRelation,
    _$PostTagsRelation,
  ],
  metadata: ModelAttributesMetadata(
    timestamps: false,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
);

const FieldDefinition _$CommentIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$CommentPostIdField = FieldDefinition(
  name: 'postId',
  columnName: 'post_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<$Comment> _$CommentDefinition = ModelDefinition(
  modelName: 'Comment',
  tableName: 'comments',
  fields: const [
    _$CommentIdField,
    _$CommentPostIdField,
    _$CommentBodyField,
  ],
  relations: const [],
  metadata: ModelAttributesMetadata(
    timestamps: true,
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
);

const FieldDefinition _$TagIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: true,
);

const FieldDefinition _$TagNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<$Tag> _$TagDefinition = ModelDefinition(
  modelName: 'Tag',
  tableName: 'tags',
  fields: const [
    _$TagIdField,
    _$TagNameField,
  ],
  relations: const [],
  metadata: ModelAttributesMetadata(
    timestamps: true,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
);

const FieldDefinition _$PostTagPostIdField = FieldDefinition(
  name: 'postId',
  columnName: 'post_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTagTagIdField = FieldDefinition(
  name: 'tagId',
  columnName: 'tag_id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$PostTagLabelField = FieldDefinition(
  name: 'label',
  columnName: 'label',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<$PostTag> _$PostTagDefinition = ModelDefinition(
  modelName: 'PostTag',
  tableName: 'post_tags',
  fields: const [
    _$PostTagPostIdField,
    _$PostTagTagIdField,
    _$PostTagLabelField,
  ],
  relations: const [],
  metadata: ModelAttributesMetadata(
    timestamps: false,
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
);
''';

mixin OrmedTestMixin on AnalysisRuleTest {
  void addMockOrmedPackage() {
    final package = newPackage('ormed');
    package.addFile('lib/ormed.dart', _mockOrmedPackage);
  }

  void writeOrmFixture() {
    newFile('$testPackageLibPath/models.orm.dart', _ormFixture);
  }
}
