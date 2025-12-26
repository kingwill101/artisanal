import 'package:ormed/src/builder/descriptors.dart';
import 'package:ormed/src/builder/helpers.dart';
import 'package:ormed/src/builder/model_context.dart';

import '../../model/model.dart';

class ModelDefinitionEmitter {
  ModelDefinitionEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final fields = context.fields;
    final relations = context.relations;
    final accessors = context.accessors;
    final mutators = context.mutators;
    final className = context.className;
    final tableName = context.tableName;
    final schema = context.schema;
    final softDeleteColumn = context.softDeleteColumn;
    final hiddenAnnotation = context.hiddenAnnotation;
    final visibleAnnotation = context.visibleAnnotation;
    final fillableAnnotation = context.fillableAnnotation;
    final guardedAnnotation = context.guardedAnnotation;
    final castsAnnotation = context.castsAnnotation;
    final appendsAnnotation = context.appendsAnnotation;
    final driverAnnotations = context.driverAnnotations;
    final connectionAnnotation = context.connectionAnnotation;
    final effectiveSoftDeletes = context.effectiveSoftDeletes;
    final generateCodec = context.generateCodec;

    _writeFields(buffer, fields);
    _writeRelations(buffer, relations);

    buffer.writeln(
      'Map<String, Object?> _encode${className}Untracked(Object model, ValueCodecRegistry registry) {',
    );
    buffer.writeln('  final m = model as $className;');
    buffer.writeln('  return <String, Object?>{');
    for (final field in fields) {
      if (field.isVirtual) {
        continue;
      }
      buffer.writeln(
        "    '${escape(field.columnName)}': registry.encodeField(${field.identifier}, m.${field.name}),",
      );
    }
    buffer.writeln('  };');
    buffer.writeln('}\n');

