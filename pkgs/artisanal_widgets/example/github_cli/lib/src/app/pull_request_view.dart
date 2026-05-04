import 'package:artisanal/style.dart'
    show Colors, HorizontalAlign, VerticalAlign;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../client/client.dart';
import '../models/action_prompt.dart';
import '../models/dashboard_data.dart';
import '../models/display_item.dart';
import '../state/notifiers.dart';
import '../ui/dashboard/detail_pane.dart';
import '../ui/dashboard/modal_stack.dart';
import '../utils/pull_request_input.dart';
import 'action_coordinator.dart';
import 'command_items.dart';
import 'detail_loader.dart';
import 'diff_interaction_state.dart';
import 'layout_mode.dart';
import 'messages.dart';
import 'theme.dart';
import 'ui_state.dart';

final class GithubPullRequestView extends w.StatefulWidget {
  GithubPullRequestView({
    required this.client,
    required this.target,
    super.key,
  });

  final GithubDashboardClient client;
  final GithubPullRequestTarget target;

  @override
  w.State<GithubPullRequestView> createState() => _GithubPullRequestViewState();
}

final class _GithubPullRequestViewState extends w.State<GithubPullRequestView> {
  final _scrollController = w.WidgetScrollController();

  late final GithubDataNotifier _data;
  late final GithubQueueNotifier _queue;
  late final GithubDetailNotifier _detail;
  late final GithubDashboardUiState _uiState;
  late final GithubDashboardDetailLoader _detailLoader;
  late final GithubDashboardActionCoordinator _actions;
  late final GithubDashboardCommandItems _commandItems;

  bool _pullRequestLoading = true;
  String? _pullRequestError;

  final _diffController = w.GitDiffController();
  final _diffInteraction = GithubDiffInteractionState();

  @override
  void initState() {
    super.initState();
    _data = GithubDataNotifier()..setRepository(widget.target.repository);
    _queue = GithubQueueNotifier(tabIndex: 2);
    _detail = GithubDetailNotifier();
    _uiState = GithubDashboardUiState()
      ..layoutMode = GithubDashboardLayoutMode.focused;
    _detailLoader = GithubDashboardDetailLoader(
      client: () => widget.client,
      data: _data,
      queue: _queue,
      detail: _detail,
      detailScrollController: _scrollController,
      setLayoutMode: (_) => tui.Cmd.none(),
    );
    _actions = GithubDashboardActionCoordinator(
      client: () => widget.client,
      data: _data,
      queue: _queue,
      detail: _detail,
      loadDashboard: _reload,
    );
    _commandItems = GithubDashboardCommandItems(
      uiState: _uiState,
      queue: _queue,
      data: _data,
      paletteAction: _paletteAction,
      openRepositoryPrompt: () => tui.Cmd.none(),
      openRepositoryList: () => tui.Cmd.none(),
      loadDashboard: _reload,
      loadCurrentPage: ({required bool replace}) => tui.Cmd.none(),
      openSelectedUrl: _detailLoader.openSelectedUrl,
      toggleFocusedView: () => tui.Cmd.none(),
      cycleTheme: _cycleTheme,
      switchTab: _switchDetailShortcut,
      openSelectedDetail: () => tui.Cmd.none(),
      openSelectedComments: _detailLoader.openSelectedComments,
      openSelectedCommits: _detailLoader.openSelectedCommits,
      openSelectedReviewComments: _detailLoader.openSelectedReviewComments,
      openSelectedDiff: _detailLoader.openSelectedDiff,
      openSelectedMergeInfo: _detailLoader.openSelectedMergeInfo,
      openSelectedRunDetail: _detailLoader.openSelectedRunDetail,
      openSelectedRepositoryLabels: _detailLoader.openSelectedRepositoryLabels,
      openActionPrompt: _actions.openActionPrompt,
      toggleSelectedPullRequestDraft: _actions.toggleSelectedPullRequestDraft,
    );
  }

