import 'package:ormed/src/builder/helpers.dart';

import '../model_context.dart';

class ModelPredicateFieldsEmitter {
  ModelPredicateFieldsEmitter(this.context);

  final ModelContext context;

  static const Set<String> _reservedPredicateMembers = {
    'definition',
    'build',
    'where',
    'orWhere',
    'whereBetween',
    'whereNotBetween',
    'whereIn',
    'whereNotIn',
    'whereNull',
    'whereNotNull',
    'whereLike',
    'whereILike',
    'whereNotLike',
    'whereNotILike',
    'whereColumn',
    'whereRaw',
    'whereBitwise',
    'orWhereBitwise',
    'hashCode',
    'runtimeType',
    'toString',
    'noSuchMethod',
  };

  static const Set<String> _dartReservedWords = {
    'abstract',
    'else',
    'import',
    'show',
    'as',
    'enum',
    'in',
    'static',
    'assert',
    'export',
    'interface',
    'super',
    'async',
    'extends',
    'is',
    'switch',
    'await',
    'extension',
    'late',
    'sync',
    'break',
    'external',
    'library',
    'this',
    'case',
    'factory',
    'mixin',
    'throw',
    'catch',
    'false',
    'new',
    'true',
    'class',
    'final',
    'null',
    'try',
    'const',
    'finally',
    'on',
    'typedef',
    'continue',
    'for',
    'operator',
    'var',
    'covariant',
    'Function',
    'part',
    'void',
    'default',
    'get',
    'required',
    'while',
    'deferred',
    'hide',
    'rethrow',
    'with',
    'do',
    'if',
    'return',
    'yield',
    'dynamic',
    'implements',
    'set',
  };

  String emit() {
    final buffer = StringBuffer();
    _emitPredicateFields(buffer);
    _emitRelationHelpers(buffer);
    return buffer.toString();
  }

  void _emitPredicateFields(StringBuffer buffer) {
    final className = context.className;
    final fields = context.fields
        .where((field) => !field.isVirtual)
        .where((field) => !_shouldSkipField(field.name))
        .toList(growable: false);

    if (fields.isEmpty) {
      return;
    }

    buffer.writeln(
      'extension ${className}PredicateFields on PredicateBuilder<$className> {',
    );
    for (final field in fields) {
      buffer.writeln(
        '  PredicateField<$className, ${field.resolvedType}> get ${field.name} =>',
      );
      buffer.writeln(
        "      PredicateField<$className, ${field.resolvedType}>(this, '${escape(field.name)}');",
      );
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  void _emitRelationHelpers(StringBuffer buffer) {
    if (context.relations.isEmpty) {
      return;
    }

    final className = context.className;
    buffer.writeln(
      'extension ${className}TypedRelations on Query<$className> {',
    );
    for (final relation in context.relations) {
      final suffix = pascalize(relation.name);
      final target = relation.targetModel;
      buffer.writeln(
        '  Query<$className> with$suffix([PredicateCallback<$target>? constraint]) =>',
      );
      buffer.writeln(
        "      withRelationTyped('${escape(relation.name)}', constraint);",
      );
      buffer.writeln(
        '  Query<$className> whereHas$suffix([PredicateCallback<$target>? constraint]) =>',
      );
      buffer.writeln(
        "      whereHasTyped('${escape(relation.name)}', constraint);",
      );
      buffer.writeln(
        '  Query<$className> orWhereHas$suffix([PredicateCallback<$target>? constraint]) =>',
      );
      buffer.writeln(
        "      orWhereHasTyped('${escape(relation.name)}', constraint);",
      );
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  bool _shouldSkipField(String name) =>
      _reservedPredicateMembers.contains(name) ||
      _dartReservedWords.contains(name);
}
