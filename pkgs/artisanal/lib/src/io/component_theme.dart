import '../style/color.dart';
import '../style/style.dart';
import '../style/theme.dart';
import '../tui/bubbles/components/base.dart' show RenderConfig;
import '../tui/bubbles/confirm.dart' show ConfirmStyles;
import '../tui/bubbles/data_table.dart' show DataTableStyles;
import '../tui/bubbles/filepicker.dart' show FilePickerStyles;
import '../tui/bubbles/number_input.dart' show NumberInputStyles;
import '../tui/bubbles/password.dart' show PasswordStyles;
import '../tui/bubbles/search.dart' show SearchStyles;
import '../tui/bubbles/select.dart' show MultiSelectStyles, SelectStyles;
import '../tui/bubbles/suggest.dart' show SuggestStyles;
import '../tui/bubbles/textinput.dart'
    show TextInputCursorStyle, TextInputStyleState, TextInputStyles;

/// CLI-friendly names for the built-in [ComponentTheme] presets.
const componentThemePresetNames = [
  'dark',
  'light',
  'hacker',
  'ocean',
  'monokai',
  'dracula',
  'nord',
  'solarized-dark',
  'solarized-light',
];

/// Returns a built-in component theme by its CLI-friendly [name].
ComponentTheme componentThemeForName(String name) => switch (name) {
  'dark' => ComponentTheme.dark,
  'light' => ComponentTheme.light,
  'hacker' => ComponentTheme.hacker,
  'ocean' => ComponentTheme.ocean,
  'monokai' => ComponentTheme.monokai,
  'dracula' => ComponentTheme.dracula,
  'nord' => ComponentTheme.nord,
  'solarized-dark' => ComponentTheme.solarizedDark,
  'solarized-light' => ComponentTheme.solarizedLight,
  _ => throw ArgumentError.value(name, 'name', 'Unknown component theme'),
};

/// A palette and style bundle for Artisanal's built-in console components.
///
/// [ComponentTheme] keeps the visual language of interactive prompts and
/// display components together. Use one of the built-in presets or provide a
/// custom [ThemePalette]. Style objects are created on demand, so callers may
/// safely customize the returned bundle for a single widget.
///
/// ```dart
/// final console = Console(
///   componentTheme: ComponentTheme.ocean,
/// );
///
/// await console.selectChoice(
///   'Deploy to:',
///   choices: ['staging', 'production'],
/// );
/// ```
class ComponentTheme {
  /// Creates a component theme from a semantic [palette].
  const ComponentTheme({
    this.palette = ThemePalette.dark,
    this.cursorPrefix = '❯ ',
    this.itemPrefix = '  ',
    this.multiSelectCursorPrefix = '❯',
    this.selectedIconChar = '✓',
    this.unselectedIconChar = '○',
    this.pointer = '❯',
  });

  /// Classic terminal colors for dark backgrounds.
  static const dark = ComponentTheme(palette: ThemePalette.dark);

  /// Adaptive colors optimized for light terminal backgrounds.
  static const light = ComponentTheme(palette: ThemePalette.light);

  /// Matrix-inspired green terminal palette.
  static const hacker = ComponentTheme(palette: ThemePalette.hacker);

  /// Blue and cyan palette for calm, information-heavy tools.
  static const ocean = ComponentTheme(palette: ThemePalette.ocean);

  /// High-contrast Monokai-inspired palette.
  static const monokai = ComponentTheme(palette: ThemePalette.monokai);

  /// Dracula-inspired purple palette.
  static const dracula = ComponentTheme(palette: ThemePalette.dracula);

  /// Nord-inspired cool palette.
  static const nord = ComponentTheme(palette: ThemePalette.nord);

  /// Solarized dark palette.
  static const solarizedDark = ComponentTheme(
    palette: ThemePalette.solarizedDark,
  );

  /// Solarized light palette.
  static const solarizedLight = ComponentTheme(
    palette: ThemePalette.solarizedLight,
  );

  /// The default dark component theme.
  static const default_ = dark;

  /// The semantic colors used to build component styles.
  final ThemePalette palette;

  /// Prefix shown before the active item in single-select and search prompts.
  final String cursorPrefix;

  /// Prefix shown before inactive items in single-select and search prompts.
  final String itemPrefix;

  /// Prefix shown before the active item in multi-select prompts.
  final String multiSelectCursorPrefix;

  /// Character shown for a selected multi-select item.
  final String selectedIconChar;

  /// Character shown for an unselected multi-select item.
  final String unselectedIconChar;

  /// Pointer shown next to the active suggestion.
  final String pointer;

  /// Creates the primary prompt style.
  Style promptStyle([RenderConfig config = const RenderConfig()]) =>
      _style(palette.accentBold, config, bold: true);

  /// Creates the standard text style.
  Style textStyle([RenderConfig config = const RenderConfig()]) =>
      _style(palette.text, config);

  /// Creates a muted secondary-text style.
  Style mutedStyle([RenderConfig config = const RenderConfig()]) =>
      _style(palette.textDim, config);

  /// Creates a success style.
  Style successStyle([RenderConfig config = const RenderConfig()]) =>
      _style(palette.success, config);

  /// Creates a warning style.
  Style warningStyle([RenderConfig config = const RenderConfig()]) =>
      _style(palette.warning, config);

  /// Creates an error style.
  Style errorStyle([RenderConfig config = const RenderConfig()]) =>
      _style(palette.error, config, bold: true);

  /// Creates an informational style.
  Style infoStyle([RenderConfig config = const RenderConfig()]) =>
      _style(palette.info, config);

