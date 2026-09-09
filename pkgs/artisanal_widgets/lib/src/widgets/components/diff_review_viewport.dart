/// A virtualized rich review surface over the core TEA review model.
library;

import 'dart:math' as math;

import 'package:artisanal/git_diff.dart';
import 'package:artisanal/runtime.dart';
import 'package:artisanal/style.dart'
    show
        Style,
        StyleRange,
        overlayBackgroundRangesPreservingAnsi,
        cutAnsiByCells;
import 'package:artisanal/uv.dart' show suppressOverflowingTerminalGraphics;

import '../core/element.dart';
import '../core/framework.dart';
import '../core/key.dart';
import '../core/widget.dart';
import '../layout/_layout_core.dart';
import '../rendering/render_object.dart';
import '../scroll/scroll_widgets.dart' show WidgetScrollController;
import '../theme/theme_scope.dart';
import 'diff_review_extents.dart';

/// Builds the expanded body of a visible review thread.
///
/// Keep drafts and provider payloads outside the widget tree, keyed by
/// document/revision and thread ID: offscreen bodies are unmounted.
typedef DiffReviewThreadBuilder =
    Widget Function(BuildContext context, DiffReviewThreadPlacement placement);

/// Owns TEA review state and the single comment-inclusive scroll position.
///
/// The base model's viewport is not used for rich scrolling. Selection and
/// expansion go through [update]; all scrolling uses [scrollController].
///
/// {@category Widgets}
class DiffReviewController {
  /// Creates a controller for a loaded review.
  DiffReviewController(DiffReviewModel model)
    : _model = model,
      _blocks = DiffReviewBlocks(model) {
    _extents = ReviewExtents(_blocks);
  }

  DiffReviewModel _model;
  DiffReviewBlocks _blocks;
  late ReviewExtents _extents;
  final _listeners = <void Function()>{};

  /// Current immutable TEA state.
  DiffReviewModel get model => _model;

  /// Sparse mixed code/thread sequence.
  DiffReviewBlocks get blocks => _blocks;

  /// Scroll offset and metrics in composed content rows, including comments.
  final WidgetScrollController scrollController = WidgetScrollController();

  /// Applies a semantic review message and returns any resulting command.
  Cmd? update(DiffReviewMsg msg) {
    final before = _model;
    final anchor = _capturePosition();
    final (next, cmd) = before.update(msg);
    if (identical(before, next)) return cmd;
    _model = next;
    final newDocument =
        before.document.id != next.document.id ||
        before.document.revision != next.document.revision;
    if (!identical(before.diff.layout, next.diff.layout) ||
        !identical(before.threads, next.threads) ||
        !identical(before.expandedThreadIds, next.expandedThreadIds)) {
      final oldExtents = _extents;
      _blocks = DiffReviewBlocks(next);
      _extents = ReviewExtents(_blocks);
      if (!newDocument &&
          before.diff.width == next.diff.width &&
          before.diff.splitColumns == next.diff.splitColumns) {
        for (var i = 0; i < _blocks.threadCount; i++) {
          final thread = _blocks.threadAt(i).placement.thread;
          if (identical(before.threads[thread.id], thread) &&
              before.expandedThreadIds.contains(thread.id) ==
                  next.expandedThreadIds.contains(thread.id)) {
            final oldIndex = oldExtents.blocks.indexOfThread(thread.id);
            if (oldIndex != null) {
              _extents.setThreadHeight(i, oldExtents.heightAt(oldIndex));
            }
          }
        }
      }
    }
    _syncMetrics();
    if (newDocument) {
      scrollController.jumpTo(0);
    } else {
      _restorePosition(anchor);
    }
    for (final listener in List.of(_listeners)) {
      listener();
    }
    return cmd;
  }

  /// Makes the selected source row visible in the composed viewport.
  void revealSelection() {
    final anchor = model.selectedAnchor;
    if (anchor == null) return;
    final top = _extents.offsetOf(blocks.indexOfRow(anchor.renderLine));
    final bottom =
        _extents.offsetOf(blocks.indexOfRow(anchor.renderLineEnd - 1)) + 1;
    final scroll = scrollController;
    if (top < scroll.offset || bottom - top > scroll.viewportExtent) {
      scroll.jumpTo(top);
    } else if (bottom > scroll.offset + scroll.viewportExtent) {
      scroll.jumpTo(bottom - scroll.viewportExtent);
    }
  }

