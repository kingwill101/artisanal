# Nocterm Web Interactive Demo

This is a comprehensive interactive demo showcasing the capabilities of nocterm running in a web browser.

## Features

The demo includes 4 interactive tabs:

### 1. Dashboard Tab
- **Live Metrics**: Real-time CPU, Memory, Network, and Request counters
- **System Monitor**: Animated progress bars showing resource usage
- **CPU History**: Sparkline chart displaying historical CPU usage
- **Activity Feed**: Live feed of system events

### 2. Widgets Tab
- **Interactive Counter**: Clickable +/- buttons to increment/decrement
- **Toggle Switch**: ON/OFF toggle with visual feedback
- **Selection List**: Click to select from multiple options
- **Text Styles**: Showcase of bold, italic, underline, dim, and colored text

### 3. Animation Tab
- **Spinners**: Three different animated loading spinners
- **Progress Bars**: Linear progress bar and bouncing progress indicator
- **Wave Animation**: Sine wave animation using block characters
- **Color Gradient**: Animated RGB gradient

### 4. About Tab
- Information about nocterm and its features
- ASCII art borders
- Feature list

## Navigation

- **Arrow Keys (←→)**: Switch between tabs
- **Number Keys (1-4)**: Jump directly to a specific tab
- **Mouse**: Click on buttons, toggles, and selection items

## Implementation Highlights

- **Stateful Components**: Uses `StatefulComponent` and `State` with lifecycle methods
- **Timers**: Real-time updates via `Timer.periodic`
- **Keyboard Input**: `Focusable` component with `onKeyEvent` handling
- **Mouse Input**: `GestureDetector` with `onTap` callbacks
- **Reactive UI**: `setState()` triggers rebuilds automatically
- **Styling**: Tokyo Night color theme with rich text formatting
- **Layout**: Flex layouts with Row, Column, and Expanded

## Code Structure

```
lib/example.dart
├── InteractiveDemo (main app with tab navigation)
├── DashboardTab (live metrics and monitoring)
├── WidgetsTab (interactive UI components)
├── AnimationTab (animated elements)
└── AboutTab (info panel)
```

## Running the Demo

To build and run this demo in the browser:

```bash
# From the example directory
dart compile js bin/example.dart -o out.js

# Then open index.html in a browser
```

The demo will be rendered using xterm.js in the browser, showcasing how nocterm can create rich terminal UIs that run in web environments.

## Technologies

- **Dart**: Programming language
- **nocterm**: TUI framework (Flutter-like for terminals)
- **xterm.js**: Terminal emulator for the browser
- **ANSI escape codes**: Terminal formatting and colors
