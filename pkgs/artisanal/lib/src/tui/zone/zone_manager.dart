// Copyright (c) 2024. All rights reserved.
// Use of this source code is governed by the MIT license that can be found in
// the LICENSE file.
//
// Port of github.com/lrstanley/bubblezone for Dart/Artisanal.

import '../cmd.dart';
import '../model.dart';
import '../msg.dart';
import 'zone_info.dart';
import 'zone_scanner.dart';

/// Global zone manager instance.
///
/// Initialize with [initGlobalZone] before using [zone].
ZoneManager? _globalZone;

/// Returns the global zone manager if initialized.
ZoneManager? get globalZone => _globalZone;

/// Whether the global zone manager has been initialized.
bool get hasGlobalZone => _globalZone != null;

/// Gets the global zone manager.
///
/// Must call [initGlobalZone] first, otherwise throws a [StateError].
///
/// ## Example
///
/// ```dart
/// void main() {
///   initGlobalZone();
///
///   // Now you can use zone.mark(), zone.scan(), zone.get()
///   runProgram(MyModel());
/// }
/// ```
ZoneManager get zone {
  final z = _globalZone;
  if (z == null) {
    throw StateError(
      'Global zone manager not initialized. Call initGlobalZone() first.',
    );
  }
  return z;
}

/// Initializes the global zone manager.
///
/// Call this once at application startup before using [zone].
///
/// ## Example
///
/// ```dart
/// void main() {
///   initGlobalZone();
///   runProgram(MyModel());
/// }
/// ```
ZoneManager initGlobalZone() {
  _globalZone?.close();
  _globalZone = ZoneManager();
  return _globalZone!;
}

/// Closes the global zone manager.
///
/// Call this when the application exits or when you want to clean up.
void closeGlobalZone() {
  _globalZone?.close();
  _globalZone = null;
}

/// Counter for generating unique marker IDs.
int _markerCounter = 1000;

/// Counter for generating unique prefixes.
int _prefixCounter = 0;

/// Zone manager for tracking clickable regions in TUI output.
///
/// BubbleZone allows you to wrap components in zero-printable-width
/// identifiers that don't affect layout calculations. When the output is
/// scanned, these markers are detected and their screen positions are stored.
///
/// This enables easy mouse event hit testing - simply check if a mouse event
/// is within the bounds of a zone by its ID.
///
/// ## Usage
///
/// 1. Create or use the global zone manager:
///    ```dart
///    initGlobalZone();
///    // or
///    final myZone = ZoneManager();
///    ```
///
/// 2. In your view method, wrap clickable content with [mark]:
///    ```dart
///    String view() {
///      return zone.mark('my-button', style.render('Click Me'));
///    }
///    ```
///
/// 3. In your root model, wrap the entire view output with [scan]:
///    ```dart
///    String view() {
///      return zone.scan(renderAllChildren());
///    }
///    ```
///
/// 4. In update, check if mouse events are within zones:
///    ```dart
///    (Model, Cmd?) update(Msg msg) {
///      if (msg is MouseMsg && msg.action == MouseAction.release) {
///        if (zone.get('my-button')?.inBounds(msg) ?? false) {
///          return (handleButtonClick(), null);
///        }
///      }
///      return (this, null);
///    }
///    ```
///
/// ## Tips
///
/// - Use [newPrefix] to prevent ID collisions between component instances
/// - Only call [scan] at the root model level
/// - Use `lipgloss.width()` equivalent for width calculations, not `String.length`
/// - Zones are bounding boxes - organic shapes will include corner areas
class ZoneManager {
  /// Creates a new zone manager.
  ZoneManager() {
    _enabled = true;
  }

  /// Whether the manager is enabled.
  bool _enabled = true;

  /// Map of user ID -> generated marker ID.
  final Map<String, String> _ids = {};

  /// Map of generated marker ID -> user ID.
  final Map<String, String> _rids = {};

  /// Map of user ID -> zone info.
  final Map<String, ZoneInfo> _zones = {};

  /// Current iteration number.
  int _iteration = 0;

  /// Whether the manager has been closed.
  bool _closed = false;

  /// Closes the zone manager and releases resources.
  void close() {
    _closed = true;
    _zones.clear();
    _ids.clear();
    _rids.clear();
  }

