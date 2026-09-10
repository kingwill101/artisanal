# Changelog

## 0.6.2

### Added

- Added the reusable interactive `TreeModel`, `TreeItem`, and projected
  `TreeRow` Bubble primitives with stable-ID expansion/selection state,
  keyboard and mouse navigation, viewport scrolling, branch connectors, and a
  standalone string renderer for non-widget TUI applications. Trees also own
  renderer-independent horizontal panning state with `H`/`L` and shifted-arrow
  bindings.

### Fixed

- Fixed text decoration foreground styles being overwritten by the editor's
  base text color during rendering, restoring visible editable syntax
  highlighting and keeping configured decoration styles immutable.
- Indexed text-decoration ranges by document offset and line decorations by
  row, so viewport rendering only examines intersecting decorations instead of
  scanning every document decoration for every visible line.

## 0.6.1

### Added

- Added `DiffReviewBlocks`, a sparse code/thread display sequence with indexed
  source-row and thread lookup, and `DiffLayout.anchorsAtRow` for hit testing.
- Added `DiffReviewModel` and semantic TEA messages for source-key selection,
  range navigation, side switching, thread expansion, and revision-scoped
  updates. `DiffReviewDocument` indexes both source sides independently of
  presentation; thread placement explicitly distinguishes attached, unmapped,
  and outdated anchors without nearest-line fallback.
- Added `GitDiffModel.layout`, an immutable `DiffLayout` snapshot with exact
  source-key lookup. Rendering now emits source anchors in the same pass as
  terminal rows, and viewport-only updates reuse the snapshot.

### Fixed

- `Cmd.openUrl` now runs the browser launcher without releasing the terminal,
  keeping the alternate screen, input, and rendering active. `Cmd.exec` also
  supports `releaseTerminal: false` for non-interactive background helpers.
- Corrected split-view anchors after context lines that wrap differently in
  the left and right panels.

## 0.6.0

### Added

- Added shared command-palette items, scored matches, deterministic matching,
  viewport windows, stable item IDs/payloads, editor command state, and a
  scrolling TEA modal overlay (`CommandPaletteOverlay` +
  `CommandPaletteComponent`). Widget and string-view hosts now share one
  matcher, selection, and visible window.
- Added FFI-free editor seams `text_language.dart` (`EditorLanguageAdapter` +
  `EditorLanguageRegistry`) and `syntax_tree.dart` (`EditorSyntaxNode` /
  `EditorSyntaxTree` / `SyntaxTreeProvider` DTOs) so Tree-sitter, LSP, or
  custom language backends can plug in from their own packages without the
  core bundling native dependencies.
- Added `code_extensions.dart` as the opt-in home for builtin language
  behavior; the minimal `editor_core.dart` barrel now exports only the
  versatile core.
- Added `codeShouldIncreaseIndentForAdapter` alongside the legacy
  string-based indent helper.
- Added prompt-composer helpers: tracked paste placeholders
  (`text_placeholders.dart`), prompt normalization + external-editor
  resolution (`prompt_content.dart`), and IDE selection ingestion
  (`editor_selection.dart`), with a `prompt-composer` TUI example wiring all
  four together (`TextAreaModel` + `Cmd.openEditor` + placeholders +
  selection context).
- Disabled kernel XOFF flow control (`stty -ixon`, state saved/restored)
  while stdio raw mode owns the terminal, so `Ctrl+S`/`Ctrl+Q` reach TUI
  apps as keys instead of freezing output.
- Fixed shared `pgup`/`pgdown` key-binding aliases and prevented unmodified
  special-key aliases from accidentally matching modified key events.
- Added an editor-core boundary test (no `dart:io`/`dart:ffi`, no builtin
  imports from core, builtins excluded from the minimal barrel).
- Added advanced editing capabilities: bracket matching
  (`text_brackets.dart`), regex find/replace with sessions
  (`text_search.dart`), multi-selection sets (`text_selection_set.dart`),
  atomic workspace edits with preview (`workspace_edits.dart`), snippets
  with tabstop sessions (`text_snippets.dart`), and indent folding
  (`text_folding.dart`).
- Added portable editor commands and keymaps, completion and code-action
  provider contracts, asynchronous syntax sessions, configurable work budgets,
  and document snapshot persistence/recovery.
- Added reusable UTF-8 byte/grapheme coordinate conversion and a
  generation-safe `AsyncSyntaxTreeSession` for optional native or isolate-based
  structural parser adapters.
- Added an optional `tree_sitter_language_pack` example package demonstrating
  native runtime ownership, asynchronous parsing, syntax-tree DTO conversion,
  UTF-8 byte-to-grapheme span mapping, and live syntax decorations in an
  editable `TextAreaModel` without adding FFI to editor core.
- Expanded `TextAreaModel` with command dispatch, undo/redo, dirty revisions,
  search and diagnostics navigation, completion acceptance, clipboard
  transactions, and multi-cursor character, word, line, vertical, selection
  extension, indent/outdent, and line move/duplicate/delete operations.
- Enforced editor work budgets in search (truncated matches), decoration
  layers, completion lists, and synchronous syntax scheduling.
- Added `EditorRangeResolver`, `mapSelectionRanges`, and `mapSelectionEnds` so
  motions and edits share selection-set transforms; routed textarea keys
  through named commands (including argument-taking insert and undoable
  transpose/word-case transforms), exposed line and selection transforms to
  command palettes, added typed selection wrapping and Markdown line-transform
  commands, added portable indent/cleanup/sort command options, and made
  `TextView` skip folded lines without stranding cursors in hidden bodies.
- Preserved each selection range's anchor and active edge independently, so
  repeated backward extension, anchor crossing, edit mapping, and primary
  cursor placement behave consistently for one or many selections.
