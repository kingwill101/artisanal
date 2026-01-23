/// Lipgloss-style List component for terminal output.
///
/// Provides a fluent, chainable API for creating styled lists.
///
/// ```dart
/// final list = LipList.create(['Foo', 'Bar', 'Baz'])
///     .enumerator(ListEnumerators.bullet)
///     .itemStyle(Style().foreground(Colors.cyan));
///
/// print(list);
/// ```
library;

import 'style.dart';
import '../tui/bubbles/components/tree.dart' as lip_tree;
import '../tui/bubbles/components/base.dart' show RenderConfig;

/// Callback for determining the style of a list item.
typedef ListStyleFunc = Style Function(ListItems items, int index);

/// Callback for generating the enumerator string for a list item.
typedef ListEnumeratorFunc = String Function(ListItems items, int index);

/// Callback for generating indentation for nested items.
typedef ListIndenterFunc = String Function(ListItems items, int index);

/// Provides access to list items for style/enumerator functions.
abstract class ListItems {
  /// Returns the item at the given index.
  ListItem at(int index);

  /// Returns the number of items.
  int get length;
}

/// A single item in a list.
abstract class ListItem {
  /// The value/content of this item.
  String get value;

  /// The children of this item (for nested lists).
  ListItems get children;

  /// Whether this item is hidden.
  bool get hidden;
}

final class _TreeListItems implements ListItems {
  _TreeListItems(this._nodes);

  final List<lip_tree.TreeNode> _nodes;

  @override
  ListItem at(int index) {
    if (index < 0 || index >= _nodes.length) return const _TreeListItem.empty();
    return _TreeListItem(_nodes[index]);
  }

  @override
  int get length => _nodes.length;
}

final class _TreeListItem implements ListItem {
  const _TreeListItem(this._node);

  const _TreeListItem.empty() : _node = null;

  final lip_tree.TreeNode? _node;

  @override
  String get value => _node?.value ?? '';

  @override
  ListItems get children =>
      _TreeListItems(_node?.childrenNodes.toList(growable: false) ?? const []);

  @override
  bool get hidden => _node?.hidden ?? true;
}

// ═══════════════════════════════════════════════════════════════════════════
// LipList - Fluent List Builder
// ═══════════════════════════════════════════════════════════════════════════

/// A fluent, chainable list builder inspired by Go's lipgloss list.
///
/// ```dart
/// final groceries = LipList.create([
///   'Bananas',
///   'Barley',
///   'Cashews',
///   LipList.create(['Almond Milk', 'Coconut Milk', 'Full Fat Milk']),
///   'Eggs',
/// ]);
///
/// print(groceries);
/// ```
class LipList {
  LipList({RenderConfig renderConfig = const RenderConfig()})
    : _tree = lip_tree.Tree(renderConfig: renderConfig, showRoot: false) {
    // Mirror lipgloss v2 defaults: enumerator + indenter styles include
    // right padding of 1, and we render without inserting an extra space
    // between prefix and item.
    enumeratorStyleFunc((_, _) => Style().paddingRight(1));
    indenterStyleFunc((_, _) => Style().paddingRight(1));
  }

  final lip_tree.Tree _tree;
  ListEnumeratorFunc _enumerator = ListEnumerators.bullet;
  ListIndenterFunc _indenter = (_, _) => ' ';
  ListStyleFunc _itemStyleFunc = (_, _) => Style();
  ListStyleFunc _enumeratorStyleFunc = (_, _) => Style().paddingRight(1);
  ListStyleFunc _indenterStyleFunc = (_, _) => Style().paddingRight(1);

