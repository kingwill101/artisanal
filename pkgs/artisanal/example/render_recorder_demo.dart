import 'package:artisanal/tui.dart';

void main() {
  final capture = ProgramRenderCapture();

  void recordFrame(int generation, String view, Duration renderDuration) {
    capture.onRendered(
      renderGeneration: generation,
      view: view,
      degradationLevel: DegradationLevel.full,
      renderDuration: renderDuration,
      width: 24,
      height: 4,
    );
  }

  recordFrame(
    1,
    'Status: booting\n'
    'Lane: [####------]\n'
    'Overlay: idle',
    const Duration(milliseconds: 4),
  );
  recordFrame(
    2,
    'Status: ready\n'
    'Lane: [########--]\n'
    'Overlay: monitor attached',
    const Duration(milliseconds: 6),
  );

  final snapshot = capture.lastSnapshot!;
  final report = capture.report(prefix: 'Demo');
  final lastSummary = capture.lastSnapshotSummary();
  final payload = capture.payload(prefix: 'Demo');

  print('Last render generation: ${snapshot.renderGeneration}');
  print('Parsed lines:');
  for (final line in snapshot.lines) {
    print('  $line');
  }
  print('');
  print('Structured report:');
  print('  last generation: ${report.lastRenderGeneration}');
  print('  frame lines: ${report.frameLines.length}');
  print('  changed cells: ${report.lastChangeSummary?.changedCellCount ?? 0}');
  print('  last snapshot summary: ${lastSummary?.toJson()}');
  print('  as json: ${report.toJson()}');
  print('  payload json: ${payload.toJson()}');
  print('  capture json: ${capture.toJson(prefix: 'Demo')}');
  print('');
  print('Capture report:');
  for (final line in report.toLines()) {
    print('  $line');
  }
}
