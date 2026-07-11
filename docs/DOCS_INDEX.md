# Artisanal Documentation Index

This index links the current primary documentation across the workspace.

## Getting Started

> **Package READMEs** are in the repository root: `pkgs/artisanal/`, `pkgs/ultraviolet/`, and `pkgs/artisanal_widgets/`.

## Core Toolkit

- Architecture overview (detailed): [ARCHITECTURE.md](ARCHITECTURE.md)
- Architecture overview (concise): [ARCHITECTURE.md](ARCHITECTURE.md)
- Console I/O: [CONSOLE.md](CONSOLE.md)
- Args runner: [ARGS.md](ARGS.md)
- Terminal abstraction: [TERMINAL.md](TERMINAL.md)
- Renderer abstraction: [RENDERER.md](RENDERER.md)

## Styling and Layout

- Style system: [STYLE.md](STYLE.md)
- Layout utilities: [LAYOUT.md](LAYOUT.md)
- Unicode utilities: [UNICODE.md](UNICODE.md)
- Color profiles: [COLORPROFILE.md](COLORPROFILE.md)

## TEA Programming Model

> Build UIs with `implements Model` + `runProgram()`. Direct, lightweight, composable with Bubbles.

- TUI runtime and inline mode: [TUI.md](TUI.md)
- Inline non-alt-screen TUIs: [INLINE_TUI.md](INLINE_TUI.md)
- Replay automation: [REPLAY.md](REPLAY.md)
- TEA-composable Bubbles components: [BUBBLES.md](BUBBLES.md)
- Console component helpers: [IO_COMPONENTS.md](IO_COMPONENTS.md)

## Widget System

> Flutter-inspired widget tree. Use `StatelessWidget` / `StatefulWidget` + `runArtisanalApp()`.

- Widget catalog: [WIDGETS.md](WIDGETS.md)
- Animation timeline and tween system: [ANIMATION.md](ANIMATION.md)
- Remote plugin surfaces and slot registry: [PLUGINS.md](PLUGINS.md)

## Rendering and Content

- UV system: [UV.md](UV.md)
- Markdown rendering (ANSI + Glamour): [MARKDOWN.md](MARKDOWN.md)
- Charting primitives: [CHARTING.md](CHARTING.md)
- Terminal graphics (Sixel / Kitty / iTerm2): [TERMINAL_GRAPHICS.md](TERMINAL_GRAPHICS.md)

## Testing and Debugging

- Widget testing harness and utilities: [TESTING.md](TESTING.md)
- TUI replay automation: [REPLAY.md](REPLAY.md)

## Experimental

- Liquid templates: [LIQUID.md](LIQUID.md)
- Physics helpers: [PHYSICS.md](PHYSICS.md)
