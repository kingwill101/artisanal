# Artisanal Workspace Architecture

The workspace is centered on reusable terminal UI primitives and rendering,
with app-level behavior built on top.

## Package Boundaries

1. `artisanal`: core terminal toolkit (styles, layout, markdown, TUI runtime).
2. `artisanal_widgets`: composable widget system and higher-level UI widgets.
3. `ultraviolet`: low-level UV terminal renderer and graphics primitives.

## Core Principles

1. Keep `artisanal` focused on stable primitives, not app-specific logic.
2. Build reusable UI components in `artisanal_widgets` without product coupling.
3. Keep renderer concerns (`diff`, sync output, frame behavior) in `ultraviolet`.
4. Treat examples and app shells as consumers, not framework core.
5. Keep dependencies one-way: `artisanal_widgets` may depend on `artisanal`,
   while `artisanal` must not import or re-export `artisanal_widgets`.

## Non-Goals

1. Embedding product-specific assistant orchestration in core packages.
2. Tight coupling from widgets/examples to external app repos.
3. Mixing renderer internals into widget/business-layer APIs.
