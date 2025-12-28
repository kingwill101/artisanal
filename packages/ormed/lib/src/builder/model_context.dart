import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:ormed/src/annotations.dart';
import 'package:ormed/src/model/model.dart';
import 'package:source_gen/source_gen.dart';

import 'descriptors.dart';
import 'helpers.dart';

final _modelChecker = TypeChecker.fromUrl(
  'package:ormed/src/model/model.dart#Model',
);
final _hasFactoryChecker = TypeChecker.fromUrl(
  'package:ormed/src/annotations.dart#HasFactory',
);
final _ormEventChecker = TypeChecker.fromUrl(
  'package:ormed/src/annotations.dart#OrmEvent',
);
final _eventChecker = TypeChecker.fromUrl(
  'package:ormed/src/events/event_bus.dart#Event',
);
final _modelEventChecker = TypeChecker.fromUrl(
  'package:ormed/src/model/model_events.dart#ModelEvent',
);

/// Checks if the class has the @HasFactory() annotation.
bool _hasFactoryAnnotation(ClassElement element) {
  return _hasFactoryChecker.hasAnnotationOf(element);
}

class ModelContext {
  ModelContext(this.element, this.annotation)
    : className = element.displayName,
      tableName =
          annotation.peek('table')?.stringValue ??
          inferTableName(element.displayName),
      schema = annotation.peek('schema')?.stringValue,
      generateCodec = annotation.peek('generateCodec')?.boolValue ?? true,
      annotationTimestampsFlag =
          annotation.peek('timestamps')?.boolValue ?? true,
      mixinSoftDeletes = element.mixins.any(isSoftDeletesMixin),
      mixinSoftDeletesTZ = element.mixins.any(isSoftDeletesTZMixin),
      mixinTimestamps = element.mixins.any(isTimestampsMixin),
      mixinTimestampsTZ = element.mixins.any(isTimestampsTZMixin),
      mixinModelAttributes = classOrSuperHasMixin(
        element,
        isModelAttributesMixin,
      ),
      mixinModelConnection = classOrSuperHasMixin(
        element,
        isModelConnectionMixin,
      ),
      mixinModelFactory = classOrSuperHasMixin(element, isModelFactoryMixin),
      annotationHasFactory = _hasFactoryAnnotation(element),
      extendsModel = _modelChecker.isAssignableFromType(element.thisType),
      annotationSoftDeletesFlag =
          annotation.peek('softDeletes')?.boolValue ?? false,
      annotationSoftDeleteColumnOverride = annotation
          .peek('softDeletesColumn')
          ?.stringValue,
      hiddenAnnotation = readStringList(annotation.peek('hidden')),
      visibleAnnotation = readStringList(annotation.peek('visible')),
      fillableAnnotation = readStringList(annotation.peek('fillable')),
      guardedAnnotation = readStringList(annotation.peek('guarded')),
      castsAnnotation = readStringMap(annotation.peek('casts')),
      appendsAnnotation = readStringList(annotation.peek('appends')),
      touchesAnnotation = readStringList(annotation.peek('touches')),
      driverAnnotations = readStringList(annotation.peek('driverAnnotations')),
      annotationPrimaryKeys = readStringList(annotation.peek('primaryKey')),
      connectionAnnotation = annotation.peek('connection')?.stringValue,
      constructorOverride = normalizeConstructorOverride(annotation) {
    fields = _collectFields();
    _applyAnnotationPrimaryKeys(fields);
    if (fields.isEmpty) {
      throw InvalidGenerationSourceError(
        'No fields detected for $className. Add final fields to generate metadata.',
        element: element,
      );
    }

    relations = _collectRelations();
    accessors = _collectAccessors();
    mutators = _collectMutators();
    ignoredFieldNames = _collectIgnoredFields();
    relationFieldNames = relations.map((relation) => relation.name).toSet();
    scopes = _collectScopes();

    final softDeleteFields = fields
        .where((field) => field.isSoftDelete)
        .toList();
    if (softDeleteFields.length > 1) {
      throw InvalidGenerationSourceError(
        'Only one field can be annotated with @OrmSoftDelete for $className.',
        element: element,
      );
    }

    final effectiveSoftDeletes = annotationSoftDeletesFlag || mixinSoftDeletes;
    var softDeleteColumn = softDeleteFields.isEmpty
        ? null
        : (softDeleteFields.single.softDeleteColumnName ??
              softDeleteFields.single.columnName);
    softDeleteColumn ??= annotationSoftDeleteColumnOverride;
    if (softDeleteColumn == null && effectiveSoftDeletes) {
      softDeleteColumn = SoftDeletes.defaultColumn;
    }

    this.softDeleteColumn = softDeleteColumn;
    this.effectiveSoftDeletes = effectiveSoftDeletes;

    _markPrimaryKeyFallback(fields);
    constructor = _resolveConstructor();
    eventHandlers = _collectEventHandlers();
  }

