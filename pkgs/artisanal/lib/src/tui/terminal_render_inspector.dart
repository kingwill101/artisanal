import 'view.dart';
import '../terminal/ansi.dart';
import 'package:ultraviolet/rendering.dart' show UvAnsi;
import 'package:ultraviolet/core.dart' show Link, UvStyle;
import 'package:ultraviolet/rendering.dart' as uv_style;
import 'package:ultraviolet/core.dart' as uv_styled;

/// Parsed representation of rendered terminal output.
class TerminalRenderFrame {
  /// Creates a parsed render frame.
  const TerminalRenderFrame(this.lines);

  /// ANSI-aware lines in the rendered frame.
  final List<TerminalRenderLine> lines;

  /// The rendered frame reassembled line-by-line.
  String get content => lines.map((line) => line.rendered).join('\n');

  /// The ANSI-stripped frame content.
  String get plainText => lines.map((line) => line.plainText).join('\n');

  /// Parses rendered [content] into an ANSI-aware frame model.
  static TerminalRenderFrame parse(String content) {
    if (content.isEmpty) {
      return const TerminalRenderFrame(<TerminalRenderLine>[
        TerminalRenderLine(raw: '', statePrefix: ''),
      ]);
    }

    final lines = <TerminalRenderLine>[];
    final lineBuffer = StringBuffer();
    final styleState = uv_styled.StyleState(const UvStyle());
    final linkState = uv_styled.LinkState(const Link());

    UvStyle lineStartStyle = styleState.style;
    Link lineStartLink = linkState.link;

    void flushLine() {
      lines.add(
        TerminalRenderLine(
          raw: lineBuffer.toString(),
          statePrefix: _lineStatePrefix(lineStartStyle, lineStartLink),
        ),
      );
      lineBuffer.clear();
      lineStartStyle = styleState.style;
      lineStartLink = linkState.link;
    }

    var i = 0;
    while (i < content.length) {
      final code = content.codeUnitAt(i);

      if (code == 0x0A) {
        flushLine();
        i++;
        continue;
      }

      if (code == 0x1B) {
        final next = Ansi.consumeEscapeSequence(content, i);
        final sequence = content.substring(i, next);
        lineBuffer.write(sequence);
        _applyAnsiState(sequence, styleState, linkState);
        i = next;
        continue;
      }

      lineBuffer.writeCharCode(code);
      i++;
    }

    flushLine();
    return TerminalRenderFrame(List<TerminalRenderLine>.unmodifiable(lines));
  }

  /// Parses a rendered [view] string or [View].
  static TerminalRenderFrame inspect(Object view) {
    final content = switch (view) {
      String s => s,
      View v => v.content,
      _ => view.toString(),
    };
    return parse(content);
  }
}

/// Parsed representation of a rendered terminal line.
class TerminalRenderLine {
  /// Creates a parsed render line.
  const TerminalRenderLine({required this.raw, required this.statePrefix});

  /// Raw line content as it appeared in the rendered frame.
  final String raw;

  /// ANSI state that must be applied before [raw] when rendering this line in
  /// isolation.
  final String statePrefix;

  /// The line as it should be rendered standalone.
  String get rendered => '$statePrefix$raw';

  /// The ANSI-stripped visible text for this line.
  String get plainText => Ansi.stripAnsi(rendered);

  /// The visible width of the rendered line.
  int get visibleWidth => Ansi.visibleLength(rendered);

  @override
  bool operator ==(Object other) =>
      other is TerminalRenderLine &&
      other.raw == raw &&
      other.statePrefix == statePrefix;

  @override
  int get hashCode => Object.hash(raw, statePrefix);
}

/// Applies every escape sequence found in [input] to [styleState] /
/// [linkState], skipping non-escape bytes. Public counterpart of the frame
/// parser's internal state tracking, for callers that need the ANSI state in
/// effect at an arbitrary point of a rendered line (e.g. minimal-span
/// diffing).
void applyRenderedAnsiState(
  String input,
  uv_styled.StyleState styleState,
  uv_styled.LinkState linkState,
) {
  var i = 0;
  while (i < input.length) {
    if (input.codeUnitAt(i) == 0x1B) {
      final end = Ansi.consumeEscapeSequence(input, i);
      _applyAnsiState(input.substring(i, end), styleState, linkState);
      i = end;
      continue;
    }
    i++;
  }
}

/// Serializes [style] and [link] as the escape sequences that recreate them
/// from a reset pen — the same form as [TerminalRenderLine.statePrefix].
String renderedStatePrefix(UvStyle style, Link link) =>
    _lineStatePrefix(style, link);

String _lineStatePrefix(UvStyle style, Link link) {
  final buffer = StringBuffer();
  if (!link.isZero) {
    buffer.write(UvAnsi.setHyperlink(link.url, link.params));
  }
  if (!style.isZero) {
    buffer.write(uv_style.styleToSgr(style));
  }
  return buffer.toString();
}

void _applyAnsiState(
  String sequence,
  uv_styled.StyleState styleState,
  uv_styled.LinkState linkState,
) {
  if (sequence.length < 2 || sequence.codeUnitAt(0) != 0x1B) return;

  final introducer = sequence.codeUnitAt(1);
  if (introducer == 0x5B && sequence.endsWith('m')) {
    final paramsRaw = sequence.substring(2, sequence.length - 1);
    uv_styled.readStyle(_parseSgrParams(paramsRaw), styleState);
    return;
  }

  if (introducer != 0x5D) return;

  final terminatorLength = sequence.endsWith('\x1B\\') ? 2 : 1;
  if (sequence.length <= 2 + terminatorLength) return;

  final body = sequence.substring(2, sequence.length - terminatorLength);
  final separator = body.indexOf(';');
  if (separator <= 0) return;

  final command = int.tryParse(body.substring(0, separator));
  if (command != 8) return;

  uv_styled.readLink(body.substring(separator + 1), linkState);
}

List<uv_styled.SgrParam> _parseSgrParams(String raw) {
  if (raw.isEmpty) return const <uv_styled.SgrParam>[];

  final out = <uv_styled.SgrParam>[];
  for (final part in raw.split(';')) {
    if (part.isEmpty) {
      out.add(const uv_styled.SgrParam(0, <int>[]));
      continue;
    }

    final subParts = part.split(':');
    final value = int.tryParse(subParts[0]) ?? 0;
    final sub = <int>[];
    for (var i = 1; i < subParts.length; i++) {
      final segment = subParts[i];
      sub.add(int.tryParse(segment.isEmpty ? '0' : segment) ?? 0);
    }
    out.add(uv_styled.SgrParam(value, sub));
  }
  return out;
}
