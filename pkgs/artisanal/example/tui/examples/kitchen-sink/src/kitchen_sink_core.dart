/// Fullscreen kitchen-sink TUI.
///
/// A manual test app that exercises multiple subsystems in one place:
/// - UV input decoder vs legacy input
/// - UV renderer vs default renderer
/// - tree/list/table (lipgloss v2 parity surfaces)
/// - interactive list selection (Enter/Space handling)
/// - unicode width / grapheme cluster clipping
///
/// Options:
///   --legacy-input     Use the legacy KeyParser (default is UV decoder)
///   --uv-renderer      Use UV renderer (cell-buffer diff)

part of 'kitchen_sink.dart';

enum _Page {
  overview('Overview'),
  input('Input'),
  listSelect('List'),
  renderer('TuiRenderer'),
  lipgloss('tui.Tree/List/tui.Table'),
  colors('Colors'),
  writer('Writer'),
  unicode('Unicode'),
  widgets('Widgets'),
  neofetch('Neofetch'),
  graphics('Graphics'),
  capabilities('Capabilities'),
  keyboard('Keyboard'),
  lipglossV2('Lipgloss v2'),
  compositor('uv.Compositor'),
  selection('Selection');

  const _Page(this.title);
  final String title;
}

class _TickMsg extends tui.Msg {
  const _TickMsg();
}

class _KitchenSinkModel extends tui.Model {
  _KitchenSinkModel({required this.useUvInput, required this.useUvRenderer})
    : spinner = tui.SpinnerModel(spinner: tui.Spinners.miniDot),
      progress = tui.ProgressModel(width: 44, useGradient: true),
      textInput = tui.TextInputModel(prompt: 'search: ', width: 32),
      textarea = tui.TextAreaModel(width: 48, height: 6, prompt: ''),
      viewport = tui.ViewportModel(width: 60, height: 10),
      text = tui.TextModel(''),
      listSelection = _ListSelectionState.initial(),
      emojiEnabled = _defaultEmojiEnabled(io.Platform.environment),
      capabilities = uv.TerminalCapabilities(
        env: io.Platform.environment.entries
            .map((e) => '${e.key}=${e.value}')
            .toList(growable: false),
      );

  final bool useUvInput;
  final bool useUvRenderer;
  bool emojiEnabled;
  final uv.TerminalCapabilities capabilities;

  int _width = 80;
  int _height = 24;
  int _pageIndex = 0;
  bool _showHelp = true;
  int _headerLines = 4;
  int _footerLines = 0;

  tui.TerminalThemeState _theme = const tui.TerminalThemeState();

  tui.SpinnerModel spinner;
  tui.ProgressModel progress;
  final tui.TextInputModel textInput;
  final tui.TextAreaModel textarea;
  tui.ViewportModel viewport;
  tui.TextModel text;
  _SelectionLayout _selectionLayout = const _SelectionLayout();

  _ListSelectionState listSelection;
  final List<String> _eventLog = <String>[];
  final List<_TabHit> _tabHits = <_TabHit>[];
  int _tabLineCount = 1;

  late final Map<_Page, _KitchenSinkPage Function()> _pageFactories =
      <_Page, _KitchenSinkPage Function()>{
        _Page.overview: () => const _OverviewPage(),
        _Page.input: () => const _InputPage(),
        _Page.listSelect: () => const _ListSelectPage(),
        _Page.renderer: () => _RendererPage(),
        _Page.lipgloss: () => _LipglossPage(),
        _Page.colors: () => const _ColorsPage(),
        _Page.writer: () => const _WriterPage(),
        _Page.unicode: () => const _UnicodePage(),
        _Page.widgets: () => _WidgetsPage(),
        _Page.neofetch: () => const _NeofetchPage(),
        _Page.graphics: () => const _GraphicsPage(),
        _Page.capabilities: () => const _CapabilitiesPage(),
        _Page.keyboard: () => const _KeyboardPage(),
        _Page.lipglossV2: () => const _LipglossV2Page(),
        _Page.compositor: () => const _CompositorPage(),
        _Page.selection: () => const _SelectionPage(),
      };

  late final Map<_Page, _KitchenSinkPage> _pages = <_Page, _KitchenSinkPage>{
    _page: (_pageFactories[_page] ?? () => const _OverviewPage())(),
  };

  late _KitchenSinkPage _activePage = _pages[_page]!;

