import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/unknown_field_rule.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownFieldRuleTest);
  });
}

@reflectiveTest
class UnknownFieldRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = UnknownFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_knownField() async {
    await assertNoDiagnostics(r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.where('email', 'a');
  query.where('email_address', 'a');
}
''');
  }

  Future<void> test_unknownField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.where('emali', 'a');
}
''';
    final offset = content.indexOf("'emali'");
    await assertDiagnostics(content, [lint(offset, "'emali'".length)]);
  }
}
