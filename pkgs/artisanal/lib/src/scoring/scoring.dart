/// Bayesian match scoring for command palette filtering.
///
/// Implements a probabilistic scoring model using Bayes factors to compute
/// match relevance. An evidence ledger tracks each scoring factor and its
/// contribution, enabling explainable ranking decisions.
///
/// ```dart
/// final scorer = BayesianScorer();
/// final result = scorer.score('gd', 'Go Dashboard');
/// print(result.score);       // 0.823
/// print(result.matchType);   // MatchType.wordStart
///
/// // Incremental scoring for query-as-you-type
/// final inc = IncrementalScorer();
/// final ranked = inc.scoreCorpus('gd', ['Go Dashboard', 'Git Diff', 'Grid']);
/// ```
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Match Types
// ---------------------------------------------------------------------------

/// Type of match between query and title.
///
/// Ordered from strongest to weakest: exact > prefix > wordStart >
/// substring > fuzzy > noMatch.
enum MatchType {
  /// No characters found.
  noMatch,

  /// Characters found in order but with gaps.
  fuzzy,

  /// Query found as contiguous substring.
  substring,

  /// Query matches start of word boundaries.
  wordStart,

  /// Title starts with query.
  prefix,

  /// Query equals title exactly.
  exact;

  /// Prior odds ratio P(relevant) / P(not_relevant) for this match type.
  double get priorOdds => switch (this) {
    MatchType.exact => 99.0,
    MatchType.prefix => 9.0,
    MatchType.wordStart => 4.0,
    MatchType.substring => 2.0,
    MatchType.fuzzy => 0.333,
    MatchType.noMatch => 0.0,
  };
}

// ---------------------------------------------------------------------------
// Match Result
// ---------------------------------------------------------------------------

/// Result of scoring a query against a title.
class MatchResult {
  const MatchResult({
    required this.score,
    required this.matchType,
    this.matchPositions = const [],
    this.evidence = const [],
  });

  /// Create a no-match result.
  const MatchResult.noMatch()
    : score = 0.0,
      matchType = MatchType.noMatch,
      matchPositions = const [],
      evidence = const [];

  /// Computed relevance score (posterior probability, 0.0–1.0).
  final double score;

  /// Type of match detected.
  final MatchType matchType;

  /// Positions of matched characters in the title.
  final List<int> matchPositions;

  /// Evidence entries explaining the score.
  final List<EvidenceEntry> evidence;
}

// ---------------------------------------------------------------------------
// Evidence
// ---------------------------------------------------------------------------

/// Types of evidence that contribute to match scoring.
enum EvidenceKind {
  /// Base match type (prior).
  matchType,

  /// Match at word boundary.
  wordBoundary,

  /// Match position (earlier is better).
  position,

  /// Gap between matched characters.
  gapPenalty,

  /// Query also matches a tag.
  tagMatch,

  /// Title length factor (shorter is more specific).
  titleLength,
}

/// A single piece of evidence contributing to the match score.
class EvidenceEntry {
  const EvidenceEntry({
    required this.kind,
    required this.bayesFactor,
    required this.description,
  });

  /// Type of evidence.
  final EvidenceKind kind;

  /// Bayes factor: values > 1.0 support relevance, < 1.0 oppose it.
  final double bayesFactor;

  /// Human-readable explanation.
  final String description;

  @override
  String toString() =>
      '$kind: BF=${bayesFactor.toStringAsFixed(2)} - $description';
}

// ---------------------------------------------------------------------------
// Bayesian Scorer
// ---------------------------------------------------------------------------

/// Bayesian fuzzy matcher for command palette.
///
/// Computes relevance scores using a probabilistic model with match
/// classification (exact > prefix > word-start > substring > fuzzy) and
/// weighted evidence factors (position, word boundaries, gap, title length).
///
/// ```dart
/// final scorer = BayesianScorer();
/// final r = scorer.score('gd', 'Go Dashboard');
/// // r.matchType == MatchType.wordStart
/// // r.score ≈ 0.82
/// ```
class BayesianScorer {
  /// Whether to track detailed evidence (slightly slower but explainable).
  final bool trackEvidence;

