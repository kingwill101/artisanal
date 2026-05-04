import 'package:artisanal/tui.dart' as tui;

import '../models/dashboard_data.dart';
import '../models/display_item.dart';

final class GithubDashboardLoadedMsg extends tui.Msg {
  const GithubDashboardLoadedMsg(this.dashboard);

  final GithubDashboardData dashboard;
}

final class GithubDashboardFailedMsg extends tui.Msg {
  const GithubDashboardFailedMsg(this.message);

  final String message;
}

final class GithubOverviewLoadedMsg extends tui.Msg {
  const GithubOverviewLoadedMsg(this.filter, this.bucket);

  final GithubOverviewFilter filter;
  final GithubOverviewBucket bucket;
}

final class GithubOverviewFailedMsg extends tui.Msg {
  const GithubOverviewFailedMsg(this.filter, this.message);

  final GithubOverviewFilter filter;
  final String message;
}

final class GithubIssuesPageLoadedMsg extends tui.Msg {
  const GithubIssuesPageLoadedMsg(this.page, {required this.replace});

  final GithubPage<GithubIssueItem> page;
  final bool replace;
}

final class GithubPullRequestsPageLoadedMsg extends tui.Msg {
  const GithubPullRequestsPageLoadedMsg(this.page, {required this.replace});

  final GithubPage<GithubPullRequestItem> page;
  final bool replace;
}

final class GithubPullRequestLoadedMsg extends tui.Msg {
  const GithubPullRequestLoadedMsg(this.pullRequest);

  final GithubPullRequestItem pullRequest;
}

final class GithubPullRequestFailedMsg extends tui.Msg {
  const GithubPullRequestFailedMsg(this.message);

  final String message;
}

final class GithubWorkflowRunsPageLoadedMsg extends tui.Msg {
  const GithubWorkflowRunsPageLoadedMsg(this.page, {required this.replace});

  final GithubPage<GithubWorkflowRunItem> page;
  final bool replace;
}

final class GithubPageFailedMsg extends tui.Msg {
  const GithubPageFailedMsg(this.tabIndex, this.message);

  final int tabIndex;
  final String message;
}

final class GithubOpenedUrlMsg extends tui.Msg {
  const GithubOpenedUrlMsg();
}

final class GithubCommentsLoadedMsg extends tui.Msg {
  const GithubCommentsLoadedMsg(this.comments);

  final List<GithubCommentItem> comments;
}

final class GithubCommentsFailedMsg extends tui.Msg {
  const GithubCommentsFailedMsg(this.message);

  final String message;
}

final class GithubReviewCommentsLoadedMsg extends tui.Msg {
  const GithubReviewCommentsLoadedMsg(this.comments);

  final List<GithubPullRequestReviewComment> comments;
}

final class GithubReviewCommentsFailedMsg extends tui.Msg {
  const GithubReviewCommentsFailedMsg(this.message);

  final String message;
}

final class GithubCommitsLoadedMsg extends tui.Msg {
  const GithubCommitsLoadedMsg(this.commits);

  final List<GithubPullRequestCommit> commits;
}

final class GithubCommitsFailedMsg extends tui.Msg {
  const GithubCommitsFailedMsg(this.message);

  final String message;
}

final class GithubDiffLoadedMsg extends tui.Msg {
  const GithubDiffLoadedMsg(this.diff, {this.token});

  final String diff;
  final int? token;
}

final class GithubDiffChunkLoadedMsg extends tui.Msg {
  const GithubDiffChunkLoadedMsg(this.chunk, {required this.token});

  final GithubPullRequestDiffChunk chunk;
  final int token;
}

final class GithubDiffFinishedMsg extends tui.Msg {
  const GithubDiffFinishedMsg({required this.token});

  final int token;
}

final class GithubDiffFailedMsg extends tui.Msg {
  const GithubDiffFailedMsg(this.message, {this.token});

  final String message;
  final int? token;
}

final class GithubMergeInfoLoadedMsg extends tui.Msg {
  const GithubMergeInfoLoadedMsg(this.info);

  final GithubPullRequestMergeInfo info;
}

final class GithubMergeInfoFailedMsg extends tui.Msg {
  const GithubMergeInfoFailedMsg(this.message);

  final String message;
}

final class GithubRepositoryLabelsLoadedMsg extends tui.Msg {
  const GithubRepositoryLabelsLoadedMsg(this.item, this.labels);

  final GithubDisplayItem item;
  final List<GithubRepositoryLabel> labels;
}

final class GithubRepositoryLabelsFailedMsg extends tui.Msg {
  const GithubRepositoryLabelsFailedMsg(this.message);

  final String message;
}

final class GithubRunDetailLoadedMsg extends tui.Msg {
  const GithubRunDetailLoadedMsg(this.detail);

  final GithubWorkflowRunDetail detail;
}

final class GithubRunDetailFailedMsg extends tui.Msg {
  const GithubRunDetailFailedMsg(this.message);

  final String message;
}

final class GithubActionCompletedMsg extends tui.Msg {
  const GithubActionCompletedMsg(this.message);

  final String message;
}

final class GithubActionFailedMsg extends tui.Msg {
  const GithubActionFailedMsg(this.message);

  final String message;
}
