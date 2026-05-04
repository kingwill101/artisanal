import 'package:artisanal/style.dart' show Colors, Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/display_item.dart';
import '../../models/repository_label.dart';
import '../label_style.dart';

final class GithubLabelsDialog extends w.StatefulWidget {
  GithubLabelsDialog({
    required this.item,
    required this.labels,
    required this.loading,
    required this.error,
    required this.running,
    required this.actionError,
    required this.onClose,
    required this.onToggle,
    super.key,
  });

  final GithubDisplayItem item;
  final List<GithubRepositoryLabel> labels;
  final bool loading;
  final String? error;
  final bool running;
  final String? actionError;
  final tui.Cmd? Function() onClose;
  final tui.Cmd? Function(GithubRepositoryLabel label) onToggle;

  @override
  w.State<GithubLabelsDialog> createState() => _GithubLabelsDialogState();
}

final class _GithubLabelsDialogState extends w.State<GithubLabelsDialog> {
  var _query = '';
  var _selectedIndex = 0;
  String? _cachedNormalizedQuery;
  List<GithubRepositoryLabel>? _cachedLabelsSource;
  List<GithubRepositoryLabel> _cachedFilteredLabels = const [];
  GithubDisplayItem? _cachedActiveItem;
  Set<String> _cachedActiveLabelNames = const {};

  List<GithubRepositoryLabel> get _filteredLabels {
    final normalized = _query.trim().toLowerCase();
    if (_cachedNormalizedQuery == normalized &&
        identical(_cachedLabelsSource, widget.labels)) {
      return _cachedFilteredLabels;
    }
    _cachedNormalizedQuery = normalized;
    _cachedLabelsSource = widget.labels;
    _cachedFilteredLabels = normalized.isEmpty
        ? widget.labels
        : widget.labels
              .where((label) => label.name.toLowerCase().contains(normalized))
              .toList(growable: false);
    return _cachedFilteredLabels;
  }