  final ConstantReader annotation;
  final ClassElement element;
  final String className;
  final String? tableName;
  final String? schema;
  final bool generateCodec;
  final bool annotationTimestampsFlag;
  final bool mixinSoftDeletes;
  final bool mixinSoftDeletesTZ;
  final bool mixinTimestamps;
  final bool mixinTimestampsTZ;
  final bool mixinModelAttributes;
  final bool mixinModelConnection;
  final bool mixinModelFactory;
  final bool annotationHasFactory;
  final bool extendsModel;
  final bool annotationSoftDeletesFlag;
  final String? annotationSoftDeleteColumnOverride;
  final List<String> hiddenAnnotation;
  final List<String> visibleAnnotation;
  final List<String> fillableAnnotation;
  final List<String> guardedAnnotation;
  final List<String> driverAnnotations;
  final List<String> annotationPrimaryKeys;
  final Map<String, String> castsAnnotation;
  final List<String> appendsAnnotation;
  final List<String> touchesAnnotation;
  final String? connectionAnnotation;
  final String? constructorOverride;

  late final List<FieldDescriptor> fields;
  late final List<RelationDescriptor> relations;
  late final List<AccessorDescriptor> accessors;
  late final List<MutatorDescriptor> mutators;
  late final List<ScopeDescriptor> scopes;
  late final List<EventHandlerDescriptor> eventHandlers;
  late final String? softDeleteColumn;
  late final bool effectiveSoftDeletes;
  late final ConstructorElement constructor;
  late final Set<String> ignoredFieldNames;
  late final Set<String> relationFieldNames;

  /// Whether this model has factory support enabled via mixin or annotation.
  bool get hasFactory => mixinModelFactory || annotationHasFactory;

  /// Whether this model declares any @OrmEvent handlers.
  bool get hasEventHandlers => eventHandlers.isNotEmpty;

  /// Returns the generated tracked model class name.
  /// Always just adds $ prefix to the class name.
  String get trackedModelClassName => '\$$className';

  ConstructorElement _resolveConstructor() {
    final constructorName = constructorOverride;

    if (constructorName != null && constructorName.isNotEmpty) {
      // Look for named constructor
      final namedConstructor = element.constructors.firstWhereOrNull(
        (c) => c.name == constructorName,
      );
      if (namedConstructor == null) {
        throw InvalidGenerationSourceError(
          'Constructor "$constructorName" not found on ${element.name}',
          element: element,
        );
      }
      return namedConstructor;
    }

    // Default behavior: use first generative (non-factory) constructor
    final ctor = element.constructors.firstWhereOrNull(
      (constructor) => !constructor.isFactory,
    );
    if (ctor == null) {
      throw InvalidGenerationSourceError(
        'A generative constructor is required for $className.',
        element: element,
      );
    }
    return ctor;
  }

  bool shouldSkipConstructorParameter(FormalParameterElement parameter) {
    final name = parameter.displayName;
    final isIgnored =
        ignoredFieldNames.contains(name) || relationFieldNames.contains(name);
    if (!isIgnored) {
      return false;
    }
    if (parameter.isRequiredNamed || parameter.isRequiredPositional) {
      throw InvalidGenerationSourceError(
        'Constructor parameter $name is required but is not backed by a field. '
        'Make it optional with a default value or map it to an @OrmField.',
        element: parameter,
      );
    }
    return true;
  }

