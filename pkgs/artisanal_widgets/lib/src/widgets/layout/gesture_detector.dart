part of 'layout_widgets.dart';

class GestureDetector extends StatefulWidget {
  GestureDetector({
    required this.child,
    // --- Tap ---
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    // --- Double tap ---
    this.onDoubleTap,
    // --- Long press ---
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressEnd,
    // --- Drag ---
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    // --- Hover ---
    this.onEnter,
    this.onExit,
    // --- Wheel ---
    this.onWheel,
    // --- Behavior ---
    this.behavior = HitTestBehavior.deferToChild,
    this.enabled = true,
    this.captureMouse = true,
    super.key,
  });

  final Widget child;

  // Tap callbacks
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTap;
  final GestureTapCancelCallback? onTapCancel;

  // Double-tap callback
  final GestureDoubleTapCallback? onDoubleTap;

  // Long-press callbacks
  final GestureLongPressCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;

  // Drag callbacks
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  // Hover callbacks
  final MouseEnterCallback? onEnter;
  final MouseExitCallback? onExit;

  // Wheel callback
  final GestureWheelCallback? onWheel;

  // Hit-test behavior
  final HitTestBehavior behavior;

  final bool enabled;
  final bool captureMouse;

  @override
  State createState() => _GestureDetectorState();
}

class _GestureDetectorState extends State<GestureDetector> {
  bool _hovering = false;
  Offset? _lastPointerGlobal;
  Offset? _lastPointerLocal;

  /// Set to `true` when a [HitTestMouseMsg] is received in the current
  /// update cycle.  The subsequent broadcast [MouseMsg] should NOT trigger
  /// hover exit because we already know the cursor is within our bounds.
  bool _hitTestedThisFrame = false;

  // Recognizers (created lazily based on which callbacks are set)
  TapGestureRecognizer? _tap;
  DoubleTapGestureRecognizer? _doubleTap;
  LongPressGestureRecognizer? _longPress;
  DragGestureRecognizer? _drag;

  // Arena for this detector's recognizers
  GestureArenaManager? _arena;
  int? _arenaKey;

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  Cmd? didUpdateWidget(covariant GestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRecognizers();
    return null;
  }

  /// Creates or updates recognizer instances based on which callbacks are set.
  void _syncRecognizers() {
    // Tap recognizer
    if (_hasTapCallbacks) {
      _tap ??= TapGestureRecognizer();
      _tap!
        ..onTapDown = widget.onTapDown
        ..onTapUp = widget.onTapUp
        ..onTap = widget.onTap
        ..onTapCancel = widget.onTapCancel;
    } else {
      _tap?.dispose();
      _tap = null;
    }

    // Double-tap recognizer
    if (widget.onDoubleTap != null) {
      _doubleTap ??= DoubleTapGestureRecognizer();
      _doubleTap!.onDoubleTap = widget.onDoubleTap;
    } else {
      _doubleTap?.dispose();
      _doubleTap = null;
    }

    // Long-press recognizer
    if (_hasLongPressCallbacks) {
      _longPress ??= LongPressGestureRecognizer();
      _longPress!
        ..onLongPress = widget.onLongPress
        ..onLongPressStart = widget.onLongPressStart
        ..onLongPressEnd = widget.onLongPressEnd;
    } else {
      _longPress?.dispose();
      _longPress = null;
    }

    // Drag recognizer
    if (_hasDragCallbacks) {
      _drag ??= DragGestureRecognizer();
      _drag!
        ..onDragStart = widget.onDragStart
        ..onDragUpdate = widget.onDragUpdate
        ..onDragEnd = widget.onDragEnd;
    } else {
      _drag?.dispose();
      _drag = null;
    }
  }

  bool get _hasTapCallbacks =>
      widget.onTapDown != null ||
      widget.onTapUp != null ||
      widget.onTap != null ||
      widget.onTapCancel != null;

  bool get _hasLongPressCallbacks =>
      widget.onLongPress != null ||
      widget.onLongPressStart != null ||
      widget.onLongPressEnd != null;

  bool get _hasDragCallbacks =>
      widget.onDragStart != null ||
      widget.onDragUpdate != null ||
      widget.onDragEnd != null;

