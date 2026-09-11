import 'check_summary.dart';
import '../client/json.dart';

enum GithubPullRequestMergeAction {
  merge(['--merge', '--delete-branch'], 'Merged'),
  squash(['--squash', '--delete-branch'], 'Merged'),
  rebase(['--rebase', '--delete-branch'], 'Merged'),
  autoMerge(['--merge', '--auto', '--delete-branch'], 'Enabled auto-merge'),
  autoSquash(['--squash', '--auto', '--delete-branch'], 'Enabled auto-merge'),
  autoRebase(['--rebase', '--auto', '--delete-branch'], 'Enabled auto-merge'),
  disableAuto(['--disable-auto'], 'Disabled auto-merge'),
  adminMerge(['--merge', '--admin', '--delete-branch'], 'Admin merged'),
  adminSquash(['--squash', '--admin', '--delete-branch'], 'Admin merged'),
  adminRebase(['--rebase', '--admin', '--delete-branch'], 'Admin merged');

  const GithubPullRequestMergeAction(this.cliArgs, this.pastTense);

  final List<String> cliArgs;
  final String pastTense;

  String get title {
    return switch (this) {
      GithubPullRequestMergeAction.merge => 'Merge commit',
      GithubPullRequestMergeAction.squash => 'Squash and merge',
      GithubPullRequestMergeAction.rebase => 'Rebase and merge',
      GithubPullRequestMergeAction.autoMerge => 'Enable auto-merge',
      GithubPullRequestMergeAction.autoSquash => 'Enable auto-squash',
      GithubPullRequestMergeAction.autoRebase => 'Enable auto-rebase',
      GithubPullRequestMergeAction.disableAuto => 'Disable auto-merge',
      GithubPullRequestMergeAction.adminMerge => 'Admin merge',
      GithubPullRequestMergeAction.adminSquash => 'Admin squash',
      GithubPullRequestMergeAction.adminRebase => 'Admin rebase',
    };
  }

  String get description {
    return switch (this) {
      GithubPullRequestMergeAction.merge =>
        'Create a merge commit and delete the branch.',
      GithubPullRequestMergeAction.squash =>
        'Squash commits, merge, and delete the branch.',
      GithubPullRequestMergeAction.rebase =>
        'Rebase commits, merge, and delete the branch.',
      GithubPullRequestMergeAction.autoMerge =>
        'Merge automatically when requirements pass.',
      GithubPullRequestMergeAction.autoSquash =>
        'Squash automatically when requirements pass.',
      GithubPullRequestMergeAction.autoRebase =>
        'Rebase automatically when requirements pass.',
      GithubPullRequestMergeAction.disableAuto =>
        'Turn off auto-merge for this pull request.',
      GithubPullRequestMergeAction.adminMerge =>
        'Bypass requirements with an admin merge commit.',
      GithubPullRequestMergeAction.adminSquash =>
        'Bypass requirements with an admin squash merge.',
      GithubPullRequestMergeAction.adminRebase =>
        'Bypass requirements with an admin rebase merge.',
    };
  }

  bool get isDangerous {
    return switch (this) {
      GithubPullRequestMergeAction.adminMerge ||
      GithubPullRequestMergeAction.adminSquash ||
      GithubPullRequestMergeAction.adminRebase => true,
      _ => false,
    };
  }

  static GithubPullRequestMergeAction? parse(String input) {
    final normalized = input.trim().toLowerCase().replaceAll('_', '-');
    return switch (normalized) {
      'merge' => GithubPullRequestMergeAction.merge,
      'squash' => GithubPullRequestMergeAction.squash,
      'rebase' => GithubPullRequestMergeAction.rebase,
      'auto-merge' || 'auto' => GithubPullRequestMergeAction.autoMerge,
      'auto-squash' => GithubPullRequestMergeAction.autoSquash,
      'auto-rebase' => GithubPullRequestMergeAction.autoRebase,
      'disable-auto' ||
      'disable auto' => GithubPullRequestMergeAction.disableAuto,
      'admin-merge' => GithubPullRequestMergeAction.adminMerge,
      'admin-squash' => GithubPullRequestMergeAction.adminSquash,
      'admin-rebase' => GithubPullRequestMergeAction.adminRebase,
      _ => null,
    };
  }
}

