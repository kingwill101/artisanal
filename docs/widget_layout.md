# Predictable widget layout

Artisanal widgets measure positions and sizes in terminal cells. A layout has
three distinct pieces of information:

1. **Requested size:** what a widget asks for.
2. **Parent constraints:** the minimum and maximum space it may use.
3. **Allocated size:** the resolved size used to lay out children and paint.

A request is not permission to exceed the parent. Resolve it within the parent's
interval before calculating child space. Do not infer available child space from
the original request after the outer widget has been clamped.

## Boxes and their children

`Container` resolves its outer size first. Padding and borders consume space
inside the box; margins consume space outside that decorated box but within the
parent's allocation.

For example, a requested 40-cell container under a 28-cell maximum, with one-cell
padding and a one-cell border on each side, has:

- Allocated outer width: **28**
- Child width: **24**, not 36

Explicit dimensions also respect parent minimums. A two-cell request under a
ten-cell minimum receives ten cells.

`SizedBox` uses the resolved dimensions for both its child constraints and its
painted output. `ConstrainedBox` adds limits within the parent's limits:

- `maxWidth: 20` means “no more than 20,” not “exactly 20.”
- `minWidth: 20` asks for at least 20, subject to parent limits.
- Tight constraints request one exact size, again subject to parent limits.
- `BoxConstraints.enforce(parent)` resolves conflicting valid intervals at the
  nearest parent bound instead of producing a minimum greater than a maximum.

Container alignment deliberately loosens the child's minimums within the
allocated inner area so the content can be positioned naturally.

## Application roots

`WidgetApp` supplies a tight viewport-sized root. This behavior is unchanged.
Consequently, putting a small `SizedBox` directly at the root does not override
the viewport's minimum size.

For a smaller panel, explicitly provide a loose host:

```dart
Align(
  alignment: Alignment.topLeft,
  child: Container(
    width: 40,
    height: 10,
    child: Text('A bounded panel'),
  ),
)
```

Use `Center` when the panel should be centered. The host occupies the viewport;
the child receives loose constraints bounded by that viewport. If the viewport
shrinks below 40 columns, the panel and its child are constrained accordingly.

**Migration:** code that depended on a root box reporting the viewport size
while painting a smaller requested size should add an explicit host. Do not make
parent constraints invalid to preserve that discrepancy.

## Flex allocation

`Row` and `Column` apply their explicit extents before measuring flex children.
They subtract fixed child extents and gaps, then distribute whole terminal cells.

- `Expanded` / tight `Flexible` consumes its allocation.
- Loose `Flexible` has a proportional upper bound and may use less.
- Loose caps retain floored proportional shares. The remaining budget is split
  among tight children using rounded cumulative boundaries in child order.
- All-tight children consume the entire available integer budget. For 80 cells
  at weights 1:2, allocations are **27 and 53**, not 26 and 53.
- Layout, positioning, and paint use the same measured child extents. Unused
  loose capacity is not silently redistributed while painting.

Non-flex children still size naturally along the main axis. A column containing
more non-flex content than fits can overflow; it does not silently shrink all
children like a browser flex layout.

For a header/body/footer screen, bound the body explicitly:

```dart
Column(
  mainAxisSize: MainAxisSize.max,
  children: [
    Text('Release overview'),
    Expanded(
      child: ScrollArea(
        child: Column(
          children: [
            Text('Long content goes here'),
            Text('The body scrolls instead of pushing the footer away'),
          ],
        ),
      ),
    ),
    Text('q quit · / search'),
  ],
)
```

## Visibility is not a size request

`SizedBox.shrink()` requests zero size, but a tight parent can require more.
It is not a substitute for hiding content. Navigator offstage entries now use
explicit paint and pointer suppression while retaining mounted state.

## Lists and rendered rows

A single newline between two item strings joins their rows; it does not add a
blank row. List content extents, visible ranges, and hit-test offsets use the
same rule. For an explicit empty row between items, use `separator: '\n\n'`.

## Parent-aware builders

`LayoutBuilder` receives the constraints its immediate render parent supplies
during layout. Padding, borders, explicit dimensions, and flex allocation have
already affected those constraints. For example, inside a 24-cell container
with two cells of padding on each side, its maximum width is 20—not the terminal
width.

The callback runs again when constraints, widget configuration, or an inherited
dependency changes. Keyed children keep their state across compatible rebuilds.
Initialization commands for children first mounted during layout run through
the normal command loop after layout, without waiting for another input event.

An axis can legitimately be unbounded, such as the main axis of a non-flex child
in a row. Check `hasBoundedWidth` / `hasBoundedHeight` before treating maxima as
finite dimensions. Builders should describe children, not recursively invoke
layout themselves.

**Migration:** use `MediaQuery` when a decision intentionally depends on the
whole terminal viewport. `LayoutBuilder` no longer substitutes viewport
dimensions for parent constraints.

## Alignment geometry

`Align` resolves its own allocation before laying out its child. An implicit
dimension fills a bounded parent axis and shrink-wraps an unbounded axis;
explicit dimensions still respect parent minimum and maximum bounds.

Alignment uses the child's allocated size, including reserved blank space, not
just the number of visible characters it paints. Sparse paint is fitted to that
child allocation before positioning, so text and hit regions share one origin.
Cell-centering uses consistent integer rounding.

A mounted `Align.view()` uses its existing render object. A standalone view has
no parent constraints and uses the corresponding unconstrained sizing path.

## Stack clipping and positioning

Stack painting and hit testing are bounded by its allocated rectangle.
Positioned children may extend beyond it, but clipped cells cannot receive
pointer hits. Negative offsets are supported and rounded as signed cell
positions, rather than clamped to zero.

Opposite insets, such as `left` and `right`, stretch a child against the
**allocated** stack size after parent constraints apply. `StackFit.loose`
loosens child minima, `expand` fills bounded axes, and `passthrough` retains
the effective constraints.

Only `Overflow.clip` is supported by the current stack compositor.
`Overflow.visible` now throws `UnsupportedError` rather than silently clipping.
Use an ancestor `Overlay` for popups that need to extend beyond a component.

Fractional dimensions are quantized for terminal painting. Prefer integer-cell
dimensions when exact boundary alignment is important.

## Testing a layout

Check allocated render-object rectangles and child constraints, not only whether
a substring appears in the output. Important cases include:

- Parent smaller or larger than the child's requested size.
- Padding, border, or margins consuming most of the allocation.
- Unequal flex weights, one spare cell, and mixed tight/loose children.
- Resizing the same mounted tree.
- Painting, scroll metrics, and pointer positions agreeing with measured bounds.

Run the layout regression suite from the repository root:

```sh
dart test pkgs/artisanal_widgets/test/layout
```