  @override
  void dispose() {
    _queue.dispose();
    _data.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  tui.Cmd? handleInit() => _reload(notify: false);

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is GithubPullRequestLoadedMsg) {
      final dashboard = _dashboardFor(msg.pullRequest);
      setState(() {
        _pullRequestLoading = false;
        _pullRequestError = null;
      });
      _data.applyLoaded(dashboard);
      _queue.batchApply(
        dashboard: () => dashboard,
        resetSelection: true,
        pageStatus: _data.pageStatusForTab(_queue.tabIndex),
      );
      return _detailLoader.openSelectedComments();
    }
    if (msg is GithubPullRequestFailedMsg) {
      setState(() {
        _pullRequestLoading = false;
        _pullRequestError = msg.message;
      });
      _data.applyError(msg.message);
      return null;
    }
    if (_detailLoader.handlesMessage(msg)) {
      return _detailLoader.handleMessage(msg);
    }
    if (_actions.handlesMessage(msg)) {
      return _actions.handleMessage(msg);
    }
    if (msg is GithubOpenedUrlMsg) return null;
    if (msg is! tui.KeyMsg) return null;
    return _handleKey(msg);
  }

  tui.Cmd? _handleKey(tui.KeyMsg msg) {
    final key = msg.key;
    if (_modalOpen) return null;
    if (_detailLoader.diffTabActive) {
      final command = _handleDiffKey(msg);
      if (command != null) return command;
    }
    if (key.isChar('q')) return tui.Cmd.quit();
    if (key.isChar('r')) return _reload();
    if (key.isChar('o')) return _detailLoader.openSelectedUrl();
    if (key.isChar('p')) return _openCommandPalette();
    if (key.isChar('t')) return _cycleTheme();
    if (key.isChar('c')) return _detailLoader.openSelectedComments();
    if (key.isChar('v')) return _detailLoader.openSelectedReviewComments();
    if (key.isChar('d')) return _detailLoader.openSelectedDiff();
    if (key.isChar('m')) return _detailLoader.openSelectedMergeInfo();
    if (key.isChar('b') || key.isChar('l')) {
      return _detailLoader.openSelectedRepositoryLabels();
    }
    if (key.isChar('a')) {
      return _actions.openActionPrompt(GithubActionPromptKind.addComment);
    }
    if (key.isChar('x')) {
      return _actions.openActionPrompt(GithubActionPromptKind.removeLabels);
    }
    if (key.type == tui.KeyType.tab || key.type == tui.KeyType.right) {
      return _cycleDetailTab(1);
    }
    if (key.type == tui.KeyType.left) {
      return _cycleDetailTab(-1);
    }
    if (key.isChar('j') || key.type == tui.KeyType.down) {
      return _scrollDetailBy(1);
    }
    if (key.isChar('k') || key.type == tui.KeyType.up) {
      return _scrollDetailBy(-1);
    }
    if (key.type == tui.KeyType.pageDown ||
        key.isChar('d', requireNoModifiers: false) && key.ctrl) {
      return _scrollDetailBy(_pageStep);
    }
    if (key.type == tui.KeyType.pageUp ||
        key.isChar('u', requireNoModifiers: false) && key.ctrl) {
      return _scrollDetailBy(-_pageStep);
    }
    return null;
  }

  tui.Cmd? _handleDiffKey(tui.KeyMsg msg) {
    final key = msg.key;
    if (key.isChar('a') || key.type == tui.KeyType.enter) {
      return _openDiffCommentPrompt();
    }
    if (key.isChar('v')) {
      setState(() {
        _ensureDiffSelection();
        _diffInteraction.toggleRange(_diffController.commentAnchors);
      });
      return tui.Cmd.none();
    }
    if (key.isChar('s')) {
      setState(() {
        final modes = w.DiffViewMode.values;
        _uiState.diffViewMode =
            modes[(_uiState.diffViewMode.index + 1) % modes.length];
      });
      return tui.Cmd.none();
    }
    if (key.isChar(']')) {
      return _moveDiffFile(1);
    }
    if (key.isChar('[')) {
      return _moveDiffFile(-1);
    }
    if (key.isChar('j') || key.type == tui.KeyType.down) {
      return _moveDiffAnchor(1);
    }
    if (key.isChar('k') || key.type == tui.KeyType.up) {
      return _moveDiffAnchor(-1);
    }
    if (key.type == tui.KeyType.pageDown ||
        key.isChar('d', requireNoModifiers: false) && key.ctrl) {
      return _scrollDiffViewport(_pageStep);
    }
    if (key.type == tui.KeyType.pageUp ||
        key.isChar('u', requireNoModifiers: false) && key.ctrl) {
      return _scrollDiffViewport(-_pageStep);
    }
    if (key.isChar('h')) {
      return _selectDiffSide(w.DiffCommentSide.left);
    }
    if (key.isChar('l')) {
      return _selectDiffSide(w.DiffCommentSide.right);
    }
    if (key.type == tui.KeyType.escape && _diffInteraction.rangeActive) {
      setState(() => _diffInteraction.rangeStartAnchorIndex = null);
      return tui.Cmd.none();
    }
    return null;
  }

  tui.Cmd _reload({bool clearDashboard = false, bool notify = true}) {
    void apply() {
      _pullRequestLoading = true;
      _pullRequestError = null;
      _data.setRepository(widget.target.repository);
      _data.startLoading(clearDashboard: true);
      _queue.batchApply(
        dashboard: () => null,
        resetSelection: true,
        pageStatus: _data.pageStatusForTab(_queue.tabIndex),
      );
      _detail.closeAllInlineDetails();
      _diffInteraction.reset();
      _uiState.diffViewMode = w.DiffViewMode.unified;
      _uiState.commandPaletteOpen = false;
      _scrollController.jumpTo(0);
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
    return _loadPullRequest();
  }

  tui.Cmd _loadPullRequest() {
    return tui.Cmd(() async {
      try {
        return GithubPullRequestLoadedMsg(
          await widget.client.loadPullRequest(
            repository: widget.target.repository,
            number: widget.target.number,
          ),
        );
      } catch (error) {
        return GithubPullRequestFailedMsg(error.toString());
      }
    });
  }

  tui.Cmd? _changeDetailTab(int index) => _detailLoader.changeDetailTab(index);

  tui.Cmd _openDiffCommentPrompt() {
    final target = _currentDiffCommentTarget();
    return _actions.openDiffCommentPrompt(target);
  }

  GithubDiffCommentTarget? _currentDiffCommentTarget() {
    if (_detail.diff.trim().isEmpty) return null;
    final anchors = _diffController.commentAnchors;
    _ensureDiffSelection();
    return _diffInteraction.targetFor(anchors);
  }

  tui.Cmd _moveDiffAnchor(int delta) {
    setState(() {
      final anchors = _diffController.commentAnchors;
      _ensureDiffSelection();
      _diffInteraction.moveSelection(anchors, delta);
      _revealDiffAnchor(_diffInteraction.selectedAnchor(anchors));
    });
    return tui.Cmd.none();
  }

  void _ensureDiffSelection() {
    if (_diffInteraction.hasSelection) return;
    final renderLine = _scrollController.offset;
    final anchor =
        _diffController.commentAnchorAt(renderLine) ??
        _diffController.nearestCommentAnchor(renderLine);
    if (anchor != null) {
      _diffInteraction.selectAnchor(_diffController.commentAnchors, anchor);
    }
  }

  tui.Cmd _selectDiffSide(w.DiffCommentSide side) {
    setState(() {
      _diffInteraction.selectSide(_diffController.commentAnchors, side);
    });
    return tui.Cmd.none();
  }

  tui.Cmd? _selectDiffAnchor(w.DiffCommentAnchor anchor) {
    setState(() {
      _diffInteraction.selectAnchor(_diffController.commentAnchors, anchor);
      _revealDiffAnchor(anchor);
    });
    return tui.Cmd.none();
  }

  tui.Cmd? _selectDiffFile(int index) {
    setState(() {
      if (_detail.selectDiffFile(index)) {
        _diffInteraction.reset();
        _scrollController.jumpTo(0);
      }
    });
    return tui.Cmd.none();
  }

  tui.Cmd _moveDiffFile(int delta) {
    setState(() {
      if (_detail.moveDiffFile(delta)) {
        _diffInteraction.reset();
        _scrollController.jumpTo(0);
      }
    });
    return tui.Cmd.none();
  }

  void _revealDiffAnchor(w.DiffCommentAnchor? anchor) {
    if (anchor == null) return;
    final viewport = _scrollController.viewportExtent <= 0
        ? 24
        : _scrollController.viewportExtent;
    final top = _scrollController.offset;
    final bottom = top + viewport - 1;
    if (anchor.renderLine < top) {
      _scrollController.jumpTo(anchor.renderLine);
    } else if (anchor.renderLine > bottom) {
      _scrollController.jumpTo(anchor.renderLine - viewport + 1);
    }
  }

  tui.Cmd _scrollDiffViewport(int delta) {
    setState(() {
      _scrollController.scrollBy(delta);
      _syncDiffSelectionToViewport();
    });
    return tui.Cmd.none();
  }

  void _syncDiffSelectionToViewport() {
    final anchors = _diffController.commentAnchors;
    if (anchors.isEmpty) return;
    final viewport = _scrollController.viewportExtent <= 0
        ? 24
        : _scrollController.viewportExtent;
    final top = _scrollController.offset;
    final bottom = top + viewport - 1;
    final selected = _diffInteraction.selectedAnchor(anchors);
    if (selected != null &&
        selected.renderLine >= top &&
        selected.renderLine <= bottom) {
      return;
    }

    final preferredSide = selected?.side;
    w.DiffCommentAnchor? anchor = _diffController.commentAnchorAt(
      top,
      side: preferredSide,
    );
    anchor ??= anchors
        .where(
          (candidate) =>
              candidate.renderLine >= top &&
              candidate.renderLine <= bottom &&
              (preferredSide == null || candidate.side == preferredSide),
        )
        .firstOrNull;
    anchor ??= anchors
        .where(
          (candidate) =>
              candidate.renderLine >= top && candidate.renderLine <= bottom,
        )
        .firstOrNull;
    anchor ??= _diffController.nearestCommentAnchor(top);
    anchor ??= anchors.last;
    _diffInteraction.selectAnchor(anchors, anchor);
  }

  bool get _modalOpen =>
      _detail.detailItem != null ||
      _detail.mergeInfoItem != null ||
      _detail.repositoryLabelsItem != null ||
      _detail.actionPrompt != null ||
      _detail.repoPromptOpen;

  int get _pageStep {
    final extent = _scrollController.viewportExtent;
    return extent <= 2 ? 1 : extent - 2;
  }

  tui.Cmd _scrollDetailBy(int delta) {
    _scrollController.scrollBy(delta);
    return tui.Cmd.none();
  }

  tui.Cmd _cycleDetailTab(int delta) {
    final item = _queue.selectedItem;
    if (item == null) return tui.Cmd.none();
    const count = 4;
    final next = (_activeDetailTabIndex(item) + delta) % count;
    return _changeDetailTab(next < 0 ? next + count : next) ?? tui.Cmd.none();
  }

  int _activeDetailTabIndex(GithubDisplayItem item) {
    if (_sameItem(item, _detail.commitsItem)) return 1;
    if (_sameItem(item, _detail.reviewCommentsItem)) return 2;
    if (_sameItem(item, _detail.diffItem)) return 3;
    return 0;
  }

  bool _sameItem(GithubDisplayItem item, GithubDisplayItem? detail) {
    return detail != null &&
        detail.target == item.target &&
        detail.number == item.number;
  }

  tui.Cmd _switchDetailShortcut(int index) {
    return switch (index) {
      1 => _detailLoader.openSelectedCommits(),
      2 => _detailLoader.openSelectedReviewComments(),
      3 => _detailLoader.openSelectedDiff(),
      _ => tui.Cmd.none(),
    };
  }

  tui.Cmd _cycleTheme() {
    setState(() {
      _uiState.themeIndex =
          (_uiState.themeIndex + 1) % githubDashboardThemes.length;
    });
    _detail.applyNotice('Theme: ${_uiState.themeChoice.label}');
    return tui.Cmd.none();
  }

  tui.Cmd _openCommandPalette() {
    setState(() => _uiState.commandPaletteOpen = true);
    return tui.Cmd.none();
  }

  tui.Cmd _closeCommandPalette() {
    setState(() => _uiState.commandPaletteOpen = false);
    return tui.Cmd.none();
  }

  tui.Cmd? _paletteAction(tui.Cmd? Function() action) {
    setState(() => _uiState.commandPaletteOpen = false);
    return action();
  }

  @override
  w.Widget build(w.BuildContext context) {
    final themeChoice = _uiState.themeChoice;
    return w.ThemeScope(
      theme: themeChoice.theme(),
      child: w.ListenableBuilder(
        listenable: _detail,
        builder: (context, child) {
          return wrapGithubDashboardModals(
            child: child!,
            detailItem: _detail.detailItem,
            diffItem: null,
            diff: '',
            diffLoading: false,
            diffError: null,
            runDetailItem: null,
            runDetail: null,
            runDetailLoading: false,
            runDetailError: null,
            commentsItem: null,
            comments: _detail.comments,
            commentsLoading: _detail.commentsLoading,
            commentsError: _detail.commentsError,
            mergeInfoItem: _detail.mergeInfoItem,
            mergeInfo: _detail.mergeInfo,
            mergeInfoLoading: _detail.mergeInfoLoading,
            mergeInfoError: _detail.mergeInfoError,
            repositoryLabelsItem: _detail.repositoryLabelsItem,
            repositoryLabels: _detail.repositoryLabels,
            repositoryLabelsLoading: _detail.repositoryLabelsLoading,
            repositoryLabelsError: _detail.repositoryLabelsError,
            actionPrompt: _detail.actionPrompt,
            actionPromptError: _detail.actionPromptError,
            actionRunning: _detail.actionRunning,
            repoPromptOpen: false,
            repositoryListOpen: false,
            dashboard: _data.dashboard,
            repositories: const [],
            repoPromptError: null,
            onCloseDetail: _detailLoader.closeDetail,
            onCloseDiff: _detailLoader.closeDiff,
            onCloseRunDetail: _detailLoader.closeRunDetail,
            onCloseComments: _detailLoader.closeComments,
            onCloseMergeInfo: _detailLoader.closeMergeInfo,
            onSubmitMergeAction: _actions.submitMergeAction,
            onCloseRepositoryLabels: _detailLoader.closeRepositoryLabels,
            onToggleRepositoryLabel: _actions.toggleRepositoryLabel,
            onCloseActionPrompt: _actions.closeActionPrompt,
            onSubmitActionPrompt: _actions.submitActionPrompt,
            onCloseRepositoryPrompt: () => tui.Cmd.none(),
            onSubmitRepository: (_) => tui.Cmd.none(),
            onCloseRepositoryList: () => tui.Cmd.none(),
            onSelectRepository: (_) => tui.Cmd.none(),
          );
        },
        child: w.CommandPalette(
          open: _uiState.commandPaletteOpen,
          title: 'GitHub command center',
          hint: 'comments, review, diff, actions...',
          width: 72,
          maxHeight: 24,
          items: _uiState.commandPaletteOpen
              ? _commandItems.build()
              : const <w.CommandPaletteItem>[],
          onDismiss: _closeCommandPalette,
          child: w.Builder(
            builder: (context) {
              final theme = w.ThemeScope.of(context);
              final size =
                  w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
              final width = size.width.toInt().clamp(60, 240);
              final height = size.height.toInt().clamp(18, 80);
              return w.Container(
                padding: const w.EdgeInsets.all(1),
                color: theme.background,
                child: w.Column(
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  children: [
                    w.Expanded(
                      child: _body(theme, width: width - 2, height: height - 4),
                    ),
                    w.Divider(
                      width: width - 2,
                      style: theme.bodySmall.copy()..foreground(theme.border),
                    ),
                    _footer(theme, themeChoice.label),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  w.Widget _body(w.Theme theme, {required int width, required int height}) {
    return w.ListenableBuilder(
      listenable: w.Listenable.merge([_data, _queue, _detail]),
      builder: (context, _) {
        final dashboard = _data.dashboard;
        final item = _queue.selectedItem;
        if (dashboard == null || item == null) {
          if (_pullRequestError != null) {
            return _centerText(theme, _pullRequestError!, error: true);
          }
          return _centerText(
            theme,
            _pullRequestLoading
                ? 'Loading ${widget.target.repository} PR #${widget.target.number}...'
                : 'No pull request loaded.',
          );
        }

        return githubDetailPane(
          theme: theme,
          dashboard: dashboard,
          selectedItem: item,
          navigating: false,
          controller: _scrollController,
          commentsItem: _detail.commentsItem,
          comments: _detail.comments,
          commentsLoading: _detail.commentsLoading,
          commentsError: _detail.commentsError,
          commitsItem: _detail.commitsItem,
          commits: _detail.commits,
          commitsLoading: _detail.commitsLoading,
          commitsError: _detail.commitsError,
          reviewCommentsItem: _detail.reviewCommentsItem,
          reviewComments: _detail.reviewComments,
          reviewCommentsLoading: _detail.reviewCommentsLoading,
          reviewCommentsError: _detail.reviewCommentsError,
          diffItem: _detail.diffItem,
          diff: _detail.diff,
          diffFiles: _detail.diffFiles,
          diffFileIndex: _detail.diffFileIndex,
          diffLoading: _detail.diffLoading,
          diffError: _detail.diffError,
          diffViewMode: _uiState.diffViewMode,
          diffController: _diffController,
          diffCommentHighlights: _diffInteraction.highlights(
            _diffController.commentAnchors,
          ),
          onDiffCommentAnchorSelected: _selectDiffAnchor,
          onDiffFileSelected: _selectDiffFile,
          mergeInfoItem: null,
          mergeInfo: null,
          mergeInfoLoading: _detail.mergeInfoLoading,
          mergeInfoError: _detail.mergeInfoError,
          repositoryLabelsItem: null,
          repositoryLabels: const <GithubRepositoryLabel>[],
          repositoryLabelsLoading: _detail.repositoryLabelsLoading,
          repositoryLabelsError: _detail.repositoryLabelsError,
          runDetailItem: null,
          runDetail: null,
          runDetailLoading: false,
          runDetailError: null,
          onTabChanged: _changeDetailTab,
          height: height,
          width: width,
        );
      },
    );
  }

  GithubDashboardData _dashboardFor(GithubPullRequestItem pullRequest) {
    return GithubDashboardData(
      repository: GithubRepositorySummary(
        nameWithOwner: widget.target.repository,
        description: '',
        url: 'https://github.com/${widget.target.repository}',
        defaultBranch: '',
        stars: 0,
        forks: 0,
        isPrivate: false,
        viewerPermission: '',
        primaryLanguage: '',
        latestRelease: '',
      ),
      issues: const <GithubIssueItem>[],
      pullRequests: [pullRequest],
      loadedAt: DateTime.now(),
    );
  }

  w.Widget _centerText(w.Theme theme, String text, {bool error = false}) {
    return w.Container(
      align: HorizontalAlign.center,
      verticalAlign: VerticalAlign.center,
      child: w.Text(
        text,
        style: theme.bodyMedium.copy()
          ..foreground(error ? theme.error : theme.muted),
        softWrap: true,
        maxWidth: 100,
      ),
    );
  }

  w.Widget _footer(w.Theme theme, String themeName) {
    final keyStyle = theme.bodyMedium.copy()..foreground(Colors.warning);
    final hintStyle = theme.bodyMedium.copy()..foreground(theme.muted);
    w.Widget key(String value) => w.Text(value, style: keyStyle);
    w.Widget label(String value) => w.Text(value, style: hintStyle);
    return w.ListenableBuilder(
      listenable: _detail,
      builder: (context, _) {
        final diffActive = _detailLoader.diffTabActive;
        return w.Row(
          gap: 1,
          children: [
            key('↑↓/j/k'),
            label('scroll'),
            key('tab/←→'),
            label('tabs'),
            if (diffActive) key('c'),
            if (diffActive) label('conversation'),
            if (!diffActive) key('c/v/d'),
            if (!diffActive) label('conversation/reviews/diff'),
            if (diffActive) key('enter/a'),
            if (diffActive) label('comment'),
            if (diffActive) key('v'),
            if (diffActive) label('range'),
            if (diffActive) key('s'),
            if (diffActive) label('layout'),
            key('m/l/x'),
            label('merge/labels'),
            key('o'),
            label('open'),
            key('p'),
            label('palette'),
            key('r'),
            label('refresh'),
            key('q'),
            label('quit'),
            w.Spacer(),
            if (_detail.notice != null) label(_detail.notice!),
            label(themeName),
          ],
        );
      },
    );
  }
}
