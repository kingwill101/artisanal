import 'package:artisanal/git_diff.dart';
import 'package:artisanal/tui.dart' show Msg, Model;
import 'package:test/test.dart';

const _patch = '''
diff --git a/old.dart b/new.dart
--- a/old.dart
+++ b/new.dart
@@ -10,3 +20,3 @@
 context
-before
+after
 last
@@ -100,1 +110,1 @@
 distant
''';

DiffCommentLineKey _key(
  int line, {
  DiffCommentSide side = DiffCommentSide.right,
  String? path,
}) => DiffCommentLineKey(
  path: path ?? (side == DiffCommentSide.left ? 'old.dart' : 'new.dart'),
  line: line,
  side: side,
);

DiffReviewThread _thread(
  String id,
  int line, {
  DiffCommentSide side = DiffCommentSide.right,
  int? end,
  bool outdated = false,
}) => DiffReviewThread(
  id: id,
  range: DiffReviewRange(_key(line, side: side), _key(end ?? line, side: side)),
  outdated: outdated,
);

DiffReviewModel _review({
  DiffViewMode mode = DiffViewMode.unified,
  Iterable<DiffReviewThread> threads = const [],
}) => DiffReviewModel(
  documentId: 'pr-1',
  revision: 'base..head',
  diff: GitDiffModel(width: 40, height: 5, viewMode: mode).setDiff(_patch),
  threads: threads,
);

DiffReviewModel _send(DiffReviewModel model, Msg msg) {
  final (next, cmd) = model.update(msg);
  expect(cmd, isNull);
  return next;
}

final class _UnknownMsg extends Msg {
  const _UnknownMsg();
}

