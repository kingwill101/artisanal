/// Internal sparse extent index for the review viewport.
library;

import 'package:artisanal/git_diff.dart';

/// Known one-row code extents plus measured/estimated thread extents.
///
/// The Fenwick tree stores only thread heights minus one. Storage is O(T);
/// height updates and offset queries are O(log T). Offset resolution uses a
/// binary search over mixed slots without constructing or measuring children.
class ReviewExtents {
  ReviewExtents(this.blocks)
    : _heights = List.filled(blocks.threadCount, 1),
      _tree = List.filled(blocks.threadCount + 1, 0);

  final DiffReviewBlocks blocks;
  final List<int> _heights;
  final List<int> _tree;

  int get totalHeight => offsetOf(blocks.length);

  int offsetOf(int index) => index + _prefix(blocks.threadsBefore(index));

  int heightAt(int index) {
    final block = blocks[index];
    return block is DiffReviewThreadBlock
        ? _heights[blocks.threadsBefore(index)]
        : 1;
  }

  bool setThreadHeight(int ordinal, int height) {
    if (height < 1) {
      throw ArgumentError.value(height, 'height', 'Must be positive');
    }
    final delta = height - _heights[ordinal];
    if (delta == 0) return false;
    _heights[ordinal] = height;
    for (var i = ordinal + 1; i < _tree.length; i += i & -i) {
      _tree[i] += delta;
    }
    return true;
  }

  ({int index, int intraRow}) resolve(int offset) {
    if (blocks.length == 0) return (index: 0, intraRow: 0);
    final target = offset.clamp(0, totalHeight - 1);
    var low = 0;
    var high = blocks.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (offsetOf(mid) <= target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    final index = low - 1;
    return (index: index, intraRow: target - offsetOf(index));
  }

  int _prefix(int count) {
    var sum = 0;
    for (var i = count; i > 0; i -= i & -i) {
      sum += _tree[i];
    }
    return sum;
  }
}
