import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  const budget = EditorWorkBudget(
    largeDocumentLength: 10,
    oversizedDocumentLength: 20,
    largeDocumentLines: 4,
    oversizedDocumentLines: 8,
    maxSynchronousSyntaxLength: 6,
    maxSearchResults: 12,
    maxDecorations: 24,
  );

  test('classifies documents by either grapheme or line limits', () {
    expect(
      budget.assess(TextDocument(text: 'small')).scale,
      EditorDocumentScale.normal,
    );
    expect(
      budget.assess(TextDocument(text: '0123456789')).scale,
      EditorDocumentScale.large,
    );
    expect(
      budget.assess(TextDocument(text: 'a\nb\nc\nd')).scale,
      EditorDocumentScale.large,
    );
    expect(
      budget.assess(TextDocument(text: '01234567890123456789')).scale,
      EditorDocumentScale.oversized,
    );
  });

  test('reports bounded feature recommendations without changing content', () {
    final normal = budget.assess(TextDocument(text: '123456'));
    final large = budget.assess(TextDocument(text: '1234567890'));

    expect(normal.allowSynchronousSyntax, isTrue);
    expect(normal.preferVisibleRangeWork, isFalse);
    expect(large.allowSynchronousSyntax, isFalse);
    expect(large.preferVisibleRangeWork, isTrue);
    expect(large.maxSearchResults, 12);
    expect(large.maxDecorations, 24);
  });
}
