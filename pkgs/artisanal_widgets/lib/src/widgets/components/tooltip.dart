part of 'components_widgets.dart';

enum TooltipPosition { above, below }

/// A hover-triggered message bubble for a child widget.
///
/// When [show] is omitted, the tooltip appears on mouse enter and hides on
/// mouse exit. When an [Overlay] ancestor is available, the tooltip floats
/// above the surrounding layout instead of pushing sibling widgets down.
/// Passive hover requires `MouseMode.allMotion` when widgets are launched
/// through the low-level runtime directly. The higher-level widget runners
/// already opt into that mode by default.
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
  bool _hovered = false;
  OverlayEntry? _floatingEntry;
  bool _floatingSyncScheduled = false;
  ({int x, int y})? _lastPointer;

  void _setHovered(bool value, [MouseMsg? event]) {
    if (_hovered == value) return;
    if (event != null) {
      _lastPointer = (x: event.x, y: event.y);
    }
    setState(() {
      _hovered = value;
    });
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
    entry.remove();
  }

  ({int x, int y, int width, int height})? _triggerGeometry() {
    final host = elementOf(widget);
    if (host == null) return null;
    final root = _firstRenderObject(host);
    if (root == null) return null;
    final anchor = _bestPopupAnchorRenderObject(host, root);
    final global = _globalOffset(anchor);
    return (
      x: global.x.floor(),
      y: global.y.floor(),
      width: anchor.size.width.toInt(),
      height: anchor.size.height.toInt(),
    );
  }

  ({int x, int y, int width, int height})? _anchorGeometry() {
    final trigger = _triggerGeometry();
    if (trigger != null) return trigger;
    final pointer = _lastPointer;
    if (pointer == null) return null;
    return (x: pointer.x, y: pointer.y, width: 0, height: 0);
  }

  String _viewToString(Object view) {
    if (view is String) return view;
    return view.toString();
  }

  TooltipPosition _resolvedPosition({
    required TooltipPosition preferred,
    required int bubbleHeight,
    required ({int x, int y, int width, int height})? trigger,
    required Size viewport,
  }) {
    if (trigger == null) return preferred;
    final gap = 1;
    final fitsAbove = trigger.y >= bubbleHeight + gap;
    final fitsBelow =
        trigger.y + trigger.height + gap + bubbleHeight <= viewport.height;
    return switch (preferred) {
      TooltipPosition.above when !fitsAbove && fitsBelow => TooltipPosition.below,
      TooltipPosition.below when !fitsBelow && fitsAbove => TooltipPosition.above,
      _ => preferred,
    };
  }

  void _scheduleFloatingSync() {
    if (_floatingSyncScheduled || !mounted) return;
    _floatingSyncScheduled = true;
    scheduleMicrotask(() {
      _floatingSyncScheduled = false;
      if (!mounted) return;
      _syncFloatingEntry();
    });
  }

  Widget _buildBubble(BuildContext context) {
    final theme = ThemeScope.of(context);
    final labelStyle = _copyStyle(widget.textStyle ?? theme.bodySmall)
      ..foreground(widget.foreground ?? theme.onSurface);
    return Frame(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 1),
      background: widget.background ?? theme.surface,
      border: Border.normal,
      borderColor: theme.border,
      child: Text(widget.message, style: labelStyle),
    );
  }

  void _ensureFloatingEntry(OverlayState overlayState) {
    final existing = _floatingEntry;
    if (existing != null) {
      existing.markNeedsBuild();
      return;
    }

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final trigger = _anchorGeometry();
        if (trigger == null) return SizedBox.shrink();
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
        final gap = 1;
        final left = trigger.x.clamp(
          0,
          math.max(0, viewport.width.toInt() - bubbleWidth),
        );
        final top = switch (position) {
          TooltipPosition.above => (trigger.y - bubbleHeight - gap).clamp(
            0,
            math.max(0, viewport.height.toInt() - bubbleHeight),
          ),
          TooltipPosition.below => (trigger.y + trigger.height + gap).clamp(
            0,
            math.max(0, viewport.height.toInt() - bubbleHeight),
          ),
        };
        return Positioned(left: left, top: top, child: bubble);
      },
    );
    _floatingEntry = entry;
    overlayState.insert(entry);
  }

  void _syncFloatingEntry() {
    final show = widget.enabled && (widget.show ?? _hovered);
    if (!show) {
      _removeFloatingEntry();
      return;
    }
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) {
      _removeFloatingEntry();
      return;
    }
    if (_anchorGeometry() == null) {
      _scheduleFloatingSync();
      return;
    }
    _ensureFloatingEntry(overlayState);
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
  void initState() {
    super.initState();
    if (widget.enabled && widget.show == true) {
      _scheduleFloatingSync();
    }
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
    _syncFloatingEntry();
    if (visibilityChanged || (_floatingEntry != null && appearanceChanged)) {
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
      if (_floatingEntry != null) {
        _floatingEntry!.markNeedsBuild();
      } else {
        _scheduleFloatingSync();
      }
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
