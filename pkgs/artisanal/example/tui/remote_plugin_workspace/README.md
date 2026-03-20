# Remote Plugin Workspace

This example shows a full `artisanal` host app launching multiple
out-of-process plugins and composing their remote surfaces into one UV-backed
workspace.

The host discovers plugins from the `plugins/` directory by loading each
`*.plugin.json` manifest, validating it, and launching the manifest's
`entrypoint` relative to the manifest file.

The host passes one `RemotePluginGenericServiceCatalog` into
`RemotePluginHostConnection.startProcess(..., genericServices: ...)`, which
automatically advertises the shared `services` capability, exposes the
catalog's descriptors in `host.hello`, and binds the shared
`plugin.service.request` / `host.service.response` lane for clipboard, URL,
notification, and file-picker RPCs.

## Run the interactive host

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart
```

Keys:

- `1` focus the overview plugin
- `2` focus the activity plugin
- `3` focus the alerts plugin
- mouse click focus the clicked plugin surface
- mouse motion routes into the hovered plugin surface
- other keys route into the focused plugin surface
- `c` in the activity plugin reads the host clipboard service
- `o` in the activity plugin calls the host URL-open service
- `n` in the activity plugin calls the host notification service
- `p` in the activity plugin calls the host file-picker service
- `r` reload the workspace
- `q` quit

## Render a one-shot snapshot

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot
```

The snapshot mode launches the same plugin workspace, waits for the initial
surfaces, prints one composed frame, and exits. That is the path used by the
example regression test.

You can also inject one synthetic click before the snapshot is rendered:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-click=37,6
```

And you can send one synthetic key into the focused plugin surface:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-click=37,6 \
  --snapshot-key=a
```

The activity plugin also uses the host clipboard service when it receives `c`:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-click=37,6 \
  --snapshot-key=c
```

It can also call the host URL-open and notification services:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-click=37,6 \
  --snapshot-key=o
```

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-click=37,6 \
  --snapshot-key=n
```

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-click=37,6 \
  --snapshot-key=p
```

And you can inject one synthetic hover motion into the workspace:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-motion=5,18
```
