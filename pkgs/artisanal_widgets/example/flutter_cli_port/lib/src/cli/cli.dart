import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:artisanal/artisanal.dart' as artisanal;
import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../app.dart';
import '../cli/flutter_process.dart';
import '../model.dart';
import '../theme.dart';
import '../views/build_view.dart';
import '../views/test_view.dart';
import 'commands/devices.dart';
import 'commands/external.dart';
import 'commands/init.dart';

const flutterCliVersion = '0.4.10';

Future<void> runFlutterCli(List<String> args) async {
  await FlutterCliRunner().run(args);
}

runtime.ProgramOptions flutterCliInlineOptions({required int height}) {
  return runtime.ProgramOptions(
    altScreen: false,
    screenMode: runtime.ScreenMode.inline,
    inlineHeight: height,
    uiAnchor: runtime.UiAnchor.bottom,
    mouseMode: runtime.MouseMode.none,
    fps: 30,
    startupProbes: false,
  );
}

final class FlutterCliRunner extends CommandRunner<void> {
  FlutterCliRunner()
    : super(
        'flutter-cli',
        'A modern Flutter CLI with seamless USB→WiFi hot reload',
        unknownCommandFallback: runExternalCommand,
      ) {
    argParser.addFlag(
      'version',
      abbr: 'V',
      negatable: false,
      help: 'Print version.',
    );
    addCommand(DevicesCommand());
    addCommand(RunCommand());
    addCommand(BuildCommand());
    addCommand(TestCommand());
    addCommand(InitCommand());
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      writeOut('flutter-cli $flutterCliVersion');
      return;
    }
    await super.runCommand(topLevelResults);
  }
}

final class DevicesCommand extends Command<void> {
  @override
  String get name => 'devices';

  @override
  String get description =>
      'List attached devices with status, IP, battery, OS version';

  @override
  Future<void> run() => runDevicesCommand();
}

final class RunCommand extends Command<void> {
  RunCommand() {
    argParser
      ..addOption('project', abbr: 'p', help: 'Flutter project directory.')
      ..addMultiOption('device', abbr: 'd', help: 'Device id, repeatable.')
      ..addFlag('all', negatable: false, help: 'Run on all devices.')
      ..addFlag(
        'no-picker',
        negatable: false,
        help: 'Do not open the device picker.',
      )
      ..addFlag('no-wifi', negatable: false, help: 'Disable USB→WiFi pairing.')
      ..addFlag(
        'no-tui',
        aliases: ['logs'],
        negatable: false,
        help: 'Stream output without the dashboard.',
      )
      ..addFlag(
        'basic',
        negatable: false,
        help: 'Pure passthrough to `flutter run`.',
      )
      ..addFlag('release', negatable: false, help: 'Build in release mode.')
      ..addFlag('profile', negatable: false, help: 'Build in profile mode.')
      ..addFlag('debug', negatable: false, help: 'Build in debug mode.');
  }

  @override
  String get name => 'run';

  @override
  String get description =>
      'Run a Flutter app with the `flutter-cli` dashboard. Auto-pairs USB→WiFi';

  @override
  Future<void> run() async {
    final results = argResults!;
    final mode = _modeFromResults(results, FlutterCliBuildMode.debug);
    final extra = results.rest;
    final basic = results['basic'] == true || results['no-tui'] == true;
    if (basic) {
      final flutterArgs = _runFlutterArgs(results, mode, extra);
      await runExternalCommand(
        flutterArgs,
        workingDirectory: results.option('project'),
      );
      return;
    }

    await _runInlineWidget(
      FlutterCliDashboard(
        initialState: _initialRunState(results, mode),
        process: FlutterProcessSpec(
          arguments: _runFlutterArgs(results, mode, extra),
          workingDirectory: results.option('project'),
          mode: mode,
        ),
      ),
      height: 16,
    );
  }
}

