import 'package:artisanal/editor_core.dart'
    show TextDecorationRange, TextDocument, TextUtf8CoordinateIndex;
import 'package:tree_sitter_language_pack/tree_sitter_language_pack.dart'
    as language_pack;

import 'editor_syntax_highlighter.dart';

// RustLib is not exported by the dependency's public barrel. Keep this
// implementation import isolated at the native runtime boundary.
// ignore: implementation_imports
import 'package:tree_sitter_language_pack/src/tree_sitter_language_pack_bridge_generated/frb_generated.dart'
    show RustLib;

/// Tree-sitter highlighting owned by the standalone editor application.
///
/// Grammars are loaded on demand by `tree_sitter_language_pack`; failures are
/// isolated per buffer so Artisanal's built-in highlighter remains a fallback.
final class TreeSitterSyntaxHighlighter implements EditorSyntaxHighlighter {
  TreeSitterSyntaxHighlighter._();

  static bool _initialized = false;

  /// Initializes the package's native bridge.
  static Future<TreeSitterSyntaxHighlighter> initialize() async {
    if (!_initialized) {
      await RustLib.init();
      _initialized = true;
    }
    return TreeSitterSyntaxHighlighter._();
  }

  /// Releases the native bridge after the editor event loop exits.
  static void disposeRuntime() {
    if (!_initialized) return;
    RustLib.dispose();
    _initialized = false;
  }

  @override
  bool supports(String languageId) => languageId != 'text';

  @override
  Future<List<TextDecorationRange>> highlight({
    required String languageId,
    required TextDocument document,
  }) async {
    final parser = await language_pack.getParser(name: languageId);
    final tree = await parser.parse(source: document.text);
    if (tree == null) return const [];

    final coordinates = TextUtf8CoordinateIndex(document);
    final decorations = <TextDecorationRange>[];

    Future<void> visit(language_pack.Node node, [String? parentKind]) async {
      final kind = await node.kind();
      final styleKey = treeSitterStyleForNodeKind(kind, parentKind: parentKind);
      if (styleKey != null) {
        decorations.add(
          TextDecorationRange(
            startOffset: coordinates.offsetForByteOffset(
              await node.startByte(),
            ),
            endOffset: coordinates.offsetForByteOffset(await node.endByte()),
            styleKey: styleKey,
          ),
        );
      }
      final childCount = await node.childCount();
      for (var index = 0; index < childCount; index++) {
        final child = await node.child(index: index);
        if (child != null) await visit(child, kind);
      }
    }

    await visit(await tree.rootNode());
    return List.unmodifiable(decorations);
  }
}

/// Maps common Tree-sitter node names to CodeEditor's syntax style slots.
String? treeSitterStyleForNodeKind(String kind, {String? parentKind}) {
  final normalized = kind.toLowerCase();
  if (_keywords.contains(normalized)) return 'syntax.keyword';
  if (normalized.contains('number') ||
      normalized.contains('integer') ||
      normalized == 'float' ||
      normalized.contains('float_literal')) {
    return 'syntax.literal.number';
  }
  if (_types.contains(normalized) ||
      normalized.endsWith('_type') ||
      normalized == 'type_identifier') {
    return 'syntax.keyword.type';
  }
  if (normalized.contains('comment')) return 'syntax.comment';
  if (normalized.contains('string') ||
      normalized == 'template_literal' ||
      normalized == 'char_literal') {
    return 'syntax.literal.string';
  }
  if (_constants.contains(normalized)) return 'syntax.name.constant';
  if (normalized.contains('operator')) return 'syntax.operator';
  if (normalized == 'identifier' ||
      normalized == 'property_identifier' ||
      normalized == 'field_identifier') {
    final parent = parentKind?.toLowerCase() ?? '';
    if (parent.contains('class')) return 'syntax.name.class';
    if (parent.contains('function') ||
        parent.contains('method') ||
        parent.contains('constructor')) {
      return 'syntax.name.function';
    }
    if (normalized != 'identifier') return 'syntax.name.attribute';
    return 'syntax.name';
  }
  return null;
}

const _constants = {'false', 'null', 'none', 'nil', 'true', 'undefined'};

const _types = {
  'bool',
  'boolean',
  'byte',
  'char',
  'double',
  'dynamic',
  'float',
  'int',
  'integer',
  'long',
  'num',
  'object',
  'short',
  'string',
  'void',
};

const _keywords = {
  'abstract',
  'and',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'def',
  'defer',
  'delete',
  'do',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'final',
  'finally',
  'for',
  'from',
  'func',
  'function',
  'global',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'lambda',
  'late',
  'let',
  'match',
  'mixin',
  'namespace',
  'new',
  'nonlocal',
  'not',
  'of',
  'operator',
  'or',
  'override',
  'package',
  'pass',
  'private',
  'protected',
  'public',
  'raise',
  'required',
  'return',
  'sealed',
  'static',
  'struct',
  'super',
  'switch',
  'this',
  'throw',
  'trait',
  'try',
  'typedef',
  'typeof',
  'var',
  'while',
  'with',
  'yield',
};
