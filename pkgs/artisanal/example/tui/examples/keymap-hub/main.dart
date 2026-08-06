/// KeymapHub demo — surface-first layers, leader chords, which-key, help sheet.
///
/// Run from `pkgs/artisanal`:
/// ```bash
/// dart run example/tui/examples/keymap-hub/main.dart
/// ```
///
/// Keys:
/// - `ctrl+x` then `b` / `m` / `t` — session actions (leader)
/// - `ctrl+p` — pretend command palette
/// - `?` — shortcuts sheet for the active surface
/// - `d` — push exclusive dialog surface
/// - `esc` — close dialog or help sheet
/// - `q` / `ctrl+c` — quit
library;

import 'package:artisanal/tui.dart';

void main() async {
  final hub = KeymapHub();

  // Session surface (default).
  hub.push(
    ShortcutSurface(
      id: 'session',
      bindings: _sessionBindings,
    ),
  );

  await runProgram(
    _KeymapDemoModel(hub: hub),
    options: ProgramOptions(
      altScreen: true,
      interceptor: hub,
    ),
  );
}

List<ShortcutBinding> get _sessionBindings => [
  ShortcutBinding.chord(
    id: 'toggle-sidebar',
    leader: 'ctrl+x',
    key: 'b',
    description: 'toggle sidebar',
    group: 'session',
  ),
  ShortcutBinding.chord(
    id: 'switch-model',
    leader: 'ctrl+x',
    key: 'm',
    description: 'switch model',
    group: 'session',
  ),
  ShortcutBinding.chord(
    id: 'theme-list',
    leader: 'ctrl+x',
    key: 't',
    description: 'themes',
    group: 'session',
  ),
  ShortcutBinding.single(
    id: 'command_list',
    key: 'ctrl+p',
    description: 'commands',
    group: 'app',
  ),
  ShortcutBinding.single(
    id: 'open_dialog',
    key: 'd',
    description: 'open dialog surface',
    group: 'demo',
  ),
  ShortcutBinding.help(),
];

List<ShortcutBinding> get _dialogBindings => [
  ShortcutBinding.single(
    id: 'confirm',
    key: 'y',
    description: 'confirm',
    group: 'dialog',
  ),
  ShortcutBinding.single(
    id: 'cancel',
    key: 'n',
    description: 'cancel / close',
    group: 'dialog',
  ),
  ShortcutBinding.help(),
];

final class _KeymapDemoModel implements Model {
  _KeymapDemoModel({
    required this.hub,
    this.status = 'Ready — press ctrl+x then a letter, or ? for help',
    this.lastAction,
    this.dialogOpen = false,
    this.helpOpen = false,
  });

  final KeymapHub hub;
  final String status;
  final String? lastAction;
  final bool dialogOpen;
  final bool helpOpen;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    // Esc: close help first, then dialog.
    if (msg is KeyMsg && msg.key.isEscape) {
      if (helpOpen) {
        return (copyWith(helpOpen: false, status: 'Help closed'), null);
      }
      if (dialogOpen) {
        hub.pop('dialog');
        return (
          copyWith(
            dialogOpen: false,
            status: 'Dialog closed — session surface active',
          ),
          null,
        );
      }
    }

    if (msg is KeymapSequencePrefixMsg) {
      final cont = hub.activeContinuations
          .map((c) => c.keyLabel)
          .join(' ');
      return (
        copyWith(
          status: 'Leader ${msg.matchedLabels.join(' ')} — then: $cont',
        ),
        null,
      );
    }

    if (msg is KeymapSequenceCancelledMsg) {
      return (
        copyWith(
          status: msg.timedOut ? 'Chord timed out' : 'Chord cancelled',
        ),
        null,
      );
    }

    if (msg is KeymapActionMsg) {
      return _onAction(msg.id);
    }

    if (msg is KeyMsg) {
      if (msg.key.isCtrlC || msg.key.rune == 0x71 /* q */) {
        return (this, Cmd.quit());
      }
    }

    return (this, null);
  }

  (Model, Cmd?) _onAction(String id) {
    switch (id) {
      case shortcutHelpActionId:
        return (
          copyWith(
            helpOpen: !helpOpen,
            status: helpOpen ? 'Help closed' : 'Shortcuts sheet open (esc)',
          ),
          null,
        );
      case 'command_list':
        return (
          copyWith(
            lastAction: id,
            status: 'Command palette (demo) — ctrl+p',
          ),
          null,
        );
      case 'open_dialog':
        if (!dialogOpen) {
          hub.push(
            ShortcutSurface(
              id: 'dialog',
              exclusive: true,
              bindings: _dialogBindings,
            ),
          );
          return (
            copyWith(
              dialogOpen: true,
              lastAction: id,
              status: 'Dialog surface (exclusive) — y/n or ?',
            ),
            null,
          );
        }
        return (this, null);
      case 'confirm':
        hub.pop('dialog');
        return (
          copyWith(
            dialogOpen: false,
            lastAction: id,
            status: 'Confirmed — back to session',
          ),
          null,
        );
      case 'cancel':
        hub.pop('dialog');
        return (
          copyWith(
            dialogOpen: false,
            lastAction: id,
            status: 'Cancelled — back to session',
          ),
          null,
        );
      default:
        return (
          copyWith(
            lastAction: id,
            status: 'Action: $id',
          ),
          null,
        );
    }
  }

  @override
  String view() {
    final b = StringBuffer();
    b.writeln();
    b.writeln('  ╔══════════════════════════════════════╗');
    b.writeln('  ║     KeymapHub surface demo         ║');
    b.writeln('  ╚══════════════════════════════════════╝');
    b.writeln();
    b.writeln('  Status: $status');
    if (lastAction != null) {
      b.writeln('  Last action: $lastAction');
    }
    b.writeln(
      '  Surfaces: ${hub.surfaceIds.isEmpty ? '(none)' : hub.surfaceIds.join(' → ')}',
    );
    if (hub.isSequencePending) {
      b.writeln('  Pending: ${hub.pendingStatusHint}');
      b.writeln(
        '  Continuations: ${hub.activeContinuations.map((c) => '${c.keyLabel}=${c.description}').join('  ')}',
      );
    }
    b.writeln();
    if (helpOpen) {
      b.writeln('  ── Shortcuts (${hub.top?.id ?? '?'}) ──');
      for (final binding in hub.activeShortcuts()) {
        b.writeln(
          '    ${binding.formattedKeys.padRight(12)} ${binding.description}',
        );
      }
      b.writeln('  ────────────────────────────');
      b.writeln('  esc close help');
    } else if (dialogOpen) {
      b.writeln('  ┌─ Confirm dialog (exclusive) ─┐');
      b.writeln('  │  Proceed?  y=yes  n=no  ?=help │');
      b.writeln('  └────────────────────────────────┘');
    } else {
      b.writeln('  Session surface');
      b.writeln('    ctrl+x b/m/t   leader chords');
      b.writeln('    ctrl+p         commands');
      b.writeln('    d              open exclusive dialog');
      b.writeln('    ?              shortcuts sheet');
      b.writeln('    q              quit');
    }
    b.writeln();
    return b.toString();
  }

  _KeymapDemoModel copyWith({
    String? status,
    String? lastAction,
    bool? dialogOpen,
    bool? helpOpen,
  }) {
    return _KeymapDemoModel(
      hub: hub,
      status: status ?? this.status,
      lastAction: lastAction ?? this.lastAction,
      dialogOpen: dialogOpen ?? this.dialogOpen,
      helpOpen: helpOpen ?? this.helpOpen,
    );
  }
}
