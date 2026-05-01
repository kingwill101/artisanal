/// Composable widget harness gauntlet.
library;

import 'dart:convert';

import '../core/widget.dart';
import 'flicker_analyzer.dart';
import 'harness_artifacts.dart';
import 'widget_storm.dart';
import 'widget_tester.dart';

/// Configuration for [WidgetGauntlet].
final class WidgetGauntletConfig {
  /// Creates a gauntlet configuration.
  const WidgetGauntletConfig({
    this.runId = 'widget-gauntlet',
    this.runtimeLane = 'widget-test',
    this.stormProfiles = const <WidgetStormProfile>[],
    this.analyzeFlicker = false,
    this.requireSynchronizedOutput = false,
    this.nowProvider,
  });

  /// Run identifier used in reports and artifact manifests.
  final String runId;

  /// Runtime lane label for reports.
  final String runtimeLane;

  /// Storm profiles to run after the widget is mounted.
  final List<WidgetStormProfile> stormProfiles;

  /// Whether to analyze raw terminal writes after the run.
  final bool analyzeFlicker;

  /// Whether visible output outside synchronized brackets is an error.
  final bool requireSynchronizedOutput;

  /// Clock seam for deterministic tests.
  final DateTime Function()? nowProvider;

  DateTime _now() => nowProvider?.call() ?? DateTime.now();
}

/// Result from one [WidgetGauntlet] run.
final class WidgetGauntletResult {
  /// Creates a gauntlet result.
  const WidgetGauntletResult({
    required this.config,
    required this.startedAt,
    required this.stormResults,
    required this.manifest,
    this.flickerAnalysis,
  });

  /// Configuration used for the run.
  final WidgetGauntletConfig config;

  /// Run start timestamp.
  final DateTime startedAt;

  /// Storm results in execution order.
  final List<WidgetStormResult> stormResults;

  /// Optional flicker analysis.
  final FlickerAnalysis? flickerAnalysis;

  /// In-memory artifact manifest for the run.
  final HarnessArtifactManifest manifest;

  /// Manifest validation failures.
  List<HarnessArtifactValidation> get manifestFailures => manifest.validate();

  /// Whether every gate passed.
  bool get passed {
    final stormsPassed = stormResults.every((result) => result.passed);
    final flickerPassed = flickerAnalysis?.isFlickerFree ?? true;
    return stormsPassed && flickerPassed && manifestFailures.isEmpty;
  }

  /// Human-readable failure summaries.
  List<String> get failureSummaries {
    final failures = <String>[];
    for (final result in stormResults) {
      if (!result.passed) {
        failures.add(
          'storm ${result.profile.name} failed at ${result.failedStep}: '
          '${result.error}',
        );
      }
    }
    final flicker = flickerAnalysis;
    if (flicker != null && !flicker.isFlickerFree) {
      failures.add(
        'flicker analysis found ${flicker.stats.errorCount} error(s)',
      );
    }
    for (final failure in manifestFailures) {
      failures.add(
        'artifact ${failure.path} failed manifest validation: '
        'missing=${failure.missingFields}, oversize=${failure.oversize}',
      );
    }
    return failures;
  }

  /// Compact text summary lines.
  List<String> summaryLines() {
    return <String>[
      'WidgetGauntlet ${config.runId}: ${passed ? 'passed' : 'failed'}',
      'storms: ${stormResults.length}',
      if (flickerAnalysis != null)
        'flicker: ${flickerAnalysis!.isFlickerFree ? 'clean' : 'errors'} '
            'coverage=${flickerAnalysis!.stats.syncCoverage.toStringAsFixed(2)}',
      'artifacts: ${manifest.entries.length}',
      ...failureSummaries,
    ];
  }

  /// Converts this result into a serialization-friendly map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runId': config.runId,
      'runtimeLane': config.runtimeLane,
      'startedAt': startedAt.toIso8601String(),
      'passed': passed,
      'storms': stormResults
          .map((result) => result.toJson())
          .toList(growable: false),
      'flickerAnalysis': flickerAnalysis?.toJson(),
      'manifest': manifest.toJson(),
      'failures': failureSummaries,
    };
  }
}

