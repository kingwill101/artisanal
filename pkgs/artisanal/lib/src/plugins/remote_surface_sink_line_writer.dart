import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

/// Serializes newline writes onto one [io.IOSink].
///
/// An `IOSink` rejects any write or flush issued while an earlier flush is
/// still draining ("StreamSink is bound to a stream"), so unsynchronized
/// callers crash on the first overlap. This writer queues each line behind
/// the previous one and keeps the queue alive after a failed send so later
/// lines still get their own attempt.
final class RemotePluginSinkLineWriter {
  RemotePluginSinkLineWriter(this._sink);

  final io.IOSink _sink;
  Future<void> _pending = Future<void>.value();

  /// Writes [line] after every previously queued line has flushed.
  Future<void> send(String line) {
    final result = _pending.then((_) {
      _sink.add(utf8.encode(line));
      return _sink.flush();
    });
    _pending = result.then((_) {}, onError: (_) {});
    return result;
  }
}
