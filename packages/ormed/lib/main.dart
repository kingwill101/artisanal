import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/analyzer/rules/dto_rules.dart';
import 'src/analyzer/rules/field_selection_rules.dart';
import 'src/analyzer/rules/query_safety_rules.dart';
import 'src/analyzer/rules/raw_sql_alias_missing_rule.dart';
import 'src/analyzer/rules/raw_sql_interpolation_rule.dart';
import 'src/analyzer/rules/relation_rules.dart';
import 'src/analyzer/rules/timestamp_rules.dart';
import 'src/analyzer/rules/type_mismatch_rules.dart';
import 'src/analyzer/rules/typed_predicate_field_rule.dart';
import 'src/analyzer/rules/unknown_field_rule.dart';
import 'src/analyzer/rules/unknown_relation_rule.dart';

final plugin = OrmedAnalyzerPlugin();

class OrmedAnalyzerPlugin extends Plugin {
  @override
  String get name => 'ormed';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(UnknownFieldRule());
    registry.registerWarningRule(UnknownRelationRule());
    registry.registerWarningRule(TypedPredicateFieldRule());
    registry.registerWarningRule(RawSqlInterpolationRule());
    registry.registerWarningRule(UnknownSelectFieldRule());
    registry.registerWarningRule(UnknownOrderFieldRule());
    registry.registerWarningRule(UnknownGroupFieldRule());
    registry.registerWarningRule(UnknownHavingFieldRule());
    registry.registerWarningRule(DuplicateSelectFieldRule());
    registry.registerWarningRule(TypeMismatchEqualsRule());
    registry.registerWarningRule(WhereInTypeMismatchRule());
    registry.registerWarningRule(WhereBetweenTypeMismatchRule());
    registry.registerWarningRule(UnknownNestedRelationRule());
    registry.registerWarningRule(InvalidWhereHasRule());
    registry.registerWarningRule(RelationFieldMismatchRule());
    registry.registerWarningRule(MissingPivotFieldRule());
    registry.registerWarningRule(WithTrashedOnNonSoftDeleteRule());
    registry.registerWarningRule(WithoutTimestampsOnTimestampedModelRule());
    registry.registerWarningRule(UpdatedAtAccessOnWithoutTimestampsRule());
    registry.registerWarningRule(UpdateDeleteWithoutWhereRule());
    registry.registerWarningRule(OffsetWithoutOrderRule());
    registry.registerWarningRule(LimitWithoutOrderRule());
    registry.registerWarningRule(GetWithoutLimitRule());
    registry.registerWarningRule(RawSqlAliasMissingRule());
    registry.registerWarningRule(InsertMissingRequiredRule());
    registry.registerWarningRule(UpdateMissingPkRule());
  }
}
