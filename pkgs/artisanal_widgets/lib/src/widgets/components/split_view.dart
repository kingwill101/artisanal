import '_component_foundation.dart';

/// A two-pane view that arranges children along an axis.
///
/// The [SplitView] widget displays [first] and [second] children with optional
/// [separator] and [gap]. Use [firstFlex] and [secondFlex] to control the
/// relative sizes of the panes.
///
/// By default, axes are horizontal (side-by-side). Set [axis] to
/// [Axis.vertical] for top-to-bottom arrangement.
///
/// Example:
/// ```dart
/// SplitView(
///   first: ListView(children: [Text('Pane 1')]),
///   second: EditorArea(),
///   gap: 1,
///   separator: VerticalDivider(),
/// )
/// ```
class SplitView extends StatelessWidget {
  SplitView({
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.gap = 1,
    this.separator,
    super.key,
  });

  final Widget first;
  final Widget second;
  final Axis axis;
  final int firstFlex;
  final int secondFlex;
  final int gap;
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    final sep = separator ?? _defaultSeparator();
    if (axis == Axis.horizontal) {
      return Row(
        gap: 0,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: firstFlex, child: first),
          if (gap > 0 || separator != null) sep,
          Expanded(flex: secondFlex, child: second),
        ],
      );
    }

    return Column(
      gap: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: firstFlex, child: first),
        if (gap > 0 || separator != null) sep,
        Expanded(flex: secondFlex, child: second),
      ],
    );
  }

  Widget _defaultSeparator() {
    return axis == Axis.horizontal
        ? SizedBox(width: gap)
        : SizedBox(height: gap);
  }
}

/// A two-pane view with a pointer-draggable separator.
///
/// The first pane starts at [initialFirstExtent] cells and is constrained by
/// [minFirstExtent] and [minSecondExtent]. Dragging [separator] resizes the
/// panes without requiring either child to own layout state.
///
/// This widget is intentionally separate from [SplitView]: use [SplitView]
/// for proportional, non-interactive layouts and [ResizableSplitView] when
/// users should control the divider.
class ResizableSplitView extends StatefulWidget {
  ResizableSplitView({
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFirstExtent = 24,
    this.minFirstExtent = 8,
    this.minSecondExtent = 8,
    this.separatorExtent = 1,
    this.separator,
    this.onChanged,
    super.key,
  }) : assert(initialFirstExtent >= 0),
       assert(minFirstExtent >= 0),
       assert(minSecondExtent >= 0),
       assert(separatorExtent > 0);

  /// Content before the draggable separator.
  final Widget first;

  /// Content after the draggable separator.
  final Widget second;

  /// Direction in which the panes are arranged and resized.
  final Axis axis;

  /// Initial width or height of [first], in terminal cells.
  final int initialFirstExtent;

  /// Smallest width or height allowed for [first].
  final int minFirstExtent;

  /// Smallest width or height allowed for [second].
  final int minSecondExtent;

  /// Width or height of the separator's drag target.
  final int separatorExtent;

  /// Optional separator content.
  final Widget? separator;

  /// Called after dragging changes the first pane's extent.
  final void Function(int extent)? onChanged;

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  int? _firstExtent;

  int _clampExtent(int extent, int available) {
    final maximum =
        (available - widget.separatorExtent - widget.minSecondExtent).clamp(
          0,
          available,
        );
    final minimum = widget.minFirstExtent.clamp(0, maximum);
    return extent.clamp(minimum, maximum);
  }

  void _resizeBy(int delta, int available) {
    if (delta == 0) return;
    final current = _clampExtent(
      _firstExtent ?? widget.initialFirstExtent,
      available,
    );
    final next = _clampExtent(current + delta, available);
    if (next == current) return;
    setState(() => _firstExtent = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawAvailable = widget.axis == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final available = rawAvailable.isFinite
            ? rawAvailable.toInt()
            : widget.initialFirstExtent +
                  widget.separatorExtent +
                  widget.minSecondExtent;
        final firstExtent = _clampExtent(
          _firstExtent ?? widget.initialFirstExtent,
          available,
        );
        final separator = GestureDetector(
          onDragUpdate: (details) {
            final delta = widget.axis == Axis.horizontal
                ? details.delta.dx.round()
                : details.delta.dy.round();
            _resizeBy(delta, available);
            return null;
          },
          child: SizedBox(
            width: widget.axis == Axis.horizontal
                ? widget.separatorExtent
                : null,
            height: widget.axis == Axis.vertical
                ? widget.separatorExtent
                : null,
            child:
                widget.separator ??
                Text(widget.axis == Axis.horizontal ? '│' : '─'),
          ),
        );

        if (widget.axis == Axis.horizontal) {
          return Row(
            gap: 0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: firstExtent, child: widget.first),
              separator,
              Expanded(child: widget.second),
            ],
          );
        }
        return Column(
          gap: 0,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: firstExtent, child: widget.first),
            separator,
            Expanded(child: widget.second),
          ],
        );
      },
    );
  }
}
