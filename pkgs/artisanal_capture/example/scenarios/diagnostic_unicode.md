# Diagnostic Unicode Stress

> This fixture intentionally includes glyphs that may be unsupported or
> incorrectly shaped by the raster backend. Do not silently assume success.

Combining marks: é å ñ Ż (base letters plus combining accents).

CJK sample: 日本語 中文 한국어 — expected unsupported-glyph stress.

Emoji sample: 😀 🧪 🧵 🚀 — expected unsupported raster glyph/shaping stress.

Mixed sequence: Á → 日本語 → 😀, with a final ASCII checkpoint.

END_UNICODE_DIAG
