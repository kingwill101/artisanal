import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../descriptors.dart';
import '../model_context.dart';

class ModelCodecEmitter {
  ModelCodecEmitter(this.context);

  final ModelContext context;

  String emit() {
    if (!context.generateCodec) {
      return _unsupportedCodec(context.className);
    }
    return _codecFor(context.constructor, context.fields);
  }

  String _codecFor(
    ConstructorElement constructor,
    List<FieldDescriptor> fields,
  ) {
    final generatedClassName = context.trackedModelClassName;
    final codecName = '_${generatedClassName}Codec';
    final buffer = StringBuffer();
    buffer.writeln(
      'class $codecName extends ModelCodec<$generatedClassName> {',
    );
    buffer.writeln('  const $codecName();');
    buffer.writeln('  @override');
    buffer.writeln(
      '  Map<String, Object?> encode($generatedClassName model, ValueCodecRegistry registry) {',
    );
    buffer.writeln('    return <String, Object?>{');
    for (final field in fields) {
      final accessor = field.isVirtual
          ? "model.getAttribute<${field.resolvedType}>('${field.columnName}')"
          : 'model.${field.name}';
      buffer.writeln(
        "      '${field.columnName}': registry.encodeField(${field.identifier}, $accessor),",
      );
    }
    buffer.writeln('    };');
    buffer.writeln('  }\n');

    buffer.writeln('  @override');
    buffer.writeln(
      '  $generatedClassName decode(Map<String, Object?> data, ValueCodecRegistry registry) {',
    );
    for (final field in fields) {
      buffer.writeln(
        '    final ${field.resolvedType} ${field.localIdentifier} = ${_decodeExpression(field)};',
      );
    }
    buffer.writeln(
      '    final model = ${_constructorInvocation(constructor, fields, subclass: true)};',
    );
    buffer.writeln('    model._attachOrmRuntimeMetadata({');
    for (final field in fields) {
      buffer.writeln("      '${field.columnName}': ${field.localIdentifier},");
    }
    buffer.writeln('    });');
    buffer.writeln('    return model;');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
    return buffer.toString();
  }

  String _constructorInvocation(
    ConstructorElement constructor,
    List<FieldDescriptor> fields, {
    bool subclass = false,
  }) {
    final buffer = StringBuffer();
    final targetClass = subclass
        ? context.trackedModelClassName
        : context.className;
    buffer.writeln('$targetClass(');

    // The generated subclass constructor always uses named parameters
    // to simplify handling of defaults and optional fields.
    if (subclass) {
      for (final parameter in constructor.formalParameters) {
        final paramName = parameter.displayName;
        final field = fields.firstWhereOrNull(
          (f) => !f.isVirtual && f.name == paramName,
        );
        if (field == null) {
          if (context.shouldSkipConstructorParameter(parameter)) {
            continue;
          }
          throw InvalidGenerationSourceError(
            'Constructor parameter $paramName is not backed by a field.',
            element: constructor,
          );
        }
        buffer.writeln('      $paramName: ${field.localIdentifier},');
      }
      buffer.writeln('    )');
      return buffer.toString();
    }

    for (final parameter in constructor.formalParameters) {
      final paramName = parameter.displayName;
      final field = fields.firstWhereOrNull(
        (f) => !f.isVirtual && f.name == paramName,
      );
      if (field == null) {
        if (context.shouldSkipConstructorParameter(parameter)) {
          continue;
        }
        throw InvalidGenerationSourceError(
          'Constructor parameter $paramName is not backed by a field.',
          element: constructor,
        );
      }
      buffer.writeln('      $paramName: ${field.localIdentifier},');
    }
    buffer.writeln('    )');
    return buffer.toString();
  }

  String _decodeExpression(FieldDescriptor field) {
    final access =
        "registry.decodeField<${field.resolvedType}>(${field.identifier}, data['${field.columnName}'])";
    if (field.isNullable) {
      return access;
    }
    // Auto-increment fields can be null during decode (e.g., when using createMany with partial data)
    // The database will generate the value on insert
    if (field.autoIncrement) {
      return "$access ?? 0"; // Default to 0 for auto-increment fields when null
    }
    // Fields with SQL defaults can be null during decode - use type-appropriate defaults
    if (field.defaultValueSql != null && field.defaultValueSql!.isNotEmpty) {
      return "$access ?? ${_dartDefaultForType(field.dartType)}";
    }
    return "$access ?? (throw StateError('Field ${field.name} on ${context.className} cannot be null.'))";
  }

  String _dartDefaultForType(String dartType) {
    switch (dartType) {
      case 'bool':
        return 'false';
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'String':
        return "''";
      default:
        return 'null'; // For complex types, default to null (shouldn't happen for non-nullable)
    }
  }

  String _unsupportedCodec(String className) =>
      'class _\$${className}UnsupportedCodec extends ModelCodec<$className> {\n'
      '  const _\$${className}UnsupportedCodec();\n'
      '  @override Map<String, Object?> encode($className model, ValueCodecRegistry registry) =>\n'
      "      throw UnsupportedError('Codec generation disabled for $className');\n"
      '  @override $className decode(Map<String, Object?> data, ValueCodecRegistry registry) =>\n'
      "      throw UnsupportedError('Codec generation disabled for $className');\n"
      '}\n';
}
