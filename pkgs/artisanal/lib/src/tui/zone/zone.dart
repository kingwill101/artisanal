// Copyright (c) 2024. All rights reserved.
// Use of this source code is governed by the MIT license that can be found in
// the LICENSE file.

/// BubbleZone - Mouse click zone tracking for TUI applications.
///
/// This is a port of [github.com/lrstanley/bubblezone](https://github.com/lrstanley/bubblezone)
/// for Dart/Artisanal.
///
/// BubbleZone allows you to wrap components in zero-printable-width identifiers
/// that don't affect layout calculations. When the output is scanned, these
/// markers are detected and their screen positions are stored, enabling easy
/// mouse event hit testing.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal/artisanal.dart';
///
/// void main() {
///   // Initialize the global zone manager
///   initGlobalZone();
///
///   // Run your program with passive hover + mouse enabled.
///   runProgram(
///     MyModel(),
///     options: ProgramOptions(mouseMode: MouseMode.allMotion),
///   );
/// }
///
/// class MyModel extends Model {
///   @override
///   String view() {
///     // Wrap clickable content with zone.mark()
///     final button = zone.mark('my-button', '[Click Me]');
///
///     // Scan the entire output at the root level
///     return zone.scan(button);
///   }
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     if (msg is MouseMsg && msg.action == MouseAction.release) {
///       // Check if the click was in the button zone
///       if (zone.get('my-button')?.inBounds(msg) ?? false) {
///         print('Button clicked!');
///       }
///     }
///     return (this, null);
///   }
/// }
/// ```
///
/// ## Key Concepts
///
/// - **Mark**: Wrap content with invisible markers using [ZoneManager.mark]
/// - **Scan**: Process the output to find markers using [ZoneManager.scan]
/// - **Get**: Retrieve zone bounds using [ZoneManager.get]
/// - **InBounds**: Check if a mouse event is in a zone using [ZoneInfo.inBounds]
///
/// ## Tips
///
/// 1. **Overlapping IDs**: Use [ZoneManager.newPrefix] to prevent ID collisions
///    between component instances.
///
/// 2. **Width calculations**: The markers don't affect `lipgloss.width()` or
///    equivalent width functions, but will affect `String.length`.
///
/// 3. **Root-level scan**: Only call [ZoneManager.scan] at the root model level,
///    not inside child components.
///
/// 4. **Bounding boxes**: Zones are rectangular bounding boxes. Organic shapes
///    (like circles) will include corner areas in their bounds.
library;

export 'zone_info.dart' show ZoneInfo;
export 'zone_manager.dart'
    show
        ZoneManager,
        ZoneInBoundsMsg,
        zone,
        globalZone,
        hasGlobalZone,
        initGlobalZone,
        closeGlobalZone;