- Added fold-aware preferred-column vertical motion and retained a separate
  column affinity for every active textarea cursor, restoring columns after
  short lines and resetting the affinity after horizontal movement. Soft-wrap
  mode follows projected visual rows and retains terminal-cell columns;
  Home/End use visual-row boundaries while logical-line commands remain
  separately dispatchable, and Page Up/Page Down move or extend selections by
  viewport-sized visual-row pages. Shift+Ctrl+Home/End extends selections to
  document boundaries through stable commands.
- Added `MemoryEditorDocumentStore` plus a file-backed example store for
  save/recovery workflows.
- Added a full-screen alternate-buffer `advanced-editor` example with find
  and replace, completion and code-action overlays, syntax sessions,
  persistence/recovery, folding, snippets, and matching brackets.
- Added inline media: typed chip elements (`text_inline_elements.dart`)
  plus the attachment lifecycle (`media_attachments.dart`: preview
  pipeline, viewer state, capability-gated affordances), pasted/dropped
  path recognition (`media_paths.dart`, via `package:path`), a
  `cursorOffset` getter on `TextAreaModel` for overlay hit-testing, and a
  full-screen `media-composer` example wiring the chip → cursor preview →
  modal viewer workflow (mime types via `package:mime`).
- Chip elements track edits by position diff, never marker text: pasted
  marker-looking text cannot hijack elements, typing inside a chip
  destroys it, chips refuse nesting, and prompts cap at ten images.
