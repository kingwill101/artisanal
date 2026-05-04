import 'package:artisanal/args.dart' show ArgParser, ArgResults;

final class GithubCliReplayConfig {
  const GithubCliReplayConfig({
    this.scenario,
    this.trace,
    this.traceOut,
    this.traceName,
    this.traceDescription,
    this.traceFromUs,
    this.traceToUs,
    this.traceMinSleepUs = 30000,
    this.traceScreenWidth = 0,
    this.traceScreenHeight = 0,
    this.traceFixedRightWidth = 0,
    this.traceIncludeHoverMoves = false,
    this.loop = false,
    this.keepOpen = false,
    this.blockInput = false,
    this.convertOnly = false,
    this.speed = 1.0,
  });

  final String? scenario;
  final String? trace;
  final String? traceOut;
  final String? traceName;
  final String? traceDescription;
  final int? traceFromUs;
  final int? traceToUs;
  final int traceMinSleepUs;
  final int traceScreenWidth;
  final int traceScreenHeight;
  final int traceFixedRightWidth;
  final bool traceIncludeHoverMoves;
  final bool loop;
  final bool keepOpen;
  final bool blockInput;
  final bool convertOnly;
  final double speed;

  bool get hasReplaySource => scenario != null || trace != null;

  static ({GithubCliReplayConfig config, String? error}) fromArgResults(
    ArgResults parsed,
  ) {
    final scenario = parsed['replay-scenario'] as String?;
    final trace = parsed['replay-trace'] as String?;
    if (scenario != null && trace != null) {
      return (
        config: const GithubCliReplayConfig(),
        error:
            'Use only one replay source: '
            '--replay-scenario or --replay-trace.',
      );
    }

    final speed = _parseDouble(parsed['replay-speed'], '--replay-speed');
    if (speed case (value: _, error: final error?)) {
      return (config: const GithubCliReplayConfig(), error: error);
    }

    final minSleep = _parseInt(
      parsed['replay-trace-min-sleep-us'],
      '--replay-trace-min-sleep-us',
    );
    if (minSleep case (value: _, error: final error?)) {
      return (config: const GithubCliReplayConfig(), error: error);
    }

    final screenWidth = _parseInt(
      parsed['replay-trace-screen-width'],
      '--replay-trace-screen-width',
    );
    if (screenWidth case (value: _, error: final error?)) {
      return (config: const GithubCliReplayConfig(), error: error);
    }

    final screenHeight = _parseInt(
      parsed['replay-trace-screen-height'],
      '--replay-trace-screen-height',
    );
    if (screenHeight case (value: _, error: final error?)) {
      return (config: const GithubCliReplayConfig(), error: error);
    }

    final fixedRightWidth = _parseInt(
      parsed['replay-trace-fixed-right-width'],
      '--replay-trace-fixed-right-width',
    );
    if (fixedRightWidth case (value: _, error: final error?)) {
      return (config: const GithubCliReplayConfig(), error: error);
    }

    final fromUs = _parseOptionalInt(
      parsed['replay-trace-from-us'],
      '--replay-trace-from-us',
    );
    if (fromUs case (value: _, error: final error?)) {
      return (config: const GithubCliReplayConfig(), error: error);
    }

    final toUs = _parseOptionalInt(
      parsed['replay-trace-to-us'],
      '--replay-trace-to-us',
    );
    if (toUs case (value: _, error: final error?)) {
      return (config: const GithubCliReplayConfig(), error: error);
    }

    final convertOnly = parsed['replay-convert-only'] == true;
    if (convertOnly && trace == null) {
      return (
        config: const GithubCliReplayConfig(),
        error: '--replay-convert-only requires --replay-trace.',
      );
    }

    final traceOut = parsed['replay-trace-out'] as String?;
    if (convertOnly && (traceOut == null || traceOut.trim().isEmpty)) {
      return (
        config: const GithubCliReplayConfig(),
        error: '--replay-convert-only requires --replay-trace-out <path>.',
      );
    }

    return (
      config: GithubCliReplayConfig(
        scenario: _blankToNull(scenario),
        trace: _blankToNull(trace),
        traceOut: _blankToNull(traceOut),
        traceName: _blankToNull(parsed['replay-trace-name'] as String?),
        traceDescription: _blankToNull(
          parsed['replay-trace-description'] as String?,
        ),
        traceFromUs: fromUs.value,
        traceToUs: toUs.value,
        traceMinSleepUs: minSleep.value,
        traceScreenWidth: screenWidth.value,
        traceScreenHeight: screenHeight.value,
        traceFixedRightWidth: fixedRightWidth.value,
        traceIncludeHoverMoves: parsed['replay-trace-include-hover'] == true,
        loop: parsed['replay-loop'] == true,
        keepOpen: parsed['replay-keep-open'] == true,
        blockInput: parsed['replay-block-input'] == true,
        convertOnly: convertOnly,
        speed: speed.value,
      ),
      error: null,
    );
  }

