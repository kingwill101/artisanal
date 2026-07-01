// ignore_for_file: unused_field

/// Web stub for `evidence_impl.dart` — no-op evidence logger.
library;

import 'dart:convert';

/// A decoded evidence event line.
final class TuiEvidenceRecord {
  const TuiEvidenceRecord({
    required this.version,
    required this.type,
    required this.timestampUs,
    required this.decisionType,
    required this.result,
    required this.factors,
    this.runId,
  });

  final int version;
  final String type;
  final int timestampUs;
  final String decisionType;
  final String result;
  final Map<String, Object?> factors;
  final String? runId;
}

/// Structured runtime evidence logging (web stub — no-op).
final class TuiEvidence {
  static const _flagEnv = 'ARTISANAL_TUI_EVIDENCE';
  static const _pathEnv = 'ARTISANAL_TUI_EVIDENCE_PATH';
  static const _runIdEnv = 'ARTISANAL_TUI_EVIDENCE_RUN_ID';
  static const _framesEnv = 'ARTISANAL_TUI_EVIDENCE_FRAMES';
  static const _schemaVersion = 1;

  static bool? _testEnabled;
  static bool? _testCaptureFrames;
  static String? _testPath;
  static String? _testRunId;
  static DateTime Function()? _testNowProvider;
  static bool _testOverride = false;
  static bool _resolved = false;

  static String? _path;
  static String? _runId;
  static final bool _captureFrames = false;

  static void configureForTest({
    bool? enabled,
    bool captureFrames = false,
    String? path,
    String? runId,
    DateTime Function()? nowProvider,
    bool clear = false,
  }) {
    _testOverride = true;
    _testEnabled = clear ? false : enabled;
    _testCaptureFrames = clear ? false : captureFrames;
    _testPath = clear ? null : path;
    _testRunId = clear ? null : runId;
    _testNowProvider = clear ? null : nowProvider;
    _resolved = false;
  }

  static void clearTestOverrides() {
    _testOverride = false;
    _testEnabled = null;
    _testCaptureFrames = null;
    _testPath = null;
    _testRunId = null;
    _testNowProvider = null;
    _resolved = false;
  }

  static bool get enabled => false;
  static bool get captureFramesEnabled => false;

  static void logDecision({
    required String decisionType,
    required String result,
    required Map<String, Object?> factors,
    String type = 'runtime.decision',
  }) {}

  static void logRenderFrame({
    required Object view,
    int? renderGeneration,
    String? degradationLevel,
    int? renderDurationUs,
    int? width,
    int? height,
    Object? nativeSpanDelta,
  }) {}

  static void logRenderCapture({
    required Object capture,
    String prefix = 'Render',
    int maxFrameLines = 3,
  }) {}

  static void logRenderCapturePayload({required Object payload}) {}

  static TuiEvidenceRecord? tryParseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    final decoded = _decodeJsonObject(trimmed);
    if (decoded == null) return null;

    final version = decoded['v'];
    if (version is! int && version is! num) return null;
    if (version.toInt() != 1) return null;

    final type = decoded['type'];
    final decisionType = decoded['decisionType'];
    final result = decoded['result'];
    final timestampUs = decoded['timestampUs'];
    if (type is! String || type.isEmpty) return null;
    if (decisionType is! String || decisionType.isEmpty) return null;
    if (result is! String || result.isEmpty) return null;
    if (timestampUs is! int && timestampUs is! num) return null;

    final rawFactors = decoded['factors'];
    if (rawFactors is! Map) return null;
    final factors = <String, Object?>{};
    for (final entry in rawFactors.entries) {
      final key = entry.key;
      if (key is String) {
        factors[key] = entry.value;
      }
    }

    return TuiEvidenceRecord(
      version: version.toInt(),
      type: type,
      timestampUs: timestampUs.toInt(),
      decisionType: decisionType,
      result: result,
      factors: factors,
      runId: decoded['runId'] as String?,
    );
  }

  static void close() {
    _resolved = false;
  }
}

Map<String, dynamic>? _decodeJsonObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }
}
