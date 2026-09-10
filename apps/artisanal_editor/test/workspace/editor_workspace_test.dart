import 'dart:async';
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

  test('keeps edits made during a save dirty', () async {
    final path = p.join(sandbox.path, 'main.dart');
    await File(path).writeAsString('initial');
    final repository = _DelayedWriteRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    addTearDown(workspace.dispose);
    final buffer = await workspace.open(files.single);
    buffer.controller.insertText(' first');

    final saving = workspace.save(buffer);
    await repository.waitForWriteCount(1);
    buffer.controller.insertText(' second');
    repository.complete(0);
    await saving;

    expect(await File(path).readAsString(), 'initial first');
    expect(buffer.controller.text, 'initial first second');
    expect(buffer.isDirty, isTrue);
  });

  test('serializes saves so older snapshots cannot win', () async {
    final path = p.join(sandbox.path, 'main.dart');
    await File(path).writeAsString('initial');
    final repository = _DelayedWriteRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    addTearDown(workspace.dispose);
    final buffer = await workspace.open(files.single);
    buffer.controller.insertText(' first');

    final firstSave = workspace.save(buffer);
    await repository.waitForWriteCount(1);
    buffer.controller.insertText(' second');
    final secondSave = workspace.save(buffer);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repository.writes, hasLength(1));

    repository.complete(0);
    await firstSave;
    await repository.waitForWriteCount(2);
    expect(repository.writes[1].contents, 'initial first second');
    repository.complete(1);
    await secondSave;

    expect(await File(path).readAsString(), 'initial first second');
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

final class _DelayedWriteRepository extends EditorFileRepository {
  final List<_PendingWrite> writes = [];

  @override
  Future<void> write(EditorFileEntry file, String contents) async {
    final pending = _PendingWrite(contents);
    writes.add(pending);
    await pending.allowed.future;
    await super.write(file, contents);
  }

  Future<void> waitForWriteCount(int count) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (writes.length < count) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for $count writes.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  void complete(int index) => writes[index].allowed.complete();
}

final class _PendingWrite {
  _PendingWrite(this.contents);

  final String contents;
  final Completer<void> allowed = Completer();
}
