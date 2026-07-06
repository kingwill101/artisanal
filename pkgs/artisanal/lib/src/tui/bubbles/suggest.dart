/// Suggest bubble — text input with a scrollable prefix-matched dropdown.
///
/// Shows a text-input field and, as the user types, a scrollable list of
/// matching suggestions below. The user can navigate suggestions with
/// arrow keys and accept one with Enter or Tab, or keep typing freely.
library;

import 'package:artisanal/style.dart';
import '../../unicode/grapheme.dart' as uni;
import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'key_binding.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the user accepts a value (typed or from the dropdown).
class SuggestSubmittedMsg extends Msg {
  /// Creates a submitted message with the accepted [value].
  const SuggestSubmittedMsg(this.value);

  /// The accepted value.
  final String value;

  @override
  String toString() => 'SuggestSubmittedMsg($value)';
}

/// Emitted when the user cancels the suggest prompt.
class SuggestCancelledMsg extends Msg {
  const SuggestCancelledMsg();

  @override
  String toString() => 'SuggestCancelledMsg()';
}

// ─────────────────────────────────────────────────────────────────────────────
// Key map
// ─────────────────────────────────────────────────────────────────────────────

/// Key bindings for [SuggestModel].
class SuggestKeyMap extends KeyMap {
  /// Creates a key map with default bindings.
  SuggestKeyMap({
    KeyBinding? moveUp,
    KeyBinding? moveDown,
    KeyBinding? moveFirst,
    KeyBinding? moveLast,
    KeyBinding? accept,
    KeyBinding? deleteBackward,
    KeyBinding? moveCursorLeft,
    KeyBinding? moveCursorRight,
    KeyBinding? cancel,
  }) : moveUp =
           moveUp ??
           KeyBinding(
             keys: ['up', 'ctrl+p', 'shift+tab'],
             help: Help(key: Arrows.up, desc: 'up'),
           ),
       moveDown =
           moveDown ??
           KeyBinding(
             keys: ['down', 'ctrl+n', 'tab'],
             help: Help(key: Arrows.down, desc: 'down'),
           ),
       moveFirst =
           moveFirst ??
           KeyBinding(
             keys: ['ctrl+a', 'home'],
             help: Help(key: 'home', desc: 'first'),
           ),
       moveLast =
           moveLast ??
           KeyBinding(
             keys: ['ctrl+e', 'end'],
             help: Help(key: 'end', desc: 'last'),
           ),
       accept =
           accept ??
           KeyBinding(
             keys: ['enter'],
             help: Help(key: KeyboardChars.enter, desc: 'accept'),
           ),
       deleteBackward =
           deleteBackward ??
           KeyBinding(
             keys: ['backspace', 'ctrl+h'],
             help: Help(key: KeyboardChars.backspace, desc: 'delete'),
           ),
       moveCursorLeft =
           moveCursorLeft ??
           KeyBinding(
             keys: ['left', 'ctrl+b'],
             help: Help(key: Arrows.left, desc: 'cursor left'),
           ),
       moveCursorRight =
           moveCursorRight ??
           KeyBinding(
             keys: ['right', 'ctrl+f'],
             help: Help(key: Arrows.right, desc: 'cursor right'),
           ),
       cancel =
           cancel ??
           KeyBinding(
             keys: ['esc', 'ctrl+c'],
             help: Help(key: 'esc', desc: 'cancel'),
            ) {
    shortHelp = [this.moveUp, this.moveDown, this.accept, this.cancel];
    fullHelp = [
      [this.moveUp, this.moveDown, this.moveFirst, this.moveLast],
      [this.deleteBackward, this.accept, this.cancel],
    ];
  }

  /// Move selection up in the dropdown.
  final KeyBinding moveUp;

  /// Move selection down in the dropdown.
  final KeyBinding moveDown;

  /// Jump to first suggestion.
  final KeyBinding moveFirst;

  /// Jump to last suggestion.
  final KeyBinding moveLast;

  /// Accept the current input or highlighted suggestion.
  final KeyBinding accept;

  /// Delete the character before the cursor.
  final KeyBinding deleteBackward;

  /// Move text cursor left (clears dropdown selection).
  final KeyBinding moveCursorLeft;

  /// Move text cursor right (clears dropdown selection).
  final KeyBinding moveCursorRight;

  /// Cancel the prompt.
  final KeyBinding cancel;

}

// ─────────────────────────────────────────────────────────────────────────────
// Styles
// ─────────────────────────────────────────────────────────────────────────────

