import 'package:artisanal_widgets/widgets.dart' as w;

final class GithubDiffCommentTarget {
  const GithubDiffCommentTarget({
    required this.path,
    required this.line,
    required this.side,
    required this.renderLine,
    this.startLine,
    this.startSide,
  });

  factory GithubDiffCommentTarget.fromAnchor(
    w.DiffCommentAnchor anchor, {
    w.DiffCommentAnchor? startAnchor,
  }) {
    return GithubDiffCommentTarget(
      path: anchor.path,
      line: anchor.line,
      side: anchor.side.githubApiValue,
      renderLine: anchor.renderLine,
      startLine: startAnchor?.line,
      startSide: startAnchor?.side.githubApiValue,
    );
  }

  final String path;
  final int line;
  final String side;
  final int renderLine;
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
