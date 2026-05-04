final class GithubPullRequestTarget {
  const GithubPullRequestTarget({
    required this.repository,
    required this.number,
  });

  final String repository;
  final int number;

  String get url => 'https://github.com/$repository/pull/$number';
}

GithubPullRequestTarget? parseGithubPullRequestTarget(String? input) {
  final raw = input?.trim();
  if (raw == null || raw.isEmpty) return null;

  final shorthand = RegExp(
    r'^([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)#(\d+)$',
  ).firstMatch(raw);
  if (shorthand != null) {
    return _target(shorthand.group(1), shorthand.group(2));
  }

  final path = _githubPath(raw);
  final segments = path
      .split('/')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.length != 4) return null;
  if (segments[2] != 'pull' && segments[2] != 'pulls' && segments[2] != 'pr') {
    return null;
  }
  return _target('${segments[0]}/${segments[1]}', segments[3]);
}

String _githubPath(String raw) {
  if (raw.startsWith('github.com/')) {
    return raw.substring('github.com/'.length);
  }
  if (raw.startsWith('www.github.com/')) {
    return raw.substring('www.github.com/'.length);
  }
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme) return raw;
  if (uri.scheme != 'https' && uri.scheme != 'http') return raw;
  if (uri.host != 'github.com' && uri.host != 'www.github.com') return raw;
  return uri.path;
}

GithubPullRequestTarget? _target(String? repository, String? numberText) {
  final number = int.tryParse((numberText ?? '').replaceFirst('#', ''));
  if (repository == null || number == null || number <= 0) return null;
  return GithubPullRequestTarget(repository: repository, number: number);
}
