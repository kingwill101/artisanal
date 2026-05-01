/// Artifact manifest contracts for widget harness evidence bundles.
library;

/// Artifact classes emitted by widget harness and gauntlet runs.
enum HarnessArtifactClass {
  runMeta,
  evidenceLedger,
  frameSnapshot,
  stormLog,
  flickerReport,
  gauntletReport,
  captureLog,
  replayScript,
  summary,
}

/// Retention class for an artifact.
enum HarnessArtifactRetention { ephemeral, session, release, permanent }

/// Metadata helpers for [HarnessArtifactClass].
extension HarnessArtifactClassMetadata on HarnessArtifactClass {
  /// Canonical filename pattern.
  String get filenamePattern {
    return switch (this) {
      HarnessArtifactClass.runMeta => 'run_meta.json',
      HarnessArtifactClass.evidenceLedger => 'evidence_ledger.jsonl',
      HarnessArtifactClass.frameSnapshot => 'frame_{index:04}.json',
      HarnessArtifactClass.stormLog => 'storm_{profile}.json',
      HarnessArtifactClass.flickerReport => 'flicker_report.json',
      HarnessArtifactClass.gauntletReport => 'gauntlet_report.json',
      HarnessArtifactClass.captureLog => '{source}.log',
      HarnessArtifactClass.replayScript => 'replay.dart',
      HarnessArtifactClass.summary => 'summary.txt',
    };
  }

  /// Recommended maximum size in bytes.
  int get maxSizeBytes {
    return switch (this) {
      HarnessArtifactClass.runMeta => 64 * 1024,
      HarnessArtifactClass.evidenceLedger => 1024 * 1024,
      HarnessArtifactClass.frameSnapshot => 256 * 1024,
      HarnessArtifactClass.stormLog => 512 * 1024,
      HarnessArtifactClass.flickerReport => 256 * 1024,
      HarnessArtifactClass.gauntletReport => 512 * 1024,
      HarnessArtifactClass.captureLog => 10 * 1024 * 1024,
      HarnessArtifactClass.replayScript => 8 * 1024,
      HarnessArtifactClass.summary => 64 * 1024,
    };
  }

  /// Suggested retention class.
  HarnessArtifactRetention get retention {
    return switch (this) {
      HarnessArtifactClass.runMeta => HarnessArtifactRetention.release,
      HarnessArtifactClass.evidenceLedger => HarnessArtifactRetention.release,
      HarnessArtifactClass.frameSnapshot => HarnessArtifactRetention.session,
      HarnessArtifactClass.stormLog => HarnessArtifactRetention.session,
      HarnessArtifactClass.flickerReport => HarnessArtifactRetention.release,
      HarnessArtifactClass.gauntletReport => HarnessArtifactRetention.release,
      HarnessArtifactClass.captureLog => HarnessArtifactRetention.session,
      HarnessArtifactClass.replayScript => HarnessArtifactRetention.permanent,
      HarnessArtifactClass.summary => HarnessArtifactRetention.release,
    };
  }

  /// Fields required in the artifact manifest entry.
  List<String> get requiredFields {
    return switch (this) {
      HarnessArtifactClass.runMeta => <String>[
        'runId',
        'createdAt',
        'status',
        'runtimeLane',
      ],
      HarnessArtifactClass.evidenceLedger => <String>[
        'runId',
        'entryCount',
        'schemaVersion',
      ],
      HarnessArtifactClass.frameSnapshot => <String>[
        'runId',
        'frameIndex',
        'checksum',
        'viewport',
      ],
      HarnessArtifactClass.stormLog => <String>[
        'runId',
        'profile',
        'seed',
        'stepCount',
        'passed',
      ],
      HarnessArtifactClass.flickerReport => <String>[
        'runId',
        'eventCount',
        'isFlickerFree',
      ],
      HarnessArtifactClass.gauntletReport => <String>[
        'runId',
        'gateCount',
        'passed',
      ],
      HarnessArtifactClass.captureLog => <String>[
        'runId',
        'source',
        'byteCount',
      ],
      HarnessArtifactClass.replayScript => <String>[
        'runId',
        'scenario',
        'seed',
        'viewport',
      ],
      HarnessArtifactClass.summary => <String>['runId', 'createdAt'],
    };
  }
}

