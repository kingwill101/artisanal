import 'package:artisanal/style.dart' show Color, Style;
import '_component_foundation.dart';

// ignore_for_file: unused_shown_name
/// A single entry in the undo/redo history.
class HistoryEntry {
  const HistoryEntry({required this.description, this.isRedo = false});

  /// Human-readable description of the command.
  final String description;

  /// Whether this entry is in the redo (future) stack.
  final bool isRedo;
}

/// Display mode for [HistoryPanel].
enum HistoryPanelMode {
  /// Shows only the most recent items with overflow indicators.
  compact,

  /// Shows the complete history stack.
  full,
}

/// A panel that displays undo/redo command history with a position marker.
///
/// Renders a vertical list of command descriptions showing the undo/redo
/// history stack. A centered marker separates undo (past) from redo (future)
/// items. Compact mode limits visible items with "..." overflow indicators.
///
/// ```dart
/// HistoryPanel(
///   title: 'Edit History',
///   undoItems: [
///     HistoryEntry(description: 'Insert text'),
///     HistoryEntry(description: 'Delete word'),
///   ],
///   redoItems: [
///     HistoryEntry(description: 'Paste', isRedo: true),
///   ],
/// )
/// ```
class HistoryPanel extends StatelessWidget {
  HistoryPanel({
    this.title = 'History',
    this.undoItems = const [],
    this.redoItems = const [],
    this.mode = HistoryPanelMode.compact,
    this.compactLimit = 5,
    this.markerText = '─── current ───',
    this.undoIcon = '↶ ',
    this.redoIcon = '↷ ',
    this.titleStyle,
    this.undoStyle,
    this.redoStyle,
    this.markerStyle,
    this.background,
    this.padding,
    super.key,
  });

  /// Panel title displayed at the top.
  final String title;

  /// Undo stack entries (oldest first).
  final List<HistoryEntry> undoItems;

  /// Redo stack entries (oldest first).
  final List<HistoryEntry> redoItems;

  /// Display mode (compact or full).
  final HistoryPanelMode mode;

  /// Maximum items to show per stack in compact mode (default: 5).
  final int compactLimit;

  /// Text for the current-position marker.
  final String markerText;

  /// Icon prefix for undo items.
  final String undoIcon;

  /// Icon prefix for redo items.
  final String redoIcon;

  /// Style for the title.
  final Style? titleStyle;

  /// Style for undo items.
  final Style? undoStyle;

  /// Style for redo items (dimmed by default).
  final Style? redoStyle;

  /// Style for the position marker.
  final Style? markerStyle;

  /// Background color.
  final Color? background;

  /// Padding inside the panel.
  final EdgeInsets? padding;

  /// Whether the panel has no history items.
  bool get isEmpty => undoItems.isEmpty && redoItems.isEmpty;

  /// Total number of history items.
  int get length => undoItems.length + redoItems.length;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;

    final tStyle = copyStyle(titleStyle ?? theme.titleSmall)
      ..foreground(theme.onSurface)
      ..bold();
    final uStyle = copyStyle(undoStyle ?? theme.bodySmall)
      ..foreground(theme.onSurface);
    final rStyle = copyStyle(redoStyle ?? theme.bodySmall)
      ..foreground(theme.muted)
      ..dim();
    final mStyle = copyStyle(markerStyle ?? theme.bodySmall)
      ..foreground(theme.muted)
      ..bold();

    final children = <Widget>[];

    // Title
    if (title.isNotEmpty) {
      children.add(Text(title, style: tStyle));
      children.add(Text(''));
    }

    // Determine visible items
    final (undoVisible, redoVisible) = _computeVisible();

    // Overflow indicator for hidden undo items
    if (mode == HistoryPanelMode.compact &&
        undoVisible.length < undoItems.length) {
      final hidden = undoItems.length - undoVisible.length;
      children.add(Text('... ($hidden more)', style: rStyle));
    }

    // Undo items
    for (final entry in undoVisible) {
      children.add(Text('$undoIcon${entry.description}', style: uStyle));
    }

    // Position marker
    children.add(Text(markerText, style: mStyle));

    // Redo items
    for (final entry in redoVisible) {
      children.add(Text('$redoIcon${entry.description}', style: rStyle));
    }

    // Overflow indicator for hidden redo items
    if (mode == HistoryPanelMode.compact &&
        redoVisible.length < redoItems.length) {
      final hidden = redoItems.length - redoVisible.length;
      children.add(Text('... ($hidden more)', style: rStyle));
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(1),
      color: bg,
      child: Column(gap: 0, children: children),
    );
  }

  (List<HistoryEntry>, List<HistoryEntry>) _computeVisible() {
    if (mode == HistoryPanelMode.full) {
      return (undoItems, redoItems);
    }
    final half = compactLimit ~/ 2;
    final undoStart = (undoItems.length - half).clamp(0, undoItems.length);
    final redoEnd = half.clamp(0, redoItems.length);
    return (undoItems.sublist(undoStart), redoItems.sublist(0, redoEnd));
  }
}
