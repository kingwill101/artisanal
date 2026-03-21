# OpenCode Performance Tests

This directory now keeps only the narrower OpenCode input/paste profile checks
that are still useful as cheap regression detectors in normal test runs.

## Test suites

- `opencode_input_hold_profile_test.dart`
  - held-key growth detector
  - held-key cadence spike detector
  - large paste latency check

The broader replay, markdown, resize, and soak suites were removed because
they were expensive, noisy in full-package runs, and more useful as ad hoc
profiling than as always-on regression gates.

## Run commands

From repository root:

```bash
dart test pkgs/artisanal_widgets/test/perf/
dart test pkgs/artisanal_widgets/test/perf/opencode_input_hold_profile_test.dart
```

## Trace profiling workflow

For deeper OpenCode performance investigation, prefer targeted manual trace
captures against the example app instead of broad perf assertions in CI. The
trace analyzer is still available under:

```bash
python pkgs/artisanal_widgets/example/opencode/analyze_trace.py --help
```
