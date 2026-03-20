# Remote Plugin Workspace

This example shows a full `artisanal` host app launching multiple
out-of-process plugins and composing their remote surfaces into one UV-backed
workspace.

The host discovers plugins from the `plugins/` directory by loading each
`*.plugin.json` manifest, validating it, and launching the manifest's
`entrypoint` relative to the manifest file.

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

And you can inject one synthetic hover motion into the workspace:

```bash
dart run pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart \
  --snapshot \
  --snapshot-motion=5,18
```
