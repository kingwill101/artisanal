/// Stub for `report_probe.dart` when `dart:io` is not available.
library;

final class TerminalReportSnapshot {
  const TerminalReportSnapshot({
    required this.rawResponse,
    this.terminalVersion,
    this.primaryAttributes = const <int>[],
    this.secondaryAttributes = const <int>[],
    this.windowPixelWidth,
    this.windowPixelHeight,
    this.cellPixelWidth,
    this.cellPixelHeight,
  });

  final String rawResponse;
  final String? terminalVersion;
  final List<int> primaryAttributes;
  final List<int> secondaryAttributes;
  final int? windowPixelWidth;
  final int? windowPixelHeight;
  final int? cellPixelWidth;
  final int? cellPixelHeight;

  bool get hasSixel => primaryAttributes.contains(4);
}

final class TerminalReportProbe {
  static Future<TerminalReportSnapshot?> probe({
    Duration idleTimeout = const Duration(milliseconds: 120),
    Duration totalTimeout = const Duration(milliseconds: 600),
    String ttyPath = '/dev/tty',
  }) async => null;
}
