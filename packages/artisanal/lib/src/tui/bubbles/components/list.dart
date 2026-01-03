import '../../../style/style.dart';
import 'base.dart';

/// Callback for per-item styling in lists.
///
/// [index] is the item index (0-based).
/// [item] is the item content.
typedef ListStyleFunc = Style? Function(int index, String item);

/// Defines how list items are explicitly enumerated.
class ListEnumerator {
  /// Creates a custom enumerator.
  const ListEnumerator(this._builder);

  final String Function(int index) _builder;

  /// Generates the enumeration string for the given index.
  String call(int index) => _builder(index);

  /// Creates a fixed enumerator (repeats the same string).
  static ListEnumerator fixed(String symbol) => ListEnumerator((_) => symbol);

  /// Standard bullet (•).
  static final bullet = fixed('•');

  /// Arabic numerals (1., 2., 3.).
  static final arabic = ListEnumerator((i) => '${i + 1}.');

  /// Lowercase alphabet (a., b., c.).
  static final alphabet = ListEnumerator((i) => '${_toAlpha(i + 1)}.');

  /// Uppercase roman numerals (I., II., III.).
  static final roman = ListEnumerator((i) => '${_toRoman(i + 1)}.');
}

String _toAlpha(int n) {
  if (n <= 0) return '';
  final result = StringBuffer();
  while (n > 0) {
    n--;
    result.writeCharCode(97 + (n % 26));
    n ~/= 26;
  }
  return result.toString().split('').reversed.join('');
}

String _toRoman(int n) {
  if (n <= 0) return '';
  if (n >= 1000) return 'M${_toRoman(n - 1000)}';
  if (n >= 900) return 'CM${_toRoman(n - 900)}';
  if (n >= 500) return 'D${_toRoman(n - 500)}';
  if (n >= 400) return 'CD${_toRoman(n - 400)}';
  if (n >= 100) return 'C${_toRoman(n - 100)}';
  if (n >= 90) return 'XC${_toRoman(n - 90)}';
  if (n >= 50) return 'L${_toRoman(n - 50)}';
  if (n >= 40) return 'XL${_toRoman(n - 40)}';
  if (n >= 10) return 'X${_toRoman(n - 10)}';
  if (n >= 9) return 'IX${_toRoman(n - 9)}';
  if (n >= 5) return 'V${_toRoman(n - 5)}';
  if (n >= 4) return 'IV${_toRoman(n - 4)}';
  return 'I${_toRoman(n - 1)}';
}

/// A bullet list component.
class BulletList extends DisplayComponent {
  const BulletList({
    required this.items,
    this.bullet = '•',
    this.indent = 2,
    this.enumerator,
    this.itemStyleFunc,
    this.renderConfig = const RenderConfig(),
  });

  final List<String> items;
  final String bullet;
  final int indent;
  final ListEnumerator? enumerator;
  final ListStyleFunc? itemStyleFunc;
  final RenderConfig renderConfig;

  @override
  String render() {
    final buffer = StringBuffer();
    final prefix = ' ' * indent;
    final enumFn = enumerator ?? ListEnumerator.fixed(bullet);

    for (var i = 0; i < items.length; i++) {
      final symbol = enumFn(i);
      var text = items[i];

      if (itemStyleFunc != null) {
        final style = itemStyleFunc!(i, text);
        if (style != null) {
          renderConfig.configureStyle(style);
          text = style.render(text);
        }
      }

      buffer.write('$prefix$symbol $text');
      if (i < items.length - 1) buffer.writeln();
    }

    return buffer.toString();
  }
}

/// A numbered list component.
class NumberedList extends DisplayComponent {
  const NumberedList({
    required this.items,
    this.indent = 2,
    this.startAt = 1,
    this.enumerator,
    this.itemStyleFunc,
    this.renderConfig = const RenderConfig(),
  });

  final List<String> items;
  final int indent;
  final int startAt;
  final ListEnumerator? enumerator;
  final ListStyleFunc? itemStyleFunc;
  final RenderConfig renderConfig;

  @override
  String render() {
    final buffer = StringBuffer();
    final prefix = ' ' * indent;
    final enumFn = enumerator ?? ListEnumerator.arabic;

    // Pre-calculate symbols to align widths
    final symbols = <String>[];
    var maxSymbolWidth = 0;

    for (var i = 0; i < items.length; i++) {
      // Offset index by startAt for generation
      // If we use default arabic generator, it expects 0-based index and adds 1.
      // But if startAt is 5, we want pass 4 (so it produces 5.)?
      // Or we just rely on `enumerator` taking raw index and we trust user used correct one?
      // For default arabic, we need to shift.
      // But if user provides custom enumerator, shifting might be wrong.
      // Let's assume enumerator receives logical index (0-based iteration index + startAt - 1).
      // If startAt is 1, we pass 0, 1, 2...
      // If startAt is 5, we pass 4, 5, 6...
      final logicalIndex = (startAt - 1) + i;
      final s = enumFn(logicalIndex);
      symbols.add(s);
      if (s.length > maxSymbolWidth) maxSymbolWidth = s.length;
    }

    for (var i = 0; i < items.length; i++) {
      final symbol = symbols[i].padLeft(maxSymbolWidth);
      var text = items[i];

      if (itemStyleFunc != null) {
        final style = itemStyleFunc!(i, text);
        if (style != null) {
          renderConfig.configureStyle(style);
          text = style.render(text);
        }
      }

      buffer.write('$prefix$symbol $text');
      if (i < items.length - 1) buffer.writeln();
    }

    return buffer.toString();
  }
}
