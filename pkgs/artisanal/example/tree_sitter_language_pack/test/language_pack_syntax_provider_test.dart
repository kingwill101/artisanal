import 'package:artisanal/editor_core.dart';
import 'package:artisanal_tree_sitter_language_pack_example/tree_sitter_language_pack_adapter.dart';
import 'package:test/test.dart';
import 'package:tree_sitter_language_pack/tree_sitter_language_pack.dart'
    as language_pack;

void main() {
  test('maps UTF-8 structure spans into grapheme tree nodes', () {
    final document = TextDocument(text: '😀 class\n  method');
    final result = language_pack.ProcessResult(
      language: 'test',
      metrics: const language_pack.FileMetrics(
        totalLines: 2,
        codeLines: 2,
        commentLines: 0,
        blankLines: 0,
        totalBytes: 19,
        nodeCount: 2,
        errorCount: 0,
        maxDepth: 2,
      ),
      structure: [
        language_pack.StructureItem(
          kind: const language_pack.StructureKind.class_(),
          name: 'class',
          span: const language_pack.Span(
            startByte: 5,
            endByte: 19,
            startLine: 0,
            startColumn: 5,
            endLine: 1,
            endColumn: 8,
          ),
          children: [
            language_pack.StructureItem(
              kind: const language_pack.StructureKind.method(),
              name: 'method',
              span: const language_pack.Span(
                startByte: 13,
                endByte: 19,
                startLine: 1,
                startColumn: 2,
                endLine: 1,
                endColumn: 8,
              ),
              children: const [],
              decorators: const [],
            ),
          ],
          decorators: const [],
        ),
      ],
      imports: const [],
      exports: const [],
      comments: const [],
      docstrings: const [],
      symbols: const [],
      diagnostics: const [],
      chunks: const [],
    );

    final tree = editorTreeFromLanguagePackResult(
      document: document,
      result: result,
      revision: 7,
    );

    expect(tree.languageId, 'test');
    expect(tree.revision, 7);
    expect(tree.rootId, 0);
    expect(tree.nodes, hasLength(3));
    expect(tree.byId[0]?.childIds, [1]);
    expect(tree.byId[1]?.type, 'class');
    expect(tree.byId[1]?.startOffset, 2);
    expect(tree.byId[1]?.childIds, [2]);
    expect(tree.byId[2]?.type, 'method');
    expect(tree.byId[2]?.parentId, 1);
    expect(tree.byId[2]?.startOffset, 10);
    expect(tree.byId[2]?.endOffset, document.length);

    final decorations = editorDecorationsFromLanguagePackResult(
      document: document,
      result: result,
    );
    expect(
      decorations,
      contains(
        const TextDecorationRange(
          startOffset: 2,
          endOffset: 7,
          styleKey: 'syntax.class',
        ),
      ),
    );
  });
}
