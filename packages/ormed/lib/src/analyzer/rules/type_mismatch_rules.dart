import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class TypeMismatchEqualsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_type_mismatch_eq',
    "Type mismatch for field '{0}' on model '{1}'.",
    correctionMessage: 'Use a value compatible with the field type.',
    severity: DiagnosticSeverity.WARNING,
  );

  TypeMismatchEqualsRule()
    : super(
        name: 'ormed_type_mismatch_eq',
        description: 'Reports obvious type mismatches in equals comparisons.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _TypeMismatchEqualsVisitor(this, index));
  }
}

class WhereInTypeMismatchRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_where_in_type_mismatch',
    "Type mismatch for field '{0}' on model '{1}'.",
    correctionMessage: 'Use values compatible with the field type.',
    severity: DiagnosticSeverity.WARNING,
  );

  WhereInTypeMismatchRule()
    : super(
        name: 'ormed_where_in_type_mismatch',
        description: 'Reports obvious type mismatches in whereIn calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _WhereInMismatchVisitor(this, index));
  }
}

class WhereBetweenTypeMismatchRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_where_between_type_mismatch',
    "Type mismatch for field '{0}' on model '{1}'.",
    correctionMessage: 'Use values compatible with the field type.',
    severity: DiagnosticSeverity.WARNING,
  );

  WhereBetweenTypeMismatchRule()
    : super(
        name: 'ormed_where_between_type_mismatch',
        description: 'Reports obvious type mismatches in whereBetween calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(
      this,
      _WhereBetweenMismatchVisitor(this, index),
    );
  }
}

class _TypeMismatchEqualsVisitor extends SimpleAstVisitor<void> {
  _TypeMismatchEqualsVisitor(this.rule, this.index);

  final TypeMismatchEqualsRule rule;
  final OrmModelIndex index;

  static const Set<String> _eqMethods = {
    'whereEquals',
    'whereNotEquals',
    'orWhereEquals',
    'orWhereNotEquals',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_eqMethods.contains(methodName)) return;

    final modelType = _modelTypeForTarget(node.realTarget ?? node.target);
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final fieldName = simpleStringLiteralValue(args.first);
    if (fieldName == null) return;

    final field = modelInfo.fieldFor(fieldName);
    if (field == null) return;

    final fieldCategory = _categoryForField(field);
    if (fieldCategory == null) return;

    final valueCategory = _categoryForValue(args[1]);
    if (valueCategory == null) return;
    if (fieldCategory != valueCategory) {
      rule.reportAtNode(args[1], arguments: [field.name, modelInfo.modelName]);
    }
  }
}

class _WhereInMismatchVisitor extends SimpleAstVisitor<void> {
  _WhereInMismatchVisitor(this.rule, this.index);

  final WhereInTypeMismatchRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {
    'whereIn',
    'whereNotIn',
    'orWhereIn',
    'orWhereNotIn',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_methods.contains(methodName)) return;

    final modelType = _modelTypeForTarget(node.realTarget ?? node.target);
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final fieldName = simpleStringLiteralValue(args.first);
    if (fieldName == null) return;

    final field = modelInfo.fieldFor(fieldName);
    if (field == null) return;

    final fieldCategory = _categoryForField(field);
    if (fieldCategory == null) return;

    final values = args[1];
    if (values is! ListLiteral) return;

    bool sawLiteral = false;
    for (final element in values.elements) {
      if (element is! Expression) continue;
      final valueCategory = _categoryForValue(element);
      if (valueCategory == null) continue;
      sawLiteral = true;
      if (valueCategory != fieldCategory) {
        rule.reportAtNode(element, arguments: [field.name, modelInfo.modelName]);
        return;
      }
    }
    if (!sawLiteral) return;
  }
}

class _WhereBetweenMismatchVisitor extends SimpleAstVisitor<void> {
  _WhereBetweenMismatchVisitor(this.rule, this.index);

  final WhereBetweenTypeMismatchRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {
    'whereBetween',
    'whereNotBetween',
    'orWhereBetween',
    'orWhereNotBetween',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_methods.contains(methodName)) return;

    final modelType = _modelTypeForTarget(node.realTarget ?? node.target);
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.length < 3) return;

    final fieldName = simpleStringLiteralValue(args.first);
    if (fieldName == null) return;

    final field = modelInfo.fieldFor(fieldName);
    if (field == null) return;

    final fieldCategory = _categoryForField(field);
    if (fieldCategory == null) return;

    final lowerCategory = _categoryForValue(args[1]);
    final upperCategory = _categoryForValue(args[2]);
    if (lowerCategory == null || upperCategory == null) return;

    if (lowerCategory != fieldCategory || upperCategory != fieldCategory) {
      rule.reportAtNode(args[1], arguments: [field.name, modelInfo.modelName]);
    }
  }
}

String? _modelTypeForTarget(Expression? target) {
  return modelTypeNameFromExpression(target, 'Query') ??
      modelTypeNameFromExpression(target, 'PredicateBuilder');
}

enum _FieldTypeCategory { string, number, boolean }

_FieldTypeCategory? _categoryForField(OrmFieldInfo field) {
  final type = _normalizeTypeName(field.resolvedType);
  if (type == null) return null;
  if (type == 'String') return _FieldTypeCategory.string;
  if (type == 'bool') return _FieldTypeCategory.boolean;
  if (type == 'int' || type == 'double' || type == 'num' || type == 'BigInt') {
    return _FieldTypeCategory.number;
  }
  return null;
}

_FieldTypeCategory? _categoryForValue(Expression value) {
  if (value is SimpleStringLiteral || value is AdjacentStrings) {
    return _FieldTypeCategory.string;
  }
  if (value is StringInterpolation) {
    return _FieldTypeCategory.string;
  }
  if (value is IntegerLiteral || value is DoubleLiteral) {
    return _FieldTypeCategory.number;
  }
  if (value is BooleanLiteral) {
    return _FieldTypeCategory.boolean;
  }
  return null;
}

String? _normalizeTypeName(String typeName) {
  var normalized = typeName.trim();
  if (normalized.isEmpty) return null;
  if (normalized.endsWith('?')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  final genericIndex = normalized.indexOf('<');
  if (genericIndex > 0) {
    normalized = normalized.substring(0, genericIndex);
  }
  return normalized;
}
