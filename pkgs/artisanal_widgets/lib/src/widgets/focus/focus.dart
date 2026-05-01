library;

import 'package:artisanal/tui.dart' show Cmd, Msg, KeyMsg, TuiTrace;
import '../core/framework.dart'
    show BuildContext, InheritedWidget, State, StatefulWidget;

import '../layout/layout_widgets.dart' show GestureDetector;
import '../core/widget.dart';

typedef FocusListener = void Function();
typedef VoidCallback = void Function();
typedef FocusKeyCallback = Cmd? Function(KeyMsg msg);
typedef FocusChangedCallback = void Function(bool focused);

/// Controls which focusable widget is currently focused.
class FocusController {
  String? _focusedId;
  final Set<FocusListener> _listeners = <FocusListener>{};
  final Map<String, String?> _parents = {};
  final List<String> _focusableIds = [];
  String? _trapId;

  /// Saved focus ID to restore when the current trap is cleared.
  String? _savedFocusId;

  /// The currently focused ID, if any.
  String? get focusedId => _focusedId;

  /// The ID of the current focus trap, if any.
  String? get trapId => _trapId;

  /// Returns true when any widget is focused.
  bool get hasFocus => _focusedId != null;

  /// Returns true when [id] matches the current focus.
  ///
  /// When [searchPath] is true, returns true if [id] is an ancestor of the
  /// currently focused widget.
  bool isFocused(String id, {bool searchPath = false}) {
    if (_focusedId == id) return true;
    if (searchPath && _focusedId != null) {
      var current = _focusedId;
      while (current != null) {
        if (current == id) return true;
        current = _parents[current];
      }
    }
    return false;
  }

  /// Returns true if [id] is [ancestorId] or one of its descendants.
  bool isDescendant(String id, String ancestorId) {
    var current = id as String?;
    while (current != null) {
      if (current == ancestorId) return true;
      current = _parents[current];
    }
    return false;
  }

  /// Registers a parent-child relationship for focus IDs to support bubbling.
  ///
  /// If [focusable] is true, the ID is added to the navigation order.
  void register(String id, {String? parentId, bool focusable = true}) {
    if (id == parentId) return; // Prevent cycles
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'focus.register id=$id parentId=$parentId focusable=$focusable ids=$_focusableIds',
      );
    }
    _parents[id] = parentId;
    if (focusable && !_focusableIds.contains(id)) {
      _focusableIds.add(id);
    }
  }

  /// Unregisters a focus ID.
  void unregister(String id) {
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'focus.unregister id=$id wasFocused=${_focusedId == id} trapId=$_trapId savedFocus=$_savedFocusId',
      );
    }
    _parents.remove(id);
    _focusableIds.remove(id);
    // Clean children that referenced this ID as their parent — they are
    // orphaned now and leaving them causes stale ancestry chains that
    // break isDescendant() checks.
    _parents.removeWhere((_, parentId) => parentId == id);
    if (_focusedId == id) {
      _focusedId = null;
      _notify();
    }
    if (_trapId == id) {
      _trapId = null;
    }
    if (_savedFocusId == id) {
      _savedFocusId = null;
    }
  }

  /// Sets or clears the focus trap.
  ///
  /// When a trap is set, focus requests for IDs outside the trap's subtree
  /// will be ignored. The currently focused ID is saved so it can be
  /// restored when the trap is cleared.
  void setTrap(String? id) {
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'focus.setTrap id=$id prev=$_trapId focusedId=$_focusedId savedFocus=$_savedFocusId',
      );
    }
    if (id != null && _trapId == null) {
      _savedFocusId = _focusedId;
      if (TuiTrace.enabled) {
        TuiTrace.log('focus.setTrap saved=$_savedFocusId');
      }
    } else if (id == null && _trapId != null) {
      final restore = _savedFocusId;
      _savedFocusId = null;
      _trapId = null;
      if (TuiTrace.enabled) {
        TuiTrace.log(
          'focus.setTrap clearing restore=$restore ids=$_focusableIds focusedId=$_focusedId',
        );
      }
      if (restore != null && _focusableIds.contains(restore)) {
        _focusedId = restore;
        if (TuiTrace.enabled) {
          TuiTrace.log('focus.setTrap restored focusedId=$_focusedId');
        }
        _notify();
        return;
      }
      // Saved ID was stale (widget was recreated with a new ID) — clear
      // focus so the next autofocus widget can claim it.
      _focusedId = null;
      if (TuiTrace.enabled) {
        TuiTrace.log('focus.setTrap stale-restore, cleared focusedId');
      }
      _notify();
      return;
    }
    _trapId = id;
  }

  /// Moves focus to the next focusable widget.
  ///
  /// If a trap is active, only navigates within the trapped subtree.
  void next() {
    final candidates = _getVisibleCandidates();
    if (candidates.isEmpty) return;

    final index = _focusedId == null ? -1 : candidates.indexOf(_focusedId!);
    final nextIndex = (index + 1) % candidates.length;
    requestFocus(candidates[nextIndex]);
  }

  /// Moves focus to the previous focusable widget.
  ///
  /// If a trap is active, only navigates within the trapped subtree.
  void previous() {
    final candidates = _getVisibleCandidates();
    if (candidates.isEmpty) return;

    final index = _focusedId == null ? 0 : candidates.indexOf(_focusedId!);
    final prevIndex = (index - 1 + candidates.length) % candidates.length;
    requestFocus(candidates[prevIndex]);
  }

  List<String> _getVisibleCandidates() {
    if (_trapId == null) return _focusableIds;
    return _focusableIds.where((id) => isDescendant(id, _trapId!)).toList();
  }

  /// Requests focus for [id]. Returns true when focus changed.
  bool requestFocus(String id) {
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'focus.requestFocus id=$id current=$_focusedId trapId=$_trapId',
      );
    }
    if (_focusedId == id) return false;

    // Check trap
    if (_trapId != null && !isDescendant(id, _trapId!)) {
      if (TuiTrace.enabled) {
        TuiTrace.log(
          'focus.requestFocus DENIED id=$id trapId=$_trapId parents=$_parents',
        );
      }
      return false;
    }

    _focusedId = id;
    if (TuiTrace.enabled) {
      TuiTrace.log('focus.requestFocus OK focusedId=$_focusedId');
    }
    _notify();
    return true;
  }

  /// Clears focus. Returns true when focus changed.
  bool clearFocus() {
    if (_focusedId == null) return false;
    _focusedId = null;
    _notify();
    return true;
  }

  /// Adds a listener that fires when focus changes.
  void addListener(FocusListener listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(FocusListener listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List<FocusListener>.from(_listeners)) {
      listener();
    }
  }
}

