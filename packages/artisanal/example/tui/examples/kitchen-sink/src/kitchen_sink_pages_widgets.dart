part of 'kitchen_sink.dart';

final class _WidgetsPage extends _KitchenSinkPage {
  _WidgetsPage()
    : _pane = tui.ViewportScrollPane(
        viewport: tui.ViewportModel(width: 0, height: 0, horizontalStep: 4),
      ),
      _confirmToggle = tui.ConfirmModel(
        prompt: 'Continue?',
        displayMode: tui.ConfirmDisplayMode.toggle,
        showHelp: true,
      ),
      _confirmHint = tui.ConfirmModel(
        prompt: 'Continue?',
        displayMode: tui.ConfirmDisplayMode.hint,
        showHelp: false,
      ),
      _confirmInline = tui.ConfirmModel(
        prompt: 'Continue?',
        displayMode: tui.ConfirmDisplayMode.inline,
        showHelp: false,
      ),
      _destructive = tui.DestructiveConfirmModel(
        prompt: 'Type DELETE to confirm:',
        confirmText: 'DELETE',
        showHelp: true,
      ),
      _password = tui.PasswordModel(
        prompt: 'Password: ',
        echoMode: tui.PasswordEchoMode.mask,
        showHelp: true,
      ),
      _anticipate = tui.AnticipateModel(
        prompt: 'pkg: ',
        placeholder: 'type to search…',
        suggestions: const [
          'artisanal',
          'ultraviolet',
          'lipgloss',
          'bubbletea',
          'bubbles',
          'markdown',
          'http',
          'path',
        ],
        defaultValue: '',
      ),
      _select = tui.SelectModel<String>(
        title: 'Choose a color:',
        items: const ['Red', 'Green', 'Blue', 'Indigo', 'Teal', 'Rose'],
        height: 8,
      ),
      _search = tui.SearchModel<String>(
        title: 'Search files:',
        items: const [
          'pubspec.yaml',
          'README.md',
          'lib/src/tui/program.dart',
          'lib/src/uv/decoder.dart',
          'example/tui/examples/kitchen-sink/main.dart',
          'test/tui/uv_keypad_mapping_test.dart',
        ],
        height: 9,
      ),
      _list = tui.ListModel(
        title: 'Packages',
        items: const [
          'artisanal',
          'ultraviolet',
          'lipgloss',
          'chalkdart',
          'characters',
          'path',
          'args',
          'collection',
          'test',
        ].map(tui.StringItem.new).toList(growable: false),
        width: 72,
        height: 12,
        filteringEnabled: true,
        showHelp: true,
        showPagination: true,
      ),
      _tableModel = tui.TableModel(
        width: 72,
        height: 8,
        columns: [
          tui.Column(title: 'Widget', width: 16),
          tui.Column(title: 'Status', width: 10),
          tui.Column(title: 'Notes', width: 42),
        ],
        rows: const [
          ['Viewport', 'OK', 'scroll + wheel + drag'],
          ['List', 'OK', 'filter + paging'],
          ['Select', 'OK', 'single selection'],
          ['Search', 'OK', 'query + highlight'],
          ['Confirm', 'OK', 'toggle/hint/inline'],
          ['FilePicker', 'OK', 'directory browsing'],
        ],
      ),
      _viewportPreview = tui.ViewportModel(width: 60, height: 4)
          .setContent(List.generate(20, (i) => 'line ${i + 1}').join('\n'))
          .setYOffset(6),
      _timer = tui.TimerModel(timeout: const Duration(minutes: 2, seconds: 34)),
      _stopwatch = tui.StopwatchModel(),
      _pause = tui.PauseModel(message: 'Press any key to continue…'),
      _countdown = tui.CountdownModel(duration: const Duration(seconds: 10)),
      _filePicker = tui.FilePickerModel(
        currentDirectory: io.Directory.current.path,
        dirAllowed: true,
        fileAllowed: true,
        showHidden: false,
        height: 12,
      ),
      super(
        help:
            'Widgets: click a panel to focus; Esc unfocus; when unfocused you can scroll/drag the scrollbar',
      );

  final tui.ViewportScrollPane _pane;
  final tui.ConfirmModel _confirmToggle;
  final tui.ConfirmModel _confirmHint;
  final tui.ConfirmModel _confirmInline;
  tui.DestructiveConfirmModel _destructive;
  tui.PasswordModel _password;
  tui.AnticipateModel _anticipate;
  tui.SelectModel<String> _select;
  tui.SearchModel<String> _search;
  tui.ListModel _list;
  tui.TableModel _tableModel;
  tui.ViewportModel _viewportPreview;
  tui.TimerModel _timer;
  tui.StopwatchModel _stopwatch;
  final tui.PauseModel _pause;
  tui.CountdownModel _countdown;
  tui.FilePickerModel _filePicker;
  bool _filePickerInitSent = false;

  _WidgetsFocus _focus = _WidgetsFocus.none;
  bool _liveTextArea = false;
  final List<_PanelRange> _panelRanges = <_PanelRange>[];