  _Page get _page => _Page.values[_pageIndex.clamp(0, _Page.values.length - 1)];

  int _wrapPageIndex(int i) {
    final len = _Page.values.length;
    var v = i % len;
    if (v < 0) v += len;
    return v;
  }

  void _setActivePage(
    int pageIndex,
    List<tui.Cmd> cmds, {
    required bool recreate,
  }) {
    _pageIndex = _wrapPageIndex(pageIndex);
    final page = _page;
    final factory = _pageFactories[page] ?? () => const _OverviewPage();
    if (recreate) {
      _pages[page] = factory();
    } else {
      _pages.putIfAbsent(page, factory);
    }
    _activePage = _pages[page]!;
    _activePage.onActivate(this, cmds);
  }

  void _log(String line) {
    _eventLog.add(line);
    if (_eventLog.length > 200) _eventLog.removeAt(0);
  }

  tui.Cmd _scheduleTick() {
    return tui.Cmd.tick(
      const Duration(milliseconds: 120),
      (_) => const _TickMsg(),
    );
  }

  static bool _defaultEmojiEnabled(Map<String, String> env) {
    final v = env['ARTESANAL_EMOJI'];
    if (v == '1' || v == 'true') return true;
    final nv = env['ARTESANAL_NO_EMOJI'] ?? env['NO_EMOJI'];
    if (nv == '1' || nv == 'true') return false;
    return true;
  }

  String emoji(String emoji, String fallback) =>
      emojiEnabled ? emoji : fallback;

  @override
  tui.Cmd? init() {
    final cmds = <tui.Cmd>[
      _scheduleTick(),
      spinner.tick(),
      tui.Cmd.enableReportFocus(),
      tui.Cmd.enableBracketedPaste(),
      tui.Cmd.enableMouseCellMotion(),
    ];
    _activePage.onActivate(this, cmds);
    if (useUvInput) {
      // Request background color so we can adapt styles to light/dark themes.
      cmds.add(tui.Cmd.requestBackgroundColorReport());
      // Capability probing (best-effort; replies arrive as UV events).
      cmds.add(
        tui.Cmd.writeRaw('\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\'),
      ); // Kitty graphics query
      cmds.add(
        tui.Cmd.writeRaw('\x1b[?u'),
      ); // Kitty keyboard enhancements query
      // Query a handful of palette entries (enough to know it's supported).
      for (var i = 0; i < 8; i++) {
        cmds.add(tui.Cmd.writeRaw('\x1b]4;$i;?\x1b\\'));
      }
    }
    final focus = textInput.focus();
    if (focus != null) cmds.add(focus);
    return tui.Cmd.batch(cmds);
  }

  Style _style([Style? base]) {
    final s = base ?? Style();
    s.hasDarkBackground = _theme.hasDarkBackground ?? true;
    return s;
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd>[];

    // Update shared widgets, but do not swallow the message: other widgets
    // (like ListModel's internal spinner) may also consume these.
    if (msg is tui.SpinnerTickMsg) {
      final (s, c) = spinner.update(msg);
      spinner = s;
      if (c != null) cmds.add(c);
    } else if (msg is tui.ProgressFrameMsg) {
      final (p, c) = progress.update(msg);
      progress = p;
      if (c != null) cmds.add(c);
    }

    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        _width = width;
        _height = height;
        return (this, null);

      case tui.BackgroundColorMsg(:final hex):
        _log('BackgroundColorMsg(hex: $hex)');
        _theme = _theme.update(msg);
        return (this, null);

      case tui.ForegroundColorMsg(:final hex):
        _log('ForegroundColorMsg(hex: $hex)');
        _theme = _theme.update(msg);
        return (this, null);

      case tui.CursorColorMsg(:final hex):
        _log('CursorColorMsg(hex: $hex)');
        _theme = _theme.update(msg);
        return (this, null);

      case _TickMsg():
        cmds.add(_scheduleTick());
        _activePage.onTick(this, cmds);
        return (this, tui.Cmd.batch(cmds));

      case tui.FocusMsg(:final focused):
        _log('FocusMsg(focused: $focused)');

      case tui.PasteMsg(:final content):
        _log(
          'PasteMsg(${content.length} bytes): ${content.replaceAll('\n', r'\n')}',
        );

      case tui.MouseMsg(
        :final action,
        :final button,
        :final x,
        :final y,
        :final ctrl,
        :final alt,
        :final shift,
      ):
        _log(
          'MouseMsg(action: $action, button: $button, x: $x, y: $y, ctrl: $ctrl, alt: $alt, shift: $shift)',
        );
        if (action == tui.MouseAction.press && button == tui.MouseButton.left) {
          final idx = _tabIndexAt(x, y);
          if (idx != null) {
            // Per request: only mouse-activated tabs create a fresh page
            // instance. Keyboard navigation keeps existing instances.
            _setActivePage(idx, cmds, recreate: true);
            return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
          }
        }

      case tui.KeyMsg(key: final key):
        // Global quits.
        if (key.matchesSingle(tui.CommonKeyBindings.quit) ||
            key.isEscape ||
            key.isCtrlC ||
            key.isChar('q')) {
          return (this, tui.Cmd.quit());
        }

        // Global help toggle.
        if (key.isChar('?') || (key.ctrl && key.char == 'h')) {
          _showHelp = !_showHelp;
          return (this, null);
        }

        // Give the active page first right of refusal on keys so focused
        // widgets can prevent global navigation shortcuts.
        final consumed = _activePage.onKey(this, key, cmds);

        // Emoji toggle for terminals without emoji fonts.
        if (!consumed && (key.isChar('e') || key.isChar('E'))) {
          emojiEnabled = !emojiEnabled;
          return (this, null);
        }

        // Global page navigation.
        if (!consumed && key.type == tui.KeyType.tab) {
          _setActivePage(
            _wrapPageIndex(_pageIndex + (key.shift ? -1 : 1)),
            cmds,
            recreate: false,
          );
          return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
        }
        if (!consumed &&
            key.type == tui.KeyType.runes &&
            key.runes.isNotEmpty) {
          final r = key.runes.first;
          // 1..9 jump to page; 0 jumps to 10th page (if present).
          if (r >= 0x31 && r <= 0x39) {
            final idx = (r - 0x31).clamp(0, _Page.values.length - 1);
            _setActivePage(idx, cmds, recreate: false);
            return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
          }
          if (r == 0x30 /* '0' */ && _Page.values.length >= 10) {
            _setActivePage(9, cmds, recreate: false);
            return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
          }
        }

      case tui.ClipboardMsg(:final selection, :final content):
        _log(
          'ClipboardMsg(selection: $selection, ${content.length} bytes): ${content.replaceAll('\n', r'\n')}',
        );

      case tui.UvEventMsg(:final event):
        _log('UvEventMsg(${event.runtimeType}): $event');
        if (event is uv.Event) {
          capabilities.updateFromEvent(event);
        }
    }

    _activePage.onMsg(this, msg, cmds);

    return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
  }

