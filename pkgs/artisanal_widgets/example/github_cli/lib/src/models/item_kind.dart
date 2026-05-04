enum GithubItemKind {
  issue,
  pullRequest;

  String get ghCommand {
    return switch (this) {
      GithubItemKind.issue => 'issue',
      GithubItemKind.pullRequest => 'pr',
    };
  }

  String get label {
    return switch (this) {
      GithubItemKind.issue => 'issue',
      GithubItemKind.pullRequest => 'pull request',
    };
  }
}
