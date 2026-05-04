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

  static GithubPullRequestReviewComment? fromJson(Map<String, Object?> json) {
    final path = ghString(json['path']);
    final line = ghInt(json['line'] ?? json['original_line']);
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
    );
  }
}