  /// Scrolls to the header of a thread by identity, including unmapped threads.
  void revealThread(String id) {
    final index = blocks.indexOfThread(id);
    if (index != null) scrollController.jumpTo(_extents.offsetOf(index));
  }

  /// Observes model updates. Scrolling is observed on [scrollController].
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes a model observer.
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _syncMetrics() => scrollController.updateMetrics(
    viewportExtent: model.diff.height,
    contentExtent: _extents.totalHeight,
  );

  _ReviewPosition? _capturePosition() {
    if (blocks.length == 0) return null;
    final position = _extents.resolve(scrollController.offset);
    return switch (blocks[position.index]) {
      DiffReviewThreadBlock(:final placement) => _ReviewPosition(
        threadId: placement.thread.id,
        intraRow: position.intraRow,
        fallbackRow: placement.afterRow ?? blocks.layout.lines.length,
      ),
      DiffReviewCodeBlock(:final renderRow) => _codePosition(renderRow),
    };
  }

  _ReviewPosition _codePosition(int row) {
    final anchor = blocks.layout.anchorsAtRow(row).firstOrNull;
    return _ReviewPosition(
      source: anchor?.key,
      intraRow: anchor == null ? 0 : row - anchor.renderLine,
      fallbackRow: row,
    );
  }

  void _restorePosition(_ReviewPosition? position) {
    if (position == null ||
        blocks.length == 0 ||
        scrollController.thumbDragActive) {
      return;
    }
    final threadIndex = position.threadId == null
        ? null
        : blocks.indexOfThread(position.threadId!);
    if (threadIndex != null) {
      scrollController.jumpTo(
        _extents.offsetOf(threadIndex) +
            position.intraRow.clamp(0, _extents.heightAt(threadIndex) - 1),
      );
      return;
    }
    if (blocks.layout.lines.isEmpty) {
      scrollController.jumpTo(0);
      return;
    }
    final source = position.source;
    final anchor = source == null
        ? null
        : model.document.anchorIn(blocks.layout, source);
    final row = anchor == null
        ? position.fallbackRow.clamp(0, blocks.layout.lines.length - 1)
        : math.min(
            anchor.renderLine + position.intraRow,
            anchor.renderLineEnd - 1,
          );
    scrollController.jumpTo(_extents.offsetOf(blocks.indexOfRow(row)));
  }

  void _measureThread(int index, int height) {
    final ordinal = blocks.threadsBefore(index);
    final position = _capturePosition();
    if (!_extents.setThreadHeight(ordinal, height)) return;
    _syncMetrics();
    _restorePosition(position);
  }
}

class _ReviewPosition {
  const _ReviewPosition({
    this.threadId,
    this.source,
    required this.intraRow,
    required this.fallbackRow,
  });
  final String? threadId;
  final DiffCommentLineKey? source;
  final int intraRow;
  final int fallbackRow;
}

/// A bounded viewport for code and rich inline review threads.
///
/// Code is painted directly from the shared layout. Only visible thread widgets
/// are mounted and measured; scrolling never reparses or rebuilds code rows.
/// Comments participate in the same scroll extent as code, including when a
/// single comment is taller than the viewport.
///
/// [handleKeys] enables arrows/page/home/end scrolling, j/k source navigation,
/// h/l side switching, and v range selection. Disable it while a host editor
/// owns keyboard input. Width/height come from parent constraints when omitted.
///
/// {@category Widgets}
class DiffReviewViewport extends StatefulWidget {
  /// Creates a rich review viewport.
  DiffReviewViewport({
    required this.controller,
    required this.threadBuilder,
    this.width,
    this.height,
    this.handleKeys = true,
    this.mouseWheelDelta = 3,
    super.key,
  });