    final generatedClassName = context.trackedModelClassName;
    final modelVar =
        '_$generatedClassName'
        'Definition';
    buffer.writeln(
      'final ModelDefinition<$generatedClassName> $modelVar = ModelDefinition(',
    );
    buffer.writeln("  modelName: '${escape(className)}',");
    buffer.writeln("  tableName: '${escape(tableName!)}',");
    if (schema != null) {
      buffer.writeln("  schema: '${escape(schema)}',");
    }
    buffer.writeln('  fields: const [');
    for (final field in fields) {
      buffer.writeln('    ${field.identifier},');
    }
    buffer.writeln('  ],');
    buffer.writeln('  relations: const [');
    for (final relation in relations) {
      buffer.writeln('    ${relation.identifier},');
    }
    buffer.writeln('  ],');
    if (softDeleteColumn != null) {
      buffer.writeln("  softDeleteColumn: '${escape(softDeleteColumn)}',");
    }
    buffer.writeln('  metadata: ModelAttributesMetadata(');
    buffer.writeln('    hidden: ${stringListLiteral(hiddenAnnotation)},');
    buffer.writeln('    visible: ${stringListLiteral(visibleAnnotation)},');
    buffer.writeln('    fillable: ${stringListLiteral(fillableAnnotation)},');
    buffer.writeln('    guarded: ${stringListLiteral(guardedAnnotation)},');
    buffer.writeln('    casts: ${stringMapLiteral(castsAnnotation)},');
    buffer.writeln('    appends: ${stringListLiteral(appendsAnnotation)},');
    final fieldOverrides = fields.where((f) => f.attributeMetadata != null);
    if (fieldOverrides.isNotEmpty) {
      buffer.writeln('    fieldOverrides: const {');
      for (final field in fieldOverrides) {
        final override = field.attributeMetadata!;
        buffer.writeln(
          "      '${escape(field.columnName)}': FieldAttributeMetadata(",
        );
        if (override.fillable != null) {
          buffer.writeln('      fillable: ${boolLiteral(override.fillable!)},');
        }
        if (override.guarded != null) {
          buffer.writeln('      guarded: ${boolLiteral(override.guarded!)},');
        }
        if (override.hidden != null) {
          buffer.writeln('      hidden: ${boolLiteral(override.hidden!)},');
        }
        if (override.visible != null) {
          buffer.writeln('      visible: ${boolLiteral(override.visible!)},');
        }
        if (override.cast != null) {
          buffer.writeln("      cast: '${escape(override.cast!)}',");
        }
        buffer.writeln('      ),');
      }
      buffer.writeln('    },');
    }
    if (driverAnnotations.isNotEmpty) {
      buffer.writeln('    driverAnnotations: const [');
      for (final driver in driverAnnotations) {
        buffer.writeln("      DriverModel('${escape(driver)}'),");
      }
      buffer.writeln('    ],');
    }
    if (connectionAnnotation != null) {
      buffer.writeln("    connection: '${escape(connectionAnnotation)}',");
    }
    buffer.writeln(
      '    softDeletes: ${effectiveSoftDeletes ? 'true' : 'false'},',
    );
    final metadataSoftDeleteColumn =
        softDeleteColumn ?? SoftDeletes.defaultColumn;
    buffer.writeln(
      "    softDeleteColumn: '${escape(metadataSoftDeleteColumn)}',",
    );
    buffer.writeln('  ),');
    if (accessors.isNotEmpty) {
      buffer.writeln('  accessors: {');
      for (final accessor in accessors) {
        final attribute = escape(accessor.attribute);
        final target = className;
        final modelExpr = '(model as $className)';
        if (accessor.isGetter) {
          buffer.writeln(
            "    '$attribute': (model, value) => $target.${accessor.name},",
          );
        } else {
          final valueExpr = accessor.takesValue
              ? _castValue('value', accessor.valueType!)
              : null;
          final args = accessor.takesModel
              ? valueExpr == null
                  ? modelExpr
                  : '$modelExpr, $valueExpr'
              : valueExpr;
          buffer.writeln(
            "    '$attribute': (model, value) => $target.${accessor.name}(${args ?? ''}),",
          );
        }
      }
      buffer.writeln('  },');
    }
    if (mutators.isNotEmpty) {
      buffer.writeln('  mutators: {');
      for (final mutator in mutators) {
        final attribute = escape(mutator.attribute);
        final target = className;
        final modelExpr = '(model as $className)';
        final valueExpr = _castValue('value', mutator.valueType);
        final args = mutator.takesModel ? '$modelExpr, $valueExpr' : valueExpr;
        if (mutator.returnType == 'void') {
          buffer.writeln("    '$attribute': (model, value) {");
          buffer.writeln('      $target.${mutator.name}($args);');
          buffer.writeln('      return value;');
          buffer.writeln('    },');
        } else {
          buffer.writeln(
            "    '$attribute': (model, value) => $target.${mutator.name}($args),",
          );
        }
      }
      buffer.writeln('  },');
    }
    buffer.writeln('  untrackedToMap: _encode${className}Untracked,');
    if (generateCodec) {
      buffer.writeln('  codec: _${generatedClassName}Codec(),');
    } else {
      buffer.writeln('  codec: _${generatedClassName}UnsupportedCodec(),');
    }
    buffer.writeln(');\n');

    if (context.hasFactory) {
      buffer.writeln('// ignore: unused_element');
      buffer.writeln(
        'final ${className.toLowerCase()}ModelDefinitionRegistration = ModelFactoryRegistry.register<$generatedClassName>(',
      );
      buffer.writeln('  $modelVar,');
      buffer.writeln(');\n');
    }

    // Generate instance extension
    buffer.writeln('extension ${className}OrmDefinition on $className {');
    buffer.writeln(
      '  static ModelDefinition<$generatedClassName> get definition => $modelVar;',
    );
    buffer.writeln('}\n');

