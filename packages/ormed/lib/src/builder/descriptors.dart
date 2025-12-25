import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:ormed/src/annotations.dart';
import 'package:ormed/src/model/model_definition.dart';

import 'helpers.dart';

class FieldDescriptor {
  FieldDescriptor({
    required this.owner,
    required this.name,
    required this.columnName,
    required this.dartType,
    required this.resolvedType,
    required this.isPrimaryKey,
    required this.isNullable,
    required this.isUnique,
    required this.isIndexed,
    required this.autoIncrement,
    required this.columnType,
    required this.defaultValueSql,
    required this.codecType,
    required this.isSoftDelete,
    this.isVirtual = false,
    this.softDeleteColumnName,
    this.driverOverrides = const {},
    this.attributeMetadata,
  });

  final String owner;
  final String name;
  final String columnName;
  final String dartType;
  final String resolvedType;
  bool isPrimaryKey;
  final bool isNullable;
  final bool isUnique;
  final bool isIndexed;
  final bool autoIncrement;
  final String? columnType;
  final String? defaultValueSql;
  final String? codecType;
  final bool isSoftDelete;
  final bool isVirtual;
  final String? softDeleteColumnName;
  final Map<String, DriverFieldOverrideDescriptor> driverOverrides;
  final FieldAttributeMetadata? attributeMetadata;

  String get identifier => '_\$$owner${pascalize(name)}Field';

  String get localIdentifier {
    final prefix = owner.isEmpty
        ? ''
        : owner[0].toLowerCase() + owner.substring(1);
    return '$prefix${pascalize(name)}Value';
  }
}

class DriverFieldOverrideDescriptor {
  const DriverFieldOverrideDescriptor({
    this.columnType,
    this.defaultValueSql,
    this.codecType,
  });

  final String? columnType;
  final String? defaultValueSql;
  final String? codecType;
}

class RelationDescriptor {
  RelationDescriptor({
    required this.owner,
    required this.name,
    required this.fieldType,
    required this.kind,
    required this.targetModel,
    this.foreignKey,
    this.localKey,
    this.through,
    this.throughModel,
    this.throughForeignKey,
    this.throughLocalKey,
    this.pivotForeignKey,
    this.pivotRelatedKey,
    this.morphType,
    this.morphClass,
  });

  final String owner;
  final String name;
  final DartType fieldType;
  final RelationKind kind;
  final String targetModel;
  final String? foreignKey;
  final String? localKey;
  final String? through;
  final String? throughModel;
  final String? throughForeignKey;
  final String? throughLocalKey;
  final String? pivotForeignKey;
  final String? pivotRelatedKey;
  final String? morphType;
  final String? morphClass;

  String get identifier => '_\$$owner${pascalize(name)}Relation';

  /// Whether this is a list relation (hasMany, manyToMany, morphMany, morphToMany)
  bool get isList =>
      kind == RelationKind.hasMany ||
      kind == RelationKind.hasManyThrough ||
      kind == RelationKind.manyToMany ||
      kind == RelationKind.morphMany ||
      kind == RelationKind.morphToMany ||
      kind == RelationKind.morphedByMany;

  /// The resolved type string for the relation field
  String get resolvedType => nonNullableTypeName(fieldType);

  /// Whether the relation field is nullable
  bool get isNullable => fieldType.nullabilitySuffix != NullabilitySuffix.none;
}

class ScopeDescriptor {
  ScopeDescriptor({
    required this.name,
    required this.identifier,
    required this.parameters,
    required this.isGlobal,
  });

  final String name;
  final String identifier;
  final List<FormalParameterElement> parameters;
  final bool isGlobal;
}

class EventHandlerDescriptor {
  EventHandlerDescriptor({
    required this.owner,
    required this.methodName,
    required this.eventType,
    required this.isStatic,
    required this.isModelEvent,
  });

  final String owner;
  final String methodName;
  final DartType eventType;
  final bool isStatic;
  final bool isModelEvent;

  String get registrationFunction =>
      'register${owner}EventHandlers'; // convention
}