/// Visual styles for [SuggestModel].
class SuggestStyles {
  /// Creates styles with sensible defaults.
  SuggestStyles({
    Style? title,
    Style? value,
    Style? placeholder,
    Style? highlighted,
    Style? suggestion,
    Style? hint,
    Style? dimmed,
    String? pointer,
  }) : title = title ?? Style().foreground(AnsiColor(11)).bold(),
       value = value ?? Style(),
       placeholder = placeholder ?? Style().foreground(AnsiColor(8)),
       highlighted = highlighted ?? Style().foreground(AnsiColor(14)).bold(),
       suggestion = suggestion ?? Style(),
       hint = hint ?? Style().foreground(AnsiColor(8)),
       dimmed = dimmed ?? Style().foreground(AnsiColor(8)),
       pointer = pointer ?? '❯';

  /// Style for the prompt label.
  final Style title;

  /// Style for the typed value.
  final Style value;

  /// Style for placeholder text.
  final Style placeholder;

  /// Style for the highlighted/selected suggestion row.
  final Style highlighted;

  /// Style for unselected suggestion rows.
  final Style suggestion;

  /// Style for the hint line.
  final Style hint;

  /// Style for secondary/dimmed text (help, scroll indicators).
  final Style dimmed;

  /// Pointer character for the highlighted suggestion.
  final String pointer;
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

/// Interactive text-input with a scrollable prefix-matched suggestion dropdown.
///
/// Behaviour mirrors Laravel's `SuggestPrompt`:
/// - Suggestions are filtered by prefix match as the user types.
/// - Up/Down (or Tab/Shift-Tab) navigate the visible suggestion list.
/// - Accepting a suggestion (Enter when highlighted, Tab) copies it to the input.
/// - Pressing Enter when no suggestion is highlighted submits the typed value.
/// - Escape / Ctrl+C cancels and emits [SuggestCancelledMsg].
/// - Left/Right arrow clears the dropdown selection.
///
/// Emits [SuggestSubmittedMsg] on success or [SuggestCancelledMsg] on cancel.
class SuggestModel extends ViewComponent {
  /// Creates a new suggest model.
  SuggestModel({
    this.prompt = '? ',
    this.options = const [],
    this.placeholder = '',
    this.defaultValue = '',
    this.scroll = 5,
    this.hint = '',
    this.showHelp = true,
    SuggestKeyMap? keyMap,
    SuggestStyles? styles,
  }) : keyMap = keyMap ?? SuggestKeyMap(),
       styles = styles ?? SuggestStyles(),
       _rawInput = defaultValue,
       _cursor = defaultValue.length;

  /// The label shown before the input field.
  final String prompt;

  /// The static list of suggestion strings.
  final List<String> options;

  /// Placeholder shown when the input is empty.
  final String placeholder;

  /// Pre-filled default value.
  final String defaultValue;

  /// Maximum number of suggestions visible at once (scrolled window).
  final int scroll;

  /// Optional hint line shown below the input.
  final String hint;

  /// Whether to show the keyboard help line.
  final bool showHelp;

  /// Key bindings.
  final SuggestKeyMap keyMap;

  /// Visual styles.
  final SuggestStyles styles;

  // ── internal state ────────────────────────────────────────────────────────

  String _rawInput;

  /// Text cursor offset (grapheme index).
  int _cursor;

  /// Currently highlighted suggestion index, or -1 for none.
  int _highlighted = -1;

  /// Index of first visible suggestion in the scroll window.
  int _firstVisible = 0;

  // ── public accessors ──────────────────────────────────────────────────────

  /// The current typed value.
  String get rawInput => _rawInput;

  /// The index of the highlighted suggestion, or -1 if none.
  int get highlighted => _highlighted;

  /// All suggestions that prefix-match the current input.
  List<String> get matches {
    final query = _rawInput.toLowerCase();
    if (query.isEmpty) return List.of(options);
    return options.where((o) => o.toLowerCase().startsWith(query)).toList();
  }

  /// The visible window of [matches] after applying scroll.
  List<String> get visible {
    final all = matches;
    final start = _firstVisible.clamp(0, all.isEmpty ? 0 : all.length);
    final end = (start + scroll).clamp(0, all.length);
    return all.sublist(start, end);
  }

  // ── MVU ───────────────────────────────────────────────────────────────────

  @override
  Cmd? init() => null;

