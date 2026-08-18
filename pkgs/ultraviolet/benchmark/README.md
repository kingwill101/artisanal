# Ultraviolet performance baseline

`baseline.dart` is the reference gate for hot-path changes. It measures the
renderer, buffer writes, Unicode width calculation, style transitions, and
input decoding with deterministic workloads.

The harness provides:

- deterministic inputs and checksums;
- an explicit warmup period;
- calibrated samples long enough to reduce timer noise;
- median, p95, median absolute deviation, and coefficient of variation (CV);
- machine, Dart, Git revision, and dirty-worktree metadata;
- JSON output for storing and comparing runs.
- one explicit DevTools CPU/memory region named `ultraviolet.<workload>` for
  every measured workload when launched by `devtools-profiler`.

## Reference run

Run from the repository root:

```sh
task benchmark-uv
```

This compiles the harness to an AOT executable and runs it. A quicker JIT smoke
run is available as `task benchmark-uv-jit`, but JIT results are not the
reference numbers for accepting an optimization.

To save machine-readable output:

```sh
mkdir -p build/benchmarks
build/benchmarks/uv_baseline --json > build/benchmarks/uv-baseline.json
```

The `build/` directory is intentionally ignored by Git. Keep a baseline JSON
file outside the source tree while testing a patch.

## Comparison protocol

1. Use the same machine, power mode, Dart SDK, and background-load conditions.
   Let thermally constrained laptops cool before each run; the report records
   the CPU governor, AC state, and maximum hardware temperature visible after
   the run.
2. Build once, then run the executable at least three times before a change.
3. Apply one optimization and rebuild the executable.
4. Run it at least three times again, preferably alternating baseline and
   candidate binaries to reduce thermal and time-order bias.
5. Compare per-process medians. Treat CV above 5% as noisy and rerun.
6. Require a repeatable improvement larger than the observed noise. For small
   changes, 5% is a sensible minimum unless many alternating runs establish a
   tighter confidence interval.
7. Run correctness tests and profiling as separate gates. A faster benchmark
   does not establish output correctness, and a profiler hypothesis does not
   establish a throughput improvement.

Use `--only=renderer`, `--samples=N`, `--warmup-ms=N`, or `--sample-ms=N` for
focused investigation. Do not compare runs with different harness settings.

## Profiling

Profile all measured workloads under the JIT from the repository root:

```sh
task benchmark-uv-profile
```

Pass a focused selector after `--`, for example:

```sh
task benchmark-uv-profile -- --only=decoder.csi_parameters \
  --samples=7 --warmup-ms=500 --sample-ms=150
```

Warmup and sample calibration happen before each named region opens, so CPU
samples and memory deltas cover only the repeatable measurement loop. AOT
executables remain the throughput reference; Dart's product AOT executable
does not expose the VM service needed by `devtools-profiler`, so collect CPU
and allocation attribution from the JIT run and confirm speed with AOT.

The renderer cases call `flush()` every frame. This bounds the internal output
buffer and measures ANSI materialization into a no-I/O counting sink without
adding terminal or filesystem latency.
