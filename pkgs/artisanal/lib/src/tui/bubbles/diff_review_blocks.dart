/// Mixed code/thread ordering without building a widget or object per code row.
library;

import 'diff_review.dart';
import 'git_diff.dart';

/// A display slot in a review. Heights are owned by the rendering host.
///
/// {@category TUI}
sealed class DiffReviewBlock {
  const DiffReviewBlock();
}

/// One already-laid-out terminal code row.
final class DiffReviewCodeBlock extends DiffReviewBlock {
  const DiffReviewCodeBlock._(this.renderRow);

  /// Index in [DiffLayout.lines], not a comment-expanded scroll offset.
  final int renderRow;
}

/// One independently identified thread, whether attached, outdated, or unmapped.
final class DiffReviewThreadBlock extends DiffReviewBlock {
  const DiffReviewThreadBlock._(this.placement);

  /// Source attachment and stable thread identity.
  final DiffReviewThreadPlacement placement;
}

/// Immutable, sparsely indexed mixed review document.
///
/// Only thread insertions are stored. Code slots are derived on demand in
/// O(log T), where T is the number of threads. Construction does not enumerate
/// code rows, instantiate code blocks, or rerender the patch.
///
/// Unmapped and outdated threads follow the patch rather than disappearing or
/// being attached to guessed source lines. Same-row threads retain input order.
///
/// {@category TUI}
final class DiffReviewBlocks {
  /// Builds an ordering for the model's current layout and threads.
  DiffReviewBlocks(DiffReviewModel model) : layout = model.diff.layout {
    final placements = model.threadPlacements.indexed.toList()
      ..sort((a, b) {
        final rowA = a.$2.afterRow == null
            ? layout.lines.length
            : a.$2.afterRow!;
        final rowB = b.$2.afterRow == null
            ? layout.lines.length
            : b.$2.afterRow!;
        final byRow = rowA.compareTo(rowB);
        return byRow != 0 ? byRow : a.$1.compareTo(b.$1);
      });
    for (final (order, (_, placement)) in placements.indexed) {
      final beforeRow = placement.afterRow == null
          ? layout.lines.length
          : placement.afterRow! + 1;
      _beforeRows.add(beforeRow);
      _threadPositions.add(beforeRow + order);
      _threads.add(DiffReviewThreadBlock._(placement));
      _threadById[placement.thread.id] = order;
    }
  }

  /// Shared code layout; code strings are never copied by this index.
  final DiffLayout layout;
  final _beforeRows = <int>[];
  final _threadPositions = <int>[];
  final _threads = <DiffReviewThreadBlock>[];
  final _threadById = <String, int>{};

  /// Number of mixed display slots, before host measurement.
  int get length => layout.lines.length + _threads.length;

  /// Number of thread slots.
  int get threadCount => _threads.length;

  /// Block at [index], with code blocks materialized only when requested.
  DiffReviewBlock operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', length);
    final before = threadsBefore(index);
    if (before < threadCount && _threadPositions[before] == index) {
      return _threads[before];
    }
    return DiffReviewCodeBlock._(index - before);
  }

  /// Number of thread slots strictly before a mixed slot index.
  ///
  /// [index] may equal [length], for computing a total content extent.
  int threadsBefore(int index) {
    RangeError.checkValueInInterval(index, 0, length, 'index');
    return _lowerBound(_threadPositions, index);
  }

  /// Mixed slot index of a thread by stable identity, or null when absent.
  int? indexOfThread(String id) {
    final ordinal = _threadById[id];
    return ordinal == null ? null : _threadPositions[ordinal];
  }

  /// Thread at a sparse thread ordinal, in display order.
  DiffReviewThreadBlock threadAt(int ordinal) => _threads[ordinal];

  /// Mixed slot index of the code row at [renderRow].
  int indexOfRow(int renderRow) {
    RangeError.checkValidIndex(renderRow, layout.lines, 'renderRow');
    return renderRow + _lowerBound(_beforeRows, renderRow + 1);
  }

  static int _lowerBound(List<int> values, int target) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (values[mid] < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
