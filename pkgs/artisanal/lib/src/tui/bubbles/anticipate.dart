/// Anticipate bubble - Interactive autocomplete input component.
///
/// This provides an autocomplete input field with suggestions that filter
/// as you type, navigation with arrow keys, and selection with Enter/Tab.
///
/// Based on the Bubble Tea anticipate component.
library;

import 'package:artisanal/src/tui/bubbles/key_binding.dart';
import 'package:artisanal/src/tui/tui.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/unicode/grapheme.dart' as uni;

/// Configuration for anticipate/autocomplete component.
class AnticipateConfig {
  /// Creates anticipate configuration.
  const AnticipateConfig({
    this.maxSuggestions = 5,
    this.highlightColor = '36',
    this.pointer = '❯',
    this.minCharsToSearch = 1,
  });

  /// Maximum number of suggestions to show.
  final int maxSuggestions;

  /// ANSI color code for highlighting selected suggestion.
  final String highlightColor;

  /// Pointer character for selected suggestion.
  final String pointer;

  /// Minimum characters needed before showing suggestions.
  final int minCharsToSearch;
}

/// Key map for anticipate navigation and selection.
class AnticipateKeyMap implements KeyMap {
  /// Creates an anticipate key map with default bindings.
  AnticipateKeyMap({
    KeyBinding? acceptSuggestion,
    KeyBinding? nextSuggestion,
    KeyBinding? prevSuggestion,
    KeyBinding? cancel,
    KeyBinding? deleteCharacterBackward,
  }) : acceptSuggestion =
           acceptSuggestion ??
           KeyBinding(
             keys: ['enter', 'tab'],
             help: Help(key: '↵/tab', desc: 'accept'),
           ),
       nextSuggestion =
           nextSuggestion ??
           KeyBinding(
             keys: ['down', 'ctrl+n'],
             help: Help(key: '↓', desc: 'next'),
           ),
       prevSuggestion =
           prevSuggestion ??
           KeyBinding(
             keys: ['up', 'ctrl+p'],
             help: Help(key: '↑', desc: 'prev'),
           ),
       cancel =
           cancel ??
           KeyBinding(
             keys: ['esc', 'ctrl+c'],
             help: Help(key: 'esc', desc: 'cancel'),
           ),
       deleteCharacterBackward =
           deleteCharacterBackward ??
           KeyBinding(
             keys: ['backspace', 'ctrl+h'],
             help: Help(key: '⌫', desc: 'delete char'),
           );

  /// Accept current suggestion or typed input.
  final KeyBinding acceptSuggestion;

  /// Move to next suggestion.
  final KeyBinding nextSuggestion;

  /// Move to previous suggestion.
  final KeyBinding prevSuggestion;

  /// Cancel input (return null).
  final KeyBinding cancel;

  /// Delete character backward (backspace).
  final KeyBinding deleteCharacterBackward;

  @override
  List<KeyBinding> shortHelp() => [acceptSuggestion, cancel];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [acceptSuggestion, cancel],
    [nextSuggestion, prevSuggestion],
  ];
}

/// Anticipate model for autocomplete input.
class AnticipateModel extends ViewComponent {
  /// Creates a new anticipate model.
  AnticipateModel({
    this.prompt = '? ',
    this.placeholder = '',
    this.suggestions = const [],
    this.defaultValue = '',
    this.config = const AnticipateConfig(),
    AnticipateKeyMap? keyMap,
    Style? promptStyle,
    Style? textStyle,
    Style? placeholderStyle,
    Style? suggestionStyle,
    Style? selectedSuggestionStyle,
  }) : keyMap = keyMap ?? AnticipateKeyMap(),
       _promptStyle = promptStyle ?? Style().foreground(Colors.info),
       _textStyle = textStyle ?? Style().foreground(Colors.warning).bold(),
       _placeholderStyle = placeholderStyle ?? Style().dim(),
       _suggestionStyle = suggestionStyle ?? Style(),
       _selectedSuggestionStyle =
           selectedSuggestionStyle ??
           Style().foreground(AnsiColor(int.parse(config.highlightColor)));

  /// Prompt displayed before input.
  final String prompt;

  /// Placeholder text when empty.
  final String placeholder;

  /// Available suggestions for autocomplete.
  final List<String> suggestions;

  /// Default value if no input provided.
  final String defaultValue;

  /// Configuration for behavior.
  final AnticipateConfig config;

  /// Key bindings.
  final AnticipateKeyMap keyMap;

  /// Style for the prompt.
  final Style _promptStyle;

  /// Style for the input text.
  final Style _textStyle;

  /// Style for placeholder text.
  final Style _placeholderStyle;

  /// Style for suggestions.
  final Style _suggestionStyle;

  /// Style for selected suggestion.
  final Style _selectedSuggestionStyle;

  // Internal state
  String _value = '';
  int _selectedIndex = 0;
  bool _focused = false;
  List<String> _filteredSuggestions = [];

  /// Gets the current input value.
  String get value => _value;

  /// Sets the current input value.
  set value(String v) {
    _value = v;
    _updateFilteredSuggestions();
  }

  /// Gets the selected suggestion index.
  int get selectedIndex => _selectedIndex;

  /// Gets the currently selected suggestion.
  String get selectedSuggestion => _selectedIndex < _filteredSuggestions.length
      ? _filteredSuggestions[_selectedIndex]
      : '';

