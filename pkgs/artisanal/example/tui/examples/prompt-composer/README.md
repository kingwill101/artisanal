# Prompt Composer

Prompt editing on the artisanal core: a `TextAreaModel` composer plus four
editor integrations.

- **Tracked placeholders** (`ctrl+v`): large pastes insert a short
  `[Pasted ~N lines]` display marker while the full text is retained in a
  `PlaceholderTracker`; submit expands them via `expandPlaceholderRanges`.
- **Normalization** (`ctrl+t` or `ctrl+s`): submit runs
  `normalizePromptContent`, which strips the single trailing newline
  external editors append to one-line prompts while preserving multiline
  drafts. (The runtime disables XOFF flow control in raw mode, so `ctrl+s`
  arrives as a key instead of freezing the terminal.)
- **External editor** (`ctrl+o`): the draft is written to a temp `.md` file
  and opened with `Cmd.openEditor` (`$VISUAL`/`$EDITOR`); the terminal is
  released and restored around the child process, then the file is read back
  and normalized.
- **IDE selection** (`ctrl+g` / `ctrl+d`): a simulated 1-based wire selection
  resolves against a `TextDocument` to clamped offsets, labels like `#2`, and
  a `formatEditorSelectionContext` block attached on submit.

```sh
dart run example/tui/examples/prompt-composer/main.dart
```

A `Last key:` footer shows the decoded key event for every press, so key
 delivery is visible when debugging terminals.
