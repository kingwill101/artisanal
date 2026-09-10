import 'dart:async';
import 'dart:io';

import 'package:artisanal/editor_core.dart'
    show EditorCompletionItem, EditorCompletionRequest, EditorCompletionResult;
import 'package:artisanal_editor/src/ui/editor_app.dart';
import 'package:artisanal_editor/src/lsp/editor_language_service.dart';
import 'package:artisanal_editor/src/workspace/editor_file_repository.dart';
import 'package:artisanal_editor/src/workspace/editor_workspace.dart';
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/terminal.dart' show Key, KeyType;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' show Navigator, ValueKey;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('remaps suspend into Ctrl+Z for editor undo', () {
    final message = remapEditorInput(const runtime.SuspendMsg());

    expect(message, isA<runtime.KeyMsg>());
    final key = (message as runtime.KeyMsg).key;
    expect(key.type, KeyType.runes);
    expect(key.ctrl, isTrue);
    expect(key.char, 'z');
  });

  test(
    'renders a dense editor and reveals optional panels on demand',
    () async {
      final sandbox = await Directory.systemTemp.createTemp('editor-screen-');
      addTearDown(() async => sandbox.delete(recursive: true));
      await File(
        p.join(sandbox.path, 'main.dart'),
      ).writeAsString('// TODO: implement\nvoid main() {}\n');
      const repository = EditorFileRepository();
      final files = await repository.discover(sandbox.path);
      final workspace = EditorWorkspace(
        root: sandbox.path,
        files: files,
        repository: repository,
      );
      await workspace.open(files.single);

      final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
      addTearDown(tester.dispose);
      await tester.pumpWidget(EditorScreen(workspace: workspace));

      expect(tester.view, contains('main.dart'));
      expect(tester.view, contains('NORMAL'));
      expect(tester.view, isNot(contains('Tracked TODO item')));
      expect(tester.view, isNot(contains('Problems')));
      expect(tester.view, contains('UTF-8'));
      expect(
        tester.view,
        matches(RegExp('\x1B\\[(?:[0-9:]+;)*4(?:;[0-9:]+)*m')),
        reason: 'diagnostic ranges should render with an underline SGR style',
      );
      final diagnosticTarget = tester.locateText('TODO');
      expect(diagnosticTarget, isNotNull);
      tester.tapAt(diagnosticTarget!.x + 1, diagnosticTarget.y);
      final diagnosticDetails = tester.locateText('Tracked TODO item.');
      expect(diagnosticDetails, isNotNull);
      expect(
        tester.view,
        contains('Tracked TODO item.'),
        reason: 'clicking an underlined issue should reveal its details',
      );
      expect(
        diagnosticDetails!.y,
        diagnosticTarget.y,
        reason: 'diagnostic details should render beside the affected line',
      );

      tester.sendMsg(
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x70], ctrl: true)),
      );
      expect(tester.view, contains('COMMAND PALETTE'));
      expect(tester.view, contains('Save File'));
      tester.typeText('Show Output');
      tester.sendSpecialKey(KeyType.enter);
      expect(tester.view, isNot(contains('COMMAND PALETTE')));
      expect(tester.view, contains('Output panel'));

      tester.sendMsg(
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x6a], ctrl: true)),
      );
      expect(tester.view, isNot(contains('Output')));

      tester.sendMsg(
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x62], ctrl: true)),
      );
      expect(tester.view, isNot(contains('main.dart ●')));
    },
  );

  test('shows a resizable Markdown preview that can be toggled', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'editor-markdown-preview-',
    );
    addTearDown(() async => sandbox.delete(recursive: true));
    final readme = File(p.join(sandbox.path, 'README.md'));
    await readme.writeAsString(
      '# Preview heading\n\nA **rendered** paragraph.\n',
    );
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    await workspace.open(files.single);

    final tester = WidgetTester(screenWidth: 120, screenHeight: 30);
    addTearDown(tester.dispose);
    await tester.pumpWidget(EditorScreen(workspace: workspace));

    expect(tester.view, contains('MARKDOWN PREVIEW'));
    expect(tester.view, contains('Preview heading'));

    tester.tap(
      tester.find.byKeyLocation(
        ValueKey('close-markdown-preview:${p.canonicalize(readme.path)}'),
      ),
    );
    expect(tester.view, isNot(contains('MARKDOWN PREVIEW')));

    tester.sendMsg(
      const runtime.KeyMsg(
        Key(KeyType.runes, runes: [0x76], ctrl: true, shift: true),
      ),
    );
    expect(tester.view, contains('MARKDOWN PREVIEW'));

    tester.sendMsg(
      const runtime.KeyMsg(Key(KeyType.runes, runes: [0x70], ctrl: true)),
    );
    tester.typeText('Markdown Preview');
    tester.sendSpecialKey(KeyType.enter);
    expect(tester.view, isNot(contains('MARKDOWN PREVIEW')));
  });

  test('file tree and editor respond to mouse wheel scrolling', () async {
    final sandbox = await Directory.systemTemp.createTemp('editor-scroll-');
    addTearDown(() async => sandbox.delete(recursive: true));
    for (var index = 0; index < 30; index++) {
      await File(
        p.join(
          sandbox.path,
          'lib',
          'src',
          'file_${index.toString().padLeft(2, '0')}.dart',
        ),
      ).create(recursive: true);
    }
    final activeFile = File(p.join(sandbox.path, 'main.dart'));
    await activeFile.writeAsString(
      List.generate(40, (index) => '// line $index').join('\n'),
    );
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    final buffer = await workspace.open(
      files.singleWhere((file) => file.path == p.canonicalize(activeFile.path)),
    );
    buffer.controller.setCursor(0, 0);

    final tester = WidgetTester(screenWidth: 100, screenHeight: 24);
    addTearDown(tester.dispose);
    await tester.pumpWidget(EditorScreen(workspace: workspace));

    expect(tester.view, contains('lib'));
    expect(tester.view, isNot(contains('src')));
    expect(tester.view, isNot(contains('file_00')));
    tester.tap(tester.find.byKeyLocation(const ValueKey('explorer:lib')));
    expect(tester.view, contains('src'));
    expect(tester.view, isNot(contains('file_00')));
    tester.tap(tester.find.byKeyLocation(const ValueKey('explorer:lib/src')));
    expect(tester.view, contains('file_00'));
    expect(tester.view, contains('█'));
    final treeTarget = tester.locateText('file_00');
    expect(treeTarget, isNotNull);
    tester.sendMsg(
      runtime.MouseMsg(
        action: runtime.MouseAction.wheel,
        button: runtime.MouseButton.wheelDown,
        x: treeTarget!.x,
        y: treeTarget.y,
      ),
    );
    expect(tester.view, isNot(contains('file_00')));

    final editorTarget = tester.locateText('line 0');
    expect(editorTarget, isNotNull);
    tester.sendMsg(
      runtime.MouseMsg(
        action: runtime.MouseAction.wheel,
        button: runtime.MouseButton.wheelDown,
        x: editorTarget!.x,
        y: editorTarget.y,
      ),
    );
    expect(buffer.controller.line, 3);
  });

  test('closes clean tabs and offers save-and-close for dirty tabs', () async {
    final sandbox = await Directory.systemTemp.createTemp('editor-close-');
    addTearDown(() async => sandbox.delete(recursive: true));
    final firstFile = File(p.join(sandbox.path, 'first.dart'));
    final secondFile = File(p.join(sandbox.path, 'second.dart'));
    await firstFile.writeAsString('void first() {}\n');
    await secondFile.writeAsString('void second() {}\n');
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    final first = await workspace.open(files.first);
    await workspace.open(files.last);

    final tester = WidgetTester(screenWidth: 100, screenHeight: 24);
    addTearDown(tester.dispose);
    await tester.pumpWidget(
      Navigator(home: EditorScreen(workspace: workspace)),
    );

    tester.tap(
      tester.find.byKeyLocation(
        ValueKey('close-tab:${p.canonicalize(secondFile.path)}'),
      ),
    );
    expect(workspace.openBuffers, [same(first)]);
    first.controller.insertText('// changed\n');
    tester.sendMsg(
      const runtime.KeyMsg(Key(KeyType.runes, runes: [0x77], ctrl: true)),
    );
    expect(workspace.openBuffers, [same(first)]);
    expect(tester.view, contains('UNSAVED CHANGES'));
    expect(tester.view, contains('Save and close'));
    expect(tester.view, contains('Discard changes'));

    tester.sendSpecialKey(KeyType.escape);
    for (
      var attempt = 0;
      attempt < 20 && tester.view.contains('UNSAVED CHANGES');
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      tester.pump();
    }
    expect(workspace.openBuffers, [same(first)]);
    expect(tester.view, isNot(contains('UNSAVED CHANGES')));

    tester.sendMsg(
      const runtime.KeyMsg(Key(KeyType.runes, runes: [0x77], ctrl: true)),
    );
    expect(tester.view, contains('UNSAVED CHANGES'));
    tester.sendSpecialKey(KeyType.enter);
    for (
      var attempt = 0;
      attempt < 100 && workspace.openBuffers.isNotEmpty;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    tester.pump();

    expect(workspace.openBuffers, isEmpty);
    expect(await firstFile.readAsString(), contains('// changed'));
  });

  test('dirty close can explicitly discard edits', () async {
    final sandbox = await Directory.systemTemp.createTemp('editor-discard-');
    addTearDown(() async => sandbox.delete(recursive: true));
    final file = File(p.join(sandbox.path, 'main.dart'));
    const original = 'void main() {}\n';
    await file.writeAsString(original);
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    final buffer = await workspace.open(files.single);
    buffer.controller.insertText('// discarded\n');

    final tester = WidgetTester(screenWidth: 100, screenHeight: 24);
    addTearDown(tester.dispose);
    await tester.pumpWidget(
      Navigator(home: EditorScreen(workspace: workspace)),
    );

    tester.sendMsg(
      const runtime.KeyMsg(Key(KeyType.runes, runes: [0x77], ctrl: true)),
    );
    tester.sendSpecialKey(KeyType.down);
    tester.sendSpecialKey(KeyType.enter);
    for (
      var attempt = 0;
      attempt < 20 && workspace.openBuffers.isNotEmpty;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      tester.pump();
    }

    expect(workspace.openBuffers, isEmpty);
    expect(await file.readAsString(), original);
  });

  test('Ctrl+Space uses the language service in Artisanal popup', () async {
    final sandbox = await Directory.systemTemp.createTemp('editor-complete-');
    addTearDown(() async => sandbox.delete(recursive: true));
    await File(p.join(sandbox.path, 'main.dart')).writeAsString('');
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final language = _CompletionLanguageService();
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
      languageService: language,
    );
    final buffer = await workspace.open(files.single);

    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(tester.dispose);
    await tester.pumpWidget(EditorScreen(workspace: workspace));
    tester.sendMsg(const runtime.KeyMsg(Key(KeyType.space, ctrl: true)));
    for (
      var attempt = 0;
      attempt < 20 && !buffer.controller.model.completionVisible;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    tester.pump();

    expect(buffer.controller.model.completionVisible, isTrue);
    expect(tester.view, contains('uniqueCompletion'));
    tester.sendSpecialKey(KeyType.enter);
    expect(buffer.controller.text, 'uniqueCompletion');
  });

  test('K shows language hover and Escape dismisses it', () async {
    final sandbox = await Directory.systemTemp.createTemp('editor-hover-');
    addTearDown(() async => sandbox.delete(recursive: true));
    await File(
      p.join(sandbox.path, 'main.dart'),
    ).writeAsString('void main() {}');
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
      languageService: _CompletionLanguageService(),
    );
    await workspace.open(files.single);

    final tester = WidgetTester(screenWidth: 110, screenHeight: 34);
    addTearDown(tester.dispose);
    await tester.pumpWidget(EditorScreen(workspace: workspace));
    tester.sendKey('K');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    tester.pump();

    expect(tester.view, contains('HOVER'));
    expect(tester.view, contains('Fake'));
    expect(tester.view, contains('documentation'));
    tester.sendSpecialKey(KeyType.escape);
    expect(tester.view, isNot(contains('Fake')));
  });
}

final class _CompletionLanguageService implements EditorLanguageService {
  final StreamController<EditorLanguageEvent> _events =
      StreamController.broadcast();

  @override
  Stream<EditorLanguageEvent> get events => _events.stream;

  @override
  bool supports(String languageId) => languageId == 'dart';

  @override
  void openDocument({
    required String path,
    required String languageId,
    required String text,
  }) {}

  @override
  void changeDocument({required String path, required String text}) {}

  @override
  void closeDocument(String path) {}

  @override
  void saveDocument({required String path, required String text}) {}

  @override
  Future<EditorCompletionResult> provideCompletions({
    required String path,
    required EditorCompletionRequest request,
  }) async {
    return const EditorCompletionResult(
      items: [
        EditorCompletionItem(
          label: 'uniqueCompletion',
          insertText: 'uniqueCompletion',
        ),
      ],
    );
  }

  @override
  Future<EditorLanguageHover?> provideHover({
    required String path,
    required String documentText,
    required int cursorOffset,
  }) async {
    return const EditorLanguageHover(contents: '**Fake hover documentation**');
  }

  @override
  Future<void> dispose() => _events.close();
}
