import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:ormed/src/annotations.dart';

import '../descriptors.dart';
import '../model_context.dart';

class ModelSubclassEmitter {
  ModelSubclassEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final className = context.className;
    final modelSubclassName = context.trackedModelClassName;

    // Generate documentation for the tracked model class
    buffer.writeln('/// Generated tracked model class for [$className].');
    buffer.writeln('///');
    buffer.writeln(
      '/// This class extends the user-defined [$className] model and adds',
    );
    buffer.writeln(
      '/// attribute tracking, change detection, and relationship management.',
    );
    buffer.writeln(
      '/// Instances of this class are returned by queries and repositories.',
    );
    buffer.writeln('///');
    buffer.writeln(
      '/// **Do not instantiate this class directly.** Use queries, repositories,',
    );
    buffer.writeln('/// or model factories to create tracked model instances.');

    // The generated tracked model class needs ModelAttributes mixin
    // to enable attribute tracking and change detection.
    // Note: The base Model class already includes ModelConnection and ModelRelations,
    // so we only need to add ModelAttributes when extending Model.
    final mixins = <String>[];

    if (context.extendsModel) {
      // User model extends Model, so we only need to add ModelAttributes
      // (Model already includes ModelConnection and ModelRelations)
      mixins.add('ModelAttributes');

      // Add timestamp implementation mixins
      if (context.mixinTimestamps) {
        mixins.add('TimestampsImpl');
      } else if (context.mixinTimestampsTZ) {
        mixins.add('TimestampsTZImpl');
      }

      // Add soft delete implementation mixin
      if (context.mixinSoftDeletesTZ) {
        mixins.add('SoftDeletesTZImpl');
      } else if (context.effectiveSoftDeletes) {
        // Use the implementation mixin, not the marker mixin
        mixins.add('SoftDeletesImpl');
      }
    } else {
      // If not extending Model, we need to add all the mixins
      if (!context.mixinModelAttributes) {
        mixins.add('ModelAttributes');
      }
      if (!context.mixinModelConnection) {
        mixins.add('ModelConnection');
      }
      mixins.add('ModelRelations');

      // Add timestamp implementation mixins
      if (context.mixinTimestamps) {
        mixins.add('TimestampsImpl');
      } else if (context.mixinTimestampsTZ) {
        mixins.add('TimestampsTZImpl');
      }

      // Add soft delete implementation mixin
      if (context.mixinSoftDeletesTZ) {
        mixins.add('SoftDeletesTZImpl');
      } else if (context.effectiveSoftDeletes) {
        // Use the implementation mixin, not the marker mixin
        mixins.add('SoftDeletesImpl');
      }
    }

    final mixinSuffix = mixins.isEmpty ? '' : ' with ${mixins.join(', ')}';
    buffer.writeln(
      'class $modelSubclassName extends $className$mixinSuffix implements OrmEntity {',
    );
    buffer.writeln(
      '  $modelSubclassName${_constructorParameters(context.constructor, context.fields)}',
    );
    buffer.writeln('      : super${_superInvocation(context.constructor)} {');
    buffer.writeln('    _attachOrmRuntimeMetadata({');
    for (final field in context.fields.where((f) => !f.isVirtual)) {
      buffer.writeln("      '${field.columnName}': ${field.name},");
    }
    buffer.writeln('    });');
    buffer.writeln('  }\n');

