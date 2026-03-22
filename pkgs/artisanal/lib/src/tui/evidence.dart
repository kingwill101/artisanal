/// Structured runtime evidence logging for diagnostic replayability.
///
/// Evidence logs are opt-in JSONL entries emitted for runtime decisions
/// (for example, render-budget transitions).  The format is stable and parseable
/// with [tryParseLine].
library;

import 'dart:convert';
import 'dart:io' as io;

/// A decoded evidence event line.
final class TuiEvidenceRecord {
  /// Creates a typed evidence record.
  const TuiEvidenceRecord({
    required this.version,
    required this.type,
    required this.timestampUs,
    required this.decisionType,
    required this.result,
    required this.factors,
    this.runId,
  });

  /// Evidence schema version.
  final int version;

  /// Event category/type.
  final String type;

  /// Monotonic timestamp in microseconds.
  final int timestampUs;

  /// Decision family (for example, `render_budget`).
  final String decisionType;

  /// Result label (for example, `degrade`, `recover`, `hold`, `disabled`).
  final String result;

  /// Decision factor ledger used by the runtime.
  final Map<String, Object?> factors;

  /// Optional run identifier for correlation.
  final String? runId;
}

/// Optional evidence logger for structured runtime diagnostics.
///
/// Logging is enabled when `ARTISANAL_TUI_EVIDENCE` is set, or when
/// [configureForTest] explicitly enables it.
final class TuiEvidence {
  static const _flagEnv = 'ARTISANAL_TUI_EVIDENCE';
  static const _pathEnv = 'ARTISANAL_TUI_EVIDENCE_PATH';
  static const _runIdEnv = 'ARTISANAL_TUI_EVIDENCE_RUN_ID';
  static const _schemaVersion = 1;

  static bool? _testEnabled;
  static String? _testPath;
  static String? _testRunId;
  static bool _testOverride = false;
  static bool _resolved = false;

  static String? _path;
  static String? _runId;
  static io.File? _file;
  static final Stopwatch _clock = Stopwatch();

  /// Enable/disable evidence logging for tests regardless of process env.
  ///
  /// If [enabled] is `null`, the logger is enabled by default for the test.
  static void configureForTest({
    bool? enabled,
    String? path,
    String? runId,
    bool clear = false,
  }) {
    _testOverride = true;
    _testEnabled = clear ? false : enabled;
    _testPath = clear ? null : path;
    _testRunId = clear ? null : runId;
    _resolved = false;
    close();
  }

  /// Clears test overrides and returns to env-based behavior.
  static void clearTestOverrides() {
    _testOverride = false;
    _testEnabled = null;
    _testPath = null;
    _testRunId = null;
    _resolved = false;
    close();
  }

  /// Whether evidence logging is enabled.
  static bool get enabled {
    if (!_resolved) {
      _resolveState();
    }
    return _path != null;
  }

  /// Parses one strict JSONL evidence line.
  static TuiEvidenceRecord? tryParseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    final decoded = _decodeJsonObject(trimmed);
    if (decoded == null) return null;

    final version = decoded['v'];
    if (version is! int && version is! num) return null;
    if (version.toInt() != _schemaVersion) return null;

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

  /// Emits one decision event.
  ///
  /// The shape is:
  /// `{"v":1,"type":"runtime.decision","timestampUs":123,"decisionType":"...","result":"...","factors":{...}}`
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
    if (_runId != null) {
      payload['runId'] = _runId!;
    }
    _write(payload);
  }

  /// Closes the evidence file and drops in-flight buffers.
  static void close() {
    _file = null;
    _clock.stop();
    _clock.reset();
    _resolved = false;
  }

  static void _resolveState() {
    final flag = _resolveEnabledFlag();
    _path = flag ? _resolvePath() : null;
    _runId = _resolveRunId();
    _resolved = true;
    if (_path != null && !_clock.isRunning) {
      _clock.start();
    }
  }

  static bool _resolveEnabledFlag() {
    if (_testOverride) {
      if (_testEnabled == null) return true;
      return _testEnabled!;
    }
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

  static void _write(Map<String, Object?> payload) {
    final file = _file ?? _openFile();
    file.writeAsStringSync(
      '${jsonEncode(payload)}\n',
      mode: io.FileMode.append,
    );
  }

  static io.File _openFile() {
    final file = io.File(_path!);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    _file = file;
    return file;
  }

  static String _generateDateBasedPath() {
    final now = DateTime.now();
    final ts =
        '${now.year.toString().padLeft(4, '0')}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}'
        'T${now.hour.toString().padLeft(2, '0')}'
        '-${now.minute.toString().padLeft(2, '0')}'
        '-${now.second.toString().padLeft(2, '0')}';
    final dir = io.Directory('evidence');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return 'evidence/artisanal-${now.microsecond}-$ts.jsonl';
  }

  static Map<String, dynamic>? _decodeJsonObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  static bool _isEnabledFlag(String value) {
    final normalized = value.toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
}