  List<FieldDescriptor> _collectFields() {
    final descriptors = <FieldDescriptor>[];
    final seen = <String>{};

    void collectFrom(InterfaceElement source) {
      for (final field in source.fields) {
        if (field.isStatic || field.isSynthetic || field.isPrivate) {
          continue;
        }
        if (!field.isFinal) {
          throw InvalidGenerationSourceError(
            'Fields must be final for $className.',
            element: field,
          );
        }
        if (!seen.add(field.displayName)) {
          continue;
        }
        final descriptor = _buildFieldDescriptor(field);
        if (descriptor != null) {
          descriptors.add(descriptor);
        }
      }
      if (source is ClassElement) {
        for (final mixinType in source.mixins) {
          collectFrom(mixinType.element);
        }
        final supertype = source.supertype;
        if (supertype != null && supertype.element.name != 'Object') {
          collectFrom(supertype.element);
        }
      }
    }

    collectFrom(element);

    final requiresSoftDeletes =
        mixinSoftDeletes || mixinSoftDeletesTZ || annotationSoftDeletesFlag;
    if (requiresSoftDeletes &&
        !descriptors.any((descriptor) => descriptor.isSoftDelete)) {
      descriptors.add(
        FieldDescriptor(
          owner: className,
          name: 'deletedAt',
          columnName:
              annotationSoftDeleteColumnOverride ?? SoftDeletes.defaultColumn,
          dartType: 'DateTime',
          resolvedType: 'DateTime?',
          isPrimaryKey: false,
          isNullable: true,
          isUnique: false,
          isIndexed: false,
          autoIncrement: false,
          columnType: null,
          defaultValueSql: null,
          codecType: null,
          isSoftDelete: true,
          isVirtual: true,
          softDeleteColumnName:
              annotationSoftDeleteColumnOverride ?? SoftDeletes.defaultColumn,
        ),
      );
    }

    // Add virtual timestamp fields if using Timestamps or TimestampsTZ mixins
    final requiresTimestamps = mixinTimestamps || mixinTimestampsTZ;
    if (requiresTimestamps) {
      // Add createdAt field if not already present
      if (!descriptors.any((d) => d.name == 'createdAt')) {
        descriptors.add(
          FieldDescriptor(
            owner: className,
            name: 'createdAt',
            columnName: 'created_at',
            dartType: 'DateTime',
            resolvedType: 'DateTime?',
            isPrimaryKey: false,
            isNullable: true,
            isUnique: false,
            isIndexed: false,
            autoIncrement: false,
            columnType: null,
            defaultValueSql: null,
            codecType: null,
            isSoftDelete: false,
            isVirtual: true,
          ),
        );
      }

      // Add updatedAt field if not already present
      if (!descriptors.any((d) => d.name == 'updatedAt')) {
        descriptors.add(
          FieldDescriptor(
            owner: className,
            name: 'updatedAt',
            columnName: 'updated_at',
            dartType: 'DateTime',
            resolvedType: 'DateTime?',
            isPrimaryKey: false,
            isNullable: true,
            isUnique: false,
            isIndexed: false,
            autoIncrement: false,
            columnType: null,
            defaultValueSql: null,
            codecType: null,
            isSoftDelete: false,
            isVirtual: true,
          ),
        );
      }
    }

    return descriptors;
  }

  Set<String> _collectIgnoredFields() {
    final ignored = <String>{};
    final seen = <String>{};

    void collectFrom(InterfaceElement source) {
      for (final field in source.fields) {
        if (field.isStatic || field.isSynthetic || field.isPrivate) {
          continue;
        }
        if (!seen.add(field.displayName)) {
          continue;
        }
        final reader = readAnnotation(field, 'OrmField');
        if (reader?.peek('ignore')?.boolValue ?? false) {
          ignored.add(field.displayName);
        }
      }
      if (source is ClassElement) {
        for (final mixinType in source.mixins) {
          collectFrom(mixinType.element);
        }
        final supertype = source.supertype;
        if (supertype != null && supertype.element.name != 'Object') {
          collectFrom(supertype.element);
        }
      }
    }

    collectFrom(element);
    return ignored;
  }