  /// Gets filtered suggestions based on current input.
  List<String> get filteredSuggestions => _filteredSuggestions;

  /// Whether the anticipate is focused.
  bool get focused => _focused;

  /// Sets focus state.
  AnticipateModel focus() => copyWith(focused: true);

  /// Removes focus.
  AnticipateModel blur() => copyWith(focused: false);

  /// Resets the anticipate to initial state.
  AnticipateModel reset() =>
      copyWith(value: '', selectedIndex: 0, focused: false);

  /// Creates a copy with updated fields.
  AnticipateModel copyWith({
    String? value,
    int? selectedIndex,
    bool? focused,
    List<String>? filteredSuggestions,
  }) {
    final newModel = AnticipateModel(
      prompt: prompt,
      placeholder: placeholder,
      suggestions: suggestions,
      defaultValue: defaultValue,
      config: config,
      keyMap: keyMap,
      promptStyle: _promptStyle,
      textStyle: _textStyle,
      placeholderStyle: _placeholderStyle,
      suggestionStyle: _suggestionStyle,
      selectedSuggestionStyle: _selectedSuggestionStyle,
    );
    newModel._value = value ?? _value;
    newModel._selectedIndex = selectedIndex ?? _selectedIndex;
    newModel._focused = focused ?? _focused;

    if (filteredSuggestions != null) {
      newModel._filteredSuggestions = filteredSuggestions;
    } else if (value != null) {
      // If the value changed, recompute suggestions deterministically.
      newModel._updateFilteredSuggestions();
    } else {
      newModel._filteredSuggestions = _filteredSuggestions;
    }
    return newModel;
  }

  void _updateFilteredSuggestions() {
    if (uni.graphemes(_value).length < config.minCharsToSearch) {
      _filteredSuggestions = [];
    } else {
      _filteredSuggestions = suggestions
          .where((s) => s.toLowerCase().contains(_value.toLowerCase()))
          .take(config.maxSuggestions)
          .toList();
    }
    if (_filteredSuggestions.isEmpty) {
      _selectedIndex = 0;
    } else {
      _selectedIndex = _selectedIndex.clamp(0, _filteredSuggestions.length - 1);
    }
  }

  @override
  Cmd? init() => null;

  @override
  (AnticipateModel, Cmd?) update(Msg msg) {
    if (!_focused) return (this, null);

    if (msg is KeyMsg) {
      if (keyMatches(msg.key, [keyMap.cancel])) {
        return (blur().copyWith(value: ''), null);
      } else if (keyMatches(msg.key, [keyMap.acceptSuggestion])) {
        final result = _filteredSuggestions.isNotEmpty
            ? _filteredSuggestions[_selectedIndex]
            : (_value.isNotEmpty ? _value : defaultValue);
        return (blur().copyWith(value: result), null);
      } else if (keyMatches(msg.key, [keyMap.nextSuggestion])) {
        if (_filteredSuggestions.isNotEmpty) {
          final newIndex = (_selectedIndex + 1) % _filteredSuggestions.length;
          return (copyWith(selectedIndex: newIndex), null);
        }
      } else if (keyMatches(msg.key, [keyMap.prevSuggestion])) {
        if (_filteredSuggestions.isNotEmpty) {
          final newIndex = _selectedIndex > 0
              ? _selectedIndex - 1
              : _filteredSuggestions.length - 1;
          return (copyWith(selectedIndex: newIndex), null);
        }
      } else if (keyMatches(msg.key, [keyMap.deleteCharacterBackward])) {
        if (_value.isNotEmpty) {
          final newValue = _dropLastGrapheme(_value);
          final newModel = copyWith(value: newValue);
          return (newModel, null);
        }
      } else if (msg.key.runes.isNotEmpty) {
        // Handle character input
        final newValue = _value + String.fromCharCodes(msg.key.runes);
        final newModel = copyWith(value: newValue);
        return (newModel, null);
      }
    }

    return (this, null);
  }

  @override
  String view() {
    final buffer = StringBuffer();

    // Prompt and input
    buffer.write(_promptStyle.render(prompt));
    buffer.write(_textStyle.render(prompt.isNotEmpty ? ' ' : ''));

    final displayValue = _value.isNotEmpty ? _value : placeholder;
    final valueStyle = _value.isNotEmpty ? _textStyle : _placeholderStyle;
    buffer.write(valueStyle.render(displayValue));

    // Suggestions
    if (_filteredSuggestions.isNotEmpty) {
      buffer.writeln();
      for (var i = 0; i < _filteredSuggestions.length; i++) {
        if (i == _selectedIndex) {
          buffer.write('  ');
          buffer.write(_selectedSuggestionStyle.render(config.pointer));
          buffer.write(' ');
          buffer.write(
            _selectedSuggestionStyle.render(_filteredSuggestions[i]),
          );
        } else {
          buffer.write('    ');
          buffer.write(_suggestionStyle.render(_filteredSuggestions[i]));
        }
        if (i < _filteredSuggestions.length - 1) {
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }

  static String _dropLastGrapheme(String s) {
    if (s.isEmpty) return '';
    final gs = uni.graphemes(s).toList();
    if (gs.isEmpty) return '';
    gs.removeLast();
    return gs.join();
  }
}
