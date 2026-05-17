/// Stable protocol entrypoint for out-of-process Artisanal plugins.
///
/// Web stub — io-dependent exports (host connection, process, manifest,
/// workspace, and host-side services) are omitted since they rely on
/// `dart:io`.
library;

export 'package:json_schema_builder/json_schema_builder.dart'
    show Schema, SchemaValidation, ValidationError;
export 'src/plugins/remote_surface_protocol.dart'
    show
        remotePluginProtocolVersion,
        RemotePluginMessageType,
        RemotePluginSurfaceKind,
        RemotePluginCursorShape,
        RemotePluginMouseAction,
        RemotePluginMouseButton,
        RemotePluginNotificationLevel,
        RemotePluginFilePickerKind,
        RemotePluginServiceDescriptor,
        RemotePluginAnchorRect,
        RemotePluginCellAttributes,
        RemotePluginFrameCell,
        RemotePluginCursor,
        RemotePluginMessage,
        RemotePluginHostHello,
        RemotePluginHello,
        RemotePluginSurfaceOpen,
        RemotePluginSurfaceResize,
        RemotePluginSurfaceClose,
        RemotePluginFrame,
        RemotePluginClipboardReadRequest,
        RemotePluginClipboardWriteRequest,
        RemotePluginOpenUrlRequest,
        RemotePluginNotificationRequest,
        RemotePluginFilePickerRequest,
        RemotePluginServiceRequest,
        RemotePluginKeyInput,
        RemotePluginMouseInput,
        RemotePluginFocusInput,
        RemotePluginBlurInput,
        RemotePluginClipboardReadResponse,
        RemotePluginClipboardWriteResponse,
        RemotePluginOpenUrlResponse,
        RemotePluginNotificationResponse,
        RemotePluginFilePickerResponse,
        RemotePluginServiceResponse,
        RemotePluginProtocolSchemas,
        RemotePluginProtocolValidator,
        RemotePluginProtocolValidationException;
export 'src/plugins/remote_surface_transport.dart'
    show RemotePluginJsonTransport;
export 'src/plugins/remote_surface_channel.dart' show RemotePluginJsonChannel;
export 'src/plugins/remote_surface_controller.dart'
    show RemotePluginSurfaceController;
export 'src/plugins/remote_surface_drawable.dart'
    show RemotePluginSurfaceDrawable;
export 'src/plugins/remote_surface_layers.dart'
    show
        RemotePluginSurfacePlacement,
        RemotePluginResolvedSurfacePlacement,
        RemotePluginSurfaceHit,
        resolveRemotePluginSurfacePlacements,
        hitTestRemotePluginSurface,
        buildRemotePluginSurfaceLayers;
export 'src/plugins/remote_surface_slots.dart'
    show
        RemotePluginSlotEntry,
        resolveRemotePluginSlotEntries,
        groupRemotePluginSlotEntries;
export 'src/plugins/remote_surface_slot_input.dart'
    show RemotePluginSlotHit, RemotePluginSlotInputRouter;
export 'src/plugins/remote_surface_input_router.dart'
    show RemotePluginSurfaceMessageSender, RemotePluginSurfaceInputRouter;
export 'src/plugins/remote_surface_session.dart' show RemotePluginSession;
export 'src/plugins/remote_surface_state.dart'
    show
        RemotePluginSurfaceCell,
        RemotePluginSurfaceState,
        RemotePluginSurfaceStore;

import 'dart:async';

import 'src/plugins/remote_surface_channel.dart' as channel;
import 'src/plugins/remote_surface_protocol.dart' as protocol;
import 'src/plugins/remote_surface_session.dart' as session;
import 'src/plugins/remote_surface_state.dart' as state;
import 'src/plugins/remote_surface_slots.dart' as slots;
import 'src/plugins/remote_surface_slot_input.dart' as slot_input;

typedef RemotePluginClipboardReader =
    FutureOr<String> Function(
      protocol.RemotePluginClipboardReadRequest request,
    );
typedef RemotePluginClipboardWriter =
    FutureOr<void> Function(protocol.RemotePluginClipboardWriteRequest request);
