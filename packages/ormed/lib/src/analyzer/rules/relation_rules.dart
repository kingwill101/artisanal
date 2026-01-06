import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class UnknownNestedRelationRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_unknown_nested_relation',
    "Unknown nested relation '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined nested relation path.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnknownNestedRelationRule()
    : super(
        name: 'ormed_unknown_nested_relation',
        description: 'Reports unknown nested relations in withRelation calls.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _UnknownNestedVisitor(this, index));
  }
}

class InvalidWhereHasRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_invalid_where_has',
    "Unknown relation '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined relation name.',
    severity: DiagnosticSeverity.WARNING,
  );

  InvalidWhereHasRule()
    : super(
        name: 'ormed_invalid_where_has',
        description: 'Reports unknown relations used with whereHas.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _InvalidWhereHasVisitor(this, index));
  }
}

class RelationFieldMismatchRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_relation_field_mismatch',
    "Unknown field '{0}' on related model '{1}'.",
    correctionMessage: 'Use a defined field on the related model.',
    severity: DiagnosticSeverity.WARNING,
  );

  RelationFieldMismatchRule()
    : super(
        name: 'ormed_relation_field_mismatch',
        description: 'Reports invalid fields inside whereHas callbacks.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _RelationFieldVisitor(this, index));
  }
}

class MissingPivotFieldRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_missing_pivot_field',
    "Unknown pivot field '{0}' on model '{1}'.",
    correctionMessage: 'Use a defined pivot field or column name.',
    severity: DiagnosticSeverity.WARNING,
  );

  MissingPivotFieldRule()
    : super(
        name: 'ormed_missing_pivot_field',
        description: 'Reports missing pivot columns in relation definitions.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addInstanceCreationExpression(
      this,
      _MissingPivotVisitor(this, index),
    );
  }
}

class _UnknownNestedVisitor extends SimpleAstVisitor<void> {
  _UnknownNestedVisitor(this.rule, this.index);

  final UnknownNestedRelationRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {'withRelation', 'withRelationTyped'};

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

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final relationPath = simpleStringLiteralValue(args.first);
    if (relationPath == null) return;
    if (!relationPath.contains('.')) return;

    final segments = relationPath.split('.');
    var currentModel = modelInfo;
    for (final segment in segments) {
      final relation = currentModel.relationFor(segment);
      if (relation == null) {
        rule.reportAtNode(
          args.first,
          arguments: [segment, currentModel.modelName],
        );
        return;
      }
      final next = index.modelForType(relation.targetModel);
      if (next == null) {
        return;
      }
      currentModel = next;
    }
  }
}

class _InvalidWhereHasVisitor extends SimpleAstVisitor<void> {
  _InvalidWhereHasVisitor(this.rule, this.index);

  final InvalidWhereHasRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {
    'whereHas',
    'whereHasTyped',
    'orWhereHas',
    'orWhereHasTyped',
  };

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

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final relationName = simpleStringLiteralValue(args.first);
    if (relationName == null) return;
    if (relationName.contains('.')) return;

    if (modelInfo.relationFor(relationName) == null) {
      rule.reportAtNode(
        args.first,
        arguments: [relationName, modelInfo.modelName],
      );
    }
  }
}

class _RelationFieldVisitor extends SimpleAstVisitor<void> {
  _RelationFieldVisitor(this.rule, this.index);

  final RelationFieldMismatchRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {
    'whereHas',
    'whereHasTyped',
    'orWhereHas',
    'orWhereHasTyped',
  };

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

    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final relationName = simpleStringLiteralValue(args.first);
    if (relationName == null) return;
    if (relationName.contains('.')) return;

    final relation = modelInfo.relationFor(relationName);
    if (relation == null) return;

    final relatedModel = index.modelForType(relation.targetModel);
    if (relatedModel == null) return;

    final callback = args[1];
    if (callback is! FunctionExpression) return;

    final paramName = _firstParamName(callback.parameters);
    if (paramName == null) return;

    final visitor = _RelationCallbackVisitor(
      paramName: paramName,
      onField: (node, fieldName) {
        if (!relatedModel.allFieldNames.contains(fieldName)) {
          rule.reportAtNode(
            node,
            arguments: [fieldName, relatedModel.modelName],
          );
        }
      },
    );
    callback.body.visitChildren(visitor);
  }
}