  @override
  void onActivate(_KitchenSinkModel m, List<tui.Cmd> cmds) {
    if (_filePickerInitSent) return;
    _filePickerInitSent = true;
    final c = _filePicker.init();
    if (c != null) cmds.add(c);
  }

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Widgets showcase');

    final paginator = tui.PaginatorModel(
      type: tui.PaginationType.dots,
    ).setTotalPages(12).copyWith(page: 3);

    final helpShort = tui.HelpModel(width: 72).view(tui.ViewportKeyMap());
    final helpFull = tui.HelpModel(
      width: 72,
      showAll: true,
    ).view(tui.TableKeyMap());

    final status = [
      '${m.spinner.view()}  spinner',
      m.progress.view(),
      '',
      m
          ._style(Style())
          .dim()
          .render(
            _focus == _WidgetsFocus.live
                ? 'focused: ${_liveTextArea ? 'TextArea' : 'TextInput'} (press i to toggle)'
                : 'click this panel to edit; Esc to unfocus',
          ),
      '',
      m._style(Style()).dim().render('TextInput:'),
      m.textInput.view(),
      '',
      m._style(Style()).dim().render('TextArea:'),
      m.textarea.view(),
    ].join('\n');

    final panels = <({String text, _WidgetsFocus focus})>[
      (
        text: _box(m, 'Live (shared state)', status, focus: _WidgetsFocus.live),
        focus: _WidgetsFocus.live,
      ),
      (
        text: _box(
          m,
          'Paginator + Help',
          [
            paginator.view(),
            m._style(Style()).dim().render('short help:'),
            helpShort,
            m._style(Style()).dim().render('full help:'),
            helpFull,
          ].join('\n'),
          focus: _WidgetsFocus.help,
        ),
        focus: _WidgetsFocus.help,
      ),
      (
        text: _box(
          m,
          'Confirm',
          Layout.joinHorizontal(VerticalAlign.top, [
            _confirmToggle.view(),
            '  ',
            [_confirmHint.view(), _confirmInline.view()].join('\n'),
          ]),
          focus: _WidgetsFocus.confirm,
        ),
        focus: _WidgetsFocus.confirm,
      ),
      (
        text: _box(
          m,
          'Destructive confirm',
          _destructive.view(),
          focus: _WidgetsFocus.destructive,
        ),
        focus: _WidgetsFocus.destructive,
      ),
      (
        text: _box(
          m,
          'Password',
          _password.view(),
          focus: _WidgetsFocus.password,
        ),
        focus: _WidgetsFocus.password,
      ),
      (
        text: _box(
          m,
          'Anticipate (autocomplete)',
          _anticipate.view(),
          focus: _WidgetsFocus.anticipate,
        ),
        focus: _WidgetsFocus.anticipate,
      ),
      (
        text: _box(m, 'Select', _select.view(), focus: _WidgetsFocus.select),
        focus: _WidgetsFocus.select,
      ),
      (
        text: _box(m, 'Search', _search.view(), focus: _WidgetsFocus.search),
        focus: _WidgetsFocus.search,
      ),
      (
        text: _box(m, 'List', _list.view(), focus: _WidgetsFocus.list),
        focus: _WidgetsFocus.list,
      ),
      (
        text: _box(
          m,
          'TableModel',
          _tableModel.view(),
          focus: _WidgetsFocus.table,
        ),
        focus: _WidgetsFocus.table,
      ),
      (
        text: _box(
          m,
          'ViewportModel',
          [
            _viewportPreview.view(),
            m
                ._style(Style())
                .dim()
                .render(
                  'scroll=${(_viewportPreview.scrollPercent * 100).round()}% (focus this panel to use j/k)',
                ),
          ].join('\n'),
          focus: _WidgetsFocus.viewport,
        ),
        focus: _WidgetsFocus.viewport,
      ),
      (
        text: _box(
          m,
          'FilePicker',
          _filePicker.view(),
          focus: _WidgetsFocus.filePicker,
        ),
        focus: _WidgetsFocus.filePicker,
      ),
      (
        text: _box(
          m,
          'Timer + Stopwatch + Pause',
          [
            'Timer: ${_timer.view()}',
            'Stopwatch: ${_stopwatch.view()}',
            _pause.view(),
            _countdown.view(),
          ].join('\n'),
          focus: _WidgetsFocus.timer,
        ),
        focus: _WidgetsFocus.timer,
      ),
    ];

    _panelRanges.clear();
    var lineCursor = 0;
    final renderedPanels = <String>[];
    for (var i = 0; i < panels.length; i++) {
      final p = panels[i];
      final panelLines = p.text.split('\n');
      final lines = panelLines.length;
      var maxCols = 0;
      for (final l in panelLines) {
        maxCols = math.max(maxCols, Style.visibleLength(l));
      }
      _panelRanges.add(
        _PanelRange(
          focus: p.focus,
          startLine: lineCursor,
          endLine: lineCursor + lines,
          endCol: maxCols,
        ),
      );
      renderedPanels.add(p.text);
      lineCursor += lines;
      if (i != panels.length - 1) {
        lineCursor += 1; // join('\n\n') adds exactly 1 blank line
      }
    }
    final columns = renderedPanels.join('\n\n');

