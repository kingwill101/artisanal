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
