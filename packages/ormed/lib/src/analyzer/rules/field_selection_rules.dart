import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class UnknownSelectFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_unknown_select_field',
    "Unknown select field '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined field or column name.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnknownSelectFieldRule()
    : super(
        name: 'ormed_unknown_select_field',
        description: 'Reports unknown fields in select() or distinct() calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _SelectFieldVisitor(this, index));
  }
}

class DuplicateSelectFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_duplicate_select_field',
    "Duplicate select field '{0}' on model '{1}'.",
    correctionMessage: 'Remove duplicated select entries.',
    severity: DiagnosticSeverity.WARNING,
  );

  DuplicateSelectFieldRule()
    : super(
        name: 'ormed_duplicate_select_field',
        description: 'Reports duplicate field names in select() calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _DuplicateSelectVisitor(this, index));
  }
}

class UnknownOrderFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_unknown_order_field',
    "Unknown order field '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined field or column name.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnknownOrderFieldRule()
    : super(
        name: 'ormed_unknown_order_field',
        description: 'Reports unknown fields in orderBy() calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _OrderFieldVisitor(this, index));
  }
}

class UnknownGroupFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_unknown_group_field',
    "Unknown group field '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined field or column name.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnknownGroupFieldRule()
    : super(
        name: 'ormed_unknown_group_field',
        description: 'Reports unknown fields in groupBy() calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _GroupFieldVisitor(this, index));
  }
}

class UnknownHavingFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_unknown_having_field',
    "Unknown having field '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined field or column name.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnknownHavingFieldRule()
    : super(
        name: 'ormed_unknown_having_field',
        description: 'Reports unknown fields in having() calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _HavingFieldVisitor(this, index));
  }
}

class _SelectFieldVisitor extends SimpleAstVisitor<void> {
  _SelectFieldVisitor(this.rule, this.index);

  final UnknownSelectFieldRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {'select', 'distinct'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_methods.contains(methodName)) return;

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final columns = _stringLiteralsFromList(args.first);
    if (columns.isEmpty) return;

    for (final column in columns) {
      final normalized = _normalizeFieldName(column.value);
      if (normalized == null) continue;
      if (!modelInfo.allFieldNames.contains(normalized)) {
        rule.reportAtNode(
          column.node,
          arguments: [normalized, modelInfo.modelName],
        );
      }
    }
  }
}

class _DuplicateSelectVisitor extends SimpleAstVisitor<void> {
  _DuplicateSelectVisitor(this.rule, this.index);

  final DuplicateSelectFieldRule rule;
  final OrmModelIndex index;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'select') return;

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final columns = _stringLiteralsFromList(args.first);
    if (columns.isEmpty) return;

    final seen = <String>{};
    for (final column in columns) {
      final normalized = _normalizeFieldName(column.value);
      if (normalized == null) continue;
      if (!seen.add(normalized)) {
        rule.reportAtNode(
          column.node,
          arguments: [normalized, modelInfo.modelName],
        );
      }
    }
  }
}

class _OrderFieldVisitor extends SimpleAstVisitor<void> {
  _OrderFieldVisitor(this.rule, this.index);

  final UnknownOrderFieldRule rule;
  final OrmModelIndex index;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'orderBy') return;

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final value = simpleStringLiteralValue(args.first);
    if (value == null) return;

    final normalized = _normalizeFieldName(value);
    if (normalized == null) return;
    if (modelInfo.allFieldNames.contains(normalized)) return;

    rule.reportAtNode(args.first, arguments: [normalized, modelInfo.modelName]);
  }
}

class _GroupFieldVisitor extends SimpleAstVisitor<void> {
  _GroupFieldVisitor(this.rule, this.index);

  final UnknownGroupFieldRule rule;
  final OrmModelIndex index;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'groupBy') return;

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final columns = _stringLiteralsFromList(args.first);
    if (columns.isEmpty) return;

    for (final column in columns) {
      final normalized = _normalizeFieldName(column.value);
      if (normalized == null) continue;
      if (!modelInfo.allFieldNames.contains(normalized)) {
        rule.reportAtNode(
          column.node,
          arguments: [normalized, modelInfo.modelName],
        );
      }
    }
  }
}

class _HavingFieldVisitor extends SimpleAstVisitor<void> {
  _HavingFieldVisitor(this.rule, this.index);

  final UnknownHavingFieldRule rule;
  final OrmModelIndex index;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'having') return;

    final modelType = modelTypeNameFromExpression(
      node.realTarget ?? node.target,
      'Query',
    );
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final value = simpleStringLiteralValue(args.first);
    if (value == null) return;

    final normalized = _normalizeFieldName(value);
    if (normalized == null) return;
    if (modelInfo.allFieldNames.contains(normalized)) return;

    rule.reportAtNode(args.first, arguments: [normalized, modelInfo.modelName]);
  }
}

class _LiteralEntry {
  _LiteralEntry(this.value, this.node);

  final String value;
  final Expression node;
}

Iterable<_LiteralEntry> _stringLiteralsFromList(Expression expression) {
  if (expression is! ListLiteral) return const [];
  final values = <_LiteralEntry>[];
  for (final element in expression.elements) {
    if (element is! Expression) continue;
    final value = simpleStringLiteralValue(element);
    if (value == null) continue;
    values.add(_LiteralEntry(value, element));
  }
  return values;
}

String? _normalizeFieldName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.contains(RegExp(r'\s'))) return null;
  if (trimmed.contains('(') || trimmed.contains(')')) return null;
  if (trimmed.contains(',')) return null;
  final jsonIndex = trimmed.indexOf('->');
  if (jsonIndex > 0) {
    final base = trimmed.substring(0, jsonIndex);
    return base.isEmpty ? null : base;
  }
  if (trimmed.contains('.')) return null;
  return trimmed;
}
