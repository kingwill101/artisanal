/// Helpers for OpenCode keymap tests (hub-driven which-key).
library;

import 'package:artisanal/tui.dart' as tui;

import '../../example/opencode/chords.dart';

/// Drive the app hub like the program interceptor would for `ctrl+x`.
tui.Msg? openCodePrefixMsg(tui.KeymapHub hub) {
  return hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
}

/// Shared hub for tests that need an explicit interceptor instance.
tui.KeymapHub testOpenCodeHub() => openCodeKeymapHub();
