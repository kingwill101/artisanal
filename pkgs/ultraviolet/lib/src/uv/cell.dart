/// Cell model: glyph content, style, link, and display width.
///
/// A [Cell] holds a single grapheme (`content`), its `width`, a [UvStyle]
/// (foreground/background color, underline, attributes), and an optional
/// [Link] for terminals that support hyperlinks. Colors are represented by
/// [UvColor] with palette variants [UvBasic16], [UvIndexed256], and true color
/// [UvRgb].
///
/// {@category Ultraviolet}
/// {@subCategory Cells & Colors}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final cell = Cell(
///   content: 'A',
///   style: const UvStyle(fg: UvColor.rgb(255, 0, 0)),
///   link: const Link(url: 'https://example.com'),
/// );
/// ```
library;

import '../unicode/width.dart';

/// Underline style for terminal cells.
enum UnderlineStyle { none, single, double, curly, dotted, dashed }

/// Terminal hyperlink metadata (OSC 8).
///
/// Carries a target [url] and optional [params] for terminals supporting
/// OSC 8 hyperlinks.
final class Link {
  const Link({this.url = '', this.params = ''});

  final String url;
  final String params;

  /// Whether this link has no URL or parameters.
  bool get isZero => url.isEmpty && params.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Link && other.url == url && other.params == params;

  @override
  int get hashCode => _mixHash(url.hashCode, params.hashCode);
}

/// Color representation sufficient for Ultraviolet parity tests.
///
/// uses `x/ansi` helpers for named/indexed colors.
/// Unified UV color representation across palettes and true color.
///
/// Use [UvBasic16] for 16-color palette, [UvIndexed256] for 256-color
/// indexed palette, and [UvRgb] for 24-bit RGB.
sealed class UvColor {
  const UvColor();

  const factory UvColor.basic16(int index, {bool bright}) = UvBasic16;
  const factory UvColor.indexed256(int index) = UvIndexed256;
  const factory UvColor.rgb(int r, int g, int b, {int a}) = UvRgb;
}

/// 16-color palette index (optionally bright).
final class UvBasic16 extends UvColor {
  const UvBasic16(this.index, {this.bright = false});

  final int index; // 0..7
  final bool bright;

  @override
  bool operator ==(Object other) =>
      other is UvBasic16 && other.index == index && other.bright == bright;

  @override
  int get hashCode => index | (bright ? 0x100 : 0);
}

/// 256-color indexed palette entry.
final class UvIndexed256 extends UvColor {
  const UvIndexed256(this.index);

  final int index; // 0..255

  @override
  bool operator ==(Object other) =>
      other is UvIndexed256 && other.index == index;

  @override
  int get hashCode => index;
}

/// 24-bit RGBA color.
final class UvRgb extends UvColor {
  const UvRgb(this.r, this.g, this.b, {this.a = 255});

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) =>
      other is UvRgb &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.a == a;

  @override
  int get hashCode => r | (g << 8) | (b << 16) | (a << 24);
}

/// Text attributes (bitmask).
///
abstract final class Attr {
  static const int bold = 1 << 0;
  static const int faint = 1 << 1;
  static const int italic = 1 << 2;
  static const int blink = 1 << 3;
  static const int rapidBlink = 1 << 4;
  static const int reverse = 1 << 5;
  static const int conceal = 1 << 6;
  static const int strikethrough = 1 << 7;
}

/// Style attributes for a terminal [Cell].
final class UvStyle {
  const UvStyle({
    this.fg,
    this.bg,
    this.underlineColor,
    this.underline = UnderlineStyle.none,
    this.attrs = 0,
  });

  final UvColor? fg;
  final UvColor? bg;
  final UvColor? underlineColor;
  final UnderlineStyle underline;
  final int attrs;

  /// A packed metadata key for this style.
  ///
  /// This folds colors, underline mode, and attributes into one stable integer
  /// so callers can cheaply compare and cache style state.
  int get packedKey => _packStyleExact(this);

  /// Whether this style has no attributes or colors set.
  bool get isZero =>
      fg == null &&
      bg == null &&
      underlineColor == null &&
      underline == UnderlineStyle.none &&
      attrs == 0;

