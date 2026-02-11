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

These tests are deterministic and include thresholds so regressions fail in CI.

## Run commands

From repository root:

```bash
dart test pkgs/artisanal_widgets/test/perf/
dart test pkgs/artisanal_widgets/test/perf/opencode_replay_test.dart -n "heavy replay"
dart test pkgs/artisanal_widgets/test/perf/opencode_diff_markdown_regression_test.dart -n "OpenCode diff-heavy"
```

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
