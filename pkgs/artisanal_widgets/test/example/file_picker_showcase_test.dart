import 'dart:io';

import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/file_picker/main.dart' as example;

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
  fail('Timed out waiting for showcase render');
}

void main() {
  test('file picker showcase renders the browser view', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'artisanal-file-picker-showcase',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await File('${tempDir.path}/README.md').writeAsString('docs');
    await Directory('${tempDir.path}/src').create();

    final tester = WidgetTester(screenWidth: 96, screenHeight: 28);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      example.FilePickerShowcaseScreen(initialDirectory: tempDir.path),
    );
    await _pumpUntil(tester, () => tester.view.contains('README.md'));

    expect(tester.find.text('Browse project files'), isTrue);
    expect(tester.view, contains('README.md'));
    expect(tester.view, contains('ctrl+c'));
  });
}
