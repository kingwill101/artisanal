part of 'components_widgets.dart';

/// A convenience widget that wraps [SingleChildScrollView] with optional
/// sizing and an optional [Scrollbar].
///
/// Provide [width] and/or [height] to constrain the scroll area. When
/// [showScrollbar] is true (the default), a [Scrollbar] is drawn to the
/// right of the scrollable content.
///
/// You may supply an external [ScrollController] to programmatically
/// control the scroll position or to share it with other widgets.
class ScrollArea extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Use a shared controller so the scrollbar and scroll view stay in sync.
    final ctrl = controller ?? WidgetScrollController();

    Widget inner = SingleChildScrollView(
      controller: ctrl,
      padding: padding,
      child: child,
    );

    if (showScrollbar) {
      inner = Scrollbar(controller: ctrl, child: inner);
    }

    if (width != null || height != null) {
      inner = Container(width: width, height: height, child: inner);
    }

    return inner;
  }
}
