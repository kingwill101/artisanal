String modelHelperClass(String className) {
  // Don't double "Model" suffix if class name already ends with "Model"
  final trackedClassName = className.endsWith('Model')
      ? '\$$className'
      : '\$${className}Model';
  final codecName = '_${trackedClassName}Codec';
  final factoryName = className.endsWith('Model')
      ? '${className}Factory'
      : '${className}ModelFactory';

  final buffer = StringBuffer();
  buffer.writeln('class $factoryName {');
  buffer.writeln('  const $factoryName._();');
  buffer.writeln();
  buffer.writeln('  static ModelDefinition<$className> get definition =>');
  buffer.writeln('      ${className}OrmDefinition.definition;');
  buffer.writeln();
  buffer.writeln(
    '  static ModelCodec<$className> get codec => definition.codec;',
  );
  buffer.writeln();
  buffer.writeln('  static $className fromMap(');
  buffer.writeln('    Map<String, Object?> data, {');
  buffer.writeln('    ValueCodecRegistry? registry,');
  buffer.writeln('  }) =>');
  buffer.writeln('      definition.fromMap(data, registry: registry);');
  buffer.writeln();
  buffer.writeln('  static Map<String, Object?> toMap(');
  buffer.writeln('    $className model, {');
  buffer.writeln('    ValueCodecRegistry? registry,');
  buffer.writeln('  }) =>');
  buffer.writeln(
    '      definition.toMap(model.toTracked(), registry: registry);',
  );
  buffer.writeln();
  buffer.writeln('  static void registerWith(ModelRegistry registry) =>');
  buffer.writeln('      registry.register(definition);');
  buffer.writeln();
  buffer.writeln(
    '  static ModelFactoryConnection<$className> withConnection(QueryContext context) =>',
  );
  buffer.writeln(
    '      ModelFactoryConnection<$className>(definition: definition, context: context);',
  );
  buffer.writeln();
  buffer.writeln('  /// Starts building a query for [$className].');
  buffer.writeln('  ///');
  buffer.writeln('  /// {@macro ormed.query}');
  buffer.writeln('  static Query<$className> query([String? connection]) {');
  buffer.writeln(
    '    final connName = connection ?? definition.metadata.connection;',
  );
  buffer.writeln(
    '    final conn = ConnectionManager.instance.connection(connName ?? ConnectionManager.instance.defaultConnectionName ?? "default");',
  );
  buffer.writeln('    return conn.query<$className>();');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln('  static ModelFactoryBuilder<$className> factory({');
  buffer.writeln('    GeneratorProvider? generatorProvider,');
  buffer.writeln('  }) =>');
  buffer.writeln('      ModelFactoryRegistry.factoryFor<$className>(');
  buffer.writeln('        generatorProvider: generatorProvider,');
  buffer.writeln('      );');
  buffer.writeln();
  // Add static CRUD helpers
  buffer.writeln(
    '  static Future<List<$className>> all([String? connection]) =>',
  );
  buffer.writeln('      query(connection).get();');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> create(Map<String, dynamic> attributes, [String? connection]) async {',
  );
  buffer.writeln(
    '    final model = const $codecName().decode(attributes, ValueCodecRegistry.instance);',
  );
  buffer.writeln(
    '    final connName = connection ?? definition.metadata.connection;',
  );
  buffer.writeln(
    '    final conn = ConnectionManager.instance.connection(connName ?? ConnectionManager.instance.defaultConnectionName ?? "default");',
  );
  buffer.writeln('    final repo = conn.context.repository<$className>();');
  buffer.writeln('    final result = await repo.insertMany([model], );');
  buffer.writeln('    return result.first;');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln(
    '  static Future<List<$className>> createMany(List<Map<String, dynamic>> records, [String? connection]) async {',
  );
  buffer.writeln(
    '    final models = records.map((r) => const $codecName().decode(r, ValueCodecRegistry.instance)).toList();',
  );
  buffer.writeln(
    '    final connName = connection ?? definition.metadata.connection;',
  );
  buffer.writeln(
    '    final conn = ConnectionManager.instance.connection(connName ?? ConnectionManager.instance.defaultConnectionName ?? "default");',
  );
  buffer.writeln('    final repo = conn.context.repository<$className>();');
  buffer.writeln('    return await repo.insertMany(models, );');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln(
    '  static Future<void> insert(List<Map<String, dynamic>> records, [String? connection]) async {',
  );
  buffer.writeln(
    '    final models = records.map((r) => const $codecName().decode(r, ValueCodecRegistry.instance)).toList();',
  );
  buffer.writeln(
    '    final connName = connection ?? definition.metadata.connection;',
  );
  buffer.writeln(
    '    final conn = ConnectionManager.instance.connection(connName ?? ConnectionManager.instance.defaultConnectionName ?? "default");',
  );
  buffer.writeln('    final repo = conn.context.repository<$className>();');
  buffer.writeln('    await repo.insertMany(models, returning: false);');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className?> find(Object id, [String? connection]) =>',
  );
  buffer.writeln('      query(connection).find(id);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> findOrFail(Object id, [String? connection]) async {',
  );
  buffer.writeln('    final result = await find(id, connection);');
  buffer.writeln(
    '    if (result == null) throw StateError("Model not found with id: \$id");',
  );
  buffer.writeln('    return result;');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln(
    '  static Future<List<$className>> findMany(List<Object> ids, [String? connection]) =>',
  );
  buffer.writeln('      query(connection).findMany(ids);');
  buffer.writeln();
  buffer.writeln('  static Future<$className?> first([String? connection]) =>');
  buffer.writeln('      query(connection).first();');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> firstOrFail([String? connection]) async {',
  );
  buffer.writeln('    final result = await first(connection);');
  buffer.writeln('    if (result == null) throw StateError("No model found");');
  buffer.writeln('    return result;');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln('  static Future<int> count([String? connection]) =>');
  buffer.writeln('      query(connection).count();');
  buffer.writeln();
  buffer.writeln('  static Future<bool> exists([String? connection]) async =>');
  buffer.writeln('      await count(connection) > 0;');
  buffer.writeln();
  buffer.writeln(
    '  static Future<int> destroy(List<Object> ids, [String? connection]) async {',
  );
  buffer.writeln('    final models = await findMany(ids, connection);');
  buffer.writeln('    for (final model in models) {');
  buffer.writeln('      await model.delete();');
  buffer.writeln('    }');
  buffer.writeln('    return models.length;');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> where(String column, dynamic value, [String? connection]) =>',
  );
  buffer.writeln('      query(connection).where(column, value);');
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> whereIn(String column, List<dynamic> values, [String? connection]) =>',
  );
  buffer.writeln('      query(connection).whereIn(column, values);');
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> orderBy(String column, {String direction = "asc", String? connection}) =>',
  );
  buffer.writeln(
    '      query(connection).orderBy(column, descending: direction.toLowerCase() == "desc");',
  );
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> limit(int count, [String? connection]) =>',
  );
  buffer.writeln('      query(connection).limit(count);');
  buffer.writeln('}');
  buffer.writeln();
  return buffer.toString();
}