  void _captureMouse() {
    if (!widget.captureMouse) return;
    elementOf(widget)?.captureMouse();
  }

  void _releaseMouse() {
    if (!widget.captureMouse) return;
    elementOf(widget)?.releaseMouse();
  }

  void _setHovering(bool next, MouseMsg msg) {
    if (_hovering == next) return;
    _hovering = next;
    if (next) {
      widget.onEnter?.call(msg);
    } else {
      widget.onExit?.call(msg);
    }
  }

  /// Collects all pending commands from recognizers.
  List<Cmd> _collectCmds() {
    final cmds = <Cmd>[];
    if (_tap != null) {
      cmds.addAll(_tap!.pendingCmds);
      _tap!.pendingCmds.clear();
    }
    if (_doubleTap != null) {
      cmds.addAll(_doubleTap!.pendingCmds);
      _doubleTap!.pendingCmds.clear();
    }
    if (_longPress != null) {
      cmds.addAll(_longPress!.pendingCmds);
      _longPress!.pendingCmds.clear();
    }
    if (_drag != null) {
      cmds.addAll(_drag!.pendingCmds);
      _drag!.pendingCmds.clear();
    }
    return cmds;
  }

  Cmd? _batchCmds(List<Cmd> cmds) {
    if (cmds.isEmpty) return null;
    if (cmds.length == 1) return cmds.first;
    return Cmd.batch(cmds);
  }

  /// Sets up the arena for a new pointer sequence.
  void _startArena() {
    final recognizers = <GestureRecognizer>[
      if (_tap != null) _tap!,
      if (_doubleTap != null) _doubleTap!,
      if (_longPress != null) _longPress!,
      if (_drag != null) _drag!,
    ];

    if (recognizers.length > 1) {
      _arena = GestureArenaManager();
      _arenaKey = _arena!.createArena();
      for (final r in recognizers) {
        _arena!.add(_arenaKey!, r);
      }
    } else {
      _arena = null;
      _arenaKey = null;
    }
  }

  Cmd? _handleInBounds(MouseMsg event, {int? localX, int? localY}) {
    final lx = (localX ?? event.x).toDouble();
    final ly = (localY ?? event.y).toDouble();
    final localPos = Offset(lx, ly);
    _lastPointerGlobal = Offset(event.x.toDouble(), event.y.toDouble());
    _lastPointerLocal = localPos;

    final cmds = <Cmd>[];

    switch (event.action) {
      case MouseAction.press:
        if (event.button == MouseButton.left) {
          // Reset recognizers for a new sequence.
          _tap?.reset();
          // Only reset double-tap if it's defunct (completed or rejected).
          // If it's waiting for a second tap, we must not reset it.
          if (_doubleTap?.state == GestureRecognizerState.defunct) {
            _doubleTap?.reset();
          }
          _longPress?.reset();
          _drag?.reset();

          _startArena();
          _captureMouse();

          // Feed pointer-down to all active recognizers.
          _tap?.handlePointerDown(event, localPos);
          _doubleTap?.handlePointerDown(event, localPos);
          _longPress?.handlePointerDown(event, localPos);
          _drag?.handlePointerDown(event, localPos);

          cmds.addAll(_collectCmds());
        }
        break;

      case MouseAction.release:
        if (event.button == MouseButton.left) {
          // Feed pointer-up to all active recognizers.
          _tap?.handlePointerUp(event, localPos);
          _doubleTap?.handlePointerUp(event, localPos);
          _longPress?.handlePointerUp(event, localPos);
          _drag?.handlePointerUp(event, localPos);

          cmds.addAll(_collectCmds());

          // Close the arena if still open.
          if (_arena != null && _arenaKey != null) {
            _arena!.close(_arenaKey!);
            cmds.addAll(_collectCmds());
          }

          _releaseMouse();
        }
        break;

      case MouseAction.motion:
        if (!_hovering) {
          _setHovering(true, event);
        }
        // Feed pointer-move to active recognizers.
        _tap?.handlePointerMove(event, localPos);
        _doubleTap?.handlePointerMove(event, localPos);
        _longPress?.handlePointerMove(event, localPos);
        _drag?.handlePointerMove(event, localPos);

        cmds.addAll(_collectCmds());
        break;

      case MouseAction.wheel:
        final cmd = widget.onWheel?.call(event);
        if (cmd != null) cmds.add(cmd);
        break;
    }

    return _batchCmds(cmds);
  }

