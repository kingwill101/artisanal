/// Overlay and OverlayEntry widgets for managing layered content.
///
/// Provides a simplified overlay system for managing floating content
/// such as dropdowns, tooltips, popups, and navigation route layers.
library;

import '../core/framework.dart' show BuildContext, StatefulWidget, State;
import '../core/widget.dart';
import '../layout/layout_widgets.dart';

/// An entry in an [Overlay].
///
/// Each entry wraps a widget builder that produces the overlay content.
/// Entries can be marked as opaque (blocking hit-testing to lower entries).
///
/// ```dart
/// final entry = OverlayEntry(
///   builder: (context) => Positioned(
///     top: 10,
///     left: 20,
///     child: Card(child: Text('Tooltip')),
///   ),
/// );
/// ```
class OverlayEntry {
  OverlayEntry({
    required this.builder,
    this.opaque = false,
    this.maintainState = false,
  });

  /// Builds the overlay content.
  final Widget Function(BuildContext context) builder;

  /// Whether this entry is opaque (blocks content below).
  final bool opaque;

  /// Whether to maintain state when the entry is not visible.
  final bool maintainState;

  /// Back-reference to the [OverlayState] this entry belongs to.
  OverlayState? _overlayState;

  /// Marks this entry as needing a rebuild.
  ///
  /// Triggers the overlay's state update to schedule a rebuild of the
  /// overlay stack, which will call this entry's `builder` again.
  void markNeedsBuild() {
    _overlayState?.setState(() {});
  }

  /// Removes this entry from its overlay.
  ///
  /// After calling this method, the entry is no longer displayed and
  /// its [builder] will not be called again.
  void remove() {
    _overlayState?.removeEntry(this);
  }
}

/// A widget that manages a stack of [OverlayEntry] objects.
///
/// Overlay entries are rendered in order, with later entries appearing
/// on top of earlier ones. This provides a simplified version of Flutter's
/// Overlay for terminal UIs.
///
/// Use [Overlay.of] to access the nearest [OverlayState] from a descendant:
///
/// ```dart
/// final overlayState = Overlay.of(context);
/// overlayState.insert(myEntry);
/// ```
class Overlay extends StatefulWidget {
  Overlay({this.initialEntries = const [], super.key});

  /// Initial overlay entries to display.
  final List<OverlayEntry> initialEntries;

  /// Returns the [OverlayState] from the closest [Overlay] ancestor.
  ///
  /// Throws a [StateError] if no [Overlay] ancestor is found.
  static OverlayState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'Overlay.of() called with a context that does not contain an Overlay.',
      );
    }
    return state;
  }

  /// Returns the [OverlayState] from the closest [Overlay] ancestor,
  /// or `null` if no [Overlay] ancestor exists.
  static OverlayState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<OverlayState>();
  }

  @override
  State<Overlay> createState() => OverlayState();
}

/// State for [Overlay], providing methods to insert and remove entries.
class OverlayState extends State<Overlay> {
  final List<OverlayEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    for (final entry in widget.initialEntries) {
      entry._overlayState = this;
      _entries.add(entry);
    }
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry._overlayState = null;
    }
    super.dispose();
  }

  /// Inserts an [entry] at the top of the overlay stack.
  void insert(OverlayEntry entry) {
    setState(() {
      entry._overlayState = this;
      _entries.add(entry);
    });
  }

  /// Inserts all [entries] at the top of the overlay stack.
  void insertAll(Iterable<OverlayEntry> entries) {
    setState(() {
      for (final entry in entries) {
        entry._overlayState = this;
        _entries.add(entry);
      }
    });
  }

  /// Inserts an [entry] above [below] in the overlay stack.
  void insertAbove(OverlayEntry entry, {required OverlayEntry below}) {
    final index = _entries.indexOf(below);
    setState(() {
      entry._overlayState = this;
      if (index >= 0) {
        _entries.insert(index + 1, entry);
      } else {
        _entries.add(entry);
      }
    });
  }

  /// Inserts an [entry] below [above] in the overlay stack.
  void insertBelow(OverlayEntry entry, {required OverlayEntry above}) {
    final index = _entries.indexOf(above);
    setState(() {
      entry._overlayState = this;
      if (index >= 0) {
        _entries.insert(index, entry);
      } else {
        _entries.insert(0, entry);
      }
    });
  }

  /// Removes an [entry] from the overlay.
  void removeEntry(OverlayEntry entry) {
    setState(() {
      entry._overlayState = null;
      _entries.remove(entry);
    });
  }

  /// Removes all entries.
  void clear() {
    setState(() {
      for (final entry in _entries) {
        entry._overlayState = null;
      }
      _entries.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return SizedBox.shrink();

    // Find the lowest entry we need to render: start from the last opaque
    // entry and include everything from there upward.
    var startIndex = 0;
    for (var i = _entries.length - 1; i >= 0; i--) {
      if (_entries[i].opaque) {
        startIndex = i;
        break;
      }
    }

    final children = <Widget>[];
    for (var i = startIndex; i < _entries.length; i++) {
      final entry = _entries[i];
      // Skip entries below an opaque entry that don't maintain state.
      if (i < startIndex && !entry.maintainState) continue;
      children.add(entry.builder(context));
    }

    if (children.isEmpty) return SizedBox.shrink();

    // Keep the render shape stable as entries are inserted/removed so
    // descendants (for example PopupMenuButton triggers) are not remounted
    // when overlay entry count changes.
    return Stack(fit: StackFit.expand, children: children);
  }
}
