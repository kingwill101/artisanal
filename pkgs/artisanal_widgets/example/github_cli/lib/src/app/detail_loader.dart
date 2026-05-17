import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../client/client.dart';
import '../models/display_item.dart';
import '../models/item_kind.dart';
import '../models/pull_request_diff.dart';
import '../state/notifiers.dart';
import 'layout_mode.dart';
import 'messages.dart';

final class GithubDashboardDetailLoader {
  GithubDashboardDetailLoader({
    required this.client,
    required this.data,
    required this.queue,
    required this.detail,
    required this.detailScrollController,
    required this.setLayoutMode,
  });

  final GithubDashboardClient Function() client;
  final GithubDataNotifier data;
  final GithubQueueNotifier queue;
  final GithubDetailNotifier detail;
  final w.WidgetScrollController detailScrollController;
  final tui.Cmd Function(GithubDashboardLayoutMode mode) setLayoutMode;
  var _diffLoadToken = 0;

  bool handlesMessage(tui.Msg msg) {
    return msg is GithubCommentsLoadedMsg ||
        msg is GithubCommentsFailedMsg ||
        msg is GithubCommitsLoadedMsg ||
        msg is GithubCommitsFailedMsg ||
        msg is GithubReviewCommentsLoadedMsg ||
        msg is GithubReviewCommentsFailedMsg ||
        msg is GithubDiffLoadedMsg ||
        msg is GithubDiffChunkLoadedMsg ||
        msg is GithubDiffFinishedMsg ||
        msg is GithubDiffFailedMsg ||
        msg is GithubMergeInfoLoadedMsg ||
        msg is GithubMergeInfoFailedMsg ||
        msg is GithubRepositoryLabelsLoadedMsg ||
        msg is GithubRepositoryLabelsFailedMsg ||
        msg is GithubRunDetailLoadedMsg ||
        msg is GithubRunDetailFailedMsg ||
        msg is GithubSearchLoadedMsg ||
        msg is GithubSearchFailedMsg;
  }

  tui.Cmd? handleMessage(tui.Msg msg) {
    if (msg is GithubCommentsLoadedMsg) {
      detail.applyCommentsLoaded(msg.comments);
      return null;
    }
    if (msg is GithubCommentsFailedMsg) {
      detail.applyCommentsError(msg.message);
      return null;
    }
    if (msg is GithubCommitsLoadedMsg) {
      detail.applyCommitsLoaded(msg.commits);
      return null;
    }
    if (msg is GithubCommitsFailedMsg) {
      detail.applyCommitsError(msg.message);
      return null;
    }
    if (msg is GithubReviewCommentsLoadedMsg) {
      detail.applyReviewCommentsLoaded(msg.comments);
      return null;
    }
    if (msg is GithubReviewCommentsFailedMsg) {
      detail.applyReviewCommentsError(msg.message);
      return null;
    }
    if (msg is GithubDiffLoadedMsg) {
      if (!_isCurrentDiffToken(msg.token)) return null;
      detail.applyDiffLoaded(msg.diff);
      return null;
    }
    if (msg is GithubDiffChunkLoadedMsg) {
      if (!_isCurrentDiffToken(msg.token)) return null;
      detail.applyDiffChunk(msg.chunk);
      return null;
    }
    if (msg is GithubDiffFinishedMsg) {
      if (!_isCurrentDiffToken(msg.token)) return null;
      detail.applyDiffFinished();
      return null;
    }
    if (msg is GithubDiffFailedMsg) {
      if (!_isCurrentDiffToken(msg.token)) return null;
      detail.applyDiffError(msg.message);
      return null;
    }
    if (msg is GithubMergeInfoLoadedMsg) {
      detail.applyMergeInfoLoaded(msg.info);
      return null;
    }
    if (msg is GithubMergeInfoFailedMsg) {
      detail.applyMergeInfoError(msg.message);
      return null;
    }
    if (msg is GithubRepositoryLabelsLoadedMsg) {
      detail.applyRepositoryLabelsLoaded(msg.labels);
      return null;
    }
    if (msg is GithubRepositoryLabelsFailedMsg) {
      detail.applyRepositoryLabelsError(msg.message);
      return null;
    }
    if (msg is GithubRunDetailLoadedMsg) {
      detail.applyRunDetailLoaded(msg.detail);
      return null;
    }
    if (msg is GithubRunDetailFailedMsg) {
      detail.applyRunDetailError(msg.message);
      return null;
    }
    if (msg is GithubSearchLoadedMsg) {
      queue.applySearchResults(msg.query, msg.results, msg.hasMore);
      return null;
    }
    if (msg is GithubSearchFailedMsg) {
      queue.applySearchError(msg.query, msg.message);
      return null;
    }
    return null;
  }

  bool get diffTabActive {
    final item = queue.selectedItem;
    return item != null && _isActiveDetailItem(item, detail.diffItem);
  }

  tui.Cmd openSelectedUrl() {
    final item = queue.selectedItem;
    final url = item?.url ?? data.dashboard?.repository.url;
    if (url == null || url.isEmpty) return tui.Cmd.none();
    return _openUrl(url);
  }

