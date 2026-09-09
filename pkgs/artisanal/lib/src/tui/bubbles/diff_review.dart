/// Source-anchored review state shared by TEA and widget hosts.
library;

import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'git_diff.dart';

/// An inclusive range on one side of one file.
///
/// {@category TUI}
final class DiffReviewRange {
  /// Creates a normalized range. Cross-file and cross-side ranges are rejected.
  factory DiffReviewRange(DiffCommentLineKey start, [DiffCommentLineKey? end]) {
    end ??= start;
    if (start.path != end.path ||
        start.side != end.side ||
        start.line <= 0 ||
        end.line <= 0) {
      throw ArgumentError(
        'A review range must use positive lines on one file and side.',
      );
    }
    return start.line <= end.line
        ? DiffReviewRange._(start, end)
        : DiffReviewRange._(end, start);
  }

  const DiffReviewRange._(this.start, this.end);

  /// First source position, inclusive.
  final DiffCommentLineKey start;

  /// Last source position, inclusive.
  final DiffCommentLineKey end;

  /// Whether this range spans more than one source line.
  bool get isRange => start != end;

  /// Whether [key] belongs to this source range.
  bool contains(DiffCommentLineKey key) =>
      key.path == start.path &&
      key.side == start.side &&
      key.line >= start.line &&
      key.line <= end.line;
}

/// A review thread's stable identity and attachment, independent of its UI.
///
/// Bodies, authors, network effects, and widget builders belong to the host,
/// keyed by [id]. A missing anchor is never approximated to a nearby line.
///
/// {@category TUI}
final class DiffReviewThread {
  /// Creates a thread descriptor.
  const DiffReviewThread({
    required this.id,
    required this.range,
    this.outdated = false,
  });

  /// Stable identity within a review document, not a rendered-row number.
  final String id;

  /// Source range this thread annotates.
  final DiffReviewRange range;

  /// Whether the provider identifies this attachment as belonging to old code.
  final bool outdated;
}

/// Whether a thread can be attached to the current patch.
enum DiffReviewThreadStatus {
  /// Every line in the source range is present.
  attached,

  /// At least one source position is absent from this patch.
  unmapped,

  /// The provider explicitly marked the attachment as outdated.
  outdated,
}

/// A thread's placement in one layout.
///
/// {@category TUI}
final class DiffReviewThreadPlacement {
  const DiffReviewThreadPlacement._(this.thread, this.status, this.afterRow);

  /// Original descriptor, including its stable identity and side.
  final DiffReviewThread thread;

  /// Explicit resolution result.
  final DiffReviewThreadStatus status;

  /// Last row of the annotated range's final aligned group; null unless attached.
  ///
  /// Includes the taller split panel, so an inline block cannot interrupt the
  /// other side's wrapped code. Multiple threads can follow the same row
  /// without sharing identity.
  final int? afterRow;
}

/// Immutable source index for a particular review document revision.
///
/// Context lines retain both old and new coordinates, even in unified view.
/// Presentation changes reuse this index; only patch replacement rebuilds it.
///
/// {@category TUI}
final class DiffReviewDocument {
  /// Snapshots parsed files and builds a source index independent of layout.
  DiffReviewDocument({
    required this.id,
    required this.revision,
    required Iterable<DiffFile> files,
  }) : files = List.unmodifiable(
         files.map(
           (file) => DiffFile(
             oldPath: file.oldPath,
             newPath: file.newPath,
             lines: List.unmodifiable(file.lines),
           ),
         ),
       ) {
    for (final file in this.files) {
      for (final line in file.lines) {
        if (line.type != DiffLineType.context &&
            line.type != DiffLineType.added &&
            line.type != DiffLineType.removed) {
          continue;
        }
        final left = line.oldLineNumber == null
            ? null
            : DiffCommentLineKey(
                path: file.oldPath,
                line: line.oldLineNumber!,
                side: DiffCommentSide.left,
              );
        final right = line.newLineNumber == null
            ? null
            : DiffCommentLineKey(
                path: file.newPath,
                line: line.newLineNumber!,
                side: DiffCommentSide.right,
              );
        if (left == null && right == null) continue;
        _rows.add((left: left, right: right));
        if (left != null) _keys.add(left);
        if (right != null) _keys.add(right);
        if (left != null && right != null) {
          _counterparts[left] = right;
          _counterparts[right] = left;
        }
      }
    }
    for (final key in _keys) {
      _keysByFileSide.putIfAbsent((key.path, key.side), () => []).add(key);
    }
    for (final keys in _keysByFileSide.values) {
      keys.sort((a, b) => a.line.compareTo(b.line));
    }
  }