    final topRow0 = m._headerLines + 2;
    final contentHeight = (m._height - m._headerLines - m._footerLines - 1)
        .clamp(0, 9999);
    final bodyHeight = (contentHeight - 2).clamp(1, 9999);

    final viewportWidth = (m._width - 2).clamp(10, 9999);
    _pane.viewport = _pane.viewport.copyWith(
      width: viewportWidth,
      height: bodyHeight,
    );
    _pane.viewport = _pane.viewport.setContent(columns);
    _pane.originX = 0;
    _pane.originY = topRow0;

    final pane = _pane.view();

    return [title, '', pane].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    if (key.isEscape) {
      _focus = _WidgetsFocus.none;
      return true;
    }

    if (_focus == _WidgetsFocus.none) {
      final (_, cmd) = _pane.update(tui.KeyMsg(key));
      if (cmd != null) cmds.add(cmd);
      return false;
    }

    if (_focus == _WidgetsFocus.live && key.isChar('i')) {
      _liveTextArea = !_liveTextArea;
      if (_liveTextArea) {
        final c = m.textarea.focus();
        if (c != null) cmds.add(c);
      } else {
        final c = m.textInput.focus();
        if (c != null) cmds.add(c);
      }
      return true;
    }

    switch (_focus) {
      case _WidgetsFocus.live:
        if (_liveTextArea) {
          final (next, cmd) = m.textarea.update(tui.KeyMsg(key));
          m.textarea.value = next.value;
          if (cmd != null) cmds.add(cmd);
        } else {
          final (next, cmd) = m.textInput.update(tui.KeyMsg(key));
          m.textInput.value = next.value;
          if (cmd != null) cmds.add(cmd);
        }
        return true;
      case _WidgetsFocus.confirm:
        final (cm, cmd) = _confirmToggle.update(tui.KeyMsg(key));
        // ConfirmModel is mutable-ish internally; keep reference.
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.destructive:
        final (dm, cmd) = _destructive.update(tui.KeyMsg(key));
        _destructive = dm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.password:
        final (pm, cmd) = _password.update(tui.KeyMsg(key));
        _password = pm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.anticipate:
        final (am, cmd) = _anticipate.update(tui.KeyMsg(key));
        _anticipate = am;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.select:
        final (sm, cmd) = _select.update(tui.KeyMsg(key));
        _select = sm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.search:
        final (sm, cmd) = _search.update(tui.KeyMsg(key));
        _search = sm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.list:
        final (lm, cmd) = _list.update(tui.KeyMsg(key));
        _list = lm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.table:
        final (tm, cmd) = _tableModel.update(tui.KeyMsg(key));
        _tableModel = tm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.viewport:
        final (vp, cmd) = _viewportPreview.update(tui.KeyMsg(key));
        _viewportPreview = vp;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.filePicker:
        final (fp, cmd) = _filePicker.update(tui.KeyMsg(key));
        _filePicker = fp;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.timer:
        // Preview only (no interactive controls wired yet).
        return true;
      case _WidgetsFocus.help:
      case _WidgetsFocus.none:
        return false;
    }
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    if (msg is tui.MouseMsg) {
      final consumed = _pane.consumesMouse(msg);
      final (_, cmd) = _pane.update(msg);
      if (cmd != null) cmds.add(cmd);
      if (consumed) return;

      if (msg.button == tui.MouseButton.left &&
          msg.action == tui.MouseAction.press) {
        // Click-to-focus (sticky until Esc).
        _focus = _focusForMouseLine(msg);
        return;
      }

      if (msg.button == tui.MouseButton.none &&
          msg.action == tui.MouseAction.motion) {
        // Hover-to-focus (matches "mouse focus" behavior). Keep click-to-focus
        // sticky: once a widget is focused, don't change focus on hover.
        if (_focus == _WidgetsFocus.none) {
          _focus = _focusForMouseLine(msg);
        }
        return;
      }

      return;
    }

    // Route non-key background messages to embedded widgets so they can process
    // their own async/tick events.
    if (msg is tui.KeyMsg) return;

    {
      final (lm, cmd) = _list.update(msg);
      _list = lm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (sm, cmd) = _search.update(msg);
      _search = sm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (fp, cmd) = _filePicker.update(msg);
      _filePicker = fp;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (vp, cmd) = _viewportPreview.update(msg);
      _viewportPreview = vp;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (dm, cmd) = _destructive.update(msg);
      _destructive = dm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (pm, cmd) = _password.update(msg);
      _password = pm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (am, cmd) = _anticipate.update(msg);
      _anticipate = am;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (sm, cmd) = _select.update(msg);
      _select = sm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (tm, cmd) = _tableModel.update(msg);
      _tableModel = tm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (tm, cmd) = _timer.update(msg);
      _timer = tm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (sw, cmd) = _stopwatch.update(msg);
      _stopwatch = sw;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (cd, cmd) = _countdown.update(msg);
      _countdown = cd;
      if (cmd != null) cmds.add(cmd);
    }
  }

  _WidgetsFocus _focusForMouseLine(tui.MouseMsg msg) {
    final pos = _pane.contentPosAtMouse(msg);
    if (pos == null) return _WidgetsFocus.none;
    final (line, col) = pos;
    final hit = _panelRanges.firstWhere(
      (r) => line >= r.startLine && line < r.endLine && col < r.endCol,
      orElse: () => const _PanelRange(
        focus: _WidgetsFocus.none,
        startLine: -1,
        endLine: -1,
        endCol: 0,
      ),
    );
    return hit.focus;
  }
}

