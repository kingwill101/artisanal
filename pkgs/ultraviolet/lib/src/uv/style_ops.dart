/// Operations on [UvStyle] objects.
///
/// Includes utilities for converting styles to SGR sequences and adapting
/// styles to different terminal color profiles.
///
/// {@category Ultraviolet}
/// {@subCategory Styling}
///
/// {@macro artisanal_uv_renderer_overview}
library;

import '../colorprofile/convert.dart' as cpconv;
import '../colorprofile/profile.dart' as cp;

import 'ansi.dart';
import 'cell.dart';
import 'color_utils.dart' as color_utils;

/// Converts a [UvStyle] to respect the given terminal color [profile].
///
UvStyle convertStyle(UvStyle style, cp.Profile profile) {
  switch (profile) {
    case cp.Profile.trueColor:
      return style;
    case cp.Profile.noTty:
      return const UvStyle();
    case cp.Profile.ascii:
    case cp.Profile.unknown:
      return style.copyWith(
        clearFg: true,
        clearBg: true,
        clearUnderlineColor: true,
      );
    case cp.Profile.ansi:
    case cp.Profile.ansi256:
      break;
  }

  return style.copyWith(
    fg: _convertColor(style.fg, profile),
    clearFg: style.fg != null && _convertColor(style.fg, profile) == null,
    bg: _convertColor(style.bg, profile),
    clearBg: style.bg != null && _convertColor(style.bg, profile) == null,
    underlineColor: _convertColor(style.underlineColor, profile),
    clearUnderlineColor:
        style.underlineColor != null &&
        _convertColor(style.underlineColor, profile) == null,
  );
}

/// Converts a [Link] to respect the given terminal color [profile].
///
Link convertLink(Link link, cp.Profile profile) {
  if (profile == cp.Profile.noTty) return const Link();
  return link;
}

UvColor? _convertColor(UvColor? c, cp.Profile profile) {
  if (c == null) return null;
  if (profile == cp.Profile.trueColor) return c;
  if (profile <= cp.Profile.ascii) return null;

  switch (c) {
    case UvBasic16():
      return c;
    case UvIndexed256(:final index):
      if (profile == cp.Profile.ansi) {
        final idx16 = cpconv.ansi256ToAnsi16(index);
        return _basic16FromIdx16(idx16);
      }
      return c;
    case UvRgb(:final r, :final g, :final b):
      if (profile == cp.Profile.ansi256) {
        return UvColor.indexed256(cpconv.rgbToAnsi256(r, g, b));
      }
      if (profile == cp.Profile.ansi) {
        return _basic16FromIdx16(cpconv.rgbToAnsi16(r, g, b));
      }
      return c;
  }
}

UvBasic16 _basic16FromIdx16(int idx16) {
  final i = idx16.clamp(0, 15);
  if (i < 8) return UvBasic16(i, bright: false);
  return UvBasic16(i - 8, bright: true);
}

/// LRU-style cache for [styleToSgr] results (≤64 entries).
final _styleSgrCache = <int, String>{};
const _styleSgrCacheMax = 64;

/// Returns the SGR sequence for [style].
///
String styleToSgr(UvStyle style) {
  if (style.isZero) return UvAnsi.resetStyle;

  final key = style.packedKey;
  final cached = _styleSgrCache[key];
  if (cached != null) return cached;

  final simple = _simpleRgbStyleToSgr(style);
  if (simple != null) {
    _cacheSgr(key, simple);
    return simple;
  }

  final sb = StringBuffer();
  var sep = false;
  void add(String s) {
    if (sep) sb.write(';');
    sb.write(s);
    sep = true;
  }

  final attrs = style.attrs;
  if ((attrs & Attr.bold) != 0) add('1');
  if ((attrs & Attr.faint) != 0) add('2');
  if ((attrs & Attr.italic) != 0) add('3');
  if ((attrs & Attr.blink) != 0) add('5');
  if ((attrs & Attr.rapidBlink) != 0) add('6');
  if ((attrs & Attr.reverse) != 0) add('7');
  if ((attrs & Attr.conceal) != 0) add('8');
  if ((attrs & Attr.strikethrough) != 0) add('9');

  switch (style.underline) {
    case UnderlineStyle.none:
      break;
    case UnderlineStyle.single:
      add('4');
    case UnderlineStyle.double:
      add('4:2');
    case UnderlineStyle.curly:
      add('4:3');
    case UnderlineStyle.dotted:
      add('4:4');
    case UnderlineStyle.dashed:
      add('4:5');
  }

  final fg = _colorCode(style.fg, _ColorTarget.fg);
  if (fg != null) add(fg);
  final bg = _colorCode(style.bg, _ColorTarget.bg);
  if (bg != null) add(bg);
  final ul = _colorCode(style.underlineColor, _ColorTarget.underline);
  if (ul != null) add(ul);

  if (!sep) {
    _cacheSgr(key, UvAnsi.resetStyle);
    return UvAnsi.resetStyle;
  }
  final result = '\x1b[${sb.toString()}m';
  _cacheSgr(key, result);
  return result;
}

