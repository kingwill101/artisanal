# artisanal_test

`artisanal_test` is the PTY-scenario layer for Artisanal. It provides the
process-independent parts of an end-to-end terminal test harness:

- a small raw-byte PTY backend contract;
- deterministic input, output, resize, and exit events;
- output waits that work across arbitrary stream chunk boundaries;
- replayable JSON Lines traces; and
- environment-safe diagnostics.

The package deliberately does not choose a native PTY implementation yet. A
backend can wrap `portable_pty`, ConPTY, a remote PTY service, or a deterministic
fake without changing scenario code.

## Basic use

```dart
import 'dart:typed_data';

import 'package:artisanal_test/artisanal_test.dart';

Future<void> counterScenario(PtyBackendFactory spawnPty) async {
  final harness = PtyHarness(backendFactory: spawnPty);
  final session = await harness.spawn(
    PtySpawnRequest(
      executable: 'dart',
      arguments: const ['run', 'example/counter.dart'],
      columns: 80,
      rows: 24,
      environment: const {'TERM': 'xterm-256color'},
    ),
  );

  await session.waitForText('Count: 0');
  await session.sendText('j');
  await session.waitForText('Count: 1');
  await session.resize(columns: 40, rows: 12);

  final trace = await session.close();
  print(trace.toJsonLines());
}
```

A backend owns the actual subprocess and exposes raw terminal output:

```dart
abstract interface class PtyBackend {
  Stream<Uint8List> get output;
  Future<int> get exitCode;

  Future<void> write(Uint8List bytes);
  Future<void> resize({required int columns, required int rows});
  Future<void> kill();
  Future<void> close();
}
```

## Assertion strategy

Use captured bytes for protocol-level assertions and diagnostics. For ordinary
TUI rendering tests, feed those bytes into an independent virtual-terminal
model and compare the resulting cells. Different ANSI byte sequences can
produce the same correct screen, so byte-for-byte snapshots should not be the
default renderer assertion.

## Trace format

`PtyTrace.toJsonLines()` writes one metadata record followed by ordered event
records. Binary data is base64-encoded. The spawn environment is intentionally
excluded so API keys, tokens, and other secrets cannot leak into CI artifacts.

```json
{"type":"trace","schemaVersion":1,"spawn":{"executable":"dart","arguments":["run","example/counter.dart"],"columns":80,"rows":24}}
{"type":"output","elapsedMicros":1210,"bytes":"Q291bnQ6IDA="}
{"type":"input","elapsedMicros":8041,"bytes":"ag=="}
{"type":"resize","elapsedMicros":9102,"columns":40,"rows":12}
```

## Planned backends

The first native adapter should target `portable_pty` and retain exact bytes.
Its current synchronous blocking read API needs an asynchronous read pump or a
non-blocking polling primitive before it can safely accept writes and resize
commands while output is idle. Keeping that concern behind `PtyBackend` lets us
add the adapter without redesigning scenarios or traces.

The next layer after native spawning is a virtual-terminal driver that consumes
`PtyOutputEvent` bytes and exposes semantic screen assertions.
