import '../core/widget.dart';
import '../framework.dart';
import 'column.dart';
import 'text.dart';
import '../style.dart';

/// A widget that displays an error message with red styling.
///
/// Useful for error boundaries and fallback UIs when widget rendering fails.
///
/// ```dart
/// TUIErrorWidget(
///   message: 'Something went wrong',
///   details: 'Stack trace here...',
/// )
/// ```
class TUIErrorWidget extends StatelessWidget {
  TUIErrorWidget({
    required this.message,
    this.details,
    this.showIcon = true,
    super.key,
  });

  /// The error message to display.
  final String message;

  /// Optional additional details (e.g. stack trace).
  final String? details;

  /// Whether to show an error icon prefix.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final errorStyle = Style()
      ..foreground(Colors.red)
      ..bold(true);
    final detailStyle = Style()..foreground(Colors.red);

    final prefix = showIcon ? '✗ ' : '';
    final children = <Widget>[Text('$prefix$message', style: errorStyle)];

    if (details != null && details!.isNotEmpty) {
      children.add(Text(details!, style: detailStyle));
    }

    return Column(crossAxisAlignment: .start, children: children);
  }
}

/// A widget that deliberately throws during build.
///
/// This is primarily useful for testing error boundaries and error handling
/// in the widget framework.
///
/// ```dart
/// // In tests:
/// ErrorThrowingWidget(message: 'test error')
/// ```
class ErrorThrowingWidget extends StatelessWidget {
  ErrorThrowingWidget({this.message = 'Widget error', super.key});

  /// The error message to throw.
  final String message;

  @override
  Widget build(BuildContext context) {
    throw FlutterError(message);
  }
}

/// Simple error class for widget framework errors.
class FlutterError extends Error {
  FlutterError(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'FlutterError: $message';
}
