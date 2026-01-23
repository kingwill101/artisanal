/// Operations on [Screen] objects.
///
/// Provides high-level utilities for clearing, filling, and cloning areas
/// of a [Screen] or [Buffer].
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_concept_overview}
library;

import 'buffer.dart';
import 'cell.dart';
import 'geometry.dart';
import 'screen.dart';

/// Screen helpers for clearing/filling/cloning.
///
/// Mirrors upstream `third_party/ultraviolet/screen`.

/// Clears the entire [screen] to empty cells.
void clear(Screen screen) {
  if (screen is ClearableScreen) {
    screen.clear();
    return;
  }
  fill(screen, null);
}

/// Clears [area] of [screen] to empty cells.
void clearArea(Screen screen, Rectangle area) {
  if (screen is ClearAreaScreen) {
    screen.clearArea(area);
    return;
  }
  fillArea(screen, null, area);
}

/// Fills the entire [screen] with [cell].
void fill(Screen screen, Cell? cell) {
  if (screen is FillableScreen) {
    screen.fill(cell);
    return;
  }
  fillArea(screen, cell, screen.bounds());
}

/// Fills [area] of [screen] with [cell].
void fillArea(Screen screen, Cell? cell, Rectangle area) {
  if (screen is FillAreaScreen) {
    screen.fillArea(cell, area);
    return;
  }

  for (var y = area.minY; y < area.maxY; y++) {
    for (var x = area.minX; x < area.maxX; x++) {
      screen.setCell(x, y, cell);
    }
  }
}

/// Returns a copy of [screen] as a [Buffer].
Buffer clone(Screen screen) {
  if (screen case CloneableScreen(:final clone)) {
    final v = clone();
    if (v is Buffer) return v;
  }
  return cloneArea(screen, screen.bounds()) ?? Buffer.create(0, 0);
}

/// Returns a copy of [area] from [screen], or null when empty.
Buffer? cloneArea(Screen screen, Rectangle area) {
  if (screen case CloneAreaScreen(:final cloneArea)) {
    final v = cloneArea(area);
    if (v == null) return null;
    if (v is Buffer) return v;
  }

  final b = Buffer.create(area.width, area.height);
  for (var y = area.minY; y < area.maxY; y++) {
    for (var x = area.minX; x < area.maxX; x++) {
      final c = screen.cellAt(x, y);
      if (c == null || c.isZero) continue;
      b.setCell(x - area.minX, y - area.minY, c.clone());
    }
  }
  return b;
}
