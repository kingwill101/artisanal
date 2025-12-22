import '../descriptors.dart';
import '../model_context.dart';

/// Emits PartialEntity for a given model.
/// Partials are fully nullable projections; `toEntity` validation is left for future
/// enhancement once required-field metadata is wired in.
class ModelPartialEmitter {
  ModelPartialEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final className = context.className;
    final trackedName = context.trackedModelClassName;

    _writePartial(buffer, className, trackedName, context.fields);
    buffer.writeln();

    return buffer.toString();
  }

  void _writePartial(
    StringBuffer buffer,
    String className,
    String trackedName,
    List<FieldDescriptor> fields,
  ) {
    final visible = fields.where((f) => !f.isVirtual);

    buffer.writeln('/// Partial projection for [$className].');
    buffer.writeln('///');
    buffer.writeln('/// All fields are nullable; intended for subset SELECTs.');
    buffer.writeln(
      'class ${className}Partial implements PartialEntity<$trackedName> {',
    );

    if (visible.isEmpty) {
      buffer.writeln('  const ${className}Partial();');
    } else {
      buffer.write('  const ${className}Partial({');
      for (final field in visible) {
        buffer.write('this.${field.name}, ');
      }
      buffer.writeln('});');
    }

    // Add fromRow factory for hydrating from database rows
    _writeFromRowFactory(buffer, className, visible.toList());

    for (final field in visible) {
      buffer.writeln('  final ${field.dartType}? ${field.name};');
    }
    buffer.writeln();

    buffer.writeln('  @override');
    buffer.writeln('  $trackedName toEntity() {');
    buffer.writeln(
      "    // Basic required-field check: non-nullable fields must be present.",
    );
    for (final field in visible.where((f) => !f.isNullable)) {
      buffer.writeln(
        '    final ${field.dartType}? ${field.name}Value = ${field.name};',
      );
      buffer.writeAll([
        "    if (${field.name}Value == null) {",
        "        throw StateError('Missing required field: ${field.name}');",
        "    }",
      ]);
    }
    buffer.writeln('    return $trackedName(');
    for (final field in visible) {
      if (!field.isNullable) {
        buffer.writeln('      ${field.name}: ${field.name}Value,');
      } else {
        buffer.writeln('      ${field.name}: ${field.name},');
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    // Generate toMap() method
    _writeToMapMethod(buffer, visible.toList());

    // Generate copyWith()
    if (visible.isEmpty) {
      buffer.writeln();
      buffer.writeln('  ${className}Partial copyWith() => this;');
    } else {
      buffer.writeln();
      buffer.writeln(
          '  static const _${className}PartialCopyWithSentinel _copyWithSentinel = _${className}PartialCopyWithSentinel();');
      buffer.write('  ${className}Partial copyWith({');
      for (final field in visible) {
        buffer.write('Object? ${field.name} = _copyWithSentinel, ');
      }
      buffer.writeln('}) {');
      buffer.writeln('    return ${className}Partial(');
      for (final field in visible) {
        buffer.writeln(
            '      ${field.name}: identical(${field.name}, _copyWithSentinel) ? this.${field.name} : ${field.name} as ${field.dartType}?,');
      }
      buffer.writeln('    );');
      buffer.writeln('  }');
    }

    buffer.writeln('}');

    if (visible.isNotEmpty) {
      buffer.writeln(
          'class _${className}PartialCopyWithSentinel { const _${className}PartialCopyWithSentinel(); }');
    }
  }

  void _writeToMapMethod(StringBuffer buffer, List<FieldDescriptor> fields) {
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, Object?> toMap() {');
    buffer.writeln('    return {');
    for (final field in fields) {
      buffer.writeln(
        "      if (${field.name} != null) '${field.columnName}': ${field.name},",
      );
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
  }

  void _writeFromRowFactory(
    StringBuffer buffer,
    String className,
    List<FieldDescriptor> fields,
  ) {
    buffer.writeln();
    buffer.writeln('  /// Creates a partial from a database row map.');
    buffer.writeln('  ///');
    buffer.writeln('  /// The [row] keys should be column names (snake_case).');
    buffer.writeln('  /// Missing columns will result in null field values.');
    buffer.writeln(
      '  factory ${className}Partial.fromRow(Map<String, Object?> row) {',
    );
    buffer.writeln('    return ${className}Partial(');
    for (final field in fields) {
      buffer.writeln(
        "      ${field.name}: row['${field.columnName}'] as ${field.dartType}?,",
      );
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
  }
}
