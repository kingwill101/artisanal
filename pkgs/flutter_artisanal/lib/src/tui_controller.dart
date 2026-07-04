import 'dart:async';

import 'package:artisanal/hosts.dart'
    show BackendTerminal, EmbeddedTerminalBackend, ProgramHost, ProgramOptions, TerminalDimensions;
import 'package:artisanal/runtime.dart' show Model, runProgram;
import 'package:artisanal/tui.dart' show Msg, ProgramInterceptor, TuiRendererOptions;
import 'package:flutter/widgets.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

import 'tui_renderer.dart';

final class _SendBridgeInterceptor extends ProgramInterceptor {
  _SendBridgeInterceptor();

  void Function(Msg msg)? send;

  @override
  void onStart(void Function(Msg msg) send) {
    this.send = send;
  }
}

class TuiController<M extends Model> {
  TuiController({
    required M model,
    this.options = const ProgramOptions(),
    this.rendererOptions,
  }) : _model = model;

  final M _model;
  final ProgramOptions options;
  final TuiRendererOptions? rendererOptions;

  M get model => _model;

  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();
  final StreamController<TerminalDimensions> _resizeController =
      StreamController<TerminalDimensions>.broadcast();
  final StreamController<void> _shutdownController =
       StreamController<void>.broadcast();

  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);

  late final EmbeddedTerminalBackend _backend;
  late final FlutterTerminalRenderer _renderer;
  late final ProgramHost _host;

  late final _SendBridgeInterceptor _sendBridge;

  uv.Buffer? _buffer;
  bool _started = false;
  bool _disposed = false;
  Future<void>? _programFuture;

  uv.Buffer? get buffer => _buffer;
  Listenable get repaint => _repaintNotifier;
  Future<void>? get done => _programFuture;

  void send(Msg msg) {
    if (!_disposed) {
      _sendBridge.send?.call(msg);
    }
  }

  Future<void> start() async {
    if (_started || _disposed) {
      throw StateError('TuiController has already been started or disposed');
    }
    _started = true;

    _sendBridge = _SendBridgeInterceptor();

    _backend = EmbeddedTerminalBackend(
      output: (_) {},
      inputStream: _inputController.stream,
      resizeStream: _resizeController.stream,
      shutdownStream: _shutdownController.stream,
      initialSize: const (width: 80, height: 24),
    );

    final backendTerminal = BackendTerminal(_backend);

    _renderer = FlutterTerminalRenderer(
      terminal: backendTerminal,
      options: rendererOptions ?? const TuiRendererOptions(),
      onFlush: (uv.Buffer buf) {
        if (!_disposed) {
          _buffer = buf;
          _repaintNotifier.value++;
        }
      },
    );

    _host = ProgramHost.backend(_backend);

    _programFuture = runProgram(
      _model,
      options: options.withInterceptor(_sendBridge),
      host: _host,
      renderer: _renderer,
    );
  }

  void addInput(List<int> bytes) {
    if (!_disposed) {
      _backend.addInput(bytes);
    }
  }

  void resize(int width, int height) {
    if (!_disposed) {
      _backend.notifySizeChanged((width: width, height: height));
    }
  }

  void requestShutdown() {
    if (!_disposed) {
      _backend.requestShutdown();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    requestShutdown();
    await _inputController.close();
    await _resizeController.close();
    await _shutdownController.close();
    _repaintNotifier.dispose();
  }
}
