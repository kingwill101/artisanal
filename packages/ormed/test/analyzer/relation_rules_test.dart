import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/relation_rules.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownNestedRelationRuleTest);
    defineReflectiveTests(InvalidWhereHasRuleTest);
    defineReflectiveTests(RelationFieldMismatchRuleTest);
    defineReflectiveTests(MissingPivotFieldRuleTest);
  });
}

@reflectiveTest
class UnknownNestedRelationRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = UnknownNestedRelationRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testUnknownNestedRelation() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.withRelation('posts.missing');
}
''';
    final offset = content.indexOf("'posts.missing'");
    await assertDiagnostics(content, [lint(offset, "'posts.missing'".length)]);
  }
}

@reflectiveTest
class InvalidWhereHasRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = InvalidWhereHasRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testInvalidWhereHas() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.whereHas('missing');
}
''';
    final offset = content.indexOf("'missing'");
    await assertDiagnostics(content, [lint(offset, "'missing'".length)]);
  }
}

@reflectiveTest
class RelationFieldMismatchRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = RelationFieldMismatchRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testRelationFieldMismatch() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.whereHas('posts', (q) => q.where('email', 'a'));
}
''';
    final offset = content.indexOf("'email'");
    await assertDiagnostics(content, [lint(offset, "'email'".length)]);
  }
}

@reflectiveTest
class MissingPivotFieldRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = MissingPivotFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testMissingPivotField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

const RelationDefinition badRelation = RelationDefinition(
  name: 'tags',
  kind: RelationKind.belongsToMany,
  targetModel: 'Tag',
  pivotColumns: ['missing_pivot'],
  pivotModel: 'PostTag',
);
''';
    final offset = content.indexOf("'missing_pivot'");
    await assertDiagnostics(content, [lint(offset, "'missing_pivot'".length)]);
  }
}
