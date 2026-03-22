# Layout

```bash
dart run example/tui/examples/layout/main.dart
```

This example uses `Layout.joinVertical` and `Layout.joinHorizontal` to compose
three information cards that reflow as terminal width changes.

What to expect:

- Width >= 120 uses a 3-column layout.
- Width 70-119 uses 2 columns.
- Width < 70 stacks cards vertically.
- Resize your terminal and watch card widths and arrangement update on
  `WindowSizeMsg`.