- Added a TEA-native modal popup (`renderModal` + `ModalChrome`, with box
  chrome from the Style-driven `PanelComponent` and splicing via
  ultraviolet's `cutAnsiByCells` slicer) and exported the image renderer
  (`ImageProtocol`, `detectImageProtocol`, `renderImageToAnsi`) from the
  markdown barrel; the `media-composer` viewer paints halfblock pixels
  or terminal-native Kitty/iTerm2/Sixel images inside the modal, with a
  manual protocol cycle (`ctrl+p`) and `esc`/`q` viewer close.
- Added `FrameView`, `FrameArea`, and `FrameRenderable` for immediate-mode TEA
  views that position Artisanal styled strings without exposing renderer cells.
- Added pure horizontal and vertical `FrameLayout` splitting with fixed,
  percentage, weighted-fill, gap, and inset constraints.
- Added `FrameArea.inset` and `FrameArea.centered` geometry helpers for pane
  content and overlays.
- Added a responsive, core-only positioned-frame dashboard example covering
  nested layouts, selection state, narrow stacking, and overlays.
- Documented when TEA applications should return `String`, `View`, or
  `FrameView`, including positioned layout and styling guidance.
- Covered structured frame rendering through `Program` and both supported core
  runtime entrypoints.
- Added an opt-in, program-owned developer tools overlay for raw TUI and widget
  applications. It supports a configurable `KeyBinding`, recent messages,
  captured output, render metrics, hot-reload statuses, and a shared custom
  metrics registry.
- Added focused `charting.dart`, `git_diff.dart`, `layout.dart`,
  `markdown.dart`, `runtime.dart`, `scoring.dart`, and `text_editing.dart`
  entrypoints so reusable packages can import only the features they need.

### Changed

- Moved builtin language data out of core logic: `CodeLanguageProfile` now
  implements `EditorLanguageAdapter`, and the colon-indent rule lives on the
  Python/YAML adapters instead of a hardcoded branch in `code_edit_policy.dart`.
  `resolveCodeLanguageProfile` keeps its signature as a registry-backed shim.
- Split `editing.dart` / `viewing.dart` barrels into core-only exports;
  `package:artisanal/editor_core.dart` and `package:artisanal/artisanal.dart`
  re-export `code_extensions.dart` for backwards compatibility.
- Kept terminal graphics commands outside DEC synchronized-update frames so
  Kitty placements render correctly in Ghostty.
- Simplified CLI GUI helpers behind shared presentation, prompt, and operation
  services. `Console` and `Console.components` now use the same capability,
  styling, spinner, progress, task, workflow, countdown, and prompt
  implementations instead of delegating to each other or maintaining parallel
  lifecycle code.
- Implemented the `FrameLayout` facade with Ultraviolet rectangles, fixed and
  percentage constraints, and stable largest-remainder allocation rather than
  maintaining duplicate layout primitives.
- Reserved the actual wrapped height of persistent log lines before painting a
  structured frame.
- Simplified and hardened hot-reload initialization: concurrent starts now
  share one attempt, shutdown waits for watcher disposal, reassembly completes
  before success is reported, and initialization no longer mutates the
  process working directory. Entrypoints outside `bin`, `lib`, and `test` are
  watched directly, including editor saves that replace the original file.
- Delegated Kitty, iTerm2, and Sixel image protocol encoding to Ultraviolet,
  removing three duplicated renderer implementations while preserving the
  public terminal API.
- Routed Ultraviolet integration through package-owned public entrypoints and
  removed duplicated one-line renderer, Unicode, and color-profile forwarding
  libraries.
- Added a narrow, platform-safe `runtime.dart` entrypoint for reusable and
  browser-capable consumers of the core TEA runtime.
- Kept Markdown text rendering browser-compatible while retaining native image
  downloading and SVG rasterization on `dart:io` platforms.
- Reduced the published package archive by excluding repository-hosted demo
  media.
- Generalized the browser runner as `runBrowserProgram(Model)` and the shared
  network-host lifecycle as `TerminalHostServer`.
- Added elapsed timestamps and the documented script, capture, and tag metadata
  to trace output. Reconfiguration now resets paths, headers, and tag filters;
  test-controlled events use the injected clock, and `clear: true` replaces
  existing output. Invalid structured fields and filesystem failures no longer
  allow optional tracing to terminate the running application, and invalid
  tag-only allow-lists now fail closed instead of enabling every category.
  Multiline log content is encoded as one record and cannot forge structured
  events consumed by replay tooling.
- Changed DevTools message instrumentation to use independently paired
  asynchronous timeline tasks, preserving valid timelines when several
  messages are queued together. Dropped messages and shutdown now also clear
  pending-message accounting.

### Fixed

- `Console.spin` now honors custom completion messages, and generated spinner
  results use the task's completed elapsed time rather than a near-zero
  precomputed duration.
- Non-interactive tasks, spinners, and progress operations now avoid terminal
  allocation, cursor control sequences, and unterminated output when
  `clearOnDone` is enabled.
- Non-interactive number prompts now validate configured defaults, and
  multi-select prompts consistently ignore invalid default indices.
- Retained the optional `InlineAnimation.renderConfig` constructor parameter
  for backwards compatibility while deriving animation behavior from the
  terminal.
- Non-interactive task groups now report unrun operations as skipped after a
  failure, matching the interactive task-group result.
- Generated Zsh completion wrappers now forward the actual cursor position
  instead of treating every completion request as if the cursor were at the
  start of the command line.
- Preserved underline colors when copying `Style` and kept a standalone
  `TextStyle.decorationStyle` from enabling an otherwise unspecified underline.
- Kept `TextStyle` underline and line-through decorations continuous across
  interior spaces while preserving `Style`'s explicit whitespace controls.
- Preserved ANSI styling and hyperlinks across `Layout.wrap()` continuation
  lines and hard-wrapped overlong text to its requested cell width.

### Removed

- Removed the unused out-of-process remote plugin protocol, process host,
  manifest and schema APIs, examples, and CI precompiler.
- Removed the unused Forge2D dependency, physics helpers, documentation, and
  physics demo page.
- Removed the unused `chalkdart` dependency, unreachable web bootstrap code,
  obsolete color-profile forwarding files, and the abandoned duplicate
  documentation site.
- Removed the dependency on `artisanal_widgets`, including the widget runner
  APIs and the `widgets.dart` / `testing.dart` re-export entrypoints. Widget
  applications now import those APIs from `package:artisanal_widgets`.

## 0.5.0

### Added

- Added immutable, value-equal `TextStyle` declarations with Flutter-shaped
  `FontWeight`, `FontStyle`, and `TextDecoration` values, `copyWith()`,
  parent/child `merge()`, and `Style` composition through `applyTo()` and
  `toStyle()`.
- Added `ComponentTheme` presets and semantic style bundles for built-in
  console prompts and display components, configurable through `Console`.
- Added the standalone `example/widget_catalog.dart` CLI for browsing every
  built-in Bubble/display component and rendering preset showcases.
- Added the public `widgetCatalogEntries` registry and `filterWidgetCatalog()`
  helper for application-owned catalogs, command palettes, and help screens.
- Added category-aware keyboard search to the widget catalog, plus VHS tapes
  and golden snapshots covering the preset showcase.
- Added `ScreenMode.fixed` and `FixedViewport` for rendering into an arbitrary
  primary-screen rectangle without clearing surrounding terminal content.
- Added world-coordinate canvas shapes (`CanvasLine`,
  `CanvasRectangle`, `CanvasCircle`, and `CanvasPoints`) backed by the existing
  braille chart canvas.
- Added an `uv-effects` TUI example showing the low-level
  `Canvas` -> `BufferRenderSink` -> terminal effects pipeline.

### Changed

- Routed fixed viewports through the UV renderer with clipped row and column
  addressing, viewport-scoped clears, and preservation of surrounding primary
  screen content.
- Reset fullscreen UV diff state whenever terminal geometry changes so a frame
  is never compared against cells from the previous width.

### Fixed

- Invalidate cached remote-plugin kernel snapshots when the active Dart SDK
  changes, avoiding invalid SDK hash failures after SDK upgrades.
- Fixed horizontal downsizing artifacts by forcing a clean repaint after the
  screen buffer shrinks and disabling geometry-sensitive scroll operations
  during resize.
- Kept inline and fixed-viewport cleanup bounded to the rows and columns owned
  by the application.

## 0.4.0

### Added

- Added `option()`, `hasOption()`, `argument()`, `arguments`, and
  `argumentCount` convenience methods to `Command` (Laravel/Artisan-style).
  Instead of raw `argResults!['name']`, commands can now write
  `option('name') as String?`, `argument(0)`, etc.
- Added `CommandRunner.detectExecutableName()` static method that
  auto-detects the binary name from `Platform.script`. Compiled binaries
  show their filename (`artisan`), while `dart run` invocations show
  `dart run path/to/script.dart` in usage help.
- Added `getNamespaces()` and `allCommandsInNamespace()` to `CommandRunner`
  for programmatic namespace inspection (matching Symfony Console's
  `Application::getNamespaces()` and `Application::all($namespace)`).
- Added namespace-aware error recovery: typing a namespace prefix (e.g.,
  `db` where `db:migrate`, `db:seed` exist) shows subcommands instead of
  a "command not found" error. Exits with code 1, matching Symfony.
- Added Symfony-style error blocks: `UsageException` output is now rendered
  as a styled `<error>` block (white-on-red in ANSI mode) written to stderr,
  matching Laravel Artisan's `formatBlock($message, 'error', large: true)`.
- Added `_extractAllNamespaces()` for extracting parent namespace parts from
  nested command names like `cache:user:list`.
- Added `example/args/` directory with a comprehensive, self-documented demo
  covering all 14 args improvements (namespaces, subcommands, verbosity,
  non-interactive mode, shell completion, error blocks, help themes, etc.).

### Changed

- `CommandRunner.run()` now attempts namespace discovery before falling back
  to `_printUsageError`. If the missing command matches a namespace prefix,
  subcommands are listed instead.
- `_printUsageError()` now writes styled error blocks to stderr instead of
  plain text to stdout.
- `_handleMissingCommandAsNamespace()` now exits with code 1 instead of the
  default `usageExitCode` (64), matching Symfony Console behavior.
- Removed `_error()` method; replaced by `_styleErrorBlock()` which applies
  proper white-on-red `<error>` styling.
- Updated library-level documentation in `args.dart` to include a complete
  GreetCommand example using the new argument/option helpers.

## 0.3.1

### Added

- Added automatic shell tab-completion for `CommandRunner` via `ShellCompleter`,
  covering top-level commands, subcommands, option flags, and allowed values.
  Enabled by default; opt out with `enableShellCompletion: false`.
- Added `ShellCompleter.generate(executableName)` and `generateAll(names)` for
  producing bash/zsh/tcsh completion scripts that can be sourced from shell rc files.
- Added `unknownCommandFallback` to `CommandRunner` for shim-style CLIs that
  delegate unknown commands while keeping built-in completion automatic.
- Added `completion: ^1.0.2` dependency.
- Added a scrollback-preserving inline TUI guide plus richer inline examples
  and trace inspection tooling for bottom-pinned command dashboards.
- Added inline renderer regression coverage for native scrollback, resizing,
  log insertion, cleanup, and non-alt-screen behavior.

### Changed

- Reduced UV-backed TUI render overhead by reading the terminal size once per
  render pass.
- Updated workspace dependency constraints for the current `ultraviolet` and
  `artisanal_widgets` releases.

### Fixed

- Fixed bottom-anchored inline rendering so `Cmd.println` output is inserted
  above the pinned UI without clearing scrollback or pushing the panel down.
- Fixed inline resize handling so renderer clears stay scoped to the inline
  viewport instead of erasing prior terminal history.

## 0.3.0

### Added

- Added `NumberInputModel` bubble for numeric input prompts with min/max validation and configurable step.
- Added `SuggestModel` bubble for auto-complete suggestion prompts with fuzzy filtering.
- Added `Console.clearScreen()` to clear the terminal screen.
- Added `Console.setTerminalTitle(String)` to set the terminal window title.
- Added `Console.notify(String)` to send a desktop notification.
- Added `Console.grid(List<List<String>>)` to render a formatted grid/table to the console.
- Added `Console.number(...)` interactive prompt for reading a numeric value from the user.
- Added `Console.suggest(...)` interactive prompt for auto-complete suggestion input.

### Fixed

- Fixed terminal corruption on Ctrl+C by enabling `signalHandlers: true` and `sendInterrupt: true` in `promptProgramOptions`, `dataTablePromptOptions`, and `textareaPromptOptions` so SIGINT is caught before killing the process and the terminal is properly restored.
- Fixed `InterruptMsg` handling in all 14 `_*PromptModel` wrapper models so Ctrl+C during any prompt gracefully restores the terminal.
- Fixed `_AnticipatePromptModel` so an `InterruptMsg` arriving before `init()` completes (via `_initDone` guard) exits cleanly instead of hanging.
- Fixed `runSpinnerTask` to call `future.ignore()` so a rejected future before the `await` does not produce an unhandled error.

- Added `example/tui/remote_plugin_generic_service_host_demo.dart` plus a
  matching guest plugin demo, showing how to register a custom schema-backed
  `host.ping` generic service and call it from an out-of-process plugin.
- Fixed init-time exec restore ordering so the first visible frame is only marked complete after a real paint, preserving the initial restored frame before exec-completion updates run.
- Wired the `remote_plugin_workspace` example through the new remote-surface input router, including click-to-focus behavior and a `--snapshot-click=` test mode for deterministic example coverage.
- Extended the `remote_plugin_workspace` example to route keyboard input into the focused plugin surface, including a `--snapshot-key=` path so the example regression can assert focused-plugin key handling deterministically.
- Extended the `remote_plugin_workspace` example to route mouse-motion events into hovered plugin surfaces, including a `--snapshot-motion=` path so the example regression can assert hover-style remote input deterministically.
- Bound the `remote_plugin_workspace` host example to the remote clipboard service and taught the activity plugin to surface the returned clipboard text on `c`, so the workspace demo now exercises a real host-owned RPC end to end.
- Added generic `plugin.service.request` / `host.service.response` protocol messages plus a guest-side `RemotePluginGuestServices.call(...)` helper, so future host-owned RPCs can share one versioned envelope instead of growing one bespoke message pair per service.
- Added `RemotePluginGenericHostService` plus `RemotePluginHostConnection.bindGenericService(...)`, so hosts can dispatch the new generic service envelope by `service + method` without hand-writing message loops for each plugin connection.
- Added optional request/result schema validation to `RemotePluginGenericHostService.register(...)`, so host-owned generic RPCs can reject malformed JSON payloads before they reach service handlers.
- Bound the built-in generic clipboard, URL-open, notification, and file-picker helpers to explicit request/result schemas too, so the shared service path now validates those host-owned capabilities consistently instead of only custom generic handlers.
- Added optional request/result schema validation to `RemotePluginGuestServices.call(...)` too, and taught the built-in guest clipboard/URL-open/notification/file-picker helpers to use it on their generic-service branches, so plugins now validate shared-RPC payloads on both sides of the boundary.
- Added optional `RemotePluginServiceDescriptor` discovery payloads to `host.hello` and taught the built-in guest service helpers to consult them, so plugins can discover the exact `service.method` pairs and JSON schemas a host exposes instead of relying on the coarse `services` capability alone.
- Added `RemotePluginGenericServiceCatalog` plus `bindGenericServiceCatalog(...)`, so hosts can register generic service handlers once, reuse the derived discovery descriptors in `host.hello`, and then bind the same catalog to a plugin connection without duplicating setup.
- Added `RemotePluginHostConnection.startProcess(..., genericServices: ...)`, so hosts can pass one generic service catalog that is automatically advertised in `host.hello`, bound on connect, and disposed with the connection.
- Updated the standalone remote-plugin host demos to use `RemotePluginHostConnection.startProcess(...)` directly, so the public example path now matches the bundled host-side connection API instead of the older manual process/session/controller wiring.
- Added `RemotePluginHostConnection.startManifest(...)` and updated the manifest-backed workspace example to use it, so manifest-discovered plugin hosts no longer need to resolve entrypoints and working directories by hand.
- Added direct host-connection coverage for `RemotePluginHostConnection.startManifest(...)`, including manifest-relative entrypoint resolution plus auto-bound generic service startup.
- Unified the built-in generic clipboard, URL, notification, and file-picker registrations behind one shared implementation path, so service catalogs, bound generic host services, and descriptor generation stay in sync.
- Added `loadRemotePluginManifest(...)` and `RemotePluginHostConnection.startManifestFile(...)`, so hosts can validate and launch one manifest-backed plugin file directly without first loading a full manifest directory.
- Added a `remote_plugin_schema_dump` example and documented the schema-backed remote-plugin startup path, so plugin authors can dump `RemotePluginProtocolSchemas`, `RemotePluginManifestSchemas`, and built-in generic service descriptors without reading the source tree.
- Added `registerBuiltIns(...)` to the generic remote-plugin service catalog and bound generic host service, so hosts can wire the built-in clipboard/URL/notification/file-picker services without repeating four separate registrations.
- Added `RemotePluginGenericServiceCatalog.builtIns(...)`, so hosts can construct a ready-to-bind built-in generic service catalog in one expression instead of creating an empty catalog first.
- Updated the `remote_plugin_workspace` host and host-connection coverage to reuse one generic service catalog across multiple plugin connections, so the example path now dogfoods the intended register-once/bind-many service model.
- Added `RemotePluginWorkspace` as a reusable manifest-backed multi-plugin host helper, so library users can launch a shared remote-plugin workspace with one call instead of rebuilding manifest loading, connection maps, shared surfaces, router wiring, and focus helpers in app code.
- Migrated clipboard onto the generic remote-plugin service path too, so guest clipboard helpers now use `plugin.service.request` / `host.service.response` whenever a host advertises `services`, while the older typed clipboard messages remain available for backward compatibility.
- Migrated URL-opening onto the generic remote-plugin service path too, so guest URL helpers now use `plugin.service.request` / `host.service.response` whenever a host advertises `services`, while the older typed URL-open messages remain available for backward compatibility.
- Migrated notifications onto the generic remote-plugin service path too, so guest notification helpers now use `plugin.service.request` / `host.service.response` whenever a host advertises `services`, while the older typed notification messages remain available for backward compatibility.
- Migrated file-picker requests onto the generic remote-plugin service path too, so guest picker helpers now use `plugin.service.request` / `host.service.response` whenever a host advertises `services`, while the older typed file-picker messages remain available for backward compatibility.
- Updated the `remote_plugin_workspace` example host to advertise `services` and bind its clipboard capability through the generic host-service registry, so the flagship multi-plugin demo now dogfoods the shared RPC path too.
- Extended the `remote_plugin_workspace` activity plugin to call the host URL-open and notification services too, so the flagship multi-plugin demo now visibly exercises three shared host-owned RPCs instead of only clipboard.
- Extended the `remote_plugin_workspace` activity plugin to call the host file-picker service too, so the flagship multi-plugin demo now visibly exercises all four built-in shared host-owned RPCs.
- Added `RemotePluginSurfaceInputRouter` so hosts can turn resolved remote surface placements into focus, blur, mouse, and key routing without rebuilding per-surface dispatch logic by hand.
- Added `RemotePluginSurfaceInputRouter.sendTuiMouse(...)` so host apps can forward runtime `MouseMsg` events into remote plugin surfaces without rewriting button/action translation by hand.
- Added resolved placement and hit-test helpers for remote plugin surfaces, so hosts can map global coordinates into the topmost plugin panel or popup using the same placement logic as UV composition.
- Added manifest-backed remote plugin discovery helpers plus workspace example manifests, so hosts can validate and load plugin process specs from `*.plugin.json` files instead of hardcoding entrypoints in app code.
- Added typed remote plugin file-picker request/response messages plus reusable host and guest helpers, so plugins can ask hosts to select files or directories without inventing custom service glue.
- Added `RemotePluginGuestServices` so guest plugins can call clipboard, URL-open, and notification host services with awaitable helpers instead of hand-rolling request ids and response matching.
- Added typed remote plugin notification request/response messages plus a reusable host-side notification responder, so plugins can ask hosts to surface success/info/warning/error notices without inventing custom protocol messages.
- Added typed remote plugin URL-open request/response messages plus a reusable host-side URL opener, so plugins can start delegating external link launches back to the host without custom transport glue.
- Added typed remote plugin clipboard request/response messages plus a reusable host-side clipboard responder, so out-of-process plugins can start using host-owned services without inventing ad hoc JSON on top of the surface transport.
- Added a `remote_plugin_workspace` example directory with a full host app plus multiple guest plugins, including a snapshot mode for regression testing and local experimentation.
- Added `RemotePluginHostConnection.startProcess(...)` so plugin hosts can launch a process, complete the handshake, and bind surface state through one host-side entrypoint instead of manually wiring process, session, and controller objects.
- Added a popup-oriented remote plugin host/guest example pair that exercises anchored child surfaces and UV composition on top of the new remote plugin controller and layer builder.
- Added `buildRemotePluginSurfaceLayers(...)` plus `RemotePluginSurfacePlacement` so hosts can turn stored remote plugin surfaces into positioned UV layers and compose anchored child surfaces without rebuilding placement logic by hand.
- Added `RemotePluginSurfaceDrawable` so remote plugin surface state can be rendered directly through the existing UV `Drawable`/`Canvas` stack instead of requiring hosts to reimplement cell translation by hand.
- Added `RemotePluginSurfaceController` so plugin hosts can bind a `RemotePluginSession` directly to host-side surface state updates instead of wiring lifecycle and frame routing by hand.
- Added a runnable remote-surface host/guest example pair that launches a plugin process, completes the hello handshake, applies plugin frames into host surface state, and prints the resulting rendered panel.
- Added `RemotePluginGuestSession` plus a stdio binding helper so plugin processes can complete the host/plugin hello handshake and speak the remote-surface protocol without rebuilding channel setup by hand.
- Added `RemotePluginSurfaceStore` so hosts can apply remote-surface open/resize/frame/close messages into concrete per-surface cell state before later compositing.
- Added `RemotePluginSession` and pre-listener channel buffering so host/plugin hello handshakes can complete reliably even when plugins emit `plugin.hello` immediately on startup.
- Added stable `package:artisanal/plugins.dart` with a typed remote-surface plugin protocol, JSON schema definitions, and message validation helpers for future out-of-process plugin hosts.
- Added newline-delimited JSON transport helpers for the remote-surface plugin protocol so plugin hosts can speak the wire format over stdio or sockets without rebuilding framing logic.
- Added `RemotePluginJsonChannel` so plugin hosts can bind typed remote-surface messages directly to line or byte streams instead of managing framing and validation manually.
- Added `RemotePluginProcess.start(...)` so plugin hosts can launch stdio-based plugin executables and interact with them as typed remote-surface message streams.
- Added `withoutStartupTitle()`, `withoutStartupProbeOverride()`, `withoutInput()`, `withoutOutput()`, `withoutCancelSignal()`, and `withoutMovementCapsOverride()` helpers so `ProgramOptions` can clear nullable overrides without rebuilding options manually.
- Added `ColorPaletteMsg` and `Cmd.requestColorPalette()` so OSC 4 palette replies are exposed through the TUI runtime instead of staying UV-internal.
- Added `CursorPositionMsg` and `Cmd.requestCursorPositionReport()` so cursor-position reports are exposed through the TUI runtime instead of staying UV-internal.
- Added `Cmd.requestPrimaryDeviceAttributesReport()` so DA1 capability queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestKeyboardEnhancementsReport()` so kitty keyboard support queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestSecondaryDeviceAttributesReport()` so DA2 capability queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestTertiaryDeviceAttributesReport()` so DA3 capability queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestTerminalVersionReport()` and `Cmd.requestTermcapStrings()` so XTVERSION and XTGETTCAP queries have explicit TUI command helpers instead of requiring raw escape writes.
- Added `Cmd.requestColorSchemeReport()` so terminal light/dark scheme queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `Cmd.requestModifyOtherKeysReport()` so xterm ModifyOtherKeys status queries have an explicit TUI command helper instead of requiring raw escape writes.
- Added `ModifyOtherKeysMsg` plus device-attribute report messages so UV capability/startup reports no longer fall back to raw UV events in the TUI runtime.
- Added `ModeReportMsg`, `ColorSchemeMsg`, and `Cmd.requestModeReport()` so UV mode-status replies and light/dark color-scheme reports are exposed through the TUI runtime instead of falling back to raw UV events.
- Added `WindowPixelSizeMsg`, `CellSizeMsg`, and matching `Cmd` request helpers so UV pixel-size and cell-size reports are exposed through the TUI runtime instead of staying UV-internal.
- Added `ProgramOptions.startupProbes` / `withStartupProbes(...)` so custom terminals can explicitly opt into or out of UV startup probing.
- Added `ProgramOptions.sendSuspendSignal` / `withoutSuspendSignal()` so `SuspendMsg` can exercise the full terminal release/restore lifecycle without sending `SIGTSTP`.
- Added stable `package:artisanal/runtime.dart` and `package:artisanal/hosts.dart` entrypoints for the focused TEA runtime and host/backend surfaces.
- Added stable `package:artisanal/app.dart`, `package:artisanal/editors.dart`, `package:artisanal/selection.dart`, and `package:artisanal/testing.dart` re-exports for the supported widget modules.
- Added `blendColor()` to the public style blending helpers so callers can interpolate a single color pair without building a gradient first.
- Added adaptive light-theme defaults to the built-in browser host page and made it emit live color-scheme reports when the browser theme changes while the hosted session is still using the page defaults.
- Made the built-in browser host page retint its toolbar and status badges from the hosted terminal theme, so browser-backed sessions no longer keep dark page chrome after a light-theme switch.
- Made the built-in browser host page switch its default ANSI palette with the hosted light/dark theme too, so `OSC 4` queries and palette resets stay consistent with browser-backed theme changes until the session overrides them.
- Preloaded light/dark CSS variables for the built-in browser host page so browser-backed sessions paint with the correct page theme before the host script finishes applying runtime state.

### Changed

- Reoriented remote plugin surface lifecycle messages to the `plugin.surface.*` wire family so the protocol matches the current model where plugins announce the surfaces they want hosts to render.
- Clarified the widget import guidance so `package:artisanal/...` widget entrypoints are documented as umbrella convenience re-exports, while `artisanal_widgets` remains the primary widget package for widget-first apps.
- Clarified the `ProgramOptions.mouse` and `mouseMode` docs so passive hover behavior explicitly points callers to `MouseMode.allMotion` instead of the `mouse: true` cell-motion default.
- Improved editor text-document offset mapping with cached line starts, and added triple-click whole-line selection across the shared text input surfaces.
- Prevented late external-process completion from restoring the terminal or delivering completion messages after the program has already quit, been killed, or lost its backend host session.
- Made direct `Program.kill()` abort active startup probes immediately, so kill behaves like quit/backend shutdown during pre-render and emoji probing.
- Deferred renders and stateful terminal control writes while `Program` temporarily releases the terminal for exec/suspend, then reapplied deferred titles and inline alt-screen/mode state on restore.
- Paused frame-tick and metrics timers while `Program` temporarily releases the terminal for exec/suspend, then resumed them cleanly on restore so background timers do not run against a released terminal.
- Reapplied `startupTitle` when restoring the terminal after exec/suspend when no view-scoped title override is active.
- `package:artisanal/widgets.dart` now re-exports the stabilized `package:artisanal_widgets/widgets.dart` surface instead of the broader experimental compatibility entrypoint.
- Made `Program` treat view-scoped terminal metadata declaratively, resetting colors, progress bars, focus reporting, bracketed paste, mouse mode, and kitty keyboard enhancements when later frames stop requesting them.
- Made `Program` reset view-scoped window titles and cursor styling declaratively, falling back to `startupTitle` when later frames drop a title override and restoring the default cursor shape when cursor metadata clears.
- Moved UV capability probing behind the first frame so pre-render startup probing only blocks on theme detection, not DA2/kitty capability replies.
- Updated the basic runtime-only TUI examples to import the stable `package:artisanal/runtime.dart` surface instead of the broader compatibility barrel.
- Updated more core runtime-only TUI examples to import the stable `package:artisanal/runtime.dart` surface instead of the broader compatibility barrel.
- Updated the widget gallery, kitchen sink, zone, mouse, cellbuffer, and UV input examples to opt into `MouseMode.allMotion` so passive hover and free pointer motion work without a button press.

### Fixed

- Buffered early non-surface `RemotePluginSurfaceController` traffic until the first host listener attaches, so startup clipboard/URL/notification/file-picker requests are not dropped before host service binders subscribe.
- Buffered post-handshake host/plugin session traffic until the first listener so eager surface frames are not dropped when callers attach `messages` just after `connect(...)`.
- Fixed `ProgramOptions.withoutFilter()` so it preserves `mouseMode` instead of silently resetting it to `MouseMode.none`.
- Taught the default browser host page to answer terminal color-scheme, foreground/background/cursor color, DA1, and XTVERSION queries and to forward browser focus changes and bracketed paste while those modes are enabled, so hosted browser sessions can participate in startup probing and runtime input delivery without leaking those control sequences into visible output.
- Taught the default browser host page to answer cursor-position and window/cell size queries, including the extended cursor-position reply used by the emoji-width probe, so hosted browser sessions can participate in more of the runtime report and startup-probe surface without timing out on those requests.
- Taught the default browser host page to answer DA2 and kitty-keyboard capability queries so the post-render UV startup capability probe can complete on browser-backed sessions instead of always timing out.
- Taught the default browser host page to answer DA3 capability queries, so browser-backed sessions can participate in tertiary device-attribute reporting too.
- Taught the default browser host page to answer XTGETTCAP requests for `RGB` and `TN`, so browser-backed sessions can participate in termcap-style capability discovery without requiring custom page glue.
- Taught the default browser host page to intercept OSC 52 clipboard reads and writes, mapping them onto the browser clipboard when available and replying with empty clipboard payloads when browser clipboard access is unavailable.
- Taught the default browser host page to answer private mode report queries for focus reporting and bracketed paste, so `Cmd.requestModeReport(1004/2004)` can complete against hosted browser sessions.
- Taught the default browser host page to answer xterm ModifyOtherKeys status queries and track later ModifyOtherKeys writes, so hosted browser sessions can report that state too.
- Taught the default browser host page to track mouse mode enable/disable writes and answer mode report queries for 1000/1002/1003/1006, so mouse-mode status requests work against hosted browser sessions too.
- Taught the default browser host page to consume OSC 0/2 title updates and mirror them into the browser tab title and toolbar heading, so hosted sessions reflect runtime window-title changes instead of dropping them.
- Taught the default browser host page to apply OSC 10/11/12 color changes and OSC 110/111/112 resets to the browser-hosted terminal theme, so hosted sessions can follow runtime foreground/background/cursor color updates after startup.
- Made browser-host color-scheme and OSC color queries reflect the current hosted theme state after OSC 10/11/12 and 110/111/112 mutations, not just the startup defaults.
- Made the default browser host page refit and resend terminal size when the terminal element itself resizes or browser font metrics finish loading, not just on `window.resize`.
- Taught the default browser host page to answer `OSC 4 ; index ; ?` palette queries and track palette mutations/resets, so browser-backed sessions can participate in palette reporting too.
- Reset cursor color overrides during terminal restore/cleanup paths and hardened startup background probing so the first rendered frame can reflect the probed terminal background.
- Hardened the pre-render theme probe so the first rendered frame can also follow an explicit terminal light/dark color-scheme reply when OSC 11 background color is unavailable.
- Treated `SuspendMsg` as a critical startup-probe lifecycle message so suspend aborts pre-render and emoji probes immediately instead of waiting on their timeouts.
- Treated `ExecProcessMsg` as a critical startup-probe lifecycle message so exec release aborts active startup probes immediately instead of waiting on their timeouts.
- Added end-to-end runtime coverage for foreground and cursor color requests through the `Program` message path.
- Fixed inline-mode dynamic alt-screen handling so command-driven and view-driven alt-screen toggles reset cleanly on later frames, suspend/restore, and shutdown, and so inline printing is suppressed while the alternate screen is active.
- Hardened `Program` resize dispatch so passive backend/SIGWINCH resize notifications are deduplicated while explicit `Cmd.windowSize()` requests still flow through filters and interceptors.
- Hardened `Program` resize dispatch so repeated passive UV window-size reports are deduplicated before reaching the model.
- Added end-to-end `Program` coverage for passive resize bursts so distinct backend and UV window-size updates still flow while duplicate sizes collapse.
- Added end-to-end `Program` coverage for focus and bracketed-paste delivery across both the UV decoder path and the legacy key parser path.
- Added end-to-end `Program` coverage for live mouse press, wheel, and `View.onMouse` command delivery across both parser paths.
- Added end-to-end `Program` coverage for UV mouse motion delivery plus parser-driven standard and in-band resize reports.
- Fixed first-frame rendering on injected custom terminals by skipping automatic UV startup probes unless the terminal explicitly opts in.
- Fixed delayed `init()` commands such as `Cmd.tick(...)` so they no longer block the first render.
- Fixed exec/suspend restore so `Program` emits the current terminal size when dimensions changed while the terminal was released, even if no resize signal or backend resize event arrived during that window.
- Fixed terminal restore helpers so an immediate shutdown during resume no longer dispatches stale resize updates or repaints after shutdown has already started.
- Fixed exec/suspend restore so a view-scoped window title is reapplied directly instead of briefly falling back to `startupTitle` first.
- Fixed forced startup probes so they skip `supportsAnsi: false` and `isTerminal: false` backends instead of writing DA/color/cursor queries directly through the terminal object.
- Added UV-to-TUI adapter parity coverage for focus, paste, mouse, and resize report translation.
- Added end-to-end `Program` and UV-to-TUI adapter coverage for mode-status replies and light/dark color-scheme reports.
- Added end-to-end `Program` and UV-to-TUI adapter coverage for ModifyOtherKeys and primary/secondary/tertiary device-attribute reports.
- Added end-to-end `Program` and UV-to-TUI adapter coverage for cursor-position reports.
- Added end-to-end `Program` coverage for terminal-version and XTGETTCAP capability reports.
- Added end-to-end `Program` coverage for kitty keyboard enhancement reports.
- Added end-to-end `Program` coverage for secondary device-attribute reports.
- Added end-to-end `Program` coverage for tertiary device-attribute reports.
- Added end-to-end `Program` coverage for clipboard read replies.
- Added direct `Program` coverage for startup `ColorProfileMsg` delivery.
- Added pre-render `Program` startup coverage for UV DA2 and kitty keyboard capability replies.
- Added direct `Program` coverage for init-triggered suspend and exec lifecycles across both fullscreen renderer backends.
- Added direct `Program` coverage for view-scoped alt-screen restoration across exec and suspend lifecycles.
- Added direct `Program` suspend lifecycle coverage for identical view-scoped metadata reapplication, including colors, cursor styling, progress bars, and input modes.
- Added direct `Program` suspend lifecycle coverage for explicit show/hide cursor overrides so release/restore keeps command-driven cursor visibility stable.
- Suppressed xterm pixel-size and cell-size report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed xterm mode-status report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed cursor-position report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed kitty keyboard enhancement report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed terminal color-scheme report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed DA2 capability queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed DA3 capability queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed XTVERSION and XTGETTCAP report queries on non-terminal hosts alongside the existing terminal-report guards.
- Suppressed batched OSC color, palette, and clipboard report queries on non-terminal hosts instead of only handling clipboard reads as a trailing special case.
- Suppressed the same terminal report queries on `supportsAnsi: false` hosts so socket/embedded clients that disable ANSI output do not receive DA, OSC color, clipboard, or window-report probes.
- Made `SocketTerminalHostServer.close(force: true)` wait for in-flight session cleanup after tearing down active client sockets, matching the browser host lifecycle contract.
- Fixed `SuspendMsg` terminal release so fullscreen suspend/restore no longer double-exits alt screen, and added direct suspend lifecycle coverage for metadata, fullscreen state, and startup-title restore.
- Fixed `SuspendMsg` restore so immediate resume commands such as `Cmd.quit()` are drained before the forced repaint, avoiding stale post-resume frames when the model exits during resume handling.
- Fixed `ExecProcess` restore so immediate completion messages such as `QuitMsg` are drained before the forced repaint, avoiding stale post-exec frames when the model exits during completion handling.
- Fixed restore scheduling so `ExecProcess`/`SuspendMsg` do not force a second post-restore repaint when immediate queued messages already rendered the first restored frame.
- Fixed restore-time backend shutdown races so immediate embedded host shutdown requests can cancel suspend repaints before a stale frame is drawn.

## 0.2.0+1

- documentation + assets

## 0.2.0

### Added

- New charting module (`package:artisanal/charting.dart`) with sparkline, histogram, heatmap, line, pie/donut, and ribbon renderers.
- Console tag parser support for style-tagged output (for example `<red>...</red>`).
- Structured TUI tracing and replay hooks for improved debugging and deterministic replay workflows.

### Changed

- Migrated widget-system implementation to `artisanal_widgets`; `package:artisanal/widgets.dart` now re-exports the widgets package.
- Split and aligned low-level UV rendering APIs with the standalone `ultraviolet` package.
- Reworked terminal image protocol handling for iTerm2, Kitty, and Sixel paths.

### Breaking

- Widget APIs are now sourced from the separate `artisanal_widgets` package; consumers should include `artisanal_widgets` in dependency resolution for hosted usage.

### Fixed

- Eliminated scroll flicker with synchronized terminal output.
- Corrected Unicode/emoji width handling and grapheme-safe truncation behavior (including variation-selector edge cases).
- Fixed style/renderer edge cases including hex color parsing and related rendering correctness issues.
- Improved input/trace runtime stability in TUI flows (including replay/capture and stream handling paths).

## 0.1.2

- **Fixed**: CI deadlocks when reading `stdin` multiple times by introducing `SharedInputStream`.
- **Fixed**: Resolved UV renderer regressions and TUI input normalization issues.
- **Improved**: Guarded `startupProbes` against `disableRenderer` configuration.

## 0.1.1

- **Updated**: Synced release with ORMed dev+7.

## 0.1.0

- **Release**: Promote Artisanal to a stable 0.1.0 release.
- **Changed**: Console labeled logs no longer append an extra blank line.

## 0.1.0-dev+5

- export args classes

## 0.1.0-dev+4

- **Improved**: Aligned with core ormed releases for advanced ORM features.
- **Updated**: Dependencies bumped to latest stable versions.

## 0.1.0-dev+3

- Synchronized release.

## 0.1.0-dev+2

- Synchronized release with ormed_cli rebranding.

## 0.1.0-dev+1

- Internal version bump to align with ORMed release.

## 0.1.0-dev

- Initial release.
