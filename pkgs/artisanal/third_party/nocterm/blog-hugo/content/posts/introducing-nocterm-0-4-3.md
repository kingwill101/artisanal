---
title: "Nocterm v0.4.3: Improved Rendering, New Components, and Better Testing"
date: 2026-01-26
description: "The latest release brings significant rendering performance improvements, new layout components, expanded image support, and updates to the testing framework."
author: "Nocterm Team"
tags: ["release", "components", "performance"]
---

We're excited to announce **Nocterm v0.4.3**, the latest release of the Flutter-like TUI framework for Dart. This release focuses on rendering reliability, new component capabilities, experimental image support, and improvements to the testing framework.

## Rendering Improvements

The core rendering pipeline has received attention in this release. The **Unicode block encoder** — used for drawing borders, box characters, and block elements — has been updated to handle edge cases that previously caused visual artifacts in certain CI environments and non-UTF-8 locales.

Differential rendering, which only redraws parts of the terminal that have actually changed, continues to be the default. In v0.4.3, we've tightened the diffing logic so that rapid `setState()` calls during animations produce fewer unnecessary redraws.

## Image Support (Experimental)

One of the most requested features is now available as an **experimental** API. Nocterm can now render images directly in the terminal using protocols like Kitty and iTerm2 inline images.

```dart
class ImageDemo extends StatelessComponent {
  Component build(BuildContext context) {
    return Column(children: [
      Text('Image Preview:'),
      Image.file('assets/logo.png',
        width: 40,
        height: 20,
      ),
    ]);
  }
}
```

> Image support is marked as experimental and the API may change in future releases. Terminal support varies — Kitty, iTerm2, and WezTerm offer the best experience. See the [documentation](https://docs.nocterm.dev) for details.

## Testing Framework Updates

The `testNocterm()` testing API has been refined based on community feedback. Key changes include:

- **Unicode handling fixes** — Tests involving Unicode block characters now produce consistent results across macOS, Linux, and CI environments.
- **Better `debugPrintAfterPump`** — The visual debugging output now shows clearer cell boundaries, making it easier to spot alignment issues during development.
- **Terminal size configuration** — You can now pass a custom `size` parameter to test components at different terminal dimensions.

```dart
await testNocterm(
  'responsive layout',
  (tester) async {
    await tester.pumpComponent(MyComponent());
    expect(tester.terminalState, containsText('Header'));
  },
  size: Size(40, 20),
  debugPrintAfterPump: true,
);
```

## New and Updated Components

### Container Enhancements

`Container` now supports gradient backgrounds via `BoxDecoration`. This lets you create more visually interesting panels without resorting to custom painting.

### Improved ListView Performance

`ListView.builder` now lazily builds only the visible items plus a small buffer, reducing memory usage for lists with thousands of items. If you were already using `ListView.builder`, you get this improvement automatically.

### TextField Improvements

The `TextField` component has received several quality-of-life improvements:

- Cursor position is now preserved across `setState()` rebuilds
- Selection and copy/paste support for terminals that support it
- New `obscureText` property for password fields

## Breaking Changes

This release has **no breaking changes**. All existing code should work without modification. The image API is additive and marked experimental.

## Upgrading

Update your `pubspec.yaml`:

```yaml
dependencies:
  nocterm: ^0.4.3
```

Or run:

```bash
$ dart pub upgrade nocterm
```

## What's Next

We're working on several features for upcoming releases:

- **Scrollable widgets** — More flexible scroll containers beyond ListView
- **Overlay system** — Tooltips, dropdowns, and modals that render above other content
- **Web target** — Compile nocterm apps to run in a browser-based terminal (you can already see this on [nocterm.dev](https://nocterm.dev))

---

Thanks to everyone who contributed bug reports, pull requests, and feedback. If you run into issues, please [open an issue on GitHub](https://github.com/Norbert515/nocterm/issues).
