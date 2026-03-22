# Style System

The Artisanal Style system provides a fluent, chainable API for styling terminal output. Inspired by Go's [Lip Gloss](https://github.com/charmbracelet/lipgloss) library, it enables composable styling with support for colors, borders, padding, margins, alignment, and more.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Color System](#color-system)
  - [BasicColor](#basiccolor)
  - [AnsiColor](#ansicolor)
  - [AdaptiveColor](#adaptivecolor)
  - [CompleteColor](#completecolor)
  - [CompleteAdaptiveColor](#completeadaptivecolor)
  - [Color Presets](#color-presets)
  - [ColorProfile](#colorprofile)
- [Text Styling](#text-styling)
- [Layout Properties](#layout-properties)
  - [Padding](#padding)
  - [Margin](#margin)
  - [Alignment](#alignment)
- [Borders](#borders)
  - [Border Presets](#border-presets)
  - [BorderSides](#bordersides)
  - [Border Colors](#border-colors)
- [Width and Height](#width-and-height)
- [LipList](#liplist)
- [Layout Composition](#layout-composition)
- [Rendering and Color Degradation](#rendering-and-color-degradation)
- [Style Composition](#style-composition)
- [Theme System](#theme-system)
- [Ranges and ANSI Slicing](#ranges-and-ansi-slicing)
- [Color Blending Utilities](#color-blending-utilities)
- [Print Helpers](#print-helpers)
- [Console Tag Parser](#console-tag-parser)
- [UV System Integration](#uv-system-integration)

---

## Overview

The Style system is designed around a fluent API where each method returns the Style instance, allowing method chaining:

```dart
import 'package:artisanal/style.dart';

final style = Style()
    .bold()
    .foreground(Colors.green)
    .padding(1, 2)
    .border(Border.rounded)
    .width(40);

print(style.render('Hello World'));
```

Key features:
- **Fluent API**: Chain methods for readable style definitions
- **Composable**: Styles can be copied and extended
- **Color Profile Aware**: Automatic degradation for terminal capabilities
- **Adaptive Colors**: Light/dark terminal background detection
- **Layout System**: Padding, margin, borders, and alignment
- **Unicode Support**: Proper handling of wide characters and grapheme clusters

---

## Quick Start

### Basic Text Styling

```dart
import 'package:artisanal/style.dart';

// Bold green text
final success = Style()
    .bold()
    .foreground(Colors.success)
    .render('Operation completed!');

// Red error with background
final error = Style()
    .foreground(Colors.white)
    .background(Colors.error)
    .padding(0, 1)
    .render(' ERROR ');

// Styled box
final box = Style()
    .foreground(Colors.cyan)
    .border(Border.rounded)
    .padding(1, 2)
    .width(30)
    .align(HorizontalAlign.center)
    .render('Welcome!');

print(success);
print(error);
print(box);
```

### Pre-set String Values

Styles can have pre-set string content using `setString()`, useful for reusable styled components:

```dart
final divider = Style()
    .foreground(Colors.muted)
    .padding(0, 1)
    .setString('|');

print('Item 1$divider Item 2$divider Item 3');
// Output: Item 1 | Item 2 | Item 3
```

---

## Color System

Artisanal provides a flexible color abstraction that adapts to terminal capabilities.

### BasicColor

The most common color type, supporting hex strings and ANSI code strings:

```dart
// Hex colors (with or without #)
final red = BasicColor('#ff0000');
final blue = BasicColor('3b82f6');
final shortHex = BasicColor('#f00');  // Expands to #ff0000

// ANSI code as string
final ansiRed = BasicColor('196');
final ansiBlue = BasicColor('21');

Style().foreground(red).render('Red text');
```

### AnsiColor

Explicit ANSI-256 color codes (0-255):

```dart
final color = AnsiColor(196);  // Bright red
final blue = AnsiColor(21);    // Blue

Style().foreground(color).render('Colored text');
```

ANSI codes 0-15 map to the basic 16-color palette:
- 0-7: Standard colors (black, red, green, yellow, blue, magenta, cyan, white)
- 8-15: Bright variants

### AdaptiveColor

Colors that adapt based on terminal background (light or dark):

```dart
// Automatically uses appropriate color for terminal background
final textColor = AdaptiveColor(
  light: Colors.black,  // Used on light terminals
  dark: Colors.white,   // Used on dark terminals
);

Style().foreground(textColor).render('Adaptive text');
```

The `hasDarkBackground` property on Style controls which variant is used (defaults to `true`).

### CompleteColor

Explicit values for each color profile, bypassing automatic degradation:

```dart
final brandColor = CompleteColor(
  trueColor: '#ff5500',   // 24-bit RGB
  ansi256: '208',         // 256-color palette
  ansi: '1',              // Basic 16-color (red)
);

Style().foreground(brandColor).render('Brand text');
```

This ensures your brand colors look intentional across all terminal types.

### CompleteAdaptiveColor

Combines CompleteColor with light/dark adaptation:

```dart
final brandColor = CompleteAdaptiveColor(
  light: CompleteColor(
    trueColor: '#0044aa',
    ansi256: '25',
    ansi: '4',  // Blue
  ),
  dark: CompleteColor(
    trueColor: '#66aaff',
    ansi256: '117',
    ansi: '6',  // Cyan
  ),
);
```

### Color Presets

The `Colors` class provides commonly used color presets:

```dart
// Semantic colors
Colors.success   // Green (#22c55e)
Colors.error     // Red (#ef4444)
Colors.warning   // Amber (#f59e0b)
Colors.info      // Blue (#3b82f6)
Colors.muted     // Gray (#6b7280)

// Basic colors
Colors.black, Colors.red, Colors.green, Colors.yellow
Colors.blue, Colors.magenta, Colors.cyan, Colors.white

// Bright variants
Colors.brightRed, Colors.brightGreen, Colors.brightBlue, ...

// Gray scale
Colors.gray50, Colors.gray100, ... Colors.gray900

// Accent colors
Colors.purple, Colors.pink, Colors.orange, Colors.teal
Colors.indigo, Colors.rose, Colors.lime, Colors.sky

// Special
Colors.none  // No color (transparent)

// Factory methods
Colors.hex('#ff5500')
Colors.ansi(196)
Colors.rgb(255, 85, 0)
Colors.adaptive(light: Colors.black, dark: Colors.white)
```

### ColorProfile

The color profile determines how colors are rendered:

```dart
enum ColorProfile {
  ascii,      // No ANSI support (plain text)
  noColor,    // NO_COLOR: SGR supported but colors disabled
  ansi,       // Basic 16-color
  ansi256,    // 256-color palette
  trueColor,  // 24-bit RGB (default)
}
```

Set the profile on a Style:

```dart
final style = Style()
    .foreground(Colors.purple);

style.colorProfile = ColorProfile.ansi256;
print(style.render('Text'));  // Uses 256-color mode
```

---

## Text Styling

### Basic Attributes

```dart
Style()
    .bold()              // Bold text
    .italic()            // Italic text
    .underline()         // Underlined text
    .strikethrough()     // Strikethrough text
    .dim()               // Dimmed/faint text (alias: faint())
    .inverse()           // Reverse video (alias: reverse())
    .blink()             // Blinking text (limited support)
```

All attribute methods accept an optional boolean:

```dart
Style().bold(true)   // Enable
Style().bold(false)  // Explicitly disabled
```

### Underline Styles

Advanced underline variants (terminal support varies):

```dart
Style().underlineStyle(UnderlineStyle.single)   // Standard underline
Style().underlineStyle(UnderlineStyle.double)   // Double underline
Style().underlineStyle(UnderlineStyle.curly)    // Wavy underline
Style().underlineStyle(UnderlineStyle.dotted)   // Dotted underline
Style().underlineStyle(UnderlineStyle.dashed)   // Dashed underline
Style().underlineStyle(UnderlineStyle.none)     // No underline
```

### Underline Color

```dart
Style()
    .underline()
    .underlineColor(Colors.red)
    .render('Error text');
```

### Space Handling

Control whether underline and strikethrough apply to spaces:

```dart
Style()
    .underline()
    .underlineSpaces(true)      // Underline spaces too
    .strikethrough()
    .strikethroughSpaces(true)  // Strike through spaces
```

### Hyperlinks

Add OSC 8 hyperlinks (terminal support varies):

```dart
Style()
    .hyperlink('https://example.com')
    .foreground(Colors.blue)
    .underline()
    .render('Click here');

// With parameters
Style()
    .hyperlink('https://example.com', params: 'id=my-link')
```

### Text Transform

Apply transformations to text before rendering:

```dart
Style()
    .transform((s) => s.toUpperCase())
    .render('hello');  // Outputs: HELLO
```

### Unsetting Properties

Remove specific styling:

```dart
final base = Style().bold().italic().foreground(Colors.red);
final modified = base.copy()
    ..unsetBold()
    ..unsetForeground();
```

Available unset methods:
- `unsetBold()`, `unsetItalic()`, `unsetUnderline()`, `unsetStrikethrough()`
- `unsetDim()`, `unsetInverse()`, `unsetBlink()`
- `unsetForeground()`, `unsetBackground()`
- `unsetWidth()`, `unsetHeight()`, `unsetMaxWidth()`, `unsetMaxHeight()`
- `unsetPadding()`, `unsetMargin()`, `unsetAlign()`
- `unsetBorder()`, `unsetTransform()`, `unsetHyperlink()`

### InteractiveStyle

`InteractiveStyle` handles state-based styling for hover, focus, active, and
disabled states.

```dart
final style = InteractiveStyle(
  normal: Style().foreground(Colors.white),
  hover: Style().foreground(Colors.cyan).bold(),
  focus: Style().foreground(Colors.yellow).underline(),
  active: Style().foreground(Colors.brightCyan).inverse(),
  disabled: Style().foreground(Colors.muted).dim(),
);

// Resolve the correct style based on current state
final current = style.resolve(
  isHovered: true,
  isFocused: false,
);
```

- **Precedence**: Higher-priority states (like `active`) override lower-priority
  ones (like `hover`) during resolution.
- **Fallback**: If a specific state style is missing, it falls back to the
  `normal` style.
- **Composition**: Easily build interactive widgets that react to user input
  using a single style definition.

---

### WCAG Contrast Checking

The `accessibility.dart` module provides helpers for ensuring readable color
combinations.

```dart
import 'package:artisanal/style.dart';

final bg = Colors.hex('#1e293b');
final fg = Colors.hex('#f8fafc');

final ratio = contrastRatio(fg, bg);
final passesAA = meetsWcagAA(fg, bg);

// Automatically pick the best text color for a background
final bestFg = bestTextColor(bg, dark: Colors.black, light: Colors.white);
```

- **Contrast Ratio**: Calculates the relative luminance ratio (1:1 to 21:1).
- **WCAG AA/AAA**: Validates against standard accessibility thresholds (4.5:1
  for AA, 7:1 for AAA).
- **Adaptive Resolution**: Correctly handles `AdaptiveColor` by resolving
  against the terminal's background luminance.

---

## Layout Properties

### Padding

Padding adds space between content and its border (internal spacing):

```dart
// All sides
Style().padding(2)

// Vertical, horizontal
Style().padding(1, 2)  // 1 top/bottom, 2 left/right

// Individual: top, right, bottom, left
Style().padding(1, 2, 3, 4)

// Per-side methods
Style()
    .paddingTop(1)
    .paddingRight(2)
    .paddingBottom(1)
    .paddingLeft(2)
```

**Padding class:**

```dart
Padding.all(2)                                    // All sides
Padding.symmetric(vertical: 1, horizontal: 2)     // Symmetric
Padding.only(top: 1, left: 2)                     // Specific sides
Padding(top: 1, right: 2, bottom: 3, left: 4)     // Explicit
Padding.zero                                       // No padding

// Properties
padding.top, padding.right, padding.bottom, padding.left
padding.horizontal  // left + right
padding.vertical    // top + bottom
padding.isZero
```

Custom padding character:

```dart
Style()
    .padding(1, 2)
    .paddingChar('.')  // Use dots instead of spaces
```

### Margin

Margin adds space outside the border (external spacing):

```dart
// All sides
Style().margin(2)

// Vertical, horizontal
Style().margin(1, 2)

// Individual: top, right, bottom, left
Style().margin(1, 2, 3, 4)

// Per-side methods
Style()
    .marginTop(1)
    .marginRight(2)
    .marginBottom(1)
    .marginLeft(2)

// Margin background color
Style()
    .margin(1)
    .marginBackground(Colors.gray800)
```

**Margin class:**

```dart
Margin.all(2)
Margin.symmetric(vertical: 1, horizontal: 2)
Margin.only(top: 1, left: 2)
Margin(top: 1, right: 2, bottom: 3, left: 4)
Margin.zero
```

### Alignment

#### Horizontal Alignment

```dart
Style().align(HorizontalAlign.left)    // or alignLeft()
Style().align(HorizontalAlign.center)  // or alignCenter()
Style().align(HorizontalAlign.right)   // or alignRight()
```

#### Vertical Alignment

```dart
Style().alignVertical(VerticalAlign.top)     // or alignTop()
Style().alignVertical(VerticalAlign.center)  // or alignMiddle()
Style().alignVertical(VerticalAlign.bottom)  // or alignBottom()
```

#### Combined Alignment

```dart
// Set both at once
Style().align(HorizontalAlign.center, VerticalAlign.middle)
```

**Align class for combined alignment:**

```dart
Align.topLeft
Align.topCenter
Align.topRight
Align.centerLeft
Align.center
Align.centerRight
Align.bottomLeft
Align.bottomCenter
Align.bottomRight
```

---

## Borders

### Border Presets

```dart
Style().border(Border.normal)       // Standard single-line: ┌─┐│└─┘
Style().border(Border.rounded)      // Rounded corners: ╭─╮│╰─╯
Style().border(Border.thick)        // Heavy lines: ┏━┓┃┗━┛
Style().border(Border.double)       // Double lines: ╔═╗║╚═╝
Style().border(Border.block)        // Full blocks: ████
Style().border(Border.outerHalfBlock)  // Outer half-blocks: ▛▀▜▌▐▙▄▟
Style().border(Border.innerHalfBlock)  // Inner half-blocks: ▗▄▖▐▌▝▀▘
Style().border(Border.hidden)       // Invisible (preserves layout)
Style().border(Border.ascii)        // ASCII compatible: +--+||+--+
Style().border(Border.markdown)     // Markdown table style
Style().border(Border.none)         // No border
```

### Custom Borders

```dart
final custom = Border(
  top: '═',
  bottom: '═',
  left: '║',
  right: '║',
  topLeft: '╔',
  topRight: '╗',
  bottomLeft: '╚',
  bottomRight: '╝',
  // Optional middle connectors for tables
  middleLeft: '╠',
  middleRight: '╣',
  middleTop: '╦',
  middleBottom: '╩',
  middle: '╬',
);

Style().border(custom)
```

### BorderSides

Control which sides of the border are visible:

```dart
// Specify sides inline
Style().border(Border.rounded, top: true, bottom: true)
Style().border(Border.rounded, left: true, right: true)

// Use BorderSides
Style()
    .border(Border.rounded)
    .borderSides(BorderSides(top: true, bottom: true, left: false, right: false))

// Presets
BorderSides.all          // All sides visible (default)
BorderSides.none         // No sides visible
BorderSides.horizontal   // Top and bottom only
BorderSides.vertical     // Left and right only
BorderSides.topOnly      // Top only
BorderSides.bottomOnly   // Bottom only

// Per-side methods
Style()
    .border(Border.rounded)
    .borderTop(true)
    .borderBottom(true)
    .borderLeft(false)
    .borderRight(false)
```

### Border Colors

```dart
// All borders same color
Style()
    .border(Border.rounded)
    .borderForeground(Colors.cyan)
    .borderBackground(Colors.gray800)

// Per-side colors
Style()
    .border(Border.rounded)
    .borderTopForeground(Colors.red)
    .borderRightForeground(Colors.green)
    .borderBottomForeground(Colors.blue)
    .borderLeftForeground(Colors.yellow)
    .borderTopBackground(Colors.gray900)
    // ... etc
```

### Border Gradient

Apply a color gradient around the border perimeter:

```dart
Style()
    .border(Border.rounded)
    .borderForegroundBlend([
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ])
    .borderForegroundBlendOffset(5)  // Rotate gradient start
    .width(40)
    .height(10)
    .render('Rainbow border!')
```

---

## Width and Height

### Fixed Dimensions

```dart
Style()
    .width(40)   // Fixed width (wraps/pads to fit)
    .height(10)  // Fixed height (pads to fit)
```

Width wrapping respects word boundaries when possible:

```dart
Style()
    .width(20)
    .render('This is a long sentence that will wrap');
```

### Maximum Dimensions

```dart
Style()
    .maxWidth(80)   // Truncates if wider
    .maxHeight(24)  // Truncates if taller
```

### ANSI-Preserving Wrap

Enable ANSI-preserving wrapping for styled content:

```dart
Style()
    .width(40)
    .wrapAnsi(true)  // Preserve ANSI codes across wrapped lines
```

### Getting Frame Size

```dart
final style = Style()
    .padding(1, 2)
    .border(Border.rounded);

final frame = style.getFrameSize;
print('Border + padding: ${frame.width} x ${frame.height}');
print('Horizontal: ${style.getHorizontalFrameSize}');
print('Vertical: ${style.getVerticalFrameSize}');
```

---

## LipList

Create styled lists with customizable enumerators:

```dart
import 'package:artisanal/style.dart';

// Basic list
final list = LipList.create(['Apples', 'Bananas', 'Cherries']);
print(list);
// • Apples
// • Bananas
// • Cherries

// Numbered list
final numbered = LipList.create(['First', 'Second', 'Third'])
    .enumerator(ListEnumerators.arabic);
print(numbered);
// 1. First
// 2. Second
// 3. Third

// Nested lists
final nested = LipList.create([
  'Fruits',
  LipList.create(['Apples', 'Bananas']),
  'Vegetables',
  LipList.create(['Carrots', 'Broccoli']),
]);
```

### Enumerator Styles

```dart
ListEnumerators.bullet     // • (default)
ListEnumerators.dash       // -
ListEnumerators.asterisk   // *
ListEnumerators.arabic     // 1. 2. 3.
ListEnumerators.alphabet   // A. B. C.
ListEnumerators.roman      // I. II. III.
ListEnumerators.romanLower // i. ii. iii.

// Custom
ListEnumerators.fixed('>')          // Always ">"
ListEnumerators.custom((i) => '[$i]')  // [0] [1] [2]
```

### Indenter Styles

```dart
ListIndenters.space        // Single space
ListIndenters.doubleSpace  // Two spaces
ListIndenters.tab          // Four spaces
ListIndenters.tree         // │ for non-last, space for last
ListIndenters.arrow        // →
ListIndenters.fixed('  ')  // Custom
```

### Styling Lists

```dart
LipList.create(['A', 'B', 'C'])
    .itemStyle(Style().foreground(Colors.cyan))
    .enumeratorStyle(Style().foreground(Colors.yellow).bold())
    .indenterStyle(Style().foreground(Colors.muted))
```

### Dynamic Styling

```dart
LipList.create(['Normal', 'Important', 'Normal'])
    .itemStyleFunc((items, index) {
      if (index == 1) {
        return Style().bold().foreground(Colors.red);
      }
      return Style();
    })
```

### Visibility and Offset

```dart
// Hide items
list.hide(true);

// Show subset of items
list.offset(1, -1);  // Skip first and last
```

---

## Layout Composition

The `Layout` class provides utilities for composing styled blocks:

### Join Horizontal

Place blocks side by side:

```dart
import 'package:artisanal/style.dart';

final left = Style()
    .border(Border.rounded)
    .width(20)
    .render('Left panel');

final right = Style()
    .border(Border.rounded)
    .width(20)
    .render('Right panel');

final combined = Layout.joinHorizontal(
  VerticalAlign.top,
  [left, right],
  gap: 2,  // Optional gap between blocks
);
```

### Join Vertical

Stack blocks vertically:

```dart
final header = Style()
    .bold()
    .align(HorizontalAlign.center)
    .width(40)
    .render('Header');

final content = Style()
    .width(40)
    .render('Content goes here...');

final page = Layout.joinVertical(
  HorizontalAlign.left,
  [header, content],
  gap: 1,
);
```

### Place Content

Position content within a container:

```dart
final centered = Layout.place(
  width: 80,
  height: 24,
  horizontal: HorizontalAlign.center,
  vertical: VerticalAlign.center,
  content: 'Centered!',
);

// With custom whitespace
final fancy = Layout.place(
  width: 40,
  height: 10,
  horizontal: HorizontalAlign.center,
  vertical: VerticalAlign.center,
  content: 'Hello',
  whitespace: WhitespaceOptions(
    chars: '.',
    foreground: Colors.muted,
  ),
);
```

### Stack Layers

Overlay blocks with transparency:

```dart
final background = Style()
    .background(Colors.gray800)
    .width(40)
    .height(10)
    .render('');

final foreground = Style()
    .foreground(Colors.white)
    .render('Overlay text');

final layered = Layout.stack([background, foreground]);
```

### Utility Functions

```dart
Layout.visibleLength('Hello')      // 5 (ignores ANSI codes)
Layout.width('Line 1\nLonger')     // Width of widest line
Layout.height('Line 1\nLine 2')    // Number of lines
Layout.size('Text\nHere')          // (width, height) tuple

Layout.pad('Hello', 10)            // Pad right to width
Layout.padLeft('Hello', 10)        // Pad left to width
Layout.center('Hello', 10)         // Center within width

Layout.truncate('Long text', 5)    // Truncate with ellipsis
Layout.wrap('Long text here', 10)  // Word wrap to width

Layout.stripAnsi('\x1b[31mRed\x1b[0m')  // Returns 'Red'
```

---

## Rendering and Color Degradation

### Color Profile Detection

Colors automatically degrade based on terminal capabilities:

```dart
final style = Style().foreground(BasicColor('#ff5500'));

// TrueColor terminal: Uses exact RGB
style.colorProfile = ColorProfile.trueColor;

// 256-color terminal: Finds nearest ANSI-256 color
style.colorProfile = ColorProfile.ansi256;

// 16-color terminal: Finds nearest basic ANSI color
style.colorProfile = ColorProfile.ansi;

// No color: Strips all color codes
style.colorProfile = ColorProfile.noColor;

// Plain text: Strips all ANSI codes
style.colorProfile = ColorProfile.ascii;
```

### Light/Dark Background

```dart
final style = Style()
    .foreground(AdaptiveColor(
      light: Colors.black,
      dark: Colors.white,
    ));

style.hasDarkBackground = true;   // Uses dark variant
style.hasDarkBackground = false;  // Uses light variant
```

### Rendering to a Renderer

```dart
final style = Style().bold();
final renderer = SomeRenderer();

// Temporarily adopts renderer's profile and writes output
style.renderTo(renderer, 'Text');
```

### Static Utilities

```dart
// Strip ANSI codes
Style.stripAnsi('\x1b[31mRed\x1b[0m');  // 'Red'

// Get visible length
Style.visibleLength('\x1b[31mRed\x1b[0m');  // 3

// Style specific runes
Style.styleRunes(
  'Hello',
  [0, 2, 4],  // Indices to style
  Style().bold(),      // Style for matched indices
  Style().dim(),       // Style for unmatched indices
);
```

---

## Style Composition

### Copying Styles

```dart
final base = Style()
    .foreground(Colors.white)
    .padding(1);

// Create independent copy
final derived = base.copy();
derived.bold();  // Doesn't affect base
```

### Inheriting Properties

Copy only explicitly-set properties from another style:

```dart
final base = Style()
    .foreground(Colors.white)
    .padding(1);

final accent = Style()
    .bold()
    .foreground(Colors.cyan);

// Combined: bold + cyan foreground + padding from base
final combined = base.copy()..inherit(accent);
```

### Checking Properties

```dart
final style = Style().bold().foreground(Colors.red);

style.isBold           // true
style.isItalic         // false
style.hasTextAttributes  // true
style.hasColors        // true
style.hasSpacing       // false
style.isEmpty          // false

style.getForeground    // Colors.red
style.getWidth         // 0 (not set)
style.getPadding       // Padding.zero
```

### Convenience Extensions

```dart
final style = Style();

// Semantic rendering
style.muted('Secondary text')
style.emphasize('Important!')
style.success('Done!')
style.warning('Careful...')
style.error('Failed!')
style.info('Note:')
```

---

## Theme System

Pre-built color palettes for consistent styling:

```dart
import 'package:artisanal/style.dart';

// Use a theme
final theme = ThemePalette.dracula;

Style().foreground(theme.accent).render('Accented');
Style().foreground(theme.success).render('Success!');
Style().foreground(theme.error).render('Error!');
```

### Available Themes

```dart
ThemePalette.dark           // Classic terminal colors
ThemePalette.light          // For light terminal backgrounds
ThemePalette.hacker         // Matrix-inspired green
ThemePalette.ocean          // Calming blue/turquoise
ThemePalette.monokai        // Warm editor theme
ThemePalette.dracula        // Purple accents
ThemePalette.nord           // Arctic bluish palette
ThemePalette.solarizedDark  // Solarized dark variant
ThemePalette.solarizedLight // Solarized light variant
```

### Theme Properties

Each theme provides semantic colors:

```dart
theme.accent       // Primary accent for active elements
theme.accentBold   // Bold variant for titles
theme.text         // Standard text
theme.textDim      // Secondary/dimmed text
theme.textBold     // Emphasized text
theme.border       // Borders and separators
theme.success      // Success indicators (green)
theme.warning      // Warning indicators (yellow)
theme.error        // Error indicators (red)
theme.info         // Info indicators (blue)
theme.highlight    // Special highlights (purple)
theme.background   // Optional background color
```

### Getting Themes by Name

```dart
final theme = ThemePalette.byName('dracula');
final theme = ThemePalette.byName('NORD');  // Case-insensitive
```

### Creating Custom Themes

```dart
final myTheme = ThemePalette(
  accent: Colors.purple,
  accentBold: Colors.brightMagenta,
  text: Colors.gray,
  textDim: Colors.gray600,
  textBold: Colors.white,
  border: Colors.gray700,
  success: Colors.green,
  warning: Colors.yellow,
  error: Colors.red,
  info: Colors.blue,
  highlight: Colors.pink,
);
```

---

## Ranges and ANSI Slicing

```dart
import 'package:artisanal/style.dart';

void main() {
  final ranges = Ranges()
    ..add(0, 5, Style().bold())
    ..add(6, 11, Style().foreground(Colors.cyan));

  final styled = ranges.apply('Hello World');
  final clipped = cutAnsiByCells(styled, 0, 8);

  print(styled);
  print(clipped);
}
```

## Color Blending Utilities

```dart
import 'package:artisanal/style.dart';

void main() {
  final palette = blend1D(Colors.red, Colors.blue, steps: 5);
  for (final color in palette) {
    print(Style().foreground(color).render('###'));
  }

  final grid = blend2D(
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.purple,
    width: 6,
    height: 3,
  );
  for (final row in grid) {
    final line = row.map((c) => Style().foreground(c).render('#')).join('');
    print(line);
  }
}
```

## Print Helpers

```dart
import 'package:artisanal/style.dart';

void main() {
  Println(Style().bold().render('Heading'));
  Printf('Count: %d\n', 3);

  final msg = Sprint(Style().foreground(Colors.yellow).render('Warning'));
  Println(msg);

  final plain = stringForProfile(ColorProfile.ascii, msg);
  Println(plain);
}
```

## Console Tag Parser

```dart
import 'package:artisanal/src/style/tag_parser.dart';

void main() {
  final parser = ConsoleTagParser();
  final segments = parser.parse('<fg=red>Alert</> normal');
  for (final segment in segments) {
    print(segment.toString());
  }
}
```

### Advanced Buffer Stacks

The `ultraviolet` buffer supports nested scissor and opacity stacks for complex
layered UIs.

```dart
buffer.pushScissor(left, top, width, height);
// All drawing is clipped to this rect.
buffer.pushOpacity(0.5);
// All drawing is blended with 50% opacity.

buffer.popOpacity();
buffer.popScissor();
```

- **Monotonic Scissor**: Nested scissors always intersect with the current
  one, ensuring they never expand outside their parents.
- **Cumulative Opacity**: Nested opacities are multiplied (0.5 * 0.5 = 0.25).
- **GPU-Style API**: `push`/`pop` semantics for reliable state restoration.

---

## UV System Integration

The Style system integrates with Artisanal's Ultraviolet (UV) TUI framework through the `UvTuiInputParser` adapter. This allows styles to be used within full-screen terminal applications.

Key integration points:

- **Color conversion**: Style colors can be converted to UV cell colors
- **Event handling**: UV input events can be processed alongside styled output
- **Terminal capabilities**: UV detects terminal features for appropriate color profile selection

```dart
import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';

// In a TUI application
final style = Style()
    .foreground(Colors.cyan)
    .bold();

// Render styled content for display
final output = style.render('Hello from UV!');
```

The UV system provides additional features like:
- Full-screen alternate buffer management
- Mouse input handling
- Keyboard event decoding
- Terminal resize detection
- Image rendering (Sixel, Kitty, iTerm2)

See the UV documentation for full TUI application development.

---

## Console Tag Syntax

The Style system supports Symfony/Laravel-style console tags for inline styling:

```dart
final text = '<fg=red>Error:</> Something went wrong';
final output = Style().render(text);
// "Error:" is red, rest is default

// Supported attributes
'<fg=green>text</>'           // Foreground color
'<bg=blue>text</>'            // Background color  
'<options=bold>text</>'       // Text options
'<options=bold,underline>'    // Multiple options
'<fg=#ff5500>hex color</>'    // Hex colors
'<href=https://...>link</>'   // Hyperlinks

// Combined
'<fg=white;bg=red;options=bold>ALERT</>'
```

---

## API Reference

### Style Class - Quick Reference

**Text Attributes:**
- `bold()`, `italic()`, `underline()`, `strikethrough()`
- `dim()` / `faint()`, `inverse()` / `reverse()`, `blink()`
- `underlineStyle(UnderlineStyle)`, `underlineSpaces()`, `strikethroughSpaces()`
- `hyperlink(url, {params})`

**Colors:**
- `foreground(Color)`, `background(Color)`, `underlineColor(Color)`
- `borderForeground(Color)`, `borderBackground(Color)`
- `borderTopForeground()`, `borderRightForeground()`, etc.
- `borderForegroundBlend(List<Color>)`, `borderForegroundBlendOffset(int)`
- `marginBackground(Color)`

**Dimensions:**
- `width(int)`, `height(int)`
- `maxWidth(int)`, `maxHeight(int)`

**Spacing:**
- `padding(top, [right, bottom, left])`
- `paddingTop()`, `paddingRight()`, `paddingBottom()`, `paddingLeft()`
- `paddingChar(String)`
- `margin(top, [right, bottom, left])`
- `marginTop()`, `marginRight()`, `marginBottom()`, `marginLeft()`
- `marginChar(String)`

**Alignment:**
- `align(HorizontalAlign, [VerticalAlign])`
- `alignHorizontal()`, `alignVertical()`
- `alignLeft()`, `alignCenter()`, `alignRight()`
- `alignTop()`, `alignMiddle()`, `alignBottom()`

**Borders:**
- `border(Border, {top, right, bottom, left})`
- `borderStyle(Border)`, `borderSides(BorderSides)`
- `borderTop(bool)`, `borderRight(bool)`, `borderBottom(bool)`, `borderLeft(bool)`

**Other:**
- `inline()` - Skip layout processing
- `wrapAnsi()` - ANSI-preserving wrap
- `transform(fn)` - Text transformation
- `tabWidth(int)` - Tab expansion width
- `colorWhitespace(bool)` - Style padding/alignment whitespace
- `setString(value)` - Pre-set string content

**Composition:**
- `copy()` - Create independent copy
- `inherit(Style)` - Merge properties from another style

**Rendering:**
- `render([text])` - Apply style and return ANSI string
- `renderTo(Renderer, [text])` - Render with renderer's settings
- `toString()` - Render pre-set string or debug representation

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [CONSOLE.md](CONSOLE.md) - Console output and tags
- [LAYOUT.md](LAYOUT.md) - Layout helpers
- [COLORPROFILE.md](COLORPROFILE.md) - Color capability detection
