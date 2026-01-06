import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/query_safety_rules.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateDeleteWithoutWhereRuleTest);
    defineReflectiveTests(OffsetWithoutOrderRuleTest);
    defineReflectiveTests(LimitWithoutOrderRuleTest);
    defineReflectiveTests(GetWithoutLimitRuleTest);
  });
}

@reflectiveTest
class UpdateDeleteWithoutWhereRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = UpdateDeleteWithoutWhereRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_updateWithoutWhere() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.update({'email': 'a'});
}
''';
    final offset = content.indexOf('update');
    await assertDiagnostics(content, [lint(offset, 'update'.length)]);
  }

  Future<void> test_updateWithWhereSplitChain() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.where('id', '=', 1);
  query.update({'email': 'a'});
}
''';
    await assertNoDiagnostics(content);
  }

  Future<void> test_deleteWithWhereSplitChain() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.where('id', '=', 1);
  query.delete();
}
''';
    await assertNoDiagnostics(content);
  }

  Future<void> test_deleteWithoutWhereSplitChainStillWarns() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build() {
  final query = Query<User>();
  query.delete();
}
''';
    final offset = content.indexOf('delete');
    await assertDiagnostics(content, [lint(offset, 'delete'.length)]);
  }
}

@reflectiveTest
class OffsetWithoutOrderRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = OffsetWithoutOrderRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_offsetWithoutOrder() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.offset(10);
}
''';
    final offset = content.indexOf('offset');
    await assertDiagnostics(content, [lint(offset, 'offset'.length)]);
  }

  Future<void> test_offsetWithOrderSplitChain() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.orderBy('id');
  query.offset(10);
}
''';
    await assertNoDiagnostics(content);
  }
}

@reflectiveTest
class LimitWithoutOrderRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = LimitWithoutOrderRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_limitWithoutOrder() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.limit(10);
}
''';
    final offset = content.indexOf('limit');
    await assertDiagnostics(content, [lint(offset, 'limit'.length)]);
  }

  Future<void> test_limitWithOrderSplitChain() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.orderBy('id');
  query.limit(10);
}
''';
    await assertNoDiagnostics(content);
  }
}

@reflectiveTest
class GetWithoutLimitRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = GetWithoutLimitRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_getWithoutLimit() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.get();
}
''';
    final offset = content.indexOf('get');
    await assertDiagnostics(content, [lint(offset, 'get'.length)]);
  }

  Future<void> test_getWithLimitSplitChain() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.limit(10);
  query.get();
}
''';
    await assertNoDiagnostics(content);
  }

  Future<void> test_rowsWithoutLimit() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.rows();
}
''';
    final offset = content.indexOf('rows');
    await assertDiagnostics(content, [lint(offset, 'rows'.length)]);
  }

  Future<void> test_rowsWithLimitSplitChain() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.limit(10);
  query.rows();
}
''';
    await assertNoDiagnostics(content);
  }

  Future<void> test_getPartialWithoutLimit() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class Post extends Model<Post> with ModelFactoryCapable {
  Post();
}

class PostPartial implements PartialEntity<Post> {
  const PostPartial();
  factory PostPartial.fromRow(Map<String, Object?> row) => const PostPartial();
  @override
  Post toEntity() => Post();
  @override
  Map<String, Object?> toMap() => const {};
}

void build(Query<Post> query) {
  query.getPartial(PostPartial.fromRow);
}
''';
    final offset = content.indexOf('getPartial');
    await assertDiagnostics(content, [lint(offset, 'getPartial'.length)]);
  }

  Future<void> test_getPartialWithLimitSplitChain() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class Post extends Model<Post> with ModelFactoryCapable {
  Post();
}

class PostPartial implements PartialEntity<Post> {
  const PostPartial();
  factory PostPartial.fromRow(Map<String, Object?> row) => const PostPartial();
  @override
  Post toEntity() => Post();
  @override
  Map<String, Object?> toMap() => const {};
}

void build(Query<Post> query) {
  query.limit(10);
  query.getPartial(PostPartial.fromRow);
}
''';
    await assertNoDiagnostics(content);
  }

  Future<void> test_getWithLimitCascade() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build() {
  final query = Query<User>()..limit(10);
  query.get();
}
''';
    await assertNoDiagnostics(content);
  }

  Future<void> test_modelAllWithoutLimit() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build() {
  Model.all<User>();
}
''';
    final offset = content.indexOf('Model.all') + 'Model.'.length;
    await assertDiagnostics(content, [lint(offset, 'all'.length)]);
  }

  Future<void> test_companionAllWithoutLimit() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build() {
  ModelCompanion<User>().all();
}
''';
    final offset = content.indexOf('ModelCompanion<User>().all') +
        'ModelCompanion<User>().'.length;
    await assertDiagnostics(content, [lint(offset, 'all'.length)]);
  }

  Future<void> test_generatedCompanionAllWithoutLimit() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

class Users {
  const Users._();
  static Query<User> query([String? connection]) => Query<User>();
  static Future<List<User>> all({String? connection}) async => <User>[];
}

void build() {
  Users.all();
}
''';
    final offset = content.indexOf('Users.all') + 'Users.'.length;
    await assertDiagnostics(content, [lint(offset, 'all'.length)]);
  }

  Future<void> test_unrelatedAllDoesNotWarn() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

class AllHelpers {
  static Future<List<User>> all() async => <User>[];
}

void build() {
  AllHelpers.all();
}
''';
    await assertNoDiagnostics(content);
  }
}
