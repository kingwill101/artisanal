import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'remote_surface_channel.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_session.dart';

/// Running out-of-process plugin connected over stdio.
final class RemotePluginProcess {
  RemotePluginProcess._({
    required this.process,
    required this.channel,
    required this.stderrLines,
  });

  /// Spawns a plugin executable and binds it to a [RemotePluginJsonChannel].
  static Future<RemotePluginProcess> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
  }) async {
    final process = await io.Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      mode: mode,
    );

    final channel = RemotePluginJsonChannel(
      sendLine: (line) {
        process.stdin.write(line);
      },
      validator: validator,
    );
    channel.bindBytes(process.stdout);

    final stderrLines = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();

    return RemotePluginProcess._(
      process: process,
      channel: channel,
      stderrLines: stderrLines,
    );
  }

  final io.Process process;
  final RemotePluginJsonChannel channel;
  final Stream<String> stderrLines;

  /// Remote protocol messages received from the plugin process.
  Stream<RemotePluginMessage> get messages => channel.messages;

  /// OS process identifier.
  int get pid => process.pid;

  /// Exit code future for the underlying process.
  Future<int> get exitCode => process.exitCode;

  /// Sends a typed protocol message to the plugin.
  Future<void> send(RemotePluginMessage message) => channel.send(message);

  /// Completes the host/plugin hello handshake on top of this process channel.
  Future<RemotePluginSession> connect({
    required RemotePluginHostHello hostHello,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return RemotePluginSession.connect(
      channel: channel,
      hostHello: hostHello,
      timeout: timeout,
    );
  }

  /// Closes the stdio channel and optionally terminates the process.
  Future<void> dispose({
    bool kill = false,
    io.ProcessSignal signal = io.ProcessSignal.sigterm,
  }) async {
    await channel.dispose();
    try {
      await process.stdin.close();
    } catch (_) {
      // Ignore late-close races when the child has already exited.
    }
    if (kill) {
      process.kill(signal);
    }
  }
}
