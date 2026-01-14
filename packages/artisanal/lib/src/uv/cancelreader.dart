/// A cancelable reader for terminal input.
///
/// Provides an interface to read from [stdin] or other sources with the
/// ability to cancel the operation, which is essential for responsive
/// terminal applications.
///
/// {@category Ultraviolet}
/// {@subCategory Input}
///
/// {@macro artisanal_uv_events_overview}
library;

import 'dart:async';
import 'dart:io';

import '../terminal/stdin_stream.dart';

/// CancelReader provides a cancelable reader interface.
///
/// Upstream: `github.com/muesli/cancelreader`.
class CancelReader {
  /// Creates a new [CancelReader] from the given [source].
  CancelReader(this._source);

  /// Creates a new [CancelReader] from [stdin].
  factory CancelReader.stdin() => CancelReader(sharedStdinStream);

  final Stream<List<int>> _source;
  StreamSubscription<List<int>>? _subscription;
  final _controller = StreamController<List<int>>.broadcast();
  bool _isCanceled = false;

  /// Returns a stream of data from the reader.
  Stream<List<int>> get stream => _controller.stream;

  /// Starts reading from the source.
  void start() {
    if (_subscription != null) return;

    _subscription = _source.listen(
      (data) {
        if (!_isCanceled) {
          _controller.add(data);
        }
      },
      onError: (err) {
        if (!_isCanceled) {
          _controller.addError(err);
        }
      },
      onDone: () {
        if (!_isCanceled) {
          _controller.close();
        }
      },
    );
  }

  /// Cancels the reader.
  ///
  /// Returns a future that completes when the reader is successfully canceled.
  Future<void> cancel() async {
    _isCanceled = true;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Closes the reader and cleans up resources.
  Future<void> close() async {
    await cancel();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  /// Returns true if the reader has been canceled.
  bool get isCanceled => _isCanceled;
}