enum _WidgetsFocus {
  none,
  live,
  help,
  confirm,
  destructive,
  password,
  anticipate,
  select,
  search,
  list,
  table,
  viewport,
  filePicker,
  timer,
}

final class _PanelRange {
  const _PanelRange({
    required this.focus,
    required this.startLine,
    required this.endLine,
    required this.endCol,
  });

  final _WidgetsFocus focus;
  final int startLine;
  final int endLine;
  final int endCol;
}

String _box(
  _KitchenSinkModel m,
  String heading,
  String body, {
  required _WidgetsFocus focus,
}) {
  final focused =
      m._activePage is _WidgetsPage &&
      (m._activePage as _WidgetsPage)._focus == focus &&
      focus != _WidgetsFocus.none;

  final base = m._style(Style()).border(Border.rounded).padding(0, 1);
  final style = focused
      ? (base..borderForeground(Colors.yellow))
      : (base
          ..borderForegroundBlend([Colors.rose, Colors.indigo, Colors.teal])
          ..borderForegroundBlendOffset(2));

  final h = m._style(Style()).bold().render(heading);
  return style.render([h, '', body].join('\n'));
}

final class _NeofetchPage extends _KitchenSinkPage {
  const _NeofetchPage()
    : super(help: 'Neofetch: static-ish system summary (no external commands)');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Neofetch (demo)');

    final user = io.Platform.environment['USER'] ?? 'user';
    final host = io.Platform.localHostname;
    final header = m
        ._style(Style())
        .bold()
        .foreground(Colors.lime)
        .render('$user@$host');
    final underline = m
        ._style(Style())
        .dim()
        .render('-' * math.min(Style.visibleLength('$user@$host'), 28));

    final os =
        _readOsPrettyName() ??
        '${io.Platform.operatingSystem} ${io.Platform.operatingSystemVersion}'
            .trim();
    final kernel =
        _extractKernel(io.Platform.operatingSystemVersion) ??
        io.Platform.operatingSystemVersion;
    final shell = (io.Platform.environment['SHELL'] ?? '').split('/').last;
    final term = io.Platform.environment['TERM'] ?? '(unknown)';
    final uptime = _readUptimePretty() ?? '(unknown)';
    final mem = _readMemPretty() ?? '(unknown)';

    String kv(String k, String v) {
      final key = m
          ._style(Style())
          .bold()
          .foreground(Colors.lime)
          .render('$k:');
      return '$key $v';
    }

    final infoLines = <String>[
      header,
      underline,
      kv('OS', os),
      kv('Kernel', kernel),
      kv('Uptime', uptime),
      kv('Shell', shell.isEmpty ? '(unknown)' : shell),
      kv('Terminal', term),
      kv('Resolution', '${m._width}x${m._height} (cells)'),
      kv('TuiRenderer', m.useUvRenderer ? 'uv' : 'default'),
      kv('Input', m.useUvInput ? 'uv' : 'legacy'),
      kv('Memory', mem),
      '',
      _colorSwatches(m),
    ].join('\n');

    final logo = _neofetchLogo(m);
    final columns = Layout.joinHorizontal(VerticalAlign.top, [
      logo,
      '  ',
      infoLines,
    ]);

    return [title, '', columns].join('\n');
  }
}

final class _GraphicsPage extends _KitchenSinkPage {
  const _GraphicsPage()
    : super(help: 'Graphics: demonstrates Kitty/iTerm2/Sixel image support');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Graphics (Image Protocols)');

    final caps = m.capabilities;
    final best = uv.Terminal.bestImageDrawable(
      img.Image(width: 1, height: 1),
      capabilities: caps,
    );

    final protocolName = switch (best.runtimeType.toString()) {
      'KittyImageDrawable' => 'Kitty Graphics Protocol',
      'ITerm2ImageDrawable' => 'iTerm2 Inline Images',
      'SixelImageDrawable' => 'Sixel Graphics',
      _ => 'None (Fallback to ASCII)',
    };

    return [
      title,
      '',
      'Your terminal supports the following image protocols:',
      '',
      '  Kitty Graphics: ${caps.hasKittyGraphics ? "✅" : "❌"}',
      '  iTerm2 Images:  ${caps.hasITerm2 ? "✅" : "❌"}',
      '  Sixel Graphics: ${caps.hasSixel ? "✅" : "❌"}',
      '',
      'Best available: $protocolName',
      '',
      'Note: To see real images, check out the dedicated image demos:',
      '  - example/compositor_image_demo.dart',
      '  - example/uv/image.dart',
    ].join('\n');
  }
}

