import '../client/json.dart';
import 'repository_label.dart';

final class GithubIssueItem {
  const GithubIssueItem({
    required this.number,
    required this.title,
    required this.body,
    required this.url,
    required this.author,
    required this.labels,
    required this.assignees,
    required this.commentCount,
    required this.updatedAt,
    this.repository = '',
    this.authorAvatarUrl = '',
    this.labelDetails = const <GithubRepositoryLabel>[],
  });

  final int number;
  final String title;
  final String body;
  final String url;
  final String repository;
  final String author;
  final String authorAvatarUrl;
  final List<String> labels;
  final List<GithubRepositoryLabel> labelDetails;
  final List<String> assignees;
  final int commentCount;
  final DateTime? updatedAt;

  static GithubIssueItem fromJson(Map<String, Object?> json) {
    final labelDetails = _labelsFromJson(json['labels']);
    return GithubIssueItem(
      number: ghInt(json['number']),
      title: ghString(json['title']),
      body: ghString(json['body']),
      url: ghString(json['url']),
      repository: ghString(ghMap(json['repository'])['nameWithOwner']),
      author: ghString(ghMap(json['author'])['login'], fallback: 'unknown'),
      authorAvatarUrl: ghString(ghMap(json['author'])['avatarUrl']),
      labels: labelDetails.isEmpty
          ? ghNames(json['labels'])
          : labelDetails.map((label) => label.name).toList(growable: false),
      labelDetails: labelDetails,
      assignees: ghNames(json['assignees']),
      commentCount: json.containsKey('commentsCount')
          ? ghInt(json['commentsCount'])
          : ghCount(json['comments']),
      updatedAt: ghDate(json['updatedAt']),
    );
  }
}

List<GithubRepositoryLabel> _labelsFromJson(Object? value) {
  return ghList(value)
      .map((item) => GithubRepositoryLabel.fromJson(ghMap(item)))
      .where((label) => label.name.isNotEmpty)
      .toList(growable: false);
}
