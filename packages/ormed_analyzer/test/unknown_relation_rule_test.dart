import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed_analyzer/src/rules/unknown_relation_rule.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownRelationRuleTest);
  });
}

@reflectiveTest
class UnknownRelationRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = UnknownRelationRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_unknownRelation() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  query.withRelation('postz');
}
''';
    final offset = content.indexOf("'postz'");
    await assertDiagnostics(content, [lint(offset, "'postz'".length)]);
  }
}