/// Provides a [FocusController] to descendants.
class FocusScope extends StatefulWidget {
  FocusScope({
    required this.child,
    this.controller,
    this.isTrapped = false,
    super.key,
  });

  /// The subtree that can access the scope controller.
  final Widget child;

  /// Optional controller for this scope.
  final FocusController? controller;

  /// Whether this scope traps focus within its subtree.
  ///
  /// When true, focus cannot move to widgets outside this scope.
  final bool isTrapped;

  /// Returns the nearest [FocusController] from the widget tree.
  static FocusController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_FocusScopeProvider>()
        ?.controller;
  }

  /// Returns the nearest ancestor scope's focus ID.
  ///
  /// This is used by widgets like [TextField] that need to register
  /// in the focus tree for trap ancestry checks but live outside
  /// `focus.dart` and cannot access private state types.
  static String? nearestScopeId(BuildContext context) {
    final state = context.findAncestorStateOfType<_FocusScopeState>();
    return state?._focusId;
  }

  @override
  State createState() => _FocusScopeState();
}

class _FocusScopeState extends State<FocusScope> {
  FocusController? _controller;
  FocusController? _localController;
  String? _parentId;
  late final String _fallbackFocusId = widget.id;

  String get _focusId => _fallbackFocusId;

  @override
  void initState() {
    super.initState();
    _resolveController();
  }

  @override
  Cmd? didUpdateWidget(covariant FocusScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.isTrapped != widget.isTrapped) {
      _resolveController();
    }
    return null;
  }

  void _resolveController() {
    _controller?.removeListener(_handleControllerChange);
    final fromScope = FocusScope.of(context);
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'focus.scope.resolve id=$_focusId fromScope=${fromScope != null} isTrapped=${widget.isTrapped}',
      );
    }
    _controller =
        widget.controller ??
        fromScope ??
        (_localController ??= FocusController());
    _controller?.addListener(_handleControllerChange);

    // Register scope in focus tree
    final parentFocusable = context.findAncestorStateOfType<_FocusableState>();
    final parentScope = context.findAncestorStateOfType<_FocusScopeState>();
    _parentId = parentFocusable?._focusId ?? parentScope?._focusId;
    if (TuiTrace.enabled) {
      TuiTrace.log('focus.scope.resolve parentId=$_parentId');
    }

    if (_parentId != null) {
      _controller?.register(_focusId, parentId: _parentId, focusable: false);
    }

    if (widget.isTrapped) {
      _controller?.setTrap(_focusId);
    } else if (_controller?.trapId == _focusId) {
      _controller?.setTrap(null);
    }
  }

  void _handleControllerChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'focus.scope.dispose id=$_focusId isTrapped=${widget.isTrapped} trapId=${_controller?.trapId}',
      );
    }
    _controller?.removeListener(_handleControllerChange);
    if (widget.isTrapped && _controller?.trapId != null) {
      _controller?.setTrap(null);
    }
    _controller?.unregister(_focusId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FocusScopeProvider(
      key: widget.key,
      controller: _controller!,
      child: widget.child,
    );
  }
}

