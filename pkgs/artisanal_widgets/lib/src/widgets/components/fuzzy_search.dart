/// Scores how closely a query matches searchable text.
///
/// Each whitespace-separated query term must match a word in [text]. Exact
/// words score `1`; prefixes, substrings, subsequences and small spelling
/// differences score progressively lower. Empty queries score `1` and empty
/// text scores `0` for a non-empty query.
///
/// Use the score with a threshold to filter results, then sort descending to
/// rank the closest matches. The score is intended for short UI labels and
/// search terms, not long documents.
abstract final class FuzzySearch {
  /// Returns a normalized match score between `0` and `1`.
  static double score(String query, String text) {
    final queryWords = _words(query);
    if (queryWords.isEmpty) return query.trim().isEmpty ? 1 : 0;
    final textWords = _words(text);
    if (textWords.isEmpty) return 0;

    var totalScore = 0.0;
    for (final queryWord in queryWords) {
      var bestScore = 0.0;
      for (final textWord in textWords) {
        final candidateScore = _wordScore(queryWord, textWord);
        if (candidateScore > bestScore) bestScore = candidateScore;
      }
      if (bestScore == 0) return 0;
      totalScore += bestScore;
    }
    return totalScore / queryWords.length;
  }

  static List<String> _words(String value) => value
      .toLowerCase()
      .split(RegExp(r'[\s,./:_-]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  static double _wordScore(String query, String text) {
    if (query == text) return 1;
    if (text.startsWith(query)) {
      return 0.82 + 0.18 * query.length / text.length;
    }
    if (text.contains(query)) {
      return 0.78 + 0.22 * query.length / text.length;
    }

    final subsequenceScore = _subsequenceScore(query, text);
    if (subsequenceScore > 0) return subsequenceScore;

    final queryCharacters = query.runes.toList(growable: false);
    final textCharacters = text.runes.toList(growable: false);
    final maximumLength = queryCharacters.length > textCharacters.length
        ? queryCharacters.length
        : textCharacters.length;
    final distance = _editDistance(queryCharacters, textCharacters);
    return 1 - distance / maximumLength;
  }

  static double _subsequenceScore(String query, String text) {
    final queryCharacters = query.runes.toList(growable: false);
    final textCharacters = text.runes.toList(growable: false);
    var queryIndex = 0;
    var longestRun = 0;
    var currentRun = 0;
    for (final character in textCharacters) {
      if (queryIndex < queryCharacters.length &&
          character == queryCharacters[queryIndex]) {
        queryIndex++;
        currentRun++;
        if (currentRun > longestRun) longestRun = currentRun;
      } else {
        currentRun = 0;
      }
    }
    if (queryIndex != queryCharacters.length) return 0;
    final coverage = queryCharacters.length / textCharacters.length;
    final continuity = longestRun / queryCharacters.length;
    return 0.64 + 0.22 * coverage + 0.14 * continuity;
  }

  static int _editDistance(List<int> left, List<int> right) {
    var previousRow = List<int>.generate(right.length + 1, (index) => index);
    for (var leftIndex = 1; leftIndex <= left.length; leftIndex++) {
      final currentRow = List<int>.filled(right.length + 1, 0);
      currentRow[0] = leftIndex;
      for (var rightIndex = 1; rightIndex <= right.length; rightIndex++) {
        final substitutionCost = left[leftIndex - 1] == right[rightIndex - 1]
            ? 0
            : 1;
        final deletion = previousRow[rightIndex] + 1;
        final insertion = currentRow[rightIndex - 1] + 1;
        final substitution = previousRow[rightIndex - 1] + substitutionCost;
        currentRow[rightIndex] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }
      previousRow = currentRow;
    }
    return previousRow[right.length];
  }
}
