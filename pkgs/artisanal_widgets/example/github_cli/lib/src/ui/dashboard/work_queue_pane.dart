import 'package:artisanal/style.dart' show Color, Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/display_item.dart';
import '../../models/overview.dart';
import '../../models/page.dart';
import '../../models/repository_label.dart';
import '../../utils/time.dart';
import '../label_style.dart';

// Cached regex patterns — creating a RegExp on every row render allocated a
// new object for every item on every keypress.  Moving them to file scope
// means they are compiled once for the lifetime of the program.
final _reviewRegex = RegExp(r'review\s+(.+)$');
final _assignedRegex = RegExp(r'assigned\s+(.+)$');

w.Widget githubWorkQueuePane({
  required w.Theme theme,
  required int tabIndex,
  required GithubOverviewFilter overviewFilter,
  required int selectedIndex,
  required GithubPageStatus pageStatus,
  required List<GithubDisplayItem> items,
  required w.ScrollController controller,
  required int width,
  required tui.Cmd? Function(GithubOverviewFilter filter)
  onOverviewFilterChanged,
  required void Function(int index) onItemSelected,
  String? searchQuery,
  bool searchLoading = false,
  String? searchError,
  int searchPage = 1,
  bool searchHasMore = false,
  bool searchPageLoading = false,
}) {
  // Pre-compute the four text-style variants once per render call instead of
  // once per row.  Each style.copy() allocates; with 30 rows × 4 copies that
  // was 120 allocations per keypress.  With shared pre-computed styles only
  // the two accent / status styles (which depend on per-item data) still need
  // a fresh copy per row.
  final normalTitleStyle = theme.bodyMedium.copy()
    ..foreground(theme.listRowForeground);
  final selectedTitleStyle = theme.bodyMedium.copy()
    ..foreground(theme.listRowSelectedForeground)
    ..bold();
  final normalMetaStyle = theme.bodySmall.copy()
    ..foreground(theme.listRowMutedForeground);
  final selectedMetaStyle = theme.bodySmall.copy()
    ..foreground(theme.listRowSelectedMutedForeground);
  final normalAuthorStyle = theme.bodySmall.copy()
    ..foreground(theme.listRowAccentForeground)
    ..bold();
  final selectedAuthorStyle = theme.bodySmall.copy()
    ..foreground(theme.listRowSelectedAccentForeground)
    ..bold();
  final normalSeparatorStyle = theme.bodySmall.copy()
    ..foreground(theme.listRowSeparatorForeground);
  final selectedSeparatorStyle = theme.bodySmall.copy()
    ..foreground(theme.listRowSelectedSeparatorForeground);

  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    children: [
      _queueHeader(
        theme,
        tabIndex,
        overviewFilter,
        pageStatus,
        onOverviewFilterChanged,
        searchQuery: searchQuery,
        searchLoading: searchLoading,
        searchError: searchError,
        searchPage: searchPage,
        searchHasMore: searchHasMore,
        searchPageLoading: searchPageLoading,
      ),
      w.Expanded(
        child: items.isEmpty
            ? w.ScrollArea(
                controller: controller,
                showScrollbar: true,
                child: _emptyQueue(theme, tabIndex, searchQuery: searchQuery),
              )
            : w.Scrollbar(
                controller: controller,
                child: _buildVirtualizedList(
                  theme: theme,
                  items: items,
                  selectedIndex: selectedIndex,
                  controller: controller,
                  width: width,
                  onItemSelected: onItemSelected,
                  showRepository: tabIndex == 0,
                  normalTitleStyle: normalTitleStyle,
                  selectedTitleStyle: selectedTitleStyle,
                  normalMetaStyle: normalMetaStyle,
                  selectedMetaStyle: selectedMetaStyle,
                  normalAuthorStyle: normalAuthorStyle,
                  selectedAuthorStyle: selectedAuthorStyle,
                  normalSeparatorStyle: normalSeparatorStyle,
                  selectedSeparatorStyle: selectedSeparatorStyle,
                ),
              ),
      ),
    ],
  );
}

