# Flutter-Like Widget API Plan

## Overview

This plan outlines the changes needed to make the Artisanal widget system more closely resemble Flutter's API for foundational widgets, providing a familiar development experience for Flutter developers while maintaining compatibility with existing code.

## Core Principles

1. **Familiarity** - Adopt Flutter's widget naming and API patterns
2. **Practicality** - Focus on what works well for terminal UI
3. **Compatibility** - Maintain backward compatibility with existing code
4. **Simplicity** - Keep the API simple and focused on core functionality
5. **Extensibility** - Design for future expansion

## Phase 1: Core Layout Widgets

### 1.1 Widget Renaming (Backward Compatible)

| Current | Flutter Equivalent | Status |
|---------|--------------------|--------|
| `HBox` | `Row` | Planned |
| `VBox` | `Column` | Planned |
| `Label` | `Text` | Planned |

### 1.2 New Widgets

#### Flex Widget (Base for Row/Column)
```dart
class Flex extends Widget {
  const Flex({
    required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.gap = 0,
    required this.children,
    String? id,
  });
  
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final int gap;
  final List<Widget> children;
}

enum Axis { horizontal, vertical }
enum MainAxisAlignment { start, end, center, spaceBetween, spaceAround, spaceEvenly }
enum CrossAxisAlignment { start, end, center, stretch, baseline }
```

#### Row and Column
```dart
class Row extends Flex {
  const Row({
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    int gap = 0,
    required List<Widget> children,
    String? id,
  }) : super(
          direction: Axis.horizontal,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          gap: gap,
          children: children,
          id: id,
        );
}

class Column extends Flex {
  const Column({
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    int gap = 0,
    required List<Widget> children,
    String? id,
  }) : super(
          direction: Axis.vertical,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          gap: gap,
          children: children,
          id: id,
        );
}
```

#### SizedBox
```dart
class SizedBox extends Widget {
  const SizedBox({
    this.width,
    this.height,
    this.child,
    String? id,
  });
  
  const SizedBox.expand({
    this.child,
    String? id,
  }) : width = double.infinity,
       height = double.infinity,
       child = child,
       _id = id;
  
  const SizedBox.shrink({
    this.child,
    String? id,
  }) : width = 0,
       height = 0,
       child = child,
       _id = id;
  
  final int? width;
  final int? height;
  final Widget? child;
}
```

#### Expanded and Flexible
```dart
class Expanded extends Widget {
  const Expanded({
    this.flex = 1,
    required this.child,
    String? id,
  });
  
  final int flex;
  final Widget child;
}

class Flexible extends Widget {
  const Flexible({
    this.flex = 1,
    this.fit = FlexFit.loose,
    required this.child,
    String? id,
  });
  
  final int flex;
  final FlexFit fit;
  final Widget child;
}

enum FlexFit { tight, loose }
```

### 1.3 Enhanced Container
```dart
class Container extends Widget {
  const Container({
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.alignment,
    String? id,
  });
  
  final Widget? child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final int? width;
  final int? height;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final Alignment? alignment;
}

class Decoration {
  const Decoration({
    this.color,
    this.border,
    this.borderRadius,
  });
  
  final Color? color;
  final Border? border;
  final BorderRadius? borderRadius;
}
```

## Phase 2: Text and Icons

### 2.1 Text Widget
```dart
class Text extends Widget {
  const Text(
    this.data, {
    this.style,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    String? id,
  });
  
  const Text.rich(
    this.textSpan, {
    this.style,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    String? id,
  });
  
  final String? data;
  final TextSpan? textSpan;
  final Style? style;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
}

class TextSpan {
  const TextSpan({
    this.style,
    this.text,
    this.children = const [],
  });
  
  final Style? style;
  final String? text;
  final List<TextSpan> children;
}

enum TextAlign { left, right, center, justify }
enum TextOverflow { clip, ellipsis }
```

