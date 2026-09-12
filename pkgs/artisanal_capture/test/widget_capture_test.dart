import 'package:artisanal_capture/widgets.dart';
import 'package:artisanal_widgets/widgets.dart';
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
