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
export 'package:artisanal/src/plugins/core_exports.dart';
export 'package:artisanal/src/plugins/host_exports.dart';