### 2.2 Icon Widget
```dart
class Icon extends Widget {
  const Icon(
    this.icon, {
    this.size = 16,
    this.color,
    String? id,
  });
  
  final IconData icon;
  final int size;
  final Color? color;
}

class IconData {
  const IconData(this.codePoint);
  
  final int codePoint;
  String get char => String.fromCharCode(codePoint);
}

class Icons {
  static const add = IconData(0x2b);
  static const remove = IconData(0x2d);
  static const check = IconData(0x2713);
  static const close = IconData(0x2715);
  static const arrowLeft = IconData(0x2190);
  static const arrowRight = IconData(0x2192);
  static const arrowUp = IconData(0x2191);
  static const arrowDown = IconData(0x2193);
}
```

## Phase 3: Stack and Positioning

### 3.1 Stack and Positioned
```dart
class Stack extends Widget {
  const Stack({
    this.alignment = Alignment.topLeft,
    this.fit = StackFit.loose,
    this.overflow = Overflow.clip,
    required this.children,
    String? id,
  });
  
  final Alignment alignment;
  final StackFit fit;
  final Overflow overflow;
  final List<Widget> children;
}

class Positioned extends Widget {
  const Positioned({
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
    String? id,
  });
  
  const Positioned.fill({
    required this.child,
    String? id,
  }) : left = 0,
       top = 0,
       right = 0,
       bottom = 0,
       width = null,
       height = null,
       child = child,
       _id = id;
  
  final int? left;
  final int? top;
  final int? right;
  final int? bottom;
  final int? width;
  final int? height;
  final Widget child;
}

class Alignment {
  const Alignment(this.x, this.y);
  
  static const topLeft = Alignment(-1.0, -1.0);
  static const topCenter = Alignment(0.0, -1.0);
  static const topRight = Alignment(1.0, -1.0);
  static const centerLeft = Alignment(-1.0, 0.0);
  static const center = Alignment(0.0, 0.0);
  static const centerRight = Alignment(1.0, 0.0);
  static const bottomLeft = Alignment(-1.0, 1.0);
  static const bottomCenter = Alignment(0.0, 1.0);
  static const bottomRight = Alignment(1.0, 1.0);
  
  final double x;
  final double y;
}

enum StackFit { loose, expand, passthrough }
enum Overflow { clip, visible }
```

### 3.2 Align and Center
```dart
class Align extends Widget {
  const Align({
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    required this.child,
    String? id,
  });
  
  final Alignment alignment;
  final double? widthFactor;
  final double? heightFactor;
  final Widget child;
}

class Center extends Align {
  const Center({
    double? widthFactor,
    double? heightFactor,
    required Widget child,
    String? id,
  }) : super(
          alignment: Alignment.center,
          widthFactor: widthFactor,
          heightFactor: heightFactor,
          child: child,
          id: id,
        );
}
```

## Phase 4: Interactive Widgets

### 4.1 Button Widgets
```dart
class ElevatedButton extends Widget {
  const ElevatedButton({
    required this.onPressed,
    required this.child,
    this.style,
    String? id,
  });
  
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
}

class OutlinedButton extends Widget {
  const OutlinedButton({
    required this.onPressed,
    required this.child,
    this.style,
    String? id,
  });
  
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
}

class TextButton extends Widget {
  const TextButton({
    required this.onPressed,
    required this.child,
    this.style,
    String? id,
  });
  
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
}

class ButtonStyle {
  const ButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.border,
    this.textStyle,
  });
  
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final Border? border;
  final Style? textStyle;
}
```

### 4.2 TextField
```dart
class TextField extends Widget {
  const TextField({
    this.controller,
    this.decoration = const InputDecoration(),
    this.textAlign = TextAlign.left,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    String? id,
  });
  
  final TextEditingController? controller;
  final InputDecoration decoration;
  final TextAlign textAlign;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
}

class InputDecoration {
  const InputDecoration({
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.border,
    this.contentPadding,
  });
  
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecorationBorder? border;
  final EdgeInsets? contentPadding;
}
```

