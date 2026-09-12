import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('renderer capture is disabled by default', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);

    await tester.pumpWidget(Text('default'));

    expect(tester.enableRenderer, isFalse);
    expect(tester.rendererOutput, isEmpty);
    expect(tester.view, contains('default'));
  });

  test('opt-in capture uses the production renderer and emits ANSI', () async {
    final tester = WidgetTester(enableRenderer: true);
    addTearDown(tester.dispose);

    await tester.pumpWidget(Text('production'));

    expect(tester.rendererOutput, isNotEmpty);
    expect(tester.rendererOutput, contains('production'));
    expect(tester.rendererOutput, contains('\x1b['));
    expect(tester.view, contains('production'));

    tester.clearRendererOutput();
    expect(tester.rendererOutput, isEmpty);
    expect(tester.lastRendererOutput, isEmpty);
  });

  test('full-screen capture includes the complete 80x24 scene', () async {
    final tester = WidgetTester(
      screenWidth: 80,
      screenHeight: 24,
      enableRenderer: true,
      altScreen: true,
    );
    addTearDown(tester.dispose);

    final scene = List<String>.generate(
      20,
      (index) => 'row ${index + 1}: 🂡 card content',
    )..addAll(const <String>['footer: totals ✓', 'footer: ready']);
    await tester.pumpWidget(Text(scene.join('\n')));

    expect(tester.altScreen, isTrue);
    expect(tester.rendererOutput, contains('row 20: 🂡 card content'));
    expect(tester.rendererOutput, contains('footer: totals ✓'));
    expect(tester.rendererOutput, contains('footer: ready'));
  });

  test(
    'successive output batches cover history once and reset after clear',
    () async {
      final tester = WidgetTester(
        enableRenderer: true,
        altScreen: true,
        screenWidth: 24,
        screenHeight: 4,
      );
      addTearDown(tester.dispose);
      await tester.pumpWidget(Text('Frame α 🚀\nSecond line'));
      final batches = StringBuffer()..write(tester.lastRendererOutput);

      for (var i = 0; i < 64; i++) {
        tester.resize(25 + i % 2, 4);
        batches.write(tester.lastRendererOutput);
      }
      expect(tester.rendererOutput, batches.toString());
      expect(tester.rendererOutput.length, batches.length);

      final beforeNoop = tester.rendererOutput;
      tester.sendKey('a');
      expect(tester.lastRendererOutput, isEmpty);
      expect(tester.rendererOutput, beforeNoop);

      tester.clearRendererOutput();
      expect(tester.rendererOutput, isEmpty);
      expect(tester.lastRendererOutput, isEmpty);
      tester.resize(30, 4);
      expect(tester.lastRendererOutput, isNotEmpty);
      expect(tester.rendererOutput, tester.lastRendererOutput);
      expect(tester.rendererOutput, contains('Frame α 🚀'));
    },
  );

  test(
    'remount disposes the previous program and resets renderer capture',
    () async {
      final tester = WidgetTester(enableRenderer: true);
      addTearDown(tester.dispose);

      await tester.pumpWidget(Text('first'));
      final firstProgram = tester.program;
      expect(tester.lastRendererOutput, contains('first'));

      await tester.pumpWidget(Text('second'));

      expect(firstProgram, isNot(same(tester.program)));
      expect(firstProgram!.currentModel, isNull);
      expect(tester.view, contains('second'));
      expect(tester.lastRendererOutput, contains('second'));
    },
  );

  test('tester can be disposed and reused', () async {
    final tester = WidgetTester(enableRenderer: true);
    addTearDown(tester.dispose);

    await tester.pumpWidget(Text('before dispose'));
    await tester.dispose();
    expect(tester.program, isNull);

    await tester.pumpWidget(Text('after dispose'));
    expect(tester.view, contains('after dispose'));
    expect(tester.lastRendererOutput, contains('after dispose'));
  });
}