  /// Provider identity, for example a pull request ID.
  final String id;

  /// Opaque revision token supplied by the host.
  final String revision;

  /// Parsed file snapshots.
  final List<DiffFile> files;

  final _keys = <DiffCommentLineKey>{};
  final _counterparts = <DiffCommentLineKey, DiffCommentLineKey>{};
  final _rows = <({DiffCommentLineKey? left, DiffCommentLineKey? right})>[];
  final _navigation = <DiffCommentSide, List<DiffCommentLineKey>>{};
  final _navigationIndices = <DiffCommentSide, Map<DiffCommentLineKey, int>>{};
  final _keysByFileSide =
      <(String, DiffCommentSide), List<DiffCommentLineKey>>{};

  /// Tests an exact source position, including its side.
  bool contains(DiffCommentLineKey key) => _keys.contains(key);

  /// The other source coordinate of the same context line, if any.
  DiffCommentLineKey? counterpart(DiffCommentLineKey key) => _counterparts[key];

  /// Source-order navigation, with one stop per parsed code line.
  ///
  /// Context uses [side]; additions and deletions use their available side.
  /// This order does not change with wrapping or presentation mode.
  List<DiffCommentLineKey> navigation(DiffCommentSide side) =>
      _navigation.putIfAbsent(
        side,
        () => List.unmodifiable({
          for (final row in _rows)
            if (side == DiffCommentSide.left)
              row.left ?? row.right!
            else
              row.right ?? row.left!,
        }),
      );

  /// Index of a source position in [navigation], or -1 when absent.
  int navigationIndex(DiffCommentSide side, DiffCommentLineKey key) =>
      _navigationIndices.putIfAbsent(side, () {
        final keys = navigation(side);
        return {for (var i = 0; i < keys.length; i++) keys[i]: i};
      })[key] ??
      -1;

  /// Resolves a source key in [layout], including left context in unified view.
  ///
  /// Only a known context counterpart may supply geometry. The source key
  /// itself remains unchanged; unrelated same-number lines are never used.
  DiffCommentAnchor? anchorIn(DiffLayout layout, DiffCommentLineKey key) {
    if (!contains(key)) return null;
    final exact = layout.anchorFor(key);
    if (exact != null) return exact;
    final other = counterpart(key);
    final anchor = other == null ? null : layout.anchorFor(other);
    if (anchor == null) return null;
    return DiffCommentAnchor(
      path: key.path,
      line: key.line,
      side: key.side,
      kind: anchor.kind,
      renderLine: anchor.renderLine,
      renderLineEnd: anchor.renderLineEnd,
      content: anchor.content,
    );
  }

  /// Source keys covered by [range], without inventing omitted context.
  Iterable<DiffCommentLineKey> keysIn(DiffReviewRange range) sync* {
    final keys = _keysByFileSide[(range.start.path, range.start.side)];
    if (keys == null) return;
    for (
      var i = _lowerBound(keys, range.start.line);
      i < keys.length && keys[i].line <= range.end.line;
      i++
    ) {
      yield keys[i];
    }
  }

  /// Whether the patch contains every source line of [range].
  ///
  /// Uses indexed bounds rather than scanning the document or enumerating
  /// arbitrarily large ranges supplied by a remote provider.
  bool covers(DiffReviewRange range) {
    final keys = _keysByFileSide[(range.start.path, range.start.side)];
    if (keys == null) return false;
    return _lowerBound(keys, range.end.line + 1) -
            _lowerBound(keys, range.start.line) ==
        range.end.line - range.start.line + 1;
  }

