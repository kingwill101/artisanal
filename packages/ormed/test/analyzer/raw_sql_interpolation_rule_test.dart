import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/raw_sql_interpolation_rule.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RawSqlInterpolationRuleTest);
  });
}

@reflectiveTest
class RawSqlInterpolationRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = RawSqlInterpolationRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_interpolated_raw_sql() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query, String status) {
  query.whereRaw('status = $status');
}
''';
    final offset = content.indexOf(r"'status = $status'");
    await assertDiagnostics(content, [
      lint(offset, r"'status = $status'".length),
    ]);
  }

  Future<void> test_raw_sql_with_bindings() async {
    await assertNoDiagnostics(r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query, String status) {
  query.whereRaw('status = ?', [status]);
}
''');
  }

  Future<void> test_rule_disabled_via_analysis_options() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      '''
ormed:
  lints:
    raw_sql_interpolation: ignore
''',
    );
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query, String status) {
  query.whereRaw('status = $status');
}
''';
    await assertNoDiagnostics(content);
  }
}
