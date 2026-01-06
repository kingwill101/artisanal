import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package:ormed/src/analyzer/rules/timestamp_rules.dart';
import 'support/ormed_test_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WithTrashedOnNonSoftDeleteRuleTest);
    defineReflectiveTests(WithoutTimestampsOnTimestampedModelRuleTest);
    defineReflectiveTests(UpdatedAtAccessOnWithoutTimestampsRuleTest);
  });
}

@reflectiveTest
class WithTrashedOnNonSoftDeleteRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = WithTrashedOnNonSoftDeleteRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testWithTrashedOnNonSoftDelete() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(Query<User> query) {
  query.withTrashed();
}
''';
    final offset = content.indexOf('withTrashed');
    await assertDiagnostics(content, [lint(offset, 'withTrashed'.length)]);
  }
}

@reflectiveTest
class WithoutTimestampsOnTimestampedModelRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = WithoutTimestampsOnTimestampedModelRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testWithoutTimestampsOnTimestampedModel() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class User extends Model<User> with ModelFactoryCapable {
  User();
}

void build(User user) {
  user.withoutTimestamps(() {});
}
''';
    final offset = content.indexOf('withoutTimestamps');
    await assertDiagnostics(content, [lint(offset, 'withoutTimestamps'.length)]);
  }
}

@reflectiveTest
class UpdatedAtAccessOnWithoutTimestampsRuleTest extends AnalysisRuleTest
    with OrmedTestMixin {
  @override
  void setUp() {
    rule = UpdatedAtAccessOnWithoutTimestampsRule();
    addMockOrmedPackage();
    writeOrmFixture();
    super.setUp();
  }

  Future<void> testUpdatedAtAccessOnWithoutTimestamps() async {
    const content = r'''
import 'package:ormed/ormed.dart';

class Post extends Model<Post> with ModelFactoryCapable {
  Post();
  Object? updatedAt;
}

void build(Post post) {
  post.updatedAt;
}
''';
    final offset = content.lastIndexOf('updatedAt');
    await assertDiagnostics(content, [lint(offset, 'updatedAt'.length)]);
  }
}
