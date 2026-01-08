import '../model_context.dart';

class ModelFactoryEmitter {
  const ModelFactoryEmitter(this.context);

  final ModelContext context;

  String emit() {
    final className = context.className;
    final generatedClassName = context.trackedModelClassName;
    final buffer = StringBuffer();

    // Use base class name without doubling "Model" suffix for factory name
    final factoryName = className.endsWith('Model')
        ? '${className}Factory'
        : '${className}ModelFactory';
    buffer.writeln('class $factoryName {');
    buffer.writeln('  const $factoryName._();');
    buffer.writeln();

    // Static getters for definition and codec
    buffer.writeln(
      '  static ModelDefinition<$generatedClassName> get definition => _${generatedClassName}Definition;',
    );
    buffer.writeln();
    buffer.writeln(
      '  static ModelCodec<$generatedClassName> get codec => definition.codec;',
    );
    buffer.writeln();

    // fromMap and toMap static methods
    buffer.writeln('  static $className fromMap(');
    buffer.writeln('    Map<String, Object?> data, {');
    buffer.writeln('    ValueCodecRegistry? registry,');
    buffer.writeln('  }) => definition.fromMap(data, registry: registry);');
    buffer.writeln();
    buffer.writeln('  static Map<String, Object?> toMap(');
    buffer.writeln('    $className model, {');
    buffer.writeln('    ValueCodecRegistry? registry,');
    buffer.writeln(
      '  }) => definition.toMap(model.toTracked(), registry: registry);',
    );
    buffer.writeln();

    // registerWith method
    buffer.writeln('  static void registerWith(ModelRegistry registry) =>');
    buffer.writeln('      registry.register(definition);');
    buffer.writeln();

    // withConnection method
    buffer.writeln(
      '  static ModelFactoryConnection<$className> withConnection(QueryContext context) =>',
    );
    buffer.writeln(
      '      ModelFactoryConnection<$className>(definition: definition, context: context);',
    );
    buffer.writeln();

    // factory method
    buffer.writeln('  static ModelFactoryBuilder<$className> factory({');
    buffer.writeln('    GeneratorProvider? generatorProvider,');
    buffer.writeln('  }) => ModelFactoryRegistry.factoryFor<$className>(');
    buffer.writeln('      generatorProvider: generatorProvider,');
    buffer.writeln('    );');

    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }
}