  FieldDescriptor? _buildFieldDescriptor(FieldElement field) {
    final reader = readAnnotation(field, 'OrmField');
    if (reader?.peek('ignore')?.boolValue ?? false) {
      return null;
    }
    final typeWithNullability = field.type.getDisplayString();
    final type = field.type.nullabilitySuffix == NullabilitySuffix.question
        ? typeWithNullability.substring(0, typeWithNullability.length - 1)
        : typeWithNullability;
    final resolvedType = typeWithNullability;
    final enumType = field.type.element is EnumElement ? type : null;
    final fieldName = field.displayName;
    final nullableOverride = reader?.peek('isNullable');
    // codecType comes from 'codec' (Type parameter)
    // If not set, use 'cast' (String) as the codec key
    final codecType = reader?.peek('codec')?.typeValue;
    final softDeleteReader = readAnnotation(field, 'OrmSoftDelete');
    final softDeleteColumnOverride = softDeleteReader
        ?.peek('columnName')
        ?.stringValue;
    var columnName =
        reader?.peek('columnName')?.stringValue ?? inferColumnName(fieldName);
    var effectiveNullable = nullableOverride == null || nullableOverride.isNull
        ? field.type.nullabilitySuffix == NullabilitySuffix.question
        : nullableOverride.boolValue;

    final softDeleteViaMixin =
        mixinSoftDeletes &&
        softDeleteReader == null &&
        fieldName == 'deletedAt';
    if (softDeleteViaMixin) {
      columnName =
          annotationSoftDeleteColumnOverride ?? SoftDeletes.defaultColumn;
      effectiveNullable = true;
    }

    final driverOverrides = _readDriverOverrides(
      reader?.peek('driverOverrides'),
      field,
    );
    final attributeMetadata = _fieldAttributeMetadata(reader);

    // Use 'cast' string as codecType if 'codec' Type is not specified
    // Priority: 1) codec Type parameter, 2) cast field parameter, 3) model-level casts map
    final castString = reader?.peek('cast')?.stringValue;
    final modelLevelCast = castsAnnotation[fieldName];
    final effectiveCodecType = codecType != null
        ? maybeTypeName(codecType)
        : (castString ?? modelLevelCast);
    final normalizedCast = effectiveCodecType
        ?.trim()
        .toLowerCase()
        .split(':')
        .first;
    if (normalizedCast == 'enum' && enumType == null) {
      throw InvalidGenerationSourceError(
        '@OrmField(cast: \'enum\') requires an enum-typed field on $className.',
        element: field,
      );
    }

    // Check if this is an auto-increment field
    final isAutoIncrement = reader?.peek('autoIncrement')?.boolValue ?? false;

    return FieldDescriptor(
      owner: className,
      name: fieldName,
      columnName: columnName,
      dartType: type,
      resolvedType: resolvedType,
      isPrimaryKey: reader?.peek('isPrimaryKey')?.boolValue ?? false,
      isNullable: effectiveNullable,
      isUnique: reader?.peek('isUnique')?.boolValue ?? false,
      isIndexed: reader?.peek('isIndexed')?.boolValue ?? false,
      autoIncrement: isAutoIncrement,
      columnType: reader?.peek('columnType')?.stringValue,
      defaultValueSql: reader?.peek('defaultValueSql')?.stringValue,
      codecType: effectiveCodecType,
      isSoftDelete: softDeleteReader != null || softDeleteViaMixin,
      softDeleteColumnName:
          softDeleteColumnOverride ??
          (softDeleteViaMixin
              ? columnName
              : reader?.peek('columnName')?.stringValue),
      enumType: enumType,
      driverOverrides: driverOverrides,
      attributeMetadata: attributeMetadata,
    );
  }

  FieldAttributeMetadata? _fieldAttributeMetadata(ConstantReader? reader) {
    if (reader == null) return null;
    final fillable = reader.peek('fillable');
    final guarded = reader.peek('guarded');
    final hidden = reader.peek('hidden');
    final visible = reader.peek('visible');
    final cast = reader.peek('cast');
    if ((fillable == null || fillable.isNull) &&
        (guarded == null || guarded.isNull) &&
        (hidden == null || hidden.isNull) &&
        (visible == null || visible.isNull) &&
        (cast == null || cast.isNull)) {
      return null;
    }
    return FieldAttributeMetadata(
      fillable: fillable?.boolValue,
      guarded: guarded?.boolValue,
      hidden: hidden?.boolValue,
      visible: visible?.boolValue,
      cast: cast?.stringValue,
    );
  }

  List<RelationDescriptor> _collectRelations() {
    final relations = <RelationDescriptor>[];
    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic || field.isPrivate) {
        continue;
      }
      final annotation = readAnnotation(field, 'OrmRelation');
      if (annotation == null) {
        continue;
      }