  /// Review state and the sole composed scroll controller.
  final DiffReviewController controller;

  /// Builds expanded bodies for visible threads.
  final DiffReviewThreadBuilder threadBuilder;

  /// Optional width in terminal columns.
  final int? width;

  /// Optional height in terminal rows.
  final int? height;

  /// Whether built-in navigation keys are enabled.
  final bool handleKeys;

  /// Number of composed rows per vertical wheel tick.
  final int mouseWheelDelta;

  @override
  State<DiffReviewViewport> createState() => _DiffReviewViewportState();
}

class _DiffReviewViewportState extends State<DiffReviewViewport> {
  bool _configuring = false;
  RenderObject? _viewport;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  void _attach(DiffReviewController controller) {
    controller.addListener(_changed);
    controller.scrollController.addListener(_scrolled);
  }

  void _detach(DiffReviewController controller) {
    controller.removeListener(_changed);
    controller.scrollController.removeListener(_scrolled);
  }

  void _changed() {
    if (!_configuring) setState(() {});
  }

  void _scrolled() => elementOf(widget)?.markNeedsPaintScrollOnly();

  @override
  Cmd? didUpdateWidget(covariant DiffReviewViewport oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _attach(widget.controller);
    }
    return super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _detach(widget.controller);
    super.dispose();
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) return _handleMouse(msg);
    if (!widget.handleKeys || msg is! KeyMsg) return null;
    final controller = widget.controller;
    final scroll = controller.scrollController;
    final key = msg.key;
    switch (key.type) {
      case KeyType.up:
        scroll.scrollBy(-1);
      case KeyType.down:
        scroll.scrollBy(1);
      case KeyType.pageUp:
        scroll.scrollBy(-scroll.viewportExtent);
      case KeyType.pageDown:
        scroll.scrollBy(scroll.viewportExtent);
      case KeyType.home:
        scroll.jumpTo(0);
      case KeyType.end:
        scroll.jumpTo(scroll.maxOffset);
      default:
        final DiffReviewMsg? action = key.isChar('j')
            ? const DiffReviewMoveMsg(1)
            : key.isChar('k')
            ? const DiffReviewMoveMsg(-1)
            : key.isChar('h')
            ? const DiffReviewSideMsg(DiffCommentSide.left)
            : key.isChar('l')
            ? const DiffReviewSideMsg(DiffCommentSide.right)
            : key.isChar('v')
            ? const DiffReviewToggleRangeMsg()
            : null;
        if (action == null) return null;
        final cmd = controller.update(action);
        controller.revealSelection();
        return cmd ?? Cmd.none();
    }
    return Cmd.none();
  }

  Cmd? _handleMouse(HitTestMouseMsg msg) {
    final viewport = _viewport;
    if (viewport == null) return null;
    final origin = globalOffset(viewport);
    final x = msg.event.x - origin.x;
    final y = msg.event.y - origin.y;
    if (x < 0 ||
        y < 0 ||
        x >= viewport.size.width ||
        y >= viewport.size.height) {
      return null;
    }
    final controller = widget.controller;
    final event = msg.event;
    if (event.button == MouseButton.wheelUp ||
        event.button == MouseButton.wheelDown) {
      controller.scrollController.scrollBy(
        event.button == MouseButton.wheelUp
            ? -widget.mouseWheelDelta
            : widget.mouseWheelDelta,
      );
      return Cmd.none();
    }
    if (event.button != MouseButton.left ||
        event.action != MouseAction.press ||
        controller.blocks.length == 0) {
      return null;
    }
    final offset = controller.scrollController.offset + y.floor();
    if (offset >= controller._extents.totalHeight) return null;
    final position = controller._extents.resolve(offset);
    final block = controller.blocks[position.index];
    if (block is! DiffReviewCodeBlock) return null;
    final columns = controller.model.diff.splitColumns;
    if (columns != null && x.floor() == columns.leftWidth) return null;
    final side = columns == null
        ? null
        : x < columns.leftWidth
        ? DiffCommentSide.left
        : DiffCommentSide.right;
    final anchor = controller.blocks.layout
        .anchorsAtRow(block.renderRow)
        .where((a) => side == null || a.side == side)
        .firstOrNull;
    if (anchor == null) return null;
    return controller.update(DiffReviewSelectMsg(anchor.key)) ?? Cmd.none();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final controller = widget.controller;
      final width =
          widget.width ??
          (constraints.hasBoundedWidth
              ? constraints.maxWidth.toInt()
              : controller.model.diff.width);
      final height =
          widget.height ??
          (constraints.hasBoundedHeight
              ? constraints.maxHeight.toInt()
              : controller.model.diff.height);
      if (width <= 0 || height <= 0) return SizedBox(width: 0, height: 0);
      _configuring = true;
      try {
        controller.update(
          DiffReviewPresentationMsg(width: width, height: height),
        );
        controller._syncMetrics();
      } finally {
        _configuring = false;
      }
      return SizedBox(
        width: width,
        height: height,
        child: _ReviewLazyViewport(
          controller: controller,
          threadBuilder: widget.threadBuilder,
          onRenderObject: (value) => _viewport = value,
        ),
      );
    },
  );
}