class _MissingPivotVisitor extends SimpleAstVisitor<void> {
  _MissingPivotVisitor(this.rule, this.index);

  final MissingPivotFieldRule rule;
  final OrmModelIndex index;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name.lexeme;
    if (typeName != 'RelationDefinition') return;

    final details = _parseRelationDetails(node.argumentList.arguments);
    if (details == null) return;
    if (details.pivotColumns.isEmpty) return;
    if (details.pivotModel == null || details.pivotModel!.isEmpty) return;

    final pivotModel = index.modelForType(details.pivotModel!);
    if (pivotModel == null) return;

    for (final column in details.pivotColumns) {
      if (!pivotModel.allFieldNames.contains(column.value)) {
        rule.reportAtNode(
          column.node,
          arguments: [column.value, pivotModel.modelName],
        );
      }
    }
  }
}

class _RelationDetails {
  _RelationDetails({
    required this.name,
    required this.pivotColumns,
    required this.pivotModel,
  });

  final String name;
  final List<_LiteralEntry> pivotColumns;
  final String? pivotModel;
}

_RelationDetails? _parseRelationDetails(NodeList<Expression> arguments) {
  String? name;
  String? pivotModel;
  List<_LiteralEntry> pivotColumns = const [];

  for (final argument in arguments) {
    if (argument is! NamedExpression) continue;
    final argName = argument.name.label.name;
    final value = argument.expression;
    if (argName == 'name') {
      name = simpleStringLiteralValue(value);
    } else if (argName == 'pivotColumns') {
      pivotColumns = _stringLiteralsFromList(value);
    } else if (argName == 'pivotModel') {
      pivotModel = simpleStringLiteralValue(value);
    }
  }

  if (name == null) return null;
  return _RelationDetails(
    name: name,
    pivotColumns: pivotColumns,
    pivotModel: pivotModel,
  );
}

class _RelationCallbackVisitor extends RecursiveAstVisitor<void> {
  _RelationCallbackVisitor({required this.paramName, required this.onField});

  final String paramName;
  final void Function(AstNode node, String fieldName) onField;

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
    final isSingle = _singleFieldMethods.contains(methodName);
    final isDouble = _doubleFieldMethods.contains(methodName);
    if (!isSingle && !isDouble) {
      return;
    }

    final target = node.target;
    if (target is SimpleIdentifier && target.name == paramName) {
      _checkArguments(node.argumentList.arguments, isDouble: isDouble);
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final target = node.target;
    if (target is SimpleIdentifier && target.name == paramName) {
      for (final section in node.cascadeSections) {
        if (section is MethodInvocation) {
          final methodName = section.methodName.name;
          final isSingle = _singleFieldMethods.contains(methodName);
          final isDouble = _doubleFieldMethods.contains(methodName);
          if (!isSingle && !isDouble) continue;
          _checkArguments(section.argumentList.arguments, isDouble: isDouble);
        }
      }
    }
    super.visitCascadeExpression(node);
  }

  void _checkArguments(NodeList<Expression> args, {required bool isDouble}) {
    if (args.isEmpty) return;
    if (isDouble) {
      if (args.length >= 2) {
        _checkFieldArg(args[0]);
        _checkFieldArg(args[1]);
      }
      return;
    }
    _checkFieldArg(args[0]);
  }

  void _checkFieldArg(Expression expression) {
    if (expression is ListLiteral) {
      for (final element in expression.elements) {
        if (element is Expression) {
          _checkFieldArg(element);
        }
      }
      return;
    }

    final value = simpleStringLiteralValue(expression);
    if (value == null) return;
    onField(expression, value);
  }
}

String? _firstParamName(FormalParameterList? parameters) {
  if (parameters == null) return null;
  if (parameters.parameters.isEmpty) return null;
  final param = parameters.parameters.first;
  if (param is SimpleFormalParameter) {
    return param.name?.lexeme;
  }
  if (param is DefaultFormalParameter) {
    final inner = param.parameter;
    if (inner is SimpleFormalParameter) {
      return inner.name?.lexeme;
    }
  }
  return null;
}

class _LiteralEntry {
  _LiteralEntry(this.value, this.node);

  final String value;
  final Expression node;
}

List<_LiteralEntry> _stringLiteralsFromList(Expression expression) {
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
