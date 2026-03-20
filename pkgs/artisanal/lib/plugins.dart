/// Stable protocol entrypoint for out-of-process Artisanal plugins.
///
/// Prefer this library when you want the supported remote-plugin wire surface
/// for plugin host processes, guest plugin processes, schema validation, and
/// future replay/compositor integrations.
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
        RemotePluginKeyInput,
        RemotePluginMouseInput,
        RemotePluginFocusInput,
        RemotePluginBlurInput,
        RemotePluginClipboardReadResponse,
        RemotePluginClipboardWriteResponse,
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
export 'src/plugins/remote_surface_controller.dart'
    show RemotePluginSurfaceController;
export 'src/plugins/remote_surface_drawable.dart'
    show RemotePluginSurfaceDrawable;
export 'src/plugins/remote_surface_host_connection.dart'
    show RemotePluginHostConnection;
export 'src/plugins/remote_surface_layers.dart'
    show RemotePluginSurfacePlacement, buildRemotePluginSurfaceLayers;
export 'src/plugins/remote_surface_guest_session.dart'
    show RemotePluginGuestSession;
export 'src/plugins/remote_surface_session.dart' show RemotePluginSession;
export 'src/plugins/remote_surface_process.dart' show RemotePluginProcess;
export 'src/plugins/remote_surface_state.dart'
    show
        RemotePluginSurfaceCell,
        RemotePluginSurfaceState,
        RemotePluginSurfaceStore;
