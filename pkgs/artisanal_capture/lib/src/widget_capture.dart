import 'dart:async';

import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';

import 'capture.dart';

/// Captures [widget] after layout and optional deterministic interactions.
///
/// The widget runs through [WidgetTester]'s real widget app and TEA runtime;
/// its styled view is then drawn into UV cells. This captures the view rather
/// than terminal transport bytes. Use [TerminalCapture.fromBuffer] when a
/// native renderer buffer is already available.
///
/// Use [arrange] to send keys, change selection, or advance a manual clock.
/// Async data should be awaited explicitly there rather than relying on sleeps.
/// The tester is always disposed, including when setup or capture fails.
///
/// {@category Capture}
Future<TerminalCapture> captureWidget(
  Widget widget, {
  int columns = 80,
  int rows = 24,
  FutureOr<void> Function(WidgetTester tester)? arrange,
}) async {
  if (columns <= 0 ||
      rows <= 0 ||
      columns > terminalCaptureMaxColumns ||
      rows > terminalCaptureMaxRows ||
      columns * rows > terminalCaptureMaxCells) {
    throw ArgumentError(
      'Widget capture dimensions must be positive and bounded.',
    );
  }
  final tester = WidgetTester(screenWidth: columns, screenHeight: rows);
  try {
    await tester.pumpWidget(widget, width: columns, height: rows);
    if (arrange != null) await arrange(tester);
    tester.pump();
    return TerminalCapture.fromAnsi(tester.view, columns: columns, rows: rows);
  } finally {
    await tester.dispose();
  }
}
