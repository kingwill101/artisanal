/// Discovers and tracks terminal features for UV rendering and input decoding.
///
/// {@category Ultraviolet}
/// {@subCategory Device Capabilities}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_events_overview}
/// {@macro artisanal_uv_performance_tips}
/// {@macro artisanal_uv_compatibility}
///
/// The [TerminalCapabilities] model centralizes capability detection to guide
/// renderer and input behavior (kitty/sixel graphics, keyboard enhancements,
/// color palette/background, and device attributes). Initial hints come from an
/// environment snapshot via [Environ], then are refined by ANSI reports such as
/// [PrimaryDeviceAttributesEvent], [SecondaryDeviceAttributesEvent],
/// [KittyGraphicsEvent], [KeyboardEnhancementsEvent], [BackgroundColorEvent],
/// and [ColorPaletteEvent]. Colors are represented with [UvRgb].
///
/// Use [TerminalCapabilities] to gate feature use: prefer Kitty/Sixel paths
/// only when available; enable enhanced keyboard decoding when reported; fall
/// back to basic ANSI or palette-safe rendering on legacy terminals. Update
/// capability state incrementally with [TerminalCapabilities.updateFromEvent].
///
/// Example:
/// ```dart
/// // Seed from environment, then refine with incoming [Event]s.
/// final env = <String>['TERM=xterm-kitty', 'TERM_PROGRAM=WezTerm'];
/// final caps = TerminalCapabilities(env: env);
///
/// // Later, as events arrive from the decoder:
/// caps.updateFromEvent(PrimaryDeviceAttributesEvent([1, 2, 4])); // 4 -> Sixel
/// caps.updateFromEvent(KeyboardEnhancementsEvent(
///   KeyboardEnhancementsEvent.reportEventTypes,
/// ));
///
/// if (caps.hasKittyGraphics || caps.hasSixel) {
///   // Use graphics-capable renderer path
/// }
/// ```
library;

import 'environ.dart';
import 'event.dart';
import 'cell.dart';

/// Terminal capabilities discovered via ANSI queries.
final class TerminalCapabilities {
  /// Creates a new terminal capabilities instance.
  ///
  /// If [env] is provided, seeds initial capability hints from environment
  /// variables (e.g. `TERM`, `TERM_PROGRAM`, `LC_TERMINAL`).
  TerminalCapabilities({List<String>? env}) {
    if (env != null) {
      final environ = Environ(env);
      final term = environ.getenv('TERM');
      final termProg = environ.getenv('TERM_PROGRAM');
      final lcTerm = environ.getenv('LC_TERMINAL');

      // iTerm2 Image Protocol is specific to iTerm2-compatible terminals.
      if (termProg.contains('iTerm') || lcTerm.contains('iTerm')) {
        hasITerm2 = true;
      }

      // Kitty graphics is supported by Kitty itself and some other terminals
      // (e.g. WezTerm). Treat TERM hints as "best effort" (queries are the
      // source of truth).
      if (term.contains('kitty') ||
          term.contains('ghostty') ||
          environ.getenv('KITTY_WINDOW_ID').isNotEmpty ||
          termProg.contains('WezTerm') ||
          termProg.toLowerCase().contains('ghostty') ||
          lcTerm.toLowerCase().contains('ghostty')) {
        hasKittyGraphics = true;
      }
    }
  }

  /// Whether the terminal supports Kitty Graphics Protocol.
  bool hasKittyGraphics = false;

  /// Whether the terminal supports Sixel Graphics.
  bool hasSixel = false;

  /// Whether the terminal supports iTerm2 Image Protocol.
  bool hasITerm2 = false;

  /// Kitty Keyboard Protocol enhancement flags reported by the terminal.
  int keyboardEnhancementFlags = 0;

  /// Whether the terminal supports Kitty Keyboard Protocol enhancements.
  bool get hasKeyboardEnhancements => keyboardEnhancementFlags != 0;

