# OpenCode Performance Tests

This directory contains deterministic performance regression tests for the
OpenCode example UI.

## Test suites

- `opencode_replay_test.dart`
  - `baseline replay`: moderate scripted interaction sequence.
  - `heavy replay`: high-pressure sequence (typing, wheel bursts, navigation).
- `opencode_diff_markdown_regression_test.dart`
  - `OpenCode diff-heavy`: many expanded diffs with repeated scrolling.
  - `Markdown-heavy`: many large markdown snippets in a virtualized list.
- `opencode_extended_regression_test.dart`
  - `OpenCode soak`: long mixed interaction session (~3k events).
  - `OpenCode resize stress`: repeated `WindowSizeMsg` with interaction.
  - `Style churn`: repeated themed markdown remounts and scrolling.

These tests are deterministic and include thresholds so regressions fail in CI.

## Run commands

From repository root:

```bash
dart test pkgs/artisanal_widgets/test/perf/
dart test pkgs/artisanal_widgets/test/perf/opencode_replay_test.dart -n "heavy replay"
dart test pkgs/artisanal_widgets/test/perf/opencode_diff_markdown_regression_test.dart -n "OpenCode diff-heavy"
dart test pkgs/artisanal_widgets/test/perf/opencode_extended_regression_test.dart
```

## Baseline snapshot

Baseline from full suite run on 2026-02-11 (`dart test pkgs/artisanal_widgets/test/perf/`):

- baseline replay: avg `9.23ms`, p95 `39.08ms`, max `44.44ms`
- heavy replay: avg `8.24ms`, p95 `29.69ms`, max `43.48ms`
- diff-heavy: avg `39.05ms`, p95 `61.89ms`, max `76.94ms`
- markdown-heavy: avg `1.34ms`, p95 `6.28ms`, max `19.75ms`
- soak: avg `4.31ms`, p95 `32.83ms`, max `77.04ms`
- resize stress: avg `12.52ms`, p95 `38.70ms`, max `53.32ms`
- style churn: avg `54.62ms`, p95 `131.22ms`, max `810.91ms`

Use this as a comparison point before tightening budgets further.

## Scenario files

Replay scenarios live in:

- `pkgs/artisanal_widgets/example/opencode/scenarios/baseline_scroll.json`
- `pkgs/artisanal_widgets/example/opencode/scenarios/heavy_scroll.json`

## Trace profiling workflow

Capture traces for deep analysis:

```bash
ARTISANAL_TUI_TRACE=1 ARTISANAL_TUI_TRACE_CAPTURE=1 \
ARTISANAL_TUI_TRACE_PATH=pkgs/artisanal_widgets/example/opencode/traces/run-replay.log \
dart test pkgs/artisanal_widgets/test/perf/opencode_replay_test.dart -n "heavy replay"

ARTISANAL_TUI_TRACE=1 ARTISANAL_TUI_TRACE_CAPTURE=1 \
ARTISANAL_TUI_TRACE_PATH=pkgs/artisanal_widgets/example/opencode/traces/run-diff.log \
dart test pkgs/artisanal_widgets/test/perf/opencode_diff_markdown_regression_test.dart -n "OpenCode diff-heavy"
```

Analyze trace output:

```bash
python pkgs/artisanal_widgets/example/opencode/analyze_trace.py \
  pkgs/artisanal_widgets/example/opencode/traces/run-replay.log --top 12

python pkgs/artisanal_widgets/example/opencode/analyze_trace.py \
  pkgs/artisanal_widgets/example/opencode/traces/run-replay.log \
  --json pkgs/artisanal_widgets/example/opencode/traces/run-replay.json --top 12
```

Compare two traces:

```bash
python pkgs/artisanal_widgets/example/opencode/analyze_trace.py \
  pkgs/artisanal_widgets/example/opencode/traces/run-replay.log \
  --compare pkgs/artisanal_widgets/example/opencode/traces/older-replay.log \
  --json pkgs/artisanal_widgets/example/opencode/traces/run-replay-compare.json --top 12
```

The analyzer now includes fallback "generic timing" summaries for sparse traces
that do not contain full dispatch/render markers.
