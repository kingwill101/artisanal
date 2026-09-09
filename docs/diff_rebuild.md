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

Rendering still eagerly produces ANSI rows. The new review viewport below
virtualizes their display and rich thread widgets; the legacy viewer's inline
comment scrolling path remains unchanged until consumers migrate.

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

## Implemented: virtualized review widgets

`package:artisanal_widgets/widgets.dart` exports `DiffReviewController` and
`DiffReviewViewport`. The controller hosts the TEA review model and owns one
`WidgetScrollController`: its offsets include both code and comment rows.
Do not combine these offsets with the base patch model's viewport offsets.

The viewport paints visible ANSI code rows directly and mounts only visible
thread widgets through the framework's lazy child manager. A sparse extent
index stores thread heights rather than allocating a widget or extent entry
for every code row. Unmeasured threads initially occupy one estimated row;
the total scroll extent becomes more accurate as threads are visited.
Visible thread bodies are measured and cached, including asynchronous size
changes. Source/thread identity and intra-block position preserve the reader's
location when measured content above it grows or shrinks.

The host supplies expanded content through `threadBuilder(context, placement)`.
Keep fetched bodies and editable drafts outside these lazily mounted widgets,
scoped by document, revision, and thread ID. The built-in header toggles
expansion in the TEA model. Attached split-view threads use the same panel
geometry as the code renderer; narrow fallback, unmapped, and outdated threads
use the full width.

Arrow/page/home/end keys scroll composed rows; `j`/`k` move source selection,
`h`/`l` switch sides, and `v` toggles a range. Set `handleKeys: false` while a
host editor owns the keyboard. Mouse selection and thread widgets share the
render tree's hit testing.

Regression tests cover tall threads, asynchronous growth/shrink, expansion,
clicking code below comments, narrow split fallback, and a 10,000-line patch
where a distant jump builds only the visited thread bodies. These are
bounded-work checks, not terminal frame-time benchmarks.

## Implemented: GitHub thread adapter

The demo's `GithubPullRequestReviewComment` preserves multiline starts,
`in_reply_to_id`, and whether a fallback position belongs to the original
revision. `GithubDiffReviewThreads` converts these into core thread descriptors
and immutable host-owned body lists, grouped by root comment ID rather than
source position. Old-side rename paths come from the patch file pairs.
Repository-relative paths are kept literally, including `a/` or `b/` directories.

Outdated threads stay outdated even if their original line exists in the current
patch. Missing source lines become unmapped; no nearest-line fallback is used.
Orphan replies and unsupported cross-side ranges remain in an explicit host
collection rather than receiving invented anchors. The parser still excludes
comments with no usable current or original line; file-level comments need a
separate attachment representation.

This adapter is tested independently but is not yet wired into the dashboard or
single-PR view. Those screens still use the legacy mapping and controllers.

## Remaining implementation stages

1. Extend the source document with explicit hunk identities and
   unavailable-content states.
2. Move GitHub integration off rendered-row comment mapping and height
   estimates. Preserve left/right thread identity and explicitly show unmapped
   or outdated comments.
3. Add full review workflow tests and benchmarks for large patches, tall
   threads, expansion, resize, asynchronous content, and scrollbar dragging.

## Performance acceptance rules

- Scrolling must not parse patches or build every offscreen comment.
- Selection should invalidate visible decorations rather than rerender the
  complete document.
- Rendering, hit testing, reveal, and split-panel placement share geometry.
- Comment rows participate in the same scroll extent as code.
- Expanding or measuring content above the viewport preserves the reader's
  stable content anchor.
