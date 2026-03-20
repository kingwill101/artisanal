import 'dart:io' as io;

import 'remote_surface_clipboard_service.dart';
import 'remote_surface_controller.dart';
import 'remote_surface_file_picker_service.dart';
import 'remote_surface_generic_service.dart';
import 'remote_surface_manifest.dart';
import 'remote_surface_notification_service.dart';
import 'remote_surface_process.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_session.dart';
import 'remote_surface_state.dart';
import 'remote_surface_url_service.dart';

/// Bundled host-side connection to one out-of-process remote plugin.
final class RemotePluginHostConnection {
  RemotePluginHostConnection._({
    required this.process,
    required this.session,
    required this.controller,
    List<RemotePluginGenericHostService> managedGenericServices =
        const <RemotePluginGenericHostService>[],
  }) : _managedGenericServices = managedGenericServices;

  /// Starts a plugin process, completes the hello handshake, and binds its
  /// surface traffic into a host-side controller.
  static Future<RemotePluginHostConnection> startProcess(
    String executable,
    List<String> arguments, {
    required RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
    RemotePluginSurfaceStore? surfaces,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final effectiveHostHello = _hostHelloWithGenericServices(
      hostHello,
      genericServices,
    );
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
        hostHello: effectiveHostHello,
        timeout: timeout,
      );
      final controller = RemotePluginSurfaceController.bind(
        session,
        surfaces: surfaces,
      );
      final managedGenericServices = <RemotePluginGenericHostService>[];
      final connection = RemotePluginHostConnection._(
        process: process,
        session: session,
        controller: controller,
        managedGenericServices: managedGenericServices,
      );
      if (genericServices != null) {
        managedGenericServices.add(genericServices.bind(connection));
      }
      return connection;
    } catch (_) {
      await process.dispose(kill: true);
      rethrow;
    }
  }

  /// Starts a plugin process described by a validated manifest.
  static Future<RemotePluginHostConnection> startManifest(
    RemotePluginManifest manifest, {
    required String executable,
    required RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
    RemotePluginSurfaceStore? surfaces,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return startProcess(
      executable,
      <String>[
        manifest.resolveEntrypoint(
          currentWorkingDirectory: workingDirectory,
        ),
      ],
      hostHello: hostHello,
      genericServices: genericServices,
      workingDirectory:
          workingDirectory ?? _manifestWorkingDirectory(manifest.manifestPath),
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      mode: mode,
      validator: validator,
      surfaces: surfaces,
      timeout: timeout,
    );
  }

  final RemotePluginProcess process;
  final RemotePluginSession session;
  final RemotePluginSurfaceController controller;
  final List<RemotePluginGenericHostService> _managedGenericServices;

  RemotePluginHello get pluginHello => session.pluginHello;
  RemotePluginSurfaceStore get surfaces => controller.surfaces;
  Stream<RemotePluginMessage> get surfaceMessages => controller.surfaceMessages;
  Stream<RemotePluginMessage> get otherMessages => controller.otherMessages;

  /// Sends one host message to the plugin.
  Future<void> send(RemotePluginMessage message) => session.send(message);

  /// Binds a clipboard request/response service to this plugin connection.
  RemotePluginClipboardHostService bindClipboardService({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
  }) {
    return RemotePluginClipboardHostService.bind(
      this,
      readClipboard: readClipboard,
      writeClipboard: writeClipboard,
    );
  }

  /// Binds a URL-open request/response service to this plugin connection.
  RemotePluginOpenUrlHostService bindOpenUrlService({
    RemotePluginUrlOpener? openUrl,
  }) {
    return RemotePluginOpenUrlHostService.bind(this, openUrl: openUrl);
  }

  /// Binds a notification request/response service to this plugin connection.
  RemotePluginNotificationHostService bindNotificationService({
    RemotePluginNotifier? notify,
  }) {
    return RemotePluginNotificationHostService.bind(this, notify: notify);
  }

  /// Binds a file picker request/response service to this plugin connection.
  RemotePluginFilePickerHostService bindFilePickerService({
    RemotePluginFilePickerHandler? pickPaths,
  }) {
    return RemotePluginFilePickerHostService.bind(this, pickPaths: pickPaths);
  }

  /// Binds a generic request/response service registry to this plugin
  /// connection.
  RemotePluginGenericHostService bindGenericService({
    Map<String, Map<String, RemotePluginGenericServiceHandler>> handlers =
        const <String, Map<String, RemotePluginGenericServiceHandler>>{},
  }) {
    return RemotePluginGenericHostService.bind(this, handlers: handlers);
  }

  /// Binds a reusable generic service catalog to this plugin connection.
  RemotePluginGenericHostService bindGenericServiceCatalog(
    RemotePluginGenericServiceCatalog catalog,
  ) {
    return catalog.bind(this);
  }

  /// Disposes controller, session, and process resources.
  Future<void> dispose({
    bool kill = false,
    io.ProcessSignal signal = io.ProcessSignal.sigterm,
  }) async {
    for (final service in _managedGenericServices) {
      await service.dispose();
    }
    await controller.dispose();
    await session.dispose();
    await process.dispose(kill: kill, signal: signal);
  }
}

RemotePluginHostHello _hostHelloWithGenericServices(
  RemotePluginHostHello hostHello,
  RemotePluginGenericServiceCatalog? genericServices,
) {
  if (genericServices == null) {
    return hostHello;
  }

  final capabilities = <String>{
    ...hostHello.capabilities,
    'services',
  }.toList(growable: false);

  final merged = <String, RemotePluginServiceDescriptor>{};
  for (final descriptor in hostHello.services) {
    merged['${descriptor.service}.${descriptor.method}'] = descriptor;
  }
  for (final descriptor in genericServices.serviceDescriptors) {
    merged['${descriptor.service}.${descriptor.method}'] = descriptor;
  }

  final services = merged.values.toList(growable: false)
    ..sort((a, b) {
      final service = a.service.compareTo(b.service);
      if (service != 0) {
        return service;
      }
      return a.method.compareTo(b.method);
    });

  return hostHello.copyWith(capabilities: capabilities, services: services);
}

String? _manifestWorkingDirectory(String? manifestPath) {
  if (manifestPath == null) {
    return null;
  }
  return io.File(manifestPath).parent.path;
}
