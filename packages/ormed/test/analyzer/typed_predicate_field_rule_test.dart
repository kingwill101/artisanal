import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/typed_predicate_field_rule.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypedPredicateFieldRuleTest);
  });
}

@reflectiveTest
class TypedPredicateFieldRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = TypedPredicateFieldRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> test_unknownTypedField() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User({required this.id, required this.email});
  final int id;
  final String email;
}

void build(Query<User> query) {
  // ignore: undefined_getter
  query.whereTyped((q) => q.emali.eq('a'));
}
''';
    final offset = content.indexOf('emali');
    await assertDiagnostics(content, [lint(offset, 'emali'.length)]);
  }
}