class _ReviewLazyViewport extends LazyRenderObjectWidget {
  _ReviewLazyViewport({
    required this.controller,
    required this.threadBuilder,
    required this.onRenderObject,
  });
  final DiffReviewController controller;
  final DiffReviewThreadBuilder threadBuilder;
  final void Function(RenderObject) onRenderObject;

  @override
  int get childCount => controller.blocks.length;

  @override
  Widget buildChild(BuildContext context, int index) {
    final block = controller.blocks[index] as DiffReviewThreadBlock;
    final placement = block.placement;
    final thread = placement.thread;
    final expanded = controller.model.expandedThreadIds.contains(thread.id);
    final theme = ThemeScope.of(context);
    Widget child = Column(
      key: ValueKey((
        controller.model.document.id,
        controller.model.document.revision,
        thread.id,
      )),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () =>
              controller.update(
                DiffReviewExpandMsg(thread.id, expanded: !expanded),
              ) ??
              Cmd.none(),
          child: Text(
            '${expanded ? '▾' : '▸'} ${thread.id} · ${thread.range.start.path}:${thread.range.start.line}'
            '${placement.status == DiffReviewThreadStatus.attached ? '' : ' · ${placement.status.name}'}',
            style: theme.labelSmall,
            softWrap: false,
          ),
        ),
        if (expanded) threadBuilder(context, placement),
      ],
    );
    final columns = controller.model.diff.splitColumns;
    if (columns != null &&
        placement.status == DiffReviewThreadStatus.attached) {
      child = Padding(
        padding: thread.range.start.side == DiffCommentSide.left
            ? EdgeInsets.only(right: columns.rightWidth + 1)
            : EdgeInsets.only(left: columns.leftWidth + 1),
        child: child,
      );
    }
    return child;
  }

  @override
  RenderObject createRenderObject() {
    final viewport = _RenderReviewViewport(controller);
    onRenderObject(viewport);
    return viewport;
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as _RenderReviewViewport).controller = controller;
    onRenderObject(renderObject);
  }

  @override
  Object view() => '';
}

class _RenderReviewViewport extends RenderBox implements LazyRenderObjectHost {
  _RenderReviewViewport(this.controller);
  DiffReviewController controller;
  LazyRenderObjectChildManager? _manager;
  final _cache =
      <int, ({RenderObject child, int width, List<String> rows, int height})>{};
  final _hits = <({RenderObject child, double top})>[];

  @override
  set childManager(LazyRenderObjectChildManager? manager) {
    _manager = manager;
    _cache.clear();
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    size = constraints.constrain(
      Size(
        controller.model.diff.width.toDouble(),
        controller.model.diff.height.toDouble(),
      ),
    );
    controller._syncMetrics();
  }

