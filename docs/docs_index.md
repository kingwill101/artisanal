# Artisanal docs

Artisanal helps you build command-line tools and interactive terminal apps in
Dart. You can use a small piece of it for nicer console output or build an
entire application with keyboard, mouse, animation, and rich layouts.

You do not need to learn the whole toolkit before you begin. Pick the path that
looks most like what you are building.

## What do you want to build?

### A command or CLI

Start with [console output](console.md) for messages, prompts, tables, and
progress. Add the [command runner](args.md) if your app has subcommands,
options, help text, or shell completion. Use [styles](style.md) when you want
more control over colors and layout.

### An interactive terminal app

Artisanal offers two ways to structure one:

- Choose the [TEA runtime](tui.md) when you want a small, explicit
  `Model` → `update` → `view` loop and direct control over messages and
  commands.
- Choose the [widget system](widgets.md) when your app has screens, forms,
  reusable components, navigation, or Flutter-style state.

Both use the same runtime and renderer, so this is a choice about how you want
to organize your code—not a choice between separate platforms. If your app
needs to share the screen with normal shell output, read the
[inline TUI guide](inline_tui.md).

### A low-level renderer or terminal integration

Use [Ultraviolet](uv.md) when you need to draw cells directly, build a custom
renderer, decode terminal input, or work with Kitty, Sixel, and iTerm2 images.
Most applications can stay at the TUI or widget layer.

## Common tasks

| I want to… | Start here |
|---|---|
| Ask questions or show progress in a CLI | [Console output](console.md) |
| Add subcommands and flags | [Commands and arguments](args.md) |
| Style text, borders, and layouts | [Terminal styling](style.md) |
| Add inputs, lists, and reusable TEA components | [Interactive components](bubbles.md) |
| Render Markdown | [Markdown in the terminal](markdown.md) |
| Draw charts or sequence diagrams | [Terminal charts](charting.md) |
| Test a widget app | [Widget testing](testing.md) |
| Record or replay a TUI session | [Replay and tracing](replay.md) |
| Show terminal images | [Terminal graphics](terminal_graphics.md) |
| Understand how the packages fit together | [Architecture](architecture.md) |

## Packages at a glance

- `artisanal` contains CLI output, styling, the TEA runtime, and the umbrella
  APIs.
- `artisanal_widgets` contains the widget framework and focused widget
  libraries.
- `ultraviolet` contains low-level buffers, rendering, input, and terminal
  graphics.

## Advanced and experimental topics

- [Renderer backends](renderer.md)
- [Terminal access](terminal.md)
- [Color detection](colorprofile.md)
- [Unicode width and graphemes](unicode.md)
- [Remote UI plugins](plugins.md)
- [Liquid templates](liquid.md) (experimental)
- [Physics helpers](physics.md) (experimental)
