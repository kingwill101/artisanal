import 'package:characters/characters.dart';
import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextDocument', () {
    test('parseLineTexts preserves empty trailing lines', () {
      expect(TextDocument.parseLineTexts(const ['alpha', '', 'beta']), const [
        ['a', 'l', 'p', 'h', 'a'],
        <String>[],
        ['b', 'e', 't', 'a'],
      ]);
    });

    test('parseFlatGraphemes preserves explicit newline boundaries', () {
      expect(
        TextDocument.parseFlatGraphemes(const ['a', '\n', '\n', 'b']),
        const [
          ['a'],
          <String>[],
          ['b'],
        ],
      );
    });

    test('native constructors build documents from line and grapheme data', () {
      final fromLineTexts = TextDocument.fromLineTexts(const [
        'alpha',
        '',
        'beta',
      ]);
      final fromParsedLines = TextDocument.fromParsedLines(const [
        ['a', 'l', 'p', 'h', 'a'],
        <String>[],
        ['b', 'e', 't', 'a'],
      ]);
      final fromFlatGraphemes = TextDocument.fromFlatGraphemes(const [
        'a',
        'l',
        'p',
        'h',
        'a',
        '\n',
        '\n',
        'b',
        'e',
        't',
        'a',
      ]);

      expect(fromLineTexts.text, 'alpha\n\nbeta');
      expect(fromParsedLines.text, 'alpha\n\nbeta');
      expect(fromFlatGraphemes.text, 'alpha\n\nbeta');
      expect(fromLineTexts.lineTexts, const ['alpha', '', 'beta']);
      expect(fromParsedLines.lines, const [
        ['a', 'l', 'p', 'h', 'a'],
        <String>[],
        ['b', 'e', 't', 'a'],
      ]);
      expect(fromFlatGraphemes.lineCount, 3);
    });

    test('raw-text documents index grapheme-heavy lines in one pass', () {
      const family = '👩‍👩‍👧‍👦';
      const rocket = '🚀';
      final document = TextDocument(text: '$family\n$rocket\n');

      expect(document.lineCount, 3);
      expect(document.lineLength(0), 1);
      expect(document.lineLength(1), 1);
      expect(document.lineLength(2), 0);
      expect(document.lineAt(0), family);
      expect(document.lineAt(1), rocket);
      expect(document.lineAt(2), '');
      expect(document.lineStartOffset(1), family.characters.length + 1);
      expect(
        document.lineStartOffset(2),
        family.characters.length + rocket.characters.length + 2,
      );
      expect(
        document.length,
        family.characters.length + rocket.characters.length + 2,
      );
    });

    test(
      'replaceTextRange mutates a single-line span with change metadata',
      () {
        final document = TextDocument(text: 'alpha beta');

        final change = document.replaceTextRange(
          startOffset: 6,
          endOffset: 10,
          replacement: 'gamma',
        );

        expect(document.text, 'alpha gamma');
        expect(change.startOffset, 6);
        expect(change.oldEndOffset, 10);
        expect(change.newEndOffset, 11);
        expect(change.startPosition, const TextPosition(line: 0, column: 6));
        expect(change.oldEndPosition, const TextPosition(line: 0, column: 10));
        expect(change.newEndPosition, const TextPosition(line: 0, column: 11));
      },
    );

    test(
      'replaceOffsetRange supports multiline replacement without reparsing text',
      () {
        final document = TextDocument(text: 'ab\ncdef\ngh');

        final change = document.replaceOffsetRange(
          startOffset: 1,
          endOffset: 7,
          replacement: const ['X', '\n', 'Y', 'Z'],
        );

        expect(document.text, 'aX\nYZ\ngh');
        expect(document.lines, const [
          ['a', 'X'],
          ['Y', 'Z'],
          ['g', 'h'],
        ]);
        expect(change.startOffset, 1);
        expect(change.oldEndOffset, 7);
        expect(change.newEndOffset, 5);
        expect(change.startPosition, const TextPosition(line: 0, column: 1));
        expect(change.oldEndPosition, const TextPosition(line: 1, column: 4));
        expect(change.newEndPosition, const TextPosition(line: 1, column: 2));
      },
    );

    test(
      'replaceOffsetRange deletes across lines and rejoins surrounding text',
      () {
        final document = TextDocument(text: 'hello\nworld\n!');

        final change = document.replaceOffsetRange(
          startOffset: 3,
          endOffset: 12,
        );

        expect(document.text, 'hel!');
        expect(document.lines, const [
          ['h', 'e', 'l', '!'],
        ]);
        expect(change.startOffset, 3);
        expect(change.oldEndOffset, 12);
        expect(change.newEndOffset, 3);
        expect(change.startPosition, const TextPosition(line: 0, column: 3));
        expect(change.oldEndPosition, const TextPosition(line: 2, column: 0));
        expect(change.newEndPosition, const TextPosition(line: 0, column: 3));
      },
    );

    test('lineTexts caches line projections and invalidates after edits', () {
      final document = TextDocument(text: 'alpha\nbeta');

      expect(document.lineTexts, const ['alpha', 'beta']);
      expect(document.lineTexts, same(document.lineTexts));

      document.replaceTextRange(
        startOffset: 6,
        endOffset: 10,
        replacement: 'B',
      );

      expect(document.lineTexts, const ['alpha', 'B']);
    });

    test(
      'replaceText builds large documents through chunked storage directly',
      () {
        final lineTexts = List<String>.generate(
          600,
          (index) => 'line-$index-abcdefghij',
          growable: false,
        );
        final document = TextDocument(text: 'seed');

        document.replaceText(lineTexts.join('\n'));

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugSourceBackedLeafCount, greaterThan(0));
        expect(document.debugDistinctSourceCount, 1);
        expect(document.debugHasMaterializedLineTextCache, isFalse);
        expect(document.debugHasTextCache, isFalse);
        expect(document.lineCount, lineTexts.length);
        expect(document.lineAt(0), lineTexts.first);
        expect(document.lineAt(511), lineTexts[511]);
        expect(document.lineAt(599), lineTexts.last);
      },
    );

    test(
      'replaceText leaves revision and storage identity stable on no-op whole-document edits',
      () {
        final document = TextDocument(text: 'alpha\nbeta');
        final revision = document.revision;
        final storageIdentity = document.storageIdentity;

        document.replaceText('alpha\nbeta');

        expect(document.revision, revision);
        expect(document.storageIdentity, same(storageIdentity));
        expect(document.text, 'alpha\nbeta');
      },
    );

    test(
      'replaceTextRange builds large multiline replacements through source-backed storage',
      () {
        final lineTexts = List<String>.generate(
          600,
          (index) => 'line-$index-abcdefghij',
          growable: false,
        );
        final document = TextDocument(text: 'seed');

        document.replaceTextRange(
          startOffset: 0,
          endOffset: document.length,
          replacement: lineTexts.join('\n'),
        );

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugSourceBackedLeafCount, greaterThan(0));
        expect(document.debugDistinctSourceCount, 1);
        expect(document.lineCount, lineTexts.length);
        expect(document.lineAt(0), lineTexts.first);
        expect(document.lineAt(599), lineTexts.last);
      },
    );

    test(
      'replaceOffsetRange keeps grapheme-heavy multiline replacement lengths correct',
      () {
        const family = '👩‍👩‍👧‍👦';
        final replacement = <String>[];
        for (var index = 0; index < 600; index++) {
          replacement.addAll(family.characters);
          if (index < 599) {
            replacement.add('\n');
          }
        }
        final document = TextDocument(text: 'seed');

        document.replaceOffsetRange(
          startOffset: 0,
          endOffset: document.length,
          replacement: replacement,
        );

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugSourceBackedLeafCount, greaterThan(1));
        expect(document.debugDistinctSourceCount, 1);
        expect(document.debugJoinedSourceTextCount, 0);
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.debugLineGraphemeCacheCount, 0);
        expect(document.lineCount, 600);
        expect(document.lineLength(0), 1);
        expect(document.lineLength(255), 1);
        expect(document.lineLength(256), 1);
        expect(document.lineLength(599), 1);
        expect(document.lineGraphemesAt(0), family.characters.toList());
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.debugLineGraphemeCacheCount, 1);
        expect(document.lineAt(0), family);
        expect(document.debugMaterializedSourceLineTextCount, 1);
        expect(document.debugLineGraphemeCacheCount, 1);
        expect(document.lineAt(599), family);
        expect(document.debugMaterializedSourceLineTextCount, 2);
        expect(document.debugLineGraphemeCacheCount, 1);
      },
    );

    test(
      'replaceLines builds large parsed documents through shared source-backed storage',
      () {
        final parsedLines = List<List<String>>.generate(
          600,
          (index) =>
              'line-$index-abcdefghij'.characters.toList(growable: false),
          growable: false,
        );
        final document = TextDocument(text: 'seed');

        document.replaceLines(parsedLines);

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugSourceBackedLeafCount, greaterThan(1));
        expect(document.debugDistinctSourceCount, 1);
        expect(document.debugJoinedSourceTextCount, 0);
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.debugLineGraphemeCacheCount, parsedLines.length);
        expect(document.lineCount, parsedLines.length);
        expect(document.lineGraphemesAt(0), parsedLines.first);
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.lineAt(0), 'line-0-abcdefghij');
        expect(document.debugMaterializedSourceLineTextCount, 1);
        expect(document.lineAt(599), 'line-599-abcdefghij');
        expect(document.debugMaterializedSourceLineTextCount, 2);
      },
    );

    test(
      'replaceLines keeps small parsed documents lazy until line text is read',
      () {
        const family = '👩‍👩‍👧‍👦';
        const rocket = '🚀';
        final parsedLines = <List<String>>[
          family.characters.toList(growable: false),
          rocket.characters.toList(growable: false),
        ];
        final document = TextDocument(text: 'seed');

        document.replaceLines(parsedLines);

        expect(document.debugSourceBackedLeafCount, 1);
        expect(document.debugDistinctSourceCount, 1);
        expect(document.debugJoinedSourceTextCount, 0);
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.lineGraphemesAt(0), parsedLines.first);
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.lineAt(0), family);
        expect(document.debugMaterializedSourceLineTextCount, 1);
        expect(document.lineAt(1), rocket);
        expect(document.debugMaterializedSourceLineTextCount, 2);
      },
    );

    test(
      'parsed-line range helpers stay lazy until line text is read explicitly',
      () {
        final document = TextDocument.fromParsedLines(const [
          ['a', 'b', 'c'],
          ['d', 'e', 'f'],
        ]);

        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.textInRange(startOffset: 0, endOffset: 2), 'ab');
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(document.textInRange(startOffset: 0, endOffset: 3), 'abc');
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(
          document.matchesOffsetRange(
            startOffset: 1,
            graphemes: const ['b', 'c'],
          ),
          isTrue,
        );
        expect(document.debugMaterializedSourceLineTextCount, 0);
        expect(
          document.matchesOffsetRange(
            startOffset: 0,
            graphemes: const ['a', 'b', 'c'],
          ),
          isTrue,
        );
        expect(document.debugMaterializedSourceLineTextCount, 0);

        expect(document.lineAt(0), 'abc');
        expect(document.debugMaterializedSourceLineTextCount, 1);
      },
    );

    test(
      'replaceLines leaves revision and storage identity stable on no-op parsed edits',
      () {
        final document = TextDocument(text: 'alpha\nbeta');
        final revision = document.revision;
        final storageIdentity = document.storageIdentity;

        document.replaceLines(const [
          ['a', 'l', 'p', 'h', 'a'],
          ['b', 'e', 't', 'a'],
        ]);

        expect(document.revision, revision);
        expect(document.storageIdentity, same(storageIdentity));
        expect(document.text, 'alpha\nbeta');
      },
    );

    test(
      'composite text reads do not materialize line text caches just to assemble text',
      () {
        final lineTexts = List<String>.generate(
          300,
          (index) => 'line-$index',
          growable: false,
        );
        final document = TextDocument.fromLineTexts(lineTexts);

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugSourceBackedLeafCount, greaterThan(0));
        expect(document.debugDistinctSourceCount, 1);
        expect(document.debugHasMaterializedLineTextCache, isFalse);
        expect(document.debugHasTextCache, isFalse);

        expect(document.text, lineTexts.join('\n'));

        expect(document.debugHasMaterializedLineTextCache, isFalse);
        expect(document.debugHasTextCache, isTrue);

        expect(document.lineTexts, lineTexts);
        expect(document.debugHasMaterializedLineTextCache, isTrue);
      },
    );

    test('line boundary offset helpers expose full-line ranges', () {
      final document = TextDocument(text: 'alpha\nbeta');

      expect(document.lineStartOffset(0), 0);
      expect(document.lineEndOffset(0), 5);
      expect(document.lineEndOffset(0, includeTrailingNewline: true), 6);
      expect(document.lineStartOffset(1), 6);
      expect(document.lineEndOffset(1), 10);
      expect(document.lineStartOffset(2), 10);
      expect(document.lineEndOffset(2), 10);
    });

    test('text range helpers read direct slices without flattening first', () {
      final document = TextDocument(text: 'alpha\nbeta\ngamma');

      expect(document.textInRange(startOffset: 2, endOffset: 9), 'pha\nbet');
      expect(
        document.textBetweenLines(startLine: 1, endLine: 3),
        'beta\ngamma',
      );
    });

    test(
      'full-range textBetweenLines reuses the composite text cache path',
      () {
        final lineTexts = List<String>.generate(
          300,
          (index) => 'line-$index',
          growable: false,
        );
        final document = TextDocument.fromLineTexts(lineTexts);

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugHasMaterializedLineTextCache, isFalse);
        expect(document.debugHasTextCache, isFalse);

        final text = document.textBetweenLines(
          startLine: 0,
          endLine: document.lineCount,
        );

        expect(text, lineTexts.join('\n'));
        expect(document.debugHasMaterializedLineTextCache, isFalse);
        expect(document.debugHasTextCache, isTrue);
      },
    );

    test('partial textBetweenLines keeps composite caches cold', () {
      final lineTexts = List<String>.generate(
        300,
        (index) => 'line-$index',
        growable: false,
      );
      final document = TextDocument(text: lineTexts.join('\n'));

      expect(document.debugStorageDepth, greaterThan(1));
      expect(document.debugHasMaterializedLineTextCache, isFalse);
      expect(document.debugHasTextCache, isFalse);

      final text = document.textBetweenLines(startLine: 120, endLine: 181);

      expect(text, lineTexts.sublist(120, 181).join('\n'));
      expect(document.debugHasMaterializedLineTextCache, isFalse);
      expect(document.debugHasTextCache, isFalse);
    });

    test('partial textBetweenLines keeps source-backed leaf caches cold', () {
      final lineTexts = List<String>.generate(
        32,
        (index) => 'line-$index',
        growable: false,
      );
      final document = TextDocument(text: lineTexts.join('\n'));

      expect(document.debugStorageDepth, 1);
      expect(document.debugSourceBackedLeafCount, 1);
      expect(document.debugHasMaterializedLineTextCache, isFalse);
      expect(document.debugHasTextCache, isFalse);

      final text = document.textBetweenLines(startLine: 7, endLine: 18);

      expect(text, lineTexts.sublist(7, 18).join('\n'));
      expect(document.debugHasMaterializedLineTextCache, isFalse);
      expect(document.debugHasTextCache, isFalse);
    });

    test(
      'composite range matching does not materialize every touched line cache',
      () {
        final lineTexts = List<String>.generate(
          300,
          (index) => 'line-$index-abcdefghij',
          growable: false,
        );
        final document = TextDocument.fromLineTexts(lineTexts);
        final start = document.lineStartOffset(120) + 2;
        final expected = lineTexts.sublist(120, 181).join('\n').substring(2);

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugLineGraphemeCacheCount, 0);

        final matches = document.matchesOffsetRange(
          startOffset: start,
          graphemes: expected.characters.toList(growable: false),
        );

        expect(matches, isTrue);
        expect(document.debugLineGraphemeCacheCount, 0);
      },
    );

    test('long-line range matching keeps grapheme caches cold', () {
      final longLine = List<String>.filled(10000, 'a', growable: false).join();
      final document = TextDocument(text: '$longLine\nsuffix');
      final graphemes = longLine
          .substring(2500, 7500)
          .characters
          .toList(growable: false);

      expect(document.debugLineGraphemeCacheCount, 0);

      final matches = document.matchesOffsetRange(
        startOffset: 2500,
        graphemes: graphemes,
      );

      expect(matches, isTrue);
      expect(document.debugLineGraphemeCacheCount, 0);
    });

    test(
      'composite grapheme range reads do not materialize every touched line cache',
      () {
        final lineTexts = List<String>.generate(
          300,
          (index) => 'line-$index-abcdefghij',
          growable: false,
        );
        final document = TextDocument.fromLineTexts(lineTexts);
        final start = document.lineStartOffset(120) + 2;
        final end = document.lineEndOffset(180);

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugLineGraphemeCacheCount, 0);

        final graphemes = document.graphemesInRange(
          startOffset: start,
          endOffset: end,
        );

        expect(
          graphemes.join(),
          lineTexts.sublist(120, 181).join('\n').substring(2),
        );
        expect(document.debugLineGraphemeCacheCount, 0);
      },
    );

    test(
      'composite text range reads do not materialize every touched line cache',
      () {
        final lineTexts = List<String>.generate(
          300,
          (index) => 'line-$index-abcdefghij',
          growable: false,
        );
        final document = TextDocument.fromLineTexts(lineTexts);
        final start = document.lineStartOffset(120) + 2;
        final end = document.lineEndOffset(180);

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugLineGraphemeCacheCount, 0);

        final text = document.textInRange(startOffset: start, endOffset: end);

        expect(text, lineTexts.sublist(120, 181).join('\n').substring(2));
        expect(document.debugLineGraphemeCacheCount, 0);
      },
    );

    test('revision is preserved on copies and increments on edits', () {
      final document = TextDocument(text: 'alpha');
      final copy = document.copy();

      expect(document.revision, 0);
      expect(copy.revision, 0);

      document.replaceTextRange(startOffset: 5, endOffset: 5, replacement: '!');

      expect(document.revision, 1);
      expect(copy.revision, 0);
    });

    test(
      'replaceOffsetRange leaves revision and storage identity stable on no-op edits',
      () {
        final document = TextDocument(text: 'alpha\nbeta');
        final revision = document.revision;
        final storageIdentity = document.storageIdentity;

        final change = document.replaceOffsetRange(
          startOffset: 6,
          endOffset: 10,
          replacement: const ['b', 'e', 't', 'a'],
        );

        expect(document.revision, revision);
        expect(document.storageIdentity, same(storageIdentity));
        expect(document.text, 'alpha\nbeta');
        expect(change.startOffset, 6);
        expect(change.oldEndOffset, 10);
        expect(change.newEndOffset, 10);
      },
    );

    test(
      'replaceTextRange leaves revision and storage identity stable on no-op string edits',
      () {
        final document = TextDocument(text: 'alpha\nbeta');
        final revision = document.revision;
        final storageIdentity = document.storageIdentity;

        final change = document.replaceTextRange(
          startOffset: 6,
          endOffset: 10,
          replacement: 'beta',
        );

        expect(document.revision, revision);
        expect(document.storageIdentity, same(storageIdentity));
        expect(document.text, 'alpha\nbeta');
        expect(change.startOffset, 6);
        expect(change.oldEndOffset, 10);
        expect(change.newEndOffset, 10);
      },
    );

    test('replaceOffsetRange keeps long-line grapheme caches cold', () {
      final prefix = List<String>.filled(4096, 'a').join();
      final emoji = '👩‍👩‍👧‍👦';
      final suffix = List<String>.filled(4096, 'b').join();
      final document = TextDocument(text: '$prefix$emoji$suffix');
      final emojiOffset = prefix.characters.length;

      expect(document.debugLineGraphemeCacheCount, 0);

      final change = document.replaceTextRange(
        startOffset: emojiOffset,
        endOffset: emojiOffset + emoji.characters.length,
        replacement: 'X',
      );

      expect(document.debugLineGraphemeCacheCount, 0);
      expect(document.text, '${prefix}X$suffix');
      expect(change.startPosition, TextPosition(line: 0, column: emojiOffset));
      expect(
        change.oldEndPosition,
        TextPosition(line: 0, column: emojiOffset + emoji.characters.length),
      );
      expect(
        change.newEndPosition,
        TextPosition(line: 0, column: emojiOffset + 1),
      );
    });

    test(
      'replaceLineTextRange rewrites only the targeted line window with change metadata',
      () {
        final document = TextDocument(text: 'alpha\nbeta\ngamma\ndelta');

        final change = document.replaceLineTextRange(
          startLine: 1,
          endLine: 3,
          replacementLineTexts: const ['bravo', 'charlie'],
        );

        expect(document.lineTexts, const [
          'alpha',
          'bravo',
          'charlie',
          'delta',
        ]);
        expect(document.text, 'alpha\nbravo\ncharlie\ndelta');
        expect(change.startOffset, 6);
        expect(change.oldEndOffset, 17);
        expect(change.newEndOffset, 20);
        expect(change.startPosition, const TextPosition(line: 1, column: 0));
        expect(change.oldEndPosition, const TextPosition(line: 3, column: 0));
        expect(change.newEndPosition, const TextPosition(line: 3, column: 0));
      },
    );

    test(
      'replaceLineTextRange builds large replacements through source-backed storage',
      () {
        final replacementLineTexts = List<String>.generate(
          600,
          (index) => 'line-$index-abcdefghij',
          growable: false,
        );
        final document = TextDocument(text: 'alpha\nbeta');

        document.replaceLineTextRange(
          startLine: 0,
          endLine: document.lineCount,
          replacementLineTexts: replacementLineTexts,
        );

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugSourceBackedLeafCount, greaterThan(0));
        expect(document.debugDistinctSourceCount, 1);
        expect(document.debugJoinedSourceTextCount, 0);
        expect(document.lineCount, replacementLineTexts.length);
        expect(document.lineAt(0), replacementLineTexts.first);
        expect(document.lineAt(599), replacementLineTexts.last);
      },
    );

    test(
      'replaceLineTextRange keeps grapheme-heavy large replacement lengths correct',
      () {
        const family = '👩‍👩‍👧‍👦';
        final replacementLineTexts = List<String>.generate(
          600,
          (_) => family,
          growable: false,
        );
        final document = TextDocument(text: 'alpha\nbeta');

        document.replaceLineTextRange(
          startLine: 0,
          endLine: document.lineCount,
          replacementLineTexts: replacementLineTexts,
        );

        expect(document.debugStorageDepth, greaterThan(1));
        expect(document.debugSourceBackedLeafCount, greaterThan(0));
        expect(document.debugDistinctSourceCount, 1);
        expect(document.lineCount, replacementLineTexts.length);
        expect(document.lineLength(0), 1);
        expect(document.lineLength(255), 1);
        expect(document.lineLength(256), 1);
        expect(document.lineLength(599), 1);
        expect(document.lineAt(0), family);
        expect(document.lineAt(599), family);
      },
    );

    test(
      'line-text-backed sources stay unjoined through composite full-text reads',
      () {
        final replacementLineTexts = List<String>.generate(
          600,
          (index) => 'line-$index-abcdefghij',
          growable: false,
        );
        final document = TextDocument(text: 'alpha\nbeta');

        document.replaceLineTextRange(
          startLine: 0,
          endLine: document.lineCount,
          replacementLineTexts: replacementLineTexts,
        );

        expect(document.debugJoinedSourceTextCount, 0);
        expect(
          document.textBetweenLines(startLine: 120, endLine: 181),
          replacementLineTexts.sublist(120, 181).join('\n'),
        );
        expect(document.debugJoinedSourceTextCount, 0);

        expect(document.text, replacementLineTexts.join('\n'));
        expect(document.debugJoinedSourceTextCount, 0);
      },
    );

    test(
      'replaceLineTextRange leaves revision and storage identity stable on no-op edits',
      () {
        final document = TextDocument(text: 'alpha\nbeta\ngamma');
        final revision = document.revision;
        final storageIdentity = document.storageIdentity;

        final change = document.replaceLineTextRange(
          startLine: 1,
          endLine: 2,
          replacementLineTexts: const ['beta'],
        );

        expect(document.revision, revision);
        expect(document.storageIdentity, same(storageIdentity));
        expect(document.text, 'alpha\nbeta\ngamma');
        expect(change.startOffset, 6);
        expect(change.oldEndOffset, 11);
        expect(change.newEndOffset, 11);
      },
    );

    test(
      'replaceLineTexts leaves revision and storage identity stable on no-op edits',
      () {
        final document = TextDocument(text: 'alpha\nbeta\ngamma');
        final revision = document.revision;
        final storageIdentity = document.storageIdentity;

        document.replaceLineTexts(const ['alpha', 'beta', 'gamma']);

        expect(document.revision, revision);
        expect(document.storageIdentity, same(storageIdentity));
        expect(document.text, 'alpha\nbeta\ngamma');
      },
    );

    test('replaceLineTextRange can delete lines down to one empty line', () {
      final document = TextDocument(text: 'alpha');

      final change = document.replaceLineTextRange(
        startLine: 0,
        endLine: 1,
        replacementLineTexts: const <String>[],
      );

      expect(document.lineTexts, const ['']);
      expect(document.text, '');
      expect(document.lineCount, 1);
      expect(document.length, 0);
      expect(change.startOffset, 0);
      expect(change.oldEndOffset, 5);
      expect(change.newEndOffset, 0);
    });

    test(
      'chained range edits keep composite line reads and offsets coherent',
      () {
        final document = TextDocument(text: 'zero\none\ntwo\nthree');

        document.replaceLineTextRange(
          startLine: 1,
          endLine: 2,
          replacementLineTexts: const ['ONE'],
        );
        document.replaceTextRange(
          startOffset: document.lineStartOffset(2),
          endOffset: document.lineEndOffset(2),
          replacement: 'TWO',
        );

        expect(document.lineAt(0), 'zero');
        expect(document.lineAt(1), 'ONE');
        expect(document.lineAt(2), 'TWO');
        expect(document.lineAt(3), 'three');
        expect(document.text, 'zero\nONE\nTWO\nthree');
        expect(document.textBetweenLines(startLine: 1, endLine: 3), 'ONE\nTWO');
        expect(document.lineStartOffset(2), 9);
        expect(document.lineEndOffset(2), 12);
      },
    );

    test('repeated edits normalize storage depth back to a flat composite', () {
      final document = TextDocument(text: 'zero\none\ntwo\nthree');

      for (var index = 0; index < 8; index++) {
        document.replaceLineTextRange(
          startLine: 1,
          endLine: 2,
          replacementLineTexts: ['ONE$index'],
        );
        document.replaceTextRange(
          startOffset: document.lineStartOffset(2),
          endOffset: document.lineEndOffset(2),
          replacement: 'TWO$index',
        );
      }

      expect(document.debugStorageDepth, lessThanOrEqualTo(2));
      expect(document.lineAt(0), 'zero');
      expect(document.lineAt(1), 'ONE7');
      expect(document.lineAt(2), 'TWO7');
      expect(document.lineAt(3), 'three');
      expect(document.text, 'zero\nONE7\nTWO7\nthree');
    });

    test('large documents are chunked into composite storage', () {
      final lineTexts = List<String>.generate(
        600,
        (index) => 'line-$index',
        growable: false,
      );
      final document = TextDocument.fromLineTexts(lineTexts);

      expect(document.debugStorageDepth, greaterThan(1));
      expect(document.debugStorageSegmentCount, greaterThan(1));
      expect(document.debugSourceBackedLeafCount, greaterThan(1));
      expect(document.debugDistinctSourceCount, 1);
      expect(document.lineAt(0), 'line-0');
      expect(document.lineAt(255), 'line-255');
      expect(document.lineAt(256), 'line-256');
      expect(document.lineAt(599), 'line-599');
      expect(
        document.lineStartOffset(256),
        greaterThan(document.lineEndOffset(255)),
      );
    });

    test('repeated line edits keep composite segment count bounded', () {
      final lineTexts = List<String>.generate(
        600,
        (index) => 'line-$index',
        growable: false,
      );
      final document = TextDocument.fromLineTexts(lineTexts);

      for (var index = 0; index < 96; index++) {
        final line = (index * 7) % document.lineCount;
        document.replaceLineTextRange(
          startLine: line,
          endLine: line + 1,
          replacementLineTexts: <String>['edit-$index'],
        );
      }

      expect(document.debugStorageSegmentCount, lessThanOrEqualTo(32));
      expect(document.debugStorageDepth, lessThanOrEqualTo(3));
      expect(document.lineCount, 600);
      expect(document.text, contains('edit-95'));
    });

    test(
      'editing into a chunked document coalesces adjacent source-backed slices',
      () {
        final lineTexts = List<String>.generate(
          300,
          (index) => 'line-$index',
          growable: false,
        );
        final document = TextDocument.fromLineTexts(lineTexts);

        document.replaceLineTextRange(
          startLine: 0,
          endLine: 100,
          replacementLineTexts: const <String>[],
        );

        expect(document.debugStorageDepth, 1);
        expect(document.debugStorageSegmentCount, 1);
        expect(document.debugSourceBackedLeafCount, 1);
        expect(document.debugDistinctSourceCount, 1);
        expect(document.lineCount, 200);
        expect(document.lineAt(0), 'line-100');
        expect(document.lineAt(155), 'line-255');
        expect(document.lineAt(156), 'line-256');
        expect(document.lineAt(199), 'line-299');
        expect(
          document.textBetweenLines(startLine: 150, endLine: 160),
          lineTexts.sublist(250, 260).join('\n'),
        );
      },
    );
  });
}
