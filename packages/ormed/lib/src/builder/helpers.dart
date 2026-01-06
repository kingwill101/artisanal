import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:inflector_dart/inflector_dart.dart' as inflector;
import 'package:source_gen/source_gen.dart';

const _annotationsLibraryUri = 'package:ormed/src/annotations.dart';

ConstantReader? readAnnotation(Element element, String className) {
  for (final metadata in element.metadata.annotations) {
    final annotationElement = metadata.element;
    if (annotationElement is! ConstructorElement) {
      continue;
    }
    final enclosingElement = annotationElement.enclosingElement;
    final uri = enclosingElement.library.uri.toString();
    if (enclosingElement.name != className || uri != _annotationsLibraryUri) {
      continue;
    }
    final value = metadata.computeConstantValue();
    if (value == null) {
      continue;
    }
    return ConstantReader(value);
  }
  return null;
}

String pascalize(String value) {
  final cleaned = value.replaceAll(RegExp(r'^_+'), '');
  final segments = cleaned
      .split(RegExp(r'[_-]'))
      .where((segment) => segment.isNotEmpty)
      .map((segment) => segment[0].toUpperCase() + segment.substring(1))
      .join();
  return segments.isEmpty
      ? value.isEmpty
            ? ''
            : value[0].toUpperCase() + value.substring(1)
      : segments;
}

String escape(String input) =>
    input.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

String boolLiteral(bool value) => value ? 'true' : 'false';

String? maybeTypeName(DartType? type) =>
    type == null ? null : nonNullableTypeName(type);

String typeOrDynamic(DartType? type) =>
    type == null ? 'dynamic' : nonNullableTypeName(type);

String typeName(DartType type) => type.getDisplayString();

String nonNullableTypeName(DartType type) {
  final display = type.getDisplayString();
  return type.nullabilitySuffix == NullabilitySuffix.question
      ? display.substring(0, display.length - 1)
      : display;
}

bool isSoftDeletesMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'SoftDeletes' &&
      libraryUri == 'package:ormed/src/model/model_mixins/soft_deletes.dart';
}

bool isSoftDeletesTZMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'SoftDeletesTZ' &&
      libraryUri == 'package:ormed/src/model/model_mixins/timestamps.dart';
}

bool isTimestampsMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'Timestamps' &&
      libraryUri == 'package:ormed/src/model/model_mixins/timestamps.dart';
}

bool isTimestampsTZMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'TimestampsTZ' &&
      libraryUri == 'package:ormed/src/model/model_mixins/timestamps.dart';
}

bool isModelAttributesMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'ModelAttributes' &&
      libraryUri ==
          'package:ormed/src/model/model_mixins/model_attributes.dart';
}

bool isModelConnectionMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'ModelConnection' &&
      libraryUri ==
          'package:ormed/src/model/model_mixins/model_connection.dart';
}

bool isModelFactoryMixin(InterfaceType type) {
  final element = type.element;
  final libraryUri = element.library.identifier;
  return element.name == 'ModelFactoryCapable' &&
      libraryUri == 'package:ormed/src/model/model_mixins/model_factory.dart';
}

bool classOrSuperHasMixin(
  ClassElement element,
  bool Function(InterfaceType type) predicate,
) {
  if (element.mixins.any(predicate)) {
    return true;
  }
  for (final supertype in element.allSupertypes) {
    if (predicate(supertype)) {
      return true;
    }
    final superElement = supertype.element;
    if (superElement.mixins.any(predicate)) {
      return true;
    }
  }
  return false;
}

List<String> readStringList(ConstantReader? reader) {
  if (reader == null || reader.isNull) return const [];
  return reader.listValue
      .map((value) => value.toStringValue())
      .whereType<String>()
      .toList(growable: false);
}

Map<String, String> readStringMap(ConstantReader? reader) {
  if (reader == null || reader.isNull) return const {};
  final map = <String, String>{};
  reader.mapValue.forEach((key, value) {
    final mapKey = key?.toStringValue();
    final mapValue = value?.toStringValue();
    if (mapKey != null && mapValue != null) {
      map[mapKey] = mapValue;
    }
  });
  return Map.unmodifiable(map);
}

String stringListLiteral(List<String> values, {bool constLiteral = true}) {
  final prefix = constLiteral ? 'const ' : '';
  if (values.isEmpty) return '$prefix<String>[]';
  final entries = values.map((entry) => "'${escape(entry)}'");
  return '$prefix<String>[${entries.join(', ')}]';
}

String stringMapLiteral(Map<String, String> values) {
  if (values.isEmpty) return 'const <String, String>{}';
  final entries = values.entries.map(
    (entry) => "'${escape(entry.key)}': '${escape(entry.value)}'",
  );
  return 'const <String, String>{${entries.join(', ')}}';
}

String? normalizeConstructorOverride(ConstantReader annotation) {
  final value = annotation.peek('constructor')?.stringValue;
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String inferTableName(String className) {
  return inflector.tableize(className);
}

String inferColumnName(String fieldName) {
  return inflector.underscore(fieldName);
}

String pluralize(String value) {
  return inflector.pluralize(value);
}
