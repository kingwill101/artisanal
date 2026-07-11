import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../client/client.dart';
import '../models/action_prompt.dart';
import '../models/diff_comment_target.dart';
import '../models/display_item.dart';
import '../state/notifiers.dart';
import '../ui/dashboard/modal_stack.dart';
import 'command_items.dart';
import 'dashboard_content.dart';
import 'data_coordinator.dart';
import 'detail_coordinator.dart';
import 'diff_interaction_state.dart';
import 'layout_mode.dart';
import 'messages.dart';
import 'navigation_coordinator.dart';
import 'shortcut.dart';
import 'ui_state.dart';

final class GithubCliDashboard extends w.StatefulWidget {
  GithubCliDashboard({
    required this.client,
    this.repository,
    this.owner,
    this.limit = 20,
    super.key,
  });

  final GithubDashboardClient client;
  final String? repository;
  final String? owner;
  final int limit;

  @override
  w.State<GithubCliDashboard> createState() => _GithubCliDashboardState();
}

final class _GithubCliDashboardState extends w.State<GithubCliDashboard> {
  late final GithubQueueNotifier _queue;
  late final GithubDataNotifier _data;
  late final GithubDetailNotifier _detail;
  late final GithubDashboardUiState _uiState;

  late final GithubDashboardDataCoordinator _dataCoordinator;
  late final GithubDashboardDetailLoader _detailLoader;
  late final GithubDashboardActionCoordinator _actions;
  late final GithubDashboardNavigationCoordinator _navigation;
  late final GithubDashboardCommandItems _commandItems;

  final _detailScrollController = w.WidgetScrollController();
  final _queueScrollController = w.WidgetScrollController();
  final _diffController = w.GitDiffController();
  final _diffInteraction = GithubDiffInteractionState();

  @override
  void initState() {
    super.initState();
    _data = GithubDataNotifier()
      ..setTarget(repository: widget.repository, owner: widget.owner);
    _queue = GithubQueueNotifier(tabIndex: widget.owner == null ? 2 : 0);
    _detail = GithubDetailNotifier();
    _uiState = GithubDashboardUiState();

    _dataCoordinator = GithubDashboardDataCoordinator(
      client: () => widget.client,
      limit: () => widget.limit,
      data: _data,
      queue: _queue,
      detail: _detail,
      resetScroll: () => _navigation.resetScroll(),
      keepSelectionVisible: () => _navigation.keepSelectionVisible(),
    );
    _detailLoader = GithubDashboardDetailLoader(
      client: () => widget.client,
      data: _data,
      queue: _queue,
      detail: _detail,
      detailScrollController: _detailScrollController,
      setLayoutMode: (mode) => _navigation.setLayoutMode(mode),
    );
    _actions = GithubDashboardActionCoordinator(
      client: () => widget.client,
      data: _data,
      queue: _queue,
      detail: _detail,
      loadDashboard: ({bool clearDashboard = false}) =>
          _dataCoordinator.loadDashboard(clearDashboard: clearDashboard),
    );
    _navigation = GithubDashboardNavigationCoordinator(
      uiState: _uiState,
      queue: _queue,
      data: _data,
      detail: _detail,
      detailScrollController: _detailScrollController,
      queueScrollController: _queueScrollController,
      setState: (fn) => setState(fn),
      loadCurrentPage: ({required bool replace}) =>
          _dataCoordinator.loadCurrentPage(replace: replace),
      changeDetailTab: _detailLoader.changeDetailTab,
    );
    _commandItems = GithubDashboardCommandItems(
      uiState: _uiState,
      queue: _queue,
      data: _data,
      paletteAction: _navigation.paletteAction,
      openRepositoryPrompt: _actions.openRepositoryPrompt,
      openRepositoryList: _actions.openRepositoryList,
      loadDashboard: _dataCoordinator.loadDashboard,
      loadCurrentPage: _dataCoordinator.loadCurrentPage,
      openSelectedUrl: _detailLoader.openSelectedUrl,
      toggleFocusedView: _navigation.toggleFocusedView,
      cycleTheme: _navigation.cycleTheme,
      switchTab: _navigation.switchTab,
      openSelectedDetail: _detailLoader.openSelectedDetail,
      openSelectedComments: _detailLoader.openSelectedComments,
      openSelectedCommits: _detailLoader.openSelectedCommits,
      openSelectedReviewComments: _detailLoader.openSelectedReviewComments,
      openSelectedDiff: _detailLoader.openSelectedDiff,
      openSelectedMergeInfo: _detailLoader.openSelectedMergeInfo,
      openSelectedRunDetail: _detailLoader.openSelectedRunDetail,
      openSelectedRepositoryLabels: _detailLoader.openSelectedRepositoryLabels,
      openActionPrompt: _actions.openActionPrompt,
      toggleSelectedPullRequestDraft: _actions.toggleSelectedPullRequestDraft,
      openSearch: _detailLoader.openSearch,
    );
  }

