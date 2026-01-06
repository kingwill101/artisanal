import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class UnknownFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_unknown_field',
    "Unknown field '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined field or column name.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnknownFieldRule()
    : super(
        name: 'ormed_unknown_field',
        description:
            'Reports unknown field or column names in Ormed query builder calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _Visitor(this, index));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.index);

  final UnknownFieldRule rule;
  final OrmModelIndex index;

  static const Set<String> _singleFieldMethods = {
    'where',
    'whereEquals',
    'whereNotEquals',
    'whereIn',
    'whereNotIn',
    'whereNull',
    'whereNotNull',
    'whereLike',
    'whereNotLike',
    'whereILike',
    'whereNotILike',
    'whereBetween',
    'whereNotBetween',
    'whereBitwise',
    'orWhere',
    'orWhereEquals',
    'orWhereNotEquals',
    'orWhereIn',
    'orWhereNotIn',
    'orWhereNull',
    'orWhereNotNull',
    'orWhereLike',
    'orWhereNotLike',
    'orWhereILike',
    'orWhereNotILike',
    'orWhereBetween',
    'orWhereNotBetween',
    'orWhereBitwise',
  };

  static const Set<String> _doubleFieldMethods = {
    'whereColumn',
    'orWhereColumn',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_singleFieldMethods.contains(methodName) &&
        !_doubleFieldMethods.contains(methodName)) {
      return;
    }

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    if (_doubleFieldMethods.contains(methodName)) {
      if (args.length >= 2) {
        _checkFieldArg(args[0], modelInfo);
        _checkFieldArg(args[1], modelInfo);
      }
      return;
    }

    _checkFieldArg(args[0], modelInfo);
  }

  void _checkFieldArg(Expression expression, OrmModelInfo modelInfo) {
    if (expression is ListLiteral) {
      for (final element in expression.elements) {
        if (element is Expression) {
          _checkFieldArg(element, modelInfo);
        }
      }
      return;
    }

    final value = simpleStringLiteralValue(expression);
    if (value == null) return;
    if (modelInfo.allFieldNames.contains(value)) return;

    rule.reportAtNode(expression, arguments: [value, modelInfo.modelName]);
  }

}