  const BayesianScorer({this.trackEvidence = false});

  /// Score a query against a title.
  MatchResult score(String query, String title) {
    if (query.length > title.length) return const MatchResult.noMatch();
    if (query.isEmpty) return _scoreEmpty(title);

    final queryLower = query.toLowerCase();
    final titleLower = title.toLowerCase();

    final (matchType, positions) = _detectMatchType(queryLower, titleLower);
    if (matchType == MatchType.noMatch) return const MatchResult.noMatch();

    return _computeScore(matchType, positions, queryLower, title);
  }

  /// Score a query against a title with searchable tags.
  MatchResult scoreWithTags(String query, String title, List<String> tags) {
    final result = score(query, title);
    if (result.matchType == MatchType.noMatch) return result;

    final queryLower = query.toLowerCase();
    final tagMatch = tags.any((tag) => tag.toLowerCase().contains(queryLower));

    if (!tagMatch) return result;

    if (trackEvidence) {
      final evidence = [
        ...result.evidence,
        const EvidenceEntry(
          kind: EvidenceKind.tagMatch,
          bayesFactor: 3.0,
          description: 'query matches tag',
        ),
      ];
      final score = _posteriorProbability(evidence);
      return MatchResult(
        score: score,
        matchType: result.matchType,
        matchPositions: result.matchPositions,
        evidence: evidence,
      );
    }

    // Fast path: multiply odds by 3.0
    if (result.score > 0.0 && result.score < 1.0) {
      final odds = result.score / (1.0 - result.score);
      final boosted = odds * 3.0;
      return MatchResult(
        score: boosted / (1.0 + boosted),
        matchType: result.matchType,
        matchPositions: result.matchPositions,
      );
    }

    return result;
  }

  MatchResult _scoreEmpty(String title) {
    final lengthFactor = 1.0 + (1.0 / (title.length + 1)) * 0.1;
    final score = lengthFactor / (1.0 + lengthFactor);
    if (trackEvidence) {
      final evidence = [
        const EvidenceEntry(
          kind: EvidenceKind.matchType,
          bayesFactor: 1.0,
          description: 'empty query matches all',
        ),
        EvidenceEntry(
          kind: EvidenceKind.titleLength,
          bayesFactor: lengthFactor,
          description: 'title length ${title.length} chars',
        ),
      ];
      return MatchResult(
        score: _posteriorProbability(evidence),
        matchType: MatchType.fuzzy,
        evidence: evidence,
      );
    }
    return MatchResult(score: score, matchType: MatchType.fuzzy);
  }

  (MatchType, List<int>) _detectMatchType(
    String queryLower,
    String titleLower,
  ) {
    // Exact
    if (queryLower == titleLower) {
      return (MatchType.exact, List.generate(titleLower.length, (i) => i));
    }

    // Prefix
    if (titleLower.startsWith(queryLower)) {
      return (MatchType.prefix, List.generate(queryLower.length, (i) => i));
    }

    // Word-start
    final wsPositions = _wordStartMatch(queryLower, titleLower);
    if (wsPositions != null) return (MatchType.wordStart, wsPositions);

    // Substring
    final subStart = titleLower.indexOf(queryLower);
    if (subStart >= 0) {
      return (
        MatchType.substring,
        List.generate(queryLower.length, (i) => subStart + i),
      );
    }

    // Fuzzy
    final fuzzyPositions = _fuzzyMatch(queryLower, titleLower);
    if (fuzzyPositions != null) return (MatchType.fuzzy, fuzzyPositions);

    return (MatchType.noMatch, const []);
  }

  List<int>? _wordStartMatch(String query, String title) {
    final positions = <int>[];
    var qi = 0;

    for (var i = 0; i < title.length; i++) {
      final isWordStart =
          i == 0 ||
          title.codeUnitAt(i - 1) == 0x20 || // space
          title.codeUnitAt(i - 1) == 0x2D || // -
          title.codeUnitAt(i - 1) == 0x5F; // _

      if (isWordStart && qi < query.length && title[i] == query[qi]) {
        positions.add(i);
        qi++;
      }
    }

    return qi == query.length ? positions : null;
  }