  /// Creates styles for a text input prompt.
  TextInputStyles textInputStyles([
    RenderConfig config = const RenderConfig(),
  ]) {
    final text = textStyle(config);
    final muted = mutedStyle(config);
    final prompt = promptStyle(config);
    return TextInputStyles(
      focused: TextInputStyleState(
        text: text,
        placeholder: muted,
        suggestion: muted,
        prompt: prompt,
        selection: _selectionStyle(config),
      ),
      blurred: TextInputStyleState(
        text: text.copy(),
        placeholder: muted.copy(),
        suggestion: muted.copy(),
        prompt: prompt.copy(),
        selection: _selectionStyle(config),
      ),
      cursor: TextInputCursorStyle(color: palette.accentBold),
    );
  }

  /// Creates styles for a password prompt.
  PasswordStyles passwordStyles([RenderConfig config = const RenderConfig()]) =>
      PasswordStyles(
        prompt: promptStyle(config),
        text: textStyle(config),
        cursor: _style(palette.accentBold, config),
        dimmed: mutedStyle(config),
        error: errorStyle(config),
      );

  /// Creates styles for a confirmation prompt.
  ConfirmStyles confirmStyles([RenderConfig config = const RenderConfig()]) =>
      ConfirmStyles(
        prompt: promptStyle(config),
        activeChoice: _style(palette.accentBold, config, bold: true),
        inactiveChoice: textStyle(config),
        hint: mutedStyle(config),
        dimmed: mutedStyle(config),
      );

  /// Creates styles for a numeric input prompt.
  NumberInputStyles numberInputStyles([
    RenderConfig config = const RenderConfig(),
  ]) => NumberInputStyles(
    prompt: promptStyle(config),
    value: textStyle(config),
    placeholder: mutedStyle(config),
    hint: mutedStyle(config),
    error: errorStyle(config),
    dimmed: mutedStyle(config),
  );

  /// Creates styles for a single-select prompt.
  SelectStyles selectStyles([RenderConfig config = const RenderConfig()]) =>
      SelectStyles(
        title: promptStyle(config),
        item: textStyle(config),
        selectedItem: _style(palette.accent, config),
        cursor: _style(palette.accentBold, config, bold: true),
        dimmed: mutedStyle(config),
        cursorPrefix: cursorPrefix,
        itemPrefix: itemPrefix,
      );

  /// Creates styles for a multi-select prompt.
  MultiSelectStyles multiSelectStyles([
    RenderConfig config = const RenderConfig(),
  ]) => MultiSelectStyles(
    title: promptStyle(config),
    item: textStyle(config),
    highlightedItem: _style(palette.accent, config, bold: true),
    selectedIcon: _style(palette.success, config),
    unselectedIcon: mutedStyle(config),
    dimmed: mutedStyle(config),
    cursorPrefix: multiSelectCursorPrefix,
    selectedIconChar: selectedIconChar,
    unselectedIconChar: unselectedIconChar,
  );

  /// Creates styles for a search prompt.
  SearchStyles searchStyles([RenderConfig config = const RenderConfig()]) =>
      SearchStyles(
        title: promptStyle(config),
        prompt: infoStyle(config),
        item: textStyle(config),
        selectedItem: _style(palette.accent, config),
        matchHighlight: _style(palette.highlight, config, bold: true),
        cursor: _style(palette.accentBold, config, bold: true),
        dimmed: mutedStyle(config),
        noResults: _style(palette.textDim, config, italic: true),
        selectedIcon: _style(palette.success, config),
        unselectedIcon: mutedStyle(config),
        cursorPrefix: cursorPrefix,
        itemPrefix: itemPrefix,
      );

  /// Creates styles for an interactive data table.
  DataTableStyles dataTableStyles([
    RenderConfig config = const RenderConfig(),
  ]) => DataTableStyles(
    title: promptStyle(config),
    prompt: infoStyle(config),
    tableHeader: _style(palette.accentBold, config, bold: true)..padding(0, 1),
    tableCell: textStyle(config)..padding(0, 1),
    tableSelected: _style(palette.accentBold, config, bold: true),
    dimmed: mutedStyle(config),
    noResults: _style(palette.textDim, config, italic: true),
  );

  /// Creates styles for a suggest/autocomplete prompt.
  SuggestStyles suggestStyles([RenderConfig config = const RenderConfig()]) =>
      SuggestStyles(
        title: promptStyle(config),
        value: textStyle(config),
        placeholder: mutedStyle(config),
        highlighted: _style(palette.accent, config, bold: true),
        suggestion: textStyle(config),
        hint: mutedStyle(config),
        dimmed: mutedStyle(config),
        pointer: pointer,
      );

  /// Creates styles for a file picker prompt.
  FilePickerStyles filePickerStyles([
    RenderConfig config = const RenderConfig(),
  ]) => FilePickerStyles(
    cursor: _style(palette.accentBold, config, bold: true),
    symlink: infoStyle(config),
    directory: _style(palette.accent, config, bold: true),
    file: textStyle(config),
    permission: mutedStyle(config),
    selected: _style(palette.accentBold, config, bold: true),
    disabledCursor: mutedStyle(config),
    disabledFile: mutedStyle(config),
    disabledSelected: mutedStyle(config)..bold(),
    fileSize: mutedStyle(config)..width(7),
    emptyDirectory: _style(palette.textDim, config, italic: true),
  );

  Style _style(
    Color color,
    RenderConfig config, {
    bool bold = false,
    bool italic = false,
  }) {
    final style = Style()..foreground(color);
    if (bold) style.bold();
    if (italic) style.italic();
    return config.configureStyle(style);
  }

  Style _selectionStyle(RenderConfig config) => Style()
    ..background(palette.accent)
    ..foreground(palette.textBold)
    ..colorProfile = config.colorProfile
    ..hasDarkBackground = config.hasDarkBackground;
}
