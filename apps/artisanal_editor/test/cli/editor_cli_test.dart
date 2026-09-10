import 'dart:io';

import 'package:artisanal_editor/src/cli/editor_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('artisanal-cli-');
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  test(
    'opens the current workspace by default through Artisanal CommandRunner',
    () async {
      EditorLaunchRequest? request;

      await runArtisanalEditor(
        const [],
        workingDirectory: sandbox.path,
        launcher: (value) async => request = value,
      );

      expect(request, isNotNull);
      expect(request!.workspace, p.canonicalize(sandbox.path));
      expect(request!.paths, isEmpty);
      expect(request!.enableLsp, isTrue);
    },
  );

  test(
    'supports direct file shorthand without bypassing the command runner',
    () async {
      final file = File(p.join(sandbox.path, 'main.dart'));
      await file.writeAsString('void main() {}');
      EditorLaunchRequest? request;

      await runArtisanalEditor(
        ['main.dart'],
        workingDirectory: sandbox.path,
        launcher: (value) async => request = value,
      );

      expect(request, isNotNull);
      expect(request!.workspace, p.canonicalize(sandbox.path));
      expect(request!.paths, [p.canonicalize(file.path)]);
      expect(request!.enableLsp, isTrue);
    },
  );

  test(
    'passes workspace and hidden options through the edit command',
    () async {
      final file = File(p.join(sandbox.path, '.hidden.dart'));
      await file.writeAsString('// hidden');
      EditorLaunchRequest? request;

      await runArtisanalEditor(
        ['edit', '--workspace', sandbox.path, '--hidden', file.path],
        workingDirectory: Directory.current.path,
        launcher: (value) async => request = value,
      );

      expect(request, isNotNull);
      expect(request!.includeHidden, isTrue);
      expect(request!.workspace, p.canonicalize(sandbox.path));
      expect(request!.enableLsp, isTrue);
    },
  );

  test('allows language tooling to be disabled', () async {
    EditorLaunchRequest? request;

    await runArtisanalEditor(
      const ['--no-lsp'],
      workingDirectory: sandbox.path,
      launcher: (value) async => request = value,
    );

    expect(request, isNotNull);
    expect(request!.enableLsp, isFalse);
  });
}
