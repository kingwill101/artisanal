# Ultraviolet

`ultraviolet` is the standalone UV rendering package extracted from `artisanal`.
It contains the terminal cell, renderer, input, and graphics primitives used by
Artisanal TUI internals.

## Installation

```yaml
dependencies:
  ultraviolet: any
```

## Preferred Imports

```dart
import 'package:ultraviolet/ultraviolet.dart';
```

## Compatibility

`package:artisanal/uv.dart` remains in-tree as a compatibility re-export so
existing imports continue to work while migration proceeds.

## Notes

- For legacy examples and integrations that rely on `artisanal`, this package can
  still be consumed indirectly through `package:artisanal/uv.dart`.
- Prefer importing `package:ultraviolet/ultraviolet.dart` for new code.
