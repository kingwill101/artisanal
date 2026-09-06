# Media Composer

Image chips, cursor preview, and a modal viewer on the artisanal core:
attached images live as typed chip elements (`[Image #N]`) in the buffer,
the chip under the cursor drives a preview line, `enter` on a chip opens a
modal viewer (checked *before* the textarea sees Enter), capability gating
falls back to text, deleting chip text drops the attachment, and submit
reconciles survivors.

- `ctrl+v` attaches an image: chip element + attachment record with
  deferred preview preparation (a tick completes it off the draw loop).
- Pasting or dropping image file paths auto-attaches them (quoted,
  `file://`, and shell-escaped forms recognized; other text pastes
  normally). Terminal file drops arrive as bracketed pastes on the same
  pipeline — the demo runs full-screen with bracketed paste enabled.
- Cursor preview line shows the chip's origin, dimensions, mime, and
  preview status — origins never enter the buffer text.
- `enter` on a chip opens the viewer — real pixels painted by the image
  subsystem (auto-detected Kitty/iTerm2/Sixel protocol, halfblock
  fallback) inside a TEA modal popup; `esc`/`q` closes it. `ctrl+f`
  forces the text fallback, `ctrl+p` cycles the paint protocol by hand
  (the footer shows the active one) for terminals that misreport
  capabilities.
- Submit prunes orphaned attachments and lists survivors as send blocks.

```sh
dart run example/tui/examples/media-composer/main.dart
```
