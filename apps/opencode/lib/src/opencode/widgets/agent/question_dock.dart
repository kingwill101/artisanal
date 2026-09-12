/// OpenCode example-local multi-question dock (not a framework API).
///
/// Presentation + light selection state for agent "ask user" flows:
/// tabs across questions, single/multi select options, optional custom
/// answer, confirm step, and reject/submit actions.
///
/// Layout adapts to width: headers/tabs/actions wrap; prompts and option
/// labels soft-wrap; confirm rows stack on narrow terminals.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

/// One selectable choice under an [AgentQuestion].
final class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.label,
    this.description,
  });

  final String id;
  final String label;
  final String? description;
}

/// A single agent question (one tab in [QuestionDock]).
final class AgentQuestion {
  const AgentQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.multiple = false,
    this.allowCustom = true,
    this.customLabel = 'Other…',
  });

  final String id;
  final String prompt;
  final List<QuestionOption> options;

  /// When true, options behave as a multi-select checklist.
  final bool multiple;

  /// When true, show a free-text "other" option.
  final bool allowCustom;
  final String customLabel;
}

/// Answers keyed by [AgentQuestion.id] → selected option labels / custom text.
typedef QuestionAnswers = Map<String, List<String>>;

/// Bottom/session dock for multi-question agent prompts (OpenCode-style).
class QuestionDock extends w.StatefulWidget {
  QuestionDock({
    required this.questions,
    this.title = 'questions',
    this.activeTab,
    this.answers,
    this.selectedOptionIndex = 0,
    this.customDrafts = const {},
    this.onTabChanged,
    this.onToggleOption,
    this.onCustomChanged,
    this.onSubmit,
    this.onReject,
    this.background,
    this.borderColor,
    this.accentColor,
    this.mutedColor,
    this.dangerColor,
    this.narrowBreakpoint = 56,
    super.key,
  }) : assert(questions.isNotEmpty, 'QuestionDock requires at least one question');

  final List<AgentQuestion> questions;
  final String title;

  /// Controlled tab index. When null, the widget owns tab state.
  final int? activeTab;

  /// Controlled answers map. When null, the widget owns answer state.
  final QuestionAnswers? answers;

  final int selectedOptionIndex;
  final Map<String, String> customDrafts;

  final void Function(int tab)? onTabChanged;
  final void Function(String questionId, String optionId)? onToggleOption;
  final void Function(String questionId, String text)? onCustomChanged;
  final void Function(QuestionAnswers answers)? onSubmit;
  final void Function()? onReject;

  final style.Color? background;
  final style.Color? borderColor;
  final style.Color? accentColor;
  final style.Color? mutedColor;
  final style.Color? dangerColor;
  final int narrowBreakpoint;

  static bool needsConfirmTab(List<AgentQuestion> questions) {
    if (questions.length > 1) return true;
    return questions.any((q) => q.multiple);
  }

  @override
  w.State<QuestionDock> createState() => _QuestionDockState();
}

class _QuestionDockState extends w.State<QuestionDock> {
  late int _tab;
  late QuestionAnswers _answers;
  late Map<String, String> _custom;
  late int _selected;

  bool get _controlledTab => widget.activeTab != null;
  bool get _controlledAnswers => widget.answers != null;

  int get _confirmIndex => widget.questions.length;
  bool get _hasConfirm => QuestionDock.needsConfirmTab(widget.questions);
  int get _tabCount =>
      _hasConfirm ? widget.questions.length + 1 : widget.questions.length;

  int get _activeTab {
    final t = _controlledTab ? widget.activeTab! : _tab;
    return t.clamp(0, _tabCount - 1);
  }

  bool get _onConfirm => _hasConfirm && _activeTab == _confirmIndex;

  QuestionAnswers get _currentAnswers => _controlledAnswers
      ? Map<String, List<String>>.of(widget.answers!)
      : _answers;

  Map<String, String> get _currentCustom =>
      _controlledAnswers ? widget.customDrafts : _custom;

