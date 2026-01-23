import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// An exception renderer component.
///
/// ```dart
/// ExceptionComponent(
///   exception: myException,
///   stackTrace: stackTrace,
/// ).render();
/// ```
class ExceptionComponent extends DisplayComponent {
  const ExceptionComponent({
    required this.exception,
    this.stackTrace,
    this.maxStackFrames = 10,
    this.showFullPaths = false,
    this.renderConfig = const RenderConfig(),
  });

  final Object exception;
  final StackTrace? stackTrace;
  final int maxStackFrames;
  final bool showFullPaths;
  final RenderConfig renderConfig;

  @override
  String render() {
    Style style() => renderConfig.configureStyle(Style());

    final buffer = StringBuffer();

    // Exception header
    final exceptionType = exception.runtimeType.toString();
    final message = exception.toString();

    buffer.writeln();
    buffer.writeln(
      style().foreground(Colors.error).bold().render('  $exceptionType  '),
    );
    buffer.writeln();

    // Exception message
    final messageLines = message.split('\n');
    for (final line in messageLines) {
      buffer.writeln(
        '  ${style().foreground(Colors.warning).bold().render(line)}',
      );
    }

    // Stack trace
    if (stackTrace != null) {
      buffer.writeln();
      buffer.writeln(style().dim().render('  Stack trace:'));
      buffer.writeln();

      final frames = _parseStackTrace(stackTrace!);
      final displayFrames = frames.take(maxStackFrames).toList();

      for (var i = 0; i < displayFrames.length; i++) {
        final frame = displayFrames[i];
        final number = (i + 1).toString().padLeft(2);
        final location = showFullPaths
            ? frame.location
            : _shortenPath(frame.location);

        buffer.writeln(
          '  ${style().dim().render(number)}  ${style().foreground(Colors.info).bold().render(frame.member)}',
        );
        buffer.writeln('      ${style().dim().render(location)}');
      }

      if (frames.length > maxStackFrames) {
        final remaining = frames.length - maxStackFrames;
        buffer.writeln();
        buffer.writeln(
          style().dim().render('  ... and $remaining more frames'),
        );
      }
    }

    buffer.writeln();
    return buffer.toString();
  }

  List<_StackFrame> _parseStackTrace(StackTrace stackTrace) {
    final frames = <_StackFrame>[];
    final lines = stackTrace.toString().split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final match = RegExp(r'#\d+\s+(\S+)\s+\((.+)\)').firstMatch(line);
      if (match != null) {
        frames.add(
          _StackFrame(
            member: match.group(1) ?? 'unknown',
            location: match.group(2) ?? 'unknown',
          ),
        );
      } else {
        final altMatch = RegExp(r'#\d+\s+(.+)').firstMatch(line);
        if (altMatch != null) {
          frames.add(
            _StackFrame(member: altMatch.group(1) ?? 'unknown', location: ''),
          );
        }
      }
    }

    return frames;
  }

  String _shortenPath(String path) {
    if (path.startsWith('package:')) {
      return path;
    }
    final match = RegExp(r'([^/]+:\d+:\d+)$').firstMatch(path);
    if (match != null) {
      return match.group(1) ?? path;
    }
    return path;
  }
}

class _StackFrame {
  _StackFrame({required this.member, required this.location});

  final String member;
  final String location;
}

/// A simple one-line exception component.
///
/// ```dart
/// SimpleExceptionComponent(
///   exception: myException,
/// ).render();
/// ```
class SimpleExceptionComponent extends DisplayComponent {
  const SimpleExceptionComponent({
    required this.exception,
    this.renderConfig = const RenderConfig(),
  });

  final Object exception;
  final RenderConfig renderConfig;

  @override
  String render() {
    final exceptionType = exception.runtimeType.toString();
    final message = exception.toString().split('\n').first;
    final style = renderConfig.configureStyle(
      Style().foreground(Colors.error).bold(),
    );
    return '${style.render('[$exceptionType]')} $message';
  }
}
