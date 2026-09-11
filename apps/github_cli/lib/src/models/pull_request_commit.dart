import '../client/json.dart';

final class GithubPullRequestCommit {
  const GithubPullRequestCommit({
    required this.sha,
    required this.messageHeadline,
    required this.messageBody,
    required this.authorName,
    required this.authorLogin,
    required this.authorAvatarUrl,
    required this.committedAt,
    required this.url,
    required this.verified,
  });

  final String sha;
  final String messageHeadline;
  final String messageBody;
  final String authorName;
  final String authorLogin;
  final String authorAvatarUrl;
  final DateTime? committedAt;
  final String url;
  final bool verified;

  String get shortSha => sha.length <= 7 ? sha : sha.substring(0, 7);

  String get displayAuthor {
    if (authorLogin.isNotEmpty) return authorLogin;
    if (authorName.isNotEmpty) return authorName;
    return 'unknown';
  }

  static GithubPullRequestCommit fromJson(Map<String, Object?> json) {
    final commit = ghMap(json['commit']);
    final message = ghString(commit['message']);
    final author = ghMap(commit['author']);
    final user = ghMap(json['author']);
    return GithubPullRequestCommit(
      sha: ghString(json['sha']),
      messageHeadline: _messageHeadline(message),
      messageBody: _messageBody(message),
      authorName: ghString(author['name']),
      authorLogin: ghString(user['login']),
      authorAvatarUrl: ghString(user['avatar_url']),
      committedAt: ghDate(author['date']),
      url: ghString(json['html_url']),
      verified: ghMap(commit['verification'])['verified'] == true,
    );
  }
}

String _messageHeadline(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return '(no commit message)';
  return trimmed.split(RegExp(r'\r?\n')).first.trim();
}

String _messageBody(String message) {
  final trimmed = message.trim();
  final newline = trimmed.indexOf('\n');
  if (newline < 0 || newline == trimmed.length - 1) return '';
  return trimmed.substring(newline + 1).trim();
}
