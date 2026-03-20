// Dedicated live surface for the shared editor-core refactor.
//
// Run with:
//   dart run example/editor-core-playground/main.dart

import 'package:artisanal/app.dart' as app;
import 'package:artisanal/bubbles.dart' as b;
import 'package:artisanal/editors.dart' as editors;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/style.dart' show Border, Color, Style;
import 'package:artisanal/terminal.dart' as terminal;
import 'package:artisanal/widgets.dart' as w;

const String _playgroundSearchLayerKey = 'playground.search';
const String _playgroundReviewLineLayerKey = 'playground.review';
const String _playgroundReviewLineDecorationKey = 'playground.review.line';
const String _playgroundReviewLineNumberDecorationKey =
    'playground.review.number';
const int _playgroundReviewLinePriority = 25;
final List<String> _playgroundThemePresetNames = <String>[
  'adaptive',
  'dark',
  'light',
  ...w.OpenCodeThemes.names,
];
const List<b.TextPatternDiagnosticRule> _playgroundDiagnosticRules =
    <b.TextPatternDiagnosticRule>[
      b.TextPatternDiagnosticRule(
        pattern: 'FIXME',
        severity: b.TextDiagnosticSeverity.error,
        code: 'FIX001',
        message: 'Resolve FIXME markers before treating this draft as ready.',
        source: 'playground',
        wholeWord: true,
      ),
      b.TextPatternDiagnosticRule(
        pattern: 'TODO',
        severity: b.TextDiagnosticSeverity.warning,
        code: 'TODO001',
        message: 'Address TODO markers before shipping this sample.',
        source: 'playground',
        wholeWord: true,
      ),
      b.TextPatternDiagnosticRule(
        pattern: 'NOTE',
        severity: b.TextDiagnosticSeverity.info,
        code: 'NOTE001',
        message: 'Review NOTE blocks for follow-up context.',
        source: 'playground',
        wholeWord: true,
      ),
      b.TextPatternDiagnosticRule(
        pattern: 'hint',
        severity: b.TextDiagnosticSeverity.hint,
        code: 'HINT001',
        message: 'Hints mark optional polish work in the sample text.',
        source: 'playground',
        wholeWord: true,
      ),
    ];

const String _rawTextSample = '''
Editor core playground

- TODO: keep decoration layers reusable
- NOTE: raw textarea exposes the lowest stable editing surface
- FIXME: add gutter markers after diagnostics land

Try dragging text, editing TODO lines, or changing the search query.
''';

const String _textEditorSample = '''
# Refactor Checkpoint

- DONE: shared document, state, view, and command layers
- TODO: ship a canonical live playground
- FIXME: feed real diagnostics into the new decoration collection

Use Ctrl+F here to exercise the built-in search UI on top of the same core.
''';

const String _codeEditorSample = '''
void bootstrapEditorCore() {
  final work = <String>[
    'TODO: wire diagnostics into the gutter',
    'FIXME: benchmark large-file wrapping',
  ];

  for (final item in work) {
    print(item);
  }

  throw UnimplementedError('hint: underline this diagnostic');
}
''';

Future<void> main() async {
  await app.runArtisanalApp(
    app.ArtisanalApp(
      title: 'Editor Core Playground',
      home: EditorCorePlaygroundScreen(),
    ),
  );
}

class EditorCorePlaygroundScreen extends w.StatefulWidget {
  EditorCorePlaygroundScreen({super.key});

  @override
  w.State createState() => _EditorCorePlaygroundScreenState();
}