## Phase 5: Utilities

### 5.1 Padding and ConstrainedBox
```dart
class Padding extends Widget {
  const Padding({
    required this.padding,
    required this.child,
    String? id,
  });
  
  final EdgeInsets padding;
  final Widget child;
}

class ConstrainedBox extends Widget {
  const ConstrainedBox({
    required this.constraints,
    required this.child,
    String? id,
  });
  
  final BoxConstraints constraints;
  final Widget child;
}

class BoxConstraints {
  const BoxConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });
  
  const BoxConstraints.tight(Size size)
      : minWidth = size.width,
        maxWidth = size.width,
        minHeight = size.height,
        maxHeight = size.height;
  
  const BoxConstraints.expand({
    int? width,
    int? height,
  }) : minWidth = width ?? double.infinity,
       maxWidth = width ?? double.infinity,
       minHeight = height ?? double.infinity,
       maxHeight = height ?? double.infinity;
  
  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;
}

class Size {
  const Size(this.width, this.height);
  
  static const zero = Size(0, 0);
  
  final int width;
  final int height;
}
```

### 5.2 Visibility and Opacity
```dart
class Visibility extends Widget {
  const Visibility({
    required this.child,
    this.visible = true,
    this.replacement = const SizedBox.shrink(),
    String? id,
  });
  
  final Widget child;
  final bool visible;
  final Widget replacement;
}

class Opacity extends Widget {
  const Opacity({
    required this.opacity,
    required this.child,
    String? id,
  }) : assert(opacity >= 0.0 && opacity <= 1.0);
  
  final double opacity;
  final Widget child;
}
```

## Phase 6: Enhanced APIs

### 6.1 Improved EdgeInsets
```dart
class EdgeInsets {
  const EdgeInsets.all(int value)
      : top = value,
        right = value,
        bottom = value,
        left = value;

  const EdgeInsets.symmetric({int vertical = 0, int horizontal = 0})
      : top = vertical,
        right = horizontal,
        bottom = vertical,
        left = horizontal;

  const EdgeInsets.only({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  const EdgeInsets.fromLTRB(int left, int top, int right, int bottom)
      : left = left,
        top = top,
        right = right,
        bottom = bottom;

  static const EdgeInsets zero = EdgeInsets.all(0);

  final int top;
  final int right;
  final int bottom;
  final int left;

  EdgeInsets copyWith({
    int? top,
    int? right,
    int? bottom,
    int? left,
  });

  EdgeInsets operator +(EdgeInsets other);
  EdgeInsets operator -(EdgeInsets other);
  bool get isZero;
}
```

## Backward Compatibility

1. **Aliases for existing widgets** - `HBox` → `Row`, `VBox` → `Column`, `Label` → `Text`
2. **Property fallbacks** - Old properties still work with deprecation warnings
3. **Migration guide** - Documentation with examples of before/after
4. **Deprecation plan** - Gradual phase-out of old API over time

## Implementation Timeline

| Phase | Focus | Estimated Time |
|-------|-------|----------------|
| 1 | Core layout widgets (Row/Column/Container) | 2-3 days |
| 2 | Text and icons | 1-2 days |
| 3 | Stack and positioning | 1-2 days |
| 4 | Interactive widgets | 2-3 days |
| 5 | Utilities | 1-2 days |
| 6 | API improvements | 1 day |
| 7 | Documentation and examples | 2 days |
| 8 | Testing | 1-2 days |

**Total: 10-15 days**

## Benefits

- **Familiar API** for Flutter developers
- **Better code reuse** between Flutter and TUI applications
- **Stronger ecosystem** by following Flutter patterns
- **Improved maintainability** with standard API design
- **Easier onboarding** for new developers

## Risks and Mitigations

1. **API complexity** - Keep it simple, focus on core widgets first
2. **Performance impact** - Optimize layout algorithms
3. **Breaking changes** - Maintain backward compatibility through aliases
4. **Over-engineering** - Focus on what's practical for TUI
