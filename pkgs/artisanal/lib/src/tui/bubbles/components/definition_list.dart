import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A definition list component (term: description pairs).
///
/// ```dart
/// DefinitionListComponent(
///   items: {
///     'Name': 'artisanal',
///     'Version': '1.0.0',
///   },
/// ).render();
/// ```
class DefinitionListComponent extends DisplayComponent {
  const DefinitionListComponent({
    required this.items,
    this.separator = ':',
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  });

  final Map<String, String> items;
  final String separator;
  final int indent;
  final RenderConfig renderConfig;

  @override
  String render() {
    if (items.isEmpty) return '';

    final buffer = StringBuffer();
    final maxKeyLen = items.keys
        .map((k) => k.length)
        .reduce((a, b) => a > b ? a : b);

    final keyStyle = renderConfig.configureStyle(
      Style().foreground(Colors.warning).bold(),
    );

    var first = true;
    for (final entry in items.entries) {
      if (!first) buffer.writeln();
      first = false;

      final key = entry.key.padRight(maxKeyLen);
      buffer.write(
        '${' ' * indent}${keyStyle.render(key)}$separator ${entry.value}',
      );
    }

    return buffer.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fluent DefinitionList Builder
// ─────────────────────────────────────────────────────────────────────────────

/// Callback for styling definition list items.
///
/// [term] is the term being rendered.
/// [description] is the description being rendered.
/// [index] is the index of the item (0-based).
/// [isTerm] indicates whether this is the term (true) or description (false).
///
/// Return a [Style] to apply, or `null` for no styling.
typedef DefinitionStyleFunc =
    Style? Function(String term, String description, int index, bool isTerm);

/// A fluent builder for creating styled definition lists.
///
/// Provides a chainable API for definition list configuration with support for
/// the new Style system and per-item conditional styling.
///
/// ```dart
/// final list = DefinitionList()
///     .item('Name', 'artisanal')
///     .item('Version', '1.0.0')
///     .item('License', 'MIT')
///     .termStyle(Style().bold().foreground(Colors.cyan))
///     .separator(':')
///     .render();
///
/// print(list);
/// ```
class DefinitionList extends DisplayComponent {
  /// Creates a new empty definition list builder.
  DefinitionList({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  final List<(String, String)> _items = [];
  String _separator = ':';
  int _indent = 2;
  int _gap = 1;
  bool _alignTerms = true;
  Style? _termStyle;
  Style? _descriptionStyle;
  Style? _separatorStyle;
  DefinitionStyleFunc? _styleFunc;

  /// Adds an item (term: description) to the list.
  DefinitionList item(String term, String description) {
    _items.add((term, description));
    return this;
  }

  /// Adds multiple items from a map.
  DefinitionList items(Map<String, String> items) {
    for (final entry in items.entries) {
      _items.add((entry.key, entry.value));
    }
    return this;
  }

  /// Sets the separator between term and description (default: ':').
  DefinitionList separator(String sep) {
    _separator = sep;
    return this;
  }

  /// Sets the left indent (default: 2).
  DefinitionList indent(int value) {
    _indent = value;
    return this;
  }

  /// Sets the gap between term and description (default: 1).
  DefinitionList gap(int value) {
    _gap = value;
    return this;
  }

  /// Sets whether to align terms to the same width (default: true).
  DefinitionList alignTerms(bool value) {
    _alignTerms = value;
    return this;
  }

  /// Sets the term style.
  DefinitionList termStyle(Style style) {
    _termStyle = style;
    return this;
  }

  /// Sets the description style.
  DefinitionList descriptionStyle(Style style) {
    _descriptionStyle = style;
    return this;
  }

  /// Sets the separator style.
  DefinitionList separatorStyle(Style style) {
    _separatorStyle = style;
    return this;
  }

  /// Sets a style function for dynamic styling.
  DefinitionList styleFunc(DefinitionStyleFunc func) {
    _styleFunc = func;
    return this;
  }

  /// Applies term styling.
  String _applyTermStyle(String text, String description, int index) {
    if (_styleFunc != null) {
      final style = _styleFunc!(text, description, index, true);
      if (style != null) {
        return _renderConfig.configureStyle(style).render(text);
      }
    }
    if (_termStyle != null) {
      return _renderConfig.configureStyle(_termStyle!).render(text);
    }
    return text;
  }

  /// Applies description styling.
  String _applyDescriptionStyle(String text, String term, int index) {
    if (_styleFunc != null) {
      final style = _styleFunc!(term, text, index, false);
      if (style != null) {
        return _renderConfig.configureStyle(style).render(text);
      }
    }
    if (_descriptionStyle != null) {
      return _renderConfig.configureStyle(_descriptionStyle!).render(text);
    }
    return text;
  }

  /// Applies separator styling.
  String _applySeparatorStyle(String text) {
    if (_separatorStyle != null) {
      return _renderConfig.configureStyle(_separatorStyle!).render(text);
    }
    return text;
  }

  @override
  String render() {
    if (_items.isEmpty) return '';

    final buffer = StringBuffer();

    // Calculate max term width if aligning
    var maxTermLen = 0;
    if (_alignTerms) {
      for (final (term, _) in _items) {
        final len = Style.visibleLength(term);
        if (len > maxTermLen) maxTermLen = len;
      }
    }

    final indentStr = ' ' * _indent;
    final gapStr = ' ' * _gap;

    for (var i = 0; i < _items.length; i++) {
      if (i > 0) buffer.writeln();

      final (term, description) = _items[i];

      // Pad term if aligning
      String paddedTerm;
      if (_alignTerms) {
        final termLen = Style.visibleLength(term);
        final padding = ' ' * (maxTermLen - termLen);
        paddedTerm = '$term$padding';
      } else {
        paddedTerm = term;
      }

      final styledTerm = _applyTermStyle(paddedTerm, description, i);
      final styledSeparator = _applySeparatorStyle(_separator);
      final styledDescription = _applyDescriptionStyle(description, term, i);

      buffer.write(
        '$indentStr$styledTerm$styledSeparator$gapStr$styledDescription',
      );
    }

    return buffer.toString();
  }

  @override
  int get lineCount => _items.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouped Definition List Builder
// ─────────────────────────────────────────────────────────────────────────────

/// A fluent builder for creating grouped definition lists.
///
/// Supports multiple groups with headers.
///
/// ```dart
/// final list = GroupedDefinitionList()
///     .group('Package Info', {
///       'Name': 'artisanal',
///       'Version': '1.0.0',
///     })
///     .group('Dependencies', {
///       'dart': '^3.0.0',
///       'meta': '^1.9.0',
///     })
///     .headerStyle(Style().bold().underline())
///     .render();
///
/// print(list);
/// ```
class GroupedDefinitionList extends DisplayComponent {
  /// Creates a new empty grouped definition list builder.
  GroupedDefinitionList({RenderConfig renderConfig = const RenderConfig()})
    : _renderConfig = renderConfig;

  final RenderConfig _renderConfig;

  final List<(String, Map<String, String>)> _groups = [];
  String _separator = ':';
  int _indent = 2;
  int _groupIndent = 0;
  int _gap = 1;
  bool _alignTerms = true;
  bool _alignAcrossGroups = false;
  Style? _headerStyle;
  Style? _termStyle;
  Style? _descriptionStyle;
  Style? _separatorStyle;
  DefinitionStyleFunc? _styleFunc;
  int _groupSpacing = 1;

  /// Adds a group with a header and items.
  GroupedDefinitionList group(String header, Map<String, String> items) {
    _groups.add((header, items));
    return this;
  }

  /// Sets the separator between term and description (default: ':').
  GroupedDefinitionList separator(String sep) {
    _separator = sep;
    return this;
  }

  /// Sets the item indent within groups (default: 2).
  GroupedDefinitionList indent(int value) {
    _indent = value;
    return this;
  }

  /// Sets the group header indent (default: 0).
  GroupedDefinitionList groupIndent(int value) {
    _groupIndent = value;
    return this;
  }

  /// Sets the gap between term and description (default: 1).
  GroupedDefinitionList gap(int value) {
    _gap = value;
    return this;
  }

  /// Sets whether to align terms within each group (default: true).
  GroupedDefinitionList alignTerms(bool value) {
    _alignTerms = value;
    return this;
  }

  /// Sets whether to align terms across all groups (default: false).
  GroupedDefinitionList alignAcrossGroups(bool value) {
    _alignAcrossGroups = value;
    return this;
  }

  /// Sets the spacing between groups (default: 1).
  GroupedDefinitionList groupSpacing(int value) {
    _groupSpacing = value;
    return this;
  }

  /// Sets the header style.
  GroupedDefinitionList headerStyle(Style style) {
    _headerStyle = style;
    return this;
  }

  /// Sets the term style.
  GroupedDefinitionList termStyle(Style style) {
    _termStyle = style;
    return this;
  }

  /// Sets the description style.
  GroupedDefinitionList descriptionStyle(Style style) {
    _descriptionStyle = style;
    return this;
  }

  /// Sets the separator style.
  GroupedDefinitionList separatorStyle(Style style) {
    _separatorStyle = style;
    return this;
  }

  /// Sets a style function for dynamic styling.
  GroupedDefinitionList styleFunc(DefinitionStyleFunc func) {
    _styleFunc = func;
    return this;
  }

  /// Applies header styling.
  String _applyHeaderStyle(String text) {
    if (_headerStyle != null) {
      return _renderConfig.configureStyle(_headerStyle!).render(text);
    }
    // Default to bold
    return _renderConfig.configureStyle(Style().bold()).render(text);
  }

  @override
  String render() {
    if (_groups.isEmpty) return '';

    final buffer = StringBuffer();

    // Calculate max term width across all groups if needed
    var globalMaxTermLen = 0;
    if (_alignAcrossGroups) {
      for (final (_, items) in _groups) {
        for (final term in items.keys) {
          final len = Style.visibleLength(term);
          if (len > globalMaxTermLen) globalMaxTermLen = len;
        }
      }
    }

    final groupIndentStr = ' ' * _groupIndent;
    final spacingLines = '\n' * _groupSpacing;

    for (var g = 0; g < _groups.length; g++) {
      if (g > 0) buffer.write(spacingLines);

      final (header, items) = _groups[g];

      // Render header
      buffer.writeln('$groupIndentStr${_applyHeaderStyle(header)}');

      // Build definition list for this group
      final list = DefinitionList(renderConfig: _renderConfig)
        ..items(items)
        ..separator(_separator)
        ..indent(_indent)
        ..gap(_gap)
        ..alignTerms(_alignTerms);

      if (_termStyle != null) list.termStyle(_termStyle!);
      if (_descriptionStyle != null) list.descriptionStyle(_descriptionStyle!);
      if (_separatorStyle != null) list.separatorStyle(_separatorStyle!);
      if (_styleFunc != null) list.styleFunc(_styleFunc!);

      buffer.write(list.render());
    }

    return buffer.toString();
  }

  @override
  int get lineCount {
    var count = 0;
    for (var g = 0; g < _groups.length; g++) {
      count += 1; // header
      count += _groups[g].$2.length; // items
      if (g < _groups.length - 1) count += _groupSpacing; // spacing
    }
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory Methods
// ─────────────────────────────────────────────────────────────────────────────

/// Factory methods for common definition list styles.
extension DefinitionListFactory on DefinitionList {
  /// Creates a simple definition list from a map.
  static DefinitionList fromMap(Map<String, String> items) {
    return DefinitionList()..items(items);
  }

  /// Creates a styled definition list with bold terms.
  static DefinitionList boldTerms(Map<String, String> items) {
    return DefinitionList()
      ..items(items)
      ..termStyle(Style().bold());
  }

  /// Creates a definition list with colored terms.
  static DefinitionList coloredTerms(Map<String, String> items, Color color) {
    return DefinitionList()
      ..items(items)
      ..termStyle(Style().foreground(color));
  }

  /// Creates a definition list with info styling.
  static DefinitionList info(Map<String, String> items) {
    return DefinitionList()
      ..items(items)
      ..termStyle(Style().bold().foreground(Colors.info))
      ..separatorStyle(Style().dim());
  }

  /// Creates a definition list with muted styling.
  static DefinitionList muted(Map<String, String> items) {
    return DefinitionList()
      ..items(items)
      ..termStyle(Style().dim())
      ..descriptionStyle(Style().dim())
      ..separatorStyle(Style().dim());
  }

  /// Creates a definition list without separator alignment.
  static DefinitionList compact(Map<String, String> items) {
    return DefinitionList()
      ..items(items)
      ..alignTerms(false)
      ..gap(0);
  }

  /// Creates a definition list with arrow separator.
  static DefinitionList arrows(Map<String, String> items) {
    return DefinitionList()
      ..items(items)
      ..separator('→')
      ..gap(1);
  }

  /// Creates a definition list with equals separator.
  static DefinitionList equals(Map<String, String> items) {
    return DefinitionList()
      ..items(items)
      ..separator('=')
      ..gap(1);
  }
}
