import 'check_summary.dart';
import '../client/json.dart';
import 'repository_label.dart';

final class GithubPullRequestItem {
  const GithubPullRequestItem({
    required this.number,
    required this.title,
    required this.body,
    required this.url,
    required this.author,
    required this.labels,
    required this.commentCount,
    required this.updatedAt,
    required this.reviewDecision,
    required this.isDraft,
    required this.checks,
    this.repository = '',
    this.authorAvatarUrl = '',
    this.headRefOid = '',
    this.labelDetails = const <GithubRepositoryLabel>[],
    this.additions = 0,
    this.deletions = 0,
    this.changedFiles = 0,
    this.commitCount = 0,
  });

  final int number;
  final String title;
  final String body;
  final String url;
  final String repository;
  final String author;
  final String authorAvatarUrl;
  final String headRefOid;
  final List<String> labels;
  final List<GithubRepositoryLabel> labelDetails;
  final int commentCount;
  final DateTime? updatedAt;
  final String reviewDecision;
  final bool isDraft;
  final GithubCheckSummary checks;
  final int additions;
  final int deletions;
  final int changedFiles;
  final int commitCount;

  static GithubPullRequestItem fromJson(Map<String, Object?> json) {
    final labelDetails = _labelsFromJson(json['labels']);
    return GithubPullRequestItem(
      number: ghInt(json['number']),
      title: ghString(json['title']),
      body: ghString(json['body']),
      url: ghString(json['url']),
      repository: ghString(ghMap(json['repository'])['nameWithOwner']),
      author: ghString(ghMap(json['author'])['login'], fallback: 'unknown'),
      authorAvatarUrl: ghString(ghMap(json['author'])['avatarUrl']),
      headRefOid: ghString(json['headRefOid']),
      labels: labelDetails.isEmpty
          ? ghNames(json['labels'])
          : labelDetails.map((label) => label.name).toList(growable: false),
      labelDetails: labelDetails,
      commentCount: json.containsKey('commentsCount')
          ? ghInt(json['commentsCount'])
          : ghCount(json['comments']),
      updatedAt: ghDate(json['updatedAt']),
      reviewDecision: ghString(json['reviewDecision'], fallback: 'PENDING'),
      isDraft: json['isDraft'] == true,
      checks: GithubCheckSummary.fromJson(json['statusCheckRollup']),
      additions: ghInt(json['additions']),
      deletions: ghInt(json['deletions']),
      changedFiles: ghInt(json['changedFiles']),
      commitCount: ghCount(json['commits']),
    );
  }
}

List<GithubRepositoryLabel> _labelsFromJson(Object? value) {
  return ghList(value)
      .map((item) => GithubRepositoryLabel.fromJson(ghMap(item)))
      .where((label) => label.name.isNotEmpty)
      .toList(growable: false);
}
