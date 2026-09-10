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
import 'package:artisanal_widgets/widgets.dart'
    show Navigator, OpenCodeThemes, ThemeScope, ValueKey;
import 'package:path/path.dart' as p;
import 'package:pty2/pty2.dart' show PseudoTerminal;
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

  test('preserves interrupts for coordinated terminal shutdown', () {
    const interrupt = runtime.InterruptMsg();

    expect(remapEditorInput(interrupt), same(interrupt));
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
      final terminals = <_FakePseudoTerminal>[];
      String? terminalRoot;
      await tester.pumpWidget(
        EditorScreen(
          workspace: workspace,
          terminalStarter: (root) {
            terminalRoot = root;
            final terminal = _FakePseudoTerminal();
            terminals.add(terminal);
            return terminal;
          },
        ),
      );

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
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x60], ctrl: true)),
      );
      expect(tester.view, contains('Terminal'));
      expect(tester.view, contains('TERMINAL'));
      expect(terminalRoot, p.canonicalize(sandbox.path));
      final terminal = terminals.single;
      expect(terminal.lastSize, (width: 81, height: 9));
      expect(
        tester.find.byKeyLocation(const ValueKey('integrated-terminal:1')),
        isNotNull,
      );
      terminal.emit('terminal-ready');
      await Future<void>.delayed(Duration.zero);
      tester.pump();
      expect(tester.view, contains('terminal-ready'));
      final terminalBeforeResize = tester.locateText('terminal-ready')!;
      final bottomDivider = tester.locateText('━')!;
      tester.drag(
        bottomDivider.x,
        bottomDivider.y,
        bottomDivider.x,
        bottomDivider.y - 3,
      );
      final terminalAfterResize = tester.locateText('terminal-ready')!;
      expect(terminalAfterResize.y, lessThan(terminalBeforeResize.y));
      expect(terminal.lastSize, (width: 81, height: 12));
      tester.sendMsg(
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x63], ctrl: true)),
      );
      tester.sendMsg(remapEditorInput(const runtime.SuspendMsg()));
      tester.sendMsg(
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x77], ctrl: true)),
      );
      expect(terminal.input, containsAllInOrder(['\x03', '\x1a', '\x17']));
      expect(workspace.openBuffers, hasLength(1));
      terminal.emit('\x1b[?1049h\x1b[>13u\x1b[?1000h\x1b[?1006h');
      await Future<void>.delayed(Duration.zero);
      tester.pump();
      expect(tester.view, contains('TERMINAL'));
      tester.sendSpecialKey(KeyType.down);
      expect(terminal.input, contains('\x1b[B'));
      tester.tap(
        tester.find.byKeyLocation(const ValueKey('close-bottom-panel')),
      );
      expect(tester.view, isNot(contains('Terminal')));
      tester.sendMsg(
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x60], ctrl: true)),
      );
      terminal.emit('terminal-reopened');
      await Future<void>.delayed(Duration.zero);
      tester.pump();
      expect(tester.view, contains('terminal-reopened'));

      tester.tap(tester.find.byKeyLocation(const ValueKey('new-terminal')));
      expect(terminals, hasLength(2));
      expect(
        tester.find.byKeyLocation(const ValueKey('integrated-terminal:1')),
        isNotNull,
      );
      expect(
        tester.find.byKeyLocation(const ValueKey('integrated-terminal:2')),
        isNotNull,
      );
      final secondTerminal = terminals.last;
      secondTerminal.emit('second-terminal-ready');
      await Future<void>.delayed(Duration.zero);
      tester.pump();
      expect(tester.view, contains('second-terminal-ready'));
      tester.sendMsg(
        const runtime.KeyMsg(Key(KeyType.runes, runes: [0x64], ctrl: true)),
      );
      tester.pump();
      expect(secondTerminal.killed, isTrue);
      expect(
        tester.find.byKeyLocation(const ValueKey('integrated-terminal:1')),
        isNotNull,
      );

      tester.tap(tester.find.byKeyLocation(const ValueKey('new-terminal')));
      final thirdTerminal = terminals.last;
      expect(thirdTerminal, isNot(same(secondTerminal)));
      tester.sendMsg(const runtime.InterruptMsg());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(terminal.killed, isTrue);
      expect(thirdTerminal.killed, isTrue);
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
      ThemeScope(
        theme: OpenCodeThemes.ayu(),
        child: Navigator(home: EditorScreen(workspace: workspace)),
      ),
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
    expect(tester.view, contains('Keep editing'));
    expect(
      tester.locateText('UNSAVED CHANGES')?.y,
      inInclusiveRange(1, 20),
      reason: 'the dirty-buffer prompt should be a visible compact dialog',
    );
    expect(
      tester.locateText('void'),
      isNotNull,
      reason: 'the default modal barrier should not hide the editor',
    );

    tester.sendSpecialKey(KeyType.escape);
    for (
      var attempt = 0;
      attempt < 100 && tester.view.contains('UNSAVED CHANGES');
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

final class _FakePseudoTerminal implements PseudoTerminal {
  final StreamController<String> _output = StreamController();
  final Completer<int> _exitCode = Completer();
  final List<String> input = [];
  bool killed = false;
  ({int width, int height})? lastSize;

  void emit(String data) => _output.add(data);

  @override
  Stream<String> get out => _output.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  void ackProcessed() {}

  @override
  void init() {}

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_output.isClosed) unawaited(_output.close());
    if (!_exitCode.isCompleted) _exitCode.complete(0);
    return true;
  }

  @override
  void resize(int width, int height) {
    lastSize = (width: width, height: height);
  }

  @override
  void write(String value) => input.add(value);
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
