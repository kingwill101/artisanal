import 'dart:async';

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/dashboard_data.dart';
import '../models/display_item.dart';
import '../state/notifiers.dart';
import 'layout_mode.dart';
import 'shortcut.dart';
import 'theme.dart';
import 'ui_state.dart';

final class GithubDashboardNavigationCoordinator {
  GithubDashboardNavigationCoordinator({
    required this.uiState,
    required this.queue,
    required this.data,
    required this.detail,
    required this.detailScrollController,
    required this.queueScrollController,
    required this.setState,
    required this.loadCurrentPage,
    required this.changeDetailTab,
  });

  final GithubDashboardUiState uiState;
  final GithubQueueNotifier queue;
  final GithubDataNotifier data;
  final GithubDetailNotifier detail;
  final w.WidgetScrollController detailScrollController;
  final w.WidgetScrollController queueScrollController;
  final void Function(void Function()) setState;
  final tui.Cmd Function({required bool replace}) loadCurrentPage;
  final tui.Cmd? Function(int index) changeDetailTab;

  Timer? _navDebounceTimer;
  static const _navDebounceMs = 120;

  void dispose() {
    _navDebounceTimer?.cancel();
  }

  tui.Cmd? handleFocusedShortcut(GithubDashboardShortcut? shortcut) {
    return switch (shortcut) {
      GithubDashboardShortcut.nextItem => scrollDetailBy(1),
      GithubDashboardShortcut.previousItem => scrollDetailBy(-1),
      GithubDashboardShortcut.nextPage => scrollDetailBy(_detailPageStep),
      GithubDashboardShortcut.previousPage => scrollDetailBy(-_detailPageStep),
      GithubDashboardShortcut.nextTab => cycleFocusedDetailTab(1),
      GithubDashboardShortcut.previousTab => cycleFocusedDetailTab(-1),
      GithubDashboardShortcut.viewDetails => tui.Cmd.none(),
      GithubDashboardShortcut.toggleFocusedView => toggleFocusedView(),
      _ => null,
    };
  }

  int get _detailPageStep {
    final extent = detailScrollController.viewportExtent;
    return extent <= 2 ? 1 : extent - 2;
  }

  tui.Cmd switchTab(int index) {
    _navDebounceTimer?.cancel();
    _navDebounceTimer = null;
    queue.switchTab(index);
    detail.closeAllInlineDetails();
    resetScroll();
    return data.hasLoadedTab(
          queue.tabIndex,
          overviewFilter: queue.overviewFilter,
        )
        ? tui.Cmd.none()
        : loadCurrentPage(replace: true);
  }

  tui.Cmd switchOverviewFilter(GithubOverviewFilter filter) {
    _navDebounceTimer?.cancel();
    _navDebounceTimer = null;
    queue.switchOverviewFilter(filter);
    detail.closeAllInlineDetails();
    resetScroll();
    return data.hasLoadedOverviewFilter(filter)
        ? tui.Cmd.none()
        : loadCurrentPage(replace: true);
  }

  tui.Cmd moveSelection(int delta) {
    final items = queue.visibleItems;
    final atEnd = items.isNotEmpty && queue.selectedIndex >= items.length - 1;
    if (delta > 0 && atEnd && queue.canLoadCurrentPage) {
      return loadCurrentPage(replace: false);
    }
    queue.moveBy(delta);
    keepSelectionVisible();
    _navDebounceTimer?.cancel();
    _navDebounceTimer = Timer(
      const Duration(milliseconds: _navDebounceMs),
      _settleNavigation,
    );
    return tui.Cmd.none();
  }

  void selectItem(int index) {
    _navDebounceTimer?.cancel();
    _navDebounceTimer = null;
    queue.moveToSettled(index);
    keepSelectionVisible();
    detailScrollController.jumpTo(0);
  }

  tui.Cmd scrollDetailBy(int delta) {
    detailScrollController.scrollBy(delta);
    return tui.Cmd.none();
  }

  tui.Cmd toggleFocusedView() {
    return setLayoutMode(
      uiState.layoutMode.isFocused
          ? GithubDashboardLayoutMode.split
          : GithubDashboardLayoutMode.focused,
    );
  }

  tui.Cmd cycleTheme() {
    setState(() {
      uiState.themeIndex =
          (uiState.themeIndex + 1) % githubDashboardThemes.length;
    });
    detail.applyNotice('Theme: ${uiState.themeChoice.label}');
    return tui.Cmd.none();
  }

  tui.Cmd setLayoutMode(GithubDashboardLayoutMode mode) {
    if (uiState.layoutMode == mode) return tui.Cmd.none();
    setState(() => uiState.layoutMode = mode);
    detailScrollController.jumpTo(0);
    return tui.Cmd.none();
  }

  tui.Cmd cycleFocusedDetailTab(int delta) {
    final item = queue.selectedItem;
    if (item == null) return tui.Cmd.none();
    final count = _detailTabCount(item);
    if (count <= 1) return tui.Cmd.none();
    final next = (_activeDetailTabIndex(item) + delta) % count;
    return changeDetailTab(next < 0 ? next + count : next) ?? tui.Cmd.none();
  }

  tui.Cmd cycleDiffViewMode() {
    final modes = w.DiffViewMode.values;
    final next = modes[(uiState.diffViewMode.index + 1) % modes.length];
    setState(() => uiState.diffViewMode = next);
    detailScrollController.jumpTo(0);
    return tui.Cmd.none();
  }

  tui.Cmd openCommandPalette() {
    setState(() => uiState.commandPaletteOpen = true);
    return tui.Cmd.none();
  }

  tui.Cmd closeCommandPalette() {
    setState(() => uiState.commandPaletteOpen = false);
    return tui.Cmd.none();
  }

  tui.Cmd? paletteAction(tui.Cmd? Function() action) {
    setState(() => uiState.commandPaletteOpen = false);
    return action();
  }

  void resetScroll() {
    queueScrollController.jumpTo(0);
    detailScrollController.jumpTo(0);
  }

  void keepSelectionVisible() {
    final viewport = queueScrollController.viewportExtent;
    if (viewport <= 0) return;
    final itemTop = queue.selectedIndex * githubDisplayItemRowExtent;
    final itemBottom = itemTop + githubDisplayItemRowExtent - 1;
    final visibleTop = queueScrollController.offset;
    final visibleBottom = visibleTop + viewport - 1;
    if (itemTop < visibleTop) {
      queueScrollController.jumpTo(itemTop);
    } else if (itemBottom > visibleBottom) {
      final target = itemBottom - viewport + 1;
      final aligned =
          ((target + githubDisplayItemRowExtent - 1) ~/
              githubDisplayItemRowExtent) *
          githubDisplayItemRowExtent;
      queueScrollController.jumpTo(aligned);
    }
  }

  void _settleNavigation() {
    _navDebounceTimer = null;
    queue.settleNavigation();
    detailScrollController.jumpTo(0);
  }

  int _detailTabCount(GithubDisplayItem item) {
    return switch (item.target) {
      GithubDisplayTarget.pullRequest => 4,
      GithubDisplayTarget.issue when item.supportsIssueActions => 1,
      GithubDisplayTarget.workflowRun => 1,
      _ => 0,
    };
  }

  int _activeDetailTabIndex(GithubDisplayItem item) {
    if (item.target == GithubDisplayTarget.pullRequest) {
      if (_isActiveDetailItem(item, detail.commitsItem)) return 1;
      if (_isActiveDetailItem(item, detail.reviewCommentsItem)) return 2;
      if (_isActiveDetailItem(item, detail.diffItem)) return 3;
      return 0;
    }
    return 0;
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
