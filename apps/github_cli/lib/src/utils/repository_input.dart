String? normalizeGithubRepositoryInput(String? input) {
  final target = parseGithubDashboardTarget(input);
  return target?.repository;
}

final class GithubDashboardTarget {
  const GithubDashboardTarget.repository(this.repository) : owner = null;
  const GithubDashboardTarget.owner(this.owner) : repository = null;

  final String? repository;
  final String? owner;

  bool get isRepository => repository != null;
}

GithubDashboardTarget? parseGithubDashboardTarget(String? input) {
  var value = input?.trim() ?? '';
  if (value.isEmpty) return null;

  if (value.startsWith('git@github.com:')) {
    value = value.substring('git@github.com:'.length);
    final repository = _repoFromPath(value);
    return repository == null
        ? null
        : GithubDashboardTarget.repository(repository);
  }

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || host != 'github.com') {
      return null;
    }
    return _targetFromParts(uri.pathSegments);
  }

  if (value.startsWith('github.com/')) {
    value = value.substring('github.com/'.length);
  }
  return _targetFromPath(value);
}

String? _repoFromPath(String path) {
  return _repoFromParts(path.split('/'));
}

GithubDashboardTarget? _targetFromPath(String path) {
  return _targetFromParts(path.split('/'));
}

GithubDashboardTarget? _targetFromParts(List<String> parts) {
  final clean = _cleanParts(parts);
  if (clean.isEmpty) return null;
  if (clean.length == 1) {
    final owner = clean.single;
    return _validOwner(owner) ? GithubDashboardTarget.owner(owner) : null;
  }
  final repository = _repoFromParts(clean);
  return repository == null
      ? null
      : GithubDashboardTarget.repository(repository);
}

String? _repoFromParts(List<String> parts) {
  final clean = _cleanParts(parts);
  if (clean.length < 2) return null;

  final owner = clean[0];
  final repo = clean[1].endsWith('.git')
      ? clean[1].substring(0, clean[1].length - 4)
      : clean[1];
  if (!_validSegment(owner) || !_validSegment(repo)) return null;
  return '$owner/$repo';
}

List<String> _cleanParts(List<String> parts) {
  return parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

bool _validOwner(String value) {
  return value == '@me' || _validSegment(value);
}

bool _validSegment(String value) {
  if (value.isEmpty || value.contains(RegExp(r'\s'))) return false;
  return !value.contains(':');
}
