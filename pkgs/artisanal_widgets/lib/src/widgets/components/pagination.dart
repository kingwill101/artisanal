import 'dart:math' as math;

import 'package:artisanal/widgets.dart';

/// A page navigation control with prev/next buttons.
///
/// The [Pagination] widget displays a page indicator with navigation buttons.
/// The [page] is the current page (1-indexed) and [pageCount] is the total
/// number of pages. Use [onChanged] to receive page change callbacks.
///
/// Set [showEdges] to true to also display First/Last buttons.
///
/// Example:
/// ```dart
/// Pagination(
///   page: _currentPage,
///   pageCount: 10,
///   showEdges: true,
///   onChanged: (p) => setState(() => _currentPage = p),
/// )
/// ```
class Pagination extends StatelessWidget {
  Pagination({
    required this.page,
    required this.pageCount,
    this.onChanged,
    this.showEdges = false,
    this.gap = 1,
    super.key,
  });

  final int page;
  final int pageCount;
  final ValueCmdCallback<int>? onChanged;
  final bool showEdges;
  final int gap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final clampedPage = page.clamp(1, math.max(1, pageCount)).toInt();
    final labelStyle = copyStyle(theme.labelSmall)..foreground(theme.muted);

    final controls = <Widget>[];
    if (showEdges) {
      controls.add(
        Button(
          label: 'First',
          size: ButtonSize.small,
          variant: ButtonVariant.ghost,
          enabled: clampedPage > 1,
          onPressed: onChanged == null ? null : () => onChanged?.call(1),
        ),
      );
    }

    controls.add(
      Button(
        label: 'Prev',
        size: ButtonSize.small,
        variant: ButtonVariant.ghost,
        enabled: clampedPage > 1,
        onPressed: onChanged == null
            ? null
            : () => onChanged?.call(clampedPage - 1),
      ),
    );

    controls.add(
      Text('Page $clampedPage / ${math.max(1, pageCount)}', style: labelStyle),
    );

    controls.add(
      Button(
        label: 'Next',
        size: ButtonSize.small,
        variant: ButtonVariant.ghost,
        enabled: clampedPage < pageCount,
        onPressed: onChanged == null
            ? null
            : () => onChanged?.call(clampedPage + 1),
      ),
    );

    if (showEdges) {
      controls.add(
        Button(
          label: 'Last',
          size: ButtonSize.small,
          variant: ButtonVariant.ghost,
          enabled: clampedPage < pageCount,
          onPressed: onChanged == null
              ? null
              : () => onChanged?.call(pageCount),
        ),
      );
    }

    return Row(gap: gap, children: controls);
  }
}
