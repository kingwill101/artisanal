import 'dart:convert';

import 'package:artisanal/editor_core.dart';
import 'package:tree_sitter_language_pack/tree_sitter_language_pack.dart'
    as language_pack;

/// Adapts `tree_sitter_language_pack.process` to Artisanal's async tree API.
///
/// The package's high-level process API performs a full parse, so this adapter
/// deliberately leaves [supportsIncremental] false. An adapter built on its
/// lower-level parser API could retain native trees and opt into incremental
/// edits without changing Artisanal.
final class LanguagePackSyntaxProvider extends AsyncSyntaxTreeProvider {
  LanguagePackSyntaxProvider._({
    required this.languageId,
    required language_pack.ProcessConfig config,
  }) : _config = config;

  /// Creates a provider configured for [languageId].
  static Future<LanguagePackSyntaxProvider> create(String languageId) async {
    final config = await language_pack.createProcessConfigFromJson(
      json: jsonEncode({
        'language': languageId,
        'structure': true,
        'imports': true,
        'exports': true,
        'comments': true,
        'docstrings': true,
        'symbols': true,
        'diagnostics': true,
      }),
    );
    return LanguagePackSyntaxProvider._(languageId: languageId, config: config);
  }

  @override
  final String languageId;

  final language_pack.ProcessConfig _config;

  @override
  Future<EditorSyntaxTree> parse({
    required TextDocument document,
    String? languageId,
    TextDocument? previousDocument,
    EditorSyntaxTree? previous,
    List<SyntaxTreeEdit>? edits,
    int? revision,
  }) async {
    final analysis = await analyze(document, revision: revision);
    return analysis.tree;
  }

  /// Parses [document] and produces both structural data and editor styling.
  Future<LanguagePackAnalysis> analyze(
    TextDocument document, {
    int? revision,
  }) async {
    final parser = await language_pack.getParser(name: languageId);
    final resultFuture = language_pack.TreeSitterLanguagePackBridge.process(
      document.text,
      config: _config,
    );
    final nativeTreeFuture = parser.parse(source: document.text);
    final result = await resultFuture;
    final nativeTree = await nativeTreeFuture;
    final resolvedRevision = revision ?? document.revision;
    final decorations = nativeTree == null
        ? editorDecorationsFromLanguagePackResult(
            document: document,
            result: result,
          )
        : await editorDecorationsFromNativeTree(
            document: document,
            tree: nativeTree,
          );
    return LanguagePackAnalysis(
      tree: editorTreeFromLanguagePackResult(
        document: document,
        result: result,
        revision: resolvedRevision,
      ),
      decorations: decorations,
    );
  }
}

/// One language-pack response converted into Artisanal editor data.
final class LanguagePackAnalysis {
  const LanguagePackAnalysis({required this.tree, required this.decorations});

  final EditorSyntaxTree tree;
  final List<TextDecorationRange> decorations;
}

/// Walks the complete Tree-sitter tree and styles lexical syntax nodes.
Future<List<TextDecorationRange>> editorDecorationsFromNativeTree({
  required TextDocument document,
  required language_pack.Tree tree,
}) async {
  final coordinates = TextUtf8CoordinateIndex(document);
  final decorations = <TextDecorationRange>[];

  Future<void> visit(language_pack.Node node) async {
    final kind = await node.kind();
    final style = _syntaxStyleForNodeKind(kind);
    if (style != null) {
      decorations.add(
        TextDecorationRange(
          startOffset: coordinates.offsetForByteOffset(await node.startByte()),
          endOffset: coordinates.offsetForByteOffset(await node.endByte()),
          styleKey: style,
        ),
      );
    }
    final childCount = await node.childCount();
    for (var index = 0; index < childCount; index++) {
      final child = await node.child(index: index);
      if (child != null) await visit(child);
    }
  }

  await visit(await tree.rootNode());
  return decorations;
}

String? _syntaxStyleForNodeKind(String kind) {
  if (_pythonKeywords.contains(kind)) return 'syntax.keyword';
  if (kind == 'comment') return 'syntax.comment';
  if (kind.contains('string')) return 'syntax.string';
  if (kind == 'integer' || kind == 'float') return 'syntax.number';
  if (kind == 'identifier') return 'syntax.identifier';
  if (kind == 'none' || kind == 'true' || kind == 'false') {
    return 'syntax.constant';
  }
  if (kind.contains('operator')) return 'syntax.operator';
  return null;
}

const _pythonKeywords = {
  'and',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'class',
  'continue',
  'def',
  'del',
  'elif',
  'else',
  'except',
  'finally',
  'for',
  'from',
  'global',
  'if',
  'import',
  'in',
  'is',
  'lambda',
  'nonlocal',
  'not',
  'or',
  'pass',
  'raise',
  'return',
  'try',
  'while',
  'with',
  'yield',
};

