import 'dart:math' as math;

import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/style.dart' as style;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../cli/flutter_process.dart';
import '../model.dart';
import '../theme.dart';
import '../utils.dart';

class TestView extends w.StatefulWidget {
  TestView({
    this.process,
    this.flTheme = FlutterCliTheme.tokyoNight,
    super.key,
  });

  final FlutterProcessSpec? process;
  final FlutterCliTheme flTheme;

  @override
  w.State createState() => TestViewState();
}

class TestViewState extends w.State<TestView> {
  int passed = 0;
  int failed = 0;
  int skipped = 0;
  final running = <({int id, String name})>[];
  final recentDone =
      <({String name, FlutterCliTestResult result, int durationMs})>[];
  final failures = <FlutterCliTestFailure>[];
  final names = <int, String>{};
  bool allDone = false;
  bool success = false;
  bool quitting = false;
  bool wantsRestart = false;
  late DateTime startedAt;
  DateTime? finishedAt;
  FlutterCliScrollFocus scrollFocus = FlutterCliScrollFocus.tests;
  int testsScroll = 0;
  int failureScroll = 0;
  int testsViewport = 10;
  int failuresViewport = 10;
  int spinnerTick = 0;
  FlutterCliTestBanner? banner;

  int get total => passed + failed + skipped;

