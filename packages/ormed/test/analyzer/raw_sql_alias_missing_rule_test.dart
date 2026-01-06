import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/raw_sql_alias_missing_rule.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RawSqlAliasMissingRuleTest);
  });
}

@reflectiveTest
class RawSqlAliasMissingRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = RawSqlAliasMissingRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_missingAlias() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.selectRaw('count(*)');
}
''';
    final offset = content.indexOf("'count(*)'");
    await assertDiagnostics(content, [lint(offset, "'count(*)'".length)]);
  }
}
