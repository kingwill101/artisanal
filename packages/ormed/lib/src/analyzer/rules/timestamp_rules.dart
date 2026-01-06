import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class WithTrashedOnNonSoftDeleteRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_with_trashed_on_non_soft_delete',
    "withTrashed used on model '{0}' without soft deletes.",
    correctionMessage: 'Enable soft deletes or remove withTrashed().',
    severity: DiagnosticSeverity.WARNING,
  );

  WithTrashedOnNonSoftDeleteRule()
    : super(
        name: 'ormed_with_trashed_on_non_soft_delete',
        description:
            'Reports withTrashed/onlyTrashed calls on models without soft deletes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _WithTrashedVisitor(this, index));
  }
}

class WithoutTimestampsOnTimestampedModelRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_without_timestamps_on_timestamped_model',
    "withoutTimestamps used on model '{0}' with timestamps enabled.",
    correctionMessage: 'Avoid disabling timestamps on timestamped models.',
    severity: DiagnosticSeverity.WARNING,
  );

  WithoutTimestampsOnTimestampedModelRule()
    : super(
        name: 'ormed_without_timestamps_on_timestamped_model',
        description:
            'Reports withoutTimestamps calls on models that use timestamps.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _WithoutTimestampsVisitor(this, index));
  }
}

class UpdatedAtAccessOnWithoutTimestampsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_updated_at_access_on_without_timestamps',
    "updatedAt accessed on model '{0}' with timestamps disabled.",
    correctionMessage: 'Enable timestamps or avoid updatedAt access.',
    severity: DiagnosticSeverity.WARNING,
  );

  UpdatedAtAccessOnWithoutTimestampsRule()
    : super(
        name: 'ormed_updated_at_access_on_without_timestamps',
        description:
            'Reports updatedAt access when timestamps are disabled on a model.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addPropertyAccess(this, _UpdatedAtAccessVisitor(this, index));
    registry.addPrefixedIdentifier(this, _UpdatedAtAccessVisitor(this, index));
  }
}

class _WithTrashedVisitor extends SimpleAstVisitor<void> {
  _WithTrashedVisitor(this.rule, this.index);

  final WithTrashedOnNonSoftDeleteRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {'withTrashed', 'onlyTrashed'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_methods.contains(node.methodName.name)) return;

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    if (!modelInfo.softDeletesEnabled) {
      rule.reportAtNode(node.methodName, arguments: [modelInfo.modelName]);
    }
  }
}

class _WithoutTimestampsVisitor extends SimpleAstVisitor<void> {
  _WithoutTimestampsVisitor(this.rule, this.index);

  final WithoutTimestampsOnTimestampedModelRule rule;
  final OrmModelIndex index;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'withoutTimestamps') return;

    final target = node.realTarget ?? node.target;
    final modelType = _modelTypeForInstance(target, index);
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    if (modelInfo.timestampsEnabled) {
      rule.reportAtNode(node.methodName, arguments: [modelInfo.modelName]);
    }
  }
}

class _UpdatedAtAccessVisitor extends SimpleAstVisitor<void> {
  _UpdatedAtAccessVisitor(this.rule, this.index);

  final UpdatedAtAccessOnWithoutTimestampsRule rule;
  final OrmModelIndex index;

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name != 'updatedAt') return;
    final target = node.target;
    if (target == null) return;

    final modelType = _modelTypeForInstance(target, index);
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    if (!modelInfo.timestampsEnabled) {
      rule.reportAtNode(node.propertyName, arguments: [modelInfo.modelName]);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name != 'updatedAt') return;

    final modelType = _modelTypeForInstance(node.prefix, index);
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    if (!modelInfo.timestampsEnabled) {
      rule.reportAtNode(node.identifier, arguments: [modelInfo.modelName]);
    }
  }
}

String? _modelTypeForInstance(Expression? target, OrmModelIndex index) {
  if (target == null) return null;
  final directName = interfaceTypeNameFromExpression(target);
  if (directName != null && index.modelForType(directName) != null) {
    return directName;
  }
  return modelTypeNameFromExpression(target, 'Model');
}
