import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as p;

class OrmFieldInfo {
  OrmFieldInfo({
    required this.name,
    required this.columnName,
    required this.dartType,
    required this.resolvedType,
    required this.isPrimaryKey,
    required this.isNullable,
    required this.autoIncrement,
    this.defaultValueSql,
  });

  final String name;
  final String columnName;
  final String dartType;
  final String resolvedType;
  final bool isPrimaryKey;
  final bool isNullable;
  final bool autoIncrement;
  final String? defaultValueSql;

  bool get isInsertable => !autoIncrement;

  bool get isRequiredOnInsert {
    if (!isInsertable) return false;
    if (isNullable) return false;
    if (defaultValueSql != null && defaultValueSql!.trim().isNotEmpty) {
      return false;
    }
    return true;
  }
}

class OrmRelationInfo {
  OrmRelationInfo({
    required this.name,
    required this.targetModel,
    required List<String> pivotColumns,
    this.pivotModel,
  }) : pivotColumns = List.unmodifiable(pivotColumns);

  final String name;
  final String targetModel;
  final List<String> pivotColumns;
  final String? pivotModel;
}

class OrmModelInfo {
  OrmModelInfo({
    required this.modelName,
    required this.trackedTypeName,
    required Map<String, OrmFieldInfo> fieldsByName,
    required Map<String, OrmFieldInfo> fieldsByColumn,
    required Map<String, OrmRelationInfo> relationsByName,
    required this.timestampsEnabled,
    required this.softDeletesEnabled,
    required this.softDeleteColumn,
  }) : fieldsByName = Map.unmodifiable(fieldsByName),
       fieldsByColumn = Map.unmodifiable(fieldsByColumn),
       relationsByName = Map.unmodifiable(relationsByName);

  final String modelName;
  final String trackedTypeName;
  final Map<String, OrmFieldInfo> fieldsByName;
  final Map<String, OrmFieldInfo> fieldsByColumn;
  final Map<String, OrmRelationInfo> relationsByName;
  final bool timestampsEnabled;
  final bool softDeletesEnabled;
  final String softDeleteColumn;

  Set<String> get fieldNames => fieldsByName.keys.toSet();
  Set<String> get columnNames => fieldsByColumn.keys.toSet();
  Set<String> get allFieldNames => {...fieldNames, ...columnNames};
  Set<String> get relationNames => relationsByName.keys.toSet();

  OrmFieldInfo? fieldFor(String nameOrColumn) {
    return fieldsByName[nameOrColumn] ?? fieldsByColumn[nameOrColumn];
  }

  OrmRelationInfo? relationFor(String name) => relationsByName[name];

  OrmFieldInfo? get primaryKeyField {
    for (final field in fieldsByName.values) {
      if (field.isPrimaryKey) return field;
    }
    return null;
  }
}

class OrmModelIndex {
  OrmModelIndex(this._modelsByType);

  final Map<String, OrmModelInfo> _modelsByType;

  OrmModelInfo? modelForType(String typeName) {
    var info = _modelsByType[typeName];
    if (info != null) {
      return info;
    }
    if (typeName.startsWith(r'$')) {
      return _modelsByType[typeName.substring(1)];
    }
    return null;
  }
}

class OrmModelIndexCache {
  static OrmModelIndex forContext(RuleContext context) {
    final root = _rootFolder(context);
    return _buildIndex(root);
  }

  static Folder _rootFolder(RuleContext context) {
    final packageRoot = context.package?.root;
    if (packageRoot != null) {
      return packageRoot;
    }
    return context.definingUnit.file.parent;
  }

