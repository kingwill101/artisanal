# Connect remote UI plugins

Remote UI plugins run outside the host process and send rendered terminal cells
back over stdin and stdout. Use them when a plugin needs its own process or
language runtime while the host keeps control of layout, focus, and input.

The API is exported by `package:artisanal/artisanal.dart`.

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

---

## Examples

### 1. Basic Host — Launch a Plugin Process

The host launches a guest executable, waits for it to open a surface, then
renders the received cell state with a UV canvas.

```dart
// example/tui/remote_plugin_host_demo.dart
import 'dart:io' as io;
import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/uv.dart' as uv;

const _surfaceId = 'demo.panel';

Future<void> main() async {
  final connection = await plugins.RemotePluginHostConnection.startProcess(
    io.Platform.resolvedExecutable,
    ['path/to/remote_plugin_guest_demo.dart'],
    hostHello: const plugins.RemotePluginHostHello(
      hostName: 'artisanal',
      hostVersion: '0.2.0',
      capabilities: ['surfaces'],
    ),
    timeout: const Duration(seconds: 15),
  );

  try {
    // Send focus to the plugin's surface
    await connection.send(
      const plugins.RemotePluginFocusInput(surfaceId: _surfaceId),
    );

    // Wait for all surface messages to complete
    await connection.surfaceMessages.drain<void>();

    // Retrieve and render the surface
    final surface = connection.surfaces[_surfaceId]!;
    final canvas = uv.Canvas(surface.width, surface.height);
    canvas.compose(plugins.RemotePluginSurfaceDrawable(surface));
    io.stdout.writeln(canvas.render());
  } finally {
    await connection.dispose(kill: true);
  }
}
```

---

### 2. Basic Guest — Open a Surface and Render Frames

The guest binds stdin/stdout, opens a named surface, and pushes sparse cell
frames back to the host.

```dart
// example/tui/remote_plugin_guest_demo.dart
import 'package:artisanal/artisanal.dart' as plugins;

const _surfaceId = 'demo.panel';
const _width = 28;
const _height = 5;

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'remote-surface-demo',
      pluginVersion: '0.1.0',
      displayName: 'Remote Surface Demo',
      capabilities: ['surfaces'],
    ),
  );

  try {
    // Open the surface
    await session.send(const plugins.RemotePluginSurfaceOpen(
      surfaceId: _surfaceId,
      kind: plugins.RemotePluginSurfaceKind.panel,
      width: _width,
      height: _height,
      title: 'Demo Panel',
      slot: 'main',
    ));

    // Push an initial frame
    await session.send(_buildFrame(
      hostName: session.hostHello.hostName,
      status: 'ready',
    ));

    // React to host messages
    await for (final message in session.messages) {
      switch (message) {
        case plugins.RemotePluginFocusInput(surfaceId: _surfaceId):
          await session.send(_buildFrame(
            hostName: session.hostHello.hostName,
            status: 'focused',
          ));
          return;
        case plugins.RemotePluginBlurInput(surfaceId: _surfaceId):
          await session.send(_buildFrame(
            hostName: session.hostHello.hostName,
            status: 'blurred',
          ));
        default:
          continue;
      }
    }
  } finally {
    await session.dispose();
  }
}

plugins.RemotePluginFrame _buildFrame({
  required String hostName,
  required String status,
}) {
  final lines = [
    'Remote Plugin Demo',
    'Host: $hostName',
    'State: $status',
    'Surface: $_surfaceId',
  ];

  final cells = <plugins.RemotePluginFrameCell>[];
  for (var row = 0; row < lines.length; row++) {
    final line = lines[row];
    for (var col = 0; col < line.length && col < _width; col++) {
      cells.add(plugins.RemotePluginFrameCell(
        column: col,
        row: row,
        symbol: line[col],
        // Highlight the title row in light blue
        foreground: row == 0 ? '#7dd3fc' : null,
      ));
    }
  }

  return plugins.RemotePluginFrame(
    surfaceId: _surfaceId,
    width: _width,
    height: _height,
    cells: cells,
    cursor: const plugins.RemotePluginCursor(column: 7, row: 2),
  );
}
```

---

### 3. Generic Host Service (Custom RPC)

