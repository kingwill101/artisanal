/// Stable protocol entrypoint for out-of-process Artisanal plugins.
///
/// Prefer this library when you want the supported remote-plugin wire surface
/// for plugin host processes, guest plugin processes, schema validation, and
/// future replay/compositor integrations.
///
/// For host-owned capabilities, prefer the generic
/// `plugin.service.request` / `host.service.response` envelope plus
/// [RemotePluginGenericHostService] and [RemotePluginGuestServices]. The older
/// typed per-service request/response messages remain available for
/// backward-compatible hosts and guests.
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
export 'src/plugins/remote_surface_clipboard_service.dart'
    show
        RemotePluginClipboardReader,
        RemotePluginClipboardWriter,
        RemotePluginClipboardHostService;
export 'src/plugins/remote_surface_generic_service.dart'
    show
        RemotePluginGenericServiceCatalog,
        RemotePluginGenericServiceHandler,
        RemotePluginGenericHostService;
export 'src/plugins/remote_surface_url_service.dart'
    show RemotePluginUrlOpener, RemotePluginOpenUrlHostService;
export 'src/plugins/remote_surface_notification_service.dart'
    show RemotePluginNotifier, RemotePluginNotificationHostService;
export 'src/plugins/remote_surface_file_picker_service.dart'
    show RemotePluginFilePickerHandler, RemotePluginFilePickerHostService;
export 'src/plugins/remote_surface_manifest.dart'
    show
        RemotePluginManifestPlacement,
        RemotePluginManifest,
        RemotePluginManifestSchemas,
        RemotePluginManifestValidator,
        RemotePluginManifestValidationException,
        loadRemotePluginManifest,
        loadRemotePluginManifests;
export 'src/plugins/remote_surface_controller.dart'
    show RemotePluginSurfaceController;
export 'src/plugins/remote_surface_drawable.dart'
    show RemotePluginSurfaceDrawable;
export 'src/plugins/remote_surface_host_connection.dart'
    show RemotePluginHostConnection;
export 'src/plugins/remote_surface_layers.dart'
    show
        RemotePluginSurfacePlacement,
        RemotePluginResolvedSurfacePlacement,
        RemotePluginSurfaceHit,
        resolveRemotePluginSurfacePlacements,
        hitTestRemotePluginSurface,
        buildRemotePluginSurfaceLayers;
export 'src/plugins/remote_surface_guest_session.dart'
    show RemotePluginGuestSession;
export 'src/plugins/remote_surface_guest_services.dart'
    show RemotePluginGuestServices, RemotePluginServiceException;
export 'src/plugins/remote_surface_input_router.dart'
    show RemotePluginSurfaceMessageSender, RemotePluginSurfaceInputRouter;
export 'src/plugins/remote_surface_workspace.dart' show RemotePluginWorkspace;
export 'src/plugins/remote_surface_session.dart' show RemotePluginSession;
export 'src/plugins/remote_surface_process.dart' show RemotePluginProcess;
export 'src/plugins/remote_surface_state.dart'
    show
        RemotePluginSurfaceCell,
        RemotePluginSurfaceState,
        RemotePluginSurfaceStore;