  int? _tabIndexAt(int x, int y) {
    // Header layout (0-based):
    // 0: title
    // 1: mode
    // 2: tabs
    // 3: divider
    const tabRow0 = 2;

    // Tolerate both 0-based and 1-based mouse coordinates.
    final candidates = <(int x, int y)>[
      (x, y),
      (x - 1, y),
      (x, y - 1),
      (x - 1, y - 1),
    ];

    for (final (cx, cy) in candidates) {
      if (cy < tabRow0 || cy >= tabRow0 + _tabLineCount) continue;
      final row = cy - tabRow0;
      for (final h in _tabHits) {
        if (h.row != row) continue;
        if (cx >= h.startX && cx < h.endX) return h.pageIndex;
      }
    }
    return null;
  }

  @override
  String view() {
    final header = _renderHeader();
    // Header line count (0-based mouse rows subtract this to get page-relative y).
    _headerLines = header.split('\n').length;

    final footer = _showHelp ? _renderHelp() : '';
    _footerLines = footer.isEmpty ? 0 : footer.split('\n').length;

    final body = _activePage.view(this);

    // Keep a small bottom margin for terminals that overwrite last line.
    return [header, body, footer, ''].where((s) => s.isNotEmpty).join('\n');
  }

  String _renderHeader() {
    _tabHits.clear();
    _tabLineCount = 1;

    final title = _style(Style()).bold().render('Kitchen Sink');
    final mode = _style(Style()).dim().render(
      'input=${useUvInput ? 'uv' : 'legacy'}  renderer=${useUvRenderer ? 'uv' : 'default'}  size=${_width}x$_height  bg=${_theme.backgroundHex ?? '(unknown)'}  dark=${_theme.hasDarkBackground ?? '(unknown)'}  emoji=${emojiEnabled ? 'on' : 'off'}',
    );

    final maxW = _width.clamp(10, 1000);
    const sep = ' ';
    const sepW = 1;

    final tabLines = <String>[];
    final lineParts = <String>[];
    var lineW = 0;
    var row = 0;

    void flushLine() {
      tabLines.add(lineParts.join(sep));
      lineParts.clear();
      lineW = 0;
    }

    for (var i = 0; i < _Page.values.length; i++) {
      final p = _Page.values[i];
      final active = i == _pageIndex;
      final label = '${i + 1}:${p.title}';
      final chip = active
          ? _style(Style())
                .foreground(const AnsiColor(16))
                .background(const AnsiColor(220))
                .padding(0, 1)
                .render(label)
          : _style(Style()).dim().padding(0, 1).render(label);

      final w = Style.visibleLength(chip);
      final needed = (lineParts.isEmpty ? 0 : sepW) + w;
      if (lineParts.isNotEmpty && lineW + needed > maxW) {
        flushLine();
        row++;
      }

      final startX = lineW + (lineParts.isEmpty ? 0 : sepW);
      _tabHits.add(
        _TabHit(pageIndex: i, row: row, startX: startX, endX: startX + w),
      );

      lineParts.add(chip);
      lineW += needed;
    }
    if (lineParts.isNotEmpty) flushLine();

    _tabLineCount = tabLines.isEmpty ? 1 : tabLines.length;
    final tabBlock = tabLines.join('\n');
    final divider = _style(Style()).dim().render('─' * _width.clamp(10, 200));
    return [title, mode, tabBlock, divider].join('\n');
  }

