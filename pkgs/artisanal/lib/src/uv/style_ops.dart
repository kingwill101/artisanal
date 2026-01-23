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

import 'package:artisanal/src/colorprofile/convert.dart' as cpconv;
import 'package:artisanal/src/colorprofile/profile.dart' as cp;

import 'ansi.dart';
import 'cell.dart';

/// Converts a [UvStyle] to respect the given terminal color [profile].
///
/// Upstream: `third_party/ultraviolet/cell.go` (`ConvertStyle`).
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
/// Upstream: `third_party/ultraviolet/cell.go` (`ConvertLink`).
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

/// Returns the SGR sequence for [style].
///
/// Upstream: `third_party/ultraviolet/cell.go` (`UvStyle.String`).
String styleToSgr(UvStyle style) {
  if (style.isZero) return UvAnsi.resetStyle;

  final codes = <String>[];

  final attrs = style.attrs;
  if ((attrs & Attr.bold) != 0) codes.add('1');
  if ((attrs & Attr.faint) != 0) codes.add('2');
  if ((attrs & Attr.italic) != 0) codes.add('3');
  if ((attrs & Attr.blink) != 0) codes.add('5');
  if ((attrs & Attr.rapidBlink) != 0) codes.add('6');
  if ((attrs & Attr.reverse) != 0) codes.add('7');
  if ((attrs & Attr.conceal) != 0) codes.add('8');
  if ((attrs & Attr.strikethrough) != 0) codes.add('9');

  switch (style.underline) {
    case UnderlineStyle.none:
      break;
    case UnderlineStyle.single:
      codes.add('4');
    case UnderlineStyle.double:
      codes.add('4:2');
    case UnderlineStyle.curly:
      codes.add('4:3');
    case UnderlineStyle.dotted:
      codes.add('4:4');
    case UnderlineStyle.dashed:
      codes.add('4:5');
  }

  final fg = _colorCode(style.fg, _ColorTarget.fg);
  if (fg != null) codes.add(fg);
  final bg = _colorCode(style.bg, _ColorTarget.bg);
  if (bg != null) codes.add(bg);
  final ul = _colorCode(style.underlineColor, _ColorTarget.underline);
  if (ul != null) codes.add(ul);

  if (codes.isEmpty) return UvAnsi.resetStyle;
  return '\x1b[${codes.join(';')}m';
}

/// Returns the SGR diff needed to transition from [from] to [to].
///
/// Upstream: `third_party/ultraviolet/cell.go` (`StyleDiff`).
String styleDiff(UvStyle? from, UvStyle? to) {
  if (from == null && to == null) return '';
  if (from != null && to != null && from == to) return '';
  if (from == null) return styleToSgr(to ?? const UvStyle());

  if (to == null || to.isZero) {
    // Resetting all styles is cheaper than calculating diffs.
    return UvAnsi.resetStyle;
  }

  final codes = <String>[];

  if (from.fg != to.fg) {
    codes.add(_colorDiffCode(to.fg, _ColorTarget.fg));
  }
  if (from.bg != to.bg) {
    codes.add(_colorDiffCode(to.bg, _ColorTarget.bg));
  }
  if (from.underlineColor != to.underlineColor) {
    codes.add(_colorDiffCode(to.underlineColor, _ColorTarget.underline));
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
      codes.add('22');
      boldChanged = true;
      faintChanged = true;
    }
  }

  final italicChanged = fromItalic != toItalic;
  if (italicChanged && !toItalic) {
    codes.add('23');
  }

  final underlineChanged =
      (fromUnderline != toUnderline) || (from.underline != to.underline);
  if (underlineChanged && !toUnderline) {
    codes.add('24');
  }

  var blinkChanged = fromBlink != toBlink;
  var rapidBlinkChanged = fromRapidBlink != toRapidBlink;
  if (blinkChanged || rapidBlinkChanged) {
    if ((fromBlink && !toBlink) || (fromRapidBlink && !toRapidBlink)) {
      codes.add('25');
      blinkChanged = true;
      rapidBlinkChanged = true;
    }
  }

  final reverseChanged = fromReverse != toReverse;
  if (reverseChanged && !toReverse) {
    codes.add('27');
  }

  final concealChanged = fromConceal != toConceal;
  if (concealChanged && !toConceal) {
    codes.add('28');
  }

  final strikethroughChanged = fromStrikethrough != toStrikethrough;
  if (strikethroughChanged && !toStrikethrough) {
    codes.add('29');
  }

  if (boldChanged && toBold) codes.add('1');
  if (faintChanged && toFaint) codes.add('2');
  if (italicChanged && toItalic) codes.add('3');
  if (underlineChanged &&
      toUnderline &&
      to.underline == UnderlineStyle.single) {
    codes.add('4');
  }
  if (blinkChanged && toBlink) codes.add('5');
  if (rapidBlinkChanged && toRapidBlink) codes.add('6');
  if (reverseChanged && toReverse) codes.add('7');
  if (concealChanged && toConceal) codes.add('8');
  if (strikethroughChanged && toStrikethrough) codes.add('9');

  if (underlineChanged &&
      toUnderline &&
      to.underline != UnderlineStyle.single) {
    codes.add(switch (to.underline) {
      UnderlineStyle.none => '24',
      UnderlineStyle.single => '4',
      UnderlineStyle.double => '4:2',
      UnderlineStyle.curly => '4:3',
      UnderlineStyle.dotted => '4:4',
      UnderlineStyle.dashed => '4:5',
    });
  }

  if (codes.isEmpty) return '';
  return '\x1b[${codes.join(';')}m';
}

enum _ColorTarget { fg, bg, underline }

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
      return switch (target) {
        _ColorTarget.fg => '38;2;$r;$g;$b',
        _ColorTarget.bg => '48;2;$r;$g;$b',
        // Underline color uses xterm-style colon parameters.
        // Example: ESC[58:2::r:g:bm
        _ColorTarget.underline => '58:2::$r:$g:$b',
      };
  }
}
