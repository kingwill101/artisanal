import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

const String _mockOrmedPackage = r'''
library ormed;

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
  Query<T> orderBy(String field, {bool descending = false}) => this;
  Query<T> groupBy(String field) => this;
  Query<T> select(List<String> columns) => this;
  Query<T> distinct([Iterable<String> columns = const []]) => this;
  Query<T> whereHas(String relation, [PredicateCallback<dynamic>? constraint]) =>
      this;
  Query<T> withRelation(
    String relation, [
    PredicateCallback<dynamic>? constraint,
  ]) =>
      this;
  Query<T> whereRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> orWhereRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> orderByRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> groupByRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> havingRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> orHavingRaw(String sql, [List<Object?> bindings = const []]) => this;
  Query<T> selectRaw(String sql, {String? alias}) => this;
}

class PredicateBuilder<T> {
  PredicateBuilder<T> where(String field, Object? value) => this;
  PredicateBuilder<T> whereRaw(String sql, [List<Object?> bindings = const []]) =>
      this;
}

class JoinBuilder {
  JoinBuilder whereRaw(String sql, [List<Object?> bindings = const []]) => this;
  JoinBuilder orWhereRaw(String sql, [List<Object?> bindings = const []]) => this;
}

typedef PredicateCallback<T> = void Function(PredicateBuilder<T>);

class Model<T> {}

mixin ModelFactoryCapable {}

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
}

enum RelationKind { hasMany }

class RelationDefinition {
  const RelationDefinition({
    required this.name,
    required this.kind,
    required this.targetModel,
    required this.foreignKey,
    required this.localKey,
  });

  final String name;
  final RelationKind kind;
  final String targetModel;
  final String foreignKey;
  final String localKey;
}

class ModelDefinition<T> {
  const ModelDefinition({
    required this.modelName,
    required this.tableName,
    required this.fields,
    required this.relations,
  });

  final String modelName;
  final String tableName;
  final List<FieldDefinition> fields;
  final List<RelationDefinition> relations;
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
  ],
  relations: const [
    _$UserPostsRelation,
  ],
);
''';

mixin OrmedTestMixin on AnalysisRuleTest {
  void addMockOrmedPackage() {
    final package = newPackage('ormed');
    package.addFile('lib/ormed.dart', _mockOrmedPackage);
  }

  void writeOrmFixture() {
    newFile('$testPackageLibPath/user.orm.dart', _ormFixture);
  }
}