  /// Creates a new list with the given items.
  ///
  /// Items can be strings, other LipLists (for nesting), or any object
  /// that can be converted to a string.
  factory LipList.create(
    List<dynamic> items, {
    RenderConfig renderConfig = const RenderConfig(),
  }) {
    return LipList(renderConfig: renderConfig).items(items);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Item Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Adds a single item to the list.
  ///
  /// [item] can be a string, LipList (for nesting), or any object.
  LipList item(dynamic item) {
    switch (item) {
      case null:
        break;
      case LipList list:
        _tree.child(list._tree);
      case lip_tree.Tree tree:
        _tree.child(tree);
      case List<dynamic> items:
        for (final it in items) {
          this.item(it);
        }
      case Iterable<dynamic> items:
        for (final it in items) {
          this.item(it);
        }
      default:
        _tree.child(item.toString());
    }
    return this;
  }

  /// Adds multiple items to the list.
  LipList items(List<dynamic> items) {
    for (final item in items) {
      this.item(item);
    }
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Enumerator & Indenter
  // ─────────────────────────────────────────────────────────────────────────

  /// Sets the list enumerator.
  ///
  /// The enumerator generates the prefix for each item (e.g., "•", "1.", "a.").
  ///
  /// ```dart
  /// list.enumerator(ListEnumerators.arabic)  // 1. 2. 3.
  /// list.enumerator(ListEnumerators.roman)   // I. II. III.
  /// list.enumerator(ListEnumerators.bullet)  // • • •
  /// ```
  LipList enumerator(ListEnumeratorFunc fn) {
    _enumerator = fn;
    _syncRenderer();
    return this;
  }

  /// Sets the indenter for nested items.
  ///
  /// The indenter generates the prefix for child items at each level.
  LipList indenter(ListIndenterFunc fn) {
    _indenter = fn;
    _syncRenderer();
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Styling
  // ─────────────────────────────────────────────────────────────────────────

  /// Sets a static style for all items.
  LipList itemStyle(Style style) {
    _itemStyleFunc = (_, _) => style;
    _syncRenderer();
    return this;
  }

  /// Sets a function to determine item style per-item.
  LipList itemStyleFunc(ListStyleFunc fn) {
    _itemStyleFunc = fn;
    _syncRenderer();
    return this;
  }

  /// Sets a static style for all enumerators.
  LipList enumeratorStyle(Style style) {
    _enumeratorStyleFunc = (_, _) => style;
    _syncRenderer();
    return this;
  }

  /// Sets a function to determine enumerator style per-item.
  LipList enumeratorStyleFunc(ListStyleFunc fn) {
    _enumeratorStyleFunc = fn;
    _syncRenderer();
    return this;
  }

  /// Sets a static style for all indenters.
  LipList indenterStyle(Style style) {
    _indenterStyleFunc = (_, _) => style;
    _syncRenderer();
    return this;
  }

  /// Sets the indenter style function for list items.
  LipList indenterStyleFunc(ListStyleFunc fn) {
    _indenterStyleFunc = fn;
    _syncRenderer();
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Visibility & Offset
  // ─────────────────────────────────────────────────────────────────────────

  /// Hides this list from rendering.
  LipList hide([bool hidden = true]) {
    _tree.hide(hidden);
    return this;
  }

  /// Returns whether this list is hidden.
  bool get isHidden => _tree.hidden;

  /// Sets the start and end offset for the list.
  ///
  /// This allows showing a subset of items. Negative end values count from
  /// the end of the list.
  ///
  /// ```dart
  /// list.offset(1, -1)  // Skip first and last items
  /// ```
  LipList offset(int start, [int end = 0]) {
    _tree.offset(start, end);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rendering
  // ─────────────────────────────────────────────────────────────────────────

  /// Renders the list to a string.
  String render() {
    _syncRenderer();
    return _tree.render().trimRight();
  }

  void _syncRenderer() {
    final children = _tree.childrenNodes.toList(growable: false);
    final listItems = _TreeListItems(children);

    _tree
      ..enumeratorFunc((sibs, i) {
        // We intentionally use the *current* children snapshot to match
        // lipgloss' siblings semantics for style functions.
        return _enumerator(listItems, i);
      })
      ..indenterFunc((sibs, i) => _indenter(listItems, i))
      ..itemStyleFunc((sibs, i) => _itemStyleFunc(listItems, i))
      ..enumeratorStyleFunc((sibs, i) => _enumeratorStyleFunc(listItems, i))
      ..indenterStyleFunc((sibs, i) => _indenterStyleFunc(listItems, i));
  }

  @override
  String toString() => render();
}

// ═══════════════════════════════════════════════════════════════════════════
// Predefined Enumerators
// ═══════════════════════════════════════════════════════════════════════════

/// Predefined list enumerators.
class ListEnumerators {
  ListEnumerators._();

  /// Bullet enumerator (•).
  static String bullet(ListItems items, int index) => '•';

  /// Dash enumerator (-).
  static String dash(ListItems items, int index) => '-';

  /// Asterisk enumerator (*).
  static String asterisk(ListItems items, int index) => '*';

  /// Arabic numerals (1. 2. 3.).
  static String arabic(ListItems items, int index) => '${index + 1}.';

  /// Alphabetic (a. b. c.).
  static String alphabet(ListItems items, int index) {
    return '${_toAlphaUpper(index)}.';
  }

  /// Uppercase alphabetic (A. B. C.).
  static String alphabetUpper(ListItems items, int index) {
    return '${_toAlphaUpper(index)}.';
  }

  /// Roman numerals (I. II. III.).
  static String roman(ListItems items, int index) {
    return '${_toRoman(index + 1)}.';
  }

  /// Lowercase roman numerals (i. ii. iii.).
  static String romanLower(ListItems items, int index) {
    return '${_toRoman(index + 1).toLowerCase()}.';
  }

  /// Creates a fixed enumerator that always returns the same string.
  static ListEnumeratorFunc fixed(String symbol) {
    return (_, _) => symbol;
  }

  /// Creates a custom enumerator from a simple index function.
  static ListEnumeratorFunc custom(String Function(int index) fn) {
    return (_, i) => fn(i);
  }

  // Helper: Convert number to alphabetic (0=a, 1=b, 26=aa, etc.)
  static String _toAlphaUpper(int index) {
    const abcLen = 26;
    final i = index;
    if (i >= abcLen * abcLen + abcLen) {
      final a = (i ~/ abcLen ~/ abcLen) - 1;
      final b = (i ~/ abcLen) % abcLen - 1;
      final c = i % abcLen;
      return String.fromCharCodes([0x41 + a, 0x41 + b, 0x41 + c]);
    }
    if (i >= abcLen) {
      final a = (i ~/ abcLen) - 1;
      final b = i % abcLen;
      return String.fromCharCodes([0x41 + a, 0x41 + b]);
    }
    return String.fromCharCode(0x41 + (i % abcLen));
  }

  // Helper: Convert number to roman numerals
  static String _toRoman(int n) {
    if (n <= 0) return '';
    final numerals = [
      ['M', 1000],
      ['CM', 900],
      ['D', 500],
      ['CD', 400],
      ['C', 100],
      ['XC', 90],
      ['L', 50],
      ['XL', 40],
      ['X', 10],
      ['IX', 9],
      ['V', 5],
      ['IV', 4],
      ['I', 1],
    ];
    final result = StringBuffer();
    var remaining = n;
    for (final entry in numerals) {
      final symbol = entry[0] as String;
      final value = entry[1] as int;
      while (remaining >= value) {
        result.write(symbol);
        remaining -= value;
      }
    }
    return result.toString();
  }
}

/// Predefined list indenters.
class ListIndenters {
  ListIndenters._();

  /// Single space indent.
  static String space(ListItems items, int index) => ' ';

  /// Double space indent.
  static String doubleSpace(ListItems items, int index) => '  ';

  /// Tab-like indent (4 spaces).
  static String tab(ListItems items, int index) => '    ';

  /// Tree-style indent with pipe for non-last items.
  static String tree(ListItems items, int index) {
    if (index == items.length - 1) {
      return '   ';
    }
    return '│  ';
  }

  /// Arrow indent.
  static String arrow(ListItems items, int index) => '→ ';

  /// Creates a fixed indenter.
  static ListIndenterFunc fixed(String indent) =>
      (_, _) => indent;
}
