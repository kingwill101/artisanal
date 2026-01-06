import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/dto_rules.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InsertMissingRequiredRuleTest);
    defineReflectiveTests(UpdateMissingPkRuleTest);
  });
}

@reflectiveTest
class InsertMissingRequiredRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = InsertMissingRequiredRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testInsertMissingRequired() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

class UserInsertDto implements InsertDto<User> {
  const UserInsertDto({this.email});
  final String? email;
  @override
  Map<String, Object?> toMap() => <String, Object?>{};
}

void build(Repository<User> repo) {
  repo.insert(UserInsertDto(email: 'a'));
}
''';
    final offset = content.lastIndexOf('UserInsertDto');
    await assertDiagnostics(content, [lint(offset, 'UserInsertDto'.length)]);
  }
}

@reflectiveTest
class UpdateMissingPkRuleTest extends AnalysisRuleTest with OrmedTestMixin {
  @override
  void setUp() {
    rule = UpdateMissingPkRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testUpdateMissingPk() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

class UserUpdateDto implements UpdateDto<User> {
  const UserUpdateDto({this.email});
  final String? email;
  @override
  Map<String, Object?> toMap() => <String, Object?>{};
}

void build(Repository<User> repo) {
  repo.update(UserUpdateDto(email: 'a'));
}
''';
    final offset = content.lastIndexOf('UserUpdateDto');
    await assertDiagnostics(content, [lint(offset, 'UserUpdateDto'.length)]);
  }
}