typedef RemotePluginUrlOpener = FutureOr<void> Function(Uri uri);
typedef RemotePluginNotifier =
    FutureOr<void> Function(protocol.RemotePluginNotificationRequest request);
typedef RemotePluginFilePickerHandler =
    FutureOr<List<String>> Function(
      protocol.RemotePluginFilePickerRequest request,
    );
typedef RemotePluginGenericServiceHandler =
    FutureOr<Map<String, Object?>> Function(
      protocol.RemotePluginServiceRequest request,
    );

Never _unsupportedRemotePlugins() {
  throw UnsupportedError('Remote plugins are not available on this platform.');
}

final class RemotePluginServiceException implements Exception {
  RemotePluginServiceException(this.message);

  final String message;

  @override
  String toString() => 'RemotePluginServiceException: $message';
}

final class RemotePluginGuestServices {
  RemotePluginGuestServices(this.session);

  final RemotePluginGuestSession session;

  bool get supportsGenericServices => false;

  List<protocol.RemotePluginServiceDescriptor> get availableServices =>
      const <protocol.RemotePluginServiceDescriptor>[];

  protocol.RemotePluginServiceDescriptor? descriptorFor(
    String service,
    String method,
  ) => null;

  bool supports(String service, String method) => false;

  Future<Map<String, Object?>> call(
    String service,
    String method, {
    Map<String, Object?> params = const <String, Object?>{},
    Duration timeout = const Duration(seconds: 5),
    Object? paramsSchema,
    Object? resultSchema,
  }) => _unsupportedRemotePlugins();

  Future<String> readClipboard({
    String selection = 'c',
    Duration timeout = const Duration(seconds: 5),
  }) => _unsupportedRemotePlugins();

  Future<void> writeClipboard(
    String text, {
    String selection = 'c',
    Duration timeout = const Duration(seconds: 5),
  }) => _unsupportedRemotePlugins();

  Future<void> openUrl(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) => _unsupportedRemotePlugins();

  Future<void> notify(
    String message, {
    String? title,
    protocol.RemotePluginNotificationLevel level =
        protocol.RemotePluginNotificationLevel.info,
    Duration timeout = const Duration(seconds: 5),
  }) => _unsupportedRemotePlugins();

  Future<List<String>> pickPaths({
    protocol.RemotePluginFilePickerKind kind =
        protocol.RemotePluginFilePickerKind.file,
    bool allowMultiple = false,
    String? title,
    String? initialPath,
    Duration timeout = const Duration(seconds: 5),
  }) => _unsupportedRemotePlugins();
}

final class RemotePluginGuestSession {
  RemotePluginGuestSession._();

