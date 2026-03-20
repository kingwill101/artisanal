import 'dart:async';

import 'remote_surface_protocol.dart';
import 'remote_surface_session.dart';
import 'remote_surface_state.dart';

/// Host-side controller that binds a session to a surface store.
///
/// Surface lifecycle and frame messages are applied to [surfaces]
/// automatically. Non-surface plugin messages are forwarded through
/// [otherMessages] so hosts can handle custom plugin traffic separately.
final class RemotePluginSurfaceController {
  RemotePluginSurfaceController.bind(
    this.session, {
    RemotePluginSurfaceStore? surfaces,
  }) : surfaces = surfaces ?? RemotePluginSurfaceStore() {
    _surfaceMessages = StreamController<RemotePluginMessage>.broadcast(
      onListen: _flushPendingSurfaceEvents,
    );
    _otherMessages = StreamController<RemotePluginMessage>.broadcast(
      onListen: _flushPendingOtherEvents,
    );
    _subscription = session.messages.listen(
      (message) {
        if (_isSurfaceMessage(message)) {
          this.surfaces.apply(message);
          _emitSurfaceMessage(message);
          return;
        }

        _emitOtherMessage(message);
      },
      onError: (Object error, StackTrace stackTrace) {
        _emitSurfaceError(error, stackTrace);
        _emitOtherError(error, stackTrace);
      },
      onDone: () {
        if (!_disposed) {
          _surfaceMessages.close();
          _otherMessages.close();
        }
      },
      cancelOnError: false,
    );
  }

  final RemotePluginSession session;
  final RemotePluginSurfaceStore surfaces;
  late final StreamController<RemotePluginMessage> _surfaceMessages;
  late final StreamController<RemotePluginMessage> _otherMessages;
  final List<_PendingControllerEvent> _pendingSurfaceEvents =
      <_PendingControllerEvent>[];
  final List<_PendingControllerEvent> _pendingOtherEvents =
      <_PendingControllerEvent>[];

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  /// Surface lifecycle and frame messages after they have been applied.
  Stream<RemotePluginMessage> get surfaceMessages => _surfaceMessages.stream;

  /// Non-surface plugin messages that the host may want to handle separately.
  Stream<RemotePluginMessage> get otherMessages => _otherMessages.stream;

  void _flushPendingSurfaceEvents() {
    if (_disposed ||
        !_surfaceMessages.hasListener ||
        _pendingSurfaceEvents.isEmpty) {
      return;
    }

    final pendingEvents = List<_PendingControllerEvent>.of(
      _pendingSurfaceEvents,
    );
    _pendingSurfaceEvents.clear();
    for (final event in pendingEvents) {
      event.deliver(_surfaceMessages);
    }
  }

  void _flushPendingOtherEvents() {
    if (_disposed ||
        !_otherMessages.hasListener ||
        _pendingOtherEvents.isEmpty) {
      return;
    }

    final pendingEvents = List<_PendingControllerEvent>.of(_pendingOtherEvents);
    _pendingOtherEvents.clear();
    for (final event in pendingEvents) {
      event.deliver(_otherMessages);
    }
  }

  void _emitSurfaceMessage(RemotePluginMessage message) {
    if (_disposed) {
      return;
    }
    if (_surfaceMessages.hasListener) {
      _surfaceMessages.add(message);
      return;
    }
    _pendingSurfaceEvents.add(_PendingControllerMessage(message));
  }

  void _emitOtherMessage(RemotePluginMessage message) {
    if (_disposed) {
      return;
    }
    if (_otherMessages.hasListener) {
      _otherMessages.add(message);
      return;
    }
    _pendingOtherEvents.add(_PendingControllerMessage(message));
  }

  void _emitSurfaceError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    if (_surfaceMessages.hasListener) {
      _surfaceMessages.addError(error, stackTrace);
      return;
    }
    _pendingSurfaceEvents.add(_PendingControllerError(error, stackTrace));
  }

  void _emitOtherError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    if (_otherMessages.hasListener) {
      _otherMessages.addError(error, stackTrace);
      return;
    }
    _pendingOtherEvents.add(_PendingControllerError(error, stackTrace));
  }

  /// Disposes the controller subscription without closing the underlying session.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _pendingSurfaceEvents.clear();
    _pendingOtherEvents.clear();
    await _subscription?.cancel();
    await _surfaceMessages.close();
    await _otherMessages.close();
  }
}

sealed class _PendingControllerEvent {
  const _PendingControllerEvent();

  void deliver(StreamController<RemotePluginMessage> controller);
}

final class _PendingControllerMessage extends _PendingControllerEvent {
  const _PendingControllerMessage(this.message);

  final RemotePluginMessage message;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.add(message);
  }
}

final class _PendingControllerError extends _PendingControllerEvent {
  const _PendingControllerError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.addError(error, stackTrace);
  }
}

bool _isSurfaceMessage(RemotePluginMessage message) {
  return switch (message) {
    RemotePluginSurfaceOpen() ||
    RemotePluginSurfaceResize() ||
    RemotePluginFrame() ||
    RemotePluginSurfaceClose() => true,
    _ => false,
  };
}
