final class GithubDiffCommentTarget {
  const GithubDiffCommentTarget({
    required this.path,
    required this.line,
    required this.side,
    this.startLine,
    this.startSide,
  });

  final String path;
  final int line;
  final String side;
  final int? startLine;
  final String? startSide;

  bool get isRange => startLine != null && startLine != line;

  String get label {
    final marker = side == 'LEFT' ? '-' : '+';
    final start = startLine;
    if (start != null && start != line) {
      return '$path:$marker$start-$marker$line';
    }
    return '$path:$marker$line';
  }
}
