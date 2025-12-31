import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class UnknownRelationRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_unknown_relation',
    "Unknown relation '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined relation name.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnknownRelationRule()
    : super(
        name: 'ormed_unknown_relation',
        description:
            'Reports unknown relation names in Ormed relation helpers.',
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

  final UnknownRelationRule rule;
  final OrmModelIndex index;

  static const Set<String> _relationMethods = {
    'withRelation',
    'withRelationTyped',
    'whereHas',
    'whereHasTyped',
    'orWhereHas',
    'orWhereHasTyped',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_relationMethods.contains(methodName)) return;

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final relation = _stringLiteralValue(args.first);
    if (relation == null) return;

    if (!modelInfo.relationNames.contains(relation)) {
      rule.reportAtNode(args.first, arguments: [relation, modelInfo.modelName]);
    }
  }

  String? _stringLiteralValue(Expression expression) {
    if (expression is SimpleStringLiteral) {
      return expression.value;
    }
    if (expression is AdjacentStrings) {
      final buffer = StringBuffer();
      for (final string in expression.strings) {
        if (string is SimpleStringLiteral) {
          buffer.write(string.value);
        } else {
          return null;
        }
      }
      return buffer.toString();
    }
    return null;
  }
}
