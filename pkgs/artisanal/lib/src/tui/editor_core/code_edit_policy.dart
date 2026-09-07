library;

import 'dart:math' as math;

import 'code_language_profile.dart';
import 'text_document.dart';
import 'text_language.dart';

String codeLeadingIndent(String line) {
  final buffer = StringBuffer();
  for (final rune in line.runes) {
    final char = String.fromCharCode(rune);
    if (char != ' ' && char != '\t') {
      break;
    }
    buffer.write(char);
  }
  return buffer.toString();
}

/// Adapter-aware indent check. Prefer this over the string-based overload:
/// pass the resolved [EditorLanguageAdapter] (builtin, Tree-sitter-backed,
/// or custom) instead of a language name.
bool codeShouldIncreaseIndentForAdapter(
  String prefix, {
  EditorLanguageAdapter? adapter,
}) {
  if (prefix.isEmpty) return false;
  final trimmed = prefix.trimRight();
  if (trimmed.isEmpty) return false;
  final last = trimmed[trimmed.length - 1];
  if (last == '{' || last == '[' || last == '(') return true;
  if (adapter == null) return false;
  return adapter.shouldIncreaseIndent(
    EditorIndentContext(
      lineBeforeCursor: prefix,
      lineAfterCursor: '',
      baseIndent: codeLeadingIndent(prefix),
      indentWidth: 2,
    ),
  );
}

bool codeShouldIncreaseIndentAfter(String prefix, {String? language}) {
  if (prefix.isEmpty) {
    return false;
  }

  final last = prefix[prefix.length - 1];
  if (last == '{' || last == '[' || last == '(') {
    return true;
  }

  // Legacy string-based path: resolve via the registry so custom adapters
  // registered on the shared registry participate without core changes.
  // The colon rule itself lives on the Python/YAML adapters, not here.
  if (last != ':') return false;
  final adapter =
      EditorLanguageRegistry.shared.lookup(language) ??
      resolveCodeLanguageProfile(language);
  return adapter.shouldIncreaseIndent(
    EditorIndentContext(
      lineBeforeCursor: prefix,
      lineAfterCursor: '',
      baseIndent: codeLeadingIndent(prefix),
      indentWidth: 2,
    ),
  );
}

({String text, int consumedColumns})? codeBlockNewlineSuffix({
  required String beforeCursor,
  required String afterCursor,
  required String baseIndent,
}) {
  if (beforeCursor.isEmpty || afterCursor.isEmpty) {
    return null;
  }

  final opening = beforeCursor[beforeCursor.length - 1];
  final expectedClosing = switch (opening) {
    '{' => '}',
    '[' => ']',
    '(' => ')',
    _ => null,
  };
  if (expectedClosing == null) {
    return null;
  }

  final leadingWhitespace = afterCursor.length - afterCursor.trimLeft().length;
  if (leadingWhitespace >= afterCursor.length) {
    return null;
  }

  if (afterCursor[leadingWhitespace] != expectedClosing) {
    return null;
  }

  return (text: '\n$baseIndent', consumedColumns: leadingWhitespace);
}

bool codeShouldAutoPairSymmetricDelimiter(
  String text,
  int offset, {
  bool hasSelection = false,
}) {
  if (hasSelection) {
    return true;
  }

  final before = offset > 0 ? text[offset - 1] : '';
  final after = offset < text.length ? text[offset] : '';
  final beforeBlocksPair =
      before.isNotEmpty && RegExp(r'[\w\\]').hasMatch(before);
  if (beforeBlocksPair) {
    return false;
  }

  return after.isEmpty || RegExp(r'[\s\]\)\}\>,.;:]').hasMatch(after);
}

bool codeShouldAutoPairSymmetricDelimiterInDocument(
  TextDocument document,
  int offset, {
  bool hasSelection = false,
}) {
  if (hasSelection) {
    return true;
  }

  final before = offset > 0 ? document.graphemeAt(offset - 1) ?? '' : '';
  final after = offset < document.length
      ? document.graphemeAt(offset) ?? ''
      : '';
  final beforeBlocksPair =
      before.isNotEmpty && RegExp(r'[\w\\]').hasMatch(before);
  if (beforeBlocksPair) {
    return false;
  }

  return after.isEmpty || RegExp(r'[\s\]\)\}\>,.;:]').hasMatch(after);
}

String codeOutdentedIndent(String indent, int width) {
  if (indent.isEmpty || width < 1) {
    return indent;
  }
  if (indent.endsWith('\t')) {
    return indent.substring(0, indent.length - 1);
  }

  final removeCount = math.min(width, indent.length);
  final trailing = indent.substring(indent.length - removeCount);
  if (trailing.runes.every((rune) => rune == 0x20)) {
    return indent.substring(0, indent.length - removeCount);
  }

  final lastSpace = indent.lastIndexOf(' ');
  if (lastSpace >= 0) {
    return indent.substring(0, lastSpace);
  }
  return '';
}