  static OrmModelIndex _buildIndex(Folder root) {
    final files = _findOrmFiles(root);
    final models = <String, OrmModelInfo>{};
    for (final file in files) {
      final content = file.readAsStringSync();
      final result = parseString(content: content, path: file.path);
      if (result.errors.isNotEmpty) {
        continue;
      }
      final unit = result.unit;
      final fieldsByConst = <String, OrmFieldInfo>{};
      final relationsByConst = <String, OrmRelationInfo>{};
      final pendingModels = <_PendingModelDef>[];

      for (final declaration in unit.declarations) {
        if (declaration is! TopLevelVariableDeclaration) {
          continue;
        }
        final variableList = declaration.variables;
        for (final variable in variableList.variables) {
          final initializer = variable.initializer;
          final invocation = _invocationInfo(initializer);
          if (invocation == null) {
            continue;
          }
          final typeName = invocation.typeName;
          if (typeName == 'FieldDefinition') {
            final fieldInfo = _parseFieldDefinition(invocation.arguments);
            if (fieldInfo != null) {
              fieldsByConst[variable.name.lexeme] = fieldInfo;
            }
          } else if (typeName == 'RelationDefinition') {
            final relationInfo = _parseRelationDefinition(invocation.arguments);
            if (relationInfo != null) {
              relationsByConst[variable.name.lexeme] = relationInfo;
            }
          } else if (typeName == 'ModelDefinition') {
            final pending = _parseModelDefinition(
              invocation.arguments,
              variableList.type,
            );
            if (pending != null) {
              pendingModels.add(pending);
            }
          }
        }
      }

      for (final pending in pendingModels) {
        final fieldsByName = <String, OrmFieldInfo>{};
        final fieldsByColumn = <String, OrmFieldInfo>{};
        for (final fieldConst in pending.fieldConsts) {
          final info = fieldsByConst[fieldConst];
          if (info == null) continue;
          fieldsByName[info.name] = info;
          fieldsByColumn[info.columnName] = info;
        }
        final relationsByName = <String, OrmRelationInfo>{};
        for (final relationConst in pending.relationConsts) {
          final info = relationsByConst[relationConst];
          if (info != null) {
            relationsByName[info.name] = info;
          }
        }
        final model = OrmModelInfo(
          modelName: pending.modelName,
          trackedTypeName: pending.trackedTypeName,
          fieldsByName: fieldsByName,
          fieldsByColumn: fieldsByColumn,
          relationsByName: relationsByName,
          timestampsEnabled: pending.timestampsEnabled,
          softDeletesEnabled: pending.softDeletesEnabled,
          softDeleteColumn: pending.softDeleteColumn,
        );
        models[pending.modelName] = model;
        models[pending.trackedTypeName] = model;
      }
    }
    return OrmModelIndex(models);
  }

  static List<File> _findOrmFiles(Folder root) {
    final files = <File>[];
    final excluded = {
      '.dart_tool',
      '.git',
      '.idea',
      '.vscode',
      'build',
      'node_modules',
    };

    void visit(Folder folder) {
      for (final child in folder.getChildren()) {
        if (child is Folder) {
          if (excluded.contains(p.basename(child.path))) {
            continue;
          }
          visit(child);
        } else if (child is File) {
          if (child.path.endsWith('.orm.dart')) {
            files.add(child);
          }
        }
      }
    }

    visit(root);
    return files;
  }
}

class _PendingModelDef {
  _PendingModelDef({
    required this.modelName,
    required this.trackedTypeName,
    required this.fieldConsts,
    required this.relationConsts,
    required this.timestampsEnabled,
    required this.softDeletesEnabled,
    required this.softDeleteColumn,
  });

  final String modelName;
  final String trackedTypeName;
  final List<String> fieldConsts;
  final List<String> relationConsts;
  final bool timestampsEnabled;
  final bool softDeletesEnabled;
  final String softDeleteColumn;
}

class _InvocationInfo {
  _InvocationInfo(this.typeName, this.arguments);

  final String typeName;
  final NodeList<Expression> arguments;
}

class _ModelMetadata {
  const _ModelMetadata({
    required this.timestampsEnabled,
    required this.softDeletesEnabled,
    required this.softDeleteColumn,
  });

  final bool timestampsEnabled;
  final bool softDeletesEnabled;
  final String softDeleteColumn;

