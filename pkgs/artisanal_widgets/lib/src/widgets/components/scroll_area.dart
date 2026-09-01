import 'package:artisanal/runtime.dart' show Cmd;
import 'package:artisanal_widgets/widgets.dart';

import 'package:artisanal/runtime.dart';

/// A convenience widget that wraps [SingleChildScrollView] with optional
/// sizing and an optional [Scrollbar].
///
/// Provide [width] and/or [height] to constrain the scroll area. When
/// [showScrollbar] is true (the default), a [Scrollbar] is drawn to the
/// right of the scrollable content.
///
/// You may supply an external [ScrollController] to programmatically

// ignore_for_file: unused_shown_name
/// control the scroll position or to share it with other widgets.
class ScrollArea extends StatefulWidget {
  ScrollArea({
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.showScrollbar = true,
    this.controller,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;
  final int? width;
  final int? height;
  final bool showScrollbar;
  final ScrollController? controller;

  @override
  State createState() => _ScrollAreaState();
}

class _ScrollAreaState extends State<ScrollArea> {
  WidgetScrollController? _ownController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownController ??= WidgetScrollController());

  @override
  Cmd? didUpdateWidget(covariant ScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      _ownController = null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _effectiveController;

    Widget inner = SingleChildScrollView(
      controller: ctrl,
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.showScrollbar) {
      inner = Scrollbar(controller: ctrl, child: inner);
    }

    if (widget.width != null || widget.height != null) {
      inner = Container(
        width: widget.width,
        height: widget.height,
        child: inner,
      );
    }

    return inner;
  }
}
