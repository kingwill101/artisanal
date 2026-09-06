import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

final class _TestAdapter extends EditorLanguageAdapter {
  const _TestAdapter({
    required this.languageId,
    this.aliases = const <String>[],
    required this.linePrefix,
    this.colonIndent = false,
  });

  @override
  final String languageId;
  @override
  final List<String> aliases;
  final String linePrefix;
  final bool colonIndent;

  @override
  EditorCommentConfig get comments =>
      EditorCommentConfig(linePrefix: linePrefix);

  @override
  bool shouldIncreaseIndent(EditorIndentContext context) {
    if (super.shouldIncreaseIndent(context)) return true;
    if (!colonIndent) return false;
    return context.lineBeforeCursor.trimRight().endsWith(':');
  }
}

final class _FakeTreeProvider extends SyntaxTreeProvider {
  const _FakeTreeProvider();

  @override
  String get languageId => 'fake';

  @override
  bool get supportsIncremental => true;

  @override
  EditorSyntaxTree parse({
    required String text,
    String? languageId,
    EditorSyntaxTree? previous,
    List<SyntaxTreeEdit>? edits,
    int? revision,
  }) {
    // Fake backend: one `function` node covering a `fn` prefix when present.
    final start = text.indexOf('fn');
    if (start < 0) {
      return EditorSyntaxTree(
        languageId: languageId ?? 'fake',
        revision: revision ?? 0,
        nodes: const [],
      );
    }
    final end = text.indexOf('}', start);
    final resolvedEnd = end < 0 ? text.length : end + 1;
    return EditorSyntaxTree(
      languageId: languageId ?? 'fake',
      revision: revision ?? 0,
      rootId: 1,
      nodes: [
        EditorSyntaxNode(
          id: 1,
          type: 'function',
          startOffset: start,
          endOffset: resolvedEnd,
          childIds: const [2],
        ),
        EditorSyntaxNode(
          id: 2,
          type: 'identifier',
          startOffset: start,
          endOffset: start + 2,
          parentId: 1,
        ),
      ],
    );
  }

  @override
  List<EditorSyntaxCapture> capturesFor(
    EditorSyntaxTree tree, {
    Set<String>? captureNames,
  }) {
    return [
      for (final node in tree.nodes)
        if (node.type == 'function')
          EditorSyntaxCapture(
            nodeId: node.id,
            capture: 'keyword',
            startOffset: node.startOffset,
            endOffset: node.endOffset,
            styleKey: 'syntax.keyword',
          ),
    ];
  }
}

void main() {
  group('language registry (builtins are opt-in data)', () {
    test('custom adapters register without builtins', () {
      final registry = EditorLanguageRegistry();
      registry.register(
        const _TestAdapter(languageId: 'dsl', linePrefix: '--'),
      );
      expect(registry.lookup('dsl')?.comments.linePrefix, '--');
      expect(registry.lookup('missing'), isNotNull); // fallback
    });

    test('builtin profiles resolve python/yaml/markdown/dart', () {
      expect(resolveCodeLanguageProfile('python').lineCommentPrefix, '#');
      expect(resolveCodeLanguageProfile('py').lineCommentPrefix, '#');
      expect(
        resolveCodeLanguageProfile('markdown').blockCommentDelimiters?.start,
        '<!--',
      );
      expect(resolveCodeLanguageProfile('dart').lineCommentPrefix, '//');
    });

    test('colon indent lives on adapters, not core', () {
      expect(codeShouldIncreaseIndentAfter('if x:', language: 'python'), isTrue);
      expect(codeShouldIncreaseIndentAfter('if x:', language: 'dart'), isFalse);
      expect(
        codeShouldIncreaseIndentForAdapter(
          'if x:',
          adapter: const _TestAdapter(
            languageId: 'custom',
            linePrefix: '//',
            colonIndent: true,
          ),
        ),
        isTrue,
      );
      expect(
        codeShouldIncreaseIndentForAdapter('if x:'),
        isFalse,
      );
    });
  });

  group('syntax-tree DTOs (FFI-free Tree-sitter seam)', () {
    test('fake provider parses without native bindings', () {
      const provider = _FakeTreeProvider();
      final tree = provider.parse(text: 'fn main() {}', revision: 3);
      expect(tree.rootId, 1);
      expect(tree.nodeAtOffset(0)?.type, 'identifier');
      expect(
        tree.namedAncestorOf(2, {'function'})?.id,
        1,
      );
      final captures = provider.capturesFor(tree);
      expect(captures, hasLength(1));
      final ranges = syntaxCapturesToRanges(captures);
      expect(ranges.single.styleKey, 'syntax.keyword');
    });

    test('edits describe single replacements', () {
      expect(
        syntaxTreeEditsForReplacement(
          startOffset: 1,
          oldEndOffset: 1,
          newEndOffset: 1,
        ),
        isEmpty,
      );
      final edits = syntaxTreeEditsForReplacement(
        startOffset: 2,
        oldEndOffset: 5,
        newEndOffset: 7,
      );
      expect(edits.single.delta, 2);
    });
  });
}
