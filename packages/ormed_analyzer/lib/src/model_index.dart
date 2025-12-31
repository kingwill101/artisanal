import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:path/path.dart' as p;

class OrmModelInfo {
  OrmModelInfo({
    required this.modelName,
    required this.trackedTypeName,
    required Set<String> fieldNames,
    required Set<String> columnNames,
    required Set<String> relationNames,
  }) : fieldNames = Set.unmodifiable(fieldNames),
       columnNames = Set.unmodifiable(columnNames),
       relationNames = Set.unmodifiable(relationNames);

  final String modelName;
  final String trackedTypeName;
  final Set<String> fieldNames;
  final Set<String> columnNames;
  final Set<String> relationNames;

  Set<String> get allFieldNames => {...fieldNames, ...columnNames};
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
      final fieldsByConst = <String, _FieldInfo>{};
      final relationsByConst = <String, String>{};
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
            final relationName = _parseRelationDefinition(invocation.arguments);
            if (relationName != null) {
              relationsByConst[variable.name.lexeme] = relationName;
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
        final fieldNames = <String>{};
        final columnNames = <String>{};
        for (final fieldConst in pending.fieldConsts) {
          final info = fieldsByConst[fieldConst];
          if (info == null) continue;
          fieldNames.add(info.name);
          columnNames.add(info.columnName);
        }
        final relationNames = <String>{};
        for (final relationConst in pending.relationConsts) {
          final name = relationsByConst[relationConst];
          if (name != null) {
            relationNames.add(name);
          }
        }
        final model = OrmModelInfo(
          modelName: pending.modelName,
          trackedTypeName: pending.trackedTypeName,
          fieldNames: fieldNames,
          columnNames: columnNames,
          relationNames: relationNames,
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

class _FieldInfo {
  _FieldInfo({required this.name, required this.columnName});

  final String name;
  final String columnName;
}

class _PendingModelDef {
  _PendingModelDef({
    required this.modelName,
    required this.trackedTypeName,
    required this.fieldConsts,
    required this.relationConsts,
  });

  final String modelName;
  final String trackedTypeName;
  final List<String> fieldConsts;
  final List<String> relationConsts;
}

class _InvocationInfo {
  _InvocationInfo(this.typeName, this.arguments);

  final String typeName;
  final NodeList<Expression> arguments;
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

_FieldInfo? _parseFieldDefinition(NodeList<Expression> arguments) {
  String? name;
  String? columnName;
  for (final argument in arguments) {
    if (argument is! NamedExpression) continue;
    final argName = argument.name.label.name;
    final value = _stringLiteralValue(argument.expression);
    if (argName == 'name' && value != null) {
      name = value;
    } else if (argName == 'columnName' && value != null) {
      columnName = value;
    }
  }
  if (name == null) return null;
  return _FieldInfo(name: name, columnName: columnName ?? name);
}

String? _parseRelationDefinition(NodeList<Expression> arguments) {
  for (final argument in arguments) {
    if (argument is! NamedExpression) continue;
    final argName = argument.name.label.name;
    if (argName != 'name') continue;
    final value = _stringLiteralValue(argument.expression);
    if (value != null) {
      return value;
    }
  }
  return null;
}

_PendingModelDef? _parseModelDefinition(
  NodeList<Expression> arguments,
  TypeAnnotation? typeAnnotation,
) {
  String? modelName;
  List<String> fieldConsts = const [];
  List<String> relationConsts = const [];

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
    }
  }

  if (modelName == null) {
    return null;
  }
  final trackedType = _trackedTypeName(typeAnnotation) ?? modelName;
  return _PendingModelDef(
    modelName: modelName,
    trackedTypeName: trackedType,
    fieldConsts: fieldConsts,
    relationConsts: relationConsts,
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
