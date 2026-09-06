import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('bracket matching', () {
    test('matches nested pairs per type', () {
      final document = TextDocument(text: 'a(b[c{d}e]f)g');
      expect(findMatchingBracket(document, 1), 11); // ( … )
      expect(findMatchingBracket(document, 3), 9); // [ … ]
      expect(findMatchingBracket(document, 5), 7); // { … }
      expect(findMatchingBracket(document, 11), 1); // ) … (
    });

    test('falls back to the bracket before the cursor', () {
      final document = TextDocument(text: '()');
      expect(findMatchingBracket(document, 2), 0);
    });

    test('returns null for unmatched or non-bracket positions', () {
      expect(findMatchingBracket(TextDocument(text: '(a'), 0), isNull);
      expect(findMatchingBracket(TextDocument(text: 'abc'), 1), isNull);
      expect(findMatchingBracket(TextDocument(text: ''), 0), isNull);
      expect(findMatchingBracket(TextDocument(text: '"hi"'), 0), isNull);
    });

    test('pair ranges cover both brackets', () {
      final document = TextDocument(text: 'x = [1];');
      final range = bracketPairRange(document, 4);
      expect(range, isNotNull);
      expect(
        document.textInRange(
          startOffset: range!.startOffset,
          endOffset: range.endOffset,
        ),
        '[1]',
      );
    });
  });

  group('regex search', () {
    test('finds literal and regex matches with groups', () {
      final document = TextDocument(text: 'foo 123 bar 456');
      final literal = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: 'bar'),
      );
      expect(literal.error, isNull);
      expect(literal.matches.single.startOffset, 8);

      final regex = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: r'(\d+)', isRegex: true),
      );
      expect(regex.matches, hasLength(2));
      expect(regex.matches.first.groups[1], '123');
    });

    test('whole-word and case flags apply', () {
      final document = TextDocument(text: 'Foo foobar FOO');
      final sensitive = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: 'Foo', caseSensitive: true),
      );
      expect(sensitive.matches, hasLength(1));
      final whole = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: 'Foo', wholeWord: true),
      );
      expect(whole.matches, hasLength(2));
    });

    test('invalid patterns report errors instead of throwing', () {
      final document = TextDocument(text: 'hello');
      final bad = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: '([', isRegex: true),
      );
      expect(bad.matches, isEmpty);
      expect(bad.error, isNotNull);
      final empty = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: ''),
      );
      expect(empty.error, isNotNull);
    });

    test('templates expand groups and replace descending', () {
      final graphemes = 'a1 b2'.split('');
      final matches = [
        const TextSearchMatch(
          startOffset: 0,
          endOffset: 2,
          groups: ['a1', 'a', '1'],
        ),
        const TextSearchMatch(
          startOffset: 3,
          endOffset: 5,
          groups: ['b2', 'b', '2'],
        ),
      ];
      expect(
        expandSearchReplacementTemplate(r'[$2$1]', matches[0], 'a1'),
        '[1a]',
      );
      expect(expandSearchReplacementTemplate(r'$$', matches[0], 'a1'), r'$');
      final replaced = replaceTextSearchMatches(
        graphemes,
        matches,
        (match) => '<${match.groups[1]}>'.split(''),
      );
      expect(replaced.join(), '<a> <b>');
    });

    test('caps materialized matches when maxResults is set', () {
      final document = TextDocument(text: 'aa aa aa aa');
      final result = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: 'aa'),
        maxResults: 2,
      );
      expect(result.matches, hasLength(2));
      expect(result.truncated, isTrue);
    });

    test('reports truncation only when additional matches exist', () {
      final document = TextDocument(text: 'aa aa');

      final exact = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: 'aa'),
        maxResults: 2,
      );
      final none = findTextSearchMatches(
        document,
        const TextSearchQuery(pattern: 'aa'),
        maxResults: 0,
      );

      expect(exact.matches, hasLength(2));
      expect(exact.truncated, isFalse);
      expect(none.matches, isEmpty);
      expect(none.truncated, isTrue);
    });

    test('sessions move with optional wrap', () {
      final session = TextSearchSession(
        query: const TextSearchQuery(pattern: 'x'),
        matches: const [
          TextSearchMatch(startOffset: 0, endOffset: 1),
          TextSearchMatch(startOffset: 5, endOffset: 6),
        ],
      );
      expect(session.next()!.startOffset, 0);
      expect(session.next()!.startOffset, 5);
      expect(session.next()!.startOffset, 0); // wraps
      expect(session.previous(wrap: false), isNull);
      expect(session.previous()!.startOffset, 5);
    });
  });

  group('selection sets', () {
    test('normalizes overlapping ranges and tracks the primary', () {
      final set = TextSelectionSet(const [
        TextSelectionRange(startOffset: 8, endOffset: 10),
        TextSelectionRange(startOffset: 2, endOffset: 5),
        TextSelectionRange(startOffset: 4, endOffset: 9),
      ], primaryOffset: 3);
      expect(set.ranges, hasLength(1));
      expect(set.ranges.single.startOffset, 2);
      expect(set.ranges.single.endOffset, 10);
      expect(set.primary, set.ranges.single);
    });

    test('keeps the primary active edge when ranges merge', () {
      final set = TextSelectionSet([
        TextSelectionRange.directional(anchorOffset: 4, activeOffset: 1),
        const TextSelectionRange(startOffset: 2, endOffset: 3),
      ], primaryOffset: 1);

      expect(set.ranges, hasLength(1));
      expect(set.primary?.anchorOffset, 4);
      expect(set.primary?.activeOffset, 1);
      expect(set.primary?.isReversed, isTrue);
    });

    test('deletions drop covered ranges but keep cursors', () {
      final set = TextSelectionSet(const [
        TextSelectionRange(startOffset: 1, endOffset: 1),
        TextSelectionRange(startOffset: 2, endOffset: 4),
        TextSelectionRange(startOffset: 10, endOffset: 12),
      ]);
      final next = set.applyDeletion(startOffset: 0, endOffset: 6);
      expect(
        next.ranges,
        contains(const TextSelectionRange(startOffset: 0, endOffset: 0)),
      );
      expect(
        next.ranges,
        contains(const TextSelectionRange(startOffset: 4, endOffset: 6)),
      );
    });

    test('inserts at every cursor descending', () {
      final set = TextSelectionSet(const [
        TextSelectionRange(startOffset: 0, endOffset: 0),
        TextSelectionRange(startOffset: 3, endOffset: 3),
      ]);
      final result = insertTextAtEachSelection('abc'.split(''), set, ['X']);
      expect(result.graphemes.join(), 'XabcX');
      expect(result.selections.ranges, hasLength(2));
    });

    test('preserves directional edges while mapping document edits', () {
      final set = TextSelectionSet([
        TextSelectionRange.directional(anchorOffset: 6, activeOffset: 2),
      ], primaryOffset: 2);

      final inserted = set.applyInsertion(offset: 0, length: 2);
      expect(inserted.primary?.anchorOffset, 8);
      expect(inserted.primary?.activeOffset, 4);
      expect(inserted.primary?.isReversed, isTrue);

      final deleted = inserted.applyDeletion(startOffset: 0, endOffset: 1);
      expect(deleted.primary?.anchorOffset, 7);
      expect(deleted.primary?.activeOffset, 3);
      expect(deleted.primary?.isReversed, isTrue);
      expect(deleted.collapseEach().primary?.activeOffset, 3);
    });
  });

  group('workspace edits', () {
    test('applies multi-file edits and reports ranges', () {
      final result = applyWorkspaceEdit(
        const {'a.dart': 'int x = 1;'},
        const WorkspaceEdit(
          files: {
            'a.dart': [
              FileTextEdit(startOffset: 4, endOffset: 5, replacement: 'y'),
            ],
          },
        ),
      );
      final applied = result['a.dart']!;
      expect(applied.applied, isTrue);
      expect(applied.newText, 'int y = 1;');
      expect(applied.appliedRanges.single.startOffset, 4);
    });

    test('rejects overlapping edits whole-file', () {
      final applied = applyFileEdits('a.dart', 'abcdef', const [
        FileTextEdit(startOffset: 1, endOffset: 4),
        FileTextEdit(startOffset: 3, endOffset: 5),
      ]);
      expect(applied.applied, isFalse);
      expect(applied.newText, 'abcdef');
      expect(applied.conflicts, hasLength(1));
    });

    test('preview renders hunks, conflicts, and unchanged files', () {
      final preview = previewWorkspaceEdit(
        const {'a.dart': 'line1\nline2\nline3\n', 'b.dart': 'same\n'},
        const WorkspaceEdit(
          files: {
            'a.dart': [
              FileTextEdit(
                startOffset: 6,
                endOffset: 11,
                replacement: 'CHANGED',
              ),
            ],
            'b.dart': <FileTextEdit>[],
            'c.dart': [
              FileTextEdit(startOffset: 0, endOffset: 2),
              FileTextEdit(startOffset: 1, endOffset: 3),
            ],
          },
        ),
      );
      expect(preview, contains('--- a/a.dart'));
      expect(preview, contains('-line2'));
      expect(preview, contains('+CHANGED'));
      expect(preview, contains('(no changes)'));
      expect(preview, contains('EditConflict'));
    });
  });

  group('snippets', () {
    test('parses placeholders, mirrors, and the final stop', () {
      final snippet = parseSnippet(r'for (${1:i} = 0; $1 < ${2:n}; $1++) {$0}');
      expect(snippet.text, 'for (i = 0; i < n; i++) {}');
      final first = snippet.tabstops.firstWhere(
        (stop) => stop.index == 1 && !stop.isMirror,
      );
      expect(first.placeholder, 'i');
      expect(snippet.text.substring(first.startOffset, first.endOffset), 'i');
    });

    test('lenient sequences emit literally', () {
      expect(parseSnippet(r'cost is $5 and ${x}').text, r'cost is  and ${x}');
      expect(parseSnippet('a\$b').text, r'a$b');
    });

    test('sessions visit each index once with \$0 last', () {
      final session = SnippetSession(parseSnippet(r'$2 $1 $2 $0'));
      expect(session.next()!.index, 1);
      expect(session.next()!.index, 2);
      expect(session.next()!.index, 0);
      expect(session.next(), isNull);
      expect(session.previous()!.index, 0);
    });
  });

  group('folding', () {
    const lines = [
      'void main() {',
      '  if (ok) {',
      '    run();',
      '  }',
      '}',
      'trailing',
    ];

    test('computes nested indent folds', () {
      final folds = computeIndentFolds(lines);
      expect(folds, hasLength(2));
      expect(folds[0].startLine, 0);
      expect(folds[0].endLine, 3);
      expect(folds[1].startLine, 1);
      expect(folds[1].endLine, 2);
    });

    test('collapse hides bodies and keeps headers', () {
      final state = FoldState(ranges: computeIndentFolds(lines))..toggle(0);
      expect(state.isLineHidden(0), isFalse);
      expect(state.isLineHidden(2), isTrue);
      expect(state.visibleLines(lines.length), [0, 4, 5]);
    });

    test('maps hidden nested lines to their visible fold header', () {
      final state = FoldState(ranges: computeIndentFolds(lines))..collapseAll();
      expect(state.visibleLineFor(0), 0);
      expect(state.visibleLineFor(1), 0);
      expect(state.visibleLineFor(2), 0);
      expect(state.visibleLineFor(5), 5);
    });

    test('retain carries collapse state across recompute', () {
      final state = FoldState(ranges: computeIndentFolds(lines))..toggle(1);
      final next = state.retain(computeIndentFolds([...lines, 'extra']));
      expect(next.isCollapsedAt(1), isTrue);
    });
  });
}
