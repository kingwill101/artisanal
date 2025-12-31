import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/raw_sql_interpolation_rule.dart';
import 'src/rules/typed_predicate_field_rule.dart';
import 'src/rules/unknown_field_rule.dart';
import 'src/rules/unknown_relation_rule.dart';

final plugin = OrmedAnalyzerPlugin();

class OrmedAnalyzerPlugin extends Plugin {
  @override
  String get name => 'ormed_analyzer';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(UnknownFieldRule());
    registry.registerWarningRule(UnknownRelationRule());
    registry.registerWarningRule(TypedPredicateFieldRule());
    registry.registerWarningRule(RawSqlInterpolationRule());
  }
}