  @override
  (SuggestModel, Cmd?) update(Msg msg) {
    if (msg is! KeyMsg) return (this, null);
    final key = msg.key;

    // Cancel
    if (keyMatches(key, [keyMap.cancel])) {
      return (this, Cmd.message(const SuggestCancelledMsg()));
    }

    // Accept
    if (keyMatches(key, [keyMap.accept])) {
      final value = _acceptedValue();
      return (this, Cmd.message(SuggestSubmittedMsg(value)));
    }

    // Navigate up / down
    if (keyMatches(key, [keyMap.moveDown])) {
      _moveHighlight(1);
      return (this, null);
    }
    if (keyMatches(key, [keyMap.moveUp])) {
      _moveHighlight(-1);
      return (this, null);
    }
    if (keyMatches(key, [keyMap.moveFirst])) {
      if (_highlighted >= 0) {
        _highlighted = 0;
        _firstVisible = 0;
      }
      return (this, null);
    }
    if (keyMatches(key, [keyMap.moveLast])) {
      if (_highlighted >= 0) {
        final m = matches;
        if (m.isNotEmpty) {
          _highlighted = m.length - 1;
          _firstVisible = (m.length - scroll).clamp(0, m.length - 1);
        }
      }
      return (this, null);
    }

    // Left / Right arrows clear the highlight but don't consume the key
    // (future: cursor movement within the input)
    if (keyMatches(key, [keyMap.moveCursorLeft])) {
      _highlighted = -1;
      if (_cursor > 0) _cursor--;
      return (this, null);
    }
    if (keyMatches(key, [keyMap.moveCursorRight])) {
      _highlighted = -1;
      final graphemes = uni.graphemes(_rawInput).toList();
      if (_cursor < graphemes.length) _cursor++;
      return (this, null);
    }

    // Backspace
    if (keyMatches(key, [keyMap.deleteBackward])) {
      _highlighted = -1;
      if (_rawInput.isNotEmpty) {
        final gs = uni.graphemes(_rawInput).toList();
        if (_cursor > 0) {
          gs.removeAt(_cursor - 1);
          _rawInput = gs.join();
          _cursor--;
        }
      }
      _firstVisible = 0;
      return (this, null);
    }

    // Character input
    if (key.runes.isNotEmpty) {
      final ch = String.fromCharCodes(key.runes);
      _highlighted = -1;
      final gs = uni.graphemes(_rawInput).toList();
      gs.insert(_cursor, ch);
      _rawInput = gs.join();
      _cursor++;
      _firstVisible = 0;
      return (this, null);
    }

    return (this, null);
  }

  @override
  String view() {
    final buf = StringBuffer();

    // Prompt + input line.
    buf.write(styles.title.render(prompt));
    buf.write(' ');
    if (_rawInput.isEmpty) {
      buf.write(
        styles.placeholder.render(placeholder.isNotEmpty ? placeholder : '...'),
      );
    } else {
      buf.write(styles.value.render(_rawInput));
    }
    buf.writeln();

    // Dropdown.
    final allMatches = matches;
    if (allMatches.isNotEmpty) {
      final end = (_firstVisible + scroll).clamp(0, allMatches.length);
      for (var i = _firstVisible; i < end; i++) {
        final isHighlighted = (i == _highlighted);
        if (isHighlighted) {
          buf.write('  ');
          buf.write(styles.highlighted.render(styles.pointer));
          buf.write(' ');
          buf.writeln(styles.highlighted.render(allMatches[i]));
        } else {
          buf.write('    ');
          buf.writeln(styles.suggestion.render(allMatches[i]));
        }
      }
      // Scroll indicator.
      if (allMatches.length > scroll) {
        final remaining = allMatches.length - (_firstVisible + scroll);
        if (remaining > 0) {
          buf.writeln(styles.dimmed.render('  ... $remaining more'));
        }
      }
    }

    // Hint line.
    if (hint.isNotEmpty) {
      buf.writeln(styles.hint.render('  $hint'));
    }

    // Help.
    if (showHelp) {
      final helpText = keyMap
          .shortHelp
          .where((b) => b.help.hasContent)
          .map((b) => '${b.help.key} ${b.help.desc}')
          .join('  ');
      buf.writeln(styles.dimmed.render('  $helpText'));
    }

    return buf.toString();
  }

  // ── private helpers ───────────────────────────────────────────────────────

  /// The value that would be submitted right now.
  String _acceptedValue() {
    if (_highlighted >= 0) {
      final m = matches;
      if (_highlighted < m.length) return m[_highlighted];
    }
    return _rawInput;
  }

  void _moveHighlight(int delta) {
    final m = matches;
    if (m.isEmpty) return;

    if (_highlighted < 0) {
      // Start navigation.
      _highlighted = delta > 0 ? 0 : m.length - 1;
    } else {
      _highlighted = (_highlighted + delta).clamp(0, m.length - 1);
    }

    // Scroll the window to keep the highlighted item visible.
    if (_highlighted < _firstVisible) {
      _firstVisible = _highlighted;
    } else if (_highlighted >= _firstVisible + scroll) {
      _firstVisible = _highlighted - scroll + 1;
    }
  }
}
