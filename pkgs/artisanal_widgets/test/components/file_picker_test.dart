import 'dart:io';

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart'
    show InterruptMsg, MouseAction, MouseButton, MouseMsg;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    tester.pump();
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for file picker update');
}

void main() {
  group('FilePicker', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('artisanal-file-picker');
      await File('${tempDir.path}/README.md').writeAsString('docs');
      await File('${tempDir.path}/notes.txt').writeAsString('notes');
      await File('${tempDir.path}/.env').writeAsString('secret');
      await Directory('${tempDir.path}/src').create();
      await File('${tempDir.path}/src/main.dart').writeAsString('void main() {}');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loads entries and selects allowed files', () async {
      final tester = WidgetTester(screenWidth: 84, screenHeight: 24);
      addTearDown(() => tester.dispose());

      String? selectedPath;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: FilePicker(
            directory: tempDir.path,
            allowedExtensions: const ['.md', '.dart'],
            onSelected: (path) {
              selectedPath = path;
              return null;
            },
          ),
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('README.md'));

      expect(tester.view, contains('README.md'));
      expect(tester.view, contains('notes.txt'));

      tester.sendSpecialKey(terminal_keys.KeyType.down);
      tester.sendSpecialKey(terminal_keys.KeyType.down);
      tester.sendSpecialKey(terminal_keys.KeyType.enter);

      expect(selectedPath, equals('${tempDir.path}/README.md'));
    });

    test('toggles hidden files and opens directories', () async {
      final tester = WidgetTester(screenWidth: 84, screenHeight: 24);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: FilePicker(
            directory: tempDir.path,
            allowedExtensions: const ['.md', '.dart'],
          ),
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('README.md'));

      expect(tester.view, isNot(contains('.env')));

      tester.sendKey('.');
      await _pumpUntil(tester, () => tester.view.contains('.env'));

      expect(tester.view, contains('.env'));

      tester.sendSpecialKey(terminal_keys.KeyType.right);
      await _pumpUntil(tester, () => tester.view.contains('main.dart'));

      expect(tester.view, contains('main.dart'));

      tester.sendSpecialKey(terminal_keys.KeyType.backspace);
      await _pumpUntil(tester, () => tester.view.contains('README.md'));

      expect(tester.view, contains('README.md'));
    });

    test('shows selection errors and exits on interrupt', () async {
      final tester = WidgetTester(screenWidth: 58, screenHeight: 20);
      addTearDown(() => tester.dispose());

      var exited = false;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: FilePicker(
            directory: tempDir.path,
            allowedExtensions: const ['.md'],
            onExit: () {
              exited = true;
              return null;
            },
          ),
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('README.md'));

      tester.sendSpecialKey(terminal_keys.KeyType.down);
      tester.sendSpecialKey(terminal_keys.KeyType.enter);

      expect(tester.view, contains('notes.txt is not allowed'));
      expect(tester.view, contains('ctrl+c'));
      expect(tester.view, contains('quit'));

      tester.sendMsg(const InterruptMsg());
      expect(exited, isTrue);
    });

    test('scrolls long directory listings with wheel input', () async {
      for (var i = 0; i < 12; i++) {
        await File(
          '${tempDir.path}/item_${i.toString().padLeft(2, '0')}.txt',
        ).writeAsString('file $i');
      }

      final tester = WidgetTester(screenWidth: 72, screenHeight: 18);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: FilePicker(directory: tempDir.path, height: 5),
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('item_00.txt'));

      expect(tester.view, contains('1-5 of 15'));
      expect(tester.view, contains('item_00.txt'));
      expect(tester.view, isNot(contains('item_11.txt')));

      final target = tester.locateText('item_00.txt');
      expect(target, isNotNull);

      tester.sendMsg(
        MouseMsg(
          action: MouseAction.wheel,
          button: MouseButton.wheelDown,
          x: target!.x,
          y: target.y,
        ),
      );

      expect(tester.view, contains('4-8 of 15'));
      expect(tester.view, isNot(contains('item_00.txt')));
      expect(tester.view, contains('item_03.txt'));
    });
  });
}
