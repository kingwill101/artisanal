// OpenCode Chat UI — Widget Example
//
// Demonstrates an OpenCode-style chat interface built with
// artisanal_widgets: session header, scrollable message body with
// text/tool/reasoning parts, prompt input, sidebar with collapsible
// sections, footer status bar, and a command palette overlay.
//
// Run with: dart run apps/opencode/bin/opencode.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'dart:io';

import 'package:opencode/src/opencode/app.dart';
export 'package:opencode/src/opencode/app.dart';
import 'package:opencode/src/opencode/chords.dart';
import 'package:opencode/src/opencode/theme.dart';
import 'package:opencode/src/opencode/replay_driver.dart';

void _printUsage() {
  stdout.write(openCodeUsage);
}

void main(List<String> args) async {
  late final OpenCodeCliOptions cliOptions;
  try {
    cliOptions = parseOpenCodeCliOptions(args);
  } on FormatException catch (error) {
    stderr.writeln('[opencode] $error');
    _printUsage();
    exitCode = 64;
    return;
  }

  if (cliOptions.help) {
    _printUsage();
    return;
  }

  final themeOverride = cliOptions.theme;
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

  // Surface-first keymap hub: routes push surfaces.
  final hub = openCodeKeymapHub(innerInterceptor: replayPlan?.interceptor);

  final app = w.WidgetApp(
    OpenCodeApp(hub: hub),
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
        interceptor: hub,
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
  final logDir = Directory('traces');
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