  /// Enables or disables the zone manager.
  ///
  /// When disabled, [mark] returns the input unchanged and [scan] strips
  /// all markers but doesn't track zones.
  ///
  /// The manager is enabled by default.
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      _zones.clear();
    }
  }

  /// Whether the zone manager is enabled.
  bool get enabled => _enabled;

  /// Generates a unique prefix for zone IDs.
  ///
  /// Use this to prevent ID collisions when the same component type is
  /// used multiple times.
  ///
  /// ## Example
  ///
  /// ```dart
  /// class MyListModel extends Model {
  ///   final String zonePrefix = zone.newPrefix();
  ///
  ///   @override
  ///   String view() {
  ///     return items.indexed.map((e) {
  ///       final (i, item) = e;
  ///       return zone.mark('${zonePrefix}item_$i', item.render());
  ///     }).join('\n');
  ///   }
  ///
  ///   @override
  ///   (Model, Cmd?) update(Msg msg) {
  ///     if (msg is MouseMsg) {
  ///       for (var i = 0; i < items.length; i++) {
  ///         if (zone.get('${zonePrefix}item_$i')?.inBounds(msg) ?? false) {
  ///           return (selectItem(i), null);
  ///         }
  ///       }
  ///     }
  ///     return (this, null);
  ///   }
  /// }
  /// ```
  String newPrefix() {
    return 'zone_${++_prefixCounter}__';
  }

  /// Wraps content with zone markers.
  ///
  /// The markers are zero-width ANSI sequences that don't affect
  /// layout calculations when using proper width functions.
  ///
  /// When the manager is disabled, returns [content] unchanged.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final button = zone.mark('submit', style.render('Submit'));
  /// final cancel = zone.mark('cancel', style.render('Cancel'));
  /// return '$button  $cancel';
  /// ```
  String mark(String id, String content) {
    if (!_enabled || id.isEmpty || content.isEmpty) {
      return content;
    }

    // Check if we already have a generated ID for this user ID
    var gid = _ids[id];
    if (gid != null) {
      return '$gid$content$gid';
    }

    // Generate a new marker ID
    gid = '\x1B[${++_markerCounter}z';
    _ids[id] = gid;
    _rids[gid] = id;

    return '$gid$content$gid';
  }

  /// Clears all registered zones.
  void clear(String id) {
    _zones.remove(id);
  }

  /// Gets the zone info for the given ID.
  ///
  /// Returns null if the zone is not known (hasn't been scanned yet).
  ///
  /// ## Example
  ///
  /// ```dart
  /// final buttonZone = zone.get('my-button');
  /// if (buttonZone?.inBounds(mouseMsg) ?? false) {
  ///   // Button was clicked!
  /// }
  /// ```
  ZoneInfo? get(String id) => _zones[id];

  /// Resolves a generated marker ID to the user-provided ID.
  String _resolveId(String markerId) => _rids[markerId] ?? '';

  /// Scans view output for zone markers and returns the output with markers removed.
  ///
  /// This should only be called at the root model level, not inside child
  /// components.
  ///
  /// The scan:
  /// 1. Parses all zone markers from the output
  /// 2. Calculates screen positions for each zone
  /// 3. Strips all markers from the output
  /// 4. Stores zone info for later retrieval via [get]
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// String view() {
  ///   final content = renderChildren();
  ///   return zone.scan(content);
  /// }
  /// ```
  ///
  /// Note: An immediate call to [get] after [scan] should return the
  /// correct zone info, but for mouse events (which don't occur immediately
  /// after a render), the zone info will be available.
  String scan(String view) {
    if (_closed) return view;

    _iteration = DateTime.now().microsecondsSinceEpoch;
    final zonesInThisScan = <String>{};

    final scanner = ZoneScanner(
      input: view,
      iteration: _iteration,
      enabled: _enabled,
      onZone: (zoneInfo) {
        _zones[zoneInfo.id] = zoneInfo;
        zonesInThisScan.add(zoneInfo.id);
      },
      resolveId: _resolveId,
    );

    final result = scanner.run();

    // Clean up zones from previous iterations that weren't in this scan
    _zones.removeWhere((id, info) => !zonesInThisScan.contains(id));

    return result;
  }

  /// Returns all zones that contain the given mouse position.
  ///
  /// Useful when zones might overlap and you need to handle all of them.
  List<ZoneInfo> findInBounds(MouseMsg msg) {
    final result = <ZoneInfo>[];
    final sortedKeys = _zones.keys.toList()..sort();

    for (final key in sortedKeys) {
      final zone = _zones[key]!;
      if (zone.inBounds(msg)) {
        result.add(zone);
      }
    }

    return result;
  }

  /// Sends a [ZoneInBoundsMsg] to the model for each zone that contains
  /// the mouse position.
  ///
  /// Returns the final model state and a batch of all commands.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// (Model, Cmd?) update(Msg msg) {
  ///   if (msg is MouseMsg) {
  ///     return zone.anyInBoundsAndUpdate(this, msg);
  ///   }
  ///   // Handle ZoneInBoundsMsg
  ///   if (msg is ZoneInBoundsMsg) {
  ///     return handleZoneClick(msg.zone, msg.event);
  ///   }
  ///   return (this, null);
  /// }
  /// ```
  (Model, Cmd?) anyInBoundsAndUpdate(Model model, MouseMsg mouse) {
    final zones = findInBounds(mouse);
    if (zones.isEmpty) return (model, null);

    final cmds = <Cmd>[];
    var currentModel = model;

    for (final zone in zones) {
      final (newModel, cmd) = currentModel.update(
        ZoneInBoundsMsg(zone: zone, event: mouse),
      );
      currentModel = newModel;
      if (cmd != null) cmds.add(cmd);
    }

    return (currentModel, cmds.isEmpty ? null : Cmd.batch(cmds));
  }

  /// Sends a [ZoneInBoundsMsg] to the model for each zone that contains
  /// the mouse position, discarding the results.
  ///
  /// Use [anyInBoundsAndUpdate] if you need the updated model and commands.
  void anyInBounds(Model model, MouseMsg mouse) {
    final zones = findInBounds(mouse);
    for (final zone in zones) {
      model.update(ZoneInBoundsMsg(zone: zone, event: mouse));
    }
  }
}

/// Message sent when a zone is within bounds of a mouse event.
///
/// This message is sent by [ZoneManager.anyInBoundsAndUpdate] or
/// [ZoneManager.anyInBounds] for each zone that contains the mouse position.
///
/// ## Example
///
/// ```dart
/// @override
/// (Model, Cmd?) update(Msg msg) {
///   return switch (msg) {
///     ZoneInBoundsMsg(:final zone, :final event)
///         when zone.id == 'my-button' && event.action == MouseAction.release =>
///       (handleClick(), null),
///     _ => (this, null),
///   };
/// }
/// ```
class ZoneInBoundsMsg extends Msg {
  /// Creates a zone in bounds message.
  const ZoneInBoundsMsg({required this.zone, required this.event});

  /// The zone that is in bounds.
  final ZoneInfo zone;

  /// The mouse event that triggered this message.
  final MouseMsg event;

  @override
  String toString() => 'ZoneInBoundsMsg(zone: ${zone.id}, event: $event)';
}
