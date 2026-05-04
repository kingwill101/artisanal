import '../client/json.dart';

final class GithubRepositorySummary {
  const GithubRepositorySummary({
    required this.nameWithOwner,
    required this.description,
    required this.url,
    required this.defaultBranch,
    required this.stars,
    required this.forks,
    required this.isPrivate,
    required this.viewerPermission,
    required this.primaryLanguage,
    required this.latestRelease,
    this.updatedAt,
  });

  final String nameWithOwner;
  final String description;
  final String url;
  final String defaultBranch;
  final int stars;
  final int forks;
  final bool isPrivate;
  final String viewerPermission;
  final String primaryLanguage;
  final String latestRelease;
  final DateTime? updatedAt;

  static GithubRepositorySummary fromJson(Map<String, Object?> json) {
    return GithubRepositorySummary(
      nameWithOwner: ghString(json['nameWithOwner'], fallback: 'unknown/repo'),
      description: ghString(json['description']),
      url: ghString(json['url']),
      defaultBranch: ghString(ghMap(json['defaultBranchRef'])['name']),
      stars: ghInt(json['stargazerCount']),
      forks: ghInt(json['forkCount']),
      isPrivate: json['isPrivate'] == true,
      viewerPermission: ghString(json['viewerPermission'], fallback: 'UNKNOWN'),
      primaryLanguage: ghString(ghMap(json['primaryLanguage'])['name']),
      latestRelease: ghString(ghMap(json['latestRelease'])['tagName']),
      updatedAt: ghDate(json['updatedAt']),
    );
  }
}