final class BuildCommand extends Command<void> {
  BuildCommand() {
    argParser
      ..addOption('project', abbr: 'p', help: 'Flutter project directory.')
      ..addFlag('release', negatable: false, help: 'Build in release mode.')
      ..addFlag('profile', negatable: false, help: 'Build in profile mode.')
      ..addFlag('debug', negatable: false, help: 'Build in debug mode.')
      ..addFlag(
        'basic',
        negatable: false,
        help: 'Pure passthrough to `flutter build`.',
      );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Build a Flutter app for a given target';

  @override
  Future<void> run() async {
    final results = argResults!;
    final rest = results.rest;
    final target = rest.isEmpty ? null : rest.first;
    final extra = rest.length <= 1 ? <String>[] : rest.sublist(1);
    final project = results.option('project');
    final mode = _modeFromResults(results, FlutterCliBuildMode.release);
    if (target == null) {
      await runExternalCommand(['build', ...extra], workingDirectory: project);
      return;
    }
    if (results['basic'] == true) {
      final flutterArgs = <String>['build', target];
      if (mode != FlutterCliBuildMode.release) {
        flutterArgs.add(mode.flutterFlag);
      }
      flutterArgs.addAll(extra);
      await runExternalCommand(flutterArgs, workingDirectory: project);
      return;
    }
    final flutterArgs = <String>['build', target];
    if (mode != FlutterCliBuildMode.release) {
      flutterArgs.add(mode.flutterFlag);
    }
    flutterArgs.addAll(extra);
    await _runInlineWidget(
      BuildView(
        target: target,
        mode: mode,
        process: FlutterProcessSpec(
          arguments: flutterArgs,
          workingDirectory: project,
          mode: mode,
        ),
      ),
      height: 14,
    );
  }
}

final class TestCommand extends Command<void> {
  TestCommand() {
    argParser
      ..addOption('project', abbr: 'p', help: 'Flutter project directory.')
      ..addOption(
        'device',
        abbr: 'd',
        help: 'Target device for integration / e2e tests.',
      )
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Run tests whose name matches this regular expression.',
      )
      ..addOption(
        'plain-name',
        help: 'Run tests whose name contains this literal substring.',
      )
      ..addMultiOption('tags', help: 'Run only tests tagged with this value.')
      ..addMultiOption(
        'exclude-tags',
        help: 'Skip tests tagged with this value.',
      )
      ..addFlag('coverage', negatable: false, help: 'Collect coverage.')
      ..addFlag(
        'update-goldens',
        negatable: false,
        help: 'Regenerate golden test files.',
      )
      ..addFlag(
        'golden',
        negatable: false,
        help: 'Default paths to test/golden/.',
      )
      ..addOption('reporter', help: 'Test reporter format.')
      ..addOption(
        'concurrency',
        abbr: 'j',
        help: 'Maximum number of suites to run in parallel.',
      )
      ..addFlag(
        'basic',
        negatable: false,
        help: 'Pure passthrough to `flutter test`.',
      );
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run flutter test with a live TUI';

  @override
  Future<void> run() async {
    final results = argResults!;
    if (results['basic'] == true) {
      await runExternalCommand(
        _testFlutterArgs(results),
        workingDirectory: results.option('project'),
      );
      return;
    }
    await _runInlineWidget(
      TestView(
        process: FlutterProcessSpec(
          arguments: _testFlutterArgs(results, machine: true),
          workingDirectory: results.option('project'),
        ),
      ),
      height: 22,
    );
  }
}

final class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Emit a shell shim that hijacks intercepted `flutter` commands';

  @override
  String get invocation =>
      '${runner?.executableName ?? 'flutter-cli'} init <shell>';

  @override
  Future<void> run() async {
    final shell = argResults!.rest.isEmpty ? null : argResults!.rest.first;
    if (shell == null) usageException('missing shell');
    if (shell != 'zsh' && shell != 'bash' && shell != 'fish') {
      usageException('unsupported shell: $shell');
    }
    stdout.write(renderInitShim(shell));
  }
}

