/// ANSI output flicker and tearing analysis for widget harnesses.
library;

import 'widget_tester.dart';

const _syncStart = '\x1b[?2026h';
const _syncEnd = '\x1b[?2026l';

/// Severity for a flicker-analysis event.
enum FlickerSeverity { info, warning, error }

/// Flicker-analysis event families.
enum FlickerEventType {
  frameStart,
  frameEnd,
  syncGap,
  partialClear,
  incompleteFrame,
  interleavedWrites,
  suspiciousCursorMove,
  analysisComplete,
}

/// One event detected while scanning terminal output.
final class FlickerEvent {
  /// Creates a flicker-analysis event.
  const FlickerEvent({
    required this.type,
    required this.severity,
    required this.message,
    required this.byteOffset,
    required this.frameId,
  });

  /// Event family.
  final FlickerEventType type;

  /// Event severity.
  final FlickerSeverity severity;

  /// Human-readable event detail.
  final String message;

  /// Character offset in the analyzed string.
  final int byteOffset;

  /// Active synchronized-frame id when the event was detected.
  final int frameId;

  /// Converts this event into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'byteOffset': byteOffset,
      'frameId': frameId,
    };
  }
}

/// Aggregate counts from a flicker scan.
final class FlickerStats {
  /// Creates flicker-analysis statistics.
  const FlickerStats({
    required this.totalBytes,
    required this.synchronizedBytes,
    required this.unsynchronizedBytes,
    required this.frameStarts,
    required this.frameEnds,
    required this.infoCount,
    required this.warningCount,
    required this.errorCount,
  });

  /// Total scanned string length.
  final int totalBytes;

  /// Visible bytes observed inside synchronized output brackets.
  final int synchronizedBytes;

  /// Visible bytes observed outside synchronized output brackets.
  final int unsynchronizedBytes;

  /// Number of synchronized-output start markers.
  final int frameStarts;

  /// Number of synchronized-output end markers.
  final int frameEnds;

  /// Number of informational events.
  final int infoCount;

  /// Number of warning events.
  final int warningCount;

  /// Number of error events.
  final int errorCount;

  /// Fraction of visible output that was synchronized.
  double get syncCoverage {
    final visibleBytes = synchronizedBytes + unsynchronizedBytes;
    if (visibleBytes == 0) return 1.0;
    return synchronizedBytes / visibleBytes;
  }

  /// Converts these stats into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'totalBytes': totalBytes,
      'synchronizedBytes': synchronizedBytes,
      'unsynchronizedBytes': unsynchronizedBytes,
      'frameStarts': frameStarts,
      'frameEnds': frameEnds,
      'infoCount': infoCount,
      'warningCount': warningCount,
      'errorCount': errorCount,
      'syncCoverage': syncCoverage,
    };
  }
}

/// Result from scanning terminal output for flicker-prone patterns.
final class FlickerAnalysis {
  /// Creates a flicker analysis result.
  const FlickerAnalysis({
    required this.runId,
    required this.requireSynchronizedOutput,
    required this.events,
    required this.stats,
  });

  /// Correlation id for reports.
  final String runId;

  /// Whether visible output outside sync brackets was treated as an error.
  final bool requireSynchronizedOutput;

  /// Detected events in scan order.
  final List<FlickerEvent> events;

  /// Aggregate scan statistics.
  final FlickerStats stats;

  /// True when the analyzer found no error-severity events.
  bool get isFlickerFree => stats.errorCount == 0;

  /// Throws [FlickerFailure] when [isFlickerFree] is false.
  void assertFlickerFree() {
    if (isFlickerFree) return;
    throw FlickerFailure(this);
  }

  /// Converts this analysis into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runId': runId,
      'requireSynchronizedOutput': requireSynchronizedOutput,
      'isFlickerFree': isFlickerFree,
      'stats': stats.toJson(),
      'events': events.map((event) => event.toJson()).toList(growable: false),
    };
  }
}

/// Exception wrapper for failed flicker analyses.
final class FlickerFailure implements Exception {
  /// Creates a failure wrapper for [analysis].
  const FlickerFailure(this.analysis);

  /// Failed analysis.
  final FlickerAnalysis analysis;

  @override
  String toString() {
    final errors = analysis.events.where(
      (event) => event.severity == FlickerSeverity.error,
    );
    final detail = errors
        .take(5)
        .map((event) => '${event.type.name}@${event.byteOffset}')
        .join(', ');
    return 'Flicker analysis failed for ${analysis.runId}: $detail';
  }
}

/// Analyzer for synchronized-output gaps, partial clears, and broken frames.
final class FlickerAnalyzer {
  const FlickerAnalyzer._();

