import 'package:artisanal_capture/widgets.dart';
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  test('captures actual widget layout at fixed dimensions', () async {
    var arranged = false;
    final capture = await captureWidget(
      Column(children: [Text('Hello'), Text('World')]),
      columns: 12,
      rows: 4,
      arrange: (tester) {
        arranged = true;
        expect(tester.view, contains('Hello'));
      },
    );
    expect(arranged, isTrue);
    expect(capture.columns, 12);
    expect(capture.rows, 4);
    final buffer = capture.toBuffer();
    expect(buffer.cellAt(0, 0)!.content, 'H');
    expect(buffer.cellAt(0, 1)!.content, 'W');
  });

  test('renderedFrame mode uses the final native renderer frame', () async {
    final capture = await captureWidget(
      Text('Rendered'),
      columns: 12,
      rows: 2,
      mode: WidgetCaptureMode.renderedFrame,
    );
    expect(capture.toBuffer().cellAt(0, 0)!.content, 'R');
  });

  test('renderedFrame captures the actual F12 overlay over the view', () async {
    final tester = WidgetTester(
      screenWidth: 80,
      screenHeight: 8,
      enableRenderer: true,
      enableNativeFrameCapture: true,
    );
    try {
      await tester.pumpWidget(Text('base'));
      expect(tester.view, isNot(contains('Artisanal DevTools')));

      tester.sendSpecialKey(KeyType.f12);
      final frame = tester.latestNativeFrame;
      expect(frame, isNotNull);
      expect(frame!.plainText, contains('Frame Time:'));
      expect(frame.plainText, contains('base'));
      // The runtime overlay is composed over the rendered view, rather than
      // changing WidgetApp.view(), which remains the canonical app output.
      expect(tester.view, contains('base'));
    } finally {
      await tester.dispose();
    }
  });

  test('propagates scenario errors', () async {
    await expectLater(
      captureWidget(
        Text('Hello'),
        arrange: (_) => throw StateError('scenario failed'),
      ),
      throwsStateError,
    );
  });

  test('rejects invalid viewport before mounting', () async {
    await expectLater(
      captureWidget(Text('Hello'), columns: 0),
      throwsArgumentError,
    );
  });
}