final class _CapabilitiesPage extends _KitchenSinkPage {
  const _CapabilitiesPage()
    : super(help: 'Capabilities: shows detected terminal features');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Terminal Capabilities');

    final caps = m.capabilities;

    String boolIcon(bool b) => b ? '✅' : '❌';

    final rows = [
      ['Kitty Graphics', boolIcon(caps.hasKittyGraphics)],
      ['Sixel Graphics', boolIcon(caps.hasSixel)],
      ['iTerm2 Images', boolIcon(caps.hasITerm2)],
      ['Keyboard Protocol', boolIcon(caps.hasKeyboardEnhancements)],
      ['Color Palette', boolIcon(caps.hasColorPalette)],
      ['Background Color', boolIcon(caps.hasBackgroundColor)],
    ];

    final table = tui.Table()
      ..border(Border.rounded)
      ..style(m._style(Style()).foreground(Colors.cyan))
      ..headerStyle(m._style(Style()).bold())
      ..headers(['Feature', 'Supported'])
      ..rows(rows);

    final details = [
      'Terminal: ${io.Platform.environment['TERM'] ?? 'unknown'}',
      'Program: ${io.Platform.environment['TERM_PROGRAM'] ?? 'unknown'}',
      '',
      'These capabilities are discovered via ANSI queries (DA1, DA2, etc.)',
      'and environment variable hints.',
    ].join('\n');

    return [title, '', table.render(), '', details].join('\n');
  }
}

final class _KeyboardPage extends _KitchenSinkPage {
  const _KeyboardPage()
    : super(help: 'Keyboard: demonstrates enhanced keyboard protocol');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Keyboard Enhancements');

    final caps = m.capabilities;

    final info = [
      'Enhanced Protocol: ${caps.hasKeyboardEnhancements ? "Enabled ✅" : "Disabled ❌"}',
      '',
      'If enabled, you can detect:',
      '- Release events (KeyUp)',
      '- Modifier keys (Super, Hyper, Meta)',
      '- Distinguish between Esc and Alt+key',
      '',
      'Try pressing keys with various modifiers!',
    ].join('\n');

    final logTitle = m._style(Style()).bold().render('Recent Events:');
    final log = m._eventLog.reversed.take(10).join('\n');

    return [title, '', info, '', logTitle, log].join('\n');
  }
}

final class _ListSelectionState {
  const _ListSelectionState({
    required this.items,
    required this.cursor,
    required this.selected,
  });

  factory _ListSelectionState.initial() => const _ListSelectionState(
    items: [
      _EmojiItem(emoji: '🍕', fallback: '[P]', label: 'Pizza'),
      _EmojiItem(emoji: '🍔', fallback: '[B]', label: 'Burger'),
      _EmojiItem(emoji: '🌮', fallback: '[T]', label: 'Tacos'),
      _EmojiItem(emoji: '🍜', fallback: '[R]', label: 'Ramen'),
      _EmojiItem(emoji: '🥗', fallback: '[S]', label: 'Salad'),
      _EmojiItem(emoji: '🍣', fallback: '[S]', label: 'Sushi'),
      _EmojiItem(emoji: '🥪', fallback: '[S]', label: 'Sandwich'),
      _EmojiItem(emoji: '🍝', fallback: '[P]', label: 'Pasta'),
    ],
    cursor: 0,
    selected: null,
  );

  final List<_EmojiItem> items;
  final int cursor;
  final String? selected;

  (_ListSelectionState, tui.Cmd?) update(tui.Key key) {
    return switch (key) {
      _ when key.type == tui.KeyType.up || key.isChar('k') => (
        copyWith(cursor: (cursor - 1).clamp(0, items.length - 1)),
        null,
      ),

      _ when key.type == tui.KeyType.down || key.isChar('j') => (
        copyWith(cursor: (cursor + 1).clamp(0, items.length - 1)),
        null,
      ),

      _ when key.isAccept => (copyWith(selected: items[cursor].label), null),

      _ when key.isChar('r') => (_ListSelectionState.initial(), null),

      _ => (this, null),
    };
  }

  _ListSelectionState copyWith({int? cursor, String? selected}) {
    return _ListSelectionState(
      items: items,
      cursor: cursor ?? this.cursor,
      selected: selected ?? this.selected,
    );
  }

  String view(_KitchenSinkModel m) {
    final buf = StringBuffer();
    buf.writeln();
    buf.writeln('  What would you like?');
    buf.writeln();

    for (var i = 0; i < items.length; i++) {
      final isSelected = i == cursor;
      final prefix = isSelected ? '▸ ' : '  ';
      final item = items[i];
      final icon = m.emoji(item.emoji, item.fallback);
      final line = '  $prefix$icon ${item.label}';
      buf.writeln(
        isSelected
            ? Style().foreground(const BasicColor('14')).render(line)
            : line,
      );
    }

    buf.writeln();
    buf.writeln(
      Style().dim().render('  ↑/k: up • ↓/j: down • Enter: select • r: reset'),
    );
    return buf.toString();
  }
}

