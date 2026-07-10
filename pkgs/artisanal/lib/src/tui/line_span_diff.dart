/// Minimal-span line diffing for the full-screen line-diff renderer.
///
/// Given the previously rendered form of a terminal line and its successor,
/// [lineSpanEdit] computes the smallest single cursor-position-and-write that
/// turns one into the other, instead of erasing and rewriting the whole row.
///
/// Why this matters: erasing a row (`CSI 2K`) destroys everything on it —
/// including terminal graphics (sixel pixels) that overlap the row but are
/// not part of the diffed text. A renderer that only ever writes the changed
/// cell range leaves unrelated screen regions untouched, so graphics overlaid
/// on stable regions survive text updates elsewhere on the same rows.
library;

import '../terminal/ansi.dart';
import '../unicode/grapheme.dart' as uni;
import '../unicode/width.dart' as uv_width;
import '../uv/ansi.dart' show UvAnsi;
import '../uv/cell.dart' show Link, UvStyle;
import '../uv/styled_string.dart' as uv_styled;
import 'terminal_render_inspector.dart';

/// One minimal terminal edit for a single row: move the cursor to the 0-based
/// display [column] and write [text] (which starts from a reset pen).
final class LineSpanEdit {
  /// Creates a span edit.
  const LineSpanEdit({required this.column, required this.text});

  /// 0-based display column where the write starts.
  final int column;

  /// The bytes to write at [column]. Always begins with a full attribute
  /// reset followed by the ANSI state active at that point of the line, so
  /// the write is correct regardless of the terminal's current pen.
  final String text;
}

/// One lexical unit of a rendered line: a whole escape sequence or a single
/// grapheme cluster, with its display width.
typedef _Token = ({String text, int width, bool isAnsi});

/// Computes the minimal single-span edit that turns [oldLine] (currently on
/// the terminal) into [newLine], both taken from parsed render frames of the
/// same row. Returns null when the difference has no visible effect (e.g.
/// only zero-width sequences changed, with no impact on later cells).
///
/// The edit never touches display columns outside the changed span: a shared
/// prefix is skipped, and a byte-identical tail is kept when the two lines
/// have the same total display width *and* the ANSI state in effect where the
/// tail starts is identical under both lines (matching bytes can render
/// differently when an earlier sequence changed the pen). When the state at
/// the longest byte-identical tail differs, the tail is shrunk to the longest
/// suffix whose inherited state agrees under both lines — typically the part
/// after the restyled run's own reset — rather than dropped entirely, so a
/// style-only change to a run of identical text (a selection highlight moving
/// on or off it) rewrites that run but still leaves the rest of the row
/// untouched.
LineSpanEdit? lineSpanEdit(
  TerminalRenderLine oldLine,
  TerminalRenderLine newLine,
) {
  final oldTokens = _tokenize(oldLine.raw);
  final newTokens = _tokenize(newLine.raw);
  final oldWidth = _totalWidth(oldTokens);
  final newWidth = _totalWidth(newTokens);

  // A different inherited state at the line start restyles every cell — the
  // whole row must be rewritten.
  if (oldLine.statePrefix != newLine.statePrefix) {
    return LineSpanEdit(
      column: 0,
      text:
          '${Ansi.reset}${UvAnsi.resetHyperlink()}'
          '${newLine.statePrefix}${newLine.raw}'
          '${_tailErase(oldWidth, newWidth)}',
    );
  }

  // Longest common token prefix.
  final minLen = oldTokens.length < newTokens.length
      ? oldTokens.length
      : newTokens.length;
  var prefix = 0;
  while (prefix < minLen &&
      oldTokens[prefix].text == newTokens[prefix].text) {
    prefix++;
  }

  var prefixColumns = 0;
  for (var i = 0; i < prefix; i++) {
    prefixColumns += newTokens[i].width;
  }

  // Longest common token suffix — only meaningful when both lines are the
  // same total display width (otherwise the shared bytes sit at different
  // columns), and only safe when the ANSI state at the suffix start is the
  // same under both lines (matching bytes can still render differently when
  // an earlier sequence changed the pen). A state mismatch at the longest
  // suffix shrinks it to the longest state-matched one instead of discarding
  // it: when only a run's style changed (its text identical, so the suffix
  // walk runs straight through it), the suffix restarts after that run's
  // reset instead of pulling the whole rest of the row into the edit.
  var suffix = 0;
  if (oldWidth == newWidth) {
    final maxSuffix = (oldTokens.length - prefix) <
            (newTokens.length - prefix)
        ? oldTokens.length - prefix
        : newTokens.length - prefix;
    while (suffix < maxSuffix &&
        oldTokens[oldTokens.length - 1 - suffix].text ==
            newTokens[newTokens.length - 1 - suffix].text) {
      suffix++;
    }
    if (suffix > 0) {
      final oldStates = _statePrefixesFrom(
          oldLine.statePrefix, oldTokens, oldTokens.length - suffix);
      final newStates = _statePrefixesFrom(
          newLine.statePrefix, newTokens, newTokens.length - suffix);
      // oldStates[j] / newStates[j] hold the state before the token that
      // starts a suffix of length (suffix - j); walk j up (suffix down)
      // until the states agree.
      var j = 0;
      while (j < suffix && oldStates[j] != newStates[j]) {
        j++;
      }
      suffix -= j;
    }
  }

  final middle = StringBuffer();
  for (var i = prefix; i < newTokens.length - suffix; i++) {
    middle.write(newTokens[i].text);
  }
  final tail = suffix == 0 ? _tailErase(oldWidth, newWidth) : '';

  // Nothing visible changed (zero-width-only difference).
  if (middle.isEmpty && tail.isEmpty) return null;

  return LineSpanEdit(
    column: prefixColumns,
    text:
        '${Ansi.reset}${UvAnsi.resetHyperlink()}'
        '${_statePrefixAt(newLine.statePrefix, newTokens, prefix)}'
        '$middle$tail',
  );
}