  List<int>? _fuzzyMatch(String query, String title) {
    final positions = <int>[];
    var qi = 0;

    for (var i = 0; i < title.length; i++) {
      if (qi < query.length && title[i] == query[qi]) {
        positions.add(i);
        qi++;
      }
    }

    return qi == query.length ? positions : null;
  }

  MatchResult _computeScore(
    MatchType matchType,
    List<int> positions,
    String queryLower,
    String title,
  ) {
    if (trackEvidence) {
      final evidence = <EvidenceEntry>[
        EvidenceEntry(
          kind: EvidenceKind.matchType,
          bayesFactor: matchType.priorOdds,
          description: matchType.name,
        ),
      ];

      // Position bonus
      if (positions.isNotEmpty) {
        final firstPos = positions.first;
        final factor = 1.0 + (1.0 / (firstPos + 1)) * 0.5;
        evidence.add(
          EvidenceEntry(
            kind: EvidenceKind.position,
            bayesFactor: factor,
            description: 'first match at position $firstPos',
          ),
        );
      }

      // Word boundary bonus
      final boundaryCount = _countWordBoundaries(positions, title);
      if (boundaryCount > 0) {
        final factor = 1.0 + (boundaryCount * 0.3);
        evidence.add(
          EvidenceEntry(
            kind: EvidenceKind.wordBoundary,
            bayesFactor: factor,
            description: '$boundaryCount word boundary matches',
          ),
        );
      }

      // Gap penalty for fuzzy
      if (matchType == MatchType.fuzzy && positions.length > 1) {
        final totalGap = _totalGap(positions);
        final factor = 1.0 / (1.0 + totalGap * 0.1);
        evidence.add(
          EvidenceEntry(
            kind: EvidenceKind.gapPenalty,
            bayesFactor: factor,
            description: 'total gap of $totalGap characters',
          ),
        );
      }

      // Title length
      final titleLen = title.length.clamp(1, 999999);
      final lengthFactor = 1.0 + (queryLower.length / titleLen) * 0.2;
      evidence.add(
        EvidenceEntry(
          kind: EvidenceKind.titleLength,
          bayesFactor: lengthFactor,
          description:
              'query covers ${(queryLower.length / titleLen * 100).toStringAsFixed(0)}% of title',
        ),
      );

      return MatchResult(
        score: _posteriorProbability(evidence),
        matchType: matchType,
        matchPositions: positions,
        evidence: evidence,
      );
    }

    // Fast path: no evidence tracking
    var combinedBf = matchType.priorOdds;

    if (positions.isNotEmpty) {
      combinedBf *= 1.0 + (1.0 / (positions.first + 1)) * 0.5;
    }

    final boundaryCount = _countWordBoundaries(positions, title);
    if (boundaryCount > 0) {
      combinedBf *= 1.0 + (boundaryCount * 0.3);
    }

    if (matchType == MatchType.fuzzy && positions.length > 1) {
      final totalGap = _totalGap(positions);
      combinedBf *= 1.0 / (1.0 + totalGap * 0.1);
    }

    final titleLen = title.length.clamp(1, 999999);
    combinedBf *= 1.0 + (queryLower.length / titleLen) * 0.2;

    final score = combinedBf / (1.0 + combinedBf);
    return MatchResult(
      score: score,
      matchType: matchType,
      matchPositions: positions,
    );
  }

  int _countWordBoundaries(List<int> positions, String title) {
    var count = 0;
    for (final pos in positions) {
      if (pos == 0) {
        count++;
      } else if (pos > 0) {
        final prev = title.codeUnitAt(pos - 1);
        if (prev == 0x20 || prev == 0x2D || prev == 0x5F) {
          count++;
        }
      }
    }
    return count;
  }

  int _totalGap(List<int> positions) {
    if (positions.length < 2) return 0;
    var total = 0;
    for (var i = 1; i < positions.length; i++) {
      total += (positions[i] - positions[i - 1] - 1).clamp(0, 999999);
    }
    return total;
  }