  Duration get elapsed => (finishedAt ?? DateTime.now()).difference(startedAt);

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
  }

  @override
  runtime.Cmd? handleInit() {
    final process = widget.process;
    if (process == null) return null;
    return listenToFlutterProcess(process);
  }

  void apply(FlutterCliTestEvent input) {
    switch (input) {
      case FlutterCliTestStarted(:final id, :final name):
        names[id] = name;
        running.add((id: id, name: name));
      case FlutterCliTestDone(
        :final id,
        :final name,
        :final result,
        :final durationMs,
      ):
        running.removeWhere((entry) => entry.id == id);
        switch (result) {
          case FlutterCliTestResult.success:
            passed++;
          case FlutterCliTestResult.failure || FlutterCliTestResult.error:
            failed++;
          case FlutterCliTestResult.skipped:
            skipped++;
        }
        final resolved = name.isNotEmpty
            ? name
            : names.remove(id) ?? 'test #$id';
        recentDone.add((
          name: resolved,
          result: result,
          durationMs: durationMs,
        ));
        if (recentDone.length > 200) {
          recentDone.removeAt(0);
          if (testsScroll > 0) testsScroll = math.max(0, testsScroll - 1);
        }
        if (testsScroll > 0) {
          testsScroll = math.min(testsScroll + 1, recentDone.length - 1);
        }
      case FlutterCliTestError(:final id, :final message, :final stack):
        final name = switch (id) {
          final value? when names.containsKey(value) => names[value]!,
          _ when running.isNotEmpty => running.last.name,
          _ => '<unknown>',
        };
        failures.add(
          FlutterCliTestFailure(name: name, message: message, stack: stack),
        );
      case FlutterCliAllDone(:final success):
        allDone = true;
        this.success = success;
        finishedAt = DateTime.now();
    }
  }

  void showBanner(FlutterCliTestBannerKind kind, String message) {
    banner = FlutterCliTestBanner(
      kind: kind,
      message: message,
      shownAt: DateTime.now(),
    );
  }

  void expireBanner() {
    final current = banner;
    if (current != null &&
        DateTime.now().difference(current.shownAt) >= current.duration) {
      banner = null;
    }
  }

  void scrollUp(int rows) {
    switch (scrollFocus) {
      case FlutterCliScrollFocus.tests:
        testsScroll = math.min(
          testsScroll + rows,
          math.max(0, recentDone.length - 1),
        );
      case FlutterCliScrollFocus.failures:
        failureScroll = math.min(
          failureScroll + rows,
          math.max(0, failures.length - 1),
        );
    }
  }

  void scrollDown(int rows) {
    switch (scrollFocus) {
      case FlutterCliScrollFocus.tests:
        testsScroll = math.max(0, testsScroll - rows);
      case FlutterCliScrollFocus.failures:
        failureScroll = math.max(0, failureScroll - rows);
    }
  }

  int viewportForFocus() {
    return switch (scrollFocus) {
      FlutterCliScrollFocus.tests => testsViewport,
      FlutterCliScrollFocus.failures => failuresViewport,
    };
  }

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();
    final height = media.size.height.round();
    return w.Container(
      width: width,
      height: height,
      background: widget.flTheme.bg,
      child: w.Column(
        width: width,
        height: height,
        children: [
          _TestHeader(state: this, flTheme: widget.flTheme),
          w.Expanded(
            child: _TestBody(state: this, flTheme: widget.flTheme),
          ),
          _TestFooter(state: this, flTheme: widget.flTheme),
          if (banner != null)
            _TestBannerLine(banner: banner!, flTheme: widget.flTheme),
        ],
      ),
    );
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is FlutterProcessStarted) {
      setState(() {
        showBanner(FlutterCliTestBannerKind.info, 'Running ${msg.commandLine}');
      });
      return runtime.Cmd.println('\$ ${msg.commandLine}');
    }
    if (msg is FlutterProcessLine) {
      setState(() {
        final event = msg.testEvent;
        if (event != null) {
          apply(event);
        } else if (msg.stderr || msg.line.trim().isNotEmpty) {
          apply(
            FlutterCliTestError(
              message: msg.line.isEmpty ? '(stderr)' : msg.line,
            ),
          );
        }
      });
      return runtime.Cmd.println(msg.line);
    }
    if (msg is FlutterProcessExited) {
      setState(() {
        if (!allDone) apply(FlutterCliAllDone(success: msg.exitCode == 0));
        if (msg.exitCode != 0 && failures.isEmpty) {
          apply(
            FlutterCliTestError(
              message: 'flutter test exited with code ${msg.exitCode}',
            ),
          );
        }
      });
      return runtime.Cmd.println(
        'flutter test exited with code ${msg.exitCode}',
      );
    }
    if (msg is FlutterProcessFailed) {
      setState(() {
        apply(FlutterCliTestError(message: msg.message));
        apply(const FlutterCliAllDone(success: false));
      });
      return runtime.Cmd.println(msg.message);
    }
    if (msg is runtime.FrameTickMsg || msg is runtime.TickMsg) {
      setState(() {
        spinnerTick = (spinnerTick + 1) % 256;
        expireBanner();
      });
      return null;
    }
    if (msg is! runtime.KeyMsg) return null;
    final key = msg.key;
    setState(() {
      switch (key.type) {
        case KeyType.tab:
          scrollFocus = switch (scrollFocus) {
            FlutterCliScrollFocus.tests => FlutterCliScrollFocus.failures,
            FlutterCliScrollFocus.failures => FlutterCliScrollFocus.tests,
          };
        case KeyType.up:
          scrollUp(1);
        case KeyType.down:
          scrollDown(1);
        case KeyType.pageUp:
          scrollUp(math.max(1, viewportForFocus()));
        case KeyType.pageDown:
          scrollDown(math.max(1, viewportForFocus()));
        default:
          final char = key.char;
          if (char == 'q' || key.ctrlC) {
            quitting = true;
          } else if (char == 'r') {
            wantsRestart = true;
            quitting = true;
            showBanner(FlutterCliTestBannerKind.info, '🔄 Restarting tests…');
          } else if (char == 'g') {
            if (scrollFocus == FlutterCliScrollFocus.tests) {
              testsScroll = 0;
            } else {
              failureScroll = 0;
            }
          } else if (char == 'G') {
            if (scrollFocus == FlutterCliScrollFocus.tests) {
              testsScroll = math.max(0, recentDone.length - 1);
            } else {
              failureScroll = math.max(0, failures.length - 1);
            }
          } else if (char == 'c') {
            if (failures.isEmpty) {
              showBanner(
                FlutterCliTestBannerKind.info,
                'Nothing to copy — no failures 🎉',
              );
            } else {
              showBanner(
                FlutterCliTestBannerKind.success,
                '📋 Copied ${failures.length} failure(s) to clipboard',
              );
            }
          }
      }
    });
    return null;
  }
}

class _TestHeader extends w.StatelessWidget {
  _TestHeader({required this.state, required this.flTheme});