  tui.Cmd _openUrl(String url) {
    return tui.Cmd(() async {
      final executable = io.Platform.isMacOS ? 'open'
          : io.Platform.isWindows ? 'cmd'
          : 'xdg-open';
      final args = io.Platform.isWindows ? ['/c', 'start', '', url] : [url];
      unawaited(
        io.Process.start(executable, args, mode: io.ProcessStartMode.detached),
      );
      return const GithubOpenedUrlMsg();
    });
  }

  tui.Cmd openSelectedDetail() {
    final item = queue.selectedItem;
    if (item == null) return tui.Cmd.none();
    if (item.target == GithubDisplayTarget.workflowRun) {
      return openSelectedRunDetail(focus: true);
    }
    return setLayoutMode(GithubDashboardLayoutMode.focused);
  }

  tui.Cmd openSelectedDiff() {
    final item = queue.selectedItem;
    final repository = data.repositoryFor(item);
    if (item == null ||
        repository == null ||
        item.target != GithubDisplayTarget.pullRequest) {
      return tui.Cmd.none();
    }
    detail.openDiff(item);
    final token = ++_diffLoadToken;
    detailScrollController.jumpTo(0);
    final activeClient = client();
    if (activeClient is GithubPullRequestDiffStreamingClient) {
      final streamingClient =
          activeClient as GithubPullRequestDiffStreamingClient;
      return tui.Cmd.listen<GithubPullRequestDiffChunk>(
        streamingClient.loadPullRequestDiffChunks(
          repository: repository,
          number: item.number,
        ),
        onData: (chunk) => GithubDiffChunkLoadedMsg(chunk, token: token),
        onError: (error, _) =>
            GithubDiffFailedMsg(error.toString(), token: token),
        onDone: () => GithubDiffFinishedMsg(token: token),
      );
    }
    return tui.Cmd(() async {
      try {
        final diff = await activeClient.loadPullRequestDiff(
          repository: repository,
          number: item.number,
        );
        return GithubDiffLoadedMsg(diff, token: token);
      } catch (error) {
        return GithubDiffFailedMsg(error.toString(), token: token);
      }
    });
  }

  bool _isCurrentDiffToken(int? token) {
    return token == null || token == _diffLoadToken;
  }

