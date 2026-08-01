# Artisanal Documentation Index

This index links the current primary documentation across the workspace.

## Getting Started

> **Package READMEs** are in the repository root: `pkgs/artisanal/`, `pkgs/ultraviolet/`, and `pkgs/artisanal_widgets/`.

## Core Toolkit

- Architecture overview (detailed): [architecture.md](architecture.md)
- Architecture overview (concise): [workspace_architecture.md](workspace_architecture.md)
- Console I/O: [console.md](console.md)
- Args runner: [args.md](args.md)
- Terminal abstraction: [terminal.md](terminal.md)
- Renderer abstraction: [renderer.md](renderer.md)

## Styling and Layout

- Style system: [style.md](style.md)
- Layout utilities: [layout.md](layout.md)
- Unicode utilities: [unicode.md](unicode.md)
- Color profiles: [colorprofile.md](colorprofile.md)

## TEA Programming Model

> Build UIs with `implements Model` + `runProgram()`. Direct, lightweight, composable with Bubbles.

- TUI runtime and inline mode: [tui.md](tui.md)
- Inline non-alt-screen TUIs: [inline_tui.md](inline_tui.md)
- Replay automation: [replay.md](replay.md)
- TEA-composable Bubbles components: [bubbles.md](bubbles.md)
- Console component helpers: [io_components.md](io_components.md)

## Widget System

> Flutter-inspired widget tree. Use `StatelessWidget` / `StatefulWidget` + `runArtisanalApp()`.

- Widget catalog: [widgets.md](widgets.md)
- Animation timeline and tween system: [animation.md](animation.md)
- Remote plugin surfaces and slot registry: [plugins.md](plugins.md)

## Rendering and Content

- UV system: [uv.md](uv.md)
- Markdown rendering (ANSI + Glamour): [markdown.md](markdown.md)
- Charting primitives: [charting.md](charting.md)
- Terminal graphics (Sixel / Kitty / iTerm2): [terminal_graphics.md](terminal_graphics.md)

## Testing and Debugging

- Widget testing harness and utilities: [testing.md](testing.md)
- TUI replay automation: [replay.md](replay.md)

## Experimental

- Liquid templates: [liquid.md](liquid.md)
- Physics helpers: [physics.md](physics.md)