      final targetType = annotation.peek('target')?.typeValue;
      final throughType = annotation.peek('throughModel')?.typeValue;
      final pivotType = annotation.peek('pivotModel')?.typeValue;
      final targetModel = targetType != null && targetType is! DynamicType
          ? nonNullableTypeName(targetType)
          : _inferTargetModel(field.type);
      final throughModel = throughType != null && throughType is! DynamicType
          ? nonNullableTypeName(throughType)
          : null;
      final pivotModel = pivotType != null && pivotType is! DynamicType
          ? nonNullableTypeName(pivotType)
          : null;

      relations.add(
        RelationDescriptor(
          owner: className,
          name: field.displayName,
          fieldType: field.type,
          kind: _readRelationKind(annotation.peek('kind')?.objectValue),
          targetModel: targetModel,
          foreignKey: annotation.peek('foreignKey')?.stringValue,
          localKey: annotation.peek('localKey')?.stringValue,
          through: annotation.peek('through')?.stringValue,
          throughModel: throughModel,
          throughForeignKey: annotation.peek('throughForeignKey')?.stringValue,
          throughLocalKey: annotation.peek('throughLocalKey')?.stringValue,
          pivotForeignKey: annotation.peek('pivotForeignKey')?.stringValue,
          pivotRelatedKey: annotation.peek('pivotRelatedKey')?.stringValue,
          pivotColumns: readStringList(annotation.peek('withPivot')),
          pivotTimestamps:
              annotation.peek('withTimestamps')?.boolValue ?? false,
          pivotModel: pivotModel,
          morphType: annotation.peek('morphType')?.stringValue,
          morphClass: annotation.peek('morphClass')?.stringValue,
        ),
      );
    }
    return relations;
  }

  List<AccessorDescriptor> _collectAccessors() {
    final accessors = <AccessorDescriptor>[];
    final seen = <String>{};

    void addAccessor(ExecutableElement element) {
      if (!element.isStatic) {
        throw InvalidGenerationSourceError(
          '@OrmAccessor must be static on $className.',
          element: element,
        );
      }

      final reader = readAnnotation(element, 'OrmAccessor');
      if (reader == null) {
        return;
      }

      final attribute = _resolveAttributeName(
        override: reader.peek('attribute')?.stringValue,
        baseName: element.displayName,
      );
      if (!seen.add(attribute)) {
        throw InvalidGenerationSourceError(
          'Duplicate accessor registered for attribute "$attribute" on $className.',
          element: element,
        );
      }

      final params = element.formalParameters;
      final takesValue = params.isNotEmpty;
      final takesModel = params.length == 2;
      if (params.length > 2 || params.any((p) => p.isNamed)) {
        throw InvalidGenerationSourceError(
          '@OrmAccessor methods must take 0, 1, or 2 positional parameters.',
          element: element,
        );
      }

      final isGetter = element is GetterElement;
      if (isGetter && params.isNotEmpty) {
        throw InvalidGenerationSourceError(
          '@OrmAccessor getters cannot declare parameters.',
          element: element,
        );
      }
      if (!isGetter && takesModel && params.length != 2) {
        throw InvalidGenerationSourceError(
          '@OrmAccessor methods with a model parameter must take exactly 2 positional parameters.',
          element: element,
        );
      }

      accessors.add(
        AccessorDescriptor(
          owner: className,
          name: element.displayName,
          attribute: attribute,
          returnType: nonNullableTypeName(element.returnType),
          takesValue: takesValue,
          takesModel: takesModel,
          isGetter: isGetter,
          valueType: takesValue ? typeName(params.last.type) : null,
        ),
      );
    }

    for (final accessor in element.getters) {
      if (accessor.isSynthetic || accessor.isPrivate) {
        continue;
      }
      if (readAnnotation(accessor, 'OrmAccessor') != null) {
        addAccessor(accessor);
      }
    }

    for (final method in element.methods) {
      if (method.isSynthetic || method.isPrivate) {
        continue;
      }
      if (readAnnotation(method, 'OrmAccessor') != null) {
        addAccessor(method);
      }
    }

    for (final accessor in element.setters) {
      if (accessor.isSynthetic || accessor.isPrivate) {
        continue;
      }
      if (readAnnotation(accessor, 'OrmAccessor') != null) {
        throw InvalidGenerationSourceError(
          '@OrmAccessor must be a static getter or method on $className.',
          element: accessor,
        );
      }
    }

    return accessors;
  }

  List<MutatorDescriptor> _collectMutators() {
    final mutators = <MutatorDescriptor>[];
    final seen = <String>{};

    void addMutator(ExecutableElement element) {
      if (!element.isStatic) {
        throw InvalidGenerationSourceError(
          '@OrmMutator must be static on $className.',
          element: element,
        );
      }

      final reader = readAnnotation(element, 'OrmMutator');
      if (reader == null) {
        return;
      }

      final attribute = _resolveAttributeName(
        override: reader.peek('attribute')?.stringValue,
        baseName: element.displayName,
      );
      if (!seen.add(attribute)) {
        throw InvalidGenerationSourceError(
          'Duplicate mutator registered for attribute "$attribute" on $className.',
          element: element,
        );
      }

      final params = element.formalParameters;
      if (params.isEmpty || params.length > 2 || params.any((p) => p.isNamed)) {
        throw InvalidGenerationSourceError(
          '@OrmMutator methods must take 1 or 2 positional parameters.',
          element: element,
        );
      }

      final takesModel = params.length == 2;
      final valueParam = params.length == 2 ? params[1] : params[0];
      mutators.add(
        MutatorDescriptor(
          owner: className,
          name: element.displayName,
          attribute: attribute,
          valueType: typeName(valueParam.type),
          returnType: nonNullableTypeName(element.returnType),
          takesModel: takesModel,
        ),
      );
    }

    for (final accessor in element.setters) {
      if (accessor.isSynthetic || accessor.isPrivate) {
        continue;
      }
      if (readAnnotation(accessor, 'OrmMutator') != null) {
        throw InvalidGenerationSourceError(
          '@OrmMutator must be a static method on $className.',
          element: accessor,
        );
      }
    }

    for (final method in element.methods) {
      if (method.isSynthetic || method.isPrivate) {
        continue;
      }
      if (readAnnotation(method, 'OrmMutator') != null) {
        addMutator(method);
      }
    }

    return mutators;
  }

  String _resolveAttributeName({String? override, required String baseName}) {
    final trimmed = override?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return inferColumnName(baseName);
  }

  String _inferTargetModel(DartType type) {
    if (type is InterfaceType) {
      // If it's a List<T>, infer T
      if (type.isDartCoreList && type.typeArguments.isNotEmpty) {
        return nonNullableTypeName(type.typeArguments.first);
      }
      // Otherwise use the type itself
      return nonNullableTypeName(type);
    }
    return 'dynamic';
  }

  List<ScopeDescriptor> _collectScopes() {
    final scopes = <ScopeDescriptor>[];
    for (final method in element.methods) {
      final annotation = readAnnotation(method, 'OrmScope');
      if (annotation == null) continue;

      if (!method.isStatic) {
        throw InvalidGenerationSourceError(
          '@OrmScope methods must be static: ${method.displayName}',
          element: method,
        );
      }

      final parameters = method.formalParameters;

      // Validate first parameter: required positional Query<model>
      if (parameters.isEmpty) {
        throw InvalidGenerationSourceError(
          '@OrmScope requires a Query parameter: ${method.displayName}',
          element: method,
        );
      }
      final first = parameters.first;
      final firstType = first.type;
      final isQueryType =
          firstType is InterfaceType && firstType.element.name == 'Query';
      if (!first.isRequiredPositional || !isQueryType) {
        throw InvalidGenerationSourceError(
          '@OrmScope methods must accept Query<T> as the first positional parameter.',
          element: method,
        );
      }

      final identifier =
          annotation.peek('identifier')?.stringValue ?? method.displayName;
      final isGlobal = annotation.peek('global')?.boolValue ?? false;

      if (isGlobal) {
        // Global scopes cannot accept additional required parameters beyond
        // the Query<T> argument because they are applied automatically.
        final extraRequired = parameters
            .skip(1)
            .where((p) => p.isRequiredPositional || p.isRequiredNamed);
        if (extraRequired.isNotEmpty) {
          throw InvalidGenerationSourceError(
            '@OrmScope(global: true) cannot declare required parameters beyond the Query<T> argument.',
            element: method,
          );
        }
      }

      scopes.add(
        ScopeDescriptor(
          name: method.displayName,
          identifier: identifier,
          parameters: parameters,
          isGlobal: isGlobal,
        ),
      );
    }
    return scopes;
  }

  List<EventHandlerDescriptor> _collectEventHandlers() {
    final handlers = <EventHandlerDescriptor>[];
    for (final method in element.methods) {
      final annotation = _ormEventChecker.firstAnnotationOf(method);
      if (annotation == null) continue;
      final exec = method as ExecutableElement;

      if (!method.isStatic) {
        throw InvalidGenerationSourceError(
          '@OrmEvent handlers must be static: ${method.displayName}',
          element: method,
        );
      }

      final reader = ConstantReader(annotation);
      final eventTypeObj = reader.peek('eventType');
      final eventType = eventTypeObj?.typeValue;
      if (eventType == null || !_eventChecker.isAssignableFromType(eventType)) {
        throw InvalidGenerationSourceError(
          '@OrmEvent requires an event type that extends Event.',
          element: method,
        );
      }

      final positional = exec.formalParameters
          .where((p) => p.isRequiredPositional)
          .toList();
      if (positional.length != 1) {
        throw InvalidGenerationSourceError(
          '@OrmEvent handler must accept exactly one positional parameter.',
          element: method,
        );
      }
      final paramType = positional.single.type;
      final eventTypeChecker = TypeChecker.fromStatic(eventType);
      if (!eventTypeChecker.isAssignableFromType(paramType)) {
        throw InvalidGenerationSourceError(
          '@OrmEvent handler parameter type must match the declared event type.',
          element: method,
        );
      }

      handlers.add(
        EventHandlerDescriptor(
          owner: className,
          methodName: method.displayName,
          eventType: eventType,
          isStatic: method.isStatic,
          isModelEvent: _modelEventChecker.isAssignableFromType(eventType),
        ),
      );
    }
    return handlers;
  }

  RelationKind _readRelationKind(DartObject? object) {
    if (object == null) {
      return RelationKind.hasOne;
    }
    final index = object.getField('index')?.toIntValue();
    return RelationKind.values[index ?? 0];
  }

  void _applyAnnotationPrimaryKeys(List<FieldDescriptor> fields) {
    if (annotationPrimaryKeys.isEmpty) {
      return;
    }
    final normalized = annotationPrimaryKeys
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      return;
    }
    for (final field in fields) {
      if (normalized.contains(field.columnName) ||
          normalized.contains(field.name)) {
        field.isPrimaryKey = true;
      }
    }
  }

  void _markPrimaryKeyFallback(List<FieldDescriptor> fields) {
    if (fields.any((field) => field.isPrimaryKey && !field.isVirtual)) {
      return;
    }
    final fallback = fields.firstWhereOrNull(
      (field) => !field.isVirtual && field.name == 'id',
    );
    if (fallback == null) {
      // Auto-create a virtual 'id' primary key if none exists.
      // This follows the Active Record convention where every table has an 'id' PK.
      fields.add(
        FieldDescriptor(
          owner: className,
          name: 'id',
          columnName: 'id',
          dartType: 'int',
          resolvedType: 'int',
          isPrimaryKey: true,
          isNullable: false,
          isUnique: true,
          isIndexed: true,
          autoIncrement: true,
          columnType: 'INTEGER',
          defaultValueSql: null,
          codecType: null,
          isSoftDelete: false,
          isVirtual: true,
        ),
      );
      return;
    }
    fallback.isPrimaryKey = true;
  }

  Map<String, DriverFieldOverrideDescriptor> _readDriverOverrides(
    ConstantReader? reader,
    FieldElement field,
  ) {
    if (reader == null || reader.isNull) return const {};
    final overrides = <String, DriverFieldOverrideDescriptor>{};
    reader.mapValue.forEach((rawKey, rawValue) {
      final driver = rawKey?.toStringValue()?.trim();
      if (driver == null || driver.isEmpty) {
        throw InvalidGenerationSourceError(
          'driverOverrides keys must be non-empty strings.',
          element: field,
        );
      }
      final normalized = driver.toLowerCase();
      final overrideReader = ConstantReader(rawValue);
      overrides[normalized] = DriverFieldOverrideDescriptor(
        columnType: overrideReader.peek('columnType')?.stringValue,
        defaultValueSql: overrideReader.peek('defaultValueSql')?.stringValue,
        codecType: maybeTypeName(overrideReader.peek('codec')?.typeValue),
      );
    });
    return Map.unmodifiable(overrides);
  }
}