  static int _lowerBound(List<DiffCommentLineKey> keys, int line) {
    var low = 0;
    var high = keys.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (keys[mid].line < line) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

/// Semantic review actions. Hosts translate their own key maps into these.
sealed class DiffReviewMsg extends Msg {
  /// Creates a semantic review action.
  const DiffReviewMsg();
}

/// Selects an exact source position. Unknown positions are ignored.
final class DiffReviewSelectMsg extends DiffReviewMsg {
  /// Selects [key] if present in the document.
  const DiffReviewSelectMsg(this.key);

  /// Exact source position to select.
  final DiffCommentLineKey key;
}

/// Moves through source-order code lines, clamped to the document bounds.
final class DiffReviewMoveMsg extends DiffReviewMsg {
  /// Moves by [delta] source lines; zero is a no-op.
  const DiffReviewMoveMsg(this.delta);

  /// Signed number of source-order navigation stops.
  final int delta;
}

/// Switches to the other coordinate of a context line or aligned split row.
final class DiffReviewSideMsg extends DiffReviewMsg {
  /// Requests selection on [side] without guessing a nearby source line.
  const DiffReviewSideMsg(this.side);

  /// Requested side.
  final DiffCommentSide side;
}

/// Starts or finishes range selection at the selected source position.
final class DiffReviewToggleRangeMsg extends DiffReviewMsg {
  /// Toggles range selection. Does nothing without a selected line.
  const DiffReviewToggleRangeMsg();
}

/// Clears range selection while keeping the selected line.
final class DiffReviewClearRangeMsg extends DiffReviewMsg {
  /// Ends range selection without clearing the selected line.
  const DiffReviewClearRangeMsg();
}

/// Clears both selected line and range.
final class DiffReviewClearSelectionMsg extends DiffReviewMsg {
  /// Clears source selection and its fixed range endpoint.
  const DiffReviewClearSelectionMsg();
}

/// Changes expansion for one known thread.
final class DiffReviewExpandMsg extends DiffReviewMsg {
  /// Sets expansion for [threadId]. Unknown IDs are ignored.
  const DiffReviewExpandMsg(this.threadId, {required this.expanded});

  /// Stable identity of the thread to update.
  final String threadId;

  /// Whether the thread should display its expanded content.
  final bool expanded;
}

/// Replaces threads for one revision, rejecting stale asynchronous responses.
final class DiffReviewThreadsMsg extends DiffReviewMsg {
  /// Snapshots a provider's complete thread list for one document revision.
  DiffReviewThreadsMsg({
    required this.documentId,
    required this.revision,
    required Iterable<DiffReviewThread> threads,
  }) : threads = List.unmodifiable(threads);

  /// Document identity this response belongs to.
  final String documentId;

  /// Revision this response belongs to.
  final String revision;

  /// Replacement thread descriptors.
  final List<DiffReviewThread> threads;
}

/// Atomically replaces patch and threads.
///
/// A different document or revision clears interaction state. A same-revision
/// patch extension keeps valid source selection and known thread expansion.
final class DiffReviewLoadMsg extends DiffReviewMsg {
  /// Loads a patch and its thread descriptors as one update.
  DiffReviewLoadMsg({
    required this.documentId,
    required this.revision,
    required this.diff,
    Iterable<DiffReviewThread> threads = const [],
  }) : threads = List.unmodifiable(threads);

  /// Provider identity of the new document.
  final String documentId;

  /// Opaque source revision token of the new patch.
  final String revision;

  /// Parsed patch and its initial presentation.
  final GitDiffModel diff;

  /// Complete thread list for the replacement patch.
  final List<DiffReviewThread> threads;
}

/// Changes presentation without changing source identities or thread state.
final class DiffReviewPresentationMsg extends DiffReviewMsg {
  /// Updates non-null presentation settings.
  const DiffReviewPresentationMsg({
    this.width,
    this.height,
    this.viewMode,
    this.wrapLines,
  });

  /// Positive viewport width in terminal columns.
  final int? width;

  /// Positive viewport height in terminal rows.
  final int? height;

  /// Requested diff presentation mode.
  final DiffViewMode? viewMode;

  /// Whether long code lines wrap inside their panels.
  final bool? wrapLines;
}

/// TEA review interaction model with source-anchored selection and threads.
///
/// [view] is the base patch projection. Rich hosts consume [highlights] and
/// [threadPlacements] without changing the patch model or reparsing its text.
/// Thread payloads and drafts remain host-owned and should be keyed by thread
/// ID, not by the lifetime of mounted widgets.
///
/// {@category TUI}
final class DiffReviewModel extends ViewComponent {
  /// Creates a review for a loaded patch.
  factory DiffReviewModel({
    required String documentId,
    required String revision,
    required GitDiffModel diff,
    Iterable<DiffReviewThread> threads = const [],
  }) => DiffReviewModel._(
    DiffReviewDocument(id: documentId, revision: revision, files: diff.files),
    diff,
    _threadMap(threads),
    null,
    null,
    const {},
  );

  DiffReviewModel._(
    this.document,
    this.diff,
    this.threads,
    this.selected,
    this.rangeStart,
    this.expandedThreadIds,
  );

  /// Stable source index for the current revision.
  final DiffReviewDocument document;

  /// Current patch presentation and base viewport.
  final GitDiffModel diff;

  /// Thread descriptors indexed by identity, preserving provider order.
  final Map<String, DiffReviewThread> threads;

  /// Selected source key, independent of rendered rows.
  final DiffCommentLineKey? selected;

  /// Fixed source endpoint while range selection is active.
  final DiffCommentLineKey? rangeStart;

  /// Expanded thread identities, independent of widget mounting.
  final Set<String> expandedThreadIds;

  /// Current normalized selection, which may span omitted patch context.
  ///
  /// Use [commentTarget] when submitting a review comment.
  DiffReviewRange? get selection {
    final key = selected;
    return key == null ? null : DiffReviewRange(rangeStart ?? key, key);
  }

  /// A submit-ready source target, or null if selection crosses omitted context.
  DiffReviewRange? get commentTarget {
    final range = selection;
    return range != null && document.covers(range) ? range : null;
  }

  /// Selected source position resolved against the current layout.
  DiffCommentAnchor? get selectedAnchor =>
      selected == null ? null : document.anchorIn(diff.layout, selected!);

  /// Selection decorations; deriving these does not rerender the patch.
  late final List<DiffCommentLineHighlight> highlights = List.unmodifiable([
    if (rangeStart != null && selection != null)
      for (final key in document.keysIn(selection!))
        DiffCommentLineHighlight(
          key: key,
          kind: DiffCommentLineHighlightKind.range,
        ),
    if (selected != null)
      DiffCommentLineHighlight(
        key: selected!,
        kind: DiffCommentLineHighlightKind.selected,
      ),
  ]);

  /// Exact thread resolution for this layout, retaining both sides and IDs.
  late final List<DiffReviewThreadPlacement> threadPlacements =
      List.unmodifiable(
        threads.values.map((thread) {
          if (thread.outdated) {
            return DiffReviewThreadPlacement._(
              thread,
              DiffReviewThreadStatus.outdated,
              null,
            );
          }
          final range = thread.range;
          final last = document.anchorIn(diff.layout, range.end);
          if (!document.covers(range) || last == null) {
            return DiffReviewThreadPlacement._(
              thread,
              DiffReviewThreadStatus.unmapped,
              null,
            );
          }
          return DiffReviewThreadPlacement._(
            thread,
            DiffReviewThreadStatus.attached,
            (diff.layout.rowGroupEndAt(last.renderLine) ?? last.renderLineEnd) -
                1,
          );
        }),
      );

  @override
  Cmd? init() => null;

  @override
  String view() => diff.view();

  DiffReviewModel _select(DiffCommentLineKey? key) {
    if (key != null && !document.contains(key)) return this;
    final start =
        key != null &&
            rangeStart?.path == key.path &&
            rangeStart?.side == key.side
        ? rangeStart
        : null;
    if (key == selected && start == rangeStart) return this;
    return DiffReviewModel._(
      document,
      diff,
      threads,
      key,
      start,
      expandedThreadIds,
    );
  }

  @override
  (DiffReviewModel, Cmd?) update(Msg msg) {
    switch (msg) {
      case DiffReviewSelectMsg(:final key):
        return (_select(key), null);
      case DiffReviewClearSelectionMsg():
        return (_select(null), null);
      case DiffReviewMoveMsg(:final delta):
        if (delta == 0) return (this, null);
        final keys = document.navigation(
          selected?.side ?? DiffCommentSide.right,
        );
        if (keys.isEmpty) return (this, null);
        final current = selected == null
            ? -1
            : document.navigationIndex(selected!.side, selected!);
        final index = current < 0
            ? (delta > 0 ? 0 : keys.length - 1)
            : (current + delta).clamp(0, keys.length - 1);
        return (_select(keys[index]), null);
      case DiffReviewSideMsg(:final side):
        final key = selected;
        if (key == null || key.side == side) return (this, null);
        final counterpart = document.counterpart(key);
        if (counterpart != null) return (_select(counterpart), null);
        final anchor = selectedAnchor;
        if (anchor == null || diff.viewMode != DiffViewMode.sideBySide) {
          return (this, null);
        }
        for (final candidate in diff.layout.anchors) {
          if (candidate.renderLine == anchor.renderLine &&
              candidate.side == side) {
            return (_select(candidate.key), null);
          }
        }
        return (this, null);
      case DiffReviewToggleRangeMsg():
        if (selected == null) return (this, null);
        return (
          DiffReviewModel._(
            document,
            diff,
            threads,
            selected,
            rangeStart == null ? selected : null,
            expandedThreadIds,
          ),
          null,
        );
      case DiffReviewClearRangeMsg():
        if (rangeStart == null) return (this, null);
        return (
          DiffReviewModel._(
            document,
            diff,
            threads,
            selected,
            null,
            expandedThreadIds,
          ),
          null,
        );
      case DiffReviewExpandMsg(:final threadId, :final expanded):
        if (!threads.containsKey(threadId) ||
            expandedThreadIds.contains(threadId) == expanded) {
          return (this, null);
        }
        final ids = {...expandedThreadIds};
        expanded ? ids.add(threadId) : ids.remove(threadId);
        return (
          DiffReviewModel._(
            document,
            diff,
            threads,
            selected,
            rangeStart,
            Set.unmodifiable(ids),
          ),
          null,
        );
      case DiffReviewThreadsMsg():
        if (msg.documentId != document.id ||
            msg.revision != document.revision) {
          return (this, null);
        }
        final next = _threadMap(msg.threads);
        return (
          DiffReviewModel._(
            document,
            diff,
            next,
            selected,
            rangeStart,
            Set.unmodifiable(expandedThreadIds.where(next.containsKey)),
          ),
          null,
        );
      case DiffReviewLoadMsg():
        final next = DiffReviewModel(
          documentId: msg.documentId,
          revision: msg.revision,
          diff: msg.diff,
          threads: msg.threads,
        );
        if (document.id != msg.documentId ||
            document.revision != msg.revision) {
          return (next, null);
        }
        final key = selected != null && next.document.contains(selected!)
            ? selected
            : null;
        final start =
            key != null &&
                rangeStart != null &&
                next.document.contains(rangeStart!)
            ? rangeStart
            : null;
        return (
          DiffReviewModel._(
            next.document,
            next.diff,
            next.threads,
            key,
            start,
            Set.unmodifiable(expandedThreadIds.where(next.threads.containsKey)),
          ),
          null,
        );
      case DiffReviewPresentationMsg():
        final width = msg.width ?? diff.width;
        final height = msg.height ?? diff.height;
        final mode = msg.viewMode ?? diff.viewMode;
        final wrap = msg.wrapLines ?? diff.wrapLines;
        if (width <= 0 || height <= 0) {
          throw ArgumentError('Review viewport dimensions must be positive.');
        }
        final geometryChanged =
            width != diff.width ||
            mode != diff.viewMode ||
            wrap != diff.wrapLines;
        if (!geometryChanged && height == diff.height) return (this, null);
        final next = geometryChanged
            ? diff
                  .copyWith(
                    width: width,
                    height: height,
                    viewMode: mode,
                    wrapLines: wrap,
                    horizontalOffset: mode != diff.viewMode ? 0 : null,
                    viewport: diff.viewport.copyWith(
                      width: width,
                      height: height,
                    ),
                  )
                  .rerender()
            : diff.copyWith(
                height: height,
                viewport: diff.viewport.copyWith(height: height),
              );
        return (
          DiffReviewModel._(
            document,
            next,
            threads,
            selected,
            rangeStart,
            expandedThreadIds,
          ),
          null,
        );
      default:
        final (next, cmd) = diff.update(msg);
        return (
          identical(next, diff)
              ? this
              : DiffReviewModel._(
                  document,
                  next,
                  threads,
                  selected,
                  rangeStart,
                  expandedThreadIds,
                ),
          cmd,
        );
    }
  }

  static Map<String, DiffReviewThread> _threadMap(
    Iterable<DiffReviewThread> threads,
  ) {
    final result = <String, DiffReviewThread>{};
    for (final thread in threads) {
      if (thread.id.isEmpty || result.containsKey(thread.id)) {
        throw ArgumentError('Review thread IDs must be nonempty and unique.');
      }
      result[thread.id] = thread;
    }
    return Map.unmodifiable(result);
  }
}