final class _EmojiItem {
  const _EmojiItem({
    required this.emoji,
    required this.fallback,
    required this.label,
  });

  final String emoji;
  final String fallback;
  final String label;
}

String _clipToWidth(String s, int maxWidth) {
  if (maxWidth <= 0) return '';
  if (Style.visibleLength(s) <= maxWidth) return s;

  var w = 0;
  final out = StringBuffer();
  for (final g in uni.graphemes(s)) {
    final gw = Style.visibleLength(g);
    if (w + gw > maxWidth) break;
    out.write(g);
    w += gw;
  }
  return out.toString();
}

String _neofetchLogo(_KitchenSinkModel m) {
  final s = m._style(Style());
  final a = s.copy()..background(const BasicColor('#a8b85b'));
  final b = s.copy()..background(const BasicColor('#6d7a2b'));

  String block(Style bg, int w) => bg.render(' ' * w);

  final w = 12;
  final rows = <String>[
    '${block(a, w)}${block(a, w)}',
    '${block(a, w)}${block(a, w)}',
    '${block(a, w)}${block(b, 3)}${block(a, w - 3)}${block(a, w)}',
    '${block(a, w)}${block(b, 3)}${block(a, w - 3)}${block(a, w)}',
    '${block(a, w)}${block(b, 3)}${block(a, w - 3)}${block(a, w)}',
    '${block(a, w)}${block(a, w)}',
    '${block(a, w)}${block(a, w)}',
  ];

  return rows.join('\n');
}

String _colorSwatches(_KitchenSinkModel m) {
  final s = m._style(Style());
  final colors = <Color>[
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue,
    Colors.magenta,
    Colors.cyan,
    Colors.white,
  ];
  final top = colors.map((c) => (s.copy()..background(c)).render('   ')).join();
  final dim = colors
      .map(
        (c) =>
            (s.copy()
                  ..background(c)
                  ..dim())
                .render('   '),
      )
      .join();
  return '$dim\n$top';
}

String? _readOsPrettyName() {
  try {
    final f = io.File('/etc/os-release');
    if (!f.existsSync()) return null;
    final lines = f.readAsLinesSync();
    for (final line in lines) {
      if (!line.startsWith('PRETTY_NAME=')) continue;
      var v = line.substring('PRETTY_NAME='.length).trim();
      v = v.replaceAll('"', '');
      return v.isEmpty ? null : v;
    }
  } catch (_) {
    // ignore
  }
  return null;
}

String? _extractKernel(String osVersion) {
  final m = RegExp(r'(\\d+\\.\\d+\\.\\d+[^\\s)]*)').firstMatch(osVersion);
  return m?.group(1);
}

String? _readUptimePretty() {
  try {
    final f = io.File('/proc/uptime');
    if (!f.existsSync()) return null;
    final parts = f.readAsStringSync().trim().split(' ');
    if (parts.isEmpty) return null;
    final seconds = double.tryParse(parts.first);
    if (seconds == null) return null;
    final total = seconds.round();
    final days = total ~/ 86400;
    final hours = (total % 86400) ~/ 3600;
    final mins = (total % 3600) ~/ 60;
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'}, $hours hour${hours == 1 ? '' : 's'}, $mins min';
    }
    if (hours > 0) return '$hours hour${hours == 1 ? '' : 's'}, $mins min';
    return '$mins min';
  } catch (_) {
    return null;
  }
}

String? _readMemPretty() {
  try {
    final f = io.File('/proc/meminfo');
    if (!f.existsSync()) return null;
    int? totalKb;
    int? availKb;
    for (final line in f.readAsLinesSync()) {
      if (line.startsWith('MemTotal:')) {
        totalKb = int.tryParse(line.split(RegExp(r'\\s+'))[1]);
      } else if (line.startsWith('MemAvailable:')) {
        availKb = int.tryParse(line.split(RegExp(r'\\s+'))[1]);
      }
      if (totalKb != null && availKb != null) break;
    }
    if (totalKb == null || availKb == null) return null;
    final usedKb = (totalKb - availKb).clamp(0, totalKb);
    String mib(int kb) => (kb / 1024).round().toString();
    return '${mib(usedKb)}MiB / ${mib(totalKb)}MiB';
  } catch (_) {
    return null;
  }
}

class _LipglossV2Page extends _KitchenSinkPage {
  const _LipglossV2Page() : super(help: 'Lipgloss v2 parity features');