void main() {
  group('DiffReviewDocument', () {
    test(
      'indexes both context coordinates and rename paths without layout',
      () {
        final model = _review();
        final doc = model.document;
        final left = _key(10, side: DiffCommentSide.left);
        expect(doc.contains(left), isTrue);
        expect(doc.counterpart(left), _key(20));
        expect(doc.contains(_key(10)), isFalse);
        expect(doc.counterpart(_key(11, side: DiffCommentSide.left)), isNull);
        final projected = doc.anchorIn(model.diff.layout, left)!;
        expect(projected.key, left);
        expect(
          projected.renderLine,
          model.diff.layout.anchorFor(_key(20))!.renderLine,
        );
      },
    );

    test(
      'navigation has one stop per source line, independent of wrapping',
      () {
        final doc = _review().document;
        expect(doc.navigation(DiffCommentSide.right), [
          _key(20),
          _key(11, side: DiffCommentSide.left),
          _key(21),
          _key(22),
          _key(110),
        ]);
        expect(doc.navigationIndex(DiffCommentSide.right, _key(21)), 2);
        expect(doc.navigationIndex(DiffCommentSide.right, _key(999)), -1);
        expect(
          () => doc.navigation(DiffCommentSide.right).clear(),
          throwsUnsupportedError,
        );
      },
    );

    test('range coverage rejects omitted context and unknown files', () {
      final doc = _review().document;
      expect(doc.covers(DiffReviewRange(_key(20), _key(22))), isTrue);
      expect(doc.covers(DiffReviewRange(_key(22), _key(110))), isFalse);
      expect(doc.covers(DiffReviewRange(_key(1, path: 'missing'))), isFalse);
      expect(doc.covers(DiffReviewRange(_key(20), _key(1000000000))), isFalse);
      expect(doc.keysIn(DiffReviewRange(_key(22), _key(110))), [
        _key(22),
        _key(110),
      ]);
    });

    test('snapshots caller-owned parsed lists', () {
      final lines = [
        const DiffLine(
          type: DiffLineType.added,
          content: 'hello',
          newLineNumber: 1,
        ),
      ];
      final files = [
        DiffFile(oldPath: '/dev/null', newPath: 'added', lines: lines),
      ];
      final doc = DiffReviewDocument(id: 'a', revision: 'b', files: files);
      files.clear();
      lines.clear();
      expect(doc.files.single.lines, hasLength(1));
      expect(doc.contains(_key(1, path: 'added')), isTrue);
      expect(() => doc.files.clear(), throwsUnsupportedError);
      expect(() => doc.files.single.lines.clear(), throwsUnsupportedError);
    });
  });

  group('DiffReviewRange', () {
    test('normalizes reversed endpoints', () {
      final range = DiffReviewRange(_key(22), _key(20));
      expect(range.start, _key(20));
      expect(range.end, _key(22));
      expect(range.isRange, isTrue);
      expect(range.contains(_key(21)), isTrue);
      expect(range.contains(_key(21, side: DiffCommentSide.left)), isFalse);
    });

    test('rejects cross-file, cross-side, and invalid line ranges', () {
      expect(() => DiffReviewRange(_key(0)), throwsArgumentError);
      expect(
        () => DiffReviewRange(_key(20), _key(21, path: 'other')),
        throwsArgumentError,
      );
      expect(
        () => DiffReviewRange(
          _key(20),
          _key(21, path: 'new.dart', side: DiffCommentSide.left),
        ),
        throwsArgumentError,
      );
    });
  });

  group('DiffReviewModel selection', () {
    test(
      'mode changes reset split horizontal offset but preserve source selection',
      () {
        final diff = GitDiffModel(
          width: 40,
          viewMode: DiffViewMode.sideBySide,
          wrapLines: false,
        ).setDiff(_patch).copyWith(horizontalOffset: 4).rerender();
        var model = DiffReviewModel(
          documentId: 'pr',
          revision: '1',
          diff: diff,
        );
        model = _send(model, DiffReviewSelectMsg(_key(21)));
        model = _send(
          model,
          const DiffReviewPresentationMsg(viewMode: DiffViewMode.pretty),
        );
        expect(model.diff.horizontalOffset, 0);
        expect(model.selected, _key(21));
      },
    );

    test('is a TEA model with a base patch view and unknown-message no-op', () {
      final model = _review();
      expect(model, isA<Model>());
      expect(model.init(), isNull);
      expect(model.view(), model.diff.view());
      expect(_send(model, const _UnknownMsg()), same(model));
      expect(_send(model, DiffReviewSelectMsg(_key(999))), same(model));
    });

    test('selection and expansion never rerender the patch', () {
      final initial = _review(threads: [_thread('one', 21)]);
      var model = _send(initial, DiffReviewSelectMsg(_key(21)));
      model = _send(model, const DiffReviewExpandMsg('one', expanded: true));
      expect(model.diff, same(initial.diff));
      expect(model.diff.layout, same(initial.diff.layout));
      expect(model.document, same(initial.document));
      expect(model.highlights.single.key, _key(21));
      expect(initial.selected, isNull);
      expect(initial.expandedThreadIds, isEmpty);
    });

    test('movement starts at an edge and clamps', () {
      final initial = _review();
      final first = _send(initial, const DiffReviewMoveMsg(1));
      expect(first.selected, _key(20));
      expect(_send(first, const DiffReviewMoveMsg(-1)), same(first));
      final last = _send(first, const DiffReviewMoveMsg(100));
      expect(last.selected, _key(110));
      expect(_send(last, const DiffReviewMoveMsg(1)), same(last));
      expect(_send(initial, const DiffReviewMoveMsg(-1)).selected, _key(110));
      expect(_send(initial, const DiffReviewMoveMsg(0)), same(initial));
    });

    test(
      'context side switch uses actual coordinates, not equal line numbers',
      () {
        var model = _send(_review(), DiffReviewSelectMsg(_key(20)));
        model = _send(model, const DiffReviewSideMsg(DiffCommentSide.left));
        expect(model.selected, _key(10, side: DiffCommentSide.left));
        expect(model.selectedAnchor!.key, model.selected);
        expect(model.selectedAnchor!.content, 'context');
      },
    );

    test('split replacement side switch uses the aligned row', () {
      var model = _send(
        _review(mode: DiffViewMode.sideBySide),
        DiffReviewSelectMsg(_key(11, side: DiffCommentSide.left)),
      );
      model = _send(model, const DiffReviewSideMsg(DiffCommentSide.right));
      expect(model.selected, _key(21));
      final unified = _send(
        _review(),
        DiffReviewSelectMsg(_key(11, side: DiffCommentSide.left)),
      );
      expect(
        _send(unified, const DiffReviewSideMsg(DiffCommentSide.right)),
        same(unified),
      );
    });

    test(
      'range endpoints normalize and omitted context cannot be submitted',
      () {
        var model = _send(_review(), DiffReviewSelectMsg(_key(22)));
        model = _send(model, const DiffReviewToggleRangeMsg());
        model = _send(model, DiffReviewSelectMsg(_key(20)));
        expect(model.selection!.start, _key(20));
        expect(model.selection!.end, _key(22));
        expect(model.commentTarget, isNotNull);
        expect(
          model.highlights.where(
            (h) => h.kind == DiffCommentLineHighlightKind.range,
          ),
          hasLength(3),
        );
        model = _send(model, DiffReviewSelectMsg(_key(110)));
        expect(model.selection, isNotNull);
        expect(model.commentTarget, isNull);
        model = _send(model, const DiffReviewClearRangeMsg());
        expect(model.rangeStart, isNull);
        expect(model.commentTarget!.start, _key(110));
      },
    );

    test('changing side or file cancels an incompatible range', () {
      var model = _send(_review(), DiffReviewSelectMsg(_key(20)));
      model = _send(model, const DiffReviewToggleRangeMsg());
      model = _send(model, const DiffReviewSideMsg(DiffCommentSide.left));
      expect(model.rangeStart, isNull);
      expect(model.selection!.isRange, isFalse);
      model = _send(model, const DiffReviewClearSelectionMsg());
      expect(model.selected, isNull);
      expect(model.highlights, isEmpty);
      expect(_send(model, const DiffReviewToggleRangeMsg()), same(model));
    });

    test(
      'presentation retains source selection, range, and thread expansion',
      () {
        var model = _send(
          _review(mode: DiffViewMode.sideBySide, threads: [_thread('one', 21)]),
          DiffReviewSelectMsg(_key(10, side: DiffCommentSide.left)),
        );
        model = _send(model, const DiffReviewToggleRangeMsg());
        model = _send(model, const DiffReviewExpandMsg('one', expanded: true));
        final next = _send(
          model,
          const DiffReviewPresentationMsg(
            width: 25,
            viewMode: DiffViewMode.unified,
            wrapLines: true,
          ),
        );
        expect(next.document, same(model.document));
        expect(next.selected, model.selected);
        expect(next.selectedAnchor!.key, model.selected);
        expect(next.rangeStart, model.rangeStart);
        expect(next.expandedThreadIds, {'one'});
        expect(next.diff.layout, isNot(same(model.diff.layout)));
      },
    );

    test(
      'height-only changes reuse layout and invalid dimensions are rejected',
      () {
        final model = _review();
        final next = _send(model, const DiffReviewPresentationMsg(height: 9));
        expect(next.diff.layout, same(model.diff.layout));
        expect(next.diff.viewport.height, 9);
        expect(_send(model, const DiffReviewPresentationMsg()), same(model));
        expect(
          () => model.update(const DiffReviewPresentationMsg(width: 0)),
          throwsArgumentError,
        );
      },
    );

    test('empty documents have no navigation or selection', () {
      final model = DiffReviewModel(
        documentId: 'empty',
        revision: '1',
        diff: GitDiffModel(),
      );
      expect(_send(model, const DiffReviewMoveMsg(1)), same(model));
      expect(model.commentTarget, isNull);
      expect(model.threadPlacements, isEmpty);
    });
  });

  group('DiffReviewModel threads and revision lifecycle', () {
    test(
      'short-side threads follow the taller split panel without interrupting code',
      () {
        final diff = GitDiffModel(
          width: 40,
          viewMode: DiffViewMode.sideBySide,
        ).setDiff(_patch.replaceFirst('+after', '+${'x' * 60}'));
        final left = diff.layout.anchorFor(
          _key(11, side: DiffCommentSide.left),
        )!;
        final right = diff.layout.anchorFor(_key(21))!;
        expect(right.renderLineEnd, greaterThan(left.renderLineEnd));
        final model = DiffReviewModel(
          documentId: 'pr',
          revision: '1',
          diff: diff,
          threads: [
            _thread('left', 11, side: DiffCommentSide.left),
            _thread('right', 21),
          ],
        );
        expect(model.threadPlacements.map((p) => p.afterRow), [
          right.renderLineEnd - 1,
          right.renderLineEnd - 1,
        ]);
        expect(diff.layout.rowGroupEndAt(left.renderLine), right.renderLineEnd);
        expect(diff.layout.rowGroupEndAt(0), isNull);
      },
    );

    test(
      'left context threads remain attached in unified and narrow split views',
      () {
        for (final mode in DiffViewMode.values) {
          var model = _review(
            mode: mode,
            threads: [_thread('old-context', 10, side: DiffCommentSide.left)],
          );
          model = _send(model, const DiffReviewPresentationMsg(width: 10));
          final placement = model.threadPlacements.single;
          expect(placement.status, DiffReviewThreadStatus.attached);
          expect(
            placement.thread.range.start,
            _key(10, side: DiffCommentSide.left),
          );
          final source = model.document.anchorIn(
            model.diff.layout,
            _key(10, side: DiffCommentSide.left),
          )!;
          expect(placement.afterRow, source.renderLineEnd - 1);
        }
      },
    );

    test('same-row opposite-side threads retain separate identities', () {
      final model = _review(
        mode: DiffViewMode.sideBySide,
        threads: [
          _thread('left', 11, side: DiffCommentSide.left),
          _thread('right', 21),
          _thread('another-right', 21),
        ],
      );
      final placements = model.threadPlacements;
      expect(placements.map((p) => p.thread.id), [
        'left',
        'right',
        'another-right',
      ]);
      expect(placements.map((p) => p.afterRow).toSet(), hasLength(1));
      expect(
        placements.every((p) => p.status == DiffReviewThreadStatus.attached),
        isTrue,
      );
    });

    test('missing, omitted-range, and outdated anchors are explicit', () {
      final model = _review(
        threads: [
          _thread('missing', 999),
          _thread('gap', 22, end: 110),
          _thread('old', 21, outdated: true),
        ],
      );
      expect(model.threadPlacements.map((p) => p.status), [
        DiffReviewThreadStatus.unmapped,
        DiffReviewThreadStatus.unmapped,
        DiffReviewThreadStatus.outdated,
      ]);
      expect(model.threadPlacements.every((p) => p.afterRow == null), isTrue);
    });

    test('thread follows the last wrapped row of its range', () {
      final patch = _patch.replaceFirst(' last', ' ${'x' * 90}');
      final diff = GitDiffModel(width: 30).setDiff(patch);
      final model = DiffReviewModel(
        documentId: 'pr',
        revision: '1',
        diff: diff,
        threads: [_thread('range', 20, end: 22)],
      );
      final anchor = diff.layout.anchorFor(_key(22))!;
      expect(anchor.renderLineEnd - anchor.renderLine, greaterThan(1));
      expect(model.threadPlacements.single.afterRow, anchor.renderLineEnd - 1);
    });

    test(
      'validates identities and snapshots caller-owned thread collections',
      () {
        final thread = _thread('one', 21);
        expect(() => _review(threads: [thread, thread]), throwsArgumentError);
        expect(() => _review(threads: [_thread('', 21)]), throwsArgumentError);
        final input = [thread];
        final model = _review(threads: input);
        input.clear();
        expect(model.threads.keys, ['one']);
        expect(() => model.threads.clear(), throwsUnsupportedError);
        expect(
          () => model.expandedThreadIds.add('one'),
          throwsUnsupportedError,
        );
        expect(
          _send(model, const DiffReviewExpandMsg('unknown', expanded: true)),
          same(model),
        );
      },
    );

    test(
      'thread refresh prunes removed expansion and rejects stale responses',
      () {
        var model = _review(threads: [_thread('one', 21), _thread('two', 22)]);
        model = _send(model, const DiffReviewExpandMsg('one', expanded: true));
        model = _send(model, const DiffReviewExpandMsg('two', expanded: true));
        expect(
          _send(
            model,
            DiffReviewThreadsMsg(
              documentId: 'pr-1',
              revision: 'old',
              threads: [],
            ),
          ),
          same(model),
        );
        expect(
          _send(
            model,
            DiffReviewThreadsMsg(
              documentId: 'other',
              revision: 'base..head',
              threads: [],
            ),
          ),
          same(model),
        );
        model = _send(
          model,
          DiffReviewThreadsMsg(
            documentId: 'pr-1',
            revision: 'base..head',
            threads: [_thread('two', 22)],
          ),
        );
        expect(model.expandedThreadIds, {'two'});
      },
    );

    test('document/revision replacement resets selection and expansion', () {
      var model = _send(
        _review(threads: [_thread('one', 21)]),
        DiffReviewSelectMsg(_key(21)),
      );
      model = _send(model, const DiffReviewToggleRangeMsg());
      model = _send(model, const DiffReviewExpandMsg('one', expanded: true));
      for (final identity in [('pr-1', 'new-head'), ('pr-2', 'base..head')]) {
        final next = _send(
          model,
          DiffReviewLoadMsg(
            documentId: identity.$1,
            revision: identity.$2,
            diff: model.diff,
            threads: [_thread('one', 21)],
          ),
        );
        expect(next.selected, isNull);
        expect(next.rangeStart, isNull);
        expect(next.expandedThreadIds, isEmpty);
      }
    });

    test(
      'same-revision replacement retains only still-valid interaction state',
      () {
        var model = _send(
          _review(threads: [_thread('one', 21)]),
          DiffReviewSelectMsg(_key(21)),
        );
        model = _send(model, const DiffReviewExpandMsg('one', expanded: true));
        final same = _send(
          model,
          DiffReviewLoadMsg(
            documentId: 'pr-1',
            revision: 'base..head',
            diff: model.diff,
            threads: model.threads.values,
          ),
        );
        expect(same.selected, model.selected);
        expect(same.expandedThreadIds, {'one'});
        final empty = _send(
          model,
          DiffReviewLoadMsg(
            documentId: 'pr-1',
            revision: 'base..head',
            diff: GitDiffModel(),
          ),
        );
        expect(empty.selected, isNull);
        expect(empty.rangeStart, isNull);
        expect(empty.expandedThreadIds, isEmpty);
      },
    );

    test(
      'same-revision removal of range start preserves the selected endpoint',
      () {
        var model = _send(_review(), DiffReviewSelectMsg(_key(20)));
        model = _send(model, const DiffReviewToggleRangeMsg());
        model = _send(model, DiffReviewSelectMsg(_key(22)));
        final replacement = GitDiffModel().setDiff('''
diff --git a/old.dart b/new.dart
--- a/old.dart
+++ b/new.dart
@@ -12,1 +22,1 @@
 last
''');
        model = _send(
          model,
          DiffReviewLoadMsg(
            documentId: 'pr-1',
            revision: 'base..head',
            diff: replacement,
          ),
        );
        expect(model.selected, _key(22));
        expect(model.rangeStart, isNull);
        expect(model.commentTarget!.isRange, isFalse);
      },
    );

    test('selecting another file clears an incompatible range', () {
      final diff = GitDiffModel().setDiff('''
$_patch
diff --git a/other.dart b/other.dart
--- a/other.dart
+++ b/other.dart
@@ -1,1 +1,1 @@
 other
''');
      var model = DiffReviewModel(documentId: 'pr', revision: '1', diff: diff);
      model = _send(model, DiffReviewSelectMsg(_key(20)));
      model = _send(model, const DiffReviewToggleRangeMsg());
      model = _send(model, DiffReviewSelectMsg(_key(1, path: 'other.dart')));
      expect(model.rangeStart, isNull);
      expect(model.commentTarget!.start.path, 'other.dart');
    });
  });
}
