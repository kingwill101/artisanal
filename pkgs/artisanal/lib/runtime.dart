/// Platform-safe core runtime for terminal applications.
///
/// This entrypoint exposes the TEA model, messages, commands, program hosting,
/// rendering contracts, input bindings, tracing, and replay APIs without
/// loading optional Markdown and native process helpers from the broader
/// `package:artisanal/tui.dart` library.
///
/// Prefer this library when implementing reusable packages or browser-capable
/// applications that only need the core runtime.
///
/// {@category TUI}
library;

export 'src/tui/runtime.dart';
export 'src/tui/rendering.dart';
export 'src/tui/automation.dart';
export 'src/tui/bubbles/debug_overlay.dart' show DebugOverlayModel;
export 'src/tui/bubbles/viewport.dart' show ViewportKeyMap, ViewportModel;
export 'src/tui/bubbles/viewport_scroll_pane.dart'
    show ScrollbarChars, ViewportScrollPane;
export 'src/tui/zone/zone_info.dart' show ZoneInfo;
export 'src/tui/zone/zone_manager.dart' show ZoneInBoundsMsg;
