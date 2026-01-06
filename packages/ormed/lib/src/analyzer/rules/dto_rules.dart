import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../model_index.dart';
import '../type_utils.dart';

class InsertMissingRequiredRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_insert_missing_required',
    "Insert is missing required fields for model '{0}'.",
    correctionMessage: 'Provide all required fields for insert inputs.',
    severity: DiagnosticSeverity.WARNING,
  );

  InsertMissingRequiredRule()
    : super(
        name: 'ormed_insert_missing_required',
        description: 'Reports insert DTOs/maps missing required fields.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _InsertMissingRequiredVisitor(this, index));
  }
}

class UpdateMissingPkRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'ormed_update_missing_pk',
    "Update input is missing a primary key for model '{0}'.",
    correctionMessage: 'Include the primary key or provide a where clause.',
    severity: DiagnosticSeverity.WARNING,
  );

  UpdateMissingPkRule()
    : super(
        name: 'ormed_update_missing_pk',
        description: 'Reports update DTOs missing primary keys when required.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final index = OrmModelIndexCache.forContext(context);
    registry.addMethodInvocation(this, _UpdateMissingPkVisitor(this, index));
  }
}

class _InsertMissingRequiredVisitor extends SimpleAstVisitor<void> {
  _InsertMissingRequiredVisitor(this.rule, this.index);

  final InsertMissingRequiredRule rule;
  final OrmModelIndex index;

  static const Set<String> _methods = {
    'insert',
    'insertMany',
    'insertOrIgnore',
    'insertOrIgnoreMany',
    'insertManyInputs',
    'insertManyInputsRaw',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_methods.contains(node.methodName.name)) return;

    final target = node.realTarget ?? node.target;
    final modelType =
        modelTypeNameFromExpression(target, 'Repository') ??
        modelTypeNameFromExpression(target, 'Query');
    if (modelType == null) return;

    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final inputs = _expandInputs(args.first);
    if (inputs.isEmpty) return;

    for (final input in inputs) {
      if (_isInsertMissingRequired(modelInfo, input)) {
        rule.reportAtNode(_reportNode(input), arguments: [modelInfo.modelName]);
      }
    }
  }
}

class _UpdateMissingPkVisitor extends SimpleAstVisitor<void> {
  _UpdateMissingPkVisitor(this.rule, this.index);

  final UpdateMissingPkRule rule;
  final OrmModelIndex index;

  static const Set<String> _repoMethods = {
    'update',
    'updateMany',
    'updateManyRaw',
  };