    return buffer.toString();
  }

  void _writeFields(StringBuffer buffer, List<FieldDescriptor> fields) {
    for (final field in fields) {
      buffer.writeln(
        'const FieldDefinition ${field.identifier} = FieldDefinition(',
      );
      buffer.writeln("  name: '${escape(field.name)}',");
      buffer.writeln("  columnName: '${escape(field.columnName)}',");
      buffer.writeln("  dartType: '${field.dartType}',");
      buffer.writeln("  resolvedType: '${field.resolvedType}',");
      buffer.writeln('  isPrimaryKey: ${field.isPrimaryKey},');
      buffer.writeln('  isNullable: ${field.isNullable},');
      buffer.writeln('  isUnique: ${field.isUnique},');
      buffer.writeln('  isIndexed: ${field.isIndexed},');
      buffer.writeln('  autoIncrement: ${field.autoIncrement},');
      if (field.columnType != null) {
        buffer.writeln("  columnType: '${escape(field.columnType!)}',");
      }
      if (field.defaultValueSql != null) {
        buffer.writeln(
          "  defaultValueSql: '${escape(field.defaultValueSql!)}',",
        );
      }
      if (field.codecType != null) {
        buffer.writeln("  codecType: '${field.codecType}',");
      }
      if (field.enumType != null) {
        buffer.writeln('  enumValues: ${field.enumType}.values,');
      }
      if (field.driverOverrides.isNotEmpty) {
        buffer.writeln('  driverOverrides: {');
        field.driverOverrides.forEach((driver, override) {
          buffer.writeln("    '${escape(driver)}': FieldDriverOverride(");
          if (override.columnType != null) {
            buffer.writeln(
              "      columnType: '${escape(override.columnType!)}',",
            );
          }
          if (override.defaultValueSql != null) {
            buffer.writeln(
              "      defaultValueSql: '${escape(override.defaultValueSql!)}',",
            );
          }
          if (override.codecType != null) {
            buffer.writeln("      codecType: '${override.codecType}',");
          }
          buffer.writeln('    ),');
        });
        buffer.writeln('  },');
      }
      buffer.writeln(');\n');
    }
  }

  String _castValue(String valueName, String dartType) {
    if (dartType == 'dynamic' || dartType == 'Object?' || dartType == 'Object') {
      return valueName;
    }
    return '$valueName as $dartType';
  }

  void _writeRelations(
    StringBuffer buffer,
    List<RelationDescriptor> relations,
  ) {
    for (final relation in relations) {
      buffer.writeln(
        'const RelationDefinition ${relation.identifier} = RelationDefinition(',
      );
      buffer.writeln("  name: '${escape(relation.name)}',");
      buffer.writeln('  kind: RelationKind.${relation.kind.name},');
      buffer.writeln("  targetModel: '${escape(relation.targetModel)}',");
      if (relation.foreignKey != null) {
        buffer.writeln("  foreignKey: '${escape(relation.foreignKey!)}',");
      }
      if (relation.localKey != null) {
        buffer.writeln("  localKey: '${escape(relation.localKey!)}',");
      }
      if (relation.through != null) {
        buffer.writeln("  through: '${escape(relation.through!)}',");
      }
      if (relation.throughModel != null) {
        buffer.writeln(
          "  throughModel: '${escape(relation.throughModel!)}',",
        );
      }
      if (relation.throughForeignKey != null) {
        buffer.writeln(
          "  throughForeignKey: '${escape(relation.throughForeignKey!)}',",
        );
      }
      if (relation.throughLocalKey != null) {
        buffer.writeln(
          "  throughLocalKey: '${escape(relation.throughLocalKey!)}',",
        );
      }
      if (relation.pivotForeignKey != null) {
        buffer.writeln(
          "  pivotForeignKey: '${escape(relation.pivotForeignKey!)}',",
        );
      }
      if (relation.pivotRelatedKey != null) {
        buffer.writeln(
          "  pivotRelatedKey: '${escape(relation.pivotRelatedKey!)}',",
        );
      }
      if (relation.morphType != null) {
        buffer.writeln("  morphType: '${escape(relation.morphType!)}',");
      }
      if (relation.morphClass != null) {
        buffer.writeln("  morphClass: '${escape(relation.morphClass!)}',");
      }
      buffer.writeln(');\n');
    }
  }
}