    // Add factory constructor to convert from user model
    buffer.writeln(
      '  /// Creates a tracked model instance from a user-defined model instance.',
    );
    buffer.writeln(
      '  factory $modelSubclassName.fromModel($className model) {',
    );
    buffer.writeln('    return $modelSubclassName(');
    for (final field in context.fields.where((f) => !f.isVirtual)) {
      buffer.writeln('      ${field.name}: model.${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }\n');

    // copyWith helper for immutable updates
    if (context.constructor.formalParameters.every((p) => p.isNamed)) {
      buffer.writeln('  $modelSubclassName copyWith({');
      for (final field in context.fields.where((f) => !f.isVirtual)) {
        final paramType = field.resolvedType.endsWith('?')
            ? field.resolvedType
            : '${field.resolvedType}?';
        buffer.writeln('    $paramType ${field.name},');
      }
      buffer.writeln('  }) {');
      buffer.writeln('    return $modelSubclassName(');
      for (final field in context.fields.where((f) => !f.isVirtual)) {
        buffer.writeln(
          "      ${field.name}: ${field.name} ?? this.${field.name},",
        );
      }
      buffer.writeln('    );');
      buffer.writeln('  }\n');
    }

    for (final field in context.fields.where((f) => !f.isVirtual)) {
      buffer.writeln('  @override');
      buffer.writeln(
        '  ${field.resolvedType} get ${field.name} => getAttribute<${field.resolvedType}>(\'${field.columnName}\') ?? super.${field.name};',
      );
      buffer.writeln();
      buffer.writeln(
        '  set ${field.name}(${field.resolvedType} value) => setAttribute(\'${field.columnName}\', value);',
      );
      buffer.writeln();
    }

    buffer.writeln(
      '  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {',
    );
    buffer.writeln('    replaceAttributes(values);');
    buffer.writeln(
      '    attachModelDefinition(_${modelSubclassName}Definition);',
    );
    if (context.effectiveSoftDeletes) {
      buffer.writeln(
        "    attachSoftDeleteColumn('${context.softDeleteColumn}');",
      );
    }
    buffer.writeln('  }');

    // Generate relation getter overrides with loaded checks
    for (final relation in context.relations) {
      final isList = relation.isList;
      final isNullable = relation.isNullable;

      // Determine return type based on relation type and field nullability
      final String returnType;
      if (isList) {
        // List relations (hasMany, manyToMany, morphMany) always return non-nullable List
        // to provide a consistent API - empty list instead of null
        returnType = 'List<${relation.targetModel}>';
      } else {
        // Single relations are always nullable (may not be loaded)
        returnType = '${relation.targetModel}?';
      }

      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  $returnType get ${relation.name} {');
      buffer.writeln("    if (relationLoaded('${relation.name}')) {");

      if (isList) {
        buffer.writeln(
          "      return getRelationList<${relation.targetModel}>('${relation.name}');",
        );
      } else {
        buffer.writeln(
          "      return getRelation<${relation.targetModel}>('${relation.name}');",
        );
      }

      buffer.writeln('    }');

      // For list relations, always ensure non-null return (use ?? const [] if super is nullable)
      // For single relations, return super as-is (nullable)
      if (isList) {
        if (isNullable) {
          // Super field is nullable, need to coalesce to empty list
          buffer.writeln('    return super.${relation.name} ?? const [];');
        } else {
          // Super field is non-nullable, no coalescing needed
          buffer.writeln('    return super.${relation.name};');
        }
      } else {
        buffer.writeln('    return super.${relation.name};');
      }
      buffer.writeln('  }');
    }

    buffer.writeln('}');
    buffer.writeln();

    // Generate relation query methods as extension
    if (context.relations.isNotEmpty) {
      buffer.writeln('extension ${className}RelationQueries on $className {');
      for (final relation in context.relations) {
        final targetType = relation.targetModel;
        buffer.writeln('  Query<$targetType> ${relation.name}Query() {');

        if (relation.kind == RelationKind.belongsTo) {
          final foreignKeyField = context.fields.firstWhereOrNull(
            (f) => f.columnName == relation.foreignKey,
          );
          final foreignKeyGetter =
              foreignKeyField?.name ?? 'getAttribute("${relation.foreignKey}")';

          buffer.writeln(
            '    return Model.query<$targetType>().where(\'${relation.localKey}\', $foreignKeyGetter);',
          );
        } else if (relation.kind == RelationKind.hasOne ||
            relation.kind == RelationKind.hasMany) {
          final localKeyField = context.fields.firstWhereOrNull(
            (f) => f.columnName == relation.localKey,
          );
          final localKeyGetter =
              localKeyField?.name ?? 'getAttribute("${relation.localKey}")';

          buffer.writeln(
            '    return Model.query<$targetType>().where(\'${relation.foreignKey}\', $localKeyGetter);',
          );
        } else if (relation.kind == RelationKind.manyToMany) {
          final ownerKeyField = context.fields.firstWhereOrNull(
            (f) => f.isPrimaryKey,
          );
          final ownerKeyGetter = ownerKeyField?.name ?? 'getAttribute("id")';

          buffer.writeln('    final query = Model.query<$targetType>();');
          buffer.writeln('    final targetTable = query.definition.tableName;');
          buffer.writeln(
            '    final targetKey = ${relation.localKey != null ? "'${relation.localKey}'" : "query.definition.primaryKeyField?.columnName ?? 'id'"};',
          );
          buffer.writeln('    return query.join(');
          buffer.writeln('      \'${relation.through}\',');
          buffer.writeln('      \'\$targetTable.\$targetKey\',');
          buffer.writeln('      \'=\',');
          buffer.writeln('      \'${relation.through}.${relation.pivotRelatedKey}\',');
          buffer.writeln(
            '    ).where(\'${relation.through}.${relation.pivotForeignKey}\', $ownerKeyGetter);',
          );
        } else if (relation.kind == RelationKind.morphOne ||
            relation.kind == RelationKind.morphMany) {
          buffer.writeln(
            '    throw UnimplementedError("Polymorphic relation query generation not yet supported");',
          );
        } else {
          // Fallback for any other relation kinds
          buffer.writeln(
            '    throw UnimplementedError("Relation query generation not supported for ${relation.kind}");',
          );
        }

        buffer.writeln('  }');
        buffer.writeln();
      }
      buffer.writeln('}');
      buffer.writeln();
    }

    // Generate toTracked() extension for converting user models to ORM-managed models
    final extensionName = '${className}OrmExtension';
    buffer.writeln('extension $extensionName on $className {');
    buffer.writeln('  /// The Type of the generated ORM-managed model class.');
    buffer.writeln(
      '  /// Use this when you need to specify the tracked model type explicitly,',
    );
    buffer.writeln('  /// for example in generic type parameters.');
    buffer.writeln('  static Type get trackedType => $modelSubclassName;');
    buffer.writeln();
    buffer.writeln(
      '  /// Converts this immutable model to a tracked ORM-managed model.',
    );
    buffer.writeln(
      '  /// The tracked model supports attribute tracking, change detection,',
    );
    buffer.writeln('  /// and persistence operations like save() and touch().');
    buffer.writeln('  $modelSubclassName toTracked() {');
    buffer.writeln('    return $modelSubclassName.fromModel(this);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    // Note: We don't generate an extension with setters on the base class because
    // setAttribute() only exists on the generated subclass (via ModelAttributes mixin).
    // Users should use the generated model type or access via repository/query builder.

    // Generate scope extensions and registrations
    if (context.scopes.isNotEmpty) {
      buffer.writeln(_emitScopeExtensions());
      buffer.writeln(_emitScopeRegistrations());
    }

    return buffer.toString();
  }

  String _emitScopeExtensions() {
    final buffer = StringBuffer();
    final className = context.className;
    final trackedName = context.trackedModelClassName;
    buffer.writeln('extension ${trackedName}Scopes on Query<$trackedName> {');
    for (final scope in context.scopes) {
      final signature = _scopeMethodSignature(scope);
      final call = _scopeInvocation(
        scope,
        receiver: className,
        firstArgument: 'this',
      );
      buffer.writeln('  Query<$trackedName> ${scope.name}$signature => $call;');
    }
    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }

  String _emitScopeRegistrations() {
    final buffer = StringBuffer();
    final className = context.className;
    final trackedName = context.trackedModelClassName;
    buffer.writeln('void register${className}Scopes(ScopeRegistry registry) {');

    for (final scope in context.scopes) {
      final identifier = scope.identifier;
      if (scope.isGlobal) {
        buffer.writeln('  registry.addGlobalScope<$trackedName>(');
        buffer.writeln("    '$identifier',");
        buffer.writeln('    (query) => query.${scope.name}(),');
        buffer.writeln('  );');
      } else {
        buffer.writeln("  registry.addLocalScope<$trackedName>('$identifier',");
        buffer.writeln('    (query, args) {');
        final tail = scope.parameters.skip(1).toList();
        final call = StringBuffer('      return query.${scope.name}(');
        int index = 0;
        for (final param in tail.where((p) => !p.isNamed)) {
          call.write('args[$index] as ${param.type.getDisplayString()}, ');
          index++;
        }
        for (final param in tail.where((p) => p.isNamed)) {
          final typeStr = param.type.getDisplayString();
          if (param.isRequiredNamed) {
            call.write('${param.displayName}: args[$index] as $typeStr, ');
          } else {
            call.write(
              '${param.displayName}: args.length > $index ? args[$index] as $typeStr : ${param.defaultValueCode ?? 'null'}, ',
            );
          }
          index++;
        }
        call.write(');');
        buffer.writeln(call.toString());
        buffer.writeln('    },');
        buffer.writeln('  );');
      }
    }

    buffer.writeln('}');
    buffer.writeln();
    return buffer.toString();
  }

  String _scopeMethodSignature(ScopeDescriptor scope) {
    final tail = scope.parameters.skip(1).toList();
    if (tail.isEmpty) return '()';

    final requiredPos = tail.where((p) => p.isRequiredPositional).toList();
    final optionalPos = tail.where((p) => p.isOptionalPositional).toList();
    final named = tail.where((p) => p.isNamed).toList();

    final buffer = StringBuffer('(');
    // required positional
    for (final param in requiredPos) {
      buffer.write('${param.type.getDisplayString()} ${param.displayName}, ');
    }
    // optional positional
    if (optionalPos.isNotEmpty) {
      buffer.write('[');
      for (final param in optionalPos) {
        buffer.write('${param.type.getDisplayString()} ${param.displayName}');
        if (param.defaultValueCode != null) {
          buffer.write(' = ${param.defaultValueCode}');
        }
        buffer.write(', ');
      }
      buffer.write(']');
    }
    // named
    if (named.isNotEmpty) {
      buffer.write('{');
      for (final param in named) {
        if (param.isRequiredNamed) {
          buffer.write('required ');
        }
        buffer.write('${param.type.getDisplayString()} ${param.displayName}');
        if (param.defaultValueCode != null) {
          buffer.write(' = ${param.defaultValueCode}');
        }
        buffer.write(', ');
      }
      buffer.write('}');
    }

    buffer.write(')');
    return buffer.toString();
  }

  String _scopeInvocation(
    ScopeDescriptor scope, {
    String receiver = '',
    String? argsSource,
    String firstArgument = 'this',
    bool includeOptional = true,
  }) {
    final target = receiver.isEmpty ? scope.name : '$receiver.${scope.name}';
    final tail = scope.parameters.skip(1).toList();
    if (tail.isEmpty || !includeOptional) {
      return '$target($firstArgument)';
    }

    // If argsSource is null, use parameter names (for extensions).
    if (argsSource == null) {
      final call = StringBuffer('$target($firstArgument');
      for (final param in tail.where((p) => !p.isNamed)) {
        call.write(', ${param.displayName}');
      }
      for (final param in tail.where((p) => p.isNamed)) {
        call.write(', ${param.displayName}: ${param.displayName}');
      }
      call.write(')');
      return call.toString();
    }

    // Otherwise use args list.
    final call = StringBuffer('$target($firstArgument');
    int index = 0;
    for (final param in tail.where((p) => !p.isNamed)) {
      final hasArg = '$argsSource.length > $index';
      final defaultExpr = param.defaultValueCode ?? 'null';
      final valueExpr = param.isOptionalPositional
          ? '($hasArg ? $argsSource[$index] : $defaultExpr)'
          : '$argsSource[$index]';
      call.write(', $valueExpr as ${param.type.getDisplayString()}');
      index++;
    }
    final named = tail.where((p) => p.isNamed).toList();
    for (final param in named) {
      final hasArg = '$argsSource.length > $index';
      final defaultExpr = param.defaultValueCode ?? 'null';
      final valueExpr = param.isRequiredNamed
          ? '$argsSource[$index]'
          : '($hasArg ? $argsSource[$index] : $defaultExpr)';
      call.write(
        ', ${param.displayName}: $valueExpr as ${param.type.getDisplayString()}',
      );
      index++;
    }
    call.write(')');
    return call.toString();
  }

  String _constructorParameters(
    ConstructorElement constructor,
    List<FieldDescriptor> fields,
  ) {
    final buffer = StringBuffer();
    buffer.write('({');
    for (final parameter in constructor.formalParameters) {
      final paramName = parameter.displayName;
      final field = fields.firstWhereOrNull(
        (f) => !f.isVirtual && f.name == paramName,
      );
      if (field == null) continue;

      // Check if this field has a default value (e.g., auto-increment sentinel)
      final hasDefaultValue = field.autoIncrement && !field.isNullable;

      if (!hasDefaultValue && (parameter.isRequired || !field.isNullable)) {
        buffer.write('required ');
      }
      buffer.write('${field.resolvedType} $paramName');

      // Add default value for auto-increment fields
      if (hasDefaultValue) {
        buffer.write(' = 0');
      }
      buffer.write(', ');
    }
    buffer.write('})');
    return buffer.toString();
  }

  String _superInvocation(ConstructorElement constructor) {
    final buffer = StringBuffer();
    if ((constructor.name ?? '').isNotEmpty) {
      buffer.write('.${constructor.name}');
    }
    buffer.write('(');
    for (final parameter in constructor.formalParameters) {
      final paramName = parameter.displayName;
      if (parameter.isNamed) {
        buffer.write('$paramName: $paramName, ');
      } else {
        buffer.write('$paramName, ');
      }
    }
    buffer.write(')');
    return buffer.toString();
  }
}