void _cacheSgr(int key, String value) {
  if (_styleSgrCache.length >= _styleSgrCacheMax) {
    _styleSgrCache.clear();
  }
  _styleSgrCache[key] = value;
}

/// Returns the SGR diff needed to transition from [from] to [to].
///
String styleDiff(UvStyle? from, UvStyle? to) {
  if (from == null && to == null) return '';
  if (from != null && to != null && from == to) return '';
  if (from == null) return styleToSgr(to ?? const UvStyle());

  final simple = _simpleRgbStyleDiff(from, to);
  if (simple != null) return simple;

  if (to == null || to.isZero) {
    // Resetting all styles is cheaper than calculating diffs.
    return UvAnsi.resetStyle;
  }

  final sb = StringBuffer();
  var sep = false;
  void add(String s) {
    if (sep) sb.write(';');
    sb.write(s);
    sep = true;
  }

  if (from.fg != to.fg) {
    add(_colorDiffCode(to.fg, _ColorTarget.fg));
  }
  if (from.bg != to.bg) {
    add(_colorDiffCode(to.bg, _ColorTarget.bg));
  }
  if (from.underlineColor != to.underlineColor) {
    add(_colorDiffCode(to.underlineColor, _ColorTarget.underline));
  }

  final fromBold = (from.attrs & Attr.bold) != 0;
  final fromFaint = (from.attrs & Attr.faint) != 0;
  final fromItalic = (from.attrs & Attr.italic) != 0;
  final fromUnderline = from.underline != UnderlineStyle.none;
  final fromBlink = (from.attrs & Attr.blink) != 0;
  final fromRapidBlink = (from.attrs & Attr.rapidBlink) != 0;
  final fromReverse = (from.attrs & Attr.reverse) != 0;
  final fromConceal = (from.attrs & Attr.conceal) != 0;
  final fromStrikethrough = (from.attrs & Attr.strikethrough) != 0;

  final toBold = (to.attrs & Attr.bold) != 0;
  final toFaint = (to.attrs & Attr.faint) != 0;
  final toItalic = (to.attrs & Attr.italic) != 0;
  final toUnderline = to.underline != UnderlineStyle.none;
  final toBlink = (to.attrs & Attr.blink) != 0;
  final toRapidBlink = (to.attrs & Attr.rapidBlink) != 0;
  final toReverse = (to.attrs & Attr.reverse) != 0;
  final toConceal = (to.attrs & Attr.conceal) != 0;
  final toStrikethrough = (to.attrs & Attr.strikethrough) != 0;

  var boldChanged = fromBold != toBold;
  var faintChanged = fromFaint != toFaint;
  if (boldChanged || faintChanged) {
    if ((fromBold && !toBold) || (fromFaint && !toFaint)) {
      add('22');
      boldChanged = true;
      faintChanged = true;
    }
  }

  final italicChanged = fromItalic != toItalic;
  if (italicChanged && !toItalic) {
    add('23');
  }

  final underlineChanged =
      (fromUnderline != toUnderline) || (from.underline != to.underline);
  if (underlineChanged && !toUnderline) {
    add('24');
  }

  var blinkChanged = fromBlink != toBlink;
  var rapidBlinkChanged = fromRapidBlink != toRapidBlink;
  if (blinkChanged || rapidBlinkChanged) {
    if ((fromBlink && !toBlink) || (fromRapidBlink && !toRapidBlink)) {
      add('25');
      blinkChanged = true;
      rapidBlinkChanged = true;
    }
  }

  final reverseChanged = fromReverse != toReverse;
  if (reverseChanged && !toReverse) {
    add('27');
  }

  final concealChanged = fromConceal != toConceal;
  if (concealChanged && !toConceal) {
    add('28');
  }

  final strikethroughChanged = fromStrikethrough != toStrikethrough;
  if (strikethroughChanged && !toStrikethrough) {
    add('29');
  }

  if (boldChanged && toBold) add('1');
  if (faintChanged && toFaint) add('2');
  if (italicChanged && toItalic) add('3');
  if (underlineChanged &&
      toUnderline &&
      to.underline == UnderlineStyle.single) {
    add('4');
  }
  if (blinkChanged && toBlink) add('5');
  if (rapidBlinkChanged && toRapidBlink) add('6');
  if (reverseChanged && toReverse) add('7');
  if (concealChanged && toConceal) add('8');
  if (strikethroughChanged && toStrikethrough) add('9');

  if (underlineChanged &&
      toUnderline &&
      to.underline != UnderlineStyle.single) {
    add(switch (to.underline) {
      UnderlineStyle.none => '24',
      UnderlineStyle.single => '4',
      UnderlineStyle.double => '4:2',
      UnderlineStyle.curly => '4:3',
      UnderlineStyle.dotted => '4:4',
      UnderlineStyle.dashed => '4:5',
    });
  }

  if (!sep) return '';
  return '\x1b[${sb.toString()}m';
}

