/// artisanal TUI examples launcher.
///
/// Usage:
///   dart run example/tui/examples/main.dart          # list
///   dart run example/tui/examples/main.dart `<name>`   # run
library;

import 'dart:io' as io;

String get _packageRoot {
  final script = io.Platform.script.toFilePath();
  final ix = script.lastIndexOf(
    io.Platform.isWindows ? r'tui\examples' : 'tui/examples',
  );
  return script.substring(0, ix);
}

const _examples = [
  'altscreen-toggle',
  'autocomplete',
  'border_showcase',
  'cellbuffer',
  'chat',
  'components-host',
  'composable-views',
  'credit-card-form',
  'debounce',
  'evidence-logging',
  'exec',
  'eyes',
  'file-picker',
  'focus-blur',
  'fullscreen',
  'git-diff',
  'glamour',
  'harness_demo',
  'help',
  'hot_reload_test',
  'http',
  'inline',
  'kitchen-sink',
  'layout',
  'layout-breakpoints',
  'list-default',
  'list-fancy',
  'list-simple',
  'macro-recorder',
  'markdown',
  'mouse',
  'package-manager',
  'pager',
  'paginator',
  'pipe',
  'prevent-quit',
  'progress-animated',
  'progress-download',
  'progress-static',
  'realtime',
  'result',
  'send-msg',
  'sequence',
  'set-window-title',
  'simple',
  'spinner',
  'spinners',
  'split-editors',
  'stopwatch',
  'suspend',
  'table',
  'table-resize',
  'tabs',
  'textarea',
  'textinput',
  'textinputs',
  'timer',
  'trello',
  'tui-daemon-combo',
  'uv-input',
  'views',
  'window-size',
  'zone',
];

String _entryPoint(String name) {
  final base = '${_packageRoot}tui/examples';
  return name == 'trello' ? '$base/trello.dart' : '$base/$name/main.dart';
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Available TUI examples:\n');
    for (final name in _examples) {
      print('  dart run example/tui/examples/main.dart $name');
    }
    print('');
    return;
  }

  final name = args.first;
  if (!_examples.contains(name)) {
    print('Unknown example "$name".');
    io.exitCode = 1;
    return;
  }

  final result = await io.Process.run('dart', [
    'run',
    _entryPoint(name),
  ], runInShell: false);

  io.stdout.write(result.stdout);
  io.stderr.write(result.stderr);
  io.exitCode = result.exitCode;
}
