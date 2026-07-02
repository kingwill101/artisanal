import 'package:artisanal/args.dart';
import 'package:artisanal/tui.dart';

/// Counter model for the harness demo.
class _CounterModel implements Model {
  const _CounterModel(this.count);

  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      if (msg.key.type == KeyType.runes && msg.key.runes.firstOrNull == 0x71) {
        return (this, Cmd.quit());
      }
      if (msg.key.type == KeyType.up) return (const _CounterModel(1), null);
      if (msg.key.type == KeyType.down) return (const _CounterModel(-1), null);
    }
    return (this, null);
  }

  @override
  String view() => 'Count: $count\n\nq to quit, up/down to change.\n';
}

/// Run the counter app directly.
Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    final runner = HarnessDemoRunner();
    await runner.run(args);
    return;
  }

  await runProgram(const _CounterModel(0), options: const ProgramOptions(altScreen: false));
}

/// Command runner with harness mixin.
class HarnessDemoRunner extends CommandRunner<void> with HarnessCommandsMixin {
  HarnessDemoRunner() : super('harness_demo', 'TUI harness demo');

  @override
  String get harnessEntrypointPath => 'example/tui/examples/harness_demo/main.dart';
}

/// Mixin that adds replay and profile commands to a runner.
mixin HarnessCommandsMixin on CommandRunner<void> {
  String get harnessEntrypointPath;

  @override
  Future<void> run(Iterable<String> args) async {
    if (!_initialized) {
      addCommand(_ReplayHarnessCommand(harnessEntrypointPath));
      addCommand(_ProfileHarnessCommand(harnessEntrypointPath));
      _initialized = true;
    }
    await super.run(args);
  }

  bool _initialized = false;
}

final class _ReplayHarnessCommand extends Command<void> with ReplayHarnessMixin<void> {
  _ReplayHarnessCommand(this.entrypointPath) {
    registerHarnessFlags();
  }

  final String entrypointPath;

  @override
  String get name => 'replay';

  @override
  String get description => 'Run a replay scenario';

  @override
  String get harnessEntrypointPath => entrypointPath;

  @override
  Future<void> run() async {
    final config = ReplayHarnessConfig.fromArgResults(argResults!);
    await executeReplay(config);
  }
}

final class _ProfileHarnessCommand extends Command<void> with ReplayHarnessMixin<void>, ProfileHarnessMixin<void> {
  _ProfileHarnessCommand(this.entrypointPath) {
    registerHarnessFlags();
    registerProfileHarnessFlags();
  }

  final String entrypointPath;

  @override
  String get name => 'profile';

  @override
  String get description => 'Profile with devtools-profiler';

  @override
  String get harnessEntrypointPath => entrypointPath;

  @override
  String get profileProfilerCommand => 'devtools-profiler';

  @override
  String get profileArtifactDir => '.dart_tool/harness_demo/profile';

  @override
  String get profileRegionName => 'harness_demo.replay';

  @override
  Future<void> run() async {
    final replayConfig = ReplayHarnessConfig.fromArgResults(argResults!);
    final profileConfig = ProfileHarnessConfig.fromArgResults(replayConfig, argResults!);
    await executeProfile(replayConfig, profileConfig);
  }
}