  @override
  void initState() {
    super.initState();
    _tab = widget.activeTab ?? 0;
    _answers = {
      for (final q in widget.questions) q.id: <String>[],
    };
    if (widget.answers != null) {
      for (final e in widget.answers!.entries) {
        _answers[e.key] = List<String>.of(e.value);
      }
    }
    _custom = Map<String, String>.of(widget.customDrafts);
    _selected = widget.selectedOptionIndex;
  }

  @override
  tui.Cmd? didUpdateWidget(covariant QuestionDock oldWidget) {
    if (widget.selectedOptionIndex != oldWidget.selectedOptionIndex) {
      _selected = widget.selectedOptionIndex;
    }
    return super.didUpdateWidget(oldWidget);
  }

  void _setTab(int tab) {
    final next = tab.clamp(0, _tabCount - 1);
    widget.onTabChanged?.call(next);
    if (!_controlledTab) {
      setState(() {
        _tab = next;
        _selected = 0;
      });
    }
  }

  void _toggle(AgentQuestion q, QuestionOption opt) {
    widget.onToggleOption?.call(q.id, opt.id);
    if (_controlledAnswers) return;

    setState(() {
      final list = List<String>.of(_answers[q.id] ?? const []);
      if (q.multiple) {
        if (list.contains(opt.label)) {
          list.remove(opt.label);
        } else {
          list.add(opt.label);
        }
      } else {
        list
          ..clear()
          ..add(opt.label);
      }
      _answers[q.id] = list;
    });
  }

  bool _isPicked(AgentQuestion q, QuestionOption opt) {
    final list = _currentAnswers[q.id] ?? const [];
    return list.contains(opt.label) || list.contains(opt.id);
  }

  void _submit() {
    widget.onSubmit?.call(_currentAnswers);
  }

  String get _primaryActionLabel {
    if (_onConfirm) return 'submit';
    if (_hasConfirm) return 'next';
    return 'submit';
  }

