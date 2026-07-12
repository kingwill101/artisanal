import 'package:artisanal/artisanal.dart' show Layout;
import 'package:artisanal_widgets/src/widgets/core/element.dart';
import 'package:artisanal_widgets/src/widgets/rendering/render_object.dart';
import 'dart:math' as math;

import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color, Border, Style;

// ignore_for_file: unused_shown_name
/// Preferred position for tooltip placement relative to its child.
enum TooltipPosition { above, below }

/// A hover-triggered message bubble for a child widget.
///
/// When [show] is omitted, the tooltip appears on mouse enter and hides on
/// mouse exit. When an [Overlay] ancestor is available, the tooltip floats
/// above the surrounding layout instead of pushing sibling widgets down.
/// Passive hover requires `MouseMode.allMotion` when widgets are launched
/// through the low-level runtime directly. The higher-level widget runners
/// already opt into that mode by default.
///
/// Example:
/// ```dart
/// Tooltip(
///   message: 'Save your changes before closing',
///   child: IconButton(icon: Icon('💾')),
/// )
/// ```
class Tooltip extends StatefulWidget {
  Tooltip({
    required this.message,
    required this.child,
    this.position = TooltipPosition.above,
    this.show,
    this.padding,
    this.background,
    this.foreground,
    this.textStyle,
    this.enabled = true,
    super.key,
  });

  final String message;
  final Widget child;
  final TooltipPosition position;
  final bool? show;
  final EdgeInsets? padding;
  final Color? background;
  final Color? foreground;
  final Style? textStyle;
  final bool enabled;

  @override
  State createState() => _TooltipState();
}

class _TooltipState extends State<Tooltip> {
  static const int _cursorHorizontalOffset = 2;
  static const int _cursorVerticalOffset = 1;

  bool _hovered = false;
  OverlayEntry? _floatingEntry;
  ({int x, int y})? _lastPointer;
  bool _overlayRendered = false;

