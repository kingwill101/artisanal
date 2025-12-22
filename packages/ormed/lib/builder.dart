/// Configuration for the ORM code generator.
///
/// This library provides the [ormModelBuilder] which is used by `build_runner`
/// to generate `.orm.dart` files for classes annotated with `@OrmModel`.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/builder/model_generator.dart';

/// Provides the default `build_runner` entrypoint for ORM model generation.
Builder ormModelBuilder(BuilderOptions options) {
  final delegate = PartBuilder(
    [OrmModelGenerator(options)],
    '.orm.dart',
    header: '// GENERATED CODE - DO NOT MODIFY BY HAND',
  );
  return _OrmPartBuilder(delegate);
}

class _OrmPartBuilder implements Builder {
  _OrmPartBuilder(this._delegate);

  final Builder _delegate;

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.orm.dart', '.orm_model.json'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    await _delegate.build(buildStep);
  }
}
