import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_utils.dart';

class RawSqlAliasMissingRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_raw_sql_alias_missing',
    'selectRaw() is missing an alias.',
    correctionMessage: 'Provide an alias for selectRaw() expressions.',
    severity: DiagnosticSeverity.WARNING,
  );

  RawSqlAliasMissingRule()
    : super(
        name: 'ormed_raw_sql_alias_missing',
        description: 'Warns when selectRaw is missing an alias.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _RawAliasVisitor(this));
  }
}

class _RawAliasVisitor extends SimpleAstVisitor<void> {
  _RawAliasVisitor(this.rule);

  final RawSqlAliasMissingRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'selectRaw') return;

    final target = node.realTarget ?? node.target;
    final targetType = interfaceTypeFromExpression(target);
    if (targetType == null || targetType.element.name != 'Query') {
      return;
    }

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final sqlValue = simpleStringLiteralValue(args.first);
    if (sqlValue == null) return;

    if (_hasAliasArgument(args)) return;
    if (_sqlHasAlias(sqlValue)) return;

    rule.reportAtNode(args.first);
  }

  bool _hasAliasArgument(NodeList<Expression> args) {
    for (final arg in args) {
      if (arg is NamedExpression && arg.name.label.name == 'alias') {
        final value = arg.expression;
        if (value is NullLiteral) return false;
        return true;
      }
    }
    return false;
  }

  bool _sqlHasAlias(String sql) {
    return RegExp(r'\s+as\s+', caseSensitive: false).hasMatch(sql);
  }
}