  @override
  String paint() {
    final height = size.height.toInt();
    final width = size.width.toInt();
    if (height <= 0 || width <= 0 || controller.blocks.length == 0) {
      _manager?.retainChildIndices({});
      _cache.clear();
      _hits.clear();
      return '';
    }
    var output = <String>[];
    final live = <int>{};
    // A second pass handles bottom clamping after a measured card shrinks.
    for (var pass = 0; pass < 2; pass++) {
      output = [];
      live.clear();
      _hits.clear();
      final origin = controller._extents.resolve(
        controller.scrollController.offset,
      );
      var intra = origin.intraRow;
      for (
        var i = origin.index;
        i < controller.blocks.length && output.length < height;
        i++
      ) {
        final block = controller.blocks[i];
        if (block is DiffReviewCodeBlock) {
          output.add(_codeRow(block.renderRow, width));
        } else {
          live.add(i);
          final child = _manager!.resolveRenderObject(i);
          var cached = _cache[i];
          if (cached == null ||
              !identical(cached.child, child) ||
              cached.width != width ||
              child.paintDirty) {
            child.layout(
              BoxConstraints(
                minWidth: width.toDouble(),
                maxWidth: width.toDouble(),
              ),
            );
            final text = child.paint();
            cached = (
              child: child,
              width: width,
              rows: text.split('\n'),
              height: math.max(1, child.size.height.round()),
            );
            _cache[i] = cached;
            child.clearPaintDirty();
          }
          controller._measureThread(i, cached.height);
          intra = intra.clamp(0, cached.height - 1);
          final top = output.length - intra;
          child.offset = Offset(0, top.toDouble());
          _hits.add((child: child, top: top.toDouble()));
          for (
            var row = intra;
            row < cached.height && output.length < height;
            row++
          ) {
            output.add(row < cached.rows.length ? cached.rows[row] : '');
          }
        }
        intra = 0;
      }
      final adjusted = controller._extents.resolve(
        controller.scrollController.offset,
      );
      if (adjusted.index == origin.index &&
          adjusted.intraRow == origin.intraRow) {
        break;
      }
    }
    _manager!.retainChildIndices(live);
    _cache.removeWhere((index, _) => !live.contains(index));
    while (output.length < height) {
      output.add('');
    }
    return suppressOverflowingTerminalGraphics(
      output.map((line) => cutAnsiByCells(line, 0, width)).join('\n'),
      height,
    );
  }

  String _codeRow(int row, int width) {
    final model = controller.model;
    final columns = model.diff.splitColumns;
    var text = controller.blocks.layout.lines[row];
    final overlays = <StyleRange>[];
    for (final anchor in controller.blocks.layout.anchorsAtRow(row)) {
      final counterpart = columns == null
          ? model.document.counterpart(anchor.key)
          : null;
      final selected =
          anchor.key == model.selected ||
          (counterpart != null && counterpart == model.selected);
      final range = model.rangeStart == null ? null : model.selection;
      final inRange =
          range != null &&
          (range.contains(anchor.key) ||
              (counterpart != null && range.contains(counterpart)));
      if (!selected && !inRange) continue;
      final start = columns != null && anchor.side == DiffCommentSide.right
          ? columns.leftWidth + 1
          : 0;
      final end = columns != null && anchor.side == DiffCommentSide.left
          ? columns.leftWidth
          : width;
      overlays.add(
        StyleRange(
          start,
          end,
          selected
              ? model.diff.styles.selectedCommentLine
              : model.diff.styles.commentRangeLine,
        ),
      );
    }
    if (overlays.isNotEmpty) {
      final padding = width - Style.visibleLength(text);
      if (padding > 0) text += ' ' * padding;
      text = overlayBackgroundRangesPreservingAnsi(text, overlays);
    }
    return text;
  }

  @override
  bool hitTest(
    HitTestResult result, {
    required double localX,
    required double localY,
  }) {
    if (localX < 0 ||
        localY < 0 ||
        localX >= size.width ||
        localY >= size.height) {
      return false;
    }
    for (final hit in _hits) {
      final y = localY - hit.top;
      if (y >= 0 && y < hit.child.size.height) {
        hit.child.hitTest(result, localX: localX, localY: y);
        break;
      }
    }
    result.add(HitTestEntry(this, localX: localX, localY: localY));
    return true;
  }
}