  static double _posteriorProbability(List<EvidenceEntry> evidence) {
    final priorEntry = evidence.firstWhere(
      (e) => e.kind == EvidenceKind.matchType,
      orElse: () => const EvidenceEntry(
        kind: EvidenceKind.matchType,
        bayesFactor: 1.0,
        description: 'default',
      ),
    );
    final prior = priorEntry.bayesFactor;

    var bf = 1.0;
    for (final e in evidence) {
      if (e.kind != EvidenceKind.matchType) {
        bf *= e.bayesFactor;
      }
    }

    final posteriorOdds = prior * bf;
    if (posteriorOdds.isInfinite) return 1.0;
    return posteriorOdds / (1.0 + posteriorOdds);
  }
}

// ---------------------------------------------------------------------------
// Ranked Results
// ---------------------------------------------------------------------------

/// Stability classification for a rank position.
enum RankStability {
  /// Score gap is large — rank is reliable.
  stable,

  /// Score gap is moderate — could swap with neighbors.
  marginal,

  /// Score gap is negligible — essentially a tie.
  unstable;

  String get label => name;
}

/// Confidence level for a ranking position.
class RankConfidence {
  const RankConfidence({
    required this.confidence,
    required this.gapToNext,
    required this.stability,
  });

  /// Probability that this item truly belongs at this rank position.
  final double confidence;

  /// Absolute score gap to the next-ranked item.
  final double gapToNext;

  /// Stability classification.
  final RankStability stability;
}

/// A single item in the ranked results.
class RankedItem {
  const RankedItem({
    required this.originalIndex,
    required this.result,
    required this.rankConfidence,
  });

  /// Index into the original (pre-sort) input list.
  final int originalIndex;

  /// The match result.
  final MatchResult result;

  /// Conformal confidence for this rank position.
  final RankConfidence rankConfidence;
}

/// Summary statistics for a ranked result set.
class RankingSummary {
  const RankingSummary({
    required this.count,
    required this.stableCount,
    required this.tieGroupCount,
    required this.medianGap,
  });

  final int count;
  final int stableCount;
  final int tieGroupCount;
  final double medianGap;
}

/// Result of ranking a set of match results.
class RankedResults {
  const RankedResults({required this.items, required this.summary});

  final List<RankedItem> items;
  final RankingSummary summary;
}

// ---------------------------------------------------------------------------
// Conformal Ranker
// ---------------------------------------------------------------------------

/// Conformal ranker that assigns distribution-free confidence to rank positions.
///
/// Given sorted scores, computes the conformal p-value (fraction of gaps
/// ≤ this gap) and classifies each position as stable/marginal/unstable.
class ConformalRanker {
  /// Threshold below which two scores are considered tied.
  final double tieEpsilon;

  /// Confidence threshold for [RankStability.stable].
  final double stableThreshold;

  /// Confidence threshold for [RankStability.marginal].
  final double marginalThreshold;

  const ConformalRanker({
    this.tieEpsilon = 1e-9,
    this.stableThreshold = 0.7,
    this.marginalThreshold = 0.3,
  });