  @override
  void dispose() {
    _navigation.dispose();
    _queue.dispose();
    _data.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant GithubCliDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.owner != widget.owner) {
      _data.setTarget(repository: widget.repository, owner: widget.owner);
      return _dataCoordinator.loadDashboard(clearDashboard: true);
    }
    return null;
  }

  @override
  tui.Cmd? handleInit() => _dataCoordinator.loadDashboard();

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (_dataCoordinator.handlesMessage(msg)) {
      return _dataCoordinator.handleMessage(msg);
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
    if (_uiState.commandPaletteOpen) return null;
    if (_detail.repoPromptOpen ||
        _detail.searchOpen ||
        _detail.repositoryListOpen) {
      return null;
    }

    final shortcut = githubDashboardShortcutFor(msg);

    // Allow loading more items even when a detail pane is open.
    if (shortcut == GithubDashboardShortcut.loadNextPage) {
      return _queue.isSearchActive
          ? _detailLoader.loadNextSearchPage()
          : _dataCoordinator.loadCurrentPage(replace: false);
    }

    if (_detail.detailItem != null ||
        _detail.mergeInfoItem != null ||
        _detail.repositoryLabelsItem != null ||
        _detail.actionPrompt != null) {
      return null;
    }

    if (_uiState.layoutMode.isFocused && msg.key.type == tui.KeyType.escape) {
      return _navigation.setLayoutMode(GithubDashboardLayoutMode.split);
    }
    if (msg.key.type == tui.KeyType.escape && _queue.isSearchActive) {
      _queue.clearSearch();
      return tui.Cmd.none();
    }
    if (_detailLoader.diffTabActive) {
      final command = _handleDiffInteractionKey(msg, shortcut);
      if (command != null) return command;
    }
    if (_uiState.layoutMode.isFocused) {
      final focusedCommand = _navigation.handleFocusedShortcut(shortcut);
      if (focusedCommand != null) return focusedCommand;
    }

    return switch (shortcut) {
      GithubDashboardShortcut.quit => tui.Cmd.quit(),
      GithubDashboardShortcut.refresh => _dataCoordinator.loadDashboard(),
      GithubDashboardShortcut.overviewTab => _navigation.switchTab(0),
      GithubDashboardShortcut.issuesTab => _navigation.switchTab(1),
      GithubDashboardShortcut.pullRequestsTab => _navigation.switchTab(2),
      GithubDashboardShortcut.actionsTab => _navigation.switchTab(3),
      GithubDashboardShortcut.nextItem => _navigation.moveSelection(1),
      GithubDashboardShortcut.previousItem => _navigation.moveSelection(-1),
      GithubDashboardShortcut.nextPage => _navigation.moveSelection(8),
      GithubDashboardShortcut.previousPage => _navigation.moveSelection(-8),
      GithubDashboardShortcut.nextTab => _navigation.switchTab(
        (_queue.tabIndex + 1) % githubDashboardTabCount,
      ),
      GithubDashboardShortcut.previousTab => _navigation.switchTab(
        (_queue.tabIndex + githubDashboardTabCount - 1) %
            githubDashboardTabCount,
      ),
      GithubDashboardShortcut.loadNextPage => null,
      GithubDashboardShortcut.openBrowser => _detailLoader.openSelectedUrl(),
      GithubDashboardShortcut.viewDetails => _detailLoader.openSelectedDetail(),
      GithubDashboardShortcut.viewDiff => _detailLoader.openSelectedDiff(),
      GithubDashboardShortcut.viewRunInfo =>
        _detailLoader.openSelectedRunDetail(),
      GithubDashboardShortcut.viewComments =>
        _detailLoader.openSelectedComments(),
      GithubDashboardShortcut.viewReviewComments =>
        _detailLoader.openSelectedReviewComments(),
      GithubDashboardShortcut.viewMergeInfo =>
        _detailLoader.openSelectedMergeInfo(),
      GithubDashboardShortcut.viewRepositoryLabels =>
        _detailLoader.openSelectedRepositoryLabels(),
      GithubDashboardShortcut.addComment => _actions.openActionPrompt(
        GithubActionPromptKind.addComment,
      ),
      GithubDashboardShortcut.addLabels =>
        _detailLoader.openSelectedRepositoryLabels(),
      GithubDashboardShortcut.removeLabels =>
        _detailLoader.openSelectedRepositoryLabels(),
      GithubDashboardShortcut.commandPalette =>
        _navigation.openCommandPalette(),
      GithubDashboardShortcut.switchRepository =>
        _actions.openRepositoryPrompt(),
      GithubDashboardShortcut.toggleFocusedView =>
        _navigation.toggleFocusedView(),
      GithubDashboardShortcut.cycleTheme => _navigation.cycleTheme(),
      GithubDashboardShortcut.search => _detailLoader.openSearch(),
      null => null,
    };
  }

  tui.Cmd? _handleDiffInteractionKey(
    tui.KeyMsg msg,
    GithubDashboardShortcut? shortcut,
  ) {
    final key = msg.key;
    if (shortcut == GithubDashboardShortcut.addComment ||
        key.type == tui.KeyType.enter) {
      return _actions.openDiffCommentPrompt(_currentDiffCommentTarget());
    }
    if (key.isChar('v')) {
      setState(() {
        _ensureDiffSelection();
        _diffInteraction.toggleRange(_diffController.commentAnchors);
      });
      return tui.Cmd.none();
    }
    if (key.isChar('s')) {
      return _navigation.cycleDiffViewMode();
    }
    if (key.isChar(']')) {
      return _moveDiffFile(1);
    }
    if (key.isChar('[')) {
      return _moveDiffFile(-1);
    }
    if (shortcut == GithubDashboardShortcut.nextItem) {
      return _moveDiffAnchor(1);
    }
    if (shortcut == GithubDashboardShortcut.previousItem) {
      return _moveDiffAnchor(-1);
    }
    if (shortcut == GithubDashboardShortcut.nextPage) {
      return _scrollDiffViewport(_detailPageStep);
    }
    if (shortcut == GithubDashboardShortcut.previousPage) {
      return _scrollDiffViewport(-_detailPageStep);
    }
    if (key.type == tui.KeyType.left) {
      return _navigation.cycleFocusedDetailTab(-1);
    }
    if (key.type == tui.KeyType.right) {
      return _navigation.cycleFocusedDetailTab(1);
    }
    if (key.isChar('h')) {
      return _selectDiffSide(w.DiffCommentSide.left);
    }
    if (key.isChar('l')) {
      return _selectDiffSide(w.DiffCommentSide.right);
    }
    if (msg.key.type == tui.KeyType.escape && _diffInteraction.rangeActive) {
      setState(() => _diffInteraction.rangeStartAnchorIndex = null);
      return tui.Cmd.none();
    }
    return null;
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

  tui.Cmd _moveDiffFile(int delta) {
    setState(() {
      if (_detail.moveDiffFile(delta)) {
        _diffInteraction.reset();
        _detailScrollController.jumpTo(0);
      }
    });
    return tui.Cmd.none();
  }

  tui.Cmd? _selectDiffFile(int index) {
    setState(() {
      if (_detail.selectDiffFile(index)) {
        _diffInteraction.reset();
        _detailScrollController.jumpTo(0);
      }
    });
    return tui.Cmd.none();
  }

  tui.Cmd _openRepositoryFromOverview(String repository) {
    _data.setTarget(repository: repository, owner: null);
    _detail.closeRepositoryList();
    _detail.closeAllInlineDetails();
    _queue.resetSelection();
    _navigation.resetScroll();
    return _dataCoordinator.loadDashboard(clearDashboard: true);
  }

  void _revealDiffAnchor(w.DiffCommentAnchor? anchor) {
    if (anchor == null) return;
    final viewport = _detailScrollController.viewportExtent <= 0
        ? 24
        : _detailScrollController.viewportExtent;
    final top = _detailScrollController.offset;
    final bottom = top + viewport - 1;
    if (anchor.renderLine < top) {
      _detailScrollController.jumpTo(anchor.renderLine);
    } else if (anchor.renderLine > bottom) {
      _detailScrollController.jumpTo(anchor.renderLine - viewport + 1);
    }
  }

  int get _detailPageStep {
    final extent = _detailScrollController.viewportExtent;
    return extent <= 2 ? 1 : extent - 2;
  }

  tui.Cmd _scrollDiffViewport(int delta) {
    setState(() {
      _detailScrollController.scrollBy(delta);
      _syncDiffSelectionToViewport();
    });
    return tui.Cmd.none();
  }

  void _syncDiffSelectionToViewport() {
    final anchors = _diffController.commentAnchors;
    if (anchors.isEmpty) return;
    final viewport = _detailScrollController.viewportExtent <= 0
        ? 24
        : _detailScrollController.viewportExtent;
    final top = _detailScrollController.offset;
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

  GithubDiffCommentTarget? _currentDiffCommentTarget() {
    if (_detail.diff.trim().isEmpty) return null;
    final anchors = _diffController.commentAnchors;
    _ensureDiffSelection();
    return _diffInteraction.targetFor(anchors);
  }

  void _ensureDiffSelection() {
    if (_diffInteraction.hasSelection) return;
    final renderLine = _detailScrollController.offset;
    final anchor =
        _diffController.commentAnchorAt(renderLine) ??
        _diffController.nearestCommentAnchor(renderLine);
    if (anchor != null) {
      _diffInteraction.selectAnchor(_diffController.commentAnchors, anchor);
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    final themeChoice = _uiState.themeChoice;

    return w.ThemeScope(
      theme: themeChoice.theme(),
      child: w.ListenableBuilder(
        listenable: _detail,
        builder: (ctx, child) => wrapGithubDashboardModals(
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
          repoPromptOpen: _detail.repoPromptOpen,
          searchOpen: _detail.searchOpen,
          repositoryListOpen: _detail.repositoryListOpen,
          dashboard: _data.dashboard,
          repositories: _data.dashboard?.repositories ?? const [],
          repoPromptError: _detail.repoPromptError,
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
          onCloseRepositoryPrompt: _actions.closeRepositoryPrompt,
          onSubmitRepository: _actions.submitRepository,
          onCloseSearch: _detailLoader.closeSearch,
          onSubmitSearch: _detailLoader.submitSearch,
          onCloseRepositoryList: _actions.closeRepositoryList,
          onSelectRepository: _openRepositoryFromOverview,
        ),
        child: GithubDashboardContent(
          queue: _queue,
          data: _data,
          detail: _detail,
          uiState: _uiState,
          commandItems: _commandItems,
          detailScrollController: _detailScrollController,
          queueScrollController: _queueScrollController,
          diffController: _diffController,
          diffCommentHighlights: _diffInteraction.highlights(
            _diffController.commentAnchors,
          ),
          onDiffCommentAnchorSelected: _selectDiffAnchor,
          onDiffFileSelected: _selectDiffFile,
          onCloseCommandPalette: _navigation.closeCommandPalette,
          onDetailTabChanged: _detailLoader.changeDetailTab,
          onTabChanged: _navigation.switchTab,
          onOverviewFilterChanged: _navigation.switchOverviewFilter,
          onItemSelected: _navigation.selectItem,
        ),
      ),
    );
  }
}
