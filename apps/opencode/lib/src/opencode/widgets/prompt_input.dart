/// Prompt input widget — matches the real OpenCode prompt.
///
/// Left ┃ border colored by agent, backgroundElement bg,
/// textarea, agent/model/provider labels below input.
/// Supports `/` slash and `@` mention autocomplete + prompt history.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import 'left_accent_pane.dart';
import 'state/open_code_ui_state.dart';
import '../theme.dart';

/// Agent color lookup (matches OpenCode agent system).
style.Color agentColor(String agent) {
  return switch (agent) {
    'build' => OC.secondary,
    'code' => OC.secondary,
    'task' => OC.accent,
    'plan' => OC.success,
    _ => OC.secondary,
  };
}

/// Demo slash commands for the OpenCode example.
const openCodeSlashCommands = <w.AutocompleteItem>[
  w.AutocompleteItem(
    id: 'slash-help',
    label: '/help',
    description: 'show help',
    group: 'commands',
    insertText: '/help',
  ),
  w.AutocompleteItem(
    id: 'slash-clear',
    label: '/clear',
    description: 'clear messages',
    group: 'commands',
    insertText: '/clear',
  ),
  w.AutocompleteItem(
    id: 'slash-model',
    label: '/model',
    description: 'switch model',
    group: 'commands',
    insertText: '/model',
  ),
  w.AutocompleteItem(
    id: 'slash-share',
    label: '/share',
    description: 'share session',
    group: 'commands',
    insertText: '/share',
  ),
  w.AutocompleteItem(
    id: 'slash-undo',
    label: '/undo',
    description: 'undo last turn',
    group: 'commands',
    insertText: '/undo',
  ),
  w.AutocompleteItem(
    id: 'slash-stash',
    label: '/stash',
    description: 'stash draft',
    group: 'commands',
    insertText: '/stash',
  ),
  w.AutocompleteItem(
    id: 'slash-unstash',
    label: '/unstash',
    description: 'restore newest stash',
    group: 'commands',
    insertText: '/unstash',
  ),
  w.AutocompleteItem(
    id: 'slash-stash-list',
    label: '/stash-list',
    description: 'browse stash',
    group: 'commands',
    insertText: '/stash-list',
  ),
];

/// Demo file mentions for the OpenCode example.
const openCodeMentionItems = <w.AutocompleteItem>[
  w.AutocompleteItem(
    id: 'file-main',
    label: 'lib/main.dart',
    description: 'entry',
    group: 'files',
    insertText: '@lib/main.dart',
  ),
  w.AutocompleteItem(
    id: 'file-pubspec',
    label: 'pubspec.yaml',
    description: 'package',
    group: 'files',
    insertText: '@pubspec.yaml',
  ),
  w.AutocompleteItem(
    id: 'file-readme',
    label: 'README.md',
    description: 'docs',
    group: 'files',
    insertText: '@README.md',
  ),
  w.AutocompleteItem(
    id: 'file-theme',
    label: 'lib/src/widgets/theme/theme.dart',
    description: 'theme',
    group: 'files',
    insertText: '@lib/src/widgets/theme/theme.dart',
  ),
  w.AutocompleteItem(
    id: 'agent-code',
    label: 'code',
    description: 'agent',
    group: 'agents',
    insertText: '@code',
  ),
  w.AutocompleteItem(
    id: 'agent-plan',
    label: 'plan',
    description: 'agent',
    group: 'agents',
    insertText: '@plan',
  ),
];

class PromptInput extends w.StatefulWidget {
  PromptInput({
    this.controller,
    this.agentName = 'build',
    this.modelName = 'gpt-5.3-codex',
    this.providerName = 'OpenAI',
    this.showPlaceholder = true,
    this.onChanged,
    this.enterBehavior = EnterBehavior.send,
    this.onSubmit,
    this.dimmed = false,
    this.slashItems = openCodeSlashCommands,
    this.mentionItems = openCodeMentionItems,
    this.frecency,
    this.history,
    this.stash,
    super.key,
  });

  final w.TextEditingController? controller;
  final String agentName;
  final String modelName;
  final String providerName;
  final bool showPlaceholder;
  final w.TextChangedCallback? onChanged;
  final EnterBehavior enterBehavior;
  final void Function(String text)? onSubmit;
  final bool dimmed;
  final List<w.AutocompleteItem> slashItems;
  final List<w.AutocompleteItem> mentionItems;
  final w.FrecencyStore? frecency;
  final w.PromptHistory? history;
  final w.PromptStash? stash;

  @override
  w.State createState() => _PromptInputState();
}

class _PromptInputState extends w.State<PromptInput> {
  late final w.TextEditingController _owned;
  late final w.FrecencyStore _frecency;
  late final w.PromptHistory _history;
  late final w.PromptStash _stash;