  /// Rank a list of match results and assign conformal confidence.
  RankedResults rank(List<MatchResult> results) {
    final count = results.length;
    if (count == 0) {
      return const RankedResults(
        items: [],
        summary: RankingSummary(
          count: 0,
          stableCount: 0,
          tieGroupCount: 0,
          medianGap: 0,
        ),
      );
    }

    // Tag with original index, sort descending by score then match type
    final indexed = <(int, MatchResult)>[];
    for (var i = 0; i < results.length; i++) {
      indexed.add((i, results[i]));
    }
    indexed.sort((a, b) {
      final scoreCmp = b.$2.score.compareTo(a.$2.score);
      if (scoreCmp != 0) return scoreCmp;
      return b.$2.matchType.index.compareTo(a.$2.matchType.index);
    });

    // Compute gaps
    final gaps = <double>[];
    for (var i = 0; i < indexed.length - 1; i++) {
      gaps.add(
        (indexed[i].$2.score - indexed[i + 1].$2.score).clamp(
          0,
          double.infinity,
        ),
      );
    }

    final sortedGaps = List<double>.from(gaps)..sort();

    // Compute confidence per position
    final items = <RankedItem>[];
    var stableCount = 0;
    var tieGroupCount = 0;
    var inTieGroup = false;

    for (var rank = 0; rank < indexed.length; rank++) {
      final (origIdx, result) = indexed[rank];
      final gapToNext = rank < gaps.length ? gaps[rank] : 0.0;

      double confidence;
      if (sortedGaps.isEmpty) {
        confidence = 1.0;
      } else {
        final leqCount = sortedGaps
            .where((g) => g <= gapToNext + tieEpsilon * 0.5)
            .length;
        confidence = leqCount / sortedGaps.length;
      }

      final isTie = gaps.isNotEmpty && gapToNext < tieEpsilon;
      RankStability stability;
      if (isTie) {
        if (!inTieGroup) {
          tieGroupCount++;
          inTieGroup = true;
        }
        stability = RankStability.unstable;
      } else {
        inTieGroup = false;
        if (confidence >= stableThreshold) {
          stableCount++;
          stability = RankStability.stable;
        } else if (confidence >= marginalThreshold) {
          stability = RankStability.marginal;
        } else {
          stability = RankStability.unstable;
        }
      }

      items.add(
        RankedItem(
          originalIndex: origIdx,
          result: result,
          rankConfidence: RankConfidence(
            confidence: confidence,
            gapToNext: gapToNext,
            stability: stability,
          ),
        ),
      );
    }

    // Median gap
    double medianGap;
    if (sortedGaps.isEmpty) {
      medianGap = 0;
    } else {
      final mid = sortedGaps.length ~/ 2;
      if (sortedGaps.length.isEven) {
        medianGap = (sortedGaps[mid - 1] + sortedGaps[mid]) / 2;
      } else {
        medianGap = sortedGaps[mid];
      }
    }

    return RankedResults(
      items: items,
      summary: RankingSummary(
        count: count,
        stableCount: stableCount,
        tieGroupCount: tieGroupCount,
        medianGap: medianGap,
      ),
    );
  }

