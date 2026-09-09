# Diff review rebuild

## Architecture

The target is a TEA-owned review document with stable source anchors, one
layout representation, and a virtualized rich widget surface. Core owns diff
semantics and interaction; `artisanal_widgets` owns widget measurement, focus,
and rich thread rendering. GitHub remains an application adapter.

## Implemented: shared row geometry

`GitDiffModel.layout` exposes an immutable `DiffLayout`. Its terminal rows and
comment anchors are emitted together by the unified, pretty, and split
renderers. This replaces the independent anchor-height traversal. Exact
source-key lookup returns null for absent positions rather than silently
attaching comments to another line.

Viewport-only copies retain the layout snapshot. Width, presentation, source,
and highlight changes invalidate it. Existing `renderedLines`, `commentAnchors`,
and viewport APIs remain available during migration.

This is a foundation, not the completed virtualized review implementation.
Rendering still eagerly produces ANSI rows, and the widget's existing inline
comment scrolling path is unchanged.

## Implemented: source-anchored TEA review state

`package:artisanal/git_diff.dart` now exports `DiffReviewModel`. It hosts a
`GitDiffModel` and a `DiffReviewDocument` source index identified by document ID
and revision. Both context coordinates are retained independently of layout,
including old/new line-number and path differences in renamed files.

Semantic messages handle selection, source-order movement, side switching,
range selection, presentation changes, and thread expansion. Selection and
expansion updates reuse the patch model and its layout, without parsing or
rendering. `view()` remains the base patch view: selection decorations and
thread placements are exposed separately for richer hosts. The old widget and
GitHub interaction state have not yet migrated to this model.

Thread descriptors carry a stable ID, a source range, and an explicit outdated
flag. They intentionally do not own GitHub payloads or widget children.
Resolution distinguishes attached, unmapped, and outdated threads; separate
left/right threads remain separate even when they follow the same row.
Attachments follow the final aligned row group of the range, including the
taller split panel so a thread cannot interrupt its continuation rows. Indexed source-range
coverage rejects ranges crossing omitted patch context without scanning the
whole document for each thread.

Lifecycle rules:

- Presentation changes preserve source selection, ranges, and expansion.
- Crossing file or side boundaries cancels an incompatible selection range.
- `selection` describes the range; `commentTarget` is null if it includes
  unavailable source lines and must be checked before submission.
- Changing document ID or revision clears interaction state.
- Same-revision patch replacement retains only still-present source selection
  and thread IDs. A thread refresh prunes expansion for removed threads.
- Thread responses tagged with a different document ID or revision are ignored.
- Hosts retain bodies, submission effects, and drafts outside mounted widgets.
  Scope draft storage to document/revision as well as thread identity.

Example host update:

```dart
var review = DiffReviewModel(
  documentId: 'pull-request-42',
  revision: 'base-sha..head-sha',
  diff: GitDiffModel(width: 100, height: 30).setDiff(patch),
);

(review, _) = review.update(DiffReviewMoveMsg(1));
(review, _) = review.update(DiffReviewToggleRangeMsg());
(review, _) = review.update(DiffReviewMoveMsg(1));
final target = review.commentTarget; // null if the range crosses omitted context
```

## Remaining implementation stages

1. Extend the source document with explicit hunk identities and
   unavailable-content states.
2. The mixed sequence is implemented as `DiffReviewBlocks`: it stores only
   thread insertion positions, derives code slots on demand, and retains
   unmapped/outdated threads after the patch. Connect it to widget measurement.
3. Compose code and threads through one variable-height virtual viewport,
   reusing existing list infrastructure where appropriate. Preserve stable
   block identity plus intra-block offset as measurements change.
4. Move GitHub integration off rendered-row comment mapping and height
   estimates. Preserve left/right thread identity and explicitly show unmapped
   or outdated comments.
5. Add full review workflow tests and benchmarks for large patches, tall
   threads, expansion, resize, asynchronous content, and scrollbar dragging.

## Performance acceptance rules

- Scrolling must not parse patches or build every offscreen comment.
- Selection should invalidate visible decorations rather than rerender the
  complete document.
- Rendering, hit testing, reveal, and split-panel placement share geometry.
- Comment rows participate in the same scroll extent as code.
- Expanding or measuring content above the viewport preserves the reader's
  stable content anchor.