  @override
  String view(_KitchenSinkModel model) {
    final buffer = StringBuffer();

    final titleStyle = Style().bold().foreground(Colors.success);
    final labelStyle = Style().foreground(Colors.muted).width(20);

    buffer.writeln(titleStyle.render('Lipgloss v2 Parity Features'));
    buffer.writeln();

    // 1. Underline Color
    final ulColorStyle = Style()
        .underline()
        .underlineStyle(.curly)
        .underlineColor(Colors.error)
        .bold();
    buffer.writeln(
      '${labelStyle.render('Underline Color:')} ${ulColorStyle.render('Curly red underline on bold text')}',
    );
    buffer.writeln(
      '${labelStyle.render('Underline Stress:')} '
      '${Style().underline().underlineColor(Colors.error).render('single')}  '
      '${Style().underlineStyle(.double).underline().underlineColor(Colors.warning).render('double')}  '
      '${Style().underlineStyle(.dotted).underline().underlineColor(Colors.info).render('dotted')}  '
      '${Style().underlineStyle(.dashed).underline().underlineColor(Colors.success).render('dashed')}',
    );
    buffer.writeln(
      '${labelStyle.render('Underline 256:')} '
      '${Style().underlineStyle(.curly).underline().underlineColor(const AnsiColor(196)).render('idx196')}  '
      '${Style().underlineStyle(.curly).underline().underlineColor(const AnsiColor(21)).render('idx21')}',
    );
    buffer.writeln(
      '${labelStyle.render('Underline RGB:')} '
      '${Style().underlineStyle(.curly).underline().underlineColor(const BasicColor('#ff0000')).render('#ff0000')}  '
      '${Style().underlineStyle(.curly).underline().underlineColor(const BasicColor('#00ff00')).render('#00ff00')}  '
      '${Style().underlineStyle(.curly).underline().underlineColor(const BasicColor('#0000ff')).render('#0000ff')}',
    );

    // 2. Padding Character
    final padCharStyle = Style()
        .background(Colors.muted)
        .padding(1, 2)
        .paddingChar('.')
        .foreground(Colors.white);
    buffer.writeln(
      '${labelStyle.render('Padding Char:')} ${padCharStyle.render('Dots as padding')}',
    );

    // 3. Margin Character & Background
    final marginStyle = Style()
        .background(Colors.success)
        .margin(1, 2)
        .marginChar('#')
        .marginBackground(Colors.warning)
        .foreground(Colors.white);
    buffer.writeln(labelStyle.render('Margin Char/Bg:'));
    buffer.writeln(
      marginStyle.render('Styled box with hash margins on yellow background'),
    );

    // 4. Underline Spaces
    final ulSpacesStyle = Style().underline().underlineSpaces(true);
    final noUlSpacesStyle = Style().underline().underlineSpaces(false);
    buffer.writeln(
      '${labelStyle.render('Underline Spaces:')} ${ulSpacesStyle.render('Underlined  Spaces')} vs ${noUlSpacesStyle.render('No  Underlined  Spaces')}',
    );

    // 5. Strikethrough Spaces
    final stSpacesStyle = Style().strikethrough().strikethroughSpaces(true);
    final noStSpacesStyle = Style().strikethrough().strikethroughSpaces(false);
    buffer.writeln(
      '${labelStyle.render('Strikethrough Spaces:')} ${stSpacesStyle.render('Strikethrough  Spaces')} vs ${noStSpacesStyle.render('No  Strikethrough  Spaces')}',
    );

    // 6. Faint & Reverse Aliases
    final faintStyle = Style().faint();
    final reverseStyle = Style().reverse();
    buffer.writeln(
      '${labelStyle.render('Faint/Reverse:')} ${faintStyle.render('Faint text')} and ${reverseStyle.render('Reverse text')}',
    );

    // 7. Multi-string Render
    final multiStyle = Style().bold().foreground(Colors.warning);
    buffer.writeln(
      '${labelStyle.render('Multi-string Render:')} ${multiStyle.render(['Joined', 'with', 'spaces'])}',
    );

    // 7b. A noisy ANSI line to stress state transitions in the UV renderer.
    final ulA = Style().underline().underlineColor(Colors.error);
    final ulB = Style()
        .underlineStyle(.curly)
        .underline()
        .underlineColor(Colors.warning);
    final ulC = Style()
        .underlineStyle(.dotted)
        .underline()
        .underlineColor(Colors.info);
    buffer.writeln(
      '${labelStyle.render('ANSI Stress:')} '
      '${ulA.render('A')}'
      '${Style().bold().render('B')}'
      '${ulB.render('C')}'
      '${Style().italic().render('D')}'
      '${ulC.render('E')}'
      '${Style().render('F')}',
    );

    // 8. tui.Table BaseStyle
    final baseStyle = Style().foreground(Colors.muted).italic();
    final table = tui.Table()
        .headers(['Feature', 'Status'])
        .row(['BaseStyle', 'Inherited'])
        .row(['StyleFunc', 'Overrides'])
        .baseStyle(baseStyle)
        .styleFunc((row, col, data) {
          if (data == 'Overrides') {
            return Style().foreground(Colors.success).bold().unsetItalic();
          }
          return null;
        })
        .border(Border.rounded);

    buffer.writeln();
    buffer.writeln(titleStyle.render('tui.Table BaseStyle Inheritance'));
    buffer.writeln(table.render());

    return buffer.toString();
  }
}

final class _CompositorPage extends _KitchenSinkPage {
  const _CompositorPage()
    : super(
        help: 'uv.Compositor: demonstrates UV layering and canvas composition',
      );

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('UV uv.Compositor & Layering');

