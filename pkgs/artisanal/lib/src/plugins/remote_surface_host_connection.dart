import 'dart:io' as io;

import 'remote_surface_controller.dart';
import 'remote_surface_process.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_session.dart';
import 'remote_surface_state.dart';

/// Bundled host-side connection to one out-of-process remote plugin.
final class RemotePluginHostConnection {
  RemotePluginHostConnection._({
    required this.process,
    required this.session,
    required this.controller,
  });

  /// Starts a plugin process, completes the hello handshake, and binds its
  /// surface traffic into a host-side controller.
  static Future<RemotePluginHostConnection> startProcess(
    String executable,
    List<String> arguments, {
    required RemotePluginHostHello hostHello,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
    RemotePluginSurfaceStore? surfaces,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final process = await RemotePluginProcess.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      mode: mode,
      validator: validator,
    );

    try {
      final session = await process.connect(
        hostHello: hostHello,
        timeout: timeout,
      );
      final controller = RemotePluginSurfaceController.bind(
        session,
        surfaces: surfaces,
      );
      return RemotePluginHostConnection._(
        process: process,
        session: session,
        controller: controller,
      );
    } catch (_) {
      await process.dispose(kill: true);
      rethrow;
    }
  }

  final RemotePluginProcess process;
  final RemotePluginSession session;
  final RemotePluginSurfaceController controller;

  RemotePluginHello get pluginHello => session.pluginHello;
  RemotePluginSurfaceStore get surfaces => controller.surfaces;
  Stream<RemotePluginMessage> get surfaceMessages => controller.surfaceMessages;
  Stream<RemotePluginMessage> get otherMessages => controller.otherMessages;

  /// Sends one host message to the plugin.
  Future<void> send(RemotePluginMessage message) => session.send(message);

  /// Disposes controller, session, and process resources.
  Future<void> dispose({
    bool kill = false,
    io.ProcessSignal signal = io.ProcessSignal.sigterm,
  }) async {
    await controller.dispose();
    await session.dispose();
    await process.dispose(kill: kill, signal: signal);
  }
}
