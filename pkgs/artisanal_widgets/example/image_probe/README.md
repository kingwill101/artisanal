# Image Probe

Small apps for isolating terminal image protocol behavior.

## Widget Probe

Run the normal widget path:

```sh
dart run pkgs/artisanal_widgets/example/image_probe/main.dart
```

Useful variants:

```sh
dart run pkgs/artisanal_widgets/example/image_probe/main.dart --mode kitty
dart run pkgs/artisanal_widgets/example/image_probe/main.dart --mode kitty --repaint-loop
dart run pkgs/artisanal_widgets/example/image_probe/main.dart --matrix
dart run pkgs/artisanal_widgets/example/image_probe/main.dart --raw kitty | cat -v
```

## Raw Overlay Probe

Use this before changing renderer code. It writes direct terminal sequences and
does not use the widget runtime.

```sh
dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage unicode-only --hold 10
dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage kitty-cursor --hold 10
dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage kitty-bottom --hold 10
dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage kitty-c1-bottom --hold 10
```

Interpretation:

- `unicode-only` corrupts: the issue is not Kitty APC.
- Only `kitty-cursor` corrupts: the cursor row is the trigger.
- `kitty-bottom` corrupts: Kitty image display is interacting with later text.
- Widget probe corrupts but raw stages do not: inspect widget/runtime repaint
  order instead of protocol encoding.

For ASCII inspection of the emitted stream:

```sh
dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage kitty-cursor --dump
```

For PTY timing capture, verify there is a silence during `--hold` before the
cleanup bytes:

```sh
script -q -e -f \
  -O /tmp/raw-overlay.tty \
  -T /tmp/raw-overlay.time \
  -c 'stty rows 34 cols 100; export COLUMNS=100 LINES=34; dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage kitty-cursor --hold 3'

tail -20 /tmp/raw-overlay.time
```

If corruption appears during the silent hold gap, the app is not emitting bytes
that cause the visual change.
