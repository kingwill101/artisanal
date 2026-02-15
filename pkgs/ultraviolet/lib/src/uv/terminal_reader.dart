/// Reads and decodes terminal input events.
///
/// Orchestrates the [CancelReader] and [UvEventStreamParser] to provide a
/// high-level stream of decoded terminal [Event]s.
///
/// {@category Ultraviolet}
/// {@subCategory Input}
///
/// {@macro artisanal_uv_events_overview}
library;

import 'dart:async';

import 'cancelreader.dart';
import 'decoder.dart';
import 'event.dart';
import 'event_stream.dart';
import 'key.dart';
import 'key_table.dart';

/// Default timeout at which the [TerminalReader] will process ESC sequences.
const Duration defaultEscTimeout = Duration(milliseconds: 50);

/// TerminalReader represents an input event loop that reads input events from
/// a reader and parses them into human-readable events.
///
/// Upstream: `third_party/ultraviolet/terminal_reader.go` (`TerminalReader`).
class TerminalReader {
  TerminalReader(
    this._reader, {
    this.term = '',
    this.escTimeout = defaultEscTimeout,
    this.useTerminfo = false,
    LegacyKeyEncoding? legacy,
  }) : _parser = UvEventStreamParser(
         decoder: EventDecoder(legacy: legacy, useTerminfo: useTerminfo),
       ),
       _legacy = legacy ?? const LegacyKeyEncoding() {
    _table = buildKeysTable(_legacy, term, useTerminfo: useTerminfo);
  }

  final CancelReader _reader;
  final String term;
  Duration escTimeout;
  final bool useTerminfo;
  final LegacyKeyEncoding _legacy;
  final UvEventStreamParser _parser;
  late final Map<String, Key> _table;

  final _eventController = StreamController<Event>.broadcast();
  Timer? _escTimer;
  bool _isStarted = false;

  /// Returns a stream of events from the terminal.
  Stream<Event> get events => _eventController.stream;
  void start() {
    if (_isStarted) return;
    _isStarted = true;

    _reader.start();
    _reader.stream.listen(
      _handleData,
      onError: (err) {
        _eventController.addError(err);
      },
      onDone: () {
        _flush(expired: true);
        _eventController.close();
      },
    );
  }

  void _handleData(List<int> data) {
    _escTimer?.cancel();
    _escTimer = null;

    final events = _parser.parseAll(data, expired: false);
    _processEvents(events);

    if (_parser.hasPending) {
      _escTimer = Timer(escTimeout, () {
        _flush(expired: true);
      });
    }
  }

  void _flush({required bool expired}) {
    final events = _parser.parseAll([], expired: expired);
    _processEvents(events);
  }

  void _processEvents(List<Event> events) {
    for (final event in events) {
      if (event is UnknownEvent) {
        final key = _table[event.value];
        if (key != null) {
          _eventController.add(KeyPressEvent(key));
          continue;
        }
      }
      _eventController.add(event);
    }
  }

  /// Closes the reader and cleans up resources.
  Future<void> close() async {
    _escTimer?.cancel();
    _escTimer = null;
    await _reader.close();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }
}
