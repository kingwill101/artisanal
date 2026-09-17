import 'dart:io';

import 'package:artisanal_editor/src/ui/editor_app.dart';
import 'package:artisanal_editor/src/workspace/editor_file_repository.dart';
import 'package:artisanal_editor/src/workspace/editor_workspace.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('markdown preview renders math from the buffer text', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'editor-math-preview-',
    );
    addTearDown(() async => sandbox.delete(recursive: true));
    final file = File(p.join(sandbox.path, 'math_preview.md'));
    await file.writeAsString(
      [
        '# Math',
        '',
        r'Inline \(E = mc^2\) and $a^2 + b^2 = c^2$.',
        '',
        r'$$',
        r'\frac{a}{b}',
        r'$$',
        '',
      ].join('\n'),
    );
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
    );
    await workspace.open(files.single);

    final tester = WidgetTester(screenWidth: 120, screenHeight: 36);
    addTearDown(tester.dispose);
    await tester.pumpWidget(EditorScreen(workspace: workspace));

    expect(tester.view, contains('MARKDOWN PREVIEW'));
    expect(tester.view, contains('E=mc²'), reason: tester.view);
    expect(tester.view, contains('a²+b²=c²'), reason: tester.view);
    expect(tester.view, contains('─'), reason: tester.view);
  });
}
