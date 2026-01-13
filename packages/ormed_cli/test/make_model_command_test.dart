import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:ormed_cli/src/commands.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MakeModelCommand', () {
    late Directory scratchDir;

    setUp(() {
      final scratchParent = Directory(
        p.join(Directory.systemTemp.path, 'ormed_cli_make_model_test'),
      );
      if (!scratchParent.existsSync()) {
        scratchParent.createSync(recursive: true);
      }
      scratchDir = Directory(
        p.join(
          scratchParent.path,
          DateTime.now().microsecondsSinceEpoch.toString(),
        ),
      );
      scratchDir.createSync(recursive: true);

      File(p.join(scratchDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: scratch
environment:
  sdk: ">=3.10.0 <4.0.0"
''');
      File(p.join(scratchDir.path, 'ormed.yaml')).writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: database/scratch.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
  ledger_table: orm_migrations
seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
''');
      Directory.current = scratchDir;
    });

    tearDown(() {
      if (scratchDir.existsSync()) {
        scratchDir.deleteSync(recursive: true);
      }
    });

    test('creates a model file with part directive', () async {
      final runner = CommandRunner<void>('ormed', 'Routed ORM CLI')
        ..addCommand(MakeModelCommand());

      await runner.run(['make:model', 'Post']);

      final modelPath = p.join(
        scratchDir.path,
        'lib/src/database/models/post.dart',
      );
      final file = File(modelPath);
      expect(file.existsSync(), isTrue);
      final text = file.readAsStringSync();
      expect(text, contains("part 'post.orm.dart';"));
      expect(text, contains('class Post'));
      expect(text, contains("@OrmModel(table: 'posts')"));
    });
  });
}