  /// Returns a copy of this style with selected fields updated.
  UvStyle copyWith({
    UvColor? fg,
    bool clearFg = false,
    UvColor? bg,
    bool clearBg = false,
    UvColor? underlineColor,
    bool clearUnderlineColor = false,
    UnderlineStyle? underline,
    int? attrs,
  }) {
    return UvStyle(
      fg: clearFg ? null : (fg ?? this.fg),
      bg: clearBg ? null : (bg ?? this.bg),
      underlineColor: clearUnderlineColor
          ? null
          : (underlineColor ?? this.underlineColor),
      underline: underline ?? this.underline,
      attrs: attrs ?? this.attrs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UvStyle &&
      other.packedKey == packedKey &&
      other.fg == fg &&
      other.bg == bg &&
      other.underlineColor == underlineColor &&
      other.underline == underline &&
      other.attrs == attrs;

  @override
  int get hashCode => packedKey;
}

/// Fixed-size packed representation of a [Cell].
///
/// This is structured into four machine-word lanes so it can be compared as a
/// small SIMD-sized tuple in hot diff paths.
final class PackedCell {
  const PackedCell({
    required this.word0,
    required this.word1,
    required this.word2,
    required this.word3,
  });

  final int word0;
  final int word1;
  final int word2;
  final int word3;

  /// Returns a copy of the words as a fixed-length list for compact inspection.
  List<int> get words => <int>[word0, word1, word2, word3];

  @override
  bool operator ==(Object other) =>
      other is PackedCell &&
      other.word0 == word0 &&
      other.word1 == word1 &&
      other.word2 == word2 &&
      other.word3 == word3;

  @override
  int get hashCode => Object.hash(word0, word1, word2, word3);
}

/// A single cell in a terminal [Buffer].
///
/// A cell contains one grapheme, a [UvStyle], an optional [Link], and its
/// display width. This Dart port keeps the public mutable API but also caches a
/// packed metadata signature so equality and hashing stay fast for the common
/// case of plain single-rune cells.
///
final class Cell {
  Cell({
    String content = '',
    UvStyle style = const UvStyle(),
    Link link = const Link(),
    this.drawable,
    int? width,
  }) {
    _width = width ?? (content.isEmpty ? 0 : 1);
    _setContent(content);
    _setStyle(style);
    _setLink(link);
  }

  Cell._packed({
    required UvStyle style,
    required Link link,
    required int width,
    required int contentKind,
    required int contentValue,
    required int styleId,
    required int linkId,
    this.drawable,
  }) : _style = style,
       _link = link,
       _width = width,
       _contentKind = contentKind,
       _contentValue = contentValue,
       _styleId = styleId,
       _linkId = linkId {
    _attachPooledContentFinalizerIfNeeded();
    _attachLinkFinalizerIfNeeded();
  }

  UvStyle _style = const UvStyle();
  Link _link = const Link();
  int _width = 0;
  int _contentKind = _CellContentKind.empty;
  int _contentValue = 0;
  int _styleId = 0;
  int _linkId = 0;
  final Object _pooledContentToken = Object();
  final Object _linkFinalizerToken = Object();

  static final Finalizer<int> _pooledContentFinalizer = Finalizer<int>((id) {
    _graphemePool.release(id);
  });
  static final Finalizer<int> _linkFinalizer = Finalizer<int>((id) {
    _linkRegistry.release(id);
  });

  /// The grapheme content stored in this cell.
  String get content => switch (_contentKind) {
    _CellContentKind.empty => '',
    _CellContentKind.space => ' ',
    _CellContentKind.singleScalar
        when _contentValue < _asciiScalarStrings.length =>
      _asciiScalarStrings[_contentValue],
    _CellContentKind.singleScalar => String.fromCharCode(_contentValue),
    _CellContentKind.complex => _graphemePool.resolve(_contentValue),
    _ => '',
  };
  set content(String value) => _setContent(value);

  /// The canonicalized style for this cell.
  UvStyle get style => _style;
  set style(UvStyle value) => _setStyle(value);

  /// The canonicalized hyperlink metadata for this cell.
  Link get link => _link;
  set link(Link value) => _setLink(value);

  /// The display width of this cell in terminal columns.
  int get width => _width;
  set width(int value) {
    _width = value;
    _updatePackedContent();
  }

  Object? drawable;

  /// Returns a fixed-layout packed cell tuple for fast comparisons.
  ///
  /// Layout:
  /// - `word0`: content kind/width plus low content bits
  /// - `word1`: content high bits
  /// - `word2`: canonicalized style identity
  /// - `word3`: canonicalized link identity
  PackedCell get packed {
    final contentLo = _contentValue & _contentPackLoMask;
    final contentHi = _contentValue >>> _contentValueBits;
    return PackedCell(
      word0:
          (_contentKind & _cellContentKindMask) |
          ((_width & _cellWidthMask) << _cellWidthShift) |
          (contentLo << _packedContentShift),
      word1: contentHi,
      word2: _styleId,
      word3: _linkId,
    );
  }

  /// The pooled complex grapheme id for this cell, if any.
  ///
  /// This is primarily useful for diagnostics and tests.
  int? get pooledContentId =>
      _contentKind == _CellContentKind.complex ? _contentValue : null;

  /// The pooled link id for this cell, if any.
  ///
  /// This is primarily useful for diagnostics and tests.
  int? get linkId => _linkId == 0 ? null : _linkId;

  /// A compact identity for just the cell content, excluding width/style/link.
  ///
  /// This is used by line-level hashing to avoid reconstructing grapheme text
  /// when only content equality matters.
  int get contentFingerprint => _mixHash(_contentKind, _contentValue);

  /// A compact identity for full rendered output at one cell slot.
  ///
  /// This includes style, link, width, and drawable identity so renderer-side
  /// line hashing can cheaply detect visual changes without reconstructing
  /// grapheme text.
  int get renderFingerprint => _mixHash(
    _mixHash(_mixHash(_contentKind, _contentValue), _width),
    _mixHash(_mixHash(_styleId, _linkId), identityHashCode(drawable)),
  );

  /// Whether this cell has no content, style, link, or drawable.
  bool get isZero =>
      _contentKind == _CellContentKind.empty &&
      _width == 0 &&
      _styleId == 0 &&
      _linkId == 0 &&
      drawable == null;

  /// Whether this cell represents a plain space with no attributes.
  bool get isEmpty =>
      _contentKind == _CellContentKind.space &&
      _width == 1 &&
      _styleId == 0 &&
      _linkId == 0 &&
      drawable == null;

  /// Returns a copy of this cell.
  Cell clone() {
    if (_contentKind == _CellContentKind.complex) {
      _graphemePool.retain(_contentValue);
    }
    if (_linkId != 0) {
      _linkRegistry.retain(_linkId);
    }
    return Cell._packed(
      style: _style,
      link: _link,
      width: _width,
      contentKind: _contentKind,
      contentValue: _contentValue,
      styleId: _styleId,
      linkId: _linkId,
      drawable: drawable,
    );
  }

  /// Returns a blank space cell with the same style/link/drawable metadata.
  ///
  /// This avoids cloning pooled grapheme content when wide-cell overwrite
  /// semantics only need a cleared replacement.
  Cell cloneEmpty() {
    if (_linkId != 0) {
      _linkRegistry.retain(_linkId);
    }
    return Cell._packed(
      style: _style,
      link: _link,
      width: 1,
      contentKind: _CellContentKind.space,
      contentValue: 0,
      styleId: _styleId,
      linkId: _linkId,
      drawable: drawable,
    );
  }

  /// Copies the full cell payload from [other] into this instance.
  ///
  /// This lets hot buffer paths update an existing slot without allocating a
  /// replacement `Cell` object first.
  void copyFrom(Cell other) {
    if (identical(this, other)) return;
    _releaseLink();
    _releasePooledContent();
    _style = other._style;
    _styleId = other._styleId;
    _link = other._link;
    _linkId = other._linkId;
    _width = other._width;
    _contentKind = other._contentKind;
    _contentValue = other._contentValue;
    drawable = other.drawable;
    if (_contentKind == _CellContentKind.complex) {
      _graphemePool.retain(_contentValue);
      _attachPooledContentFinalizerIfNeeded();
    }
    if (_linkId != 0) {
      _linkRegistry.retain(_linkId);
      _attachLinkFinalizerIfNeeded();
    }
  }

  /// Copies just the style/link/drawable payload from [other] and clears the
  /// content to a plain space cell.
  void copyEmptyFrom(Cell other) {
    _releaseLink();
    _releasePooledContent();
    _style = other._style;
    _styleId = other._styleId;
    _link = other._link;
    _linkId = other._linkId;
    _width = 1;
    _contentKind = _CellContentKind.space;
    _contentValue = 0;
    drawable = other.drawable;
    if (_linkId != 0) {
      _linkRegistry.retain(_linkId);
      _attachLinkFinalizerIfNeeded();
    }
  }

  /// Sets this cell to a space with width 1.
  void empty() {
    _releasePooledContent();
    _width = 1;
    _contentKind = _CellContentKind.space;
    _contentValue = 0;
  }

  /// Releases any pooled grapheme content owned by this cell.
  void dispose() {
    _releaseLink();
    _releasePooledContent();
    _contentKind = _CellContentKind.empty;
    _contentValue = 0;
    _width = 0;
    _updatePackedContent();
  }

  /// Resets this cell to a canonical empty space cell.
  void resetToEmptyCell() {
    _releaseLink();
    _releasePooledContent();
    _style = const UvStyle();
    _styleId = 0;
    _link = const Link();
    _linkId = 0;
    drawable = null;
    _width = 1;
    _contentKind = _CellContentKind.space;
    _contentValue = 0;
  }

  /// Resets this cell to a canonical zero-width placeholder cell.
  void resetToZeroCell() {
    _releaseLink();
    _releasePooledContent();
    _style = const UvStyle();
    _styleId = 0;
    _link = const Link();
    _linkId = 0;
    drawable = null;
    _width = 0;
    _contentKind = _CellContentKind.empty;
    _contentValue = 0;
  }

  /// Creates a space cell with width 1.
  static Cell emptyCell() => Cell._packed(
    style: const UvStyle(),
    link: const Link(),
    width: 1,
    contentKind: _CellContentKind.space,
    contentValue: 0,
    styleId: 0,
    linkId: 0,
  );

  /// Creates an empty placeholder cell with zero width and no attributes.
  static Cell zeroCell() => Cell._packed(
    style: const UvStyle(),
    link: const Link(),
    width: 0,
    contentKind: _CellContentKind.empty,
    contentValue: 0,
    styleId: 0,
    linkId: 0,
  );

  /// Creates a new cell from a grapheme, computing its display width.
  static Cell newCell(WidthMethod method, String grapheme) {
    if (grapheme.isEmpty) return Cell.zeroCell();
    if (grapheme == ' ') return Cell.emptyCell();
    final width = method.stringWidth(grapheme);
    final scalar = _trySingleScalar(grapheme);
    if (scalar != null) {
      return Cell._packed(
        style: const UvStyle(),
        link: const Link(),
        width: width,
        contentKind: _CellContentKind.singleScalar,
        contentValue: scalar,
        styleId: 0,
        linkId: 0,
      );
    }
    return Cell._packed(
      style: const UvStyle(),
      link: const Link(),
      width: width,
      contentKind: _CellContentKind.complex,
      contentValue: _graphemePool.intern(grapheme, width),
      styleId: 0,
      linkId: 0,
    );
  }

  /// Creates a one-cell printable ASCII cell without width/grapheme scanning.
  static Cell ascii(int codeUnit) => asciiStyled(codeUnit);

  /// Creates a styled one-cell printable ASCII cell without setter churn.
  static Cell asciiStyled(
    int codeUnit, {
    UvStyle style = const UvStyle(),
    Link link = const Link(),
  }) {
    assert(codeUnit >= 0x20 && codeUnit < 0x7F);
    final styleId = _styleIdFor(style);
    final linkId = link.isZero ? 0 : _linkRegistry.intern(link);
    return Cell._packed(
      style: style,
      link: link,
      width: 1,
      contentKind: codeUnit == 0x20
          ? _CellContentKind.space
          : _CellContentKind.singleScalar,
      contentValue: codeUnit == 0x20 ? 0 : codeUnit,
      styleId: styleId,
      linkId: linkId,
    );
  }

  /// Returns the printable ASCII code unit for this cell, if it has one.
  int? get asciiCodeUnit => switch (_contentKind) {
    _CellContentKind.space when _width == 1 => 0x20,
    _CellContentKind.singleScalar
        when _contentValue >= 0x20 && _contentValue < 0x7F =>
      _contentValue,
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      other._contentKind == _contentKind &&
      other._contentValue == _contentValue &&
      other._width == _width &&
      other._styleId == _styleId &&
      other._linkId == _linkId;

  @override
  int get hashCode => _mixHash(
    _mixHash(_mixHash(_contentKind, _contentValue), _width),
    _mixHash(_styleId, _linkId),
  );

  void _setContent(String value) {
    _releasePooledContent();
    _assignPackedContent(value);
  }

  void _setStyle(UvStyle value) {
    _style = value;
    _styleId = _styleIdFor(value);
  }

  void _setLink(Link value) {
    _releaseLink();
    if (value.isZero) {
      _link = const Link();
      _linkId = 0;
      return;
    }
    final id = _linkRegistry.intern(value);
    _linkId = id;
    _link = value;
    _attachLinkFinalizerIfNeeded();
  }

  void _updatePackedContent() {
    final value = content;
    _releasePooledContent();
    _assignPackedContent(value);
  }

  void _assignPackedContent(String value) {
    if (value.isEmpty) {
      _contentKind = _CellContentKind.empty;
      _contentValue = 0;
      return;
    }
    if (value == ' ' && _width == 1) {
      _contentKind = _CellContentKind.space;
      _contentValue = 0;
      return;
    }
    final scalar = _trySingleScalar(value);
    if (scalar != null) {
      _contentKind = _CellContentKind.singleScalar;
      _contentValue = scalar;
      return;
    }
    _contentKind = _CellContentKind.complex;
    _contentValue = _graphemePool.intern(value, _width);
    _attachPooledContentFinalizerIfNeeded();
  }

  void _releasePooledContent() {
    if (_contentKind == _CellContentKind.complex) {
      _pooledContentFinalizer.detach(_pooledContentToken);
      _graphemePool.release(_contentValue);
    }
  }

  void _attachPooledContentFinalizerIfNeeded() {
    if (_contentKind != _CellContentKind.complex) return;
    _pooledContentFinalizer.attach(
      this,
      _contentValue,
      detach: _pooledContentToken,
    );
  }

  void _releaseLink() {
    if (_linkId == 0) {
      return;
    }
    _linkFinalizer.detach(_linkFinalizerToken);
    _linkRegistry.release(_linkId);
    _link = const Link();
    _linkId = 0;
  }

  void _attachLinkFinalizerIfNeeded() {
    if (_linkId == 0) return;
    _linkFinalizer.attach(this, _linkId, detach: _linkFinalizerToken);
  }
}

abstract final class _CellContentKind {
  static const int empty = 0;
  static const int space = 1;
  static const int singleScalar = 2;
  static const int complex = 3;
}

final _GraphemePool _graphemePool = _GraphemePool();
final _LinkRegistry _linkRegistry = _LinkRegistry();
final List<String> _asciiScalarStrings = List<String>.generate(
  0x80,
  String.fromCharCode,
  growable: false,
);
UvStyle? _lastStyleIdStyle;
int _lastStyleId = 0;

int _styleIdFor(UvStyle style) {
  if (style.isZero) return 0;
  final cachedStyle = _lastStyleIdStyle;
  if (identical(cachedStyle, style)) return _lastStyleId;
  final packed = style.packedKey;
  final styleId = packed == 0 ? 1 : packed;
  _lastStyleIdStyle = style;
  _lastStyleId = styleId;
  return styleId;
}

final class _GraphemePool {
  final Map<({String value, int width}), int> _idsByKey =
      <({String value, int width}), int>{};
  final List<_GraphemeEntry?> _slots = <_GraphemeEntry?>[];
  final List<int> _freeSlots = <int>[];

  int intern(String value, int width) {
    final key = (value: value, width: width);
    final existing = _idsByKey[key];
    if (existing != null) {
      final entry = _entryForId(existing);
      if (entry != null) {
        entry.refCount++;
        return existing;
      }
      _idsByKey.remove(key);
    }

    final slotIndex = _freeSlots.isEmpty
        ? _allocateSlot()
        : _freeSlots.removeLast();
    final previous = _slots[slotIndex];
    final generation = previous == null ? 0 : previous.generation + 1;
    final id = _encodeId(slotIndex, generation, width);
    final entry = _GraphemeEntry(
      value: value,
      width: width,
      generation: generation,
      refCount: 1,
    );
    _slots[slotIndex] = entry;
    _idsByKey[key] = id;
    return id;
  }

  void retain(int id) {
    final entry = _entryForId(id);
    if (entry == null) return;
    entry.refCount++;
  }

  void release(int id) {
    final entry = _entryForId(id);
    if (entry == null) return;
    entry.refCount--;
    if (entry.refCount > 0) return;
    final slotIndex = _decodeSlotIndex(id);
    _idsByKey.remove((value: entry.value, width: entry.width));
    _slots[slotIndex] = entry;
    _freeSlots.add(slotIndex);
  }

  String resolve(int id) => _entryForId(id)?.value ?? '';

  int refCount(int id) => _entryForId(id)?.refCount ?? 0;

  int encodedWidth(int id) => (id >> _slotBits) & _widthMask;

  int generation(int id) => id >> (_slotBits + _widthBits);

  int slot(int id) => _decodeSlotIndex(id);

  int _allocateSlot() {
    final slotIndex = _slots.length;
    _slots.add(null);
    return slotIndex;
  }

  _GraphemeEntry? _entryForId(int id) {
    final slotIndex = _decodeSlotIndex(id);
    if (slotIndex < 0 || slotIndex >= _slots.length) return null;
    final entry = _slots[slotIndex];
    if (entry == null) return null;
    if (entry.refCount <= 0) return null;
    if (entry.generation != generation(id)) return null;
    if (entry.width != encodedWidth(id)) return null;
    return entry;
  }

  int _decodeSlotIndex(int id) => (id & _slotMask) - 1;

  int _encodeId(int slotIndex, int generation, int width) {
    return (generation << (_slotBits + _widthBits)) |
        ((width & _widthMask) << _slotBits) |
        ((slotIndex + 1) & _slotMask);
  }
}

final class _GraphemeEntry {
  _GraphemeEntry({
    required this.value,
    required this.width,
    required this.generation,
    required this.refCount,
  });

  final String value;
  final int width;
  final int generation;
  int refCount;
}

final class _LinkRegistry {
  int intern(Link link) {
    final cachedId = _lastId;
    if (cachedId != 0 && _lastUrl == link.url && _lastParams == link.params) {
      final entry = _entryForId(cachedId);
      if (entry != null) {
        entry.refCount++;
        return cachedId;
      }
      _clearLast();
    }

    final key = (url: link.url, params: link.params);
    final existing = _idsByKey[key];
    if (existing != null) {
      final entry = _entryForId(existing);
      if (entry != null) {
        entry.refCount++;
        _cacheLast(entry);
        return existing;
      }
      _idsByKey.remove(key);
    }

    _validateLinkText(link);
    final slotIndex = _freeSlots.isEmpty
        ? _allocateSlot()
        : _freeSlots.removeLast();
    if (slotIndex >= _linkSlotMask) {
      throw StateError('Link registry exhausted');
    }

    final previous = _slots[slotIndex];
    final generation = previous == null ? 0 : previous.generation + 1;
    if (previous != null && generation > _linkGenerationMask) {
      throw StateError('Link generation overflow');
    }
    final id = _encodeId(slotIndex, generation);
    final entry = _LinkEntry(
      id: id,
      url: link.url,
      params: link.params,
      generation: generation,
      refCount: 1,
    );
    _slots[slotIndex] = entry;
    _idsByKey[key] = id;
    _cacheLast(entry);
    return id;
  }

  void retain(int id) {
    final entry = _entryForId(id);
    if (entry == null) return;
    entry.refCount++;
  }

  void release(int id) {
    final entry = _entryForId(id);
    if (entry == null) return;
    entry.refCount--;
    if (entry.refCount > 0) return;
    final key = (url: entry.url, params: entry.params);
    _idsByKey.remove(key);
    if (_lastId == id) _clearLast();
    final slotIndex = _decodeSlotIndex(id);
    _freeSlots.add(slotIndex);
  }

  int refCount(int id) => _entryForId(id)?.refCount ?? 0;

  int slot(int id) => _decodeSlotIndex(id);

  int generation(int id) => id >> _linkSlotBits;

  Link resolve(int id) {
    final entry = _entryForId(id);
    if (entry == null) return const Link();
    return Link(url: entry.url, params: entry.params);
  }

  _LinkEntry? _entryForId(int id) {
    final slotIndex = _decodeSlotIndex(id);
    if (slotIndex < 0 || slotIndex >= _slots.length) return null;
    final entry = _slots[slotIndex];
    if (entry == null) return null;
    if (entry.id != id) return null;
    if (entry.refCount <= 0) return null;
    return entry;
  }

  int _allocateSlot() {
    final slotIndex = _slots.length;
    _slots.add(null);
    return slotIndex;
  }

  int _decodeSlotIndex(int id) => (id & _linkSlotMask) - 1;

  int _encodeId(int slotIndex, int generation) =>
      (generation << _linkSlotBits) | ((slotIndex + 1) & _linkSlotMask);

  void _cacheLast(_LinkEntry entry) {
    _lastId = entry.id;
    _lastUrl = entry.url;
    _lastParams = entry.params;
  }

  void _clearLast() {
    _lastId = 0;
    _lastUrl = null;
    _lastParams = null;
  }

  final Map<({String url, String params}), int> _idsByKey =
      <({String url, String params}), int>{};
  final List<_LinkEntry?> _slots = <_LinkEntry?>[];
  final List<int> _freeSlots = <int>[];
  int _lastId = 0;
  String? _lastUrl;
  String? _lastParams;
}

final class _LinkEntry {
  _LinkEntry({
    required this.id,
    required this.url,
    required this.params,
    required this.generation,
    required this.refCount,
  });

  final int id;
  final String url;
  final String params;
  final int generation;
  int refCount;
}

void _validateLinkText(Link link) {
  if (_containsControl(link.url) || _containsControl(link.params)) {
    throw ArgumentError('Link URL and params must not contain control chars');
  }
}

bool _containsControl(String value) => _containsControlCodeUnit(value);

bool _containsControlCodeUnit(String value) {
  for (var i = 0; i < value.length; i++) {
    final codeUnit = value.codeUnitAt(i);
    if (codeUnit < 0x20 || codeUnit == 0x7f) return true;
  }
  return false;
}

/// Returns the pooled grapheme refcount for [id].
///
/// This is exposed for targeted regression tests.
int debugGraphemeRefCount(int id) => _graphemePool.refCount(id);

/// Returns the encoded grapheme slot index for [id].
int debugGraphemeSlot(int id) => _graphemePool.slot(id);

/// Returns the encoded grapheme generation for [id].
int debugGraphemeGeneration(int id) => _graphemePool.generation(id);

/// Returns the encoded grapheme width for [id].
int debugGraphemeWidth(int id) => _graphemePool.encodedWidth(id);

/// Returns the pooled link refcount for [id].
///
/// This is exposed for targeted regression tests.
int debugLinkRefCount(int id) => _linkRegistry.refCount(id);

/// Returns the pooled link slot index for [id].
///
/// This is exposed for targeted regression tests.
int debugLinkSlot(int id) => _linkRegistry.slot(id);

/// Returns the pooled link generation for [id].
///
/// This is exposed for targeted regression tests.
int debugLinkGeneration(int id) => _linkRegistry.generation(id);

const int _slotBits = 16;
const int _widthBits = 16;
const int _slotMask = (1 << _slotBits) - 1;
const int _widthMask = (1 << _widthBits) - 1;
const int _linkSlotBits = 16;
const int _linkGenerationBits = 8;
const int _linkSlotMask = (1 << _linkSlotBits) - 1;
const int _linkGenerationMask = (1 << _linkGenerationBits) - 1;
const int _cellWidthBits = 4;
const int _cellWidthMask = (1 << _cellWidthBits) - 1;
const int _cellContentKindMask = 0x3;
const int _cellWidthShift = 2;
const int _packedContentShift = 6;
const int _contentValueBits = 32;
const int _contentPackLoMask = (1 << _contentValueBits) - 1;

int? _trySingleScalar(String value) {
  if (value.isEmpty) return null;
  final iterator = value.runes.iterator;
  if (!iterator.moveNext()) return null;
  final scalar = iterator.current;
  return iterator.moveNext() ? null : scalar;
}

int _mixHash(int a, int b) => 0x1fffffff & (a * 31 + b);

int _packStyleExact(UvStyle style) {
  const colorBits = 35;
  const underlineShift = colorBits * 3;
  const attrsShift = underlineShift + 3;
  return _packColorExact(style.fg) |
      (_packColorExact(style.bg) << colorBits) |
      (_packColorExact(style.underlineColor) << (colorBits * 2)) |
      (style.underline.index << underlineShift) |
      (style.attrs << attrsShift);
}

int _packColorExact(UvColor? color) {
  if (color == null) return 0;
  return switch (color) {
    UvBasic16(:final index, :final bright) =>
      1 | (index << 3) | ((bright ? 1 : 0) << 7),
    UvIndexed256(:final index) => 2 | (index << 3),
    UvRgb(:final r, :final g, :final b, :final a) =>
      3 | (r << 3) | (g << 11) | (b << 19) | (a << 27),
  };
}