  final TestViewState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final width = w.MediaQuery.of(context).size.width.round();
    final status = state.allDone ? (state.success ? '✓' : '✗') : '⏱';
    final statusColor = state.allDone
        ? (state.success ? flTheme.success : flTheme.error)
        : flTheme.fg;
    return w.Frame(
      border: style.Border.normal,
      borderColor: flTheme.dim,
      background: flTheme.bg,
      foreground: flTheme.fg,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.Row(
        width: width,
        mainAxisAlignment: w.MainAxisAlignment.spaceBetween,
        children: [
          w.Text(
            ' flutter-cli test ── ✓ ${state.passed}  ✗ ${state.failed}  – ${state.skipped}    total ${state.total}',
            style: flTheme.header,
            overflow: w.TextOverflow.clip,
          ),
          w.Text(
            '$status ${formatElapsed(state.elapsed)} ',
            style: flTheme.bold(statusColor),
          ),
        ],
      ),
    );
  }
}

class _TestBody extends w.StatelessWidget {
  _TestBody({required this.state, required this.flTheme});

  final TestViewState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final width = w.MediaQuery.of(context).size.width.round();
    if (width < 90) {
      return w.Column(
        children: [
          w.Expanded(
            child: _LiveTestsPanel(state: state, flTheme: flTheme),
          ),
          w.Expanded(
            child: _FailuresPanel(state: state, flTheme: flTheme),
          ),
        ],
      );
    }
    return w.Row(
      children: [
        w.Expanded(
          child: _LiveTestsPanel(state: state, flTheme: flTheme),
        ),
        w.Expanded(
          child: _FailuresPanel(state: state, flTheme: flTheme),
        ),
      ],
    );
  }
}

class _LiveTestsPanel extends w.StatelessWidget {
  _LiveTestsPanel({required this.state, required this.flTheme});

  final TestViewState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();
    final height = media.size.height.round();
    state.testsViewport = math.max(1, height - 4);
    final focused = state.scrollFocus == FlutterCliScrollFocus.tests;
    final focusMark = focused ? '▸ ' : '';
    final scrollHint = state.testsScroll > 0
        ? ' · paused -${state.testsScroll}'
        : '';
    final title = state.allDone
        ? ' ${focusMark}Tests · ${state.total} done$scrollHint '
        : state.running.isEmpty
        ? ' ${focusMark}Tests$scrollHint '
        : ' ${focusMark}Tests · ${state.running.length} running$scrollHint ';
    final lines = <w.Widget>[];
    const spinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    final spinner = spinnerFrames[state.spinnerTick % spinnerFrames.length];

    if (state.testsScroll == 0) {
      for (final entry in state.running.take(5)) {
        lines.add(
          w.Text(
            '$spinner ${truncate(entry.name, width - 4)}',
            style: flTheme.fgStyle(flTheme.warn),
            softWrap: false,
          ),
        );
      }
      if (state.running.length > 5) {
        lines.add(
          w.Text(
            '    … +${state.running.length - 5} more running',
            style: flTheme.dimmed,
          ),
        );
      }
    }

    final budget = math.max(0, state.testsViewport - lines.length);
    final count = state.recentDone.length;
    final offset = math.min(state.testsScroll, math.max(0, count - budget));
    final end = math.max(0, count - offset);
    final start = math.max(0, end - budget);
    for (final entry in state.recentDone.sublist(start, end)) {
      final (marker, color) = switch (entry.result) {
        FlutterCliTestResult.success => ('✓', flTheme.success),
        FlutterCliTestResult.failure ||
        FlutterCliTestResult.error => ('✗', flTheme.error),
        FlutterCliTestResult.skipped => ('–', flTheme.dim),
      };
      final duration = '${entry.durationMs}ms';
      lines.add(
        w.Text(
          '$marker ${truncate(entry.name, math.max(1, width - duration.length - 6))}  $duration',
          style: flTheme.fgStyle(color),
          softWrap: false,
        ),
      );
    }

    return w.PanelBox(
      title: title,
      border: style.Border.normal,
      borderColor: focused ? flTheme.accent : flTheme.dim,
      background: flTheme.bg,
      foreground: flTheme.fg,
      titleStyle: flTheme.bold(focused ? flTheme.accent : flTheme.dim),
      bodyStyle: flTheme.base,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(children: lines),
    );
  }
}