  static Future<RemotePluginGuestSession> connect({
    required channel.RemotePluginJsonChannel channel,
    required protocol.RemotePluginHello pluginHello,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  static Future<RemotePluginGuestSession> bindStdio({
    required protocol.RemotePluginHello pluginHello,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  protocol.RemotePluginHostHello get hostHello => _unsupportedRemotePlugins();

  RemotePluginGuestServices get services => RemotePluginGuestServices(this);

  Stream<protocol.RemotePluginMessage> get messages =>
      const Stream<protocol.RemotePluginMessage>.empty();

  Future<void> send(protocol.RemotePluginMessage message) =>
      _unsupportedRemotePlugins();

  Future<void> dispose() => _unsupportedRemotePlugins();
}

final class RemotePluginGenericServiceCatalog {
  RemotePluginGenericServiceCatalog();

  static RemotePluginGenericServiceCatalog builtIns({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
    RemotePluginUrlOpener? openUrl,
    RemotePluginNotifier? notify,
    RemotePluginFilePickerHandler? pickPaths,
  }) => RemotePluginGenericServiceCatalog();

  void register(
    String service,
    String method,
    RemotePluginGenericServiceHandler handler, {
    String? description,
    Object? paramsSchema,
    Object? resultSchema,
  }) {}

  void unregister(String service, String method) {}

  List<protocol.RemotePluginServiceDescriptor> get serviceDescriptors =>
      const <protocol.RemotePluginServiceDescriptor>[];

  RemotePluginGenericHostService bind(RemotePluginHostConnection connection) =>
      RemotePluginGenericHostService.bind(connection);

  void registerClipboard({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
  }) {}

  void registerOpenUrl({RemotePluginUrlOpener? openUrl}) {}

  void registerNotification({RemotePluginNotifier? notify}) {}

  void registerFilePicker({RemotePluginFilePickerHandler? pickPaths}) {}

  void registerBuiltIns({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
    RemotePluginUrlOpener? openUrl,
    RemotePluginNotifier? notify,
    RemotePluginFilePickerHandler? pickPaths,
  }) {}
}

final class RemotePluginGenericHostService {
  RemotePluginGenericHostService.bind(
    RemotePluginHostConnection connection, {
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
    RemotePluginUrlOpener? openUrl,
    RemotePluginNotifier? notify,
    RemotePluginFilePickerHandler? pickPaths,
  });

  void register(
    String service,
    String method,
    RemotePluginGenericServiceHandler handler, {
    String? description,
    Object? paramsSchema,
    Object? resultSchema,
  }) {}

  List<protocol.RemotePluginServiceDescriptor> get serviceDescriptors =>
      const <protocol.RemotePluginServiceDescriptor>[];

  static List<protocol.RemotePluginServiceDescriptor>
  builtInServiceDescriptors({
    bool clipboardRead = false,
    bool clipboardWrite = false,
    bool openUrl = false,
    bool notify = false,
    bool filePicker = false,
  }) => const <protocol.RemotePluginServiceDescriptor>[];

  void unregister(String service, String method) {}

  void registerClipboard({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
  }) {}

  void registerOpenUrl({RemotePluginUrlOpener? openUrl}) {}

  void registerNotification({RemotePluginNotifier? notify}) {}

  void registerFilePicker({RemotePluginFilePickerHandler? pickPaths}) {}

  void registerBuiltIns({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
    RemotePluginUrlOpener? openUrl,
    RemotePluginNotifier? notify,
    RemotePluginFilePickerHandler? pickPaths,
  }) {}

  Future<void> dispose() => _unsupportedRemotePlugins();
}

final class RemotePluginClipboardHostService {
  RemotePluginClipboardHostService.bind(
    RemotePluginHostConnection connection, {
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
  });

  Future<void> dispose() => _unsupportedRemotePlugins();
}

final class RemotePluginOpenUrlHostService {
  RemotePluginOpenUrlHostService.bind(
    RemotePluginHostConnection connection, {
    RemotePluginUrlOpener? openUrl,
  });

  Future<void> dispose() => _unsupportedRemotePlugins();
}

final class RemotePluginNotificationHostService {
  RemotePluginNotificationHostService.bind(
    RemotePluginHostConnection connection, {
    RemotePluginNotifier? notify,
  });

  Future<void> dispose() => _unsupportedRemotePlugins();
}

final class RemotePluginFilePickerHostService {
  RemotePluginFilePickerHostService.bind(
    RemotePluginHostConnection connection, {
    RemotePluginFilePickerHandler? pickPaths,
  });

  Future<void> dispose() => _unsupportedRemotePlugins();
}

final class RemotePluginHostConnection {
  RemotePluginHostConnection._();

  static Future<RemotePluginHostConnection> startProcess(
    String executable,
    List<String> arguments, {
    required protocol.RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  static Future<RemotePluginHostConnection> startManifest(
    Object manifest, {
    required protocol.RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  static Future<RemotePluginHostConnection> startManifestFile(
    String manifestPath, {
    required protocol.RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  protocol.RemotePluginHello get pluginHello => _unsupportedRemotePlugins();

  state.RemotePluginSurfaceStore get surfaces =>
      state.RemotePluginSurfaceStore();

  Stream<protocol.RemotePluginMessage> get surfaceMessages =>
      const Stream<protocol.RemotePluginMessage>.empty();

  Stream<protocol.RemotePluginMessage> get otherMessages =>
      const Stream<protocol.RemotePluginMessage>.empty();

  Future<void> send(protocol.RemotePluginMessage message) =>
      _unsupportedRemotePlugins();

  RemotePluginClipboardHostService bindClipboardService({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
  }) => RemotePluginClipboardHostService.bind(
    this,
    readClipboard: readClipboard,
    writeClipboard: writeClipboard,
  );

  RemotePluginOpenUrlHostService bindOpenUrlService({
    RemotePluginUrlOpener? openUrl,
  }) => RemotePluginOpenUrlHostService.bind(this, openUrl: openUrl);

  RemotePluginNotificationHostService bindNotificationService({
    RemotePluginNotifier? notify,
  }) => RemotePluginNotificationHostService.bind(this, notify: notify);

  RemotePluginFilePickerHostService bindFilePickerService({
    RemotePluginFilePickerHandler? pickPaths,
  }) => RemotePluginFilePickerHostService.bind(this, pickPaths: pickPaths);

  RemotePluginGenericHostService bindGenericService({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
    RemotePluginUrlOpener? openUrl,
    RemotePluginNotifier? notify,
    RemotePluginFilePickerHandler? pickPaths,
  }) => RemotePluginGenericHostService.bind(
    this,
    readClipboard: readClipboard,
    writeClipboard: writeClipboard,
    openUrl: openUrl,
    notify: notify,
    pickPaths: pickPaths,
  );

  RemotePluginGenericHostService bindGenericServiceCatalog(
    RemotePluginGenericServiceCatalog catalog,
  ) => catalog.bind(this);

  Future<void> dispose({bool kill = false}) => _unsupportedRemotePlugins();
}

final class RemotePluginManifestSchemas {
  RemotePluginManifestSchemas._();

  static Object get placement => const <String, Object?>{};
  static Object get manifest => const <String, Object?>{};
}

final class RemotePluginManifestValidator {
  const RemotePluginManifestValidator();

  Future<List<Object>> validateJson(Map<String, Object?> json) async =>
      const <Object>[];

  Future<List<Object>> validateManifest(Object manifest) async =>
      const <Object>[];

  Future<void> validateJsonOrThrow(Map<String, Object?> json) async {}
}

final class RemotePluginManifestValidationException implements Exception {
  RemotePluginManifestValidationException(this.errors);

  final List<Object> errors;
}

Future<Object> loadRemotePluginManifest(
  String manifestPath, {
  RemotePluginManifestValidator validator =
      const RemotePluginManifestValidator(),
}) => _unsupportedRemotePlugins();

Future<List<Object>> loadRemotePluginManifests(
  String directoryPath, {
  RemotePluginManifestValidator validator =
      const RemotePluginManifestValidator(),
}) => _unsupportedRemotePlugins();

final class RemotePluginProcess {
  RemotePluginProcess._();

  static Future<RemotePluginProcess> start(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  Stream<protocol.RemotePluginMessage> get messages =>
      const Stream<protocol.RemotePluginMessage>.empty();

  Future<int> get exitCode => _unsupportedRemotePlugins();

  Future<void> send(protocol.RemotePluginMessage message) =>
      _unsupportedRemotePlugins();

  Future<session.RemotePluginSession> connect({
    required protocol.RemotePluginHostHello hostHello,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  Future<void> dispose({bool kill = false}) => _unsupportedRemotePlugins();
}

final class RemotePluginWorkspace {
  RemotePluginWorkspace._();

  static Future<RemotePluginWorkspace> startManifestDirectory(
    String directoryPath, {
    required protocol.RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  static Future<RemotePluginWorkspace> startManifests(
    List<Object> manifests, {
    required protocol.RemotePluginHostHello hostHello,
    RemotePluginGenericServiceCatalog? genericServices,
    Duration timeout = const Duration(seconds: 10),
  }) => _unsupportedRemotePlugins();

  state.RemotePluginSurfaceStore get surfaces =>
      state.RemotePluginSurfaceStore();

  Object? manifestForPlugin(String pluginId) => null;

  String? pluginIdForSurface(String surfaceId) => null;

  List<slots.RemotePluginSlotEntry> slotEntriesFor(String slot) =>
      const <slots.RemotePluginSlotEntry>[];

  slot_input.RemotePluginSlotInputRouter slotInputRouterFor(String slot) =>
      _unsupportedRemotePlugins();

  Future<void> focusPlugin(String? pluginId) => _unsupportedRemotePlugins();

  Future<void> dispose({bool kill = false}) => _unsupportedRemotePlugins();
}