  /// The primary device attributes reported by the terminal.
  List<int> primaryAttributes = [];

  /// The secondary device attributes reported by the terminal.
  List<int> secondaryAttributes = [];

  /// The terminal background color.
  UvRgb? backgroundColor;

  /// The terminal foreground color.
  UvRgb? foregroundColor;

  /// The terminal cursor color.
  UvRgb? cursorColor;

  /// The terminal color palette.
  final Map<int, UvRgb> palette = {};

  /// Whether the terminal has reported its background color.
  bool get hasBackgroundColor => backgroundColor != null;

  /// Whether the terminal has reported its foreground color.
  bool get hasForegroundColor => foregroundColor != null;

  /// Whether the terminal has reported its cursor color.
  bool get hasCursorColor => cursorColor != null;

  /// Whether the terminal has reported any color palette entries.
  bool get hasColorPalette => palette.isNotEmpty;

  /// Updates capabilities based on an event.
  ///
  /// Returns true if any capability changed.
  bool updateFromEvent(Event event) {
    if (event is KittyGraphicsEvent) {
      if (!hasKittyGraphics) {
        hasKittyGraphics = true;
        return true;
      }
    } else if (event is KeyboardEnhancementsEvent) {
      if (keyboardEnhancementFlags != event.flags) {
        keyboardEnhancementFlags = event.flags;
        return true;
      }
    } else if (event is PrimaryDeviceAttributesEvent) {
      final attrsChanged =
          primaryAttributes.length != event.attrs.length ||
          primaryAttributes.asMap().entries.any(
            (entry) => entry.value != event.attrs[entry.key],
          );
      primaryAttributes = event.attrs;
      // Attribute 4 is Sixel.
      final oldSixel = hasSixel;
      hasSixel = event.attrs.contains(4);
      return attrsChanged || oldSixel != hasSixel;
    } else if (event is ForegroundColorEvent) {
      if (foregroundColor != event.color) {
        foregroundColor = event.color;
        return true;
      }
    } else if (event is BackgroundColorEvent) {
      if (backgroundColor != event.color) {
        backgroundColor = event.color;
        return true;
      }
    } else if (event is CursorColorEvent) {
      if (cursorColor != event.color) {
        cursorColor = event.color;
        return true;
      }
    } else if (event is ColorPaletteEvent) {
      if (event.color != null) {
        if (palette[event.index] != event.color) {
          palette[event.index] = event.color!;
          return true;
        }
      }
    } else if (event is SecondaryDeviceAttributesEvent) {
      final attrsChanged =
          secondaryAttributes.length != event.attrs.length ||
          secondaryAttributes.asMap().entries.any(
            (entry) => entry.value != event.attrs[entry.key],
          );
      secondaryAttributes = event.attrs;
      return attrsChanged;
    }
    return false;
  }

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('TerminalCapabilities(');
    buf.writeln('  hasKittyGraphics: $hasKittyGraphics,');
    buf.writeln('  hasSixel: $hasSixel,');
    buf.writeln('  hasITerm2: $hasITerm2,');
    buf.writeln('  hasKeyboardEnhancements: $hasKeyboardEnhancements,');
    buf.writeln('  primaryAttributes: $primaryAttributes,');
    buf.writeln('  secondaryAttributes: $secondaryAttributes,');
    buf.writeln('  foregroundColor: ${foregroundColor ?? "null"},');
    buf.writeln('  backgroundColor: ${backgroundColor ?? "null"},');
    buf.writeln('  cursorColor: ${cursorColor ?? "null"},');
    if (palette.isEmpty) {
      buf.writeln('  palette: {}');
    } else {
      buf.writeln('  palette: {');
      palette.forEach((index, color) {
        buf.writeln('    $index: $color,');
      });
      buf.writeln('  }');
    }
    buf.writeln(')');
    return buf.toString();
  }
}
