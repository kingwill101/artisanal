import 'dart:io';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:ormed/src/builder/emitters/model_codec_emitter.dart';
import 'package:ormed/src/builder/emitters/model_subclass_emitter.dart';
import 'package:ormed/src/builder/helpers.dart';
import 'package:ormed/src/builder/model_context.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

Future<ClassElement> _resolveClass(String className) async {
  final cwd = Directory.current.path;
  final candidates = <String>[
    p.join(
      cwd,
      'packages',
      'ormed',
      'test',
      'builder',
      'fixtures',
      'bug_repro_models.dart',
    ),
    p.join(cwd, 'test', 'builder', 'fixtures', 'bug_repro_models.dart'),
  ];
  final fixturePath = candidates.firstWhere(
    (path) => File(path).existsSync(),
    orElse: () =>
        throw StateError('Fixture not found in ${candidates.join(', ')}'),
  );
  final result = await resolveFile(path: fixturePath);
  if (result is! ResolvedUnitResult) {
    throw StateError('Expected resolved unit for $fixturePath.');
  }
  final classElement = result.libraryElement.classes
      .where((element) => element.displayName == className)
      .firstOrNull;
  if (classElement == null) {
    throw StateError('Class $className not found in $fixturePath.');
  }
  return classElement;
}

ConstantReader _readOrmModelAnnotation(ClassElement element) {
  final annotation = readAnnotation(element, 'OrmModel');
  if (annotation == null) {
    throw StateError('Missing @OrmModel on ${element.displayName}.');
  }
  return annotation;
}

void main() {
  test('codec defaults for non-nullable enum/map/list avoid null', () async {
    final element = await _resolveClass('DefaultValueModel');
    final context = ModelContext(element, _readOrmModelAnnotation(element));
    final output = ModelCodecEmitter(context).emit();

    expect(
      output,
      contains(
        "?? TestStatus.values.firstWhere((value) => value.name == 'active'",
      ),
    );
    expect(output, contains('?? const {}'));
    expect(output, contains('?? const []'));
  });

  test('relation getters are emitted once for relation fields', () async {
    final element = await _resolveClass('RelationModel');
    final context = ModelContext(element, _readOrmModelAnnotation(element));
    final output = ModelSubclassEmitter(context).emit();

    expect(output, contains("relationLoaded('owner')"));
    expect(RegExp(r'\bget owner\b').allMatches(output).length, 1);
    expect(RegExp(r'\bset owner\b').hasMatch(output), isFalse);
    expect(output, isNot(contains('Tracked getter for [owner]')));
  });
}
