import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/repository_summary.dart';
import '../../utils/time.dart';

final class GithubRepositoriesDialog extends w.StatefulWidget {
  GithubRepositoriesDialog({
    required this.repositories,
    required this.currentRepository,
    required this.onClose,
    required this.onSelect,
    super.key,
  });

  final List<GithubRepositorySummary> repositories;
  final String? currentRepository;
  final tui.Cmd? Function() onClose;
  final tui.Cmd? Function(String repository) onSelect;

  @override
  w.State<GithubRepositoriesDialog> createState() =>
      _GithubRepositoriesDialogState();
}

final class _GithubRepositoriesDialogState
    extends w.State<GithubRepositoriesDialog> {
  static const _rowHeight = 2;

  var _query = '';
  var _selectedIndex = 0;
  String? _cachedNormalizedQuery;
  List<GithubRepositorySummary>? _cachedRepositoriesSource;
  List<GithubRepositorySummary> _cachedFilteredRepositories = const [];

  List<GithubRepositorySummary> get _filteredRepositories {
    final normalized = _query.trim().toLowerCase();
    if (_cachedNormalizedQuery == normalized &&
        identical(_cachedRepositoriesSource, widget.repositories)) {
      return _cachedFilteredRepositories;
    }
    _cachedNormalizedQuery = normalized;
    _cachedRepositoriesSource = widget.repositories;
    _cachedFilteredRepositories = normalized.isEmpty
        ? widget.repositories
        : widget.repositories
              .where((repository) {
                return repository.nameWithOwner.toLowerCase().contains(
                      normalized,
                    ) ||
                    repository.description.toLowerCase().contains(normalized) ||
                    repository.primaryLanguage.toLowerCase().contains(
                      normalized,
                    );
              })
              .toList(growable: false);
    return _cachedFilteredRepositories;
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    final key = msg.key;
    if (key.type == tui.KeyType.escape) return widget.onClose();
    if (key.type == tui.KeyType.up) {
      _move(-1);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.down) {
      _move(1);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.pageUp) {
      _move(-8);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.pageDown) {
      _move(8);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.home) {
      _move(-_filteredRepositories.length);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.end) {
      _move(_filteredRepositories.length);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.enter) {
      final repositories = _filteredRepositories;
      if (repositories.isEmpty) return tui.Cmd.none();
      final index = _selectedIndex.clamp(0, repositories.length - 1).toInt();
      return widget.onSelect(repositories[index].nameWithOwner);
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
  tui.Cmd? didUpdateWidget(covariant GithubRepositoriesDialog oldWidget) {
    final command = super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repositories, widget.repositories)) {
      _cachedRepositoriesSource = null;
    }
    _clampSelection();
    return command;
  }

  void _move(int delta) {
    final repositories = _filteredRepositories;
    if (repositories.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta)
          .clamp(0, repositories.length - 1)
          .toInt();
    });
  }

  void _clampSelection() {
    final repositories = _filteredRepositories;
    if (repositories.isEmpty) {
      _selectedIndex = 0;
    } else if (_selectedIndex >= repositories.length) {
      _selectedIndex = repositories.length - 1;
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final size = w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
    final availableWidth = (size.width.toInt() - 10).clamp(34, 76).toInt();
    final width = availableWidth < 46
        ? availableWidth
        : availableWidth.clamp(46, 76).toInt();
    final contentWidth = (width - 2).clamp(1, width).toInt();
    final visibleSlots = _visibleSlots;
    final bodyHeight = visibleSlots * _rowHeight;
    final hint = theme.bodySmall.copy()..foreground(theme.muted);

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
                w.Text('Repositories', style: theme.titleMedium),
                w.Spacer(),
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
              child: _body(theme, visibleSlots, contentWidth),
            ),
            w.Divider(
              width: contentWidth,
              style: theme.bodySmall.copy()..foreground(theme.border),
            ),
            w.Text('↑↓ move | enter open | esc close', style: hint),
          ],
        ),
      ),
    );
  }

  int get _visibleSlots {
    final count = _filteredRepositories.length;
    if (count == 0) return 3;
    return count.clamp(1, 10).toInt();
  }

  String get _countText {
    return '${_filteredRepositories.length}/${widget.repositories.length}';
  }

  String get _queryText {
    return _query.isEmpty ? '/ type to filter repositories' : '/ $_query';
  }

  w.Widget _body(w.Theme theme, int visibleSlots, int width) {
    final repositories = _filteredRepositories;
    if (repositories.isEmpty) {
      final message = _query.isEmpty
          ? 'No repositories loaded.'
          : 'No matches.';
      return w.Center(
        child: w.Text(
          message,
          style: theme.bodyMedium.copy()..foreground(theme.muted),
          overflow: w.TextOverflow.ellipsis,
        ),
      );
    }

    final start = (_selectedIndex - visibleSlots + 1)
        .clamp(
          0,
          (repositories.length - visibleSlots).clamp(0, repositories.length),
        )
        .toInt();
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visibleSlots; i++)
          _repositoryRow(
            theme,
            repositories[start + i],
            index: start + i,
            width: width,
          ),
      ],
    );
  }

  w.Widget _repositoryRow(
    w.Theme theme,
    GithubRepositorySummary repository, {
    required int index,
    required int width,
  }) {
    final selected = index == _selectedIndex;
    final current = repository.nameWithOwner == widget.currentRepository;
    final foreground = selected
        ? theme.listRowSelectedForeground
        : theme.listRowForeground;
    final mutedForeground = selected
        ? theme.listRowSelectedMutedForeground
        : theme.listRowMutedForeground;
    final nameStyle = theme.bodyMedium.copy()
      ..foreground(foreground)
      ..bold();
    final markerStyle = theme.bodyMedium.copy()
      ..foreground(
        selected
            ? theme.listRowSelectedMarkerForeground
            : theme.listRowMarkerForeground,
      );
    final metaStyle = theme.bodySmall.copy()..foreground(mutedForeground);
    final descriptionStyle = theme.bodySmall.copy()
      ..foreground(mutedForeground);
    final meta = _repositoryMeta(repository);
    final marker = current ? '*' : ' ';

    return w.GestureDetector(
      onTap: () => widget.onSelect(repository.nameWithOwner),
      child: w.Container(
        height: _rowHeight,
        color: selected
            ? theme.listRowSelectedBackground
            : theme.listRowBackground,
        padding: const w.EdgeInsets.symmetric(horizontal: 1),
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Row(
              children: [
                w.Text(marker, style: markerStyle),
                w.Spacer(size: 1),
                w.Expanded(
                  child: w.Text(
                    repository.nameWithOwner,
                    style: nameStyle,
                    overflow: w.TextOverflow.ellipsis,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  w.Spacer(size: 1),
                  w.Text(
                    meta,
                    style: metaStyle,
                    overflow: w.TextOverflow.ellipsis,
                    maxWidth: (width ~/ 3).clamp(8, 24).toInt(),
                  ),
                ],
              ],
            ),
            w.Padding(
              padding: const w.EdgeInsets.only(left: 2),
              child: w.Text(
                repository.description.isEmpty
                    ? repository.url
                    : repository.description,
                style: descriptionStyle,
                overflow: w.TextOverflow.ellipsis,
                maxWidth: (width - 2).clamp(1, width).toInt(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _repositoryMeta(GithubRepositorySummary repository) {
    final updated = relativeGithubTime(repository.updatedAt);
    return [
      if (repository.primaryLanguage.isNotEmpty) repository.primaryLanguage,
      if (repository.stars > 0) '${repository.stars} stars',
      if (updated.isNotEmpty) updated,
      if (repository.isPrivate) 'private',
    ].join('  ');
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
