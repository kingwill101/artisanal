// Copyright (c) 2024. All rights reserved.
// Use of this source code is governed by the MIT license that can be found in
// the LICENSE file.
//
// Port of github.com/lrstanley/bubblezone for Dart/Artisanal.

import '../msg.dart';

/// Holds information about the start and end positions of a zone.
///
/// A zone represents a rectangular region in the terminal that can be
/// used for mouse event hit testing. Zones are created by wrapping
/// content with [ZoneManager.mark] and then scanning the output with
/// [ZoneManager.scan].
///
/// ## Example
///
/// ```dart
/// // In your view method:
/// final button = zone.mark('my-button', 'Click Me');
///
/// // In your update method:
/// final zoneInfo = zone.get('my-button');
/// if (zoneInfo?.inBounds(mouseMsg) ?? false) {
///   // Handle click
/// }
/// ```
class ZoneInfo {
  /// Creates a zone info with the given coordinates.
  ZoneInfo({
    required this.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.iteration = 0,
  });

  /// The user-provided ID for this zone.
  final String id;

  /// The iteration this zone was created in (used for cleanup).
  final int iteration;

  /// The x coordinate of the top left cell of the zone (0-based).
  final int startX;

  /// The y coordinate of the top left cell of the zone (0-based).
  final int startY;

  /// The x coordinate of the bottom right cell of the zone (0-based).
  final int endX;

  /// The y coordinate of the bottom right cell of the zone (0-based).
  final int endY;

  /// Returns true if this zone info represents an unknown/invalid zone.
  bool get isZero => id.isEmpty;

  /// Returns true if the mouse event was in the bounds of this zone's
  /// coordinates.
  ///
  /// If the zone is not known (isZero), returns false. It calculates this
  /// using a box between the start and end coordinates. If you're looking
  /// to check for abnormal shapes (e.g. something that might wrap a line,
  /// but can't be determined using a box), you'll need to implement this
  /// yourself.
  ///
  /// ## Example
  ///
  /// ```dart
  /// case MouseMsg(:final action, :final button) when action == MouseAction.press:
  ///   if (zone.get('my-button')?.inBounds(msg) ?? false) {
  ///     // Button was clicked!
  ///   }
  /// ```
  bool inBounds(MouseMsg msg) {
    if (isZero) return false;
    if (startX > endX || startY > endY) return false;
    if (msg.x < startX || msg.y < startY) return false;
    if (msg.x > endX || msg.y > endY) return false;
    return true;
  }

  /// Returns the coordinates of the mouse event relative to this zone.
  ///
  /// Returns a record with (x, y) being the position within the zone,
  /// with (0, 0) being the top left cell of the zone.
  ///
  /// If the zone is not known or the mouse event is not in bounds,
  /// returns (-1, -1).
  ///
  /// ## Example
  ///
  /// ```dart
  /// final zoneInfo = zone.get('text-area');
  /// if (zoneInfo != null) {
  ///   final (x, y) = zoneInfo.pos(mouseMsg);
  ///   if (x >= 0 && y >= 0) {
  ///     // x, y are coordinates within the text area
  ///     cursor.moveTo(x, y);
  ///   }
  /// }
  /// ```
  ({int x, int y}) pos(MouseMsg msg) {
    if (isZero || !inBounds(msg)) {
      return (x: -1, y: -1);
    }
    return (x: msg.x - startX, y: msg.y - startY);
  }

  /// The width of this zone in columns.
  int get width => endX - startX + 1;

  /// The height of this zone in rows.
  int get height => endY - startY + 1;

  /// Creates a copy with updated end coordinates.
  ZoneInfo withEnd({required int endX, required int endY}) {
    return ZoneInfo(
      id: id,
      iteration: iteration,
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
    );
  }

  @override
  String toString() =>
      'ZoneInfo(id: $id, start: ($startX, $startY), end: ($endX, $endY))';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ZoneInfo &&
          id == other.id &&
          startX == other.startX &&
          startY == other.startY &&
          endX == other.endX &&
          endY == other.endY);

  @override
  int get hashCode => Object.hash(id, startX, startY, endX, endY);
}