    // Create some styled content.
    final bgBox = Style()
        .background(Colors.muted)
        .width(40)
        .height(10)
        .render('');

    final foregroundBox = Style()
        .background(Colors.indigo)
        .foreground(Colors.white)
        .padding(1, 2)
        .border(Border.rounded)
        .render('I am a floating layer');

    final textLayer = uv.StyledString(
      m
          ._style(Style())
          .bold()
          .foreground(Colors.warning)
          .render('Topmost Text'),
    );

    // Build a composition.
    final comp = uv.Compositor([
      uv.Layer(uv.StyledString(bgBox)).setId('bg').setZ(0),
      uv.Layer(
        uv.StyledString(foregroundBox),
      ).setId('fg').setX(5).setY(2).setZ(10),
      uv.Layer(textLayer).setId('text').setX(15).setY(4).setZ(20),
    ]);

    final rendered = comp.render();

    final info = [
      '',
      'The uv.Compositor allows you to:',
      '- uv.Layer multiple [Drawable]s with Z-index',
      '- Position elements with X/Y offsets',
      '- Perform hit-testing (useful for mouse interaction)',
      '- Render to a [Canvas] for final output',
      '',
      'Composition Result:',
      rendered,
    ].join('\n');

    return [title, info].join('\n');
  }
}

final class _SelectionPage extends _KitchenSinkPage {
  const _SelectionPage()
    : super(
        help:
            'Selection: Click and drag to select text in any component below. Press Ctrl+C to copy.',
      );

  @override
  void onActivate(_KitchenSinkModel m, List<tui.Cmd> cmds) {
    if (m.viewport.lines.isEmpty) {
      m.viewport = m.viewport.setContent('''
Text Selection Demo
===================

This page demonstrates the new text selection and clipboard features.

1. Viewport Selection:
   You can click and drag anywhere in this scrollable area to select text.
   Once selected, press 'Ctrl+C' or 'y' to copy it to your system clipboard.

2. Multi-line TextArea:
   The box below is a TextArea. It supports multi-line selection,
   soft-wrapping, and standard editing shortcuts.

3. Single-line TextInput:
   The search box at the bottom also supports selection.

Try selecting this paragraph and copying it!
The selection will persist even if you scroll the viewport.
''');
    }

    if (m.text.lines.isEmpty) {
      m.text = m.text.setContent('''
4. Text Component (Auto-height):
   This is a TextModel component. It is built on top of ViewportModel
   but defaults to auto-height (no scrolling) and soft-wrapping.
   It also supports selection and copying just like the Viewport.
''');
    }
  }

  @override
  String view(_KitchenSinkModel m) {
    final out = <String>[];

    out.add(
      m._style(Style()).bold().render('1. Viewport (Scrollable & Selectable)'),
    );
    final vpTop = out.length;
    out.addAll(m.viewport.view().split('\n'));
    out.add('');

    out.add(m._style(Style()).bold().render('2. TextArea (Multi-line Input)'));
    final taTop = out.length;
    out.addAll((m.textarea.view() as String).split('\n'));
    out.add('');

    out.add(
      m._style(Style()).bold().render('3. TextInput (Single-line Input)'),
    );
    final tiTop = out.length;
    out.addAll((m.textInput.view() as String).split('\n'));
    out.add('');

    out.add(
      m._style(Style()).bold().render('4. Text (Auto-height & Selectable)'),
    );
    final txTop = out.length;
    out.addAll(m.text.view().split('\n'));
    out.add('');

    out.add(
      m
          ._style(Style())
          .dim()
          .render(
            'Tip: Use your mouse to select text. Press Ctrl+C to copy to clipboard.',
          ),
    );

    m._selectionLayout = _SelectionLayout(
      viewportTop: vpTop,
      textAreaTop: taTop,
      textInputTop: tiTop,
      textTop: txTop,
    );

    return out.join('\n');
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    var vpMsg = msg;
    var taMsg = msg;
    var tiMsg = msg;
    var txMsg = msg;

    if (msg is tui.MouseMsg) {
      final pageY = msg.y - m._headerLines;
      vpMsg = msg.copyWith(y: pageY - m._selectionLayout.viewportTop);
      taMsg = msg.copyWith(y: pageY - m._selectionLayout.textAreaTop);
      tiMsg = msg.copyWith(y: pageY - m._selectionLayout.textInputTop);
      txMsg = msg.copyWith(y: pageY - m._selectionLayout.textTop);
    }

    // Update Viewport
    final (newVp, vpCmd) = m.viewport.update(vpMsg);
    m.viewport = newVp;
    if (vpCmd != null) cmds.add(vpCmd);

    // Update TextArea
    final (_, taCmd) = m.textarea.update(taMsg);
    if (taCmd != null) cmds.add(taCmd);

    // Update TextInput
    final (_, tiCmd) = m.textInput.update(tiMsg);
    if (tiCmd != null) cmds.add(tiCmd);

    // Update Text
    final (newTx, txCmd) = m.text.update(txMsg);
    m.text = newTx;
    if (txCmd != null) cmds.add(txCmd);
  }
}
