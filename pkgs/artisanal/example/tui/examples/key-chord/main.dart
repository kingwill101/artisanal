import 'package:artisanal/tui.dart' as tui;

class KeyChordModel implements tui.Model {
  const KeyChordModel({this.status = 'Ready', this.lastChord});

  final String status;
  final String? lastChord;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    return switch (msg) {
      // Resolved chord: show the binding id
      tui.KeyChordResolvedMsg(:final id) => (
        copyWith(status: 'Chord activated!', lastChord: id),
        null,
      ),

      // Prefix detected: show "waiting for second key"
      tui.KeyChordPrefixMsg() => (
        copyWith(status: 'Waiting for second key...'),
        null,
      ),

      // Cancelled (timeout or unmatched key)
      tui.KeyChordCancelledMsg(:final timedOut) => (
        copyWith(
          status: timedOut ? 'Chord timed out' : 'Chord cancelled',
        ),
        null,
      ),

      // Regular keys not part of a chord pass through normally
      tui.KeyMsg(key: final k) when k.rune == 0x71 => (
        this,
        tui.Cmd.quit(),
      ),

      _ => (this, null),
    };
  }

  @override
  String view() {
    final buffer = StringBuffer();
    buffer.writeln('\n  ╔═══ Key Chord Demo ═══╗\n');
    buffer.writeln('  Status: $status');
    if (lastChord != null) {
      buffer.writeln('  Last chord: $lastChord');
    }
    buffer.writeln('');
    buffer.writeln('  Bindings:');
    buffer.writeln('    Ctrl+X then t  → open themes');
    buffer.writeln('    Ctrl+X then m  → switch model');
    buffer.writeln('');
    buffer.writeln('  Press q to quit');
    return buffer.toString();
  }

  KeyChordModel copyWith({String? status, String? lastChord}) =>
    KeyChordModel(status: status ?? this.status, lastChord: lastChord ?? this.lastChord);
}

void main() async {
  final interceptor = tui.KeyChordInterceptor(
    bindings: [
      tui.KeyChordBinding(
        id: 'open-themes',
        prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
        key: tui.KeyBinding.withHelp(['t'], 't', 'themes'),
      ),
      tui.KeyChordBinding(
        id: 'switch-model',
        prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
        key: tui.KeyBinding.withHelp(['m'], 'm', 'model'),
      ),
      tui.KeyChordBinding(
        id: 'toggle-sidebar',
        prefix: tui.KeyBinding.withHelp(['ctrl+x'], 'ctrl+x', 'prefix'),
        key: tui.KeyBinding.withHelp(['b'], 'b', 'sidebar'),
      ),
    ],
    timeout: const Duration(seconds: 3),
  );

  await tui.runProgram(
    const KeyChordModel(),
    options: tui.ProgramOptions(
      altScreen: true,
      interceptor: interceptor,
    ),
  );
}
