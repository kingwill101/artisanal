import 'dart:io';

import 'package:args/command_runner.dart' show UsageException;
import 'package:artisanal/args.dart';
import 'package:path/path.dart' as p;

import '../../config.dart';
import '../base/shared.dart';

class MakeModelCommand extends Command<void> {
  MakeModelCommand() {
    argParser
      ..addOption('name', abbr: 'n', help: 'Class name for the model.')
      ..addOption(
        'path',
        help: 'Override the models directory (relative to project root unless --realpath is set).',
      )
      ..addFlag(
        'realpath',
        negatable: false,
        help: 'Treat --path as an absolute file system path.',
      )
      ..addOption(
        'table',
        help: 'Override the database table name (defaults to pluralized snake case).',
      )
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to ormed.yaml (defaults to project root).',
      );
  }

  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new model file with @OrmModel scaffolding.';

  @override
  Future<void> run() async {
    var name = (argResults?['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      final rest = argResults?.rest ?? const <String>[];
      if (rest.isNotEmpty) {
        name = rest.first.trim();
      }
    }
    if (name == null || name.isEmpty) {
      name = io.ask(
        'What is the name of the model?',
        validator: (value) {
          if (value.trim().isEmpty) return 'Name cannot be empty.';
          return null;
        },
      );
    }

    final configArg = argResults?['config'] as String?;
    final context = resolveOrmProject(configPath: configArg);
    final root = context.root;
    final modelsDir = Directory(
      _resolveDirectory(
        root: root,
        overridePath: argResults?['path'] as String?,
        defaultPath: 'lib/src/database/models',
        useRealPath: argResults?['realpath'] == true,
      ),
    );

    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }

    final className = _toPascalCase(name);
    final snake = _toSnakeCase(name);
    final file = File(p.join(modelsDir.path, '$snake.dart'));
    if (file.existsSync()) {
      throw UsageException('Model file ${file.path} already exists.', usage);
    }

    final tableOption = (argResults?['table'] as String?)?.trim();
    final tableName =
        tableOption == null || tableOption.isEmpty
            ? _pluralize(snake)
            : tableOption;

    file.writeAsStringSync(_modelTemplate(className, snake, tableName));

    cliIO.success('Created model');
    cliIO.components.horizontalTable({
      'File': p.relative(file.path, from: root.path),
      'Class': className,
      'Table': tableName,
    });
    cliIO.note('Run: dart run build_runner build');
  }
}

String _resolveDirectory({
  required Directory root,
  required String defaultPath,
  String? overridePath,
  required bool useRealPath,
}) {
  final candidate = overridePath ?? defaultPath;
  if (useRealPath || p.isAbsolute(candidate)) {
    return p.normalize(candidate);
  }
  return resolvePath(root, candidate);
}

String _toPascalCase(String value) => value
    .split(RegExp('[-_ ]+'))
    .where((segment) => segment.isNotEmpty)
    .map(
      (segment) => segment.substring(0, 1).toUpperCase() + segment.substring(1),
    )
    .join();

String _toSnakeCase(String value) => value
    .trim()
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    )
    .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '')
    .toLowerCase();

String _pluralize(String value) {
  if (value.endsWith('s')) return value;
  return '${value}s';
}

String _modelTemplate(String className, String snake, String tableName) =>
    '''
import 'package:ormed/ormed.dart';

part '$snake.orm.dart';

@OrmModel(table: '$tableName')
class $className extends Model<$className> {
  const $className({required this.id});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
}
''';
