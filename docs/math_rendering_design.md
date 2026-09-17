# Terminal math rendering: dependency and design investigation

Status: implemented for the core construct set. This describes an independent
Artisanal implementation; no Bestie source is used.

## Recommendation

Evaluate `katex_dart` 0.1.1 as the TeX parser and font-based layout frontend.
Implement TeX-specific layout in `artisanal`. Put generic cell-buffer drawing
and composition in `ultraviolet` when the facility is not math-specific.
Keep presentation and interaction in `artisanal_widgets`.

Do not add another general-purpose canvas or parallel cell-buffer system.
The missing math abstraction is a terminal math fragment: existing cell
storage plus a baseline row, composed using math-specific layout rules.

## Existing primitives to reuse

| Need | Existing implementation | Use in math |
| --- | --- | --- |
| Offscreen composition | [`Canvas`](../pkgs/ultraviolet/lib/src/uv/canvas.dart#L30) | Cell-native surface with dirty tracking disabled, drawing, serialization, and disposal |
| Cell storage and wide-character handling | [`Buffer`](../pkgs/ultraviolet/lib/src/uv/buffer.dart#L381), [`Line`](../pkgs/ultraviolet/lib/src/uv/buffer.dart#L267) | Keep existing wide-cell placeholder and overwrite semantics |
| Fragment placement | [`Buffer.draw`](../pkgs/ultraviolet/lib/src/uv/buffer.dart#L1083) | Place a composed fragment into a target screen |
| Width measurement | [`WidthMethod` and Unicode helpers](../pkgs/ultraviolet/lib/src/unicode/width.dart#L51) | Measure glyphs using the target's terminal-width policy |
| Styling and ANSI input | [`StyledString`](../pkgs/ultraviolet/lib/src/uv/styled_string.dart#L35) | Reuse existing styled-text painting rather than another escape parser |
| Rectangular enclosures | [`UvBorder`](../pkgs/ultraviolet/lib/src/uv/border.dart#L38) | Frame boxed expressions |
| Diagonal drawing | [`drawLine`](../pkgs/artisanal/lib/src/charting/util.dart#L222) | Consider for slanted strokes; do not treat its chart-oriented glyph policy as mathematical layout |
| ANSI output | [`Canvas.render`](../pkgs/ultraviolet/lib/src/uv/canvas.dart#L120) | Serialize only after composition, retaining dimensions separately |

Use direct `UvStyle` values for cells. Artisanal `Style` renders ANSI strings;
there is no complete direct `Style` to `UvStyle` bridge. Keep any necessary
style adaptation in Artisanal, not in UV.

Existing string layout helpers align rows, not mathematical baselines. Add
baseline metadata to the math fragment rather than treating ordinary
vertical alignment as a substitute.

Important integration contracts:

- `Buffer.draw` rejects an out-of-bounds destination rectangle; it does not
  provide partial clipping. Allocate fitting composition surfaces and handle
  viewport clipping explicitly.
- `Canvas.render` trims trailing spaces. Preserve width and baseline in the
  fragment instead of reconstructing them from serialized text.
- Respect borrowed versus owned cells (`setCell` versus `setCellOwned`) and
  dispose temporary canvases. Do not bypass pooled-cell ownership.
- Paint fraction bars directly into rows. A horizontal text rule component
  is not needed for every mathematical stroke.

UV's raster renderer has pixel/font baseline metrics, but those are for
captures and exports, not a reusable terminal mathematical baseline model.
No existing KaTeX box adapter or general SVG path rasterizer was found in
Artisanal or UV.

## Package split: UV versus Artisanal

UV should own reusable cell-buffer facilities. Artisanal should own TeX
parsing, math layout, and markdown integration. Do not put KaTeX types,
TeX commands, or math-specific baseline composition in UV.

A UV addition is justified when it is useful to charts, markdown, overlays,
or other cell composition, and can be specified without TeX vocabulary.

### Candidate UV facilities

1. **Clipped buffer blit.** [`Buffer.draw`](../pkgs/ultraviolet/lib/src/uv/buffer.dart#L1083)
   currently no-ops if the destination rectangle is not fully inside the
   target. Fill and scissor already clip. A clipped blit would let callers
   compose fragments into viewports instead of allocating oversized surfaces.
   Preserve existing all-or-nothing behavior unless callers opt in.
2. **Untrimmed buffer serialization.** [`Line.render`](../pkgs/ultraviolet/lib/src/uv/buffer.dart#L371)
   and [`Buffer.render`](../pkgs/ultraviolet/lib/src/uv/buffer.dart#L821)
   trim trailing spaces. That is useful for ordinary TUI output, but it
   discards trailing cells that are part of a fragment's width. Add an
   explicit untrimmed path; do not change the current default.
3. **Simple cell-buffer strokes.** Horizontal, vertical, and optional
   diagonal runs of a caller-supplied glyph and `UvStyle` belong in UV.
   Artisanal's [`drawLine`](../pkgs/artisanal/lib/src/charting/util.dart#L222)
   is chart-oriented: it infers box-drawing characters from Bresenham steps.
   UV should provide the generic stroke; Artisanal can keep chart-specific
   glyph selection.
4. **Baseline-aware fragment later, if needed.** If several non-math
   consumers need a cell fragment plus a row index for alignment, UV can
   own that generic wrapper. Until then, keep math fragments in Artisanal.

Do not move into UV:

- KaTeX box walking, TeX delimiters, or math syntax.
- Fraction, script, radical, or delimiter composition rules.
- A `Style` to `UvStyle` converter. Color bridging already lives in
  Artisanal; full style conversion remains an Artisanal concern.
- SVG path rasterization as a math dependency. Pixel raster remains an
  optional capture/export path.

## Dependency findings

The published [katex_dart 0.1.1 package](https://pub.dev/packages/katex_dart/versions/0.1.1)
is pure Dart, requires Dart `^3.11.0`, and has runtime dependencies on `args`
and `meta`. It has no Flutter or browser dependency. Its code is MIT licensed;
bundled font assets have separate SIL OFL notices.

The actual public entrypoint is:

```dart
import 'package:katex_dart/katex_dart.dart';

final box = renderToBox(
  r'\frac{a+b}{c}',
  options: const KatexOptions(
    displayMode: true,
    strict: 'ignore',
    maxSize: 100,
  ),
);
```

This is an API example, not a proposed production size limit. The package's
README uses a different import path; the published public barrel above was
verified by running a probe.

`renderToBox` performs parsing and layout. The semantic parse AST is not
exported by that barrel. Avoid depending on private `src/` APIs for inline
linearization.

| Public box type | Information provided | Terminal responsibility |
| --- | --- | --- |
| `GlyphNode` | Unicode code point, font identity, size, metrics | Terminal width, style, glyph substitution where needed |
| `HBox` | Horizontal children sharing a baseline | Pack terminal fragments and align their baselines |
| `KernNode` | Horizontal spacing in em | Convert spacing without losing meaningful operator separation |
| `VList` | Children with resolved downward baseline shifts | Allocate rows without collapsing distinct mathematical parts |
| `RuleNode` | Width, height, depth, dashed flag | Draw visible bars; preserve invisible layout struts without painting them |
| `SpanNode` | Children, classes, color, size multiplier | Recognize math structure and apply supported styling |
| `EncloseNode` | Child and enclosure notations | Borders/strikes using existing drawing primitives |
| `SvgPathNode` | Named shape, SVG path, dimensions | Terminal equivalents for radicals, arrows, and stretchy shapes |
| `ImageNode` | Source, alternative text, dimensions | Explicit fallback; never implicitly fetch external content |

Dimensions are in em and may include negative depths. Resolved vertical
shifts are positive downward. These are font layout values, not terminal
column/row counts.

Keep the dependency behind a local adapter and cover the consumed box
structures with tests. Although `SpanNode.classes` is public, the shapes of
the generated trees remain a compatibility concern for this early-version
dependency.

## Why a generic coordinate conversion is insufficient

The executable probe demonstrated:

- `\hat{x}` and `\vec{v}` can place the accent and base at the same baseline.
  The font/path draws the accent above that baseline; a terminal glyph cannot
  simply use the same cell.
- Matrix rows contain zero-width `RuleNode` struts. These are spacing, not
  visible strokes.
- A root contains an SVG radical shape. Treating every node as ordinary text
  would lose the radical and its overbar.
- Enlarged parentheses still carry the character `(` or `)`, with a larger
  font identity. Terminal output must construct a tall delimiter explicitly.
- `\text{你好}` produces glyph nodes, but their font advances are not their
  terminal widths. Existing Unicode terminal-width handling must be used.

Use mathematical structure to constrain cell placement, then use UV to
paint the result. Merely rounding every em coordinate can overwrite content
or change the meaning of an equation.

## Output paths

### Inline

Produce one readable line suitable for paragraphs and table cells.
Use Unicode scripts where representable and explicit notation otherwise;
retain grouping for compound fractions and roots. Unsupported structures
must fall back visibly rather than silently discard information.

### Display

Produce a cell-native fragment with a baseline. Fractions, scripts, operator
limits, radicals, and matrices compose before painting. Do not wrap rows of
an already-laid-out equation as ordinary prose.

ANSI output can serialize the resulting buffer. Widget output should use
existing cell/content integration, with centering and overflow handled by
layout rather than inserted selectable padding.

### Optional graphical output

The dependency also exposes SVG output and glyph paths. That is a possible
future graphical backend, not the default terminal path: it does not replace
selectable text, terminal compatibility, or the need for a textual fallback.

## Markdown integration

Extend the existing shared markdown parser, not only its renderer:

- Recognize `\(…\)` inline and `\[…\]` / `$$…$$` display math before ordinary
  markdown escaping or block interpretation.
- Keep single-dollar math an explicit compatibility choice to avoid
  interpreting currency.
- Capture display bodies raw so blank lines and leading minus signs survive.
- Keep code spans and fences outside math recognition.
- Preserve source for malformed/unsupported expressions and copy behavior.
- Distinguish incomplete streaming input from settled invalid input.

Parser changes and rendering must be shared by ANSI and widget consumers.
Math-specific widget interaction belongs in `artisanal_widgets`.

## Resource and fallback policy

`KatexOptions` exposes `maxSize`, but that is not a bound on total expression
size, tree depth, output cells, or execution time. Production integration
needs explicit input, traversal, and output allocation limits.

The internal parser defaults to an expansion limit of 1000; the public
options do not expose `maxExpand` or `trust`. Do not import private settings
just to change those values. A hard execution deadline would require an
appropriate execution boundary, not a timer around synchronous parsing.

Catch the public `ParseError` for invalid TeX. Rendering unsupported box
shapes is a separate failure mode and needs an explicit fallback. Do not
claim success while dropping a mathematical term.

Use a quiet strictness mode: the dependency's warning mode calls `print`,
which is inappropriate inside a full-screen TUI.

## Validation performed

The published archive's SHA-256 was checked against pub.dev:
`9ffb18e394a3817f4cdfa04fd497ca30d3e3b45661e3e17f7705b8ae68dd5be9`.

An isolated scratch probe used the published package with the workspace's
existing dependencies; no dependency or lockfile was changed.

- Eleven valid expressions produced box trees: scripts, fractions, roots,
  tall delimiters, sums with limits, matrices, two accent forms, enclosures,
  CJK text, and colors.
- Two invalid expressions produced typed `ParseError`s.
- The same probe compiled to JavaScript. This verifies compile compatibility,
  not browser rendering or runtime behavior.

No terminal math adapter exists yet, so these checks do not establish visual
quality, terminal performance, full TeX coverage, or production robustness.

## First implementation slice

Done:

1. Generic UV facilities: clipped blit, untrimmed serialization, and simple
   strokes.
2. `katex_dart` behind an Artisanal adapter.
3. Baseline-aware composition on UV cells for glyphs, rows, scripts, and
   fractions.
4. Markdown delimiters `\(…\)`, `\[…\]`, and `$$…$$`, with source-preserving
   fallback and pending placeholders.

Progress demo: `dart run pkgs/artisanal/example/math_demo.dart`.

Remaining polish: tighter quadratic radicals, selection around display blocks,
and optional `$…$` inline math.
