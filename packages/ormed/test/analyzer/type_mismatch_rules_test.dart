import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/type_mismatch_rules.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeMismatchEqualsRuleTest);
    defineReflectiveTests(WhereInTypeMismatchRuleTest);
    defineReflectiveTests(WhereBetweenTypeMismatchRuleTest);
  });
}

@reflectiveTest
class TypeMismatchEqualsRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = TypeMismatchEqualsRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_equalsTypeMismatch() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email, required this.age});
  final int id;
  final String email;
  final int age;
}

void build(Query<User> query) {
  query.whereEquals('age', 'ten');
}
''';
    final offset = content.indexOf("'ten'");
    await assertDiagnostics(content, [lint(offset, "'ten'".length)]);
  }
}

@reflectiveTest
class WhereInTypeMismatchRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = WhereInTypeMismatchRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_whereInTypeMismatch() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email, required this.age});
  final int id;
  final String email;
  final int age;
}

void build(Query<User> query) {
  query.whereIn('age', ['ten']);
}
''';
    final offset = content.indexOf("'ten'");
    await assertDiagnostics(content, [lint(offset, "'ten'".length)]);
  }
}

@reflectiveTest
class WhereBetweenTypeMismatchRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = WhereBetweenTypeMismatchRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_whereBetweenTypeMismatch() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email, required this.age});
  final int id;
  final String email;
  final int age;
}

void build(Query<User> query) {
  query.whereBetween('age', 'a', 'z');
}
''';
    final offset = content.indexOf("'a'");
    await assertDiagnostics(content, [lint(offset, "'a'".length)]);
  }
}
