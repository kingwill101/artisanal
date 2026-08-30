# Artisanal Workspace Architecture

The workspace is centered on reusable terminal UI primitives and rendering,
with app-level behavior built on top.

## Package Boundaries

1. `artisanal`: core terminal toolkit (styles, layout, markdown, TUI runtime).
2. `artisanal_test`: backend-neutral PTY scenario and trace primitives for
   end-to-end terminal application testing.
3. `artisanal_widgets`: composable widget system and higher-level UI widgets.
4. `ultraviolet`: low-level UV terminal renderer and graphics primitives.

## Core Principles

1. Keep `artisanal` focused on stable primitives, not app-specific logic.
2. Keep PTY process ownership and test orchestration in `artisanal_test`; do
   not couple the runtime packages to a specific PTY implementation.
3. Build reusable UI components in `artisanal_widgets` without product coupling.
4. Keep renderer concerns (`diff`, sync output, frame behavior) in `ultraviolet`.
5. Treat examples and app shells as consumers, not framework core.

## Non-Goals

1. Embedding product-specific assistant orchestration in core packages.
2. Tight coupling from widgets/examples to external app repos.
3. Mixing renderer internals into widget/business-layer APIs.
4. Treating PTY byte snapshots as a substitute for semantic screen assertions.
