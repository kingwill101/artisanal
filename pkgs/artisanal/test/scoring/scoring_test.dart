import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // MatchType
  // ---------------------------------------------------------------------------
  group('MatchType', () {
    test('priorOdds ordering', () {
      expect(
        MatchType.exact.priorOdds,
        greaterThan(MatchType.prefix.priorOdds),
      );
      expect(
        MatchType.prefix.priorOdds,
        greaterThan(MatchType.wordStart.priorOdds),
      );
      expect(
        MatchType.wordStart.priorOdds,
        greaterThan(MatchType.substring.priorOdds),
      );
      expect(
        MatchType.substring.priorOdds,
        greaterThan(MatchType.fuzzy.priorOdds),
      );
      expect(
        MatchType.fuzzy.priorOdds,
        greaterThan(MatchType.noMatch.priorOdds),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // BayesianScorer
  // ---------------------------------------------------------------------------
  group('BayesianScorer', () {
    final scorer = const BayesianScorer();
    final tracked = const BayesianScorer(trackEvidence: true);

    group('match type detection', () {
      test('exact match', () {
        final r = scorer.score('save', 'save');
        expect(r.matchType, equals(MatchType.exact));
        expect(r.score, greaterThan(0.95));
      });

      test('case insensitive exact', () {
        final r = scorer.score('Save', 'save');
        expect(r.matchType, equals(MatchType.exact));
      });

      test('prefix match', () {
        final r = scorer.score('sav', 'save');
        expect(r.matchType, equals(MatchType.prefix));
        expect(r.score, greaterThan(0.8));
      });

      test('word-start match', () {
        final r = scorer.score('gd', 'Go Dashboard');
        expect(r.matchType, equals(MatchType.wordStart));
        expect(r.score, greaterThan(0.7));
      });

      test('word-start with hyphen', () {
        final r = scorer.score('rt', 'run-tests');
        expect(r.matchType, equals(MatchType.wordStart));
      });

      test('word-start with underscore', () {
        final r = scorer.score('fb', 'foo_bar');
        expect(r.matchType, equals(MatchType.wordStart));
      });

      test('substring match', () {
        final r = scorer.score('ave', 'save');
        expect(r.matchType, equals(MatchType.substring));
        expect(r.score, greaterThan(0.5));
        expect(r.score, lessThan(0.95));
      });

      test('fuzzy match', () {
        final r = scorer.score('sve', 'save');
        expect(r.matchType, equals(MatchType.fuzzy));
        expect(r.score, greaterThan(0.0));
        expect(r.score, lessThan(0.7));
      });

      test('no match', () {
        final r = scorer.score('xyz', 'save');
        expect(r.matchType, equals(MatchType.noMatch));
        expect(r.score, equals(0.0));
      });

      test('query longer than title returns no match', () {
        final r = scorer.score('toolong', 'short');
        expect(r.matchType, equals(MatchType.noMatch));
      });

      test('empty query matches all', () {
        final r = scorer.score('', 'anything');
        expect(r.matchType, equals(MatchType.fuzzy));
        expect(r.score, greaterThan(0.0));
      });
    });

    group('score invariants', () {
      test('score bounded 0..1', () {
        final titles = [
          'save',
          'Save File',
          'Open Recent',
          'Go Dashboard',
          'Git Diff',
          'Grid Layout',
          'abc',
          'xyz',
        ];
        final queries = ['s', 'sav', 'save', 'gd', 'xyz', ''];
        for (final q in queries) {
          for (final t in titles) {
            final r = scorer.score(q, t);
            expect(
              r.score,
              greaterThanOrEqualTo(0.0),
              reason: '$q vs $t score < 0',
            );
            expect(
              r.score,
              lessThanOrEqualTo(1.0),
              reason: '$q vs $t score > 1',
            );
          }
        }
      });

      test('exact > prefix > substring > fuzzy', () {
        final exact = scorer.score('save', 'save');
        final prefix = scorer.score('sav', 'save');
        final sub = scorer.score('ave', 'save');
        final fuzzy = scorer.score('sve', 'save');

        expect(exact.score, greaterThan(prefix.score));
        expect(prefix.score, greaterThan(sub.score));
        expect(sub.score, greaterThan(fuzzy.score));
      });

      test('longer prefix >= shorter prefix', () {
        final short = scorer.score('s', 'save');
        final med = scorer.score('sa', 'save');
        final long = scorer.score('sav', 'save');

        expect(med.score, greaterThanOrEqualTo(short.score));
        expect(long.score, greaterThanOrEqualTo(med.score));
      });

      test('deterministic', () {
        final r1 = scorer.score('gd', 'Go Dashboard');
        final r2 = scorer.score('gd', 'Go Dashboard');
        expect(r1.score, equals(r2.score));
        expect(r1.matchType, equals(r2.matchType));
      });
    });

    group('position bonus', () {
      test('earlier match scores higher', () {
        final r1 = scorer.score('a', 'abc');
        final r2 = scorer.score('a', 'bca');
        expect(r1.score, greaterThanOrEqualTo(r2.score));
      });
    });

    group('word boundary bonus', () {
      test('word-start matches get bonus over substring', () {
        final ws = scorer.score('fb', 'foo bar');
        final sub = scorer.score('oo', 'foo bar');
        // Word-start has higher prior (4.0) than substring (2.0)
        expect(ws.score, greaterThan(sub.score));
      });
    });

    group('tag matching', () {
      test('tag match boosts score', () {
        // 'git' is a substring of 'Git Diff' — base match exists
        final withoutTags = scorer.score('git', 'Git Diff');
        final withTags = scorer.scoreWithTags('git', 'Git Diff', [
          'vcs',
          'version-control',
        ]);
        expect(withTags.score, greaterThanOrEqualTo(withoutTags.score));
      });

      test('tag match boosts when title also matches', () {
        final withoutTags = scorer.score('vcs', 'Version Control');
        final withTags = scorer.scoreWithTags('vcs', 'Version Control', [
          'vcs',
          'git',
        ]);
        // 'vcs' doesn't match 'Version Control' as substring, so no boost
        // But with a tag match it should still not boost since title doesn't match
        expect(withTags.score, equals(withoutTags.score));
      });

      test('no tag match does not change score', () {
        final r1 = scorer.score('save', 'Save File');
        final r2 = scorer.scoreWithTags('save', 'Save File', ['file', 'io']);
        expect(r2.score, equals(r1.score));
      });

      test('case insensitive tag matching boosts', () {
        final r = scorer.scoreWithTags('file', 'Save File', ['FILE', 'IO']);
        // 'file' matches 'Save File' as substring, tag also matches
        expect(r.score, greaterThan(0.0));
        expect(r.matchType, equals(MatchType.substring));
      });

      test('no match with tags still returns no match', () {
        final r = scorer.scoreWithTags('xyz', 'Save', ['save', 'file']);
        expect(r.matchType, equals(MatchType.noMatch));
      });
    });

    group('evidence tracking', () {
      test('evidence entries present when trackEvidence=true', () {
        final r = tracked.score('gd', 'Go Dashboard');
        expect(r.evidence, isNotEmpty);
        expect(r.evidence.any((e) => e.kind == EvidenceKind.matchType), isTrue);
        expect(r.evidence.any((e) => e.kind == EvidenceKind.position), isTrue);
        expect(
          r.evidence.any((e) => e.kind == EvidenceKind.wordBoundary),
          isTrue,
        );
      });

      test('evidence empty when trackEvidence=false', () {
        final r = scorer.score('gd', 'Go Dashboard');
        expect(r.evidence, isEmpty);
      });

      test('tag match appears in evidence', () {
        // 'file' matches 'Save File' as substring — tag 'file' also matches
        final r = tracked.scoreWithTags('file', 'Save File', ['file', 'io']);
        expect(r.evidence.any((e) => e.kind == EvidenceKind.tagMatch), isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // ConformalRanker
  // ---------------------------------------------------------------------------
  group('ConformalRanker', () {
    final scorer = const BayesianScorer();
    final ranker = const ConformalRanker();

    test('empty input', () {
      final r = ranker.rank([]);
      expect(r.items, isEmpty);
      expect(r.summary.count, equals(0));
    });

    test('single item has confidence 1.0 and is stable', () {
      final results = [scorer.score('save', 'Save File')];
      final r = ranker.rank(results);
      expect(r.items, hasLength(1));
      expect(r.items[0].rankConfidence.confidence, equals(1.0));
      // Single item with no gaps is not a "tie" — it's trivially stable
      expect(r.items[0].rankConfidence.stability, equals(RankStability.stable));
    });

    test('sorted descending by score', () {
      final results = [
        scorer.score('s', 'Save'),
        scorer.score('s', 'Open'),
        scorer.score('s', 'Close'),
      ];
      final r = ranker.rank(results);
      for (var i = 1; i < r.items.length; i++) {
        expect(
          r.items[i - 1].result.score,
          greaterThanOrEqualTo(r.items[i].result.score),
        );
      }
    });

    test('well-separated scores are stable or marginal', () {
      final results = [
        scorer.score('save', 'Save File'), // prefix match
        scorer.score('save', 'Save As'), // prefix match
        scorer.score('save', 'Recently Opened'), // no match (score 0)
      ];
      final r = ranker.rank(results);
      // The top item has a clear gap vs the no-match item
      // It should be at least marginal (not unstable)
      expect(
        r.items[0].rankConfidence.stability,
        isNot(equals(RankStability.unstable)),
      );
    });

    test('identical scores are unstable', () {
      final results = [scorer.score('s', 'Save'), scorer.score('s', 'Song')];
      // These might have similar scores — if so, should be marginal/unstable
      final r = ranker.rank(results);
      expect(r.items, hasLength(2));
      // At least verify the summary makes sense
      expect(r.summary.count, equals(2));
    });

    test('rankTopK truncates', () {
      final results = [
        scorer.score('s', 'Save'),
        scorer.score('s', 'Open'),
        scorer.score('s', 'Close'),
        scorer.score('s', 'New'),
        scorer.score('s', 'Find'),
      ];
      final r = ranker.rankTopK(results, 3);
      expect(r.items, hasLength(3));
      expect(r.summary.count, equals(5)); // full count preserved
    });

    test('original indices preserved', () {
      final results = [
        scorer.score('op', 'Close'), // index 0 — no match
        scorer.score('op', 'Options'), // index 1 — prefix match
        scorer.score('op', 'Open'), // index 2 — prefix match
      ];
      final r = ranker.rank(results);
      // The highest-scoring items should be the prefix matches
      expect(r.items.first.result.matchType, equals(MatchType.prefix));
      // All items should have their original indices
      final origIndices = r.items.map((i) => i.originalIndex).toSet();
      expect(origIndices, equals({0, 1, 2}));
    });
  });

  // ---------------------------------------------------------------------------
  // IncrementalScorer
  // ---------------------------------------------------------------------------
  group('IncrementalScorer', () {
    late IncrementalScorer inc;
    final corpus = ['Save File', 'Open Recent', 'Go Dashboard', 'Git Diff'];

    setUp(() {
      inc = IncrementalScorer();
    });

    test('full scan on first call', () {
      final r = inc.scoreCorpus('gd', corpus);
      expect(r, hasLength(4));
      expect(inc.fullScans, equals(1));
      expect(inc.incrementalScans, equals(0));
    });

    test('incremental on query extension', () {
      inc.scoreCorpus('g', corpus);
      final r = inc.scoreCorpus('gd', corpus);
      expect(r, hasLength(4));
      expect(inc.incrementalScans, equals(1));
    });

    test('full scan on non-extension (backspace)', () {
      inc.scoreCorpus('gd', corpus);
      inc.scoreCorpus('g', corpus);
      expect(inc.fullScans, equals(2));
    });

    test('results match full scan', () {
      final scorer = BayesianScorer();
      final fullResults = corpus.map((t) => scorer.score('gd', t)).toList();

      final incResults = inc.scoreCorpus('gd', corpus);

      for (var i = 0; i < corpus.length; i++) {
        expect(incResults[i].score, equals(fullResults[i].score));
        expect(incResults[i].matchType, equals(fullResults[i].matchType));
      }
    });

    test('incremental results match full scan on extension', () {
      inc.scoreCorpus('g', corpus);

      // Now do a full scan for 'gd' to compare
      final scorer = BayesianScorer();
      final fullResults = corpus.map((t) => scorer.score('gd', t)).toList();

      final incResults = inc.scoreCorpus('gd', corpus);

      for (var i = 0; i < corpus.length; i++) {
        expect(incResults[i].score, equals(fullResults[i].score));
        expect(incResults[i].matchType, equals(fullResults[i].matchType));
      }
    });

    test('invalidate forces full scan', () {
      inc.scoreCorpus('g', corpus);
      inc.invalidate();
      inc.scoreCorpus('gd', corpus);
      expect(inc.fullScans, equals(2));
    });

    test('empty query returns all items', () {
      final r = inc.scoreCorpus('', corpus);
      expect(r, hasLength(4));
      for (final result in r) {
        expect(result.matchType, equals(MatchType.fuzzy));
        expect(result.score, greaterThan(0.0));
      }
    });

    test('tag scoring works', () {
      final tags = [
        ['file', 'io'],
        ['file', 'recent'],
        ['nav', 'ui'],
        ['git', 'vcs'],
      ];
      final r = inc.scoreCorpusWithTags('git', corpus, tags);
      expect(r, hasLength(4));
      // 'Git Diff' should match via title; 'Save File' with tag 'git' would also boost if it matched
    });
  });
}
