import 'package:markdown/markdown.dart' as md;

/// Attribute set when a math delimiter never closed.
const String unterminatedMath = 'unterminated';

const int _backslash = 0x5C;
const int _dollar = 0x24;

/// Inline math: `\(…\)` and in-paragraph `\[…\]` / `$$…$$`.
///
/// Single `$…$` is recognized when the body looks like math, not currency.
final List<md.InlineSyntax> mathInlineSyntaxes = [
  _MathSyntax(r'\\\(([\s\S]+?)\\\)', tag: 'math', startCharacter: _backslash),
  _MathSyntax(
    r'\\\[([\s\S]+?)\\\]',
    tag: 'mathDisplay',
    startCharacter: _backslash,
  ),
  _MathSyntax(
    r'\$\$([\s\S]+?)\$\$',
    tag: 'mathDisplay',
    startCharacter: _dollar,
  ),
  _DollarMathSyntax(),
];

/// Incomplete delimiters for streaming chat. Disabled in documents so a
/// half-typed `\(` does not swallow the rest of the paragraph.
final List<md.InlineSyntax> mathPendingInlineSyntaxes = [
  _PendingMathSyntax(r'\\\([^\n]*', startCharacter: _backslash),
  _PendingMathSyntax(r'\\\[[^\n]*', startCharacter: _backslash),
  _PendingMathSyntax(r'\$\$[^\n]*', startCharacter: _dollar),
];

class _DollarMathSyntax extends md.InlineSyntax {
  /// First character after `$` is not a digit, so `$5` is not a match.
  _DollarMathSyntax()
    : super(r'\$([^\$\d\n][^\$\n]*?)\$', startCharacter: _dollar);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!.trim()));
    return true;
  }
}

class _MathSyntax extends md.InlineSyntax {
  _MathSyntax(super.pattern, {required this.tag, super.startCharacter});

  final String tag;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(tag, match[1]!.trim()));
    return true;
  }
}

class _PendingMathSyntax extends md.InlineSyntax {
  _PendingMathSyntax(super.pattern, {super.startCharacter});

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mathPending', match[0]!));
    return true;
  }
}

/// Display math at the start of a line: `\[…\]` or `$$…$$`.
final List<md.BlockSyntax> mathBlockSyntaxes = [
  _MathBlockSyntax(opener: r'\[', closer: r'\]'),
  _MathBlockSyntax(opener: r'$$', closer: r'$$'),
];

class _MathBlockSyntax extends md.BlockSyntax {
  _MathBlockSyntax({required this.opener, required this.closer})
    : pattern = RegExp(r'^\s*' + RegExp.escape(opener));

  final String opener;
  final String closer;

  @override
  final RegExp pattern;

  @override
  md.Node parse(md.BlockParser parser) {
    final body = <String>[];
    final first = parser.current.content;
    final openMatch = pattern.firstMatch(first)!;
    final rest = first.substring(openMatch.end);
    parser.advance();

    var closed = true;
    final closeOnFirst = rest.indexOf(closer);
    if (closeOnFirst != -1) {
      body.add(rest.substring(0, closeOnFirst));
    } else {
      body.add(rest);
      closed = false;
      while (!parser.isDone) {
        final content = parser.current.content;
        final closeIndex = content.indexOf(closer);
        if (closeIndex != -1) {
          body.add(content.substring(0, closeIndex));
          parser.advance();
          closed = true;
          break;
        }
        // Do not swallow the rest of a live-edited document.
        if (content.trim().isEmpty ||
            content.startsWith('#') ||
            content.startsWith('```')) {
          break;
        }
        body.add(content);
        parser.advance();
      }
    }

    final element = md.Element.text('mathBlock', body.join('\n').trim());
    if (!closed) element.attributes[unterminatedMath] = 'true';
    return element;
  }
}
