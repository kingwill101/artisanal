import 'dart:io';

import 'package:artisanal_editor/artisanal_editor.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('artisanal-editor-test-');
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  test(
    'discovers supported source files and ignores generated directories',
    () async {
      await File(
        p.join(sandbox.path, 'lib', 'main.dart'),
      ).create(recursive: true);
      await File(p.join(sandbox.path, 'README.md')).writeAsString('# Project');
      await File(p.join(sandbox.path, 'notes.bin')).writeAsBytes([1, 2, 3]);
      await File(
        p.join(sandbox.path, 'build', 'generated.dart'),
      ).create(recursive: true);
      await File(p.join(sandbox.path, '.secret.dart')).writeAsString('secret');

      const repository = EditorFileRepository();
      final files = await repository.discover(sandbox.path);

      expect(files.map((file) => file.relativePath), [
        'README.md',
        p.join('lib', 'main.dart'),
      ]);
      expect(files.last.language, 'dart');
    },
  );

  test('reads and writes through the repository boundary', () async {
    final path = p.join(sandbox.path, 'main.dart');
    await File(path).writeAsString('void main() {}');
    const repository = EditorFileRepository();
    final entry = repository.entryForPath(path, root: sandbox.path);

    expect(await repository.read(entry), 'void main() {}');
    await repository.write(entry, 'void main() => run();');
    expect(await File(path).readAsString(), 'void main() => run();');
  });
}
