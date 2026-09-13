## Summary

- Add `artisanal_capture`: detached/versioned cell snapshots, native PNG exports, script-free HTML previews, widget captures, and an Artisanal-based CLI with a multi-width scenario gallery.
- Add an Ultraviolet software raster backend using `package:image` and explicit static TrueType fonts. No Chromium, browser automation, Flutter engine, or native font library is required.
- Fix complex Markdown rendering: nested quote borders, HTML container scope across blank lines, closed details visibility, width-bounded tables, alignment, and list/table composition.
- Fix F12 debug-overlay corruption over linked tables. Exact-cell ANSI clipping preserves complete OSC 8/SGR sequences, isolates panel pen state, and handles partially clipped wide glyphs without moving layers.
- Keep GitHub disclosure extraction out of HTML comments and literal code; preserve Markdown indentation and hard breaks.
- Add synthetic visual scenarios plus an attributed, checksum-pinned copy of Dart SDK issue 64170 as an offline bench, including real GitHub CLI F12/scrolling regressions.

## Architecture and review notes

- Raster rendering belongs to `ultraviolet`; capture/export orchestration belongs to `artisanal_capture`.
- Shared UV SGR parsing is reused for clipping state restoration rather than maintaining a divergent parser.
- Capture inputs and TrueType outlines have validation/resource limits; unsupported raster features produce explicit diagnostics.
- Generated galleries remain Git-ignored build artifacts. Fixtures, metadata, tests, and documentation are included.
- No CI workflow changes.

## Verification

Locally verified on Linux:

- **901 tests passed; 3 existing tests skipped** across Ultraviolet, Markdown, overlay/devtools, capture, and GitHub CLI suites:
  ```sh
  dart test pkgs/ultraviolet pkgs/artisanal/test/markdown \
    pkgs/artisanal/test/tui/bubbles/debug_overlay_test.dart \
    pkgs/artisanal/test/tui/program_devtools_test.dart \
    pkgs/artisanal_capture apps/github_cli -r compact
  ```
- Targeted `dart analyze` over the affected packages/code: no issues.
- Browser-safe entrypoint compilation passed for Ultraviolet and Artisanal.
- Compiled and ran the standalone native capture CLI; generated PNG/HTML galleries and inspected representative before/after images.
- Verified the issue fixture against GitHub's issue body and its recorded SHA-256.

## Current limitations

- Pixel output depends on the explicit font/profile; universal pixel identity with every terminal is not claimed.
- Complex shaping, missing glyphs/font variants, color fonts, and external terminal graphics are diagnosed rather than silently approximated. Cell captures preserve the status emoji even when the selected raster font cannot draw them.
- Long code lines remain unwrapped; a very narrow viewport can still flag code or heading overflow.
- Live PTY recording is not part of this capture CLI.

## Commits

- `5dbc14c6` — feat(capture): add native snapshots and harden Markdown rendering
- `385ab6c1` — fix(tui): preserve links and disclosure boundaries


<!-- This is an auto-generated comment: release notes by coderabbit.ai -->
## Summary by CodeRabbit

* **New Features**
  * Added deterministic terminal-cell snapshots, widget capture, PNG/HTML export, and scenario galleries.
  * Added native TrueType rasterization with configurable rendering and fidelity diagnostics.
  * Added shared paint policies and exact cell-based ANSI clipping for overlays and wide characters.
  * Added optional native frame capture for widget testing.

* **Bug Fixes**
  * Improved Markdown rendering for nested blockquotes, tables, HTML containers, lists, and GitHub disclosures.
  * Prevented overlay hyperlink leaks and screen-boundary overflow.
  * Improved widget cleanup, error recovery, theme contrast, and resource handling.

* **Documentation**
  * Added usage guides, examples, changelog entries, and workspace package documentation.
<!-- end of auto-generated comment: release notes by coderabbit.ai -->