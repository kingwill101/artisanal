# AGENTS.md — artisanal_test

## Scope

This package owns PTY-driven integration-test orchestration. Keep it independent
from any one PTY implementation so native, remote, fake, and future browser
backends can implement the same contract.

## Boundaries

- Capture raw bytes; decoding is a convenience view only.
- Record input, output, resize, and exit events with monotonic timestamps.
- Never serialize environment values into traces.
- Keep terminal-screen emulation separate from process ownership. A future
  screen driver should consume captured output through an explicit interface.
- Do not move renderer diff logic here; it belongs in `ultraviolet`.

## Testing

```sh
dart test pkgs/artisanal_test -r compact
```

Use fake backends for unit tests. Native backend integration tests should be
separately tagged so ordinary workspace tests stay deterministic.