  tui.Cmd openSelectedRunDetail({bool focus = false}) {
    final item = queue.selectedItem;
    final repository = data.repositoryFor(item);
    final databaseId = item?.workflowRunDatabaseId;
    if (item == null ||
        repository == null ||
        item.target != GithubDisplayTarget.workflowRun ||
        databaseId == null ||
        databaseId == 0) {
      return tui.Cmd.none();
    }
    detail.openRunDetail(item);
    if (focus) setLayoutMode(GithubDashboardLayoutMode.focused);
    detailScrollController.jumpTo(0);
    return tui.Cmd(() async {
      try {
        final runDetail = await client().loadWorkflowRunDetail(
          repository: repository,
          databaseId: databaseId,
        );
        return GithubRunDetailLoadedMsg(runDetail);
      } catch (error) {
        return GithubRunDetailFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd openSelectedComments() {
    final item = queue.selectedItem;
    if (item != null && _isActiveDetailItem(item, detail.commentsItem)) {
      detail.closeComments();
      return tui.Cmd.none();
    }
    final repository = data.repositoryFor(item);
    final kind = _kindFor(item);
    if (item == null || repository == null || kind == null) {
      return tui.Cmd.none();
    }
    detail.openComments(item);
    detailScrollController.jumpTo(0);
    return tui.Cmd(() async {
      try {
        final comments = await client().loadComments(
          repository: repository,
          kind: kind,
          number: item.number,
        );
        return GithubCommentsLoadedMsg(comments);
      } catch (error) {
        return GithubCommentsFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd openSelectedReviewComments() {
    final item = queue.selectedItem;
    final repository = data.repositoryFor(item);
    if (item == null ||
        repository == null ||
        item.target != GithubDisplayTarget.pullRequest) {
      return tui.Cmd.none();
    }
    detail.openReviewComments(item);
    detailScrollController.jumpTo(0);
    return tui.Cmd(() async {
      try {
        final comments = await client().loadPullRequestReviewComments(
          repository: repository,
          number: item.number,
        );
        return GithubReviewCommentsLoadedMsg(comments);
      } catch (error) {
        return GithubReviewCommentsFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd openSelectedCommits() {
    final item = queue.selectedItem;
    final repository = data.repositoryFor(item);
    if (item == null ||
        repository == null ||
        item.target != GithubDisplayTarget.pullRequest) {
      return tui.Cmd.none();
    }
    detail.openCommits(item);
    detailScrollController.jumpTo(0);
    return tui.Cmd(() async {
      try {
        final commits = await client().loadPullRequestCommits(
          repository: repository,
          number: item.number,
        );
        return GithubCommitsLoadedMsg(commits);
      } catch (error) {
        return GithubCommitsFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd openSelectedMergeInfo() {
    final item = queue.selectedItem;
    final repository = data.repositoryFor(item);
    if (item == null ||
        repository == null ||
        item.target != GithubDisplayTarget.pullRequest) {
      return tui.Cmd.none();
    }
    detail.openMergeInfo(item);
    detailScrollController.jumpTo(0);
    return tui.Cmd(() async {
      try {
        final info = await client().loadPullRequestMergeInfo(
          repository: repository,
          number: item.number,
        );
        return GithubMergeInfoLoadedMsg(info);
      } catch (error) {
        return GithubMergeInfoFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd openSelectedRepositoryLabels() {
    final item = queue.selectedItem;
    final repository = data.repositoryFor(item);
    if (item == null || repository == null || !item.supportsIssueActions) {
      return tui.Cmd.none();
    }
    detail.openRepositoryLabels(item);
    detailScrollController.jumpTo(0);
    return tui.Cmd(() async {
      try {
        final labels = await client().loadRepositoryLabels(
          repository: repository,
        );
        return GithubRepositoryLabelsLoadedMsg(item, labels);
      } catch (error) {
        return GithubRepositoryLabelsFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd? changeDetailTab(int index) {
    final item = queue.selectedItem;
    if (item == null) return tui.Cmd.none();
    if (item.target == GithubDisplayTarget.pullRequest) {
      return switch (index) {
        1 => openSelectedCommits(),
        2 => openSelectedReviewComments(),
        3 => openSelectedDiff(),
        _ => openSelectedComments(),
      };
    }
    if (item.target == GithubDisplayTarget.workflowRun) {
      return openSelectedRunDetail();
    }
    if (item.supportsIssueActions) {
      return openSelectedComments();
    }
    return tui.Cmd.none();
  }

  tui.Cmd closeDetail() {
    detail.closeDetail();
    return tui.Cmd.none();
  }

  tui.Cmd closeDiff() {
    detail.closeDiff();
    return tui.Cmd.none();
  }

  tui.Cmd closeRunDetail() {
    detail.closeRunDetail();
    return tui.Cmd.none();
  }

  tui.Cmd closeComments() {
    detail.closeComments();
    return tui.Cmd.none();
  }

  tui.Cmd closeMergeInfo() {
    detail.closeMergeInfo();
    return tui.Cmd.none();
  }

  tui.Cmd closeRepositoryLabels() {
    detail.closeRepositoryLabels();
    return tui.Cmd.none();
  }

  tui.Cmd openSearch() {
    // If search results are already shown, clear instead.
    if (queue.isSearchActive) {
      queue.clearSearch();
      return tui.Cmd.none();
    }
    detail.openSearch();
    return tui.Cmd.none();
  }

  tui.Cmd closeSearch() {
    detail.closeSearch();
    return tui.Cmd.none();
  }

  tui.Cmd submitSearch(String query) {
    detail.closeSearch();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return tui.Cmd.none();
    final dashboard = data.dashboard;
    if (dashboard == null) return tui.Cmd.none();
    final scope = dashboard.resolvedScope;
    queue.openSearch(trimmed);
    detailScrollController.jumpTo(0);
    return tui.Cmd(() async {
      try {
        final result = await client().searchIssuesAndPrs(
          scope: scope,
          query: trimmed,
          limit: 20,
          page: 1,
        );
        return GithubSearchLoadedMsg(trimmed, result.bucket, result.hasMore);
      } catch (error) {
        return GithubSearchFailedMsg(trimmed, error.toString());
      }
    });
  }

  tui.Cmd loadNextSearchPage() {
    final trimmed = queue.searchQuery;
    if (trimmed == null || trimmed.isEmpty) return tui.Cmd.none();
    final dashboard = data.dashboard;
    if (dashboard == null) return tui.Cmd.none();
    final scope = dashboard.resolvedScope;
    if (!queue.searchHasMore || queue.searchPageLoading) return tui.Cmd.none();
    queue.startSearchNextPage();
    return tui.Cmd(() async {
      try {
        final result = await client().searchIssuesAndPrs(
          scope: scope,
          query: trimmed,
          limit: 20,
          page: queue.searchPage,
        );
        return GithubSearchLoadedMsg(trimmed, result.bucket, result.hasMore);
      } catch (error) {
        return GithubSearchFailedMsg(trimmed, error.toString());
      }
    });
  }

  GithubItemKind? _kindFor(GithubDisplayItem? item) {
    if (item == null) return null;
    return switch (item.target) {
      GithubDisplayTarget.issue => GithubItemKind.issue,
      GithubDisplayTarget.pullRequest => GithubItemKind.pullRequest,
      GithubDisplayTarget.workflowRun => null,
    };
  }

  bool _isActiveDetailItem(GithubDisplayItem item, GithubDisplayItem? detail) {
    return detail != null &&
        detail.target == item.target &&
        detail.number == item.number &&
        (item.repository.isEmpty ||
            detail.repository.isEmpty ||
            item.repository == detail.repository);
  }
}