/// Blanks (with a reset pen) the display columns a shrinking line leaves
/// behind: the old line painted [oldWidth] columns, the new one only
/// [newWidth]. Plain spaces, never erase-to-end-of-line, so columns beyond
/// the old line's own extent are not touched.
String _tailErase(int oldWidth, int newWidth) => oldWidth > newWidth
    ? '${Ansi.reset}${' ' * (oldWidth - newWidth)}'
    : '';

/// The ANSI state active just before each token index in
/// `[from, tokens.length]`, serialized like [_statePrefixAt] — one entry per
/// index, in order. One pass over the line, so probing every candidate
/// suffix start costs the same as probing one.
List<String> _statePrefixesFrom(
    String statePrefix, List<_Token> tokens, int from) {
  final style = uv_styled.StyleState(const UvStyle());
  final link = uv_styled.LinkState(const Link());
  applyRenderedAnsiState(statePrefix, style, link);
  final out = <String>[];
  for (var i = 0; i <= tokens.length; i++) {
    if (i >= from) out.add(renderedStatePrefix(style.style, link.link));
    if (i < tokens.length && tokens[i].isAnsi) {
      applyRenderedAnsiState(tokens[i].text, style, link);
    }
  }
  return out;
}

/// The ANSI state active just before token [index], serialized as the
/// sequences that recreate it from a reset pen. [statePrefix] is the line's
/// inherited state (see [TerminalRenderLine.statePrefix]).
String _statePrefixAt(String statePrefix, List<_Token> tokens, int index) {
  final style = uv_styled.StyleState(const UvStyle());
  final link = uv_styled.LinkState(const Link());
  applyRenderedAnsiState(statePrefix, style, link);
  for (var i = 0; i < index; i++) {
    final token = tokens[i];
    if (token.isAnsi) applyRenderedAnsiState(token.text, style, link);
  }
  return renderedStatePrefix(style.style, link.link);
}

/// Splits a rendered line into escape-sequence and grapheme-cluster tokens.
List<_Token> _tokenize(String raw) {
  final out = <_Token>[];
  var i = 0;
  while (i < raw.length) {
    if (raw.codeUnitAt(i) == 0x1B) {
      final end = Ansi.consumeEscapeSequence(raw, i);
      final sequence = raw.substring(i, end);
      // Escape sequences are zero-width except graphics display payloads,
      // whose cell width visibleLength accounts for.
      out.add((
        text: sequence,
        width: Ansi.visibleLength(sequence),
        isAnsi: true,
      ));
      i = end;
      continue;
    }
    final (:grapheme, :nextIndex) = uni.readGraphemeAt(raw, i);
    out.add((
      text: grapheme,
      width: uv_width.stringWidth(grapheme),
      isAnsi: false,
    ));
    i = nextIndex;
  }
  return out;
}

int _totalWidth(List<_Token> tokens) {
  var width = 0;
  for (final token in tokens) {
    width += token.width;
  }
  return width;
}