/// Builds rows through the library-level lazy viewport so list reconciliation
/// is bounded by the rendered range instead of the loaded item count.
w.Widget _buildVirtualizedList({
  required w.Theme theme,
  required List<GithubDisplayItem> items,
  required int selectedIndex,
  required w.ScrollController controller,
  required int width,
  required void Function(int index) onItemSelected,
  required bool showRepository,
  required Style normalTitleStyle,
  required Style selectedTitleStyle,
  required Style normalMetaStyle,
  required Style selectedMetaStyle,
  required Style normalAuthorStyle,
  required Style selectedAuthorStyle,
  required Style normalSeparatorStyle,
  required Style selectedSeparatorStyle,
}) {
  const rowHeight = githubDisplayItemRowExtent; // 3 content lines + separator

  return w.VirtualListView.builder(
    controller: controller,
    width: width,
    itemExtent: rowHeight,
    cacheExtentItems: 32,
    separator: '',
    itemCount: items.length,
    itemBuilder: (context, i) => w.SizedBox(
      height: rowHeight,
      child: _queueRow(
        theme,
        items[i],
        rowIndex: i,
        selected: i == selectedIndex,
        width: width,
        onTap: () => onItemSelected(i),
        showRepository: showRepository,
        normalTitleStyle: normalTitleStyle,
        selectedTitleStyle: selectedTitleStyle,
        normalMetaStyle: normalMetaStyle,
        selectedMetaStyle: selectedMetaStyle,
        normalAuthorStyle: normalAuthorStyle,
        selectedAuthorStyle: selectedAuthorStyle,
        normalSeparatorStyle: normalSeparatorStyle,
        selectedSeparatorStyle: selectedSeparatorStyle,
      ),
    ),
  );
}

w.Widget _queueHeader(
  w.Theme theme,
  int tabIndex,
  GithubOverviewFilter overviewFilter,
  GithubPageStatus pageStatus,
  tui.Cmd? Function(GithubOverviewFilter filter) onOverviewFilterChanged, {
  String? searchQuery,
  bool searchLoading = false,
  String? searchError,
  int searchPage = 1,
  bool searchHasMore = false,
  bool searchPageLoading = false,
}) {
  final muted = theme.bodyMedium.copy()..foreground(theme.muted);
  final errorStyle = theme.bodySmall.copy()..foreground(theme.error);

  if (searchQuery != null) {
    final statusText = searchLoading
        ? 'searching...'
        : searchPageLoading
        ? 'loading page...'
        : searchHasMore
        ? 'page $searchPage · n more'
        : 'page $searchPage done';
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Row(
          children: [
            w.Text(
              'SEARCH',
              style: theme.titleMedium.copy()..foreground(theme.warning),
            ),
            w.Spacer(),
            w.Text(
              statusText,
              style: muted,
              overflow: w.TextOverflow.ellipsis,
              maxWidth: 28,
            ),
          ],
        ),
        if (searchError != null) w.Text(searchError, style: errorStyle),
        w.Text(
          searchQuery,
          style: theme.bodySmall.copy()..foreground(theme.muted),
          overflow: w.TextOverflow.ellipsis,
          maxWidth: 96,
        ),
      ],
    );
  }

  return w.Column(
    crossAxisAlignment: w.CrossAxisAlignment.stretch,
    children: [
      w.Row(
        children: [
          w.Text(
            _queueTitle(tabIndex),
            style: theme.titleMedium.copy()..foreground(theme.warning),
          ),
          w.Spacer(),
          w.Text(
            _queueStatus(pageStatus),
            style: muted,
            overflow: w.TextOverflow.ellipsis,
            maxWidth: 28,
          ),
        ],
      ),
      if (pageStatus.error != null)
        w.Text(
          pageStatus.error!,
          style: errorStyle,
          overflow: w.TextOverflow.ellipsis,
          maxWidth: 96,
        ),
      if (tabIndex == 0)
        w.Tabs(
          index: overviewFilter.index,
          gap: 1,
          size: w.ButtonSize.small,
          onChanged: (index) {
            return onOverviewFilterChanged(GithubOverviewFilter.values[index]);
          },
          tabs: [
            for (final filter in GithubOverviewFilter.values)
              w.TabItem(filter.tabLabel),
          ],
        ),
    ],
  );
}

w.Widget _emptyQueue(w.Theme theme, int tabIndex, {String? searchQuery}) {
  if (searchQuery != null) {
    return w.PanelBox(
      title: 'Empty',
      child: w.Text('No results for "$searchQuery".', style: theme.bodyMedium),
    );
  }
  final label = switch (tabIndex) {
    1 => 'No open issues returned by gh.',
    2 => 'No open pull requests returned by gh.',
    3 => 'No workflow runs returned by gh.',
    _ => 'No open work returned by gh.',
  };
  return w.PanelBox(
    title: 'Empty',
    child: w.Text(label, style: theme.bodyMedium),
  );
}

