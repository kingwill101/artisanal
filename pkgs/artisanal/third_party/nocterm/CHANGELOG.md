# 0.4.3

## New Features
- **Image Protocol Support**: Implement image rendering in the terminal using the Kitty graphics protocol (experimental)

## Bug Fixes
- **Color Quantization**: Quantize colors in environments without true color support for better compatibility
- **Web Backend**: Fix input handling and debug overlay stack fit issues

## Documentation
- **Image Documentation**: Add documentation for image support and mark as experimental
- **Website**: Add nocterm.dev website link to README

## Refactoring
- **Internal**: Use built-in `getElementForInheritedComponentOfExactType` for cleaner code

## Testing
- **CI Fix**: Fix unicode block encoder tests for CI environment

---

# 0.4.2

## Bug Fixes
- **Refactor**: Use built-in `getElementForInheritedComponentOfExactType` for cleaner code

---

# 0.4.1

## Bug Fixes
- **Test cleanup**: Remove unused variable in test

---

# 0.4.0

## Major Features

### Developer Tools
- **DebugOverlay**: New debug overlay toggled with `Ctrl+G` showing real-time FPS, build/layout/paint timings, memory usage, and CPU usage
- **FrameRate presets**: New `FrameRate` class with common presets (fps30, fps60, fps120, unlimited)

### Scrolling Improvements
- **keyboardScrollable**: New property on `ListView` and `SingleChildScrollView` to enable built-in arrow key scrolling
- **cacheExtent**: New `cacheExtent` property on `ListView` for smoother scrolling with pre-rendered items
- **Offset caching**: Performance optimization for variable-height ListView items

### UI Components
- **Tint widget**: New widget for applying color tints to children
- **ModalBarrier.obscure**: New property to control barrier visibility
- **ColoredBox.obscure**: Consistent obscure support across box widgets
- **BoxConstraints equality**: Added `==` operator for constraint comparison

### Animation
- **ColorTween**: New tween for animating between colors
- **Color.lerp**: Linear interpolation support for colors

## Performance Improvements
- **Paint phase optimization**: Skip paint phase when nothing visual changed
- **ListView cache optimization**: Smarter cache invalidation to avoid excessive rebuilds
- **Relayout on resize**: Proper relayout when terminal constraints change
- **Reduced idle CPU**: Removed forced relayout hack

## Bug Fixes
- **ListView parent data**: Refactored to use parent data for layout offsets
- **Scroll bounds**: Improved ListView scroll bounds clamping
- **Wide character rendering**: Fixed zero-width space handling
- **Scroll lag**: Resolved O(n) ListView performance issues
- **Debug overflow indicator**: Disabled by default
- **Markdown tables**: Use unicode display width for column calculations
- **Analyzer warnings**: Resolved various warnings and unused code

---

# 0.3.5

## Bug Fixes
- **GestureDetector**: Fixed tap not working in ListView and with centered content

---

# 0.3.4

## Bug Fixes
- **Frame rate**: Respect frame rate limiting in TerminalBinding

---

# 0.3.3

## Features
- **BorderTitle rich text**: Added rich text support to border titles
- **Clipping**: Implemented proper clipping in `RenderStack` and `Container`
- **New components**: Added `ClipRect`, `OverflowBox`, and `SizedOverflowBox`

## Bug Fixes
- **Input freeze**: Fixed input freeze from rapid key sequences
- **Mouse wheel**: Fixed stacking order issues with mouse wheel events

---

# 0.3.2

## Bug Fixes
- **Package publishing**: Include `lib/src/third_party` in published package

---

# 0.3.1

## Bug Fixes
- **Multi-child containers**: Pass slot through ProxyElement to maintain child order
- **Stack repaint**: Implement `invokeLayoutCallback` to fix Stack repaint bug

---

# 0.3.0

## Major Features

### Animation System
- **Flutter-like animations**: Complete animation system with `AnimationController`, `Animation`, `Tween`, `Curves`
- **Ticker system**: Proper `Ticker` and `TickerProvider` for frame-based animations
- **AnimatedBuilder**: Widget that rebuilds on animation changes
- **SingleTickerProviderStateMixin**: Mixin for state classes that need animation support

### New Components
- **AsciiText**: Large ASCII art text renderer with extensible font system
  - Built-in fonts: `standard`, `banner`, `block`, `slim`
  - Custom font support via `AsciiFont` extension
