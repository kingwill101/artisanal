library;

/// Typed inline elements (chips) anchored to document ranges.
///
/// Plain text buffers cannot express "the image under the cursor": this
/// module adds that concept without rendering opinions. Elements carry a
/// stable id, an open-ended [kind], and a grapheme range; hosts map ids to
/// sidecar records (image attachments, file refs, paste payloads) and
/// hit-test the cursor to drive overlays, modals, and submit filtering.
///
/// Offset maintenance follows the same rule as extmarks and placeholders:
/// insertions shift, deletions shrink overlaps and drop fully covered
/// elements (deleting a chip's text deletes the chip). Reconciliation
/// against live ids at submit boundaries keeps deleted chips out of sends.

/// Well-known element kinds. Kinds are open-ended strings; hosts may add
/// their own alongside these.
const inlineElementImage = 'image';
const inlineElementPaste = 'paste';
const inlineElementFileRef = 'file-ref';

/// One typed span in a document.
final class InlineElement {
  const InlineElement({
    required this.id,
    required this.kind,
    required this.startOffset,
    required this.endOffset,
  });

  final int id;
  final String kind;
  final int startOffset;
  final int endOffset;

  int get length => endOffset - startOffset;
  bool get isEmpty => startOffset >= endOffset;

  /// Whether [offset] is on the chip (`start <= offset < end`).
  bool containsOffset(int offset) =>
      offset >= startOffset && offset < endOffset;

  InlineElement normalized() => startOffset <= endOffset
      ? this
      : InlineElement(
          id: id,
          kind: kind,
          startOffset: endOffset,
          endOffset: startOffset,
        );
}

/// Owns a document's live elements: ids, hit-testing, and offset tracking.
final class InlineElementStore {
  int _nextId = 1;
  final Map<int, InlineElement> _elements = <int, InlineElement>{};

  /// Creates an element over `[startOffset, endOffset)` and returns its id.
  int create({
    required String kind,
    required int startOffset,
    required int endOffset,
  }) {
    final id = _nextId++;
    _elements[id] = InlineElement(
      id: id,
      kind: kind,
      startOffset: startOffset,
      endOffset: endOffset,
    ).normalized();
    return id;
  }

  bool delete(int id) => _elements.remove(id) != null;
  InlineElement? get(int id) => _elements[id];
  bool get isEmpty => _elements.isEmpty;

  /// Moves/resizes the element, preserving its id and kind.
  /// Returns false when [id] is unknown.
  bool updateRange({
    required int id,
    required int startOffset,
    required int endOffset,
  }) {
    final current = _elements[id];
    if (current == null) return false;
    _elements[id] = InlineElement(
      id: id,
      kind: current.kind,
      startOffset: startOffset,
      endOffset: endOffset,
    ).normalized();
    return true;
  }

  List<InlineElement> all() => _sorted(_elements.values);

  List<InlineElement> ofKind(String kind) =>
      _sorted(_elements.values.where((element) => element.kind == kind));

  Set<int> get liveIds => Set<int>.unmodifiable(_elements.keys);

  void clear() => _elements.clear();

  /// Element owning [offset], if any. On-chip wins: an offset owned by
  /// several overlapping elements resolves to the narrowest.
  InlineElement? elementAt(int offset) {
    InlineElement? best;
    for (final element in _elements.values) {
      if (!element.containsOffset(offset)) continue;
      if (best == null || element.length < best.length) best = element;
    }
    return best;
  }

  /// Element of [kind] owning [offset], or `null`.
  InlineElement? elementAtOfKind(int offset, String kind) {
    InlineElement? best;
    for (final element in _elements.values) {
      if (element.kind != kind || !element.containsOffset(offset)) continue;
      if (best == null || element.length < best.length) best = element;
    }
    return best;
  }

  /// Element of [kind] ending exactly at [offset] (cursor resting on the
  /// chip's right edge), or `null`.
  InlineElement? elementEndingAtOfKind(int offset, String kind) {
    final candidates = _elements.values
        .where(
          (element) =>
              element.kind == kind && element.endOffset == offset,
        )
        .toList(growable: false)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
    return candidates.isEmpty ? null : candidates.last;
  }

  void applyInsertion({required int offset, required int length}) {
    if (length <= 0) return;
    for (final entry in _elements.entries.toList(growable: false)) {
      final element = entry.value;
      if (element.startOffset >= offset) {
        _elements[entry.key] = InlineElement(
          id: element.id,
          kind: element.kind,
          startOffset: element.startOffset + length,
          endOffset: element.endOffset + length,
        );
      } else if (element.endOffset > offset) {
        _elements[entry.key] = InlineElement(
          id: element.id,
          kind: element.kind,
          startOffset: element.startOffset,
          endOffset: element.endOffset + length,
        );
      }
    }
  }

  void applyDeletion({required int startOffset, required int endOffset}) {
    var start = startOffset;
    var end = endOffset;
    if (start > end) {
      final next = start;
      start = end;
      end = next;
    }
    final length = end - start;
    if (length <= 0) return;
    final drop = <int>[];
    for (final entry in _elements.entries.toList(growable: false)) {
      final element = entry.value;
      if (element.endOffset <= start) continue;
      if (element.startOffset >= end) {
        _elements[entry.key] = InlineElement(
          id: element.id,
          kind: element.kind,
          startOffset: element.startOffset - length,
          endOffset: element.endOffset - length,
        );
        continue;
      }
      if (element.startOffset >= start && element.endOffset <= end) {
        drop.add(entry.key);
        continue;
      }
      if (element.startOffset < start && element.endOffset > end) {
        _elements[entry.key] = InlineElement(
          id: element.id,
          kind: element.kind,
          startOffset: element.startOffset,
          endOffset: element.endOffset - length,
        );
        continue;
      }
      if (element.startOffset < start) {
        _elements[entry.key] = InlineElement(
          id: element.id,
          kind: element.kind,
          startOffset: element.startOffset,
          endOffset: start,
        );
      } else {
        _elements[entry.key] = InlineElement(
          id: element.id,
          kind: element.kind,
          startOffset: start,
          endOffset: element.endOffset - length,
        );
      }
    }
    for (final id in drop) {
      _elements.remove(id);
    }
  }

  void applyReplacement({
    required int startOffset,
    required int endOffset,
    required int insertLength,
  }) {
    var start = startOffset;
    var end = endOffset;
    if (start > end) {
      final next = start;
      start = end;
      end = next;
    }
    applyDeletion(startOffset: start, endOffset: end);
    applyInsertion(offset: start, length: insertLength);
  }

  List<InlineElement> _sorted(Iterable<InlineElement> elements) {
    final result = elements.toList(growable: false);
    result.sort((a, b) {
      final start = a.startOffset.compareTo(b.startOffset);
      if (start != 0) return start;
      return a.id.compareTo(b.id);
    });
    return result;
  }
}

/// Drops sidecar records whose element id is no longer live.
///
/// Mirrors the submit-time reconcile: deleting a chip's text deletes the
/// chip, and reconciling at cleanup boundaries keeps orphans out of sends.
/// Returns the removed records for temp-file cleanup.
List<V> reconcileExternalRecords<V>(
  Map<int, V> records,
  Set<int> liveIds,
) {
  final removed = <V>[];
  for (final id in records.keys.toList(growable: false)) {
    if (!liveIds.contains(id)) removed.add(records.remove(id) as V);
  }
  return removed;
}
