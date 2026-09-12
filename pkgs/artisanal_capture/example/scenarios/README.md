# Markdown visual scenario corpus

These fixtures are small, deliberately readable inputs for the
`artisanal_capture` Markdown gallery. Render each one at widths **32, 64, and
96** and inspect wrapping, indentation, style transitions, container state,
and the distinctive end marker. They are fixtures, not claims about the
CommonMark specification or a test runner.

| Fixture | Focus and what to inspect |
| --- | --- |
| `nested_quotes.md` | Original combined nested quote, list, code, and table scenario. |
| `headings_inline.md` | Heading levels, emphasis nesting, code spans, links, and paragraph spacing. Check that the final marker survives inline style changes. |
| `breaks_paragraphs.md` | Soft wrapping versus hard two-space breaks, blank paragraphs, and adjacent text. |
| `quote_transitions.md` | Deep quote levels, empty levels, and sibling quote transitions. Inspect prefixes after every depth change. |
| `quote_lists.md` | Tight and loose ordered/unordered/task lists inside block quotes. |
| `lists_quotes_continuations.md` | Quotes inside list items and continuation paragraphs at several indentation levels. |
| `mixed_lists.md` | Three-plus-level mixed lists, ordered starts `9` and `98`, and loose list items. |
| `code_blocks.md` | Fenced and indented code, language labels, and literal Markdown/HTML that must not become syntax. |
| `tables.md` | Standalone aligned tables with inline content and long cells. |
| `containers_tables.md` | Tables inside quotes and list items, including alignment and continuation boundaries. |
| `html_details.md` | Open/closed `details`, `summary`, and nested HTML blocks. |
| `html_blockquote.md` | Raw HTML blockquotes containing lists and code. |
| `thematic_breaks.md` | Thematic breaks in quotes and list containers, plus surrounding transitions. |
| `escapes_entities.md` | Escaped markers, entities, literal backslashes, and text beginning with `>`. |
| `unicode_supported.md` | Latin, Greek, Cyrillic, arrows, and symbols expected to be representable by DejaVu Sans Mono. |
| `wrapping_tokens.md` | Long tokens, URLs, and links at narrow widths; verify no content disappears. |
| `images.md` | Image alt text, missing destinations, and linked images without downloads. |
| `release_notes.md` | A realistic composite of headings, lists, quotes, code, tables, links, and notes. |
| `diagnostic_unicode.md` | **Intentional diagnostic:** combining marks, CJK, and emoji stress unsupported glyph rasterization and shaping. Do not silently assume these render correctly. |

All URLs use `example.test` or relative paths. No fixture requires network
access, remote images, or additional fonts.

## Generate and inspect

Use the [`gallery` command](../../README.md#markdown-scenario-gallery) to render
all 19 fixtures at the three review widths. The resulting `index.html` links
native PNGs, full HTML previews, input Markdown, ANSI output, and cell snapshots.
Generation is not a correctness verdict; even an unflagged frame needs review.

## Resolved gallery findings

- **`html_blockquote.md`:** quote context now survives blank-line-separated
  HTML/Markdown blocks. List items and code remain within the quote border.
- **`html_details.md`:** closed nested and outer details show summaries without
  leaking their bodies; open details still show their Markdown content.
- **`tables.md` and `containers_tables.md`:** tables now wrap within the available
  width, retain header alignment, and account for quote/list indentation.
  At widths too small for a grid, labeled fields preserve the cell data.

The refreshed 32/64/96-column matrix generates all 57 images. Its five flagged
renders consist of the two narrow code cases below and the three intentional
Unicode diagnostic variants.

## Remaining policy and coverage cases

- **`code_blocks.md`, 32 columns:** long code rows extend beyond the viewport.
  The gallery preserves the unclipped ANSI and flags these rows; whether code
  should wrap, scroll, or clip is a separate rendering-policy decision.
- **`release_notes.md`, 32 columns:** its long code row remains unwrapped; the
  table that previously overflowed now fits.
- **`diagnostic_unicode.md`, all widths:** missing CJK/emoji glyphs and
  multi-codepoint shaping are intentional raster-diagnostic cases.

The gallery also caught a capture-validator defect: line wrapping can emit
valid BEL-terminated OSC 8 links, but capture accepted only ST terminators.
That is now fixed and regression-tested; image and long-link scenarios can
be captured without stripping hyperlinks.

The `9` and `98` examples in `mixed_lists.md` are separate ordered lists.
Within a single Markdown ordered list, only its first number determines the
counter; an authored later `98.` would correctly display as `10.` after `9.`.