  /// Scans [output] and returns a structured analysis.
  static FlickerAnalysis analyze(
    String output, {
    String runId = 'widget-test',
    bool requireSynchronizedOutput = false,
  }) {
    final events = <FlickerEvent>[];
    var inSync = false;
    var frameId = 0;
    var frameStarts = 0;
    var frameEnds = 0;
    var synchronizedBytes = 0;
    var unsynchronizedBytes = 0;
    var emittedSyncGap = false;

    void add(
      FlickerEventType type,
      FlickerSeverity severity,
      String message,
      int offset,
    ) {
      events.add(
        FlickerEvent(
          type: type,
          severity: severity,
          message: message,
          byteOffset: offset,
          frameId: frameId,
        ),
      );
    }

    var index = 0;
    while (index < output.length) {
      if (output.startsWith(_syncStart, index)) {
        if (inSync) {
          add(
            FlickerEventType.interleavedWrites,
            FlickerSeverity.error,
            'synchronized output started before prior frame ended',
            index,
          );
        }
        inSync = true;
        frameId++;
        frameStarts++;
        add(
          FlickerEventType.frameStart,
          FlickerSeverity.info,
          'synchronized frame started',
          index,
        );
        index += _syncStart.length;
        continue;
      }

      if (output.startsWith(_syncEnd, index)) {
        if (!inSync) {
          add(
            FlickerEventType.syncGap,
            requireSynchronizedOutput
                ? FlickerSeverity.error
                : FlickerSeverity.warning,
            'synchronized frame ended without a matching start',
            index,
          );
        } else {
          inSync = false;
          frameEnds++;
          add(
            FlickerEventType.frameEnd,
            FlickerSeverity.info,
            'synchronized frame ended',
            index,
          );
        }
        index += _syncEnd.length;
        continue;
      }

      final csi = _readCsi(output, index);
      if (csi != null) {
        if (csi.isErase) {
          add(
            FlickerEventType.partialClear,
            FlickerSeverity.warning,
            'erase command ${csi.sequence} may expose blank cells mid-frame',
            index,
          );
        } else if (csi.isCursorMove && !inSync && requireSynchronizedOutput) {
          add(
            FlickerEventType.suspiciousCursorMove,
            FlickerSeverity.warning,
            'cursor movement outside synchronized output',
            index,
          );
        }
        index += csi.sequence.length;
        continue;
      }

      final codeUnit = output.codeUnitAt(index);
      if (_isVisibleCodeUnit(codeUnit)) {
        if (inSync) {
          synchronizedBytes++;
        } else {
          unsynchronizedBytes++;
          if (requireSynchronizedOutput && !emittedSyncGap) {
            emittedSyncGap = true;
            add(
              FlickerEventType.syncGap,
              FlickerSeverity.error,
              'visible output occurred outside synchronized output brackets',
              index,
            );
          }
        }
      }
      index++;
    }

    if (inSync) {
      add(
        FlickerEventType.incompleteFrame,
        FlickerSeverity.error,
        'synchronized output started but never ended',
        output.length,
      );
    }

    add(
      FlickerEventType.analysisComplete,
      FlickerSeverity.info,
      'analysis completed',
      output.length,
    );

    final infoCount = events
        .where((event) => event.severity == FlickerSeverity.info)
        .length;
    final warningCount = events
        .where((event) => event.severity == FlickerSeverity.warning)
        .length;
    final errorCount = events
        .where((event) => event.severity == FlickerSeverity.error)
        .length;

    return FlickerAnalysis(
      runId: runId,
      requireSynchronizedOutput: requireSynchronizedOutput,
      events: List<FlickerEvent>.unmodifiable(events),
      stats: FlickerStats(
        totalBytes: output.length,
        synchronizedBytes: synchronizedBytes,
        unsynchronizedBytes: unsynchronizedBytes,
        frameStarts: frameStarts,
        frameEnds: frameEnds,
        infoCount: infoCount,
        warningCount: warningCount,
        errorCount: errorCount,
      ),
    );
  }
}

/// Convenience extension for analyzing captured widget-test terminal output.
extension WidgetTesterFlickerAnalysis on WidgetTester {
  /// Runs [FlickerAnalyzer] over the tester's raw terminal writes.
  FlickerAnalysis analyzeFlicker({
    String runId = 'widget-test',
    bool requireSynchronizedOutput = false,
  }) {
    return FlickerAnalyzer.analyze(
      terminalOutput,
      runId: runId,
      requireSynchronizedOutput: requireSynchronizedOutput,
    );
  }
}

final class _CsiSequence {
  const _CsiSequence(this.sequence, this.finalByte);

  final String sequence;
  final int finalByte;

  bool get isErase => finalByte == 0x4A || finalByte == 0x4B; // J or K.

  bool get isCursorMove {
    return switch (finalByte) {
      0x41 || // A
      0x42 || // B
      0x43 || // C
      0x44 || // D
      0x45 || // E
      0x46 || // F
      0x47 || // G
      0x48 || // H
      0x66 => true, // f
      _ => false,
    };
  }
}

_CsiSequence? _readCsi(String output, int index) {
  if (index + 2 >= output.length) return null;
  if (output.codeUnitAt(index) != 0x1B ||
      output.codeUnitAt(index + 1) != 0x5B) {
    return null;
  }

  var cursor = index + 2;
  while (cursor < output.length) {
    final byte = output.codeUnitAt(cursor);
    if (byte >= 0x40 && byte <= 0x7E) {
      return _CsiSequence(output.substring(index, cursor + 1), byte);
    }
    cursor++;
  }
  return null;
}

bool _isVisibleCodeUnit(int codeUnit) {
  return codeUnit >= 0x20 && codeUnit != 0x7F;
}
