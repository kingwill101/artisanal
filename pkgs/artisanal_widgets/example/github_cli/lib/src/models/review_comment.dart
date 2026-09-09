import '../client/json.dart';

final class GithubPullRequestReviewComment {
  const GithubPullRequestReviewComment({
    required this.id,
    required this.path,
    required this.line,
    required this.side,
    required this.author,
    required this.body,
    required this.url,
    required this.createdAt,
    this.avatarUrl = '',
    this.startLine,
    this.startSide,
    this.replyToId,
    this.outdated = false,
  });

  final String id;
  final String path;
  final int line;
  final String side;
  final String author;
  final String body;
  final String url;
  final DateTime? createdAt;
  final String avatarUrl;

  /// Inclusive start of a multiline attachment, on [startSide].
  final int? startLine;
  final String? startSide;

  /// GitHub's root review comment ID, not a source-row identity.
  final String? replyToId;

  /// The current position is absent; [line] belongs to the original revision.
  final bool outdated;

  static GithubPullRequestReviewComment? fromJson(Map<String, Object?> json) {
    final path = ghString(json['path']);
    final currentLine = ghInt(json['line']);
    final outdated = currentLine <= 0;
    final line = outdated ? ghInt(json['original_line']) : currentLine;
    final startLine = ghInt(
      outdated ? json['original_start_line'] : json['start_line'],
    );
    final side = ghString(json['side']);
    if (path.isEmpty || line <= 0 || (side != 'LEFT' && side != 'RIGHT')) {
      return null;
    }
    final id = ghString(
      json['id'] ?? json['node_id'],
      fallback: '$path:$side:$line:${ghString(json['created_at'])}',
    );
    return GithubPullRequestReviewComment(
      id: id,
      path: path,
      line: line,
      side: side,
      author: ghString(ghMap(json['user'])['login'], fallback: 'unknown'),
      body: ghString(json['body']),
      url: ghString(json['html_url'] ?? json['url']),
      createdAt: ghDate(json['created_at']),
      avatarUrl: ghString(ghMap(json['user'])['avatar_url']),
      startLine: startLine > 0 ? startLine : null,
      startSide: startLine > 0
          ? ghString(json['start_side'], fallback: side)
          : null,
      replyToId: json['in_reply_to_id'] == null
          ? null
          : ghString(json['in_reply_to_id']),
      outdated: outdated,
    );
  }
}