  void _traceLifecycle(
    String type, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!TuiTrace.enabled) return;
    TuiTrace.event(
      'tooltip.$type',
      tag: TraceTag.general,
      fields: <String, Object?>{
        'message': widget.message,
        'enabled': widget.enabled,
        'hovered': _hovered,
        'explicitShow': widget.show,
        'hasOverlayEntry': _floatingEntry != null,
        ...fields,
      },
    );
  }

  void _setHovered(bool value, [MouseMsg? event]) {
    if (_hovered == value) return;
    if (event != null) {
      _lastPointer = (x: event.x, y: event.y);
    }
    setState(() {
      _hovered = value;
    });
    _traceLifecycle(
      value ? 'hover.enter' : 'hover.exit',
      fields: <String, Object?>{
        if (event != null) 'x': event.x,
        if (event != null) 'y': event.y,
      },
    );
    if (value) {
      _syncFloatingEntry();
    } else {
      _removeFloatingEntry();
    }
  }

  void _removeFloatingEntry() {
    final entry = _floatingEntry;
    if (entry == null) return;
    _floatingEntry = null;
    if (_overlayRendered) {
      _traceLifecycle('overlay.hidden');
    }
    _overlayRendered = false;
    _traceLifecycle('overlay.remove');
    entry.remove();
  }

  ({int x, int y, int width, int height})? _triggerGeometry() {
    final host = elementOf(widget);
    if (host == null) return null;
    final root = firstRenderObject(host);
    if (root == null) return null;
    final anchor = bestPopupAnchorRenderObject(host, root);
    final global = globalOffset(anchor);
    return (
      x: global.x.floor(),
      y: global.y.floor(),
      width: anchor.size.width.toInt(),
      height: anchor.size.height.toInt(),
    );
  }

  bool get _preferPointerAnchor => widget.show != true && _hovered;

  ({int x, int y, int width, int height, bool usesPointer})? _anchorGeometry() {
    final pointer = _lastPointer;
    if (_preferPointerAnchor && pointer != null) {
      return (
        x: pointer.x,
        y: pointer.y,
        width: 0,
        height: 0,
        usesPointer: true,
      );
    }
    final trigger = _triggerGeometry();
    if (trigger != null) {
      return (
        x: trigger.x,
        y: trigger.y,
        width: trigger.width,
        height: trigger.height,
        usesPointer: false,
      );
    }
    if (pointer == null) return null;
    return (x: pointer.x, y: pointer.y, width: 0, height: 0, usesPointer: true);
  }

  String _viewToString(Object view) {
    if (view is String) return view;
    return view.toString();
  }

  TooltipPosition _resolvedPosition({
    required TooltipPosition preferred,
    required int bubbleHeight,
    required ({int x, int y, int width, int height, bool usesPointer})? trigger,
    required Size viewport,
  }) {
    if (trigger == null) return preferred;
    final gap = trigger.usesPointer ? _cursorVerticalOffset : 1;
    final fitsAbove = trigger.y >= bubbleHeight + gap;
    final fitsBelow =
        trigger.y + trigger.height + gap + bubbleHeight <= viewport.height;
    return switch (preferred) {
      TooltipPosition.above when !fitsAbove && fitsBelow =>
        TooltipPosition.below,
      TooltipPosition.below when !fitsBelow && fitsAbove =>
        TooltipPosition.above,
      _ => preferred,
    };
  }

  Widget _buildBubble(BuildContext context) {
    final theme = ThemeScope.of(context);
    final labelStyle = copyStyle(widget.textStyle ?? theme.bodySmall)
      ..foreground(widget.foreground ?? theme.onSurface);
    return Frame(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 1),
      background: widget.background ?? theme.surface,
      border: Border.normal,
      borderColor: theme.border,
      child: Text(widget.message, style: labelStyle),
    );
  }

  void _ensureFloatingEntry(
    OverlayState overlayState, {
    bool forceRebuild = false,
  }) {
    final existing = _floatingEntry;
    if (existing != null) {
      if (forceRebuild) {
        _traceLifecycle('overlay.markNeedsBuild');
        existing.markNeedsBuild();
      }
      return;
    }

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final trigger = _anchorGeometry();
        if (trigger == null) {
          if (_overlayRendered) {
            _overlayRendered = false;
            _traceLifecycle('overlay.hidden');
          }
          _traceLifecycle(
            'overlay.build.skipped',
            fields: const {'reason': 'no-anchor'},
          );
          return SizedBox.shrink();
        }
        final bubble = _buildBubble(context);
        final viewport = MediaQuery.of(overlayContext).size;
        final bubbleContent = _viewToString(bubble.view());
        final bubbleWidth = Layout.getWidth(bubbleContent);
        final bubbleHeight = Layout.getHeight(bubbleContent);
        final position = _resolvedPosition(
          preferred: widget.position,
          bubbleHeight: bubbleHeight,
          trigger: trigger,
          viewport: viewport,
        );
        final maxLeft = math.max(0, viewport.width.toInt() - bubbleWidth);
        final preferredLeft = trigger.usesPointer
            ? (() {
                final rightOfCursor = trigger.x + _cursorHorizontalOffset;
                if (rightOfCursor + bubbleWidth <= viewport.width) {
                  return rightOfCursor;
                }
                return trigger.x - bubbleWidth - _cursorHorizontalOffset;
              })()
            : (() {
                final anchorCenterX = trigger.x + (trigger.width ~/ 2);
                return anchorCenterX - (bubbleWidth ~/ 2);
              })();
        final left = preferredLeft.clamp(0, maxLeft);
        final top = switch (position) {
          TooltipPosition.above =>
            (trigger.y -
                    bubbleHeight -
                    (trigger.usesPointer ? _cursorVerticalOffset : 1))
                .clamp(0, math.max(0, viewport.height.toInt() - bubbleHeight)),
          TooltipPosition.below =>
            (trigger.y +
                    trigger.height +
                    (trigger.usesPointer ? _cursorVerticalOffset : 1))
                .clamp(0, math.max(0, viewport.height.toInt() - bubbleHeight)),
        };
        if (!_overlayRendered) {
          _overlayRendered = true;
          _traceLifecycle(
            'overlay.visible',
            fields: <String, Object?>{
              'left': left,
              'top': top,
              'bubbleWidth': bubbleWidth,
              'bubbleHeight': bubbleHeight,
              'triggerX': trigger.x,
              'triggerY': trigger.y,
              'triggerWidth': trigger.width,
              'triggerHeight': trigger.height,
              'usesPointer': trigger.usesPointer,
              'position': position.name,
            },
          );
        } else {
          _traceLifecycle(
            'overlay.build',
            fields: <String, Object?>{
              'left': left,
              'top': top,
              'usesPointer': trigger.usesPointer,
              'position': position.name,
            },
          );
        }
        return Positioned(
          left: left,
          top: top,
          child: IgnorePointer(ignoring: true, child: bubble),
        );
      },
    );
    _floatingEntry = entry;
    _traceLifecycle('overlay.insert');
    overlayState.insert(entry);
  }

  void _syncFloatingEntry({bool forceRebuild = false}) {
    final show = widget.enabled && (widget.show ?? _hovered);
    _traceLifecycle(
      'sync',
      fields: <String, Object?>{
        'show': show,
        'hasOverlayAncestor': Overlay.maybeOf(context) != null,
        'hasAnchor': _anchorGeometry() != null,
      },
    );
    if (!show) {
      _removeFloatingEntry();
      return;
    }
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) {
      _removeFloatingEntry();
      return;
    }
    if (_anchorGeometry() == null) return;
    _ensureFloatingEntry(overlayState, forceRebuild: forceRebuild);
  }

  @override
  Cmd? handleInit() {
    if (widget.enabled && widget.show == true) {
      _syncFloatingEntry();
      return Cmd.repaint();
    }
    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is! MouseMsg || !_hovered) return null;
    if (msg.action != MouseAction.motion) return null;
    final nextPointer = (x: msg.x, y: msg.y);
    if (_lastPointer == nextPointer) return null;
    _lastPointer = nextPointer;
    if (_floatingEntry != null) {
      _traceLifecycle(
        'hover.move',
        fields: <String, Object?>{'x': msg.x, 'y': msg.y},
      );
      _syncFloatingEntry(forceRebuild: true);
      return Cmd.repaint();
    }
    return null;
  }

  @override
  Cmd? didUpdateWidget(covariant Tooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final visibilityChanged =
        oldWidget.enabled != widget.enabled || oldWidget.show != widget.show;
    final appearanceChanged =
        oldWidget.message != widget.message ||
        oldWidget.position != widget.position ||
        oldWidget.padding != widget.padding ||
        oldWidget.background != widget.background ||
        oldWidget.foreground != widget.foreground ||
        oldWidget.textStyle != widget.textStyle;
    if (!widget.enabled || widget.show == false) {
      _removeFloatingEntry();
      return visibilityChanged ? Cmd.repaint() : null;
    }
    if (visibilityChanged || appearanceChanged) {
      _syncFloatingEntry(forceRebuild: appearanceChanged);
    }
    final showInline =
        Overlay.maybeOf(context) == null &&
        widget.enabled &&
        (widget.show ?? _hovered);
    if (visibilityChanged || (showInline && appearanceChanged)) {
      return Cmd.repaint();
    }
    return null;
  }

  @override
  void dispose() {
    _removeFloatingEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.enabled && (widget.show ?? _hovered);
    final bubble = _buildBubble(context);

    final target = widget.enabled
        ? MouseRegion(
            onEnter: (event) {
              _setHovered(true, event);
              return Cmd.repaint();
            },
            onExit: (event) {
              _setHovered(false, event);
              return Cmd.repaint();
            },
            child: widget.child,
          )
        : widget.child;

    if (!show) return target;

    final overlayState = Overlay.maybeOf(context);
    if (overlayState != null) {
      return target;
    }

    _removeFloatingEntry();

    return Column(
      gap: 1,
      children: widget.position == TooltipPosition.above
          ? [bubble, target]
          : [target, bubble],
    );
  }
}
