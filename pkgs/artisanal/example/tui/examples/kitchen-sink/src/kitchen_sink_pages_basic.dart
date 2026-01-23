part of 'kitchen_sink.dart';

final class _OverviewPage extends _KitchenSinkPage {
  const _OverviewPage() : super(help: 'Overview: what this app covers');

  @override
  String view(_KitchenSinkModel m) {
    final lines = <String>[
      m._style(Style()).bold().render('What to test here'),
      '',
      '• UV renderer: dynamic updates (TuiRenderer tab), tables/trees/lists (tui.Tree/List/tui.Table tab)',
      '• UV input decoder: Enter/Tab/arrows/paste/mouse (Input + List tabs)',
      '• Terminal theme: background detection + adaptive colors (Colors tab)',
      '• Graphics: Kitty/iTerm2/Sixel protocol detection (Graphics tab)',
      '• Capabilities: ANSI query results (Capabilities tab)',
      '• Keyboard: Enhanced keyboard protocol (Keyboard tab)',
      '• Lipgloss v2: Underline colors, padding chars, table inheritance (Lipgloss v2 tab)',
      '• uv.Compositor: UV layering and canvas composition (uv.Compositor tab)',
      '• Writer: ANSI downsampling (Writer tab)',
      '• Unicode width: emoji/CJK/grapheme clusters (Unicode tab)',
      '',
      m
          ._style(Style())
          .dim()
          .render('Tip: run with `--uv-renderer` and resize the terminal.'),
    ];
    return lines.join('\n');
  }
}

final class _InputPage extends _KitchenSinkPage {
  const _InputPage()
    : super(
        help:
            'Input: type in box • paste/mouse/focus/resize logs • c copy • p clipboard read • s size report',
      );

  @override
  String view(_KitchenSinkModel m) {
    final left = <String>[
      m._style(Style()).bold().render('Input controls'),
      '',
      'TextInput:',
      '  ${m.textInput.view()}',
      '',
      'TextArea:',
      m.textarea.view() as String,
      '',
      m._style(Style()).dim().render('Recent events (newest last):'),
    ];

    final maxLog = (m._height - 18).clamp(3, 9999);
    final logLines = m._eventLog.length <= maxLog
        ? m._eventLog
        : m._eventLog.sublist(m._eventLog.length - maxLog);
    final clipped = logLines.map((l) => _clipToWidth(l, m._width)).join('\n');

    return [left.join('\n'), '', clipped].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    m._log('KeyMsg($key)');
    if (key.isChar('c')) {
      cmds.add(tui.Cmd.setClipboard('kitchen-sink: hello'));
    } else if (key.isChar('p')) {
      cmds.add(tui.Cmd.requestClipboard());
    } else if (key.isChar('s')) {
      cmds.add(tui.Cmd.requestWindowSizeReport());
    }
    // This page is a key playground; avoid global navigation shortcuts while
    // typing.
    return true;
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    final (newInput, inputCmd) = m.textInput.update(msg);
    if (newInput.value != m.textInput.value) {
      m.textInput.value = newInput.value;
    }
    if (inputCmd != null) cmds.add(inputCmd);

    final (newArea, areaCmd) = m.textarea.update(msg);
    if (newArea.value != m.textarea.value) {
      m.textarea.value = newArea.value;
    }
    if (areaCmd != null) cmds.add(areaCmd);
  }
}

final class _ListSelectPage extends _KitchenSinkPage {
  const _ListSelectPage()
    : super(help: 'List: ↑/↓ or j/k move • Enter select • r reset');

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('Interactive list (accept/select)');
    final subtitle = m
        ._style(Style())
        .dim()
        .render(
          'Selected: ${m.listSelection.selected ?? '(none)'}  (Enter should select)',
        );
    return [title, subtitle, '', m.listSelection.view(m)].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    final (next, cmd) = m.listSelection.update(key);
    m.listSelection = next;
    if (cmd != null) cmds.add(cmd);
    return true;
  }
}

final class _RendererPage extends _KitchenSinkPage {
  _RendererPage()
    : super(
        help:
            'TuiRenderer: r reset • g complete • ←/→ (or h/l) nudge • t toggle auto-tick',
      );

  bool _autoTick = false;
  int _manualCooldownTicks = 0;

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('TuiRenderer stress');
    final status =
        '${m.spinner.view()}  ${m.progress.view()}  ${m._style(Style()).dim().render('auto=${_autoTick ? 'on' : 'off'} (t to toggle)')}';

    final sample =
        (tui.Tree()
              ..root('Render surfaces')
              ..child(LipList.create(['alpha', 'beta', 'gamma']))
              ..child(
                (tui.Table()
                      ..headers(['A', 'B'])
                      ..row(['left', 'right'])
                      ..row(['wrap', 'test']))
                    .render(),
              ))
            .enumerator(tui.TreeEnumerator.rounded)
            .render();

    return [title, '', status, '', sample].join('\n');
  }

  @override
  void onTick(_KitchenSinkModel m, List<tui.Cmd> cmds) {
    if (!_autoTick) return;
    if (_manualCooldownTicks > 0) {
      _manualCooldownTicks--;
      return;
    }

    // Nudge the progress bar while incomplete. Once complete, hold at 100%
    // until the user resets (so keybinds visibly "work").
    if (m.progress.percent >= 1) return;
    final next = (m.progress.percent + 0.03).clamp(0.0, 1.0);
    final (p, c) = m.progress.setPercent(next, animate: true);
    m.progress = p;
    if (c != null) cmds.add(c);
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    bool isCharAny(String a, String b) => key.isChar(a) || key.isChar(b);

    if (isCharAny('t', 'T')) {
      _autoTick = !_autoTick;
      return true;
    }

    if (isCharAny('r', 'R')) {
      final (p, c) = m.progress.setPercent(0, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }
    if (isCharAny('g', 'G')) {
      final (p, c) = m.progress.setPercent(1, animate: true);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }

    // Nudge with arrows/+/- for quick manual testing (useful on keypads too).
    final delta = switch (key.type) {
      tui.KeyType.left => -0.05,
      tui.KeyType.right => 0.05,
      _ => switch (key.char) {
        'h' => -0.05,
        'l' => 0.05,
        _ => null,
      },
    };
    if (delta != null) {
      _manualCooldownTicks = 8;
      final next = (m.progress.percent + delta).clamp(0.0, 1.0);
      final (p, c) = m.progress.setPercent(next, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }

    if (key.isChar('+') || key.isChar('=')) {
      _manualCooldownTicks = 8;
      final next = (m.progress.percent + 0.05).clamp(0.0, 1.0);
      final (p, c) = m.progress.setPercent(next, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    } else if (key.isChar('-') || key.isChar('_')) {
      _manualCooldownTicks = 8;
      final next = (m.progress.percent - 0.05).clamp(0.0, 1.0);
      final (p, c) = m.progress.setPercent(next, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }

    return false;
  }
}
