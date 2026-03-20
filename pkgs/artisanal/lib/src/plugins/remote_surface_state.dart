import 'dart:math' as math;

import 'remote_surface_protocol.dart';

/// Resolved cell state for a rendered remote plugin surface.
final class RemotePluginSurfaceCell {
  const RemotePluginSurfaceCell({
    this.symbol = ' ',
    this.width = 1,
    this.foreground,
    this.background,
    this.attributes = const RemotePluginCellAttributes(),
  });

  factory RemotePluginSurfaceCell.fromFrameCell(RemotePluginFrameCell cell) {
    return RemotePluginSurfaceCell(
      symbol: cell.symbol,
      width: cell.width,
      foreground: cell.foreground,
      background: cell.background,
      attributes: cell.attributes,
    );
  }

  final String symbol;
  final int width;
  final String? foreground;
  final String? background;
  final RemotePluginCellAttributes attributes;

  bool get isBlank =>
      symbol == ' ' &&
      width == 1 &&
      foreground == null &&
      background == null &&
      attributes == const RemotePluginCellAttributes();
}

/// Mutable host-side state for one open remote plugin surface.
final class RemotePluginSurfaceState {
  RemotePluginSurfaceState.fromOpen(RemotePluginSurfaceOpen open)
    : surfaceId = open.surfaceId,
      kind = open.kind,
      title = open.title,
      slot = open.slot,
      parentSurfaceId = open.parentSurfaceId,
      anchor = open.anchor,
      width = open.width,
      height = open.height,
      _cells = List<RemotePluginSurfaceCell>.filled(
        open.width * open.height,
        const RemotePluginSurfaceCell(),
      );

  final String surfaceId;
  final RemotePluginSurfaceKind kind;
  String? title;
  String? slot;
  String? parentSurfaceId;
  RemotePluginAnchorRect? anchor;

  int width;
  int height;
  RemotePluginCursor? cursor;

  List<RemotePluginSurfaceCell> _cells;

  Iterable<RemotePluginSurfaceCell> get cells => _cells;

  RemotePluginSurfaceCell cellAt(int column, int row) {
    _requireInBounds(column, row, width, height, surfaceId: surfaceId);
    return _cells[_index(column, row, width)];
  }

  void applyResize(RemotePluginSurfaceResize resize) {
    _requireSurface(surfaceId, resize.surfaceId);

    final nextCells = List<RemotePluginSurfaceCell>.filled(
      resize.width * resize.height,
      const RemotePluginSurfaceCell(),
    );

    final copyWidth = math.min(width, resize.width);
    final copyHeight = math.min(height, resize.height);
    for (var row = 0; row < copyHeight; row++) {
      for (var column = 0; column < copyWidth; column++) {
        nextCells[_index(column, row, resize.width)] =
            _cells[_index(column, row, width)];
      }
    }

    width = resize.width;
    height = resize.height;
    _cells = nextCells;
    if (cursor case final value?) {
      if (value.column >= width || value.row >= height) {
        cursor = null;
      }
    }
  }

  void applyFrame(RemotePluginFrame frame) {
    _requireSurface(surfaceId, frame.surfaceId);

    if (frame.width != width || frame.height != height) {
      applyResize(
        RemotePluginSurfaceResize(
          surfaceId: frame.surfaceId,
          width: frame.width,
          height: frame.height,
        ),
      );
    }

    _cells = List<RemotePluginSurfaceCell>.filled(
      width * height,
      const RemotePluginSurfaceCell(),
    );

    for (final cell in frame.cells) {
      if (cell.column < 0 ||
          cell.row < 0 ||
          cell.column >= width ||
          cell.row >= height) {
        continue;
      }
      _cells[_index(cell.column, cell.row, width)] =
          RemotePluginSurfaceCell.fromFrameCell(cell);
    }

    cursor = frame.cursor;
  }
}

/// Host-side registry of open remote plugin surfaces.
final class RemotePluginSurfaceStore {
  final Map<String, RemotePluginSurfaceState> _surfaces =
      <String, RemotePluginSurfaceState>{};

  Iterable<RemotePluginSurfaceState> get surfaces => _surfaces.values;

  RemotePluginSurfaceState? operator [](String surfaceId) => _surfaces[surfaceId];

  void apply(RemotePluginMessage message) {
    switch (message) {
      case RemotePluginSurfaceOpen():
        if (_surfaces.containsKey(message.surfaceId)) {
          throw StateError(
            'Remote plugin surface ${message.surfaceId} is already open.',
          );
        }
        _surfaces[message.surfaceId] = RemotePluginSurfaceState.fromOpen(
          message,
        );
      case RemotePluginSurfaceResize():
        final surface = _requireOpenSurface(message.surfaceId);
        surface.applyResize(message);
      case RemotePluginFrame():
        final surface = _requireOpenSurface(message.surfaceId);
        surface.applyFrame(message);
      case RemotePluginSurfaceClose():
        final surface = _surfaces.remove(message.surfaceId);
        if (surface == null) {
          throw StateError(
            'Remote plugin surface ${message.surfaceId} is not open.',
          );
        }
      default:
        return;
    }
  }

  void applyAll(Iterable<RemotePluginMessage> messages) {
    for (final message in messages) {
      apply(message);
    }
  }

  RemotePluginSurfaceState _requireOpenSurface(String surfaceId) {
    final surface = _surfaces[surfaceId];
    if (surface == null) {
      throw StateError('Remote plugin surface $surfaceId is not open.');
    }
    return surface;
  }
}

int _index(int column, int row, int width) => row * width + column;

void _requireSurface(String expectedId, String actualId) {
  if (expectedId != actualId) {
    throw StateError(
      'Surface id mismatch: expected $expectedId, got $actualId.',
    );
  }
}

void _requireInBounds(
  int column,
  int row,
  int width,
  int height, {
  required String surfaceId,
}) {
  if (column < 0 || row < 0 || column >= width || row >= height) {
    throw RangeError(
      'Cell ($column,$row) is out of bounds for surface $surfaceId '
      '($width x $height).',
    );
  }
}