  w.AutocompleteQuery? _query;
  List<w.AutocompleteItem> _items = const [];
  int _selected = 0;
  bool _stashOpen = false;
  int _stashSelected = 0;

  w.TextEditingController get _controller => widget.controller ?? _owned;

  bool get _acOpen => _query != null && _items.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _owned = w.TextEditingController();
    _frecency = widget.frecency ?? w.FrecencyStore();
    _history = widget.history ?? w.PromptHistory();
    _stash = widget.stash ?? w.PromptStash();
    _controller.addListener(_onText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    if (widget.controller == null) {
      _owned.dispose();
    }
    super.dispose();
  }

  void _onText() {
    // Note: typing often mutates TextInputModel in place without notifying
    // the controller; prefer onChanged. Listener still covers set text.
    _refreshAutocomplete(_controller.text);
  }

  void _refreshAutocomplete(String text) {
    final q = w.detectAutocompleteQuery(text);
    if (q == null) {
      if (_query != null || _items.isNotEmpty) {
        setState(() {
          _query = null;
          _items = const [];
          _selected = 0;
        });
      }
      return;
    }

    final source = q.trigger == w.AutocompleteTrigger.slash
        ? widget.slashItems
        : widget.mentionItems;
    final filtered = w.filterAutocompleteItems(
      source,
      q.query,
      frecency: _frecency,
    );

    setState(() {
      _query = q;
      _items = filtered;
      _selected = filtered.isEmpty
          ? 0
          : _selected.clamp(0, filtered.length - 1);
    });
  }

  void _applySelection(w.AutocompleteItem item) {
    final q = _query;
    if (q == null) return;
    _frecency.touch(item.id);

    // Special slash commands that act immediately (OpenCode-style).
    if (item.id == 'slash-stash') {
      _stash.push(_controller.text);
      _controller.text = '';
      _history.resetBrowse();
      setState(() {
        _query = null;
        _items = const [];
        _selected = 0;
        _stashOpen = false;
      });
      widget.onChanged?.call('');
      return;
    }
    if (item.id == 'slash-unstash') {
      final entry = _stash.pop();
      final next = entry?.input ?? '';
      _controller.text = next;
      _history.resetBrowse();
      setState(() {
        _query = null;
        _items = const [];
        _selected = 0;
        _stashOpen = false;
      });
      widget.onChanged?.call(next);
      return;
    }
    if (item.id == 'slash-stash-list') {
      setState(() {
        _query = null;
        _items = const [];
        _selected = 0;
        _stashOpen = true;
        _stashSelected = 0;
      });
      _controller.text = '';
      widget.onChanged?.call('');
      return;
    }

    final next = w.applyAutocompleteInsertion(
      _controller.text,
      q,
      item.textToInsert,
    );
    _controller.text = next;
    _history.resetBrowse();
    setState(() {
      _query = null;
      _items = const [];
      _selected = 0;
    });
    widget.onChanged?.call(next);
  }