  Cmd? _handleCapturedMouse(MouseMsg msg) {
    final globalPos = Offset(msg.x.toDouble(), msg.y.toDouble());
    final lastGlobal = _lastPointerGlobal;
    final lastLocal = _lastPointerLocal;
    final localPos = lastGlobal != null && lastLocal != null
        ? Offset(
            lastLocal.dx + (globalPos.dx - lastGlobal.dx),
            lastLocal.dy + (globalPos.dy - lastGlobal.dy),
          )
        : globalPos;
    _lastPointerGlobal = globalPos;
    _lastPointerLocal = localPos;
    final cmds = <Cmd>[];

    if (msg.action == MouseAction.motion) {
      // Feed motion to recognizers.
      _tap?.handlePointerMove(msg, localPos);
      _doubleTap?.handlePointerMove(msg, localPos);
      _longPress?.handlePointerMove(msg, localPos);
      _drag?.handlePointerMove(msg, localPos);

      cmds.addAll(_collectCmds());
    }

    if (msg.action == MouseAction.release) {
      // Feed release to recognizers.
      _tap?.handlePointerUp(msg, localPos);
      _doubleTap?.handlePointerUp(msg, localPos);
      _longPress?.handlePointerUp(msg, localPos);
      _drag?.handlePointerUp(msg, localPos);

      cmds.addAll(_collectCmds());

      // Close the arena if still open.
      if (_arena != null && _arenaKey != null) {
        _arena!.close(_arenaKey!);
        cmds.addAll(_collectCmds());
      }

      _releaseMouse();
      _lastPointerGlobal = null;
      _lastPointerLocal = null;
    }

    return _batchCmds(cmds);
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (!widget.enabled) return null;

    // ---- New: render-tree hit-test dispatch ----
    if (msg is HitTestMouseMsg) {
      // Mark that we received a hit-test this update cycle so the
      // subsequent broadcast MouseMsg doesn't incorrectly fire onExit.
      final isWheelLike =
          msg.event.action == MouseAction.wheel ||
          msg.event.button == MouseButton.wheelUp ||
          msg.event.button == MouseButton.wheelDown ||
          msg.event.button == MouseButton.wheelLeft ||
          msg.event.button == MouseButton.wheelRight;
      _hitTestedThisFrame = !isWheelLike;
      return _handleInBounds(
        msg.event,
        localX: msg.localX.toInt(),
        localY: msg.localY.toInt(),
      );
    }

    // ---- Legacy: zone-based dispatch (kept for non-widget-app users) ----
    if (msg is ZoneInBoundsMsg) {
      final event = msg.event;
      final local = event.copyWith(
        x: msg.zone.pos(event).x,
        y: msg.zone.pos(event).y,
      );
      return _handleInBounds(local);
    }

    // ---- Global mouse events (for captured drags, hover exit, etc.) ----
    if (msg is MouseMsg) {
      // If the mouse moved but hit-testing didn't deliver to us (we got the
      // raw broadcast instead of a HitTestMouseMsg), the pointer has left
      // our bounds → fire onExit.  But skip this if we already received a
      // HitTestMouseMsg in the same update cycle (the broadcast always
      // follows the hit-test dispatch).
      if (msg.action == MouseAction.motion && _hovering) {
        if (_hitTestedThisFrame) {
          // We were hit-tested this frame — cursor is still in bounds.
          _hitTestedThisFrame = false;
        } else {
          // No hit-test this frame — cursor left our bounds.
          _setHovering(false, msg);
        }
      } else {
        _hitTestedThisFrame = false;
      }
      if (!widget.captureMouse) {
        return null;
      }
      return _handleCapturedMouse(msg);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _tap?.dispose();
    _doubleTap?.dispose();
    _longPress?.dispose();
    _drag?.dispose();
    _arena?.dispose();
    super.dispose();
  }
}
