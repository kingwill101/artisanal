import 'dart:io';

import 'package:artisanal/editor_core.dart'
    show EditorCommandIds, TextDecorationRange, TextDocument;
import 'package:artisanal_editor/artisanal_editor.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory sandbox;
  const repository = EditorFileRepository();

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('artisanal-workspace-');
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  test('keeps buffers alive across tabs and persists active edits', () async {
    final firstPath = p.join(sandbox.path, 'first.dart');
    final secondPath = p.join(sandbox.path, 'second.dart');
    await File(firstPath).writeAsString('// TODO: first\n');
    await File(secondPath).writeAsString('void second() {}\n');
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    addTearDown(workspace.dispose);

    final first = await workspace.open(files.first);
    expect(first.controller.diagnostics, hasLength(1));
    first.controller.insertText('// changed');
    expect(first.isDirty, isTrue);

    final second = await workspace.open(files.last);
    expect(workspace.activeBuffer, same(second));
    workspace.activate(first);
    expect(workspace.activeBuffer, same(first));
    expect(first.controller.text, contains('// changed'));

    await workspace.saveActive();
    expect(first.isDirty, isFalse);
    expect(await File(firstPath).readAsString(), contains('// changed'));
  });

  test('opening a file does not create an undo step', () async {
    final path = p.join(sandbox.path, 'main.dart');
    const contents = 'void main() {}\n';
    await File(path).writeAsString(contents);
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    addTearDown(workspace.dispose);

    final buffer = await workspace.open(files.single);

    expect(buffer.controller.canUndo, isFalse);
    buffer.controller.dispatch(EditorCommandIds.undo);
    expect(buffer.controller.text, contents);
    expect(buffer.isDirty, isFalse);
  });

  test(
    'publishes app-provided syntax decorations on an independent layer',
    () async {
      final path = p.join(sandbox.path, 'main.dart');
      await File(path).writeAsString('void main() {}\n');
      final files = await repository.discover(sandbox.path);
      final workspace = EditorWorkspace(
        root: sandbox.path,
        files: files,
        repository: repository,
        syntaxHighlighter: const _FakeSyntaxHighlighter(),
      );
      addTearDown(workspace.dispose);

      final buffer = await workspace.open(files.single);
      await Future<void>.delayed(Duration.zero);

      final decorations = buffer.controller.decorationsForLayer(
        'artisanal-editor.tree-sitter',
      );
      expect(decorations, hasLength(1));
      expect(decorations.single.styleKey, 'syntax.keyword');
    },
  );
}

final class _FakeSyntaxHighlighter implements EditorSyntaxHighlighter {
  const _FakeSyntaxHighlighter();

  @override
  bool supports(String languageId) => languageId == 'dart';

  @override
  Future<List<TextDecorationRange>> highlight({
    required String languageId,
    required TextDocument document,
  }) async {
    return const [
      TextDecorationRange(
        startOffset: 0,
        endOffset: 4,
        styleKey: 'syntax.keyword',
      ),
    ];
  }
}