/// Runs named storm, flicker, and artifact-manifest checks for a widget.
final class WidgetGauntlet {
  /// Creates a widget gauntlet.
  const WidgetGauntlet({this.config = const WidgetGauntletConfig()});

  /// Gauntlet configuration.
  final WidgetGauntletConfig config;

  /// Mounts [widget], runs configured gates, and returns the structured result.
  Future<WidgetGauntletResult> run({
    required WidgetTester tester,
    required Widget widget,
    int? width,
    int? height,
  }) async {
    final startedAt = config._now();
    await tester.pumpWidget(widget, width: width, height: height);

    final stormResults = <WidgetStormResult>[];
    for (final profile in config.stormProfiles) {
      stormResults.add(tester.runStorm(profile));
    }

    final flicker = config.analyzeFlicker
        ? tester.analyzeFlicker(
            runId: config.runId,
            requireSynchronizedOutput: config.requireSynchronizedOutput,
          )
        : null;

    final manifest = _buildManifest(
      startedAt: startedAt,
      stormResults: stormResults,
      flickerAnalysis: flicker,
    );

    return WidgetGauntletResult(
      config: config,
      startedAt: startedAt,
      stormResults: List<WidgetStormResult>.unmodifiable(stormResults),
      flickerAnalysis: flicker,
      manifest: manifest,
    );
  }

  HarnessArtifactManifest _buildManifest({
    required DateTime startedAt,
    required List<WidgetStormResult> stormResults,
    required FlickerAnalysis? flickerAnalysis,
  }) {
    final entries = <HarnessArtifactEntry>[];

    entries.add(
      _entry(
        HarnessArtifactClass.runMeta,
        HarnessArtifactClass.runMeta.filenamePattern,
        <String, Object?>{
          'runId': config.runId,
          'createdAt': startedAt.toIso8601String(),
          'status': 'completed',
          'runtimeLane': config.runtimeLane,
        },
      ),
    );

    for (final result in stormResults) {
      entries.add(
        _entry(
          HarnessArtifactClass.stormLog,
          'storm_${result.profile.name}.json',
          <String, Object?>{
            'runId': config.runId,
            'profile': result.profile.name,
            'seed': result.profile.seed,
            'stepCount': result.history.length,
            'passed': result.passed,
            'result': result.toJson(),
          },
        ),
      );
    }

    if (flickerAnalysis != null) {
      entries.add(
        _entry(
          HarnessArtifactClass.flickerReport,
          HarnessArtifactClass.flickerReport.filenamePattern,
          <String, Object?>{
            'runId': config.runId,
            'eventCount': flickerAnalysis.events.length,
            'isFlickerFree': flickerAnalysis.isFlickerFree,
            'analysis': flickerAnalysis.toJson(),
          },
        ),
      );
    }

    entries.add(
      _entry(
        HarnessArtifactClass.gauntletReport,
        HarnessArtifactClass.gauntletReport.filenamePattern,
        <String, Object?>{
          'runId': config.runId,
          'gateCount': stormResults.length + (flickerAnalysis == null ? 0 : 1),
          'passed':
              stormResults.every((result) => result.passed) &&
              (flickerAnalysis?.isFlickerFree ?? true),
        },
      ),
    );

    entries.add(
      _entry(
        HarnessArtifactClass.summary,
        HarnessArtifactClass.summary.filenamePattern,
        <String, Object?>{
          'runId': config.runId,
          'createdAt': startedAt.toIso8601String(),
        },
      ),
    );

    return HarnessArtifactManifest(
      runId: config.runId,
      createdAt: startedAt,
      entries: List<HarnessArtifactEntry>.unmodifiable(entries),
    );
  }

  HarnessArtifactEntry _entry(
    HarnessArtifactClass artifactClass,
    String path,
    Map<String, Object?> payload,
  ) {
    return HarnessArtifactEntry(
      artifactClass: artifactClass,
      path: path,
      sizeBytes: utf8.encode(jsonEncode(payload)).length,
      fields: Set<String>.unmodifiable(payload.keys),
    );
  }
}
