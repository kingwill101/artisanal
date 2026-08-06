/// Multi-file diff review pane (OpenCode diff-viewer style).
///
/// Left: file list with +/− stats. Right: [GitDiffViewer] for the selection.
/// On narrow widths the file list stacks above the patch.
library;

import 'package:artisanal/style.dart' show Color, Border, Style;
import 'package:artisanal/tui.dart' show Cmd, KeyMsg, Msg, KeyType;
import 'package:artisanal/bubbles.dart' show DiffViewMode;

import '../core/framework.dart'
    show BuildContext, State, StatefulWidget, StatelessWidget;
import '../core/widget.dart';
import '../layout/layout.dart';
import '../media/media_query.dart' show MediaQuery;
import '../scroll/scroll_widgets.dart' show SingleChildScrollView;
import '../theme/theme_scope.dart' show ThemeScope;
import 'frame.dart' show Frame;
import 'git_diff.dart' show GitDiffViewer;

/// One changed file in a [DiffReviewPane].
final class DiffReviewFile {
  const DiffReviewFile({
    required this.path,
    required this.diff,
    this.additions = 0,
    this.deletions = 0,
  });

  final String path;

  /// Unified diff body (may include `diff --git` headers).
  final String diff;
  final int additions;
  final int deletions;

  String get fileName {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }
}

/// Review surface: selectable file list + unified/split patch viewer.
class DiffReviewPane extends StatefulWidget {
  DiffReviewPane({
    required this.files,
    this.selectedIndex = 0,
    this.onSelectedIndexChanged,
    this.fileListWidth = 28,
    this.narrowBreakpoint = 90,
    this.viewMode,
    this.title = 'review',
    this.emptyLabel = 'No changed files',
    this.background,
    this.borderColor,
    this.mutedColor,
    this.accentColor,
    this.addedColor,
    this.removedColor,
    super.key,
  });

  final List<DiffReviewFile> files;
  final int selectedIndex;
  final void Function(int index)? onSelectedIndexChanged;

  /// Preferred width of the file column when side-by-side.
  final int fileListWidth;

  /// Below this width, stack list above patch.
  final int narrowBreakpoint;

  /// Forced [GitDiffViewer] mode; null allows interactive cycling.
  final DiffViewMode? viewMode;

  final String title;
  final String emptyLabel;
  final Color? background;
  final Color? borderColor;
  final Color? mutedColor;
  final Color? accentColor;
  final Color? addedColor;
  final Color? removedColor;

  @override
  State<DiffReviewPane> createState() => _DiffReviewPaneState();
}

class _DiffReviewPaneState extends State<DiffReviewPane> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _clampIndex(widget.selectedIndex);
  }

  @override
  Cmd? didUpdateWidget(covariant DiffReviewPane oldWidget) {
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.files.length != oldWidget.files.length) {
      _index = _clampIndex(widget.selectedIndex);
    }
    return super.didUpdateWidget(oldWidget);
  }

  int _clampIndex(int i) {
    if (widget.files.isEmpty) return 0;
    return i.clamp(0, widget.files.length - 1);
  }

  void _select(int i) {
    final next = _clampIndex(i);
    widget.onSelectedIndexChanged?.call(next);
    if (widget.onSelectedIndexChanged == null) {
      setState(() => _index = next);
    } else {
      _index = next;
    }
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is! KeyMsg || widget.files.isEmpty) return null;
    final key = msg.key;
    if (key.type == KeyType.up) {
      _select(_index - 1);
      return Cmd.none();
    }
    if (key.type == KeyType.down) {
      _select(_index + 1);
      return Cmd.none();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = widget.background ?? theme.surface;
    final border = widget.borderColor ?? theme.border;
    final muted = widget.mutedColor ?? theme.muted;
    final accent = widget.accentColor ?? theme.primary;
    final added = widget.addedColor ?? theme.success;
    final removed = widget.removedColor ?? theme.error;

    final idx = _clampIndex(
      widget.onSelectedIndexChanged != null ? widget.selectedIndex : _index,
    );
    final selected = widget.files.isEmpty ? null : widget.files[idx];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);
        final narrow = width <= widget.narrowBreakpoint;

        final header = Row(
          gap: 1,
          children: [
            Text(
              widget.title,
              style: theme.labelSmall.copy()..foreground(accent),
            ),
            Text('·', style: theme.bodySmall.copy()..foreground(muted)),
            Text(
              '${widget.files.length} files',
              style: theme.bodySmall.copy()..foreground(muted),
            ),
            Spacer(),
            if (selected != null)
              Flexible(
                child: Text(
                  selected.path,
                  style: theme.bodySmall.copy()..foreground(muted),
                  softWrap: false,
                ),
              ),
          ],
        );

        final fileList = _FileList(
          files: widget.files,
          selectedIndex: idx,
          muted: muted,
          added: added,
          removed: removed,
          onSelect: _select,
        );

        final patch = selected == null
            ? Center(
                child: Text(
                  widget.emptyLabel,
                  style: theme.bodySmall.copy()..foreground(muted),
                ),
              )
            : GitDiffViewer(
                diff: selected.diff,
                viewMode: widget.viewMode,
                showLineNumbers: true,
                wrapLines: true,
                handleKeys: true,
                scrollable: true,
              );

        final body = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                gap: 1,
                children: [
                  SizedBox(
                    height: mathMin(8, widget.files.length + 1).toDouble(),
                    child: fileList,
                  ),
                  Divider(style: Style().foreground(border)),
                  Expanded(child: patch),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: widget.fileListWidth.toDouble(),
                    child: fileList,
                  ),
                  VerticalDivider(style: Style().foreground(border)),
                  Expanded(child: patch),
                ],
              );

        return Frame(
          background: bg,
          border: Border.rounded,
          borderColor: border,
          padding: const EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            gap: 1,
            children: [
              header,
              Divider(style: Style().foreground(border)),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

int mathMin(int a, int b) => a < b ? a : b;

class _FileList extends StatelessWidget {
  _FileList({
    required this.files,
    required this.selectedIndex,
    required this.muted,
    required this.added,
    required this.removed,
    required this.onSelect,
  });

  final List<DiffReviewFile> files;
  final int selectedIndex;
  final Color muted;
  final Color added;
  final Color removed;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    if (files.isEmpty) {
      return Text(
        '—',
        style: theme.bodySmall.copy()..foreground(muted),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        gap: 0,
        children: [
          for (var i = 0; i < files.length; i++)
            GestureDetector(
              onTap: () {
                onSelect(i);
                return null;
              },
              child: Container(
                color: i == selectedIndex
                    ? theme.listRowSelectedBackground
                    : null,
                child: Row(
                  gap: 1,
                  children: [
                    Text(
                      i == selectedIndex ? '›' : ' ',
                      style: theme.labelSmall.copy()
                        ..foreground(
                          i == selectedIndex
                              ? theme.listRowSelectedForeground
                              : muted,
                        ),
                    ),
                    Expanded(
                      child: Text(
                        files[i].fileName,
                        style: theme.bodySmall.copy()
                          ..foreground(
                            i == selectedIndex
                                ? theme.listRowSelectedForeground
                                : theme.onSurface,
                          ),
                        softWrap: false,
                      ),
                    ),
                    Text(
                      '+${files[i].additions}',
                      style: theme.labelSmall.copy()..foreground(added),
                    ),
                    Text(
                      '-${files[i].deletions}',
                      style: theme.labelSmall.copy()..foreground(removed),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
