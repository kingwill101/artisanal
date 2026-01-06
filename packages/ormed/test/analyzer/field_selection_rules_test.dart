import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/field_selection_rules.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownSelectFieldRuleTest);
    defineReflectiveTests(DuplicateSelectFieldRuleTest);
    defineReflectiveTests(UnknownOrderFieldRuleTest);
    defineReflectiveTests(UnknownGroupFieldRuleTest);
    defineReflectiveTests(UnknownHavingFieldRuleTest);
  });
}

@reflectiveTest
class UnknownSelectFieldRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = UnknownSelectFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_unknownSelectField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.select(['missing']);
}
''';
    final offset = content.indexOf("'missing'");
    await assertDiagnostics(content, [lint(offset, "'missing'".length)]);
  }
}

@reflectiveTest
class DuplicateSelectFieldRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = DuplicateSelectFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_duplicateSelectField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.select(['email', 'email']);
}
''';
    final offset = content.lastIndexOf("'email'");
    await assertDiagnostics(content, [lint(offset, "'email'".length)]);
  }
}

@reflectiveTest
class UnknownOrderFieldRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = UnknownOrderFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_unknownOrderField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.orderBy('missing');
}
''';
    final offset = content.indexOf("'missing'");
    await assertDiagnostics(content, [lint(offset, "'missing'".length)]);
  }
}

@reflectiveTest
class UnknownGroupFieldRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = UnknownGroupFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_unknownGroupField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.groupBy(['missing']);
}
''';
    final offset = content.indexOf("'missing'");
    await assertDiagnostics(content, [lint(offset, "'missing'".length)]);
  }
}

@reflectiveTest
class UnknownHavingFieldRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = UnknownHavingFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_unknownHavingField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.having('missing', PredicateOperator.equals, 1);
}
''';
    final offset = content.indexOf("'missing'");
    await assertDiagnostics(content, [lint(offset, "'missing'".length)]);
  }
}