  String get _enterHintLabel {
    if (_onConfirm) return 'submit';
    if (widget.questions[_activeTab].multiple) return 'toggle';
    return 'submit';
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final bg = widget.background ?? theme.surface;
    final border = widget.borderColor ?? theme.border;
    final accent = widget.accentColor ?? theme.primary;
    final muted = widget.mutedColor ?? theme.muted;
    final danger = widget.dangerColor ?? theme.error;

    final titleStyle = theme.labelSmall.copy()..foreground(accent);
    final promptStyle = theme.titleSmall.copy()
      ..foreground(theme.onSurface)
      ..bold();
    final mutedStyle = theme.bodySmall.copy()..foreground(muted);

    return w.LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (w.MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);
        final narrow = width <= widget.narrowBreakpoint;

        return w.Frame(
          background: bg,
          border: style.Border.rounded,
          borderColor: border,
          padding: const w.EdgeInsets.all(1),
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, accent, muted, titleStyle, mutedStyle, narrow),
              w.Divider(style: style.Style().foreground(border)),
              if (_onConfirm)
                _buildConfirm(theme, mutedStyle, promptStyle, narrow)
              else
                _buildQuestion(
                  widget.questions[_activeTab],
                  theme,
                  accent,
                  muted,
                  promptStyle,
                  mutedStyle,
                  narrow,
                ),
              w.Divider(style: style.Style().foreground(border)),
              _buildActionBar(theme, accent, muted, danger, mutedStyle, narrow),
            ],
          ),
        );
      },
    );
  }

  w.Widget _buildHeader(
    w.Theme theme,
    style.Color accent,
    style.Color muted,
    style.Style titleStyle,
    style.Style mutedStyle,
    bool narrow,
  ) {
    final progress = _onConfirm
        ? 'confirm'
        : '${_activeTab + 1}/${widget.questions.length}';

    final identity = w.Wrap(
      spacing: 1,
      runSpacing: 0,
      children: [
        w.Text(widget.title, style: titleStyle),
        w.Text('·', style: mutedStyle),
        w.Text(progress, style: mutedStyle),
      ],
    );

    final tabs = _tabCount > 1 ? _buildTabs(theme, accent, muted) : null;

    if (narrow || tabs == null) {
      return w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          identity,
          ?tabs,
        ],
      );
    }

    return w.Row(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.start,
      children: [
        w.Expanded(child: identity),
        tabs,
      ],
    );
  }

  w.Widget _buildTabs(w.Theme theme, style.Color accent, style.Color muted) {
    final bits = <w.Widget>[];
    for (var i = 0; i < widget.questions.length; i++) {
      final active = i == _activeTab;
      bits.add(
        w.GestureDetector(
          onTap: () {
            _setTab(i);
            return null;
          },
          child: w.Text(
            active ? '[${i + 1}]' : '${i + 1}',
            style: theme.labelSmall.copy()
              ..foreground(active ? accent : muted),
          ),
        ),
      );
    }
    if (_hasConfirm) {
      bits.add(
        w.GestureDetector(
          onTap: () {
            _setTab(_confirmIndex);
            return null;
          },
          child: w.Text(
            _onConfirm ? '[✓]' : '✓',
            style: theme.labelSmall.copy()
              ..foreground(_onConfirm ? accent : muted),
          ),
        ),
      );
    }
    return w.Wrap(spacing: 1, runSpacing: 0, children: bits);
  }

  w.Widget _buildQuestion(
    AgentQuestion q,
    w.Theme theme,
    style.Color accent,
    style.Color muted,
    style.Style promptStyle,
    style.Style mutedStyle,
    bool narrow,
  ) {
    final options = q.options;
    final customText = _currentCustom[q.id] ?? '';
    final rowCount = options.length + (q.allowCustom ? 1 : 0);

    return w.Column(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Text(q.prompt, style: promptStyle, softWrap: true),
        if (q.multiple) w.Text('multi-select', style: mutedStyle),
        for (var i = 0; i < options.length; i++)
          _optionRow(
            theme: theme,
            accent: accent,
            muted: muted,
            multi: q.multiple,
            picked: _isPicked(q, options[i]),
            focused: _selected == i,
            label: options[i].label,
            description: options[i].description,
            indexLabel: '${i + 1}',
            narrow: narrow,
            onTap: () => _toggle(q, options[i]),
          ),
        if (q.allowCustom)
          _optionRow(
            theme: theme,
            accent: accent,
            muted: muted,
            multi: q.multiple,
            picked: customText.trim().isNotEmpty &&
                (_currentAnswers[q.id] ?? const []).contains(customText.trim()),
            focused: _selected == options.length,
            label: customText.trim().isEmpty
                ? q.customLabel
                : '${q.customLabel}: $customText',
            description: null,
            indexLabel: '$rowCount',
            narrow: narrow,
            onTap: () {
              final text =
                  customText.trim().isEmpty ? 'custom answer' : customText;
              widget.onCustomChanged?.call(q.id, text);
              if (!_controlledAnswers) {
                setState(() {
                  _custom[q.id] = text;
                  final list = List<String>.of(_answers[q.id] ?? const []);
                  if (q.multiple) {
                    if (!list.contains(text)) list.add(text);
                  } else {
                    list
                      ..clear()
                      ..add(text);
                  }
                  _answers[q.id] = list;
                });
              }
            },
          ),
      ],
    );
  }

  w.Widget _buildConfirm(
    w.Theme theme,
    style.Style mutedStyle,
    style.Style promptStyle,
    bool narrow,
  ) {
    final answers = _currentAnswers;
    return w.Column(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Text('Review answers', style: promptStyle, softWrap: true),
        for (final q in widget.questions)
          if (narrow)
            w.Column(
              gap: 0,
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              children: [
                w.Text(q.prompt, style: mutedStyle, softWrap: true),
                w.Text(
                  (answers[q.id] ?? const []).isEmpty
                      ? '—'
                      : (answers[q.id] ?? const []).join(', '),
                  style: theme.bodySmall.copy()..foreground(theme.onSurface),
                  softWrap: true,
                ),
              ],
            )
          else
            w.Row(
              gap: 1,
              crossAxisAlignment: w.CrossAxisAlignment.start,
              children: [
                w.Flexible(
                  child: w.Text(
                    '${q.prompt}:',
                    style: mutedStyle,
                    softWrap: true,
                  ),
                ),
                w.Expanded(
                  flex: 2,
                  child: w.Text(
                    (answers[q.id] ?? const []).isEmpty
                        ? '—'
                        : (answers[q.id] ?? const []).join(', '),
                    style: theme.bodySmall.copy()..foreground(theme.onSurface),
                    softWrap: true,
                  ),
                ),
              ],
            ),
      ],
    );
  }

  w.Widget _optionRow({
    required w.Theme theme,
    required style.Color accent,
    required style.Color muted,
    required bool multi,
    required bool picked,
    required bool focused,
    required String label,
    required String? description,
    required String indexLabel,
    required bool narrow,
    required void Function() onTap,
  }) {
    final mark = multi
        ? (picked ? '[x]' : '[ ]')
        : (picked ? '(•)' : '( )');
    final fg = focused || picked ? theme.onSurface : muted;
    final labelStyle = theme.bodySmall.copy()
      ..foreground(fg)
      ..bold(focused || picked);
    final descStyle = theme.bodySmall.copy()..foreground(muted);

    final leading = w.Row(
      gap: 1,
      children: [
        w.Text(
          indexLabel,
          style: theme.labelSmall.copy()..foreground(muted),
        ),
        w.Text(
          mark,
          style: theme.labelSmall.copy()..foreground(picked ? accent : muted),
        ),
      ],
    );

    final body = w.Column(
      gap: 0,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Text(label, style: labelStyle, softWrap: true),
        if (description != null && description.isNotEmpty)
          w.Text(description, style: descStyle, softWrap: true),
      ],
    );

    return w.GestureDetector(
      onTap: () {
        onTap();
        return null;
      },
      child: narrow
          ? w.Column(
              gap: 0,
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              children: [leading, body],
            )
          : w.Row(
              gap: 1,
              crossAxisAlignment: w.CrossAxisAlignment.start,
              children: [
                leading,
                w.Expanded(child: body),
              ],
            ),
    );
  }

  w.Widget _buildActionBar(
    w.Theme theme,
    style.Color accent,
    style.Color muted,
    style.Color danger,
    style.Style mutedStyle,
    bool narrow,
  ) {
    final hints = <w.Widget>[
      _hintChip(theme, 'enter', _enterHintLabel, accent),
      if (_tabCount > 1) _hintChip(theme, 'tab', 'next', muted),
      _hintChip(theme, 'esc', 'reject', danger),
    ];

    final buttons = <w.Widget>[
      w.GestureDetector(
        onTap: () {
          widget.onReject?.call();
          return null;
        },
        child: w.Frame(
          padding: const w.EdgeInsets.symmetric(horizontal: 1),
          border: style.Border.rounded,
          borderColor: muted,
          child: w.Text('reject', style: mutedStyle),
        ),
      ),
      w.GestureDetector(
        onTap: () {
          if (_onConfirm ||
              (!_hasConfirm && !widget.questions.first.multiple)) {
            _submit();
          } else if (!_onConfirm && _activeTab < _confirmIndex) {
            _setTab(_activeTab + 1);
          } else {
            _submit();
          }
          return null;
        },
        child: w.Frame(
          padding: const w.EdgeInsets.symmetric(horizontal: 1),
          background: accent,
          border: style.Border.rounded,
          borderColor: accent,
          child: w.Text(
            _primaryActionLabel,
            style: theme.labelSmall.copy()
              ..foreground(theme.onPrimary)
              ..bold(),
          ),
        ),
      ),
    ];

    // Two bands: key hints wrap freely; primary buttons wrap on their own row
    // so they stay tappable and never clip against hints.
    return w.Column(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Wrap(spacing: 2, runSpacing: 1, children: hints),
        w.Wrap(
          spacing: 2,
          runSpacing: 1,
          alignment: narrow ? w.WrapAlignment.start : w.WrapAlignment.end,
          children: buttons,
        ),
      ],
    );
  }

  w.Widget _hintChip(
    w.Theme theme,
    String key,
    String label,
    style.Color color,
  ) {
    return w.Row(
      gap: 1,
      children: [
        w.Frame(
          padding: const w.EdgeInsets.symmetric(horizontal: 1),
          background: color,
          child: w.Text(
            key,
            style: theme.labelSmall.copy()..foreground(theme.onPrimary),
          ),
        ),
        w.Text(
          label,
          style: theme.labelSmall.copy()..foreground(theme.onSurface),
        ),
      ],
    );
  }
}
