import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_artisanal/flutter_artisanal.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

void main() {
  group('TerminalWidget', () {
    testWidgets('renders null buffer as SizedBox.shrink', (tester) async {
      await tester.pumpWidget(
        const TerminalWidget(buffer: null),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders CustomPaint when buffer is provided', (tester) async {
      final buffer = uv.Buffer.create(80, 24);

      await tester.pumpWidget(
        TerminalWidget(
          buffer: buffer,
          repaint: ValueNotifier(0),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('calls onResize with layout dimensions', (tester) async {
      var reportedSize = const Size(0, 0);
      final buffer = uv.Buffer.create(80, 24);

      await tester.pumpWidget(
        TerminalWidget(
          buffer: buffer,
          repaint: ValueNotifier(0),
          onResize: (cols, rows) {
            reportedSize = Size(cols.toDouble(), rows.toDouble());
          },
        ),
      );

      expect(reportedSize.width, greaterThan(0));
      expect(reportedSize.height, greaterThan(0));
    });

    testWidgets('triggers rebuild when repaint notifier fires', (tester) async {
      final buffer = uv.Buffer.create(80, 24);
      final repaint = ValueNotifier<int>(0);

      await tester.pumpWidget(
        TerminalWidget(
          buffer: buffer,
          repaint: repaint,
        ),
      );

      repaint.value++;
      await tester.pump();

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('wraps with Focus when onKey is provided', (tester) async {
      final received = <List<int>>[];
      final buffer = uv.Buffer.create(80, 24);

      await tester.pumpWidget(
        TerminalWidget(
          buffer: buffer,
          repaint: ValueNotifier(0),
          onKey: (bytes) => received.add(bytes),
        ),
      );

      final focusFinder = find.byType(Focus);
      expect(focusFinder, findsAtLeastNWidgets(1));
    });
  });
}