Register a custom `host.ping` RPC with JSON schema validation. The guest
calls it via the generic service envelope.

```dart
// Host side — example/tui/remote_plugin_generic_service_host_demo.dart
import 'dart:io' as io;
import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/uv.dart' as uv;
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

Future<void> main() async {
  // Define request/result schemas
  final paramsSchema = jsb.S.object(
    required: const ['value'],
    properties: {'value': jsb.S.string(minLength: 1)},
    additionalProperties: false,
  );
  final resultSchema = jsb.S.object(
    required: const ['reply'],
    properties: {'reply': jsb.S.string(minLength: 1)},
    additionalProperties: false,
  );

  // Build a service catalog and register the handler
  final catalog = plugins.RemotePluginGenericServiceCatalog()
    ..register(
      'host',
      'ping',
      (request) => {'reply': 'pong ${request.params['value']}'},
      description: 'Reply to a plugin ping with a tagged pong payload.',
      paramsSchema: paramsSchema,
      resultSchema: resultSchema,
    );

  final connection = await plugins.RemotePluginHostConnection.startProcess(
    io.Platform.resolvedExecutable,
    ['path/to/remote_plugin_generic_service_guest_demo.dart'],
    hostHello: const plugins.RemotePluginHostHello(
      hostName: 'artisanal',
      hostVersion: '0.2.0',
      capabilities: ['surfaces', 'services'],
    ),
    genericServices: catalog,
    timeout: const Duration(seconds: 15),
  );

  try {
    await connection.surfaceMessages.drain<void>();
    final surface = connection.surfaces['generic.panel']!;
    io.stdout.writeln('Service result rendered on surface:');
    final canvas = uv.Canvas(surface.width, surface.height);
    canvas.compose(plugins.RemotePluginSurfaceDrawable(surface));
    io.stdout.writeln(canvas.render());
  } finally {
    await connection.dispose(kill: true);
  }
}
```

```dart
// Guest side — example/tui/remote_plugin_generic_service_guest_demo.dart
import 'package:artisanal/artisanal.dart' as plugins;

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'remote-generic-service-demo',
      pluginVersion: '0.1.0',
      displayName: 'Remote Generic Service Demo',
      capabilities: ['surfaces', 'services'],
    ),
  );

  try {
    await session.send(const plugins.RemotePluginSurfaceOpen(
      surfaceId: 'generic.panel',
      kind: plugins.RemotePluginSurfaceKind.panel,
      width: 38,
      height: 6,
      title: 'Generic Service Panel',
      slot: 'main',
    ));

    // Call the host.ping generic service
    try {
      final result = await session.services.call(
        'host', 'ping',
        params: const {'value': 'demo'},
      );
      // result['reply'] == 'pong demo'
    } on plugins.RemotePluginServiceException catch (error) {
      // Handle service errors
    }
  } finally {
    await session.dispose();
  }
}
```

---

### 4. Built-In Services (Clipboard, URL, Notifications, File Picker)

Use `RemotePluginGenericServiceCatalog.builtIns(...)` to wire all four
built-in host-owned services in one call.

```dart
// Host side
final catalog = plugins.RemotePluginGenericServiceCatalog.builtIns(
  readClipboard: (_) => 'clipboard text',
  openUrl: (req) { /* launch browser */ },
  notify: (req) { /* show OS notification */ },
  pickPaths: (_) => const ['/tmp/selected.txt'],
);

final connection = await plugins.RemotePluginHostConnection.startProcess(
  io.Platform.resolvedExecutable,
  ['path/to/guest.dart'],
  hostHello: plugins.RemotePluginHostHello(
    hostName: 'my-host',
    hostVersion: '1.0.0',
    capabilities: const ['surfaces', 'services'],
  ),
  genericServices: catalog,
  timeout: const Duration(seconds: 15),
);
```

```dart
// Guest side — call built-in services via RemotePluginGuestServices
final clipboardText = await session.services.readClipboard();
await session.services.openUrl('https://example.com');
await session.services.notify('Done', body: 'Task complete');
final paths = await session.services.pickPaths(title: 'Open file');
```

---

### 5. Multi-Plugin Workspace

