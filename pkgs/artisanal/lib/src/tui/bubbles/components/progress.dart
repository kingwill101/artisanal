/// Progress indicator components for TUI applications.
///
/// Provides progress bars and spinner frames for displaying operation
/// progress to users.
///
/// ## Progress Bar
///
/// ```dart
/// print(ProgressBar(
///   current: 75,
///   total: 100,
///   showPercentage: true,
/// ).render());
/// // Output: ██████████████████████████████░░░░░░░░░░ 75%
/// ```
///
/// ## Spinner Frame
///
/// For animated spinners, use [SpinnerFrame] with a model that cycles
/// through frames. See also [SpinnerModel] in the bubbles library.
///
/// {@category TUI}
/// {@category Components}
library;

import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A progress indicator component.
class ProgressBar extends DisplayComponent {
  const ProgressBar({
    required this.current,
    required this.total,
    this.width = 40,
    this.fillChar = '█',
    this.emptyChar = '░',
    this.showPercentage = true,
  });

  final int current;
  final int total;
  final int width;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;

  @override
  String render() {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '${fillChar * filled}${emptyChar * empty}';
    final output = showPercentage
        ? '$bar ${(progress * 100).toStringAsFixed(0)}%'
        : bar;

    return output;
  }
}

/// A spinner frame component (for use in animations).
class SpinnerFrame extends DisplayComponent {
  const SpinnerFrame({
    required this.frame,
    required this.message,
    this.renderConfig = const RenderConfig(),
  });

  final String frame;
  final String message;
  final RenderConfig renderConfig;

  @override
  String render() {
    final style = renderConfig.configureStyle(Style().foreground(Colors.info));
    return '${style.render(frame)} $message';
  }
}
