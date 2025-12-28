import 'dart:math';

import 'package:contextual/contextual.dart';
import 'package:contextual_shelf/contextual_shelf.dart';
import 'package:shelf/shelf.dart';

// #region logging-setup
// #region logging-core
Logger buildLogger() {
  final logger = Logger()
    ..environment('development')
    ..addChannel(
      'console',
      ConsoleLogDriver(),
      formatter: PrettyLogFormatter(),
    );

  return logger;
}
// #endregion logging-core

// #region logging-http
HttpLogger buildHttpLogger(Logger logger) {
  final writer = DefaultLogWriter(
    logger,
    sanitizer: Sanitizer(mask: '[REDACTED]'),
  );
  return HttpLogger(LogAllRequests(), writer);
}
// #endregion logging-http

class LogAllRequests implements LogProfile {
  @override
  bool shouldLogRequest(Request request) => true;
}

// #region logging-request-id
Middleware requestIdMiddleware() {
  return (inner) {
    return (request) async {
      final requestId = _randomId();
      final updated = request.change(context: {'requestId': requestId});
      return inner(updated);
    };
  };
}

// #endregion logging-request-id

String _randomId() {
  final rand = Random();
  final now = DateTime.now().millisecondsSinceEpoch;
  final salt = rand.nextInt(999999);
  return '$now-$salt';
}

// #endregion logging-setup