`RemotePluginWorkspace` discovers plugin manifests from a directory, launches
all plugin processes, and composes their surfaces into one UV canvas. Input
routing (focus, mouse, keyboard) is handled by the built-in
`RemotePluginSurfaceInputRouter`.

```dart
// example/tui/remote_plugin_workspace/host/main.dart (condensed)
import 'dart:io' as io;
import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/tui.dart';
import 'package:artisanal/uv.dart' as uv;

Future<void> main() async {
  // Share built-in host services across all plugin connections
  final catalog = plugins.RemotePluginGenericServiceCatalog.builtIns(
    readClipboard: (_) => 'workspace clipboard',
    openUrl: (_) {},
    notify: (_) {},
    pickPaths: (_) => const ['/tmp/workspace.txt'],
  );

  // Discover manifests and launch all plugins
  final workspace = await plugins.RemotePluginWorkspace.startManifestDirectory(
    'pkgs/artisanal/example/tui/remote_plugin_workspace/plugins',
    executable: io.Platform.resolvedExecutable,
    hostHello: plugins.RemotePluginHostHello(
      hostName: 'artisanal',
      hostVersion: '0.2.0',
      capabilities: const ['surfaces'],
    ),
    genericServices: catalog,
    timeout: const Duration(seconds: 30),
  );

  // Focus the primary plugin
  await workspace.focusPlugin('overview');

  // Compose all plugin surfaces into one UV canvas using their manifest placements
  final layers = plugins.buildRemotePluginSurfaceLayers(
    workspace.surfaces,
    placements: workspace.manifests.map(
      (m) => m.placement.toSurfacePlacement(),
    ),
  );
  final output = uv.Compositor(layers).render();
  io.stdout.writeln(output);

  await workspace.dispose(kill: true);
}
```

For the full interactive TUI version (with mouse, keyboard, and live surface
updates), see
`pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart`.

---

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

---

## Widget Slot Registry

The widget slot registry extends the remote plugin model to in-process widget
contributions. While `RemotePluginHostConnection` manages out-of-process plugin
surfaces, `SlotRegistry` manages typed in-process widget builders that can be
mixed with remote surfaces in the same UI region.

### Core Types

- **`SlotRegistry<TSlot, TData>`** — holds ordered widget contributions keyed
  by a typed slot value. Contributions are resolved in
  `(order, registrationOrder, pluginId)` order, ensuring deterministic output.
- **`SlotPlugin<TSlot, TData>`** — declarative registration bundle
  (`pluginId` + a map of slot → `SlotPluginContribution`).
- **`SlotScope<TSlot, TData>`** — `InheritedWidget` that exposes a registry to
  descendants and triggers rebuilds when registrations change.
- **`SlotBuilder<TSlot, TData>`** — widget that resolves a named slot and
  renders its contributions (all stacked, or first-only).
- **`SlotPluginMount<TSlot, TData>`** — declaratively mounts a `SlotPlugin`
  into the nearest `SlotScope`; auto-unregisters on dispose.
- **`SlotRegion<TSlot, TData>`** — combines local `SlotRegistry` contributions
  with remote `RemotePluginSlotEntry` surfaces for mixed local/remote panels.
- **`RemotePluginSurfaceView`** — renders a `RemotePluginSurfaceState` as a
  text widget inside the widget tree.

### Connecting Remote Surfaces to Slots

`RemotePluginSlotEntry` values (resolved from a `RemotePluginWorkspace`) can
be passed directly to `SlotRegion` so remote plugin surfaces appear alongside
in-process contributions:

```dart
final remoteEntries = resolveRemotePluginSlotEntries(
  workspace.surfaces,
  'sidebar',  // slot name
);

SlotRegion<AppSlot, AppData>(
  slot: AppSlot.sidebar,
  data: currentData,
  remoteEntries: remoteEntries,
  // local contributions from SlotRegistry via SlotScope ancestor
)
```

The `RemotePluginSlotInputRouter` (from `package:artisanal/artisanal.dart`)
routes keyboard, mouse, and focus input to the correct remote surface when
multiple remote slots are active.

See [widgets.md](widgets.md#widget-slot-registry) for the full widget-layer API.
```
