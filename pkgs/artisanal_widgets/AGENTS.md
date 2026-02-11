# AGENTS.md — artisanal_widgets

## Package Overview

`artisanal_widgets` is a Flutter-inspired widget system for terminal UIs, built on top of the `artisanal` terminal toolkit. It lives in `pkgs/artisanal_widgets/` within the artisanal monorepo workspace.

The architecture mirrors Flutter: `Widget` → `Element` → `RenderObject`, with an Elm-style `Model`/`Msg`/`Cmd` message loop driving updates through `WidgetApp`.

## Project Structure

```
lib/
  artisanal_widgets.dart      # Public barrel — main entry point
  testing.dart                # Public barrel — testing utilities (WidgetTester, testWidgets)
  src/widgets/
    core/                     # Widget, Element, framework primitives, Key
    app/                      # WidgetApp — bridges widgets into the TUI program loop
    layout/                   # Row, Column, Container, Text, Padding, Stack, etc.
    components/               # Higher-level widgets: Button, Card, Tabs, Modal, etc.
    input/                    # TextField, text input widgets
    scroll/                   # SingleChildScrollView, ScrollView, scrollbar widgets
    focus/                    # FocusScope, FocusController
    rendering/                # RenderObject, RenderLayout (layout/paint layer)
    theme/                    # Theme, ThemeScope (InheritedWidget-based theming)
    media/                    # MediaQuery, MediaQueryData
    testing/                  # WidgetTester, testWidgets harness
    widgets.dart              # Internal barrel re-exporting all submodules
test/
example/
```

## Import Rules — CRITICAL

**Never use private `src/` imports from the `artisanal` package.** All imports from `artisanal` must go through its public barrels:

| Need | Import |
|------|--------|
| Cmd, Msg, Model, Program, View, zone types | `package:artisanal/tui.dart` |
| Style, Color, Layout, Border, properties | `package:artisanal/style.dart` |
| Terminal, Key, KeyType, Keys, RawModeGuard | `package:artisanal/terminal.dart` |
| TextInputModel, ViewportModel, Spinner, etc. | `package:artisanal/bubbles.dart` |
| Canvas, Cell, StyledString, UvStyle, UvColor | `package:artisanal/uv.dart` |

### Why `show` clauses are required on `tui.dart`

`package:artisanal/tui.dart` re-exports `package:artisanal_widgets/artisanal_widgets.dart`. Importing it without `show` from within this package creates ambiguous names. **Always use `show` clauses** when importing `tui.dart` from widget source files:

```dart
import 'package:artisanal/tui.dart' show Cmd, Msg, KeyMsg, MouseMsg, View;
```

### Name collisions with `style.dart`

`style.dart` exports `Padding`, `Align`, and `Margin` as style property types. This package defines widget classes with the same names. When both are needed, hide the style versions:

```dart
import 'package:artisanal/style.dart' hide Padding, Align;
```

### Within this package

- Use **relative imports** between sibling source files (`../core/widget.dart`).
- Tests and examples must import through the **public barrels**: `package:artisanal_widgets/artisanal_widgets.dart` and `package:artisanal_widgets/testing.dart`.
- Never import from `package:artisanal_widgets/src/...` in tests or examples.

## Architecture Essentials

### Widget lifecycle

1. `Widget` is a stateless description (like Flutter's `Widget`).
2. `Element` holds mutable state and sits in the element tree.
3. `RenderObject` handles layout (constraints-in, size-out) and painting to a `Canvas`.
4. `WidgetApp` implements `Model` and wires the element tree into the artisanal TUI program loop.

### Key base classes

- **`StatelessWidget`** — `build(BuildContext)` returns a child widget tree.
- **`StatefulWidget`** / **`State`** — mutable state with `setState()` triggering rebuilds.
- **`InheritedWidget`** — data propagation down the tree (used by `ThemeScope`, `MediaQuery`).
- **`SingleChildRenderObjectWidget`** / **`MultiChildRenderObjectWidget`** — widgets backed by render objects.

### Message dispatch

Messages flow: `Program` → `WidgetApp.update(msg)` → `ElementTree.dispatch(msg)` → each element's `handleUpdate(msg)`.

Mouse events use **render-tree hit-testing** (not zone scanning) by default. `GestureDetector` callbacks (`onTap`, `onTapDown`, `onTapUp`, `onWheel`, `onHover`) fire via `HitTestMouseMsg`.

## Testing

### Running tests

```bash
cd pkgs/artisanal_widgets
dart test
```

All tests must pass before submitting changes. There are currently 127 tests.

### Writing widget tests

Use `WidgetTester` from `package:artisanal_widgets/testing.dart`:

```dart
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

void main() {
  test('my widget works', () async {
    final tester = w.WidgetTester();
    try {
      await tester.pumpWidget(MyWidget());
      expect(tester.find.text('hello'), isTrue);
      tester.sendChar('+');
      expect(tester.find.text('count: 1'), isTrue);
    } finally {
      await tester.dispose();
    }
  });
}
```

`WidgetTester` runs a real `Program` with a mock terminal — message coalescing, command execution, and the full update→render cycle behave exactly as at runtime.

### Test helpers

- `test/mock_terminal.dart` — lightweight `Terminal` mock for program-level tests.
- `tester.sendChar(c)` / `tester.sendSpecialKey(type)` — simulate keyboard input.
- `tester.tapAt(x, y)` — simulate mouse clicks via hit-testing.
- `tester.find.text(s)` — assert rendered output contains text.

## Analysis & Formatting

```bash
dart analyze           # Must report zero errors
dart format .          # Must produce no changes
```

The `analysis_options.yaml` uses `package:lints/recommended.yaml` with no custom suppressions.

## Adding a New Widget

1. **Choose the right submodule**: `layout/` for primitives, `components/` for higher-level compound widgets, `input/` for text-entry widgets, `scroll/` for scrollable containers.
2. **Extend the correct base class**: `StatelessWidget` for pure rendering, `StatefulWidget` for mutable state, `SingleChildRenderObjectWidget` for layout-aware widgets.
3. **Export it** from the appropriate barrel file (e.g., add a `part` directive in `components_widgets.dart` or an `export` in `widgets.dart`).
4. **Add tests** in `test/` importing only from public barrels.
5. **Use the theme** — access colors via `Theme.of(context)` or `ThemeScope`, not hardcoded values.

## Common Patterns

### Accessing theme

```dart
final theme = ThemeScope.of(context);
// or from a Widget subclass:
final color = theme.primary;
```

### Rendering a child widget to a string

```dart
final content = _renderWidget(child);
```

The `_renderWidget` helper (from `_layout_utils.dart`) handles `View` objects, strings, and nested widget `view()` calls.

### Using `GestureDetector` for mouse interaction

```dart
GestureDetector(
  onTap: () { setState(() => _count++); },
  child: Text('Click me'),
)
```

### Scrollable content

```dart
SingleChildScrollView(
  child: Column(children: longList),
)
```

## Workspace Context

This package is part of the `artisanal` Dart workspace:

- **`pkgs/artisanal`** — core toolkit (style, TUI runtime, bubbles, UV renderer, terminal).
- **`pkgs/artisanal_widgets`** — this package (widget system).

The two packages have a circular path dependency (artisanal depends on artisanal_widgets to re-export it; artisanal_widgets depends on artisanal for core functionality). This is intentional and works within the Dart workspace. The `show` clause convention on `tui.dart` imports prevents ambiguity.

After making changes here, also run the artisanal package tests to catch regressions:

```bash
cd pkgs/artisanal && dart test
```
