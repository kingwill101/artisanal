# Artisanal Capture 0.1.0

This release makes terminal Markdown captures easier to inspect.

## Highlights

- Added width-aware scenario rendering.
- Preserved **inline styles**, links, and `code`.
- Added a [gallery guide](../README.md) with no network requirements.

> **Migration note:** existing captures remain readable.
>
> If a glyph is unsupported, report it rather than silently replacing it.

### Example

```text
capture --width 64 scenarios/release_notes.md
```

| Area | Result |
| --- | --- |
| Markdown | headings, lists, quotes, and tables |
| Safety | relative assets only |

See also `CHANGELOG.md` for project history.

END_RELEASE