  Set<String> get _activeLabelNames {
    if (identical(_cachedActiveItem, widget.item)) {
      return _cachedActiveLabelNames;
    }
    _cachedActiveItem = widget.item;
    _cachedActiveLabelNames = widget.item.labels
        .map((label) => label.toLowerCase())
        .toSet();
    return _cachedActiveLabelNames;
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    final key = msg.key;
    if (key.type == tui.KeyType.escape) return widget.onClose();
    if (widget.running) return tui.Cmd.none();
    if (key.type == tui.KeyType.up || key.isChar('k')) {
      _move(-1);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.down || key.isChar('j')) {
      _move(1);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.enter) {
      final labels = _filteredLabels;
      if (widget.loading || labels.isEmpty) return tui.Cmd.none();
      final index = _selectedIndex.clamp(0, labels.length - 1).toInt();
      return widget.onToggle(labels[index]);
    }
    if (key.type == tui.KeyType.backspace && _query.isNotEmpty) {
      setState(() {
        _query = _query.substring(0, _query.length - 1);
        _selectedIndex = 0;
      });
      return tui.Cmd.none();
    }
    if (_isPlainPrintable(key)) {
      setState(() {
        _query += key.char!;
        _selectedIndex = 0;
      });
      return tui.Cmd.none();
    }
    return tui.Cmd.none();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant GithubLabelsDialog oldWidget) {
    final command = super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.labels, widget.labels)) {
      _cachedLabelsSource = null;
    }
    if (!identical(oldWidget.item, widget.item)) {
      _cachedActiveItem = null;
    }
    _clampSelection();
    return command;
  }

  void _move(int delta) {
    final labels = _filteredLabels;
    if (labels.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta)
          .clamp(0, labels.length - 1)
          .toInt();
    });
  }

  void _clampSelection() {
    final labels = _filteredLabels;
    if (labels.isEmpty) {
      _selectedIndex = 0;
    } else if (_selectedIndex >= labels.length) {
      _selectedIndex = labels.length - 1;
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final size = w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
    final availableWidth = (size.width.toInt() - 8).clamp(24, 52).toInt();
    final width = availableWidth < 36
        ? availableWidth
        : availableWidth.clamp(36, 52).toInt();
    final contentWidth = (width - 2).clamp(1, width).toInt();
    final bodyHeight = _bodyHeight;
    final hint = theme.bodySmall.copy()..foreground(theme.muted);
    final errorStyle = theme.bodySmall.copy()..foreground(theme.error);

    return w.SizedBox(
      width: width,
      child: w.Frame(
        background: theme.surface,
        padding: const w.EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 1),
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Row(
              children: [
                w.Text(
                  'Labels  ${widget.item.kind.toUpperCase()} '
                  '#${widget.item.number}',
                  style: theme.titleMedium,
                ),
                w.Spacer(),
                if (widget.running || widget.loading) w.SpinnerIndicator(),
                if (widget.running || widget.loading) w.Spacer(size: 1),
                w.Text(_countText, style: hint),
              ],
            ),
            w.Text(_queryText, style: hint, overflow: w.TextOverflow.ellipsis),
            w.Divider(
              width: contentWidth,
              style: theme.bodySmall.copy()..foreground(theme.border),
            ),
            w.SizedBox(
              height: bodyHeight,
              child: _body(theme, bodyHeight, contentWidth),
            ),
            w.Divider(
              width: contentWidth,
              style: theme.bodySmall.copy()..foreground(theme.border),
            ),
            if (widget.actionError != null)
              w.Text(widget.actionError!, style: errorStyle),
            w.Text('↑↓ move | enter toggle | esc close', style: hint),
          ],
        ),
      ),
    );
  }

  int get _bodyHeight {
    if (widget.loading && widget.labels.isEmpty) return 3;
    if (widget.error != null) return 4;
    final count = _filteredLabels.length;
    if (count == 0) return 3;
    return count.clamp(4, 9).toInt();
  }

  String get _countText {
    if (widget.running) return 'updating';
    if (widget.loading) return 'loading';
    return '${_filteredLabels.length}/${widget.labels.length}';
  }

  String get _queryText {
    return _query.isEmpty ? '/ type to filter labels' : '/ $_query';
  }

  w.Widget _body(w.Theme theme, int height, int width) {
    if (widget.loading && widget.labels.isEmpty) {
      return _centered(theme, 'Loading labels from gh...', height);
    }
    if (widget.error != null) {
      return _centered(
        theme,
        widget.error!,
        height,
        style: theme.bodyMedium.copy()..foreground(theme.error),
      );
    }
    final labels = _filteredLabels;
    if (labels.isEmpty) {
      final message = _query.isEmpty ? 'No repository labels.' : 'No matches.';
      return _centered(theme, message, height);
    }

    final visibleSlots = height.clamp(1, labels.length).toInt();
    final start = (_selectedIndex - visibleSlots + 1)
        .clamp(0, (labels.length - visibleSlots).clamp(0, labels.length))
        .toInt();
    final activeNames = _activeLabelNames;
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visibleSlots; i++)
          _labelRow(
            theme,
            labels[start + i],
            index: start + i,
            active: activeNames.contains(labels[start + i].name.toLowerCase()),
            width: width,
          ),
      ],
    );
  }

  w.Widget _centered(
    w.Theme theme,
    String message,
    int height, {
    Style? style,
  }) {
    return w.SizedBox(
      height: height,
      child: w.Center(
        child: w.Text(
          message,
          style: style ?? theme.bodyMedium.copy()
            ..foreground(theme.muted),
          overflow: w.TextOverflow.ellipsis,
        ),
      ),
    );
  }

  w.Widget _labelRow(
    w.Theme theme,
    GithubRepositoryLabel label, {
    required int index,
    required bool active,
    required int width,
  }) {
    final selected = index == _selectedIndex;
    final style = theme.bodyMedium.copy()
      ..foreground(
        selected ? theme.listRowSelectedForeground : theme.listRowForeground,
      );
    final markerStyle = theme.bodyMedium.copy()
      ..foreground(
        selected
            ? theme.listRowSelectedMarkerForeground
            : active
            ? Colors.green
            : theme.listRowMutedForeground,
      );
    return w.Container(
      color: selected
          ? theme.listRowSelectedBackground
          : theme.listRowBackground,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.Row(
        children: [
          w.Text(active ? '*' : ' ', style: markerStyle),
          w.Spacer(size: 1),
          w.Badge(
            '  ',
            background: labelBackgroundColor(label),
            foreground: labelForegroundColor(label),
          ),
          w.Spacer(size: 1),
          w.Text(
            label.name,
            style: style,
            overflow: w.TextOverflow.ellipsis,
            maxWidth: width - 6,
          ),
        ],
      ),
    );
  }

  bool _isPlainPrintable(tui.Key key) {
    return key.isPrintable &&
        !key.ctrl &&
        !key.alt &&
        !key.meta &&
        !key.hyper &&
        !key.superKey;
  }
}