final class GithubPullRequestMergeInfo {
  const GithubPullRequestMergeInfo({
    required this.number,
    required this.title,
    required this.state,
    required this.isDraft,
    required this.mergeable,
    required this.reviewDecision,
    required this.autoMergeEnabled,
    this.viewerCanMergeAsAdmin,
    this.mergeCommitAllowed,
    this.squashMergeAllowed,
    this.rebaseMergeAllowed,
    required this.checks,
  });

  final int number;
  final String title;
  final String state;
  final bool isDraft;
  final String mergeable;
  final String reviewDecision;
  final bool autoMergeEnabled;
  final bool? viewerCanMergeAsAdmin;
  final bool? mergeCommitAllowed;
  final bool? squashMergeAllowed;
  final bool? rebaseMergeAllowed;
  final GithubCheckSummary checks;

  bool get isOpen => state.toLowerCase() == 'open';

  bool get isCleanlyMergeable {
    final review = reviewDecision.toUpperCase();
    return isOpen &&
        !isDraft &&
        mergeable.toUpperCase() == 'MERGEABLE' &&
        review != 'CHANGES_REQUESTED' &&
        review != 'REVIEW_REQUIRED' &&
        !checks.hasFailures &&
        checks.pending == 0;
  }

  List<String> get allowedMethods {
    return [
      if (mergeCommitAllowed != false) 'merge',
      if (squashMergeAllowed != false) 'squash',
      if (rebaseMergeAllowed != false) 'rebase',
    ];
  }

  bool get mergeMethodPolicyKnown {
    return mergeCommitAllowed != null ||
        squashMergeAllowed != null ||
        rebaseMergeAllowed != null;
  }

  List<GithubPullRequestMergeAction> get availableActions {
    final actions = <GithubPullRequestMergeAction>[];
    if (isCleanlyMergeable && mergeCommitAllowed != false) {
      actions.add(GithubPullRequestMergeAction.merge);
    }
    if (isCleanlyMergeable && squashMergeAllowed != false) {
      actions.add(GithubPullRequestMergeAction.squash);
    }
    if (isCleanlyMergeable && rebaseMergeAllowed != false) {
      actions.add(GithubPullRequestMergeAction.rebase);
    }
    if (isOpen && !autoMergeEnabled && !isDraft && mergeable != 'CONFLICTING') {
      if (mergeCommitAllowed != false) {
        actions.add(GithubPullRequestMergeAction.autoMerge);
      }
      if (squashMergeAllowed != false) {
        actions.add(GithubPullRequestMergeAction.autoSquash);
      }
      if (rebaseMergeAllowed != false) {
        actions.add(GithubPullRequestMergeAction.autoRebase);
      }
    }
    if (isOpen && autoMergeEnabled) {
      actions.add(GithubPullRequestMergeAction.disableAuto);
    }
    if (viewerCanMergeAsAdmin == true &&
        isOpen &&
        !isDraft &&
        mergeable != 'CONFLICTING') {
      if (mergeCommitAllowed != false) {
        actions.add(GithubPullRequestMergeAction.adminMerge);
      }
      if (squashMergeAllowed != false) {
        actions.add(GithubPullRequestMergeAction.adminSquash);
      }
      if (rebaseMergeAllowed != false) {
        actions.add(GithubPullRequestMergeAction.adminRebase);
      }
    }
    return actions;
  }

  static GithubPullRequestMergeInfo fromJson(Map<String, Object?> json) {
    return GithubPullRequestMergeInfo(
      number: ghInt(json['number']),
      title: ghString(json['title']),
      state: ghString(json['state'], fallback: 'UNKNOWN'),
      isDraft: json['isDraft'] == true,
      mergeable: ghString(json['mergeable'], fallback: 'UNKNOWN'),
      reviewDecision: ghString(json['reviewDecision'], fallback: 'PENDING'),
      autoMergeEnabled: json['autoMergeRequest'] != null,
      viewerCanMergeAsAdmin: _optionalBool(json['viewerCanMergeAsAdmin']),
      mergeCommitAllowed: _optionalBool(json['mergeCommitAllowed']),
      squashMergeAllowed: _optionalBool(json['squashMergeAllowed']),
      rebaseMergeAllowed: _optionalBool(json['rebaseMergeAllowed']),
      checks: GithubCheckSummary.fromJson(json['statusCheckRollup']),
    );
  }

  static bool? _optionalBool(Object? value) {
    return value is bool ? value : null;
  }
}
