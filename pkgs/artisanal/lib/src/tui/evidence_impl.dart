import 'dart:convert';
import 'dart:io' as io;

import 'render_recorder.dart';
import 'terminal_native_frame.dart';
import 'terminal_render_inspector.dart';

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

/// Structured runtime evidence logging for diagnostic replayability.
///
/// Logs are opt-in JSONL entries emitted for runtime decisions
/// (for example, render-budget transitions).
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
  static bool _captureFrames = false;
  static io.File? _file;
  static final Stopwatch _clock = Stopwatch();
  static DateTime Function() _nowProvider = DateTime.now;

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
    close();
  }

  static void clearTestOverrides() {
    _testOverride = false;
    _testEnabled = null;
    _testCaptureFrames = null;
    _testPath = null;
    _testRunId = null;
    _testNowProvider = null;
    _resolved = false;
    close();
  }

  static bool get enabled {
    if (!_resolved) _resolveState();
    return _path != null;
  }

  static bool get captureFramesEnabled {
    if (!_resolved) _resolveState();
    return enabled && _captureFrames;
  }

  static void logDecision({
    required String decisionType,
    required String result,
    required Map<String, Object?> factors,
    String type = 'runtime.decision',
  }) {
    if (!enabled) return;
    final payload = <String, Object?>{
      'v': _schemaVersion,
      'type': type,
      'timestampUs': _clock.elapsedMicroseconds,
      'decisionType': decisionType,
      'result': result,
      'factors': factors,
    };
    if (_runId != null) payload['runId'] = _runId!;
    _write(payload);
  }

  static void logRenderFrame({
    required Object view,
    int? renderGeneration,
    String? degradationLevel,
    int? renderDurationUs,
    int? width,
    int? height,
    List<TerminalNativeSpanDelta>? nativeSpanDelta,
  }) {
    if (!captureFramesEnabled) return;
    final frame = TerminalRenderFrame.inspect(view);
    logDecision(
      decisionType: 'render_frame',
      result: 'captured',
      type: 'runtime.render',
      factors: <String, Object?>{
        if (renderGeneration != null) 'renderGeneration': renderGeneration,
        if (degradationLevel != null) 'degradationLevel': degradationLevel,
        if (renderDurationUs != null) 'renderDurationUs': renderDurationUs,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'lineCount': frame.lines.length,
        'content': frame.content,
        'plainText': frame.plainText,
        'lines': frame.lines.map((line) => <String, Object?>{
          'raw': line.raw,
          'statePrefix': line.statePrefix,
          'plainText': line.plainText,
          'visibleWidth': line.visibleWidth,
        }).toList(growable: false),
        if (nativeSpanDelta != null)
          'nativeSpanDelta': nativeSpanDelta.map((line) => <String, Object?>{
            'index': line.index,
            'spans': line.spans.map((span) => <String, Object?>{
              'lineIndex': span.lineIndex,
              'startColumn': span.startColumn,
              'endColumn': span.endColumn,
              'text': span.text,
              'hasDrawable': span.hasDrawable,
              'style': <String, Object?>{
                'attrs': span.style.attrs,
                'underline': span.style.underline.name,
                'packedKey': span.style.packedKey,
              },
              'link': <String, Object?>{
                'url': span.link.url,
                'params': span.link.params,
              },
            }).toList(growable: false),
          }).toList(growable: false),
      },
    );
  }

  static void logRenderCapture({
    required ProgramRenderCapture capture,
    String prefix = 'Render',
    int maxFrameLines = 3,
  }) {
    if (!captureFramesEnabled) return;
    logRenderCapturePayload(
      payload: capture.payload(prefix: prefix, maxFrameLines: maxFrameLines),
    );
  }

  static void logRenderCapturePayload({
    required ProgramRenderCapturePayload payload,
  }) {
    if (!captureFramesEnabled) return;
    logDecision(
      decisionType: 'render_capture',
      result: 'captured',
      type: 'runtime.render',
      factors: payload.toJson(),
    );
  }

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
    _file = null;
    _clock.stop();
    _clock.reset();
    _resolved = false;
  }

  static void _resolveState() {
    _nowProvider = _testNowProvider ?? DateTime.now;
    final flag = _resolveEnabledFlag();
    _path = flag ? _resolvePath() : null;
    _runId = _resolveRunId();
    _captureFrames = flag && _resolveCaptureFrames();
    _resolved = true;
    if (_path != null && !_clock.isRunning) _clock.start();
  }

  static bool _resolveEnabledFlag() {
    if (_testOverride) return _testEnabled ?? true;
    final env = io.Platform.environment;
    final flag = env[_flagEnv];
    return flag != null && _isEnabledFlag(flag);
  }

  static String? _resolvePath() {
    if (_testOverride) {
      return _testPath == null || _testPath!.trim().isEmpty
          ? _generateDateBasedPath()
          : _testPath;
    }
    final env = io.Platform.environment;
    final explicit = env[_pathEnv];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (!_resolveEnabledFlag()) return null;
    return _generateDateBasedPath();
  }

  static String? _resolveRunId() {
    if (_testOverride) return _testRunId;
    final env = io.Platform.environment;
    return env[_runIdEnv];
  }

  static bool _resolveCaptureFrames() {
    if (_testOverride) return _testCaptureFrames ?? false;
    final env = io.Platform.environment;
    final flag = env[_framesEnv];
    if (flag == null) return false;
    return _isEnabledFlag(flag);
  }

  static void _write(Map<String, Object?> payload) {
    final file = _file ?? _openFile();
    file.writeAsStringSync(
      '${jsonEncode(payload)}\n',
      mode: io.FileMode.append,
    );
  }

  static io.File _openFile() {
    final file = io.File(_path!);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    _file = file;
    return file;
  }

  static String _generateDateBasedPath() {
    final now = _nowProvider();
    final ts = '${now.year.toString().padLeft(4, '0')}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}'
        'T${now.hour.toString().padLeft(2, '0')}'
        '-${now.minute.toString().padLeft(2, '0')}'
        '-${now.second.toString().padLeft(2, '0')}';
    final dir = io.Directory('evidence');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return 'evidence/artisanal-${now.microsecond}-$ts.jsonl';
  }

  static bool _isEnabledFlag(String value) {
    final normalized = value.toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
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
