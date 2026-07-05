// OpenCode Chat UI — Widget Example
//
// Demonstrates an OpenCode-style chat interface built with
// artisanal_widgets: session header, scrollable message body with
// text/tool/reasoning parts, prompt input, sidebar with collapsible
// sections, footer status bar, and a command palette overlay.
//
// Run with: dart run example/opencode/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'dart:io';

import 'app.dart';
import 'theme.dart';
import 'replay_driver.dart';


String? _themeOverrideFromArgs(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--theme=')) {
      final value = arg.substring('--theme='.length).trim();
      if (value.isNotEmpty) return value;
    }
    if (arg == '--theme' && i + 1 < args.length) {
      final value = args[i + 1].trim();
      if (value.isNotEmpty) return value;
    }
  }
  return null;
}

bool _hasArg(List<String> args, String flag) {
  return args.any((arg) => arg == flag);
}

void _printUsage() {
  stderr.writeln('OpenCode example usage:');
  stderr.writeln('  --theme <name>');
  stderr.writeln('  --replay-scenario <name|path>');
  stderr.writeln('  --replay-speed <factor>     (default: 1.0)');
  stderr.writeln('  --replay-loop               (repeat forever)');
  stderr.writeln(
    '  --replay-keep-open          (do not auto-quit after replay)',
  );
  stderr.writeln(
    '  --replay-block-input        (ignore manual terminal input during replay)',
  );
  stderr.writeln('  --help');
}

void main(List<String> args) async {
  if (_hasArg(args, '--help')) {
    _printUsage();
    return;
  }

  final themeOverride = _themeOverrideFromArgs(args);
  OpenCodeReplayPlan? replayPlan;
  try {
    replayPlan = await loadOpenCodeReplayPlanFromArgs(args);
  } on FormatException catch (error) {
    stderr.writeln('[opencode] $error');
    _printUsage();
    exitCode = 64;
    return;
  } on FileSystemException catch (error) {
    stderr.writeln('[opencode] ${error.message}: ${error.path ?? ''}');
    _printUsage();
    exitCode = 66;
    return;
  }

  if (themeOverride != null) {
    await loadOpenCodeThemeAtLaunch(themeName: themeOverride);
  }

  if (replayPlan != null) {
    stdout.writeln(
      '[opencode] replay=${replayPlan.name} '
      'actions=${replayPlan.actionCount} '
      'loop=${replayPlan.loop} '
      'keepOpen=${replayPlan.keepOpen} '
      'blockInput=${replayPlan.blockInput} '
      'speed=${replayPlan.speed.toStringAsFixed(2)} '
      'path=${replayPlan.path}',
    );
  }

  final app = w.WidgetApp(
    OpenCodeApp(),
    backgroundColorBuilder: currentOpenCodeRouteBackground,
  );

  try {
    await tui.runProgram(
      app,
      options: tui.ProgramOptions(
        altScreen: true,
        mouse: true,
        mouseMode: tui.MouseMode.allMotion,
        replay: replayPlan?.replay,
        interceptor: replayPlan?.interceptor,
        blockInputWhileReplay: replayPlan?.blockInput ?? false,
      ),
    );
  } catch (error, stackTrace) {
    // _restoreTerminalBestEffort();
    final logPath = await _writeCrashLog(error, stackTrace);
    stderr.writeln('[opencode] Crash log written to $logPath');
    rethrow;
  }
}

// void _restoreTerminalBestEffort() {
//   // Reset styles, show cursor, and leave alt-screen if still active.
//   stdout.write('\x1b[0m\x1b[?25h\x1b[?1049l');
// }

Future<String> _writeCrashLog(Object error, StackTrace stackTrace) async {
  final now = DateTime.now().toIso8601String().replaceAll(':', '-');
  final logDir = Directory('pkgs/artisanal_widgets/example/opencode/traces');
  if (!await logDir.exists()) {
    await logDir.create(recursive: true);
  }
  final file = File('${logDir.path}/opencode-crash-$now.log');
  final lines = [
    'OpenCode example crash',
    'time: ${DateTime.now().toIso8601String()}',
    'cwd: ${Directory.current.path}',
    '',
    'error:',
    '$error',
    '',
    'stackTrace:',
    '$stackTrace',
  ];
  await file.writeAsString('${lines.join('\n')}\n');
  return file.path;
}