  String _renderHelp() {
    final help =
        'q quit • click tabs • Tab switch pages • 1-9 (0=10) jump • ? toggle help • e toggle emoji';
    final pageHelp = _activePage.help;
    return _style(Style()).dim().render('$help\n$pageHelp');
  }

  String _render2dGradient() {
    final w = (_width - 8).clamp(10, 50);
    final h = 6;
    final colors = blend2D(w, h, 45, [
      Colors.red,
      Colors.blue,
      Colors.green,
    ], hasDarkBackground: _theme.hasDarkBackground ?? true);
    if (colors.isEmpty) return '';

    final rows = <String>[];
    for (var y = 0; y < h; y++) {
      final buf = StringBuffer();
      for (var x = 0; x < w; x++) {
        final c = colors[y * w + x];
        buf.write((_style(Style())..background(c)).render(' '));
      }
      rows.add(buf.toString());
    }
    return rows.join('\n');
  }
}

final class _SelectionLayout {
  const _SelectionLayout({
    this.viewportTop = 0,
    this.textAreaTop = 0,
    this.textInputTop = 0,
    this.textTop = 0,
  });

  final int viewportTop;
  final int textAreaTop;
  final int textInputTop;
  final int textTop;
}

final class _TabHit {
  const _TabHit({
    required this.pageIndex,
    required this.row,
    required this.startX,
    required this.endX,
  });

  final int pageIndex;
  final int row;
  final int startX;
  final int endX;
}

abstract class _KitchenSinkPage {
  const _KitchenSinkPage({required this.help});

  final String help;

  String view(_KitchenSinkModel m);

  void onActivate(_KitchenSinkModel m, List<tui.Cmd> cmds) {}

  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) => false;

  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {}

  void onTick(_KitchenSinkModel m, List<tui.Cmd> cmds) {}
}

Future<void> runKitchenSink(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    Cmd.println(''' // tui:allow-stdout
Kitchen-sink TUI

Usage:
  dart run packages/artisanal/example/tui/examples/kitchen-sink/main.dart [options]

Options:
  --legacy-input     Use legacy KeyParser input
  --uv-renderer      Use UV renderer (cell-buffer diff)
''');
    return;
  }

  final legacy = args.contains('--legacy-input');
  final uvRenderer = args.contains('--uv-renderer');

  await tui.runProgram(
    _KitchenSinkModel(useUvInput: !legacy, useUvRenderer: uvRenderer),
    options: tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      bracketedPaste: true,
      useUltravioletInputDecoder: !legacy,
      useUltravioletRenderer: uvRenderer,
    ),
  );
}