w.Widget _queueRow(
  w.Theme theme,
  GithubDisplayItem item, {
  required int rowIndex,
  required bool selected,
  required int width,
  required void Function() onTap,
  required bool showRepository,
  // Pre-computed shared styles — passed in from the outer function so they are
  // not re-allocated per row.  Only accent and status need per-row copies.
  required Style normalTitleStyle,
  required Style selectedTitleStyle,
  required Style normalMetaStyle,
  required Style selectedMetaStyle,
  required Style normalAuthorStyle,
  required Style selectedAuthorStyle,
  required Style normalSeparatorStyle,
  required Style selectedSeparatorStyle,
}) {
  final bg = selected
      ? theme.listRowSelectedBackground
      : rowIndex.isOdd
      ? theme.listRowAlternateBackground
      : theme.listRowBackground;
  final statusColor = item.hasWarning ? theme.error : theme.success;
  final titleMaxWidth = (width - 8).clamp(12, 160).toInt();
  final labelMaxWidth = (width - 5).clamp(12, 160).toInt();
  final metaMaxWidth = (width - 5).clamp(12, 120).toInt();

  // Use pre-computed styles for title/meta — no copy() needed for these two.
  final titleStyle = selected ? selectedTitleStyle : normalTitleStyle;
  final metaStyle = selected ? selectedMetaStyle : normalMetaStyle;
  final authorStyle = selected ? selectedAuthorStyle : normalAuthorStyle;
  final separatorStyle = selected
      ? selectedSeparatorStyle
      : normalSeparatorStyle;

  // Accent and status colours depend on per-item data so a copy is still needed.
  final accentStyle = theme.bodyMedium.copy()..foreground(_accentColor(theme, item));
  final statusStyle = theme.bodyMedium.copy()
    ..foreground(statusColor)
    ..bold();
  final rowSeparatorStyle = theme.bodySmall.copy()
    ..foreground(
      selected
          ? theme.listRowSelectedSeparatorForeground
          : theme.listRowSeparatorForeground,
    );
  final marker = selected ? '┃' : '│';
  final titleText = _ellipsize('#${item.number} ${item.title}', titleMaxWidth);
  final labelSpans = _queueLabelSpans(
    theme,
    item,
    maxWidth: labelMaxWidth,
    selected: selected,
    fallbackColor: _accentColor(theme, item),
    separatorStyle: separatorStyle,
    statusStyle: statusStyle,
  );
  final metaSpans = _queueMetaSpans(
    item,
    maxWidth: metaMaxWidth,
    showRepository: showRepository,
    authorStyle: authorStyle,
    metaStyle: metaStyle,
    separatorStyle: separatorStyle,
  );

  return w.GestureDetector(
    onTap: () {
      onTap();
      return null;
    },
    child: w.Container(
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      color: bg,
      child: w.Text.rich(
        w.TextSpan(
          children: [
            w.TextSpan(text: marker, style: accentStyle),
            const w.TextSpan(text: ' '),
            w.TextSpan(text: titleText, style: titleStyle),
            const w.TextSpan(text: '\n  '),
            ...labelSpans,
            const w.TextSpan(text: '\n  '),
            ...metaSpans,
            const w.TextSpan(text: '\n '),
            w.TextSpan(
              text: '─' * (width - 2).clamp(1, 160).toInt(),
              style: rowSeparatorStyle,
            ),
          ],
        ),
        softWrap: false,
      ),
    ),
  );
}

String _ellipsize(String value, int maxWidth) {
  if (maxWidth <= 0) return '';
  if (value.length <= maxWidth) return value;
  if (maxWidth <= 3) return value.substring(0, maxWidth);
  return '${value.substring(0, maxWidth - 3)}...';
}

String _queueTitle(int tabIndex) {
  return switch (tabIndex) {
    1 => 'ISSUES',
    2 => 'PULL REQUESTS',
    3 => 'ACTIONS',
    _ => 'OVERVIEW',
  };
}

String _queueStatus(GithubPageStatus pageStatus) {
  if (pageStatus.loading) return 'loading page...';
  if (pageStatus.hasNextPage) return '${pageStatus.countLabel} loaded · n more';
  return '${pageStatus.countLabel} loaded';
}

Color _accentColor(w.Theme theme, GithubDisplayItem item) {
  if (item.hasWarning) return theme.error;
  return switch (item.target) {
    GithubDisplayTarget.issue => theme.primary,
    GithubDisplayTarget.pullRequest => theme.warning,
    GithubDisplayTarget.workflowRun => theme.success,
  };
}