class _EditorCorePlaygroundScreenState
    extends w.State<EditorCorePlaygroundScreen> {
  final w.FocusController _focus = w.FocusController();
  final w.WidgetScrollController _surfaceScrollController =
      w.WidgetScrollController();
  final editors.TextEditingController _queryController =
      editors.TextEditingController(text: 'TODO');
  final editors.TextAreaController _rawController = editors.TextAreaController(
    text: _rawTextSample,
  );
  final editors.TextAreaController _textEditorController =
      editors.TextAreaController(text: _textEditorSample);
  final editors.TextAreaController _codeEditorController =
      editors.TextAreaController(text: _codeEditorSample);
  late final List<editors.TextDiagnosticsBinding> _diagnosticsBindings;
  late final List<editors.TextDecorationLayerBinding> _searchBindings;
  late final List<editors.TextLineDecorationLayerBinding> _reviewLineBindings;

  bool _searchEnabled = true;
  bool _diagnosticsEnabled = true;
  bool _reviewLinesEnabled = true;
  bool _syncingDecorations = false;
  String _themePresetName = 'adaptive';
  String _status =
      'Playground overlays are live. Edit TODO or FIXME lines to watch them move.';

  Iterable<editors.TextAreaController> get _editableControllers => [
    _rawController,
    _textEditorController,
    _codeEditorController,
  ];

  @override
  void initState() {
    super.initState();
    _diagnosticsBindings = <editors.TextDiagnosticsBinding>[
      for (final controller in _editableControllers)
        editors.TextDiagnosticsBinding(
          controller: controller,
          buildDiagnostics: (String text) =>
              _diagnosticsEnabled ? _diagnosticsFor(text) : const [],
          syncImmediately: false,
        ),
    ];
    _searchBindings = <editors.TextDecorationLayerBinding>[
      for (final controller in _editableControllers)
        editors.TextDecorationLayerBinding(
          controller: controller,
          layerKey: _playgroundSearchLayerKey,
          buildDecorations: (String text) =>
              _searchEnabled ? _searchDecorationsFor(text) : const [],
          priority: b.textSearchDecorationLayerPriority,
          syncImmediately: false,
        ),
    ];
    _reviewLineBindings = <editors.TextLineDecorationLayerBinding>[
      for (final controller in _editableControllers)
        editors.TextLineDecorationLayerBinding(
          controller: controller,
          layerKey: _playgroundReviewLineLayerKey,
          buildDecorations: (String text) =>
              _reviewLinesEnabled ? _reviewLineDecorations(text) : const [],
          priority: _playgroundReviewLinePriority,
          syncImmediately: false,
        ),
    ];
    for (final controller in _editableControllers) {
      controller.addListener(_handleEditableChanged);
    }
    _syncDecorationLayers();
  }

  @override
  void dispose() {
    for (final binding in _diagnosticsBindings) {
      binding.dispose();
    }
    for (final binding in _searchBindings) {
      binding.dispose();
    }
    for (final binding in _reviewLineBindings) {
      binding.dispose();
    }
    for (final controller in _editableControllers) {
      controller.removeListener(_handleEditableChanged);
      controller.dispose();
    }
    _queryController.dispose();
    super.dispose();
  }

  @override
  runtime.Cmd? handleIntercept(runtime.Msg msg) {
    if (msg is runtime.InterruptMsg) {
      return runtime.Cmd.quit();
    }
    if (msg is runtime.KeyMsg &&
        msg.key.type == runtime.KeyType.escape &&
        _focus.hasFocus) {
      _clearFocus();
      return runtime.Cmd.none();
    }
    if (msg is runtime.KeyMsg && !_focus.hasFocus && _isQuitShortcut(msg.key)) {
      return runtime.Cmd.quit();
    }
    return null;
  }

  void _handleEditableChanged() {
    if (!mounted || _syncingDecorations) {
      return;
    }
    if (_searchEnabled || _diagnosticsEnabled || _reviewLinesEnabled) {
      _syncDecorationLayers();
      return;
    }
    setState(() {});
  }

  void _syncDecorationLayers() {
    if (_syncingDecorations) {
      return;
    }

    _syncingDecorations = true;
    try {
      for (final binding in _diagnosticsBindings) {
        binding.sync(force: true);
      }
      for (final binding in _searchBindings) {
        binding.sync(force: true);
      }
      for (final binding in _reviewLineBindings) {
        binding.sync(force: true);
      }
    } finally {
      _syncingDecorations = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  List<b.TextDecorationRange> _searchDecorationsFor(String text) {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      return const <b.TextDecorationRange>[];
    }

    final matches = _queryMatches(text, query);
    if (matches.isEmpty) {
      return const <b.TextDecorationRange>[];
    }

    return List<b.TextDecorationRange>.unmodifiable([
      for (var index = 0; index < matches.length; index++)
        b.TextDecorationRange(
          startOffset: matches[index].startOffset,
          endOffset: matches[index].endOffset,
          styleKey: index == 0
              ? b.textSearchActiveMatchDecorationKey
              : b.textSearchMatchDecorationKey,
        ),
    ]);
  }

  List<b.TextPositionDiagnosticRange> _diagnosticsFor(String text) {
    return b.textPatternDiagnostics(
      text: text,
      rules: _playgroundDiagnosticRules,
    );
  }

  List<b.TextLineDecoration> _reviewLineDecorations(String text) {
    final decorations = <b.TextLineDecoration>[];
    final lines = text.split('\n');

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      if (line.contains('TODO') || line.contains('FIXME')) {
        decorations.add(
          b.TextLineDecoration(
            lineIndex: lineIndex,
            styleKey: _playgroundReviewLineDecorationKey,
            lineNumberStyleKey: _playgroundReviewLineNumberDecorationKey,
          ),
        );
      }
    }

    return List<b.TextLineDecoration>.unmodifiable(decorations);
  }

  ({editors.TextAreaController controller, String label})
  _activeDiagnosticSurface() {
    final focusedId = _focus.focusedId;
    if (focusedId == null) {
      return (controller: _codeEditorController, label: 'CodeEditor');
    }
    if (focusedId == 'playground.raw') {
      return (controller: _rawController, label: 'raw TextArea');
    }
    if (focusedId.startsWith('playground.notes')) {
      return (controller: _textEditorController, label: 'TextEditor');
    }
    if (focusedId.startsWith('playground.code')) {
      return (controller: _codeEditorController, label: 'CodeEditor');
    }
    return (controller: _codeEditorController, label: 'CodeEditor');
  }

  Color _diagnosticColor(w.Theme theme, b.TextDiagnosticSeverity severity) {
    return switch (severity) {
      b.TextDiagnosticSeverity.error => theme.error,
      b.TextDiagnosticSeverity.warning => theme.warning,
      b.TextDiagnosticSeverity.info => theme.resolvedInfo,
      b.TextDiagnosticSeverity.hint => theme.resolvedOnSurfaceVariant,
    };
  }

  void _jumpDiagnostic({required bool forward}) {
    final surface = _activeDiagnosticSurface();
    final changed = forward
        ? surface.controller.selectNextDiagnostic()
        : surface.controller.selectPreviousDiagnostic();
    setState(() {
      _status = changed
          ? 'Selected ${forward ? 'next' : 'previous'} diagnostic in ${surface.label}.'
          : 'No diagnostics available in ${surface.label}.';
    });
  }

  void _setOverlayState({
    bool? searchEnabled,
    bool? diagnosticsEnabled,
    bool? reviewLinesEnabled,
    String? status,
  }) {
    _searchEnabled = searchEnabled ?? _searchEnabled;
    _diagnosticsEnabled = diagnosticsEnabled ?? _diagnosticsEnabled;
    _reviewLinesEnabled = reviewLinesEnabled ?? _reviewLinesEnabled;
    if (status != null) {
      _status = status;
    }
    _syncDecorationLayers();
  }

  void _resetSamples() {
    _rawController.text = _rawTextSample;
    _textEditorController.text = _textEditorSample;
    _codeEditorController.text = _codeEditorSample;
    _setOverlayState(
      status: 'Reset playground samples and re-applied overlays.',
    );
  }

  void _clearFocus() {
    if (_focus.clearFocus()) {
      setState(() {});
    }
  }

  b.TextAreaStyles _playgroundStyles(w.Theme theme) {
    final base = w.textAreaStylesFromTheme(theme);
    b.TextAreaStyleState withReviewLineStyle(b.TextAreaStyleState state) {
      return state.copyWith(
        lineDecorationStyles: <String, Style>{
          ...state.lineDecorationStyles,
          _playgroundReviewLineDecorationKey: Style()
              .background(theme.warning)
              .foreground(theme.resolvedOnWarning),
          _playgroundReviewLineNumberDecorationKey: Style().foreground(
            theme.resolvedOnWarning,
          ),
        },
      );
    }

    return base.copyWith(
      focused: withReviewLineStyle(base.focused),
      blurred: withReviewLineStyle(base.blurred),
    );
  }

  bool _surfaceIsActive(String focusPrefix) {
    final focusedId = _focus.focusedId;
    return focusedId == focusPrefix ||
        (focusedId?.startsWith('$focusPrefix.') ?? false);
  }

  int _rangeDecorationCount(
    editors.TextAreaController controller,
    String layerKey,
  ) {
    return controller.decorationsForLayer(layerKey).length;
  }

  int _lineDecorationCount(
    editors.TextAreaController controller,
    String layerKey,
  ) {
    return controller.lineDecorationsForLayer(layerKey).length;
  }

  w.Theme _resolveTheme() {
    return switch (_themePresetName) {
      'adaptive' => w.Theme.adaptive(),
      'dark' => w.Theme.dark(),
      'light' => w.Theme.light(),
      _ => w.OpenCodeThemes.byName(_themePresetName),
    };
  }

  String _themePresetLabel(String preset) {
    return switch (preset) {
      'adaptive' => 'Adaptive core',
      'dark' => 'Dark core',
      'light' => 'Light core',
      _ => 'OpenCode ${_themePresetDisplayName(preset)}',
    };
  }

  String _themePresetDisplayName(String preset) {
    if (preset.isEmpty) {
      return preset;
    }
    final spaced = preset.replaceAllMapped(
      RegExp(r'(?<!^)([A-Z])'),
      (match) => ' ${match[1]}',
    );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  List<w.SelectOption<String>> get _themeOptions => <w.SelectOption<String>>[
    for (final preset in _playgroundThemePresetNames)
      w.SelectOption<String>(label: _themePresetLabel(preset), value: preset),
  ];

  void _setThemePreset(String preset) {
    if (preset == _themePresetName) {
      return;
    }
    setState(() {
      _themePresetName = preset;
      _status = 'Switched playground theme to ${_themePresetLabel(preset)}.';
    });
  }

  void _cycleThemePreset({required bool forward}) {
    final currentIndex = _playgroundThemePresetNames.indexOf(_themePresetName);
    final startIndex = currentIndex < 0 ? 0 : currentIndex;
    final delta = forward ? 1 : -1;
    final nextIndex =
        (startIndex + delta + _playgroundThemePresetNames.length) %
        _playgroundThemePresetNames.length;
    _setThemePreset(_playgroundThemePresetNames[nextIndex]);
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = _resolveTheme();
    final styles = _playgroundStyles(theme);
    final media = w.MediaQuery.of(context);
    final isWide = media.size.width >= 120;
    final activeDiagnostic =
        _activeDiagnosticSurface().controller.activeDiagnostic;
    final activeDiagnosticText = _activeDiagnosticSurface().controller.text;
    final activeDiagnosticLabel = activeDiagnostic == null
        ? 'Focused diagnostic: none'
        : 'Focused diagnostic: ${b.textDiagnosticSummaryLabel(text: activeDiagnosticText, diagnostic: activeDiagnostic)}';
    final activeDiagnosticStyle = activeDiagnostic == null
        ? theme.labelSmall
        : theme.labelSmall.copy().foreground(
            _diagnosticColor(theme, activeDiagnostic.severity),
          );

    final leftColumn = w.Column(
      gap: 1,
      children: [
        _buildRawSurface(theme, styles),
        _buildTextEditorSurface(theme, styles),
      ],
    );

    final editorSurfaces = isWide
        ? w.Row(
            gap: 1,
            children: [
              w.Expanded(child: leftColumn),
              w.Expanded(child: _buildCodeEditorSurface(theme, styles)),
            ],
          )
        : w.Column(
            gap: 1,
            children: [leftColumn, _buildCodeEditorSurface(theme, styles)],
          );

    return w.ThemeScope(
      theme: theme,
      child: w.FocusScope(
        controller: _focus,
        child: w.Container(
          padding: const w.EdgeInsets.all(1),
          color: theme.background,
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.start,
            children: [
              w.Text('Editor Core Playground', style: theme.titleLarge),
              w.Text(
                'Dedicated live surface for the shared document, state, view, '
                'and decoration work. Search, diagnostics, and review layers '
                'stay live while you edit.',
                style: theme.labelSmall,
              ),
              _buildControls(theme),
              w.Text(_status, style: theme.labelSmall),
              w.Text(activeDiagnosticLabel, style: activeDiagnosticStyle),
              w.Text(
                'Search matches: '
                'raw ${_rangeDecorationCount(_rawController, _playgroundSearchLayerKey)} · '
                'notes ${_rangeDecorationCount(_textEditorController, _playgroundSearchLayerKey)} · '
                'code ${_rangeDecorationCount(_codeEditorController, _playgroundSearchLayerKey)}',
                style: theme.labelSmall,
              ),
              w.Text(
                'Diagnostics: '
                'raw ${_rangeDecorationCount(_rawController, b.textDiagnosticsDecorationLayerKey)} · '
                'notes ${_rangeDecorationCount(_textEditorController, b.textDiagnosticsDecorationLayerKey)} · '
                'code ${_rangeDecorationCount(_codeEditorController, b.textDiagnosticsDecorationLayerKey)} '
                ' | review lines ${_lineDecorationCount(_codeEditorController, _playgroundReviewLineLayerKey)}',
                style: theme.labelSmall,
              ),
              w.Expanded(
                child: w.ScrollArea(
                  controller: _surfaceScrollController,
                  showScrollbar: true,
                  child: editorSurfaces,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  w.Widget _buildControls(w.Theme theme) {
    final editorTheme = theme.editorTheme;
    final isCompact = w.MediaQuery.of(context).size.width < 110;
    final themeSelect = w.Select<String>(
      options: _themeOptions,
      value: _themePresetName,
      placeholder: 'Theme preset',
      onChanged: (String preset) {
        _setThemePreset(preset);
        return null;
      },
    );
    final previousThemeButton = w.TextButton(
      child: w.Text('Theme prev'),
      onPressed: () {
        _cycleThemePreset(forward: false);
        return null;
      },
    );
    final nextThemeButton = w.TextButton(
      child: w.Text('Theme next'),
      onPressed: () {
        _cycleThemePreset(forward: true);
        return null;
      },
    );
    final queryField = w.SizedBox(
      width: isCompact ? 18 : 24,
      child: editors.TextField(
        controller: _queryController,
        focusController: _focus,
        focusId: 'playground.query',
        placeholder: 'Search query',
        onChanged: (_) {
          if (_searchEnabled) {
            _syncDecorationLayers();
          } else {
            setState(() {});
          }
        },
      ),
    );
    final searchToggle = w.TextButton(
      child: w.Text(_searchEnabled ? 'Search on' : 'Search off'),
      onPressed: () {
        _setOverlayState(
          searchEnabled: !_searchEnabled,
          status: _searchEnabled
              ? 'Disabled playground search overlays.'
              : 'Enabled playground search overlays.',
        );
        return null;
      },
    );
    final diagnosticsToggle = w.TextButton(
      child: w.Text(_diagnosticsEnabled ? 'Diagnostics on' : 'Diagnostics off'),
      onPressed: () {
        _setOverlayState(
          diagnosticsEnabled: !_diagnosticsEnabled,
          status: _diagnosticsEnabled
              ? 'Disabled diagnostic overlays.'
              : 'Enabled diagnostic overlays.',
        );
        return null;
      },
    );
    final diagnosticsPreviousButton = w.TextButton(
      child: w.Text('Diag prev'),
      onPressed: () {
        _jumpDiagnostic(forward: false);
        return null;
      },
    );
    final diagnosticsNextButton = w.TextButton(
      child: w.Text('Diag next'),
      onPressed: () {
        _jumpDiagnostic(forward: true);
        return null;
      },
    );
    final reviewToggle = w.TextButton(
      child: w.Text(
        _reviewLinesEnabled ? 'Review lines on' : 'Review lines off',
      ),
      onPressed: () {
        _setOverlayState(
          reviewLinesEnabled: !_reviewLinesEnabled,
          status: _reviewLinesEnabled
              ? 'Disabled whole-line review overlays.'
              : 'Enabled whole-line review overlays.',
        );
        return null;
      },
    );
    final focusRawButton = w.TextButton(
      child: w.Text('Focus raw'),
      onPressed: () {
        _focus.requestFocus('playground.raw');
        setState(() {
          _status = 'Focused the raw TextArea surface.';
        });
        return null;
      },
    );
    final focusNotesButton = w.TextButton(
      child: w.Text('Focus notes'),
      onPressed: () {
        _focus.requestFocus('playground.notes');
        setState(() {
          _status = 'Focused TextEditor.';
        });
        return null;
      },
    );
    final focusCodeButton = w.TextButton(
      child: w.Text('Focus code'),
      onPressed: () {
        _focus.requestFocus('playground.code');
        setState(() {
          _status = 'Focused CodeEditor.';
        });
        return null;
      },
    );
    final resetButton = w.TextButton(
      child: w.Text('Reset samples'),
      onPressed: () {
        _resetSamples();
        return null;
      },
    );
    final blurButton = w.TextButton(
      child: w.Text('Blur'),
      onPressed: () {
        _clearFocus();
        return null;
      },
    );

    return w.Frame(
      background: editorTheme?.shellBackground ?? theme.resolvedSurfaceVariant,
      border: Border.rounded,
      borderColor:
          editorTheme?.inactiveShellBorderColor ?? theme.resolvedOutline,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text('Overlay Controls', style: theme.titleMedium),
          w.Text(
            'The query field drives a dedicated playground search layer. '
            'TextEditor still keeps its own Ctrl+F search UI.',
            style: theme.labelSmall,
          ),
          w.Text(
            'Theme preset: ${_themePresetLabel(_themePresetName)}',
            style: theme.labelSmall,
          ),
          if (isCompact) ...[
            w.Row(gap: 1, children: [themeSelect]),
            w.Row(gap: 1, children: [previousThemeButton, nextThemeButton]),
            queryField,
            w.Row(gap: 1, children: [searchToggle, diagnosticsToggle]),
            w.Row(
              gap: 1,
              children: [
                diagnosticsPreviousButton,
                diagnosticsNextButton,
                reviewToggle,
              ],
            ),
            w.Row(gap: 1, children: [blurButton]),
            w.Row(gap: 1, children: [focusRawButton, focusNotesButton]),
            w.Row(gap: 1, children: [focusCodeButton, resetButton]),
          ] else ...[
            w.Row(
              gap: 1,
              children: [themeSelect, previousThemeButton, nextThemeButton],
            ),
            w.Row(
              gap: 1,
              children: [
                queryField,
                searchToggle,
                diagnosticsToggle,
                diagnosticsPreviousButton,
                diagnosticsNextButton,
                reviewToggle,
              ],
            ),
            w.Row(
              gap: 1,
              children: [
                focusRawButton,
                focusNotesButton,
                focusCodeButton,
                resetButton,
                blurButton,
              ],
            ),
          ],
        ],
      ),
    );
  }

  w.Widget _buildRawSurface(w.Theme theme, b.TextAreaStyles styles) {
    return _buildSurfaceCard(
      theme: theme,
      isActive: _surfaceIsActive('playground.raw'),
      title: 'Raw TextArea',
      description:
          'Low-level surface with direct decoration-layer control. '
          'Drag a selection here to compare selection rendering with overlays.',
      child: editors.TextArea(
        controller: _rawController,
        focusController: _focus,
        focusId: 'playground.raw',
        height: 9,
        autofocus: false,
        styles: styles,
        placeholder: 'Raw editor surface',
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  w.Widget _buildTextEditorSurface(w.Theme theme, b.TextAreaStyles styles) {
    return _buildSurfaceCard(
      theme: theme,
      isActive: _surfaceIsActive('playground.notes'),
      title: 'TextEditor',
      description:
          'Higher-level editor chrome. Ctrl+F uses the built-in find UI while '
          'diagnostics and review lines still flow through the shared layers.',
      child: editors.TextEditor(
        title: 'checkpoint.md',
        controller: _textEditorController,
        focusController: _focus,
        focusId: 'playground.notes',
        height: 9,
        styles: styles,
        showHelpBar: true,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  w.Widget _buildCodeEditorSurface(w.Theme theme, b.TextAreaStyles styles) {
    return _buildSurfaceCard(
      theme: theme,
      isActive: _surfaceIsActive('playground.code'),
      title: 'CodeEditor',
      description:
          'Syntax decorations come from the editor core. Search, diagnostics, '
          'review lines, and the active line stack on top of that.',
      child: editors.CodeEditor(
        title: 'editor_core_demo.dart',
        language: 'dart',
        controller: _codeEditorController,
        focusController: _focus,
        focusId: 'playground.code',
        autofocus: false,
        height: 10,
        previewHeight: 8,
        styles: styles,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  w.Widget _buildSurfaceCard({
    required w.Theme theme,
    required bool isActive,
    required String title,
    required String description,
    required w.Widget child,
  }) {
    final editorTheme = theme.editorTheme;
    final titleStyle = theme.titleMedium.copy()
      ..foreground(
        isActive
            ? (editorTheme?.titleForeground ?? theme.onSurface)
            : (editorTheme?.inactiveTitleForeground ??
                  theme.resolvedOnSurfaceVariant),
      );
    final descriptionStyle = theme.labelMedium.copy().foreground(
      isActive
          ? (editorTheme?.metaForeground ?? theme.resolvedOnSurfaceVariant)
          : (editorTheme?.inactiveMetaForeground ?? theme.muted),
    );
    return w.Frame(
      background: isActive
          ? (editorTheme?.shellBackground ?? theme.resolvedSurfaceVariant)
          : (editorTheme?.inactiveShellBackground ?? theme.surface),
      border: Border.rounded,
      borderColor: isActive
          ? (editorTheme?.activeShellBorderColor ?? theme.primary)
          : (editorTheme?.inactiveShellBorderColor ?? theme.resolvedOutline),
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text(title, style: titleStyle),
          w.Text(description, style: descriptionStyle),
          child,
        ],
      ),
    );
  }
}

bool _isQuitShortcut(runtime.Key key) {
  if (!key.ctrl || key.alt || key.meta) return false;
  if (key.type != runtime.KeyType.runes || key.runes.isEmpty) return false;
  final rune = key.runes.first;
  return rune == 0x03 || String.fromCharCode(rune).toLowerCase() == 'c';
}

List<({int startOffset, int endOffset})> _queryMatches(
  String text,
  String query,
) {
  final needle = terminal.graphemes(query).toList(growable: false);
  if (needle.isEmpty) {
    return const [];
  }

  final haystack = terminal.graphemes(text).toList(growable: false);
  final normalizedNeedle = needle
      .map((token) => token.toLowerCase())
      .toList(growable: false);
  final normalizedHaystack = haystack
      .map((token) => token.toLowerCase())
      .toList(growable: false);
  final matches = <({int startOffset, int endOffset})>[];
  var cursor = 0;

  while (cursor <= normalizedHaystack.length - normalizedNeedle.length) {
    var matched = true;
    for (var index = 0; index < normalizedNeedle.length; index++) {
      if (normalizedHaystack[cursor + index] != normalizedNeedle[index]) {
        matched = false;
        break;
      }
    }
    if (!matched) {
      cursor++;
      continue;
    }

    matches.add((
      startOffset: cursor,
      endOffset: cursor + normalizedNeedle.length,
    ));
    cursor += normalizedNeedle.length;
  }

  return List<({int startOffset, int endOffset})>.unmodifiable(matches);
}