  void _restoreStashAtDisplayIndex(int displayIndex) {
    final ordered = _stash.entries.reversed.toList();
    if (displayIndex < 0 || displayIndex >= ordered.length) return;
    final entry = ordered[displayIndex];
    final storageIndex = _stash.entries.length - 1 - displayIndex;
    _stash.removeAt(storageIndex);
    _controller.text = entry.input;
    setState(() {
      _stashOpen = false;
      _stashSelected = 0;
    });
    widget.onChanged?.call(entry.input);
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _history.push(text);
    widget.onSubmit?.call(text);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    final key = msg.key;

    if (_stashOpen) {
      final n = _stash.length;
      if (key.type == tui.KeyType.escape) {
        setState(() {
          _stashOpen = false;
          _stashSelected = 0;
        });
        return tui.Cmd.none();
      }
      if (n > 0 && key.type == tui.KeyType.up) {
        setState(() {
          _stashSelected = (_stashSelected - 1).clamp(0, n - 1);
        });
        return tui.Cmd.none();
      }
      if (n > 0 && key.type == tui.KeyType.down) {
        setState(() {
          _stashSelected = (_stashSelected + 1).clamp(0, n - 1);
        });
        return tui.Cmd.none();
      }
      if (n > 0 &&
          (key.type == tui.KeyType.tab || (key.isEnterLike && !key.shift))) {
        _restoreStashAtDisplayIndex(_stashSelected);
        return tui.Cmd.none();
      }
    }

    if (_acOpen) {
      if (key.type == tui.KeyType.escape) {
        setState(() {
          _query = null;
          _items = const [];
          _selected = 0;
        });
        return tui.Cmd.none();
      }
      if (key.type == tui.KeyType.up) {
        setState(() {
          _selected = (_selected - 1).clamp(0, _items.length - 1);
        });
        return tui.Cmd.none();
      }
      if (key.type == tui.KeyType.down) {
        setState(() {
          _selected = (_selected + 1).clamp(0, _items.length - 1);
        });
        return tui.Cmd.none();
      }
      if (key.type == tui.KeyType.tab ||
          (key.isEnterLike && !key.shift)) {
        if (_items.isNotEmpty) {
          _applySelection(_items[_selected.clamp(0, _items.length - 1)]);
        }
        return tui.Cmd.none();
      }
    }

    // Prompt history (OpenCode up/down when autocomplete closed).
    if (!_acOpen &&
        (key.type == tui.KeyType.up || key.type == tui.KeyType.down)) {
      final dir = key.type == tui.KeyType.up ? -1 : 1;
      final next = _history.move(dir, _controller.text);
      if (next != null) {
        _controller.text = next;
        widget.onChanged?.call(next);
        return tui.Cmd.none();
      }
    }

    // Submit on enter (send mode) when autocomplete is closed.
    if (!_acOpen && key.isEnterLike) {
      final send =
          widget.enterBehavior == EnterBehavior.send && !key.shift && !key.ctrl;
      final forceSend =
          widget.enterBehavior == EnterBehavior.newline && key.ctrl;
      if (send || forceSend) {
        _submit();
        return tui.Cmd.none();
      }
    }

    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final color = agentColor(widget.agentName);
    final agentLabel =
        '${widget.agentName[0].toUpperCase()}${widget.agentName.substring(1)}';

    final modelParts = widget.modelName.split('-');
    final modelDisplay = modelParts.length > 3
        ? modelParts.take(3).join('-')
        : widget.modelName;

    final submitHelper = widget.enterBehavior == EnterBehavior.send
        ? 'Enter'
        : 'Ctrl+Enter';

    final acTitle = _query == null
        ? null
        : (_query!.trigger == w.AutocompleteTrigger.slash ? '/' : '@');

    return w.Row(
      children: [
        w.Expanded(
          child: LeftAccentPane(
            accentColor: color,
            backgroundColor: OC.backgroundElement,
            dimmed: widget.dimmed,
            padding: const w.EdgeInsets.only(
              left: 2,
              right: 2,
              top: 1,
              bottom: 1,
            ),
            child: w.Column(
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              children: [
                w.TextField(
                  controller: _controller,
                  focusId: 'home-prompt',
                  prompt: ' ',
                  placeholder: widget.showPlaceholder ? 'Ask anything...' : '',
                  onChanged: (text) {
                    // Must drive AC from onChanged — controller may not notify
                    // on each key when TextInputModel updates in place.
                    _refreshAutocomplete(text);
                    widget.onChanged?.call(text);
                  },
                  autofocus: true,
                  multiline: true,
                  maxLines: 6,
                  charLimit: 4000,
                  collapseLargePaste: true,
                  collapsedPasteMinChars: 1200,
                  collapsedPasteMinLines: 20,
                ),
                if (_acOpen) ...[
                  w.SizedBox(height: 1),
                  w.AutocompleteOverlay(
                    title: acTitle,
                    query: _query?.query,
                    items: _items,
                    selectedIndex: _selected,
                  ),
                ],
                if (_stashOpen) ...[
                  w.SizedBox(height: 1),
                  w.PromptStashPanel(
                    entries: _stash.entries,
                    selectedIndex: _stashSelected,
                    onSelect: (storageIndex, entry) {
                      final displayIndex =
                          _stash.entries.length - 1 - storageIndex;
                      _restoreStashAtDisplayIndex(displayIndex);
                    },
                    onRemove: (storageIndex, entry) {
                      setState(() {
                        _stash.removeAt(storageIndex);
                        if (_stash.isEmpty) {
                          _stashOpen = false;
                          _stashSelected = 0;
                        } else {
                          _stashSelected = _stashSelected.clamp(
                            0,
                            _stash.length - 1,
                          );
                        }
                      });
                    },
                  ),
                ],
                w.SizedBox(height: 1),
                w.Row(
                  gap: 1,
                  children: [
                    w.Text(
                      agentLabel,
                      style: style.Style()..foreground(color),
                    ),
                    w.Text(
                      modelDisplay,
                      style: style.Style()..foreground(OC.text),
                      softWrap: false,
                    ),
                    w.Text(
                      widget.providerName,
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                    w.Spacer(),
                    w.Text(
                      _stashOpen
                          ? '↑↓ enter · esc'
                          : (_acOpen ? '↑↓ tab · esc' : submitHelper),
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