class _FocusScopeProvider extends InheritedWidget {
  _FocusScopeProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  final FocusController controller;

  @override
  bool updateShouldNotify(covariant _FocusScopeProvider oldWidget) {
    return controller != oldWidget.controller ||
        controller.focusedId != oldWidget.controller.focusedId;
  }
}

/// A widget that responds to keyboard input when focused.
class Focusable extends StatefulWidget {
  Focusable({
    required this.child,
    this.controller,
    this.focusId,
    this.autofocus = false,
    this.onKey,
    this.onFocusChange,
    this.onFocus,
    this.onBlur,
    this.enabled = true,
    super.key,
  });

  /// The widget subtree to render.
  final Widget child;

  /// Optional controller to manage focus across widgets.
  final FocusController? controller;

  /// Optional identifier used by the controller.
  final String? focusId;

  /// Whether to request focus on first build.
  final bool autofocus;

  /// Called when a key message is received while focused.
  final FocusKeyCallback? onKey;

  /// Called when focus changes for this widget.
  final FocusChangedCallback? onFocusChange;

  /// Called when this widget gains focus.
  final VoidCallback? onFocus;

  /// Called when this widget loses focus.
  final VoidCallback? onBlur;

  /// Whether focus and key handling are enabled.
  final bool enabled;

  @override
  State createState() => _FocusableState();
}

class _FocusableState extends State<Focusable> {
  FocusController? _controller;
  FocusController? _localController;
  bool _focused = false;
  bool _autofocusSent = false;
  String? _parentId;
  late final String _fallbackFocusId = widget.id;

  String get _focusId => widget.focusId ?? _fallbackFocusId;

  @override
  void initState() {
    super.initState();
    _resolveController();
  }

  @override
  Cmd? didUpdateWidget(covariant Focusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _resolveController();
    }
    if (oldWidget.focusId != widget.focusId) {
      _syncFocus();
    }
    return null;
  }

  void _resolveController() {
    _controller?.removeListener(_handleControllerChange);
    _controller =
        widget.controller ??
        FocusScope.of(context) ??
        (_localController ??= FocusController());
    _controller?.addListener(_handleControllerChange);

    // Find parent for bubbling
    final parentFocusable = context.findAncestorStateOfType<_FocusableState>();
    final parentScope = context.findAncestorStateOfType<_FocusScopeState>();
    _parentId = parentFocusable?._focusId ?? parentScope?._focusId;

    _controller?.register(_focusId, parentId: _parentId);

    _syncFocus();
  }

  void _handleControllerChange() {
    if (!mounted) return;
    _syncFocus();
  }

  void _syncFocus() {
    final controller = _controller;
    // When searching the path, we consider ourselves focused if we are the
    // primary focus OR an ancestor of the primary focus.
    final next =
        controller != null && controller.isFocused(_focusId, searchPath: true);
    if (next == _focused) return;
    setState(() {
      _focused = next;
    });
    widget.onFocusChange?.call(_focused);
    if (_focused) {
      widget.onFocus?.call();
    } else {
      widget.onBlur?.call();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChange);
    _controller?.unregister(_focusId);
    super.dispose();
  }

  void _requestFocus() {
    if (!widget.enabled) return;
    _controller?.requestFocus(_focusId);
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    final focused =
        widget.enabled &&
        (_controller?.isFocused(_focusId, searchPath: true) ?? _focused);
    if (!focused) return null;
    if (msg is KeyMsg) {
      return widget.onKey?.call(msg);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autofocus && !_autofocusSent) {
      _autofocusSent = true;
      _controller?.requestFocus(_focusId);
    }

    return GestureDetector(
      onTapDown: (_) {
        _requestFocus();
        return null;
      },
      captureMouse: false,
      child: widget.child,
    );
  }
}
