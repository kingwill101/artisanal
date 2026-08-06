/// OpenCode keybinds as [tui.ShortcutBinding]s for [tui.KeymapHub].
///
/// Leader is [openCodeChordPrefixLabel] (`ctrl+x`). Standalone shortcuts:
/// - `ctrl+p` — command panel / palette
/// - `?` — shortcuts sheet for the active surface
/// - `tab` — cycle agent/mode (handled in app, not hub)
/// - `ctrl+c` / `ctrl+d` — quit (handled in app)
///
/// Use [openCodeKeymapHub] as the program interceptor and host with
/// [w.KeymapHubScope] + per-route [w.ShortcutSurfaceScope].
library;

import 'package:artisanal/tui.dart' as tui;

import 'models/chat_model.dart';

/// OpenCode leader key (see `TuiKeybind.LeaderDefault`).
const openCodeChordPrefixLabel = 'ctrl+x';

/// Standalone command panel / palette (see `TuiKeybind.CommandListDefault`).
const openCodeCommandPanelShortcut = 'ctrl+p';

/// Compact footer status while a leader chord is pending.
const openCodeChordStatusHint = 'ctrl+x …';

/// Global / app-chrome bindings (bottom of the surface stack).
List<tui.ShortcutBinding> openCodeAppBindings() => [
  tui.ShortcutBinding.single(
    id: 'command_list',
    key: openCodeCommandPanelShortcut,
    description: 'commands',
    group: 'app',
  ),
  tui.ShortcutBinding.help(),
];

/// Session-route leader chords (OpenCode `keybind.ts` defaults).
List<tui.ShortcutBinding> openCodeSessionBindings() => [
  tui.ShortcutBinding.chord(
    id: AppChord.sidebar.id,
    leader: openCodeChordPrefixLabel,
    key: 'b',
    description: 'toggle sidebar',
    group: 'session',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.sessions.id,
    leader: openCodeChordPrefixLabel,
    key: 'l',
    description: 'session list',
    group: 'session',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.models.id,
    leader: openCodeChordPrefixLabel,
    key: 'm',
    description: 'models',
    group: 'session',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.theme.id,
    leader: openCodeChordPrefixLabel,
    key: 't',
    description: 'themes',
    group: 'session',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.newSession.id,
    leader: openCodeChordPrefixLabel,
    key: 'n',
    description: 'home / new',
    group: 'session',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.agents.id,
    leader: openCodeChordPrefixLabel,
    key: 'a',
    description: 'agents',
    group: 'session',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.review.id,
    leader: openCodeChordPrefixLabel,
    key: 'd',
    description: 'diff review',
    group: 'session',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.status.id,
    leader: openCodeChordPrefixLabel,
    key: 's',
    description: 'go to session',
    group: 'session',
  ),
  tui.ShortcutBinding.single(
    id: 'command_list',
    key: openCodeCommandPanelShortcut,
    description: 'commands',
    group: 'app',
  ),
  tui.ShortcutBinding.help(),
];

/// Home route: navigation + palette + help.
List<tui.ShortcutBinding> openCodeHomeBindings() => [
  tui.ShortcutBinding.chord(
    id: AppChord.sessions.id,
    leader: openCodeChordPrefixLabel,
    key: 'l',
    description: 'session list',
    group: 'home',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.agents.id,
    leader: openCodeChordPrefixLabel,
    key: 'a',
    description: 'agents',
    group: 'home',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.review.id,
    leader: openCodeChordPrefixLabel,
    key: 'd',
    description: 'diff review',
    group: 'home',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.theme.id,
    leader: openCodeChordPrefixLabel,
    key: 't',
    description: 'themes',
    group: 'home',
  ),
  tui.ShortcutBinding.single(
    id: 'command_list',
    key: openCodeCommandPanelShortcut,
    description: 'commands',
    group: 'app',
  ),
  tui.ShortcutBinding.help(),
];

/// Review route bindings.
List<tui.ShortcutBinding> openCodeReviewBindings() => [
  tui.ShortcutBinding.chord(
    id: AppChord.status.id,
    leader: openCodeChordPrefixLabel,
    key: 's',
    description: 'go to session',
    group: 'review',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.newSession.id,
    leader: openCodeChordPrefixLabel,
    key: 'n',
    description: 'home / new',
    group: 'review',
  ),
  tui.ShortcutBinding.single(
    id: 'command_list',
    key: openCodeCommandPanelShortcut,
    description: 'commands',
    group: 'app',
  ),
  tui.ShortcutBinding.help(),
];

/// Agent overview bindings.
List<tui.ShortcutBinding> openCodeAgentBindings() => [
  tui.ShortcutBinding.chord(
    id: AppChord.sidebar.id,
    leader: openCodeChordPrefixLabel,
    key: 'b',
    description: 'toggle sidebar',
    group: 'agent',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.status.id,
    leader: openCodeChordPrefixLabel,
    key: 's',
    description: 'go to session',
    group: 'agent',
  ),
  tui.ShortcutBinding.chord(
    id: AppChord.newSession.id,
    leader: openCodeChordPrefixLabel,
    key: 'n',
    description: 'home / new',
    group: 'agent',
  ),
  tui.ShortcutBinding.single(
    id: 'command_list',
    key: openCodeCommandPanelShortcut,
    description: 'commands',
    group: 'app',
  ),
  tui.ShortcutBinding.help(),
];

/// Legacy chord list (tests / [tui.KeyChordInterceptor] bridges).
List<tui.KeyChordBinding> openCodeChordBindings() => [
  for (final b in openCodeSessionBindings())
    if (b.toChordBinding() != null) b.toChordBinding()!,
];

/// Shared OpenCode [tui.KeymapHub] (program interceptor + surface stack).
///
/// Pass [innerInterceptor] for replay/dev tooling as a **base** layer.
tui.KeymapHub openCodeKeymapHub({
  tui.ProgramInterceptor? innerInterceptor,
}) {
  return tui.KeymapHub(
    base: [
      ?innerInterceptor,
    ],
  );
}
