import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class TypedPredicateFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_typed_predicate_field',
    "Unknown typed predicate field '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined model field.',
    severity: DiagnosticSeverity.WARNING,
  );

  TypedPredicateFieldRule()
    : super(
        name: 'ormed_typed_predicate_field',
        description:
            'Reports typed predicate field accessors that do not exist on the model.',
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

  final TypedPredicateFieldRule rule;
  final OrmModelIndex index;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target == null) return;

    Expression? base;
    SimpleIdentifier? fieldIdentifier;

    if (target is PropertyAccess) {
      base = target.target;
      fieldIdentifier = target.propertyName;
    } else if (target is PrefixedIdentifier) {
      base = target.prefix;
      fieldIdentifier = target.identifier;
    } else {
      return;
    }

    final modelType = modelTypeNameFromExpression(base, 'PredicateBuilder');
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final fieldName = fieldIdentifier.name;
    if (modelInfo.allFieldNames.contains(fieldName)) return;

    rule.reportAtNode(
      fieldIdentifier,
      arguments: [fieldName, modelInfo.modelName],
    );
  }
}