  /// Rank and return only the top-k items.
  RankedResults rankTopK(List<MatchResult> results, int k) {
    final ranked = rank(results);
    final truncated = ranked.items.length > k
        ? ranked.items.sublist(0, k)
        : ranked.items;
    final stableCount = truncated
        .where((i) => i.rankConfidence.stability == RankStability.stable)
        .length;
    return RankedResults(
      items: truncated,
      summary: RankingSummary(
        count: ranked.summary.count,
        stableCount: stableCount,
        tieGroupCount: ranked.summary.tieGroupCount,
        medianGap: ranked.summary.medianGap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Incremental Scorer
// ---------------------------------------------------------------------------

/// Cached entry from a previous scoring pass.
class _CachedEntry {
  _CachedEntry({required this.index, required this.result});
  final int index;
  final MatchResult result;
}

/// Incremental scorer that caches previous query results.
///
/// When the new query is a prefix extension of the previous query,
/// only re-scores items that previously matched (O(M×L) instead of
/// O(N×L)). Falls back to full scan for non-extending queries.
///
/// ```dart
/// final inc = IncrementalScorer();
/// var r1 = inc.scoreCorpus('gd', titles);
/// var r2 = inc.scoreCorpus('gdo', titles); // incremental — only rescores matches
/// ```
class IncrementalScorer {
  final BayesianScorer _scorer;
  String _prevQuery = '';
  List<_CachedEntry> _cache = [];
  int _corpusGeneration = -1;
  int _corpusLen = 0;

  int _fullScans = 0;
  int _incrementalScans = 0;
  int _totalEvaluated = 0;

  IncrementalScorer({BayesianScorer? scorer})
    : _scorer = scorer ?? const BayesianScorer();

  /// Number of full scans performed.
  int get fullScans => _fullScans;

  /// Number of incremental scans performed.
  int get incrementalScans => _incrementalScans;

  /// Total items evaluated across all scans.
  int get totalEvaluated => _totalEvaluated;

  /// Invalidate the cache (forces full scan on next call).
  void invalidate() {
    _prevQuery = '';
    _cache = [];
    _corpusGeneration = -1;
  }

  /// Score all items in [corpus], returning match results.
  ///
  /// [generation] is an optional corpus version; changing it invalidates the cache.
  List<MatchResult> scoreCorpus(
    String query,
    List<String> corpus, {
    int? generation,
  }) {
    if (query.isEmpty) {
      _prevQuery = '';
      _cache = [];
      final results = <MatchResult>[];
      for (final title in corpus) {
        results.add(_scorer.score('', title));
      }
      return results;
    }

    final isExtension =
        _prevQuery.isNotEmpty &&
        query.startsWith(_prevQuery) &&
        query.length > _prevQuery.length &&
        (generation == null || generation == _corpusGeneration) &&
        corpus.length == _corpusLen;

    if (isExtension && _cache.isNotEmpty) {
      // Incremental: only re-score previously matched items
      _incrementalScans++;
      final newCache = <_CachedEntry>[];
      final results = List<MatchResult>.filled(
        corpus.length,
        const MatchResult.noMatch(),
      );

      for (final entry in _cache) {
        final result = _scorer.score(query, corpus[entry.index]);
        results[entry.index] = result;
        if (result.matchType != MatchType.noMatch) {
          newCache.add(_CachedEntry(index: entry.index, result: result));
        }
      }
      _totalEvaluated += _cache.length;
      _cache = newCache;
      _prevQuery = query;
      return results;
    }

    // Full scan
    _fullScans++;
    _cache = [];
    final results = <MatchResult>[];

    for (var i = 0; i < corpus.length; i++) {
      final result = _scorer.score(query, corpus[i]);
      results.add(result);
      if (result.matchType != MatchType.noMatch) {
        _cache.add(_CachedEntry(index: i, result: result));
      }
    }

    _totalEvaluated += corpus.length;
    _prevQuery = query;
    _corpusGeneration = generation ?? _corpusGeneration;
    _corpusLen = corpus.length;
    return results;
  }

  /// Score all items with tags, returning match results.
  List<MatchResult> scoreCorpusWithTags(
    String query,
    List<String> corpus,
    List<List<String>> tags, {
    int? generation,
  }) {
    assert(corpus.length == tags.length);

    if (query.isEmpty) {
      _prevQuery = '';
      _cache = [];
      return corpus.map((t) => _scorer.score('', t)).toList();
    }

    final isExtension =
        _prevQuery.isNotEmpty &&
        query.startsWith(_prevQuery) &&
        query.length > _prevQuery.length &&
        (generation == null || generation == _corpusGeneration) &&
        corpus.length == _corpusLen;

    if (isExtension && _cache.isNotEmpty) {
      _incrementalScans++;
      final newCache = <_CachedEntry>[];
      final results = List<MatchResult>.filled(
        corpus.length,
        const MatchResult.noMatch(),
      );

      for (final entry in _cache) {
        final result = _scorer.scoreWithTags(
          query,
          corpus[entry.index],
          tags[entry.index],
        );
        results[entry.index] = result;
        if (result.matchType != MatchType.noMatch) {
          newCache.add(_CachedEntry(index: entry.index, result: result));
        }
      }
      _totalEvaluated += _cache.length;
      _cache = newCache;
      _prevQuery = query;
      return results;
    }

    _fullScans++;
    _cache = [];
    final results = <MatchResult>[];

    for (var i = 0; i < corpus.length; i++) {
      final result = _scorer.scoreWithTags(query, corpus[i], tags[i]);
      results.add(result);
      if (result.matchType != MatchType.noMatch) {
        _cache.add(_CachedEntry(index: i, result: result));
      }
    }

    _totalEvaluated += corpus.length;
    _prevQuery = query;
    _corpusGeneration = generation ?? _corpusGeneration;
    _corpusLen = corpus.length;
    return results;
  }
}