  static const Set<String> _queryMethods = {
    'updateInputs',
    'updateInputsRaw',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    final target = node.realTarget ?? node.target;

    String? modelType;
    bool requiresWhereParam = false;
    if (_repoMethods.contains(methodName)) {
      modelType = modelTypeNameFromExpression(target, 'Repository');
      requiresWhereParam = true;
    } else if (_queryMethods.contains(methodName)) {
      modelType = modelTypeNameFromExpression(target, 'Query');
      requiresWhereParam = true;
    } else {
      return;
    }

    if (modelType == null) return;
    final modelInfo = index.modelForType(modelType);
    if (modelInfo == null) return;

    if (requiresWhereParam && _hasNamedArgument(node.argumentList, 'where')) {
      return;
    }

    final pkField = modelInfo.primaryKeyField;
    if (pkField == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final inputs = _expandInputs(args.first);
    if (inputs.isEmpty) return;

    for (final input in inputs) {
      final missing = _isMissingPrimaryKey(modelInfo, pkField, input);
      if (missing == null) continue;
      if (missing) {
        rule.reportAtNode(_reportNode(input), arguments: [modelInfo.modelName]);
      }
    }
  }
}

List<Expression> _expandInputs(Expression expression) {
  if (expression is ListLiteral) {
    final values = <Expression>[];
    for (final element in expression.elements) {
      if (element is Expression) {
        values.add(element);
      }
    }
    return values;
  }
  return [expression];
}

bool _isInsertMissingRequired(OrmModelInfo modelInfo, Expression input) {
  final requiredFields = _requiredInsertFields(modelInfo);
  if (requiredFields.isEmpty) return false;

  if (input is InstanceCreationExpression) {
    final dtoModel = _modelNameFromDto(
      input.constructorName.type.name.lexeme,
      'InsertDto',
    );
    if (dtoModel == null || dtoModel != modelInfo.modelName) {
      return false;
    }
    final provided = _namedArguments(input.argumentList.arguments);
    return _missingFromProvided(requiredFields, provided);
  }

  if (input is SetOrMapLiteral && input.isMap) {
    final keys = _mapLiteralKeys(input);
    return _missingFromMapKeys(requiredFields, keys);
  }

  return false;
}

bool? _isMissingPrimaryKey(
  OrmModelInfo modelInfo,
  OrmFieldInfo pkField,
  Expression input,
) {
  final pkNames = {pkField.name, pkField.columnName};

  if (input is InstanceCreationExpression) {
    final dtoModel = _modelNameFromDto(input.constructorName.type.name.lexeme, 'UpdateDto');
    if (dtoModel == null || dtoModel != modelInfo.modelName) {
      return null;
    }
    final provided = _namedArguments(input.argumentList.arguments);
    return provided.intersection(pkNames).isEmpty;
  }

  if (input is SetOrMapLiteral && input.isMap) {
    final keys = _mapLiteralKeys(input);
    return keys.intersection(pkNames).isEmpty;
  }

  return null;
}

List<OrmFieldInfo> _requiredInsertFields(OrmModelInfo modelInfo) {
  final required = <OrmFieldInfo>[];
  for (final field in modelInfo.fieldsByName.values) {
    if (!field.isRequiredOnInsert) continue;
    if (_isTimestampField(modelInfo, field)) continue;
    required.add(field);
  }
  return required;
}

bool _isTimestampField(OrmModelInfo modelInfo, OrmFieldInfo field) {
  if (!modelInfo.timestampsEnabled) return false;
  final name = field.name;
  final column = field.columnName;
  return name == 'createdAt' ||
      name == 'updatedAt' ||
      column == 'created_at' ||
      column == 'updated_at';
}

AstNode _reportNode(Expression input) {
  if (input is InstanceCreationExpression) {
    return input.constructorName.type;
  }
  return input;
}

String? _modelNameFromDto(String typeName, String suffix) {
  if (!typeName.endsWith(suffix)) return null;
  var base = typeName.substring(0, typeName.length - suffix.length);
  if (base.startsWith(r'$')) {
    base = base.substring(1);
  }
  return base;
}

Set<String> _namedArguments(NodeList<Expression> args) {
  final names = <String>{};
  for (final arg in args) {
    if (arg is NamedExpression) {
      names.add(arg.name.label.name);
    }
  }
  return names;
}

Set<String> _mapLiteralKeys(SetOrMapLiteral map) {
  final keys = <String>{};
  for (final element in map.elements) {
    if (element is! MapLiteralEntry) continue;
    final key = element.key;
    final value = simpleStringLiteralValue(key);
    if (value != null) {
      keys.add(value);
    }
  }
  return keys;
}

bool _missingFromProvided(
  List<OrmFieldInfo> required,
  Set<String> provided,
) {
  for (final field in required) {
    if (!provided.contains(field.name)) {
      return true;
    }
  }
  return false;
}

bool _missingFromMapKeys(List<OrmFieldInfo> required, Set<String> keys) {
  for (final field in required) {
    if (keys.contains(field.name) || keys.contains(field.columnName)) {
      continue;
    }
    return true;
  }
  return false;
}

bool _hasNamedArgument(ArgumentList args, String name) {
  for (final arg in args.arguments) {
    if (arg is NamedExpression && arg.name.label.name == name) {
      return true;
    }
  }
  return false;
}