  static const defaults = _ModelMetadata(
    timestampsEnabled: true,
    softDeletesEnabled: false,
    softDeleteColumn: 'deleted_at',
  );
}

_InvocationInfo? _invocationInfo(Expression? initializer) {
  if (initializer is InstanceCreationExpression) {
    final typeName = _namedTypeName(initializer.constructorName.type);
    if (typeName == null) return null;
    return _InvocationInfo(typeName, initializer.argumentList.arguments);
  }
  if (initializer is MethodInvocation && initializer.target == null) {
    final typeName = initializer.methodName.name;
    return _InvocationInfo(typeName, initializer.argumentList.arguments);
  }
  return null;
}

OrmFieldInfo? _parseFieldDefinition(NodeList<Expression> arguments) {
  String? name;
  String? columnName;
  String? dartType;
  String? resolvedType;
  bool isPrimaryKey = false;
  bool isNullable = false;
  bool autoIncrement = false;
  String? defaultValueSql;

  for (final argument in arguments) {
    if (argument is! NamedExpression) continue;
    final argName = argument.name.label.name;
    final valueExpr = argument.expression;
    if (argName == 'name') {
      name = _stringLiteralValue(valueExpr);
    } else if (argName == 'columnName') {
      columnName = _stringLiteralValue(valueExpr);
    } else if (argName == 'dartType') {
      dartType = _stringLiteralValue(valueExpr);
    } else if (argName == 'resolvedType') {
      resolvedType = _stringLiteralValue(valueExpr);
    } else if (argName == 'isPrimaryKey') {
      final value = _boolLiteralValue(valueExpr);
      if (value != null) {
        isPrimaryKey = value;
      }
    } else if (argName == 'isNullable') {
      final value = _boolLiteralValue(valueExpr);
      if (value != null) {
        isNullable = value;
      }
    } else if (argName == 'autoIncrement') {
      final value = _boolLiteralValue(valueExpr);
      if (value != null) {
        autoIncrement = value;
      }
    } else if (argName == 'defaultValueSql') {
      defaultValueSql = _stringLiteralValue(valueExpr);
    }
  }

  if (name == null) return null;
  final resolvedColumn = columnName ?? name;
  return OrmFieldInfo(
    name: name,
    columnName: resolvedColumn,
    dartType: dartType ?? resolvedType ?? 'Object',
    resolvedType: resolvedType ?? dartType ?? 'Object',
    isPrimaryKey: isPrimaryKey,
    isNullable: isNullable,
    autoIncrement: autoIncrement,
    defaultValueSql: defaultValueSql,
  );
}

OrmRelationInfo? _parseRelationDefinition(NodeList<Expression> arguments) {
  String? name;
  String? targetModel;
  List<String> pivotColumns = const [];
  String? pivotModel;

  for (final argument in arguments) {
    if (argument is! NamedExpression) continue;
    final argName = argument.name.label.name;
    final valueExpr = argument.expression;
    if (argName == 'name') {
      name = _stringLiteralValue(valueExpr);
    } else if (argName == 'targetModel') {
      targetModel = _stringLiteralValue(valueExpr);
    } else if (argName == 'pivotColumns') {
      pivotColumns = _stringLiteralList(valueExpr);
    } else if (argName == 'pivotModel') {
      pivotModel = _stringLiteralValue(valueExpr);
    }
  }
  if (name == null || targetModel == null) {
    return null;
  }
  return OrmRelationInfo(
    name: name,
    targetModel: targetModel,
    pivotColumns: pivotColumns,
    pivotModel: pivotModel,
  );
}

