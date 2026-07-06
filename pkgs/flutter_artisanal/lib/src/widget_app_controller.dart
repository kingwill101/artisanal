import 'dart:async';

import 'package:artisanal/tui.dart' show ProgramOptions, Msg;
import 'package:artisanal/tui.dart' show TuiRendererOptions;
import 'package:flutter/widgets.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

import 'package:artisanal_widgets/app.dart'
    show
        ArtisanalApp,
        WidgetApp,
        defaultWidgetProgramOptions;
import 'package:artisanal_widgets/widgets.dart' show ImageAutoMode;
import 'tui_controller.dart';

T _configureImageAutoMode<T extends WidgetApp>(
  T app, {
  ImageAutoMode? imageAutoMode,
}) {
  if (imageAutoMode == null) return app;
  app.imageAutoMode = imageAutoMode;
  return app;
}

Future<T> _runWithDebugCapture<T>(
  ArtisanalApp app,
  Future<T> Function() body,
) async {
  final controller = app.debugConsoleController;
  if (controller == null) return body();
  if (!app.debugConsoleCapturePrint && !app.debugConsoleCaptureErrors) {
    return body();
  }
  return controller.runZoned(
    body,
    capturePrint: app.debugConsoleCapturePrint,
    captureErrors: app.debugConsoleCaptureErrors,
  );
}

class WidgetAppBinding {
  WidgetAppBinding({
    required WidgetApp app,
    this.options,
    this.rendererOptions,
    ImageAutoMode? imageAutoMode,
  }) : _controller = TuiController<WidgetApp>(
          model: _configureImageAutoMode(
            app,
            imageAutoMode: imageAutoMode,
          ),
          options: options ?? defaultWidgetProgramOptions,
          rendererOptions: rendererOptions,
        );

  final TuiController<WidgetApp> _controller;
  final ProgramOptions? options;
  final TuiRendererOptions? rendererOptions;

  Future<void> start() => _controller.start();
  void addInput(List<int> bytes) => _controller.addInput(bytes);
  void resize(int width, int height) => _controller.resize(width, height);
  void requestShutdown() => _controller.requestShutdown();
  void send(Msg msg) => _controller.send(msg);
  Future<void> dispose() => _controller.dispose();

  uv.Buffer? get buffer => _controller.buffer;
  Listenable get repaint => _controller.repaint;
  Future<void>? get done => _controller.done;
}

class ArtisanalAppBinding {
  ArtisanalAppBinding({
    required ArtisanalApp app,
    this.options,
    this.rendererOptions,
    ImageAutoMode? imageAutoMode,
  }) : _controller = TuiController<ArtisanalApp>(
          model: _configureImageAutoMode(
            app,
            imageAutoMode: imageAutoMode,
          ),
          options: _resolveOptions(
            app,
            options,
          ),
          rendererOptions: rendererOptions,
        );

  final TuiController<ArtisanalApp> _controller;
  final ProgramOptions? options;
  final TuiRendererOptions? rendererOptions;

  static ProgramOptions _resolveOptions(
    ArtisanalApp app,
    ProgramOptions? options,
  ) {
    final base = options ?? defaultWidgetProgramOptions;
    return base.copyWith(startupTitle: options?.startupTitle ?? app.title);
  }

  Future<void> start() => _runWithDebugCapture(
        _controller.model,
        _controller.start,
      );
  void addInput(List<int> bytes) => _controller.addInput(bytes);
  void resize(int width, int height) => _controller.resize(width, height);
  void requestShutdown() => _controller.requestShutdown();
  void send(Msg msg) => _controller.send(msg);
  Future<void> dispose() => _controller.dispose();

  ArtisanalApp get app => _controller.model;
  uv.Buffer? get buffer => _controller.buffer;
  Listenable get repaint => _controller.repaint;
  Future<void>? get done => _controller.done;
}