- **Builder**: Simple component for inline building (like Flutter's Builder)

### TextField Improvements
- **onKeyEvent callback**: Intercept key events before TextField processes them

## Bug Fixes
- **Overlay state**: Prevent setState call on unmounted OverlayState

## Infrastructure
- **Release workflow**: Automated pub.dev publishing with OIDC
- **Version management**: Enhanced release workflow with custom version and README updates

---

# 0.2.0

## Highlights

This is a **major release** with 100+ commits introducing foundational changes for theming, performance, web support, and developer experience.

### Comprehensive Theming System
- **6 built-in themes**: dark, light, nord, dracula, catppuccin, gruvbox
- **Auto-detection**: Terminal brightness detection via OSC 11, COLORFGBG, and macOS Dark Mode
- New `TuiThemeData`, `TuiColors`, and `TuiTheme` InheritedComponent
- Added `onSuccess` and `onWarning` colors for complete status color pairs

### Differential Rendering (Major Performance Boost)
- Partial rendering that only updates cells that changed since previous frame
- Cell equality comparison (char + style) with previous frame buffer tracking
- Dramatically reduces terminal output for mostly static UIs

### Web Platform Support (Experimental)
- New `WebBackend` abstraction for running in browsers
- Extracted Terminal backend architecture for platform flexibility
- xterm.dart integration experiments

### Monorepo Architecture
- **Melos** for monorepo management with standardized scripts (test, analyze, format, clean)
- New `provider` package for state management
- New `nested` package for organization
- SDK constraint updated to `>=3.5.0`

## Major Features

### UI Components
- **LayoutBuilder**: Constraint-aware layouts (Flutter-like) for responsive designs
- **ValueListenableBuilder**: Reactive widget for `ValueListenable`
- **Rectangle class**: Exposed for geometry operations
- **Border titles**: `BoxDecoration` now supports title property
- **Opacity/Alpha blending**: Proper transparency support
- **Clipping**: Implement clipping with riverpod provider assertions
- **ensureVisible**: Auto-scroll support for ScrollViews

### Input
- **Soft-wrapping TextField**: Text wrapping, selection, and clipboard support
- **SIGINT handling**: Proper Ctrl+C signal handling

### Terminal Features
- **Terminal Color API**: Get/set API with extended OSC handling
- **Service extensions**: Debugging tools including rainbow paint

### CLI & Developer Experience
- **compile command**: Compile and restore shell commands in CLI
- **Args package**: CLI argument parsing
- **Hot reload debounce**: Prevents rapid reload spam
- **HTTP logging**: Logs exposed via HTTP server instead of `log.txt`
- **Pre-commit hook**: Auto-format on commit

### Documentation
- **Full documentation site** at docs.nocterm.dev (Fumadocs + GitHub Pages)
- Updated README with proper badges and guides

## Performance Improvements
- **Differential rendering**: Only redraws changed cells between frames
- **No-flush optimization**: Reduced unnecessary flushes
- **Better frame scheduling**: Smoother animations

## Bug Fixes

### Critical Fixes
- **Center widget**: Now properly expands within bounded constraints (was incorrectly shrinking)
- **Ctrl+C in TextField**: App is now properly quittable again
- **Hot reload assertion**: Fixed crashes during hot reload

### Rendering Fixes
- Fixed unconnected borders in BoxDecoration
- Fixed markdown rendering and nested list items
- Improved emoji handling (including FEOF emojis)

### Other Fixes
- Navigator test stale context (now uses GlobalKey)
- Stateful component inheritance
- TextField `onChange` text mutation issues
- Shell command exceptions
- Frame buffer null assertion removal

## Refactoring & Maintenance
- Hot reload architecture cleanup with shareable classes
- Code organization with proper command classes
- Extensive linting and formatting passes
- Added pubignore for cleaner publishing
- Third-party license notice for Flutter code

---

# 0.1.0

## Breaking Changes

### ListView
- **BREAKING**: Removed automatic keyboard navigation from ListView. Applications must now manually wrap ListView in Focusable for keyboard support:
  ```dart
  // Before (0.0.1)
  ListView(children: [...])

  // After (0.1.0)
  Focusable(
    onKeyEvent: (event) { /* handle navigation */ },
    child: ListView(children: [...]),
  )
  ```

### TextField
- **BREAKING**: Removed automatic tap-to-focus behavior. Manual focus management now required for tap interactions.

## Major Features

### State Management
- **Riverpod Integration**: Complete Riverpod state management with ProviderScope, reactive widgets, and full provider API support
- **Render Theater**: New overlay management system with optimized paint ordering and hit testing
- **Provider Dependencies**: Sophisticated subscription management for reactive UI updates

### UI Components
- **Stack Widget**: Overlapping layout support with positioned/non-positioned children
- **ConstrainedBox**: Min/max width/height constraints for precise layout control
- **Markdown Support**: Rich text rendering with headers, lists, code blocks, tables, and links

### Navigation
- **Overlay System**: Complete navigator rewrite using overlay-based architecture
- **Route Replacement**: New pushReplacement methods for better navigation flow
- **Navigator Improvements**: Enhanced route management and lifecycle handling

## Performance Improvements
- **Terminal Output**: Write buffering dramatically reduces system calls
- **ListView CPU Fix**: Fixed 100% CPU usage with proper change detection
- **Event Processing**: Eliminated keyboard event spam from unparseable mouse events
- **Performance Tests**: Added benchmark suite for regression testing

## Scrolling Enhancements
- **RenderObject Scrolling**: Moved scrolling logic to RenderObject layer for better performance
- **Mouse Support**: Full mouse wheel scrolling with SGR coordinate tracking
- **Auto-Scroll**: Smart auto-scrolling for chat/log interfaces
- **Reverse Mode**: ListView reverse option for chat-like UIs
- **Improved Metrics**: Better scroll extent calculation for variable-height items

## Visual Improvements
- **Modern Colors**: Updated color palette with sophisticated muted tones
- **Cursor Styles**: Enhanced text field cursor customization
- **Text Wrapping**: Proper text wrapping in columns with cross-axis stretch

## Bug Fixes
- Fixed multi-child rebuild layout issues
- Fixed column-in-column constraint handling
- Fixed render object handling for Expanded widgets
- Fixed ESC key handling
- Fixed ordering bugs with Row/Column non-RenderObject elements
- Fixed constraints in flexible layouts and Align widgets
- Improved error handling and hot reload logging

## Architecture
- Clean separation of display and input concerns
- Enhanced lifecycle management for components
- Improved render object system with better layout calculations
- Comprehensive test coverage with visual validation


# 0.0.1

- Initial version.