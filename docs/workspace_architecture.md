# Artisanal Workspace Architecture

The workspace is centered on reusable terminal UI primitives and rendering,
with app-level behavior built on top.

## Package Boundaries

1. `artisanal`: core terminal toolkit (styles, layout, markdown, TUI runtime).
2. `artisanal_widgets`: composable widget system and higher-level UI widgets.
3. `ultraviolet`: low-level UV terminal renderer and graphics primitives.
4. `artisanal_capture`: consumer APIs and CLI for deterministic cell snapshots
   and native image exports. Pixel rendering remains in `ultraviolet`.

## Applications

Standalone applications live in `apps/` and remain Dart workspace members.
They consume the toolkit packages without becoming part of the framework.

- `apps/artisanal_editor`: terminal editor application.
- `apps/github_cli`: GitHub terminal dashboard, moved out of the widget examples.
  See its [README](../apps/github_cli/README.md) for setup and run commands.

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