_PendingModelDef? _parseModelDefinition(
  NodeList<Expression> arguments,
  TypeAnnotation? typeAnnotation,
) {
  String? modelName;
  List<String> fieldConsts = const [];
  List<String> relationConsts = const [];
  _ModelMetadata metadata = _ModelMetadata.defaults;
  String? softDeleteColumnOverride;

  for (final argument in arguments) {
    if (argument is! NamedExpression) continue;
    final argName = argument.name.label.name;
    final expression = argument.expression;
    if (argName == 'modelName') {
      modelName = _stringLiteralValue(expression);
    } else if (argName == 'fields') {
      fieldConsts = _identifierList(expression);
    } else if (argName == 'relations') {
      relationConsts = _identifierList(expression);
    } else if (argName == 'metadata') {
      metadata = _parseModelAttributesMetadata(expression) ?? metadata;
    } else if (argName == 'softDeleteColumn') {
      softDeleteColumnOverride = _stringLiteralValue(expression);
    }
  }

  if (modelName == null) {
    return null;
  }
  final trackedType = _trackedTypeName(typeAnnotation) ?? modelName;
  final softDeleteColumn =
      softDeleteColumnOverride ?? metadata.softDeleteColumn;

  return _PendingModelDef(
    modelName: modelName,
    trackedTypeName: trackedType,
    fieldConsts: fieldConsts,
    relationConsts: relationConsts,
    timestampsEnabled: metadata.timestampsEnabled,
    softDeletesEnabled: metadata.softDeletesEnabled,
    softDeleteColumn: softDeleteColumn,
  );
}

_ModelMetadata? _parseModelAttributesMetadata(Expression expression) {
  final invocation = _invocationInfo(expression);
  if (invocation == null || invocation.typeName != 'ModelAttributesMetadata') {
    return null;
  }
  var timestampsEnabled = _ModelMetadata.defaults.timestampsEnabled;
  var softDeletesEnabled = _ModelMetadata.defaults.softDeletesEnabled;
  var softDeleteColumn = _ModelMetadata.defaults.softDeleteColumn;

  for (final argument in invocation.arguments) {
    if (argument is! NamedExpression) continue;
    final argName = argument.name.label.name;
    final valueExpr = argument.expression;
    if (argName == 'timestamps') {
      final value = _boolLiteralValue(valueExpr);
      if (value != null) {
        timestampsEnabled = value;
      }
    } else if (argName == 'softDeletes') {
      final value = _boolLiteralValue(valueExpr);
      if (value != null) {
        softDeletesEnabled = value;
      }
    } else if (argName == 'softDeleteColumn') {
      final value = _stringLiteralValue(valueExpr);
      if (value != null) {
        softDeleteColumn = value;
      }
    }
  }

  return _ModelMetadata(
    timestampsEnabled: timestampsEnabled,
    softDeletesEnabled: softDeletesEnabled,
    softDeleteColumn: softDeleteColumn,
  );
}

String? _trackedTypeName(TypeAnnotation? annotation) {
  if (annotation is! NamedType) {
    return null;
  }
  if (annotation.typeArguments == null) {
    return null;
  }
  final args = annotation.typeArguments!.arguments;
  if (args.isEmpty) {
    return null;
  }
  final first = args.first;
  if (first is NamedType) {
    return first.name.lexeme;
  }
  return null;
}

String? _namedTypeName(NamedType? type) {
  if (type == null) return null;
  return type.name.lexeme;
}

List<String> _identifierList(Expression expression) {
  if (expression is! ListLiteral) {
    return const [];
  }
  final names = <String>[];
  for (final element in expression.elements) {
    if (element is! Expression) continue;
    final name = _identifierName(element);
    if (name != null) {
      names.add(name);
    }
  }
  return names;
}

String? _identifierName(Expression expression) {
  if (expression is SimpleIdentifier) {
    return expression.name;
  }
  if (expression is PrefixedIdentifier) {
    return expression.identifier.name;
  }
  return null;
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

List<String> _stringLiteralList(Expression expression) {
  if (expression is! ListLiteral) {
    return const [];
  }
  final values = <String>[];
  for (final element in expression.elements) {
    if (element is! Expression) continue;
    final value = _stringLiteralValue(element);
    if (value == null) {
      return const [];
    }
    values.add(value);
  }
  return values;
}

bool? _boolLiteralValue(Expression expression) {
  if (expression is BooleanLiteral) {
    return expression.value;
  }
  return null;
}