/// Converts semantic language-pack spans into editor decoration ranges.
List<TextDecorationRange> editorDecorationsFromLanguagePackResult({
  required TextDocument document,
  required language_pack.ProcessResult result,
}) {
  final coordinates = TextUtf8CoordinateIndex(document);
  final decorations = <TextDecorationRange>[
    for (final item in result.imports)
      _decoration(coordinates, item.span, 'syntax.import'),
    for (final item in result.comments)
      _decoration(coordinates, item.span, 'syntax.comment'),
    for (final item in result.docstrings)
      _decoration(coordinates, item.span, 'syntax.docstring'),
  ];

  void addStructureNames(Iterable<language_pack.StructureItem> items) {
    for (final item in items) {
      final start = coordinates.offsetForByteOffset(item.span.startByte);
      final end = coordinates.offsetForByteOffset(item.span.endByte);
      final graphemes = document.graphemesInRange(
        startOffset: start,
        endOffset: end,
      );
      final nameText = item.name;
      if (nameText != null) {
        final nameDocument = TextDocument(text: nameText);
        final name = nameDocument.graphemesInRange(
          startOffset: 0,
          endOffset: nameDocument.length,
        );
        final relativeStart = _indexOfGraphemes(graphemes, name);
        if (relativeStart >= 0) {
          decorations.add(
            TextDecorationRange(
              startOffset: start + relativeStart,
              endOffset: start + relativeStart + name.length,
              styleKey: 'syntax.${_structureType(item.kind)}',
            ),
          );
        }
      }
      addStructureNames(item.children);
    }
  }

  addStructureNames(result.structure);
  return decorations;
}

TextDecorationRange _decoration(
  TextUtf8CoordinateIndex coordinates,
  language_pack.Span span,
  String styleKey,
) {
  return TextDecorationRange(
    startOffset: coordinates.offsetForByteOffset(span.startByte),
    endOffset: coordinates.offsetForByteOffset(span.endByte),
    styleKey: styleKey,
  );
}

int _indexOfGraphemes(List<String> haystack, List<String> needle) {
  if (needle.isEmpty) return -1;
  for (var start = 0; start <= haystack.length - needle.length; start++) {
    var matches = true;
    for (var index = 0; index < needle.length; index++) {
      if (haystack[start + index] != needle[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return start;
  }
  return -1;
}

/// Converts language-pack structure spans from UTF-8 bytes to editor offsets.
EditorSyntaxTree editorTreeFromLanguagePackResult({
  required TextDocument document,
  required language_pack.ProcessResult result,
  required int revision,
}) {
  final coordinates = TextUtf8CoordinateIndex(document);
  final nodes = <EditorSyntaxNode>[];
  var nextId = 1;

  int addItem(language_pack.StructureItem item, {required int parentId}) {
    final id = nextId++;
    final childIds = [
      for (final child in item.children) addItem(child, parentId: id),
    ];
    nodes.add(
      EditorSyntaxNode(
        id: id,
        type: _structureType(item.kind),
        startOffset: coordinates.offsetForByteOffset(item.span.startByte),
        endOffset: coordinates.offsetForByteOffset(item.span.endByte),
        parentId: parentId,
        childIds: childIds,
      ),
    );
    return id;
  }

  final rootChildren = [
    for (final item in result.structure) addItem(item, parentId: 0),
  ];
  nodes.add(
    EditorSyntaxNode(
      id: 0,
      type: 'document',
      startOffset: 0,
      endOffset: document.length,
      parentId: null,
      childIds: rootChildren,
    ),
  );
  nodes.sort((left, right) => left.id.compareTo(right.id));
  return EditorSyntaxTree(
    languageId: result.language,
    revision: revision,
    nodes: nodes,
    rootId: 0,
  );
}

String _structureType(language_pack.StructureKind kind) {
  return switch (kind) {
    language_pack.StructureKind_Function() => 'function',
    language_pack.StructureKind_Method() => 'method',
    language_pack.StructureKind_Class() => 'class',
    language_pack.StructureKind_Struct() => 'struct',
    language_pack.StructureKind_Interface() => 'interface',
    language_pack.StructureKind_Enum() => 'enum',
    language_pack.StructureKind_Module() => 'module',
    language_pack.StructureKind_Trait() => 'trait',
    language_pack.StructureKind_Impl() => 'implementation',
    language_pack.StructureKind_Namespace() => 'namespace',
    language_pack.StructureKind_Other(:final field0) => field0,
  };
}