/// Returns the cheaper SGR transition from [from] to [to].
///
/// This compares the delta sequence from [styleDiff] with a full reset plus
/// [styleToSgr] reapply and returns whichever emits fewer bytes.
String styleTransitionSgr(UvStyle? from, UvStyle? to) {
  final delta = styleDiff(from, to);
  if (to == null || to.isZero) {
    return delta.isEmpty ? UvAnsi.resetStyle : delta;
  }
  if (from == null || from.isZero) {
    return styleToSgr(to);
  }

  final resetThenApply = '${UvAnsi.resetStyle}${styleToSgr(to)}';
  if (delta.isEmpty) return '';
  return delta.length <= resetThenApply.length ? delta : resetThenApply;
}

enum _ColorTarget { fg, bg, underline }

String? _simpleRgbStyleToSgr(UvStyle style) {
  if (!_isSimpleRgbStyle(style)) return null;
  final fg = style.fg as UvRgb?;
  final bg = style.bg as UvRgb?;
  if (fg == null && bg == null) return UvAnsi.resetStyle;
  final fgParams = fg == null ? null : _rgbParams(fg);
  final bgParams = bg == null ? null : _rgbParams(bg);
  if (fg != null && bg != null) {
    return '\x1b[38;2;${fgParams!};48;2;${bgParams!}'
        'm';
  }
  if (fg != null) {
    return '\x1b[38;2;${fgParams!}'
        'm';
  }
  return '\x1b[48;2;${bgParams!}'
      'm';
}

String? _simpleRgbStyleDiff(UvStyle from, UvStyle? to) {
  if (to == null || to.isZero) return null;
  if (!_isSimpleRgbStyle(from) || !_isSimpleRgbStyle(to)) return null;

  final fromFg = from.fg as UvRgb?;
  final fromBg = from.bg as UvRgb?;
  final toFg = to.fg as UvRgb?;
  final toBg = to.bg as UvRgb?;
  final fgChanged = fromFg != toFg;
  final bgChanged = fromBg != toBg;
  if (!fgChanged && !bgChanged) return '';

  final fgCode = fgChanged ? _simpleRgbDiffCode(toFg, _ColorTarget.fg) : null;
  final bgCode = bgChanged ? _simpleRgbDiffCode(toBg, _ColorTarget.bg) : null;
  if (fgCode != null && bgCode != null) {
    return '\x1b[$fgCode;$bgCode'
        'm';
  }
  if (fgCode != null) {
    return '\x1b[$fgCode'
        'm';
  }
  return '\x1b[$bgCode'
      'm';
}

bool _isSimpleRgbStyle(UvStyle style) =>
    style.attrs == 0 &&
    style.underline == UnderlineStyle.none &&
    style.underlineColor == null &&
    (style.fg == null || style.fg is UvRgb) &&
    (style.bg == null || style.bg is UvRgb);

String _simpleRgbDiffCode(UvRgb? color, _ColorTarget target) {
  if (color == null) {
    return target == _ColorTarget.fg ? '39' : '49';
  }
  final rgb = _rgbParams(color);
  return switch (target) {
    _ColorTarget.fg => '38;2;$rgb',
    _ColorTarget.bg => '48;2;$rgb',
    _ColorTarget.underline => '59',
  };
}

String _rgbParams(UvRgb color) {
  final r = color_utils.clampRgbChannel(color.r);
  final g = color_utils.clampRgbChannel(color.g);
  final b = color_utils.clampRgbChannel(color.b);
  return '$r;$g;$b';
}

String _colorDiffCode(UvColor? c, _ColorTarget target) {
  if (c == null) {
    return switch (target) {
      _ColorTarget.fg => '39',
      _ColorTarget.bg => '49',
      _ColorTarget.underline => '59',
    };
  }
  return _colorCode(c, target) ??
      switch (target) {
        _ColorTarget.fg => '39',
        _ColorTarget.bg => '49',
        _ColorTarget.underline => '59',
      };
}

String? _colorCode(UvColor? c, _ColorTarget target) {
  if (c == null) return null;
  switch (c) {
    case UvBasic16(:final index, :final bright):
      final idx16 = (bright ? 8 : 0) + index;
      switch (target) {
        case _ColorTarget.fg:
          final base = bright ? 90 : 30;
          return '${base + index}';
        case _ColorTarget.bg:
          final base = bright ? 100 : 40;
          return '${base + index}';
        case _ColorTarget.underline:
          // Underline color uses xterm-style colon parameters.
          // Example: ESC[58:5:idxm
          return '58:5:$idx16';
      }
    case UvIndexed256(:final index):
      return switch (target) {
        _ColorTarget.fg => '38;5;$index',
        _ColorTarget.bg => '48;5;$index',
        // Underline color uses xterm-style colon parameters.
        _ColorTarget.underline => '58:5:$index',
      };
    case UvRgb(:final r, :final g, :final b):
      final rr = color_utils.clampRgbChannel(r);
      final gg = color_utils.clampRgbChannel(g);
      final bb = color_utils.clampRgbChannel(b);
      return switch (target) {
        _ColorTarget.fg => '38;2;$rr;$gg;$bb',
        _ColorTarget.bg => '48;2;$rr;$gg;$bb',
        // Underline color uses xterm-style colon parameters.
        // Example: ESC[58:2::r:g:bm
        _ColorTarget.underline => '58:2::$rr:$gg:$bb',
      };
  }
}