class _FailuresPanel extends w.StatelessWidget {
  _FailuresPanel({required this.state, required this.flTheme});

  final TestViewState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();
    final height = media.size.height.round();
    state.failuresViewport = math.max(1, height - 4);
    final focused = state.scrollFocus == FlutterCliScrollFocus.failures;
    final focusMark = focused ? '▸ ' : '';
    final title = switch ((state.failures.length, state.failureScroll)) {
      (0, _) => ' ${focusMark}Failures · none 🎉 ',
      (final n, final scroll) when scroll > 0 =>
        ' ${focusMark}Failures · $n (paused -$scroll, g=tail, G=top) ',
      (final n, _) => ' ${focusMark}Failures · $n ',
    };
    final borderColor = focused
        ? flTheme.accent
        : state.failures.isEmpty
        ? flTheme.dim
        : flTheme.error;
    final lines = <w.Widget>[];
    if (state.failures.isEmpty) {
      final msg = state.allDone && state.success
          ? 'All tests passed.'
          : state.allDone
          ? 'Run finished without recorded failures (but exit code says fail — check daemon output).'
          : '(none yet)';
      lines.add(w.Text(msg, style: flTheme.dimmed));
    } else {
      final maxOffset = math.max(0, state.failures.length - 1);
      final offset = math.min(state.failureScroll, maxOffset);
      var index = state.failures.length - 1 - offset;
      final packed = <w.Widget>[];
      while (index >= 0 && packed.length < state.failuresViewport) {
        final failure = state.failures[index];
        final block = <w.Widget>[
          w.Text(
            '✗ ${truncate(failure.name, width - 4)}',
            style: flTheme.bold(flTheme.error),
            softWrap: false,
          ),
          for (final line in failure.message.split('\n').take(3))
            w.Text('    ${truncate(line, width - 6)}', style: flTheme.dimmed),
          w.Text('', style: flTheme.base),
        ];
        packed.insertAll(0, block);
        index--;
      }
      final visible = packed.length > state.failuresViewport
          ? packed.sublist(packed.length - state.failuresViewport)
          : packed;
      lines.addAll(visible);
    }

    return w.PanelBox(
      title: title,
      border: style.Border.normal,
      borderColor: borderColor,
      background: flTheme.bg,
      foreground: flTheme.fg,
      titleStyle: flTheme.bold(borderColor),
      bodyStyle: flTheme.base,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(children: lines),
    );
  }
}

class _TestFooter extends w.StatelessWidget {
  _TestFooter({required this.state, required this.flTheme});

  final TestViewState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    if (state.allDone) {
      final text = state.success
          ? ' ✓ ALL PASSED · ${state.total} tests in ${formatElapsed(state.elapsed)} '
          : ' ✗ ${state.failed} FAILED of ${state.total} · ${formatElapsed(state.elapsed)} ';
      final color = state.success ? flTheme.success : flTheme.error;
      return w.Row(
        children: [
          w.Text(text, style: flTheme.bold(flTheme.bg)..background(color)),
          w.Text(
            '  [Tab] switch  [r] re-run 🔄  [c] copy 📋  [q] quit ',
            style: flTheme.dimmed,
          ),
        ],
      );
    }
    return w.Text(
      ' ⏳ running… ${state.total} done · [Tab] switch  [r] re-run 🔄  [c] copy 📋  [q] quit ',
      style: flTheme.dimmed,
    );
  }
}

class _TestBannerLine extends w.StatelessWidget {
  _TestBannerLine({required this.banner, required this.flTheme});

  final FlutterCliTestBanner banner;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final bg = switch (banner.kind) {
      FlutterCliTestBannerKind.success => flTheme.success,
      FlutterCliTestBannerKind.info => flTheme.cyan,
    };
    return w.Container(
      alignment: const w.Alignment(0, 0),
      child: w.Text(
        ' ${banner.message} ',
        style: flTheme.bold(flTheme.bg)..background(bg),
        softWrap: false,
      ),
    );
  }
}

extension on runtime.Key {
  bool get ctrlC => ctrl && runes.length == 1 && runes.first == 0x63;
}
