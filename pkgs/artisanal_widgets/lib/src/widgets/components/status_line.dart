import 'package:artisanal/style.dart' show Color, Style;
import 'package:artisanal/widgets.dart';

/// A typed item that can be displayed in a [StatusLine].
///
/// Unlike a raw [Widget] list, [StatusItem] provides semantic types that
/// enable consistent rendering and automatic width calculation.
///
/// ```dart
/// StatusItem.text('[INSERT]')
/// StatusItem.keyHint('^C', 'Quit')
/// StatusItem.progress(50, 100)
/// StatusItem.spinner(frameIndex)
/// StatusItem.spacer()
/// ```
// ignore_for_file: use_null_aware_elements
sealed class StatusItem {
  const StatusItem._();

  /// Plain text item.
  const factory StatusItem.text(String text) = _TextStatusItem;

  /// A keyboard shortcut hint (e.g., "^C Quit").
  const factory StatusItem.keyHint(String key, String action) =
      _KeyHintStatusItem;

  /// A progress percentage display (e.g., "50%").
  const factory StatusItem.progress(int current, int total) =
      _ProgressStatusItem;

  /// A braille spinner that cycles through frames.
  const factory StatusItem.spinner(int frameIndex) = _SpinnerStatusItem;

  /// A flexible spacer that expands to fill available space.
  const factory StatusItem.spacer() = _SpacerStatusItem;

  /// A custom widget item.
  factory StatusItem.widget(Widget widget) = _WidgetStatusItem;

  /// Whether this item is a spacer.
  bool get isSpacer => this is _SpacerStatusItem;

  /// Calculate the display width of this item in terminal cells.
  int get displayWidth => switch (this) {
    _TextStatusItem(:final text) => text.length,
    _KeyHintStatusItem(:final key, :final action) =>
      key.length + 1 + action.length,
    _ProgressStatusItem(:final current, :final total) => _progressText(
      current,
      total,
    ).length,
    _SpinnerStatusItem() => 1,
    _SpacerStatusItem() => 0,
    _WidgetStatusItem() => 0,
  };

  /// Render this item to a display string.
  String renderToString() => switch (this) {
    _TextStatusItem(:final text) => text,
    _KeyHintStatusItem(:final key, :final action) => '$key $action',
    _ProgressStatusItem(:final current, :final total) => _progressText(
      current,
      total,
    ),
    _SpinnerStatusItem(:final frameIndex) =>
      _spinnerFrames[frameIndex % _spinnerFrames.length],
    _SpacerStatusItem() => '',
    _WidgetStatusItem() => '',
  };

  static String _progressText(int current, int total) {
    if (total <= 0) return '0%';
    final pct = (current * 100) ~/ total;
    return '$pct%';
  }

  static const _spinnerFrames = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏',
  ];
}

class _TextStatusItem extends StatusItem {
  const _TextStatusItem(this.text) : super._();
  final String text;
}

class _KeyHintStatusItem extends StatusItem {
  const _KeyHintStatusItem(this.key, this.action) : super._();
  final String key;
  final String action;
}

class _ProgressStatusItem extends StatusItem {
  const _ProgressStatusItem(this.current, this.total) : super._();
  final int current;
  final int total;
}

class _SpinnerStatusItem extends StatusItem {
  const _SpinnerStatusItem(this.frameIndex) : super._();
  final int frameIndex;
}

class _SpacerStatusItem extends StatusItem {
  const _SpacerStatusItem() : super._();
}

class _WidgetStatusItem extends StatusItem {
  const _WidgetStatusItem(this.widget) : super._();
  final Widget widget;
}

/// A horizontal status bar with left, center, and right regions.
///
/// Each region accepts typed [StatusItem]s or raw [Widget]s. The center
/// region is automatically centered in the space between left and right.
/// Spacer items expand to fill available space within their region.
///
/// ```dart
/// StatusLine(
///   left: [StatusItem.text('[INSERT]')],
///   center: [StatusItem.text('file.rs')],
///   right: [
///     StatusItem.keyHint('^C', 'Quit'),
///     StatusItem.text('Ln 42, Col 10'),
///   ],
/// )
/// ```
class StatusLine extends StatelessWidget {
  StatusLine({
    this.left = const [],
    this.center = const [],
    this.right = const [],
    this.background,
    this.foreground,
    this.padding,
    this.separator,
    this.gap = 1,
    super.key,
  });

  /// Items aligned to the left edge.
  final List<StatusItem> left;

  /// Items centered between left and right regions.
  final List<StatusItem> center;

  /// Items aligned to the right edge.
  final List<StatusItem> right;

  /// Background color. Defaults to [Theme.surface].
  final Color? background;

  /// Default foreground color. Defaults to [Theme.onSurface].
  final Color? foreground;

  /// Padding inside the status line.
  final EdgeInsets? padding;

  /// Separator string between non-spacer items (e.g., " │ ").
  /// When null, items are separated by [gap] spaces.
  final String? separator;

  /// Gap between non-spacer items when no [separator] is set (default: 1).
  final int gap;

  /// Whether the status line has any content.
  bool get isEmpty => left.isEmpty && center.isEmpty && right.isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final fg = foreground ?? theme.onSurface;
    final fgStyle = copyStyle(theme.bodySmall)..foreground(fg);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      color: bg,
      child: _buildLayout(fgStyle, fg),
    );
  }

  Widget _buildLayout(Style fgStyle, Color fg) {
    final leftWidget = _buildRegion(left, fgStyle, fg);
    final rightWidget = _buildRegion(right, fgStyle, fg);
    final centerWidget = _buildRegion(center, fgStyle, fg);

    if (center.isEmpty) {
      return Row(
        gap: 0,
        children: [
          if (leftWidget != null) leftWidget,
          Spacer(),
          if (rightWidget != null) rightWidget,
        ],
      );
    }

    return Row(
      gap: 0,
      children: [
        if (leftWidget != null) leftWidget,
        Spacer(),
        if (centerWidget != null) centerWidget,
        Spacer(),
        if (rightWidget != null) rightWidget,
      ],
    );
  }

  Widget? _buildRegion(List<StatusItem> items, Style fgStyle, Color fg) {
    if (items.isEmpty) return null;

    final children = <Widget>[];
    var prevNonSpacer = false;

    for (final item in items) {
      if (item.isSpacer) {
        children.add(Spacer());
        prevNonSpacer = false;
        continue;
      }

      if (prevNonSpacer) {
        if (separator != null) {
          children.add(Text(separator!, style: fgStyle));
        } else if (gap > 0) {
          children.add(Text(' ' * gap));
        }
      }

      if (item is _WidgetStatusItem) {
        children.add(item.widget);
      } else {
        children.add(Text(item.renderToString(), style: fgStyle));
      }
      prevNonSpacer = true;
    }

    if (children.isEmpty) return null;
    return Row(gap: 0, children: children);
  }
}
