# Remote Plugin Surfaces

`package:artisanal/plugins.dart` provides the supported out-of-process plugin
surface for remote-rendered plugins.

## Architecture

The current model is host-rendered composition with plugin-rendered content:

- The host normally launches a plugin process through
  `RemotePluginHostConnection.startProcess(...)`,
  `RemotePluginHostConnection.startManifest(...)`, or
  `RemotePluginHostConnection.startManifestFile(...)`
- The plugin process binds stdin/stdout with `RemotePluginGuestSession`
- Plugin UI is described as remote surfaces plus sparse frame cells
- The bundled host connection binds `RemotePluginSurfaceController` for
  surface lifecycle/state and can route focus/mouse/key input through
  `RemotePluginSurfaceInputRouter`

## Host-Owned Services

Host-owned capabilities such as clipboard, URL opening, notifications, and
file picking should normally travel through the generic
`plugin.service.request` / `host.service.response` envelope when the host
advertises `services`:

- Hosts can optionally include explicit `RemotePluginServiceDescriptor`s in
  `host.hello`, so guests can discover which `service.method` pairs and JSON
  schemas are actually available instead of relying on the coarse capability
  flag alone
- `RemotePluginGenericServiceCatalog` lets hosts register those generic
  services once, reuse the derived descriptors in `host.hello`, and then bind
  the same handlers to a `RemotePluginHostConnection`
- `RemotePluginWorkspace` turns a manifest directory or manifest list into one
  shared multi-plugin host with reused generic services, shared surface state,
  plugin-id lookup, and an input router
- The older typed per-service request/response messages are still available as
  a compatibility fallback for older hosts and guests

## Schemas

`RemotePluginProtocolSchemas` and `RemotePluginManifestSchemas` expose
`json_schema_builder` schemas for the full message protocol, per-message
envelopes, and manifest files so non-Dart tooling can validate the same wire
format the host and guest libraries use.

## Running the Demos

End-to-end reference demo (launches the matching guest process automatically):

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_host_demo.dart
```

Full multi-plugin workspace example (discovers manifests, launches several
plugin processes, routes focus/input across composed surfaces):

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart
```

Dump the current JSON schemas:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart --manifest
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart --message-type=plugin.service.request
dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart --built-in-services
```