  static ({double value, String? error}) _parseDouble(
    Object? value,
    String optionName,
  ) {
    final raw = (value as String? ?? '').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return (value: 1.0, error: '$optionName must be a positive number.');
    }
    return (value: parsed, error: null);
  }

  static ({int value, String? error}) _parseInt(
    Object? value,
    String optionName,
  ) {
    final raw = (value as String? ?? '').trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      return (value: 0, error: '$optionName must be a non-negative integer.');
    }
    return (value: parsed, error: null);
  }

  static ({int? value, String? error}) _parseOptionalInt(
    Object? value,
    String optionName,
  ) {
    final raw = (value as String? ?? '').trim();
    if (raw.isEmpty) return (value: null, error: null);
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      return (
        value: null,
        error: '$optionName must be a non-negative integer.',
      );
    }
    return (value: parsed, error: null);
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

extension GithubCliReplayArgumentRegistration on ArgParser {
  void registerGithubCliReplayFlags() {
    addOption(
      'replay-scenario',
      help: 'Load a replay scenario JSON file or built-in scenario name.',
      valueHelp: 'name|path',
    );
    addOption(
      'replay-trace',
      help: 'Convert a TuiTrace log into a replay scenario.',
      valueHelp: 'path',
    );
    addOption(
      'replay-trace-out',
      help: 'Write a converted replay scenario JSON file.',
      valueHelp: 'path',
    );
    addOption(
      'replay-trace-name',
      help: 'Name to use when converting a trace.',
      valueHelp: 'name',
    );
    addOption(
      'replay-trace-description',
      help: 'Description to use when converting a trace.',
      valueHelp: 'text',
    );
    addOption(
      'replay-trace-from-us',
      help: 'First trace timestamp to include, in microseconds.',
      valueHelp: 'micros',
    );
    addOption(
      'replay-trace-to-us',
      help: 'Last trace timestamp to include, in microseconds.',
      valueHelp: 'micros',
    );
    addOption(
      'replay-trace-min-sleep-us',
      defaultsTo: '30000',
      help: 'Minimum trace gap preserved as sleep during conversion.',
      valueHelp: 'micros',
    );
    addOption(
      'replay-trace-screen-width',
      defaultsTo: '0',
      help: 'Override converted replay source screen width.',
      valueHelp: 'cols',
    );
    addOption(
      'replay-trace-screen-height',
      defaultsTo: '0',
      help: 'Override converted replay source screen height.',
      valueHelp: 'rows',
    );
    addOption(
      'replay-trace-fixed-right-width',
      defaultsTo: '0',
      help: 'Keep a fixed right pane width when scaling replay mouse input.',
      valueHelp: 'cols',
    );
    addFlag(
      'replay-trace-include-hover',
      negatable: false,
      help: 'Preserve hover motion events when converting traces.',
    );
    addFlag(
      'replay-convert-only',
      negatable: false,
      help: 'Convert --replay-trace and exit without launching the TUI.',
    );
    addFlag(
      'replay-loop',
      negatable: false,
      help: 'Repeat the replay scenario until the app exits.',
    );
    addFlag(
      'replay-keep-open',
      negatable: false,
      help: 'Do not auto-quit when replay reaches the end.',
    );
    addFlag(
      'replay-block-input',
      negatable: false,
      help: 'Ignore manual terminal input while replay is active.',
    );
    addOption(
      'replay-speed',
      defaultsTo: '1.0',
      help: 'Replay speed multiplier.',
      valueHelp: 'factor',
    );
  }
}
