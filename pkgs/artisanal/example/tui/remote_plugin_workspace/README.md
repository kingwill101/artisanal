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
