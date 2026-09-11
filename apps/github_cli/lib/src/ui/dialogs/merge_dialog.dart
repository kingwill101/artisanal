import 'dart:math' as math;

import 'package:artisanal/style.dart' show Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/display_item.dart';
import '../../models/merge_info.dart';

final class GithubMergeDialog extends w.StatefulWidget {
  GithubMergeDialog({
    required this.item,
    required this.info,
    required this.loading,
    required this.error,
    required this.running,
    required this.actionError,
    required this.onClose,
    required this.onSubmit,
    super.key,
  });

  final GithubDisplayItem item;
  final GithubPullRequestMergeInfo? info;
  final bool loading;
  final String? error;
  final bool running;
  final String? actionError;
  final tui.Cmd? Function() onClose;
  final tui.Cmd? Function(GithubPullRequestMergeAction action) onSubmit;

  @override
  w.State<GithubMergeDialog> createState() => _GithubMergeDialogState();
}

final class _GithubMergeDialogState extends w.State<GithubMergeDialog> {
  int _selectedIndex = 0;

  List<GithubPullRequestMergeAction> get _actions {
    return widget.info?.availableActions ??
        const <GithubPullRequestMergeAction>[];
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
      final actions = _actions;
      if (widget.loading || actions.isEmpty) return tui.Cmd.none();
      final index = _selectedIndex.clamp(0, actions.length - 1).toInt();
      return widget.onSubmit(actions[index]);
    }
    return tui.Cmd.none();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant GithubMergeDialog oldWidget) {
    final command = super.didUpdateWidget(oldWidget);
    final actions = _actions;
    if (actions.isEmpty) {
      _selectedIndex = 0;
    } else if (_selectedIndex >= actions.length) {
      _selectedIndex = actions.length - 1;
    }
    return command;
  }

  void _move(int delta) {
    final actions = _actions;
    if (actions.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta)
          .clamp(0, actions.length - 1)
          .toInt();
    });
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final size = w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
    final availableWidth = math.max(1, size.width.toInt() - 12);
    final width = math.min(76, math.max(32, availableWidth));
    final height = _bodyHeight(size.height.toInt());
    final hint = theme.bodySmall.copy()..foreground(theme.muted);
    final errorStyle = theme.bodySmall.copy()..foreground(theme.error);

    return w.SizedBox(
      width: width,
      child: w.Frame(
        background: theme.surface,
        padding: const w.EdgeInsets.only(left: 2, right: 2, top: 1, bottom: 1),
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Row(
              children: [
                w.Text(
                  'Merge  #${widget.item.number}',
                  style: theme.titleMedium,
                ),
                w.Spacer(),
                if (widget.running || widget.loading) w.SpinnerIndicator(),
                if (widget.running || widget.loading) w.Spacer(size: 1),
                w.Text(_rightStatus, style: hint),
              ],
            ),
            w.Text(_statusLine, style: hint, overflow: w.TextOverflow.ellipsis),
            w.Divider(
              width: width - 4,
              style: theme.bodySmall.copy()..foreground(theme.border),
            ),
            w.SizedBox(height: height, child: _body(theme, height, width - 4)),
            w.Divider(
              width: width - 4,
              style: theme.bodySmall.copy()..foreground(theme.border),
            ),
            if (widget.actionError != null)
              w.Text(widget.actionError!, style: errorStyle),
            w.Text('↑↓ move | enter confirm | esc close', style: hint),
          ],
        ),
      ),
    );
  }

  String get _rightStatus {
    if (widget.running) return 'running';
    if (widget.loading) return 'loading';
    if (widget.info?.autoMergeEnabled ?? false) return 'auto on';
    return 'manual';
  }

  String get _statusLine {
    final info = widget.info;
    if (info == null) return '${widget.item.kind}  ${widget.item.status}';
    return [
      widget.item.kind,
      info.mergeable.toLowerCase(),
      info.isDraft ? 'draft' : 'ready',
      info.checks.label,
    ].join('  ');
  }

  int _bodyHeight(int screenHeight) {
    final maxBodyHeight = math.max(1, screenHeight - 16);
    if (widget.loading && widget.info == null) {
      return math.min(3, maxBodyHeight);
    }
    if (widget.error != null) return math.min(3, maxBodyHeight);
    final actions = _actions;
    if (actions.isEmpty) return math.min(3, maxBodyHeight);
    return math.min(actions.length, math.min(8, maxBodyHeight));
  }

  w.Widget _body(w.Theme theme, int height, int width) {
    final hint = theme.bodyMedium.copy()..foreground(theme.muted);
    final errorStyle = theme.bodyMedium.copy()..foreground(theme.error);
    final message = widget.error ?? _unavailableReason;
    if (widget.loading && widget.info == null) {
      return _centered(theme, 'Loading merge status from gh...', height);
    }
    if (widget.error != null) {
      return _centered(theme, widget.error!, height, style: errorStyle);
    }
    final actions = _actions;
    if (actions.isEmpty) {
      return _centered(theme, message, height, style: hint);
    }
    final visibleSlots = height.clamp(1, actions.length).toInt();
    final start = (_selectedIndex - visibleSlots + 1)
        .clamp(0, (actions.length - visibleSlots).clamp(0, actions.length))
        .toInt();
    final visible = actions.skip(start).take(visibleSlots).toList();
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++)
          _optionRow(theme, visible[i], index: start + i, width: width),
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

  w.Widget _optionRow(
    w.Theme theme,
    GithubPullRequestMergeAction action, {
    required int index,
    required int width,
  }) {
    final selected = index == _selectedIndex;
    final titleStyle = theme.bodyMedium.copy()
      ..foreground(
        action.isDangerous
            ? theme.error
            : selected
            ? theme.listRowSelectedForeground
            : theme.listRowForeground,
      );
    final hintStyle = theme.bodySmall.copy()
      ..foreground(
        selected
            ? theme.listRowSelectedMutedForeground
            : theme.listRowMutedForeground,
      );
    final label = '${action.title}  ${action.description}';
    final rowStyle = selected || action.isDangerous ? titleStyle : hintStyle;
    return w.Container(
      color: selected
          ? theme.listRowSelectedBackground
          : theme.listRowBackground,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.Text(
        label,
        style: rowStyle,
        overflow: w.TextOverflow.ellipsis,
        maxWidth: width,
      ),
    );
  }

  String get _unavailableReason {
    final info = widget.info;
    if (info == null) return 'Loading merge status from GitHub.';
    if (!info.isOpen) return 'This pull request is not open.';
    if (info.isDraft) return 'Draft pull requests cannot be merged.';
    if (info.mergeable.toLowerCase() == 'conflicting') {
      return 'This branch has merge conflicts.';
    }
    return 'No merge actions are currently available.';
  }
}