/// Suggested retention days for [HarnessArtifactRetention].
extension HarnessArtifactRetentionMetadata on HarnessArtifactRetention {
  /// Suggested number of retention days.
  int get retentionDays {
    return switch (this) {
      HarnessArtifactRetention.ephemeral => 0,
      HarnessArtifactRetention.session => 7,
      HarnessArtifactRetention.release => 90,
      HarnessArtifactRetention.permanent => 0x7FFFFFFF,
    };
  }
}

const _redactedFieldFragments = <String>[
  'hostname',
  'home',
  'user',
  'username',
  'workingdir',
  'working_dir',
  'abspath',
  'abs_path',
  'env',
  'apikey',
  'api_key',
  'token',
  'secret',
  'password',
  'cookie',
];

/// Returns true when [fieldName] should be redacted before sharing artifacts.
bool shouldRedactHarnessField(String fieldName) {
  final normalized = fieldName.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]'),
    '',
  );
  return _redactedFieldFragments.any(normalized.contains);
}

/// One artifact entry in a harness manifest.
final class HarnessArtifactEntry {
  /// Creates an artifact manifest entry.
  const HarnessArtifactEntry({
    required this.artifactClass,
    required this.path,
    required this.sizeBytes,
    required this.fields,
  });

  /// Artifact class.
  final HarnessArtifactClass artifactClass;

  /// Relative path within a run bundle.
  final String path;

  /// Artifact size in bytes.
  final int sizeBytes;

  /// Field names present in the artifact payload.
  final Set<String> fields;

  /// Validates this entry against its artifact-class contract.
  HarnessArtifactValidation validate() {
    final missing = artifactClass.requiredFields
        .where((field) => !fields.contains(field))
        .toList(growable: false);
    return HarnessArtifactValidation(
      artifactClass: artifactClass,
      path: path,
      missingFields: missing,
      oversize: sizeBytes > artifactClass.maxSizeBytes,
    );
  }

  /// Converts this entry into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': artifactClass.name,
      'path': path,
      'sizeBytes': sizeBytes,
      'maxSizeBytes': artifactClass.maxSizeBytes,
      'retention': artifactClass.retention.name,
      'retentionDays': artifactClass.retention.retentionDays,
      'fields': fields.toList()..sort(),
    };
  }
}

/// Validation result for one artifact entry.
final class HarnessArtifactValidation {
  /// Creates an artifact validation result.
  const HarnessArtifactValidation({
    required this.artifactClass,
    required this.path,
    required this.missingFields,
    required this.oversize,
  });

  /// Artifact class.
  final HarnessArtifactClass artifactClass;

  /// Relative path within a run bundle.
  final String path;

  /// Required fields missing from the artifact payload.
  final List<String> missingFields;

  /// Whether [path] exceeds the class size recommendation.
  final bool oversize;

  /// Whether this entry passes validation.
  bool get passes => missingFields.isEmpty && !oversize;

  /// Converts this result into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'class': artifactClass.name,
      'path': path,
      'missingFields': missingFields,
      'oversize': oversize,
      'passes': passes,
    };
  }
}

/// Manifest for a reproducible harness run bundle.
final class HarnessArtifactManifest {
  /// Creates an artifact manifest.
  const HarnessArtifactManifest({
    required this.runId,
    required this.createdAt,
    required this.entries,
  });

  /// Run identifier used to correlate artifact payloads.
  final String runId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Artifact entries in this bundle.
  final List<HarnessArtifactEntry> entries;

  /// Validates all entries and returns only failures.
  List<HarnessArtifactValidation> validate() {
    return entries
        .map((entry) => entry.validate())
        .where((result) => !result.passes)
        .toList(growable: false);
  }

  /// Converts this manifest into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runId': runId,
      'createdAt': createdAt.toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'validationFailures': validate()
          .map((result) => result.toJson())
          .toList(growable: false),
    };
  }
}
