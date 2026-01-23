/// ViewComponent host demo.
///
/// A minimal example showing how to host multiple `ViewComponent`s inside a
/// parent `Model` while staying compatible with both the default renderer and
/// the UV renderer/input decoder.
///
/// Options:
///   --legacy-input     Use the legacy KeyParser (default is UV decoder)
///   --uv-renderer      Use the UV renderer (cell-buffer diff)
library;

import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal/tui.dart' as tui;

class _ProgressStepMsg extends tui.Msg {
  const _ProgressStepMsg();
}

class _ComponentsHostModel extends tui.Model {
  _ComponentsHostModel({required this.useUvInput, required this.useUvRenderer})
    : spinner = tui.SpinnerModel(spinner: tui.Spinners.miniDot),
      progress = tui.ProgressModel(width: 44, useGradient: true),
      paginator = tui.PaginatorModel(
        type: tui.PaginationType.dots,
        perPage: 8,
      ).setTotalPages(_items.length);

  static final List<String> _items = List<String>.generate(
    64,
    (i) => 'Item ${i + 1}',
  );

  final bool useUvInput;
  final bool useUvRenderer;

  tui.SpinnerModel spinner;
  tui.ProgressModel progress;
  tui.PaginatorModel paginator;

  bool _auto = true;

  @override
  tui.Cmd? init() {
    return tui.Cmd.batch([spinner.tick(), _scheduleProgressStep()]);
  }

  tui.Cmd _scheduleProgressStep() {
    return tui.Cmd.tick(
      const Duration(milliseconds: 120),
      (_) => const _ProgressStepMsg(),
    );
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    // Global quits.
    if (msg case tui.KeyMsg(key: final key)
        when key.matchesSingle(tui.CommonKeyBindings.quit) ||
            key.isEscape ||
            key.isCtrlC ||
            key.isChar('q')) {
      return (this, tui.Cmd.quit());
    }

    final cmds = <tui.Cmd>[];

    // Local controls (and still allow delegation to children).
    if (msg case tui.KeyMsg(key: final key)) {
      if (key.isChar('p')) {
        _auto = !_auto;
      } else if (key.isChar('r') || key.isAccept) {
        final (p, c) = progress.setPercent(0, animate: false);
        progress = p;
        if (c != null) cmds.add(c);
      } else if (key.isChar('g')) {
        final (p, c) = progress.setPercent(1, animate: true);
        progress = p;
        if (c != null) cmds.add(c);
      }
    }

    // Delegate to child components (so they receive KeyMsg/WindowSizeMsg/etc).
    final (newSpinner, spinnerCmd) = spinner.update(msg);
    spinner = newSpinner;
    if (spinnerCmd case final c?) cmds.add(c);

    final (newProgress, progressCmd) = progress.update(msg);
    progress = newProgress;
    if (progressCmd case final c?) cmds.add(c);

    final (newPaginator, paginatorCmd) = paginator.update(msg);
    paginator = newPaginator;
    if (paginatorCmd case final c?) cmds.add(c);

    // Demo "work" loop: nudge progress while running.
    if (msg is _ProgressStepMsg) {
      cmds.add(_scheduleProgressStep());
      if (_auto) {
        final double nextTarget = progress.percent >= 1
            ? 0.0
            : (progress.percent + 0.04);
        final (p, c) = progress.setPercent(nextTarget, animate: true);
        progress = p;
        if (c != null) cmds.add(c);
      }
    }

    return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
  }

  @override
  String view() {
    final title = Style().bold().render('ViewComponent Host Demo');
    final mode =
        'input=${useUvInput ? 'uv' : 'legacy'}  renderer=${useUvRenderer ? 'uv' : 'default'}';
    final help =
        'q quit • p pause • Enter/Space/r reset • g complete • ←/→ page';

    final (start, end) = paginator.getSliceBounds(_items.length);
    final pageItems = _items.sublist(start, end);
    final pageText = pageItems
        .map((it) => '  ${Style().dim().render('•')} $it')
        .join('\n');

    final status =
        '${spinner.view()}  ${_auto ? 'running' : 'paused'}  ${progress.view()}';

    return [
      title,
      mode,
      help,
      '',
      status,
      '',
      pageText,
      '',
      '  ${paginator.view()}',
      '',
    ].join('\n');
  }
}

Future<void> main(List<String> args) async {
  final legacy = args.contains('--legacy-input');
  final uvRenderer = args.contains('--uv-renderer');

  await tui.runProgram(
    _ComponentsHostModel(useUvInput: !legacy, useUvRenderer: uvRenderer),
    options: tui.ProgramOptions(
      altScreen: true,
      useUltravioletInputDecoder: !legacy,
      useUltravioletRenderer: uvRenderer,
    ),
  );
}
