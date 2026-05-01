import 'dart:collection';

import 'cmd.dart';
import 'msg.dart';

/// Immutable snapshot of terminal-reported colors.
final class TerminalPaletteSnapshot {
  TerminalPaletteSnapshot({
    this.foregroundHex,
    this.backgroundHex,
    this.cursorHex,
    required Map<int, String> palette,
  }) : palette = UnmodifiableMapView<int, String>(
         Map<int, String>.from(palette),
       );

  final String? foregroundHex;
  final String? backgroundHex;
  final String? cursorHex;
  final UnmodifiableMapView<int, String> palette;

  bool get hasForeground => foregroundHex != null;
  bool get hasBackground => backgroundHex != null;
  bool get hasCursor => cursorHex != null;
  bool get hasCoreColors => hasForeground || hasBackground || hasCursor;
  bool get isBackgroundDark => backgroundHex == null
      ? true
      : BackgroundColorMsg(hex: backgroundHex!).isDark;

  String? paletteHex(int index) => palette[index];

  TerminalPaletteSnapshot copyWith({
    String? foregroundHex,
    String? backgroundHex,
    String? cursorHex,
    Map<int, String>? palette,
  }) {
    return TerminalPaletteSnapshot(
      foregroundHex: foregroundHex ?? this.foregroundHex,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      cursorHex: cursorHex ?? this.cursorHex,
      palette: palette ?? this.palette,
    );
  }
}

/// Message-driven cache and probe helper for terminal palette reports.
///
/// This sits above the low-level OSC report messages and gives hosts one place
/// to request, cache, and query terminal colors.
final class TerminalPaletteService {
  String? _foregroundHex;
  String? _backgroundHex;
  String? _cursorHex;
  final Map<int, String> _palette = <int, String>{};

  /// Latest cached snapshot.
  TerminalPaletteSnapshot get snapshot => TerminalPaletteSnapshot(
    foregroundHex: _foregroundHex,
    backgroundHex: _backgroundHex,
    cursorHex: _cursorHex,
    palette: Map<int, String>.unmodifiable(_palette),
  );

  /// Clears all cached terminal colors.
  void clear() {
    _foregroundHex = null;
    _backgroundHex = null;
    _cursorHex = null;
    _palette.clear();
  }

  /// Updates cached values from a terminal color report.
  ///
  /// Returns `true` when [msg] affected the cache.
  bool handle(Msg msg) {
    switch (msg) {
      case ForegroundColorMsg(:final hex):
        _foregroundHex = hex;
        return true;
      case BackgroundColorMsg(:final hex):
        _backgroundHex = hex;
        return true;
      case CursorColorMsg(:final hex):
        _cursorHex = hex;
        return true;
      case ColorPaletteMsg(:final index, :final hex):
        _palette[index] = hex;
        return true;
      default:
        return false;
    }
  }

  /// Requests foreground/background reports and optionally the cursor color.
  Cmd requestCoreColors({bool includeCursor = true}) {
    final commands = <Cmd>[
      Cmd.requestForegroundColor(),
      Cmd.requestBackgroundColor(),
      if (includeCursor) Cmd.requestCursorColor(),
    ];
    return Cmd.batch(commands);
  }

  /// Requests a normalized set of palette slot reports.
  ///
  /// Duplicate indices are removed and the resulting request order is sorted.
  Cmd requestPalette(Iterable<int> indices) {
    final normalized = indices.toSet().toList()..sort();
    if (normalized.isEmpty) {
      return Cmd.none();
    }
    return Cmd.batch(
      normalized.map((index) => Cmd.requestColorPalette(index)).toList(),
    );
  }

  /// Requests the ANSI palette range `[0, count)`.
  Cmd requestAnsiPalette({int count = 16}) {
    final normalizedCount = count.clamp(0, 256);
    return requestPalette(
      List<int>.generate(normalizedCount, (index) => index),
    );
  }
}