String _statusGlyph(GithubDisplayItem item) {
  if (item.target == GithubDisplayTarget.workflowRun) {
    return item.hasWarning ? 'fail' : item.status;
  }
  if (item.target == GithubDisplayTarget.pullRequest) {
    return item.hasWarning ? 'x' : 'ok';
  }
  return '';
}

List<w.TextSpan> _queueLabelSpans(
  w.Theme theme,
  GithubDisplayItem item, {
  required int maxWidth,
  required bool selected,
  required Color fallbackColor,
  required Style separatorStyle,
  required Style statusStyle,
}) {
  if (maxWidth <= 0) return const <w.TextSpan>[];

  final spans = <w.TextSpan>[];
  var remaining = maxWidth;

  bool addPart(String value, Style style) {
    if (value.trim().isEmpty || remaining <= 0) return false;
    const separator = '  ';
    if (spans.isNotEmpty) {
      if (remaining <= separator.length + 1) return false;
      spans.add(w.TextSpan(text: separator, style: separatorStyle));
      remaining -= separator.length;
    }
    final text = _ellipsize(value, remaining);
    if (text.isEmpty) return false;
    spans.add(w.TextSpan(text: text, style: style));
    remaining -= text.length;
    return text.length == value.length;
  }

  final labels = _displayLabels(item);
  if (labels.isNotEmpty) {
    for (final label in labels.take(3)) {
      final labelStyle = theme.bodySmall.copy()
        ..foreground(labelBackgroundColor(label, fallback: fallbackColor))
        ..bold();
      if (!addPart(label.name, labelStyle)) return spans;
    }
  } else {
    final text = item.target == GithubDisplayTarget.workflowRun
        ? item.footer
        : item.status;
    final labelStyle = theme.bodySmall.copy()
      ..foreground(
        selected ? theme.listRowSelectedAccentForeground : fallbackColor,
      )
      ..bold();
    addPart(text, labelStyle);
  }

  final statusText = _statusGlyph(item);
  if (statusText.isNotEmpty) {
    addPart(statusText, statusStyle);
  }
  return spans;
}

List<GithubRepositoryLabel> _displayLabels(GithubDisplayItem item) {
  if (item.labelDetails.isNotEmpty) return item.labelDetails;
  if (item.labels.isEmpty) return const <GithubRepositoryLabel>[];
  return item.labels
      .map((name) => GithubRepositoryLabel(name: name, color: ''))
      .toList(growable: false);
}

List<w.TextSpan> _queueMetaSpans(
  GithubDisplayItem item, {
  required int maxWidth,
  required bool showRepository,
  required Style authorStyle,
  required Style metaStyle,
  required Style separatorStyle,
}) {
  if (maxWidth <= 0) return const <w.TextSpan>[];
  final author = _ellipsize('@${item.author}', maxWidth);
  final spans = <w.TextSpan>[w.TextSpan(text: author, style: authorStyle)];
  var remaining = maxWidth - author.length;
  if (author.length < item.author.length + 1) return spans;

  const separator = '  ·  ';
  final parts = <String>[
    if (showRepository && item.repository.isNotEmpty) item.repository,
    relativeGithubTime(item.updatedAt),
    if (item.supportsIssueActions) '${item.commentCount}c',
    ..._compactFooterParts(item),
  ].where((part) => part.trim().isNotEmpty);

  for (final part in parts) {
    if (remaining <= separator.length + 1) break;
    spans.add(w.TextSpan(text: separator, style: separatorStyle));
    remaining -= separator.length;
    final text = _ellipsize(part, remaining);
    spans.add(w.TextSpan(text: text, style: metaStyle));
    remaining -= text.length;
    if (text.length < part.length) break;
  }
  return spans;
}

List<String> _compactFooterParts(GithubDisplayItem item) {
  if (item.target == GithubDisplayTarget.pullRequest) {
    final match = _reviewRegex.firstMatch(item.footer);
    final review = match?.group(1)?.trim();
    if (review == null || review.isEmpty) return const <String>[];
    return <String>[review];
  }
  if (item.target == GithubDisplayTarget.issue) {
    if (item.footer.contains('no assignee')) {
      return const <String>['unassigned'];
    }
    final match = _assignedRegex.firstMatch(item.footer);
    final assignee = match?.group(1)?.trim();
    if (assignee == null || assignee.isEmpty) return const <String>[];
    return <String>['@$assignee'];
  }
  return item.footer
      .split('/')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}