Future<void> _runInlineWidget(w.Widget root, {required int height}) {
  return artisanal.runWidgetApp(
    w.WidgetApp(root, backgroundColor: FlutterCliTheme.tokyoNight.bg),
    options: flutterCliInlineOptions(height: height),
  );
}

FlutterCliBuildMode _modeFromResults(
  ArgResults results,
  FlutterCliBuildMode defaultMode,
) {
  if (results['release'] == true) return FlutterCliBuildMode.release;
  if (results['profile'] == true) return FlutterCliBuildMode.profile;
  if (results['debug'] == true) return FlutterCliBuildMode.debug;
  return defaultMode;
}

List<String> _runFlutterArgs(
  ArgResults results,
  FlutterCliBuildMode mode,
  List<String> extra,
) {
  final out = <String>['run'];
  for (final device in results.multiOption('device')) {
    out.addAll(['-d', device]);
  }
  if (results['all'] == true) out.addAll(['-d', 'all']);
  if (mode != FlutterCliBuildMode.debug) out.add(mode.flutterFlag);
  out.addAll(extra);
  return out;
}

FlutterCliState _initialRunState(ArgResults results, FlutterCliBuildMode mode) {
  final devices = results.multiOption('device');
  final sessions = devices.isEmpty
      ? <FlutterCliSession>[
          FlutterCliSession(
            serial: 'flutter',
            shortName: 'flutter',
            displayName: results['all'] == true ? 'all devices' : 'auto device',
            connection: FlutterCliConnectionKind.usb,
            state: FlutterCliSessionState.connecting,
            platform: results['all'] == true ? '' : null,
          ),
        ]
      : [
          for (final device in devices)
            FlutterCliSession(
              serial: device,
              shortName: device.length > 8 ? device.substring(0, 8) : device,
              displayName: device,
              connection: device.contains(':')
                  ? FlutterCliConnectionKind.wifi
                  : FlutterCliConnectionKind.usb,
              state: FlutterCliSessionState.connecting,
              platform: _platformFromDeviceArg(device),
            ),
        ];
  return FlutterCliState(
    appName:
        Directory.current.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .lastOrNull ??
        'flutter app',
    mode: mode.name,
    startedAt: DateTime.now(),
    sessions: sessions,
    banner: const FlutterCliBanner(
      kind: FlutterCliBannerKind.info,
      message: 'Starting flutter run',
      persistent: true,
    ),
  );
}

String? _platformFromDeviceArg(String device) {
  final lower = device.toLowerCase();
  if (lower == 'linux' || lower == 'macos' || lower == 'windows') return lower;
  if (lower.contains('chrome') || lower == 'web-server') return 'web';
  if (lower.contains('ios')) return 'ios';
  if (lower.contains('android') || lower.contains('emulator')) return 'android';
  return null;
}

List<String> _testFlutterArgs(ArgResults results, {bool machine = false}) {
  final out = <String>['test'];
  if (machine) out.add('--machine');
  void addOption(String option, String flutterName) {
    final value = results.option(option);
    if (value != null) out.addAll([flutterName, value]);
  }

  addOption('device', '-d');
  addOption('name', '--name');
  addOption('plain-name', '--plain-name');
  for (final tag in results.multiOption('tags')) {
    out.addAll(['--tags', tag]);
  }
  for (final tag in results.multiOption('exclude-tags')) {
    out.addAll(['--exclude-tags', tag]);
  }
  if (results['coverage'] == true) out.add('--coverage');
  if (results['update-goldens'] == true) out.add('--update-goldens');
  addOption('reporter', '--reporter');
  final concurrency = results.option('concurrency');
  if (concurrency != null) out.add('--concurrency=$concurrency');

  final paths = results.rest.toList();
  if (results['golden'] == true && paths.isEmpty) {
    out.add('test/golden/');
  } else {
    out.addAll(paths);
  }
  return out;
}

extension on FlutterCliBuildMode {
  String get flutterFlag => switch (this) {
    FlutterCliBuildMode.debug => '--debug',
    FlutterCliBuildMode.profile => '--profile',
    FlutterCliBuildMode.release => '--release',
  };
}
