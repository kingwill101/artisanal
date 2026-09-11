import '../client/json.dart';

final class GithubCommentItem {
  const GithubCommentItem({
    required this.author,
    required this.body,
    required this.url,
    required this.createdAt,
    this.avatarUrl = '',
  });

  final String author;
  final String body;
  final String url;
  final DateTime? createdAt;
  final String avatarUrl;

  static GithubCommentItem fromJson(Map<String, Object?> json) {
    final author = ghMap(json['author']);
    final user = ghMap(json['user']);
    return GithubCommentItem(
      author: ghString(author['login'] ?? user['login'], fallback: 'unknown'),
      body: ghString(json['body']),
      url: ghString(json['html_url'] ?? json['url']),
      createdAt: ghDate(json['createdAt'] ?? json['created_at']),
      avatarUrl: ghString(
        author['avatarUrl'] ??
            author['avatar_url'] ??
            user['avatarUrl'] ??
            user['avatar_url'],
      ),
    );
  }
}
