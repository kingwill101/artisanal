import 'package:artisanal_editor/artisanal_editor.dart'
    show treeSitterStyleForNodeKind;
import 'package:test/test.dart';

void main() {
  test('maps common Tree-sitter nodes to CodeEditor syntax slots', () {
    expect(treeSitterStyleForNodeKind('return'), 'syntax.keyword');
    expect(
      treeSitterStyleForNodeKind('string_literal'),
      'syntax.literal.string',
    );
    expect(
      treeSitterStyleForNodeKind('decimal_integer_literal'),
      contains('number'),
    );
    expect(treeSitterStyleForNodeKind('line_comment'), 'syntax.comment');
    expect(
      treeSitterStyleForNodeKind(
        'identifier',
        parentKind: 'function_signature',
      ),
      'syntax.name.function',
    );
  });
}
