// Reproducible performance baseline for Ultraviolet's hot paths.
//
// The reference mode is an AOT-compiled executable. See benchmark/README.md.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:devtools_region_profiler/devtools_region_profiler.dart';
import 'package:ultraviolet/ultraviolet.dart';

const _width = 120;
const _height = 40;
const _cellsPerFrame = _width * _height;

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  final cases = _benchmarkCases()
      .where(
        (benchmark) =>
            options.only == null || benchmark.name.contains(options.only!),
      )
      .toList(growable: false);

  if (cases.isEmpty) {
    stderr.writeln('No benchmark matched --only=${options.only}.');
    exitCode = 64;
    return;
  }

  final results = <_Result>[];
  var checksum = 0;
  for (final benchmark in cases) {
    final result = await _run(benchmark, options);
    results.add(result);
    checksum = _mix(checksum, result.checksum);
  }

  final report = <String, Object?>{
    'schema_version': 1,
    'metadata': _metadata(options),
    'benchmarks': results.map((result) => result.toJson()).toList(),
    'checksum': checksum,
  };

  if (options.json) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  } else {
    _printHumanReport(report, results);
  }
}

List<_Benchmark> _benchmarkCases() {
  return <_Benchmark>[
    _unchangedRenderer(),
    _sparseRenderer(),
    _denseRenderer(styled: false),
    _denseRenderer(styled: true),
    _bufferWrites(),
    _asciiWidth(),
    _unicodeWidthCacheHit(),
    _unicodeWidthCacheThrash(),
    _styleDiffs(),
    _styleTransitions(),
    _csiParameterDecode(),
    _eventDecode(),
  ];
}

_Benchmark _unchangedRenderer() {
  final sink = _CountingSink();
  final renderer = _renderer(sink);
  final buffer = _makeBuffer(
    tracksDirty: true,
    cellAt: (x, y) => Cell.ascii(0x20 + ((x + y * 7) % 95)),
  );
  renderer.render(buffer);
  renderer.flush();

  const framesPerBatch = 32;
  return _Benchmark(
    name: 'renderer.unchanged_120x40',
    unit: 'frame',
    operationsPerBatch: framesPerBatch,
    context: const <String, Object?>{
      'cells_per_frame': _cellsPerFrame,
      'changed_cells_per_frame': 0,
      'includes_flush': true,
    },
    runBatch: () {
      for (var frame = 0; frame < framesPerBatch; frame++) {
        renderer.render(buffer);
        renderer.flush();
      }
      return _mix(sink.codeUnitsWritten, renderer.metrics.skippedFrames);
    },
  );
}

_Benchmark _sparseRenderer() {
  final sink = _CountingSink();
  final renderer = _renderer(sink);
  final buffer = _makeBuffer(
    tracksDirty: true,
    cellAt: (x, y) => Cell.ascii(0x20 + ((x + y * 7) % 95)),
  );
  renderer.render(buffer);
  renderer.flush();

  final cells = List<Cell>.generate(
    96,
    (index) => Cell.asciiStyled(
      0x21 + index % 94,
      style: UvStyle(
        fg: UvColor.rgb(
          (index * 17) & 0xff,
          (index * 31) & 0xff,
          (index * 47) & 0xff,
        ),
      ),
    ),
    growable: false,
  );
  const changedPerFrame = _cellsPerFrame ~/ 100;
  const framesPerBatch = 16;
  var sequence = 0;

  return _Benchmark(
    name: 'renderer.sparse_1pct_120x40',
    unit: 'frame',
    operationsPerBatch: framesPerBatch,
    context: const <String, Object?>{
      'cells_per_frame': _cellsPerFrame,
      'changed_cells_per_frame': changedPerFrame,
      'includes_buffer_mutation': true,
      'includes_flush': true,
    },
    runBatch: () {
      for (var frame = 0; frame < framesPerBatch; frame++) {
        for (var i = 0; i < changedPerFrame; i++) {
          final n = sequence + i;
          final index = (n * 104729 + frame * 8191) % _cellsPerFrame;
          buffer.setCell(
            index % _width,
            index ~/ _width,
            cells[n % cells.length],
          );
        }
        sequence += changedPerFrame;
        renderer.render(buffer);
        renderer.flush();
      }
      return _mix(sink.codeUnitsWritten, sequence);
    },
  );
}

_Benchmark _denseRenderer({required bool styled}) {
  final sink = _CountingSink();
  final renderer = _renderer(sink);
  final palettes = styled ? _stylePalettes() : _plainPalettes();
  final a = _makeBuffer(
    tracksDirty: false,
    cellAt: (x, y) => palettes.$1[(x * 3 + y * 5) % palettes.$1.length],
  );
  final b = _makeBuffer(
    tracksDirty: false,
    cellAt: (x, y) => palettes.$2[(x * 7 + y * 11) % palettes.$2.length],
  );
  renderer.render(a);
  renderer.flush();

  const framesPerBatch = 8;
  var frameNumber = 0;
  return _Benchmark(
    name: styled
        ? 'renderer.dense_style_churn_120x40'
        : 'renderer.dense_plain_120x40',
    unit: 'frame',
    operationsPerBatch: framesPerBatch,
    context: const <String, Object?>{
      'cells_per_frame': _cellsPerFrame,
      'changed_cells_per_frame': _cellsPerFrame,
      'includes_flush': true,
    },
    runBatch: () {
      for (var frame = 0; frame < framesPerBatch; frame++) {
        renderer.render(frameNumber.isEven ? b : a);
        renderer.flush();
        frameNumber++;
      }
      return _mix(sink.codeUnitsWritten, frameNumber);
    },
  );
}

_Benchmark _bufferWrites() {
  final buffer = Buffer.create(_width, _height);
  final cells = List<Cell>.generate(
    95,
    (index) => Cell.ascii(0x20 + index),
    growable: false,
  );
  const framesPerBatch = 16;
  var generation = 0;

  return _Benchmark(
    name: 'buffer.sequential_ascii_writes_120x40',
    unit: 'cell_write',
    operationsPerBatch: framesPerBatch * _cellsPerFrame,
    context: const <String, Object?>{
      'cells_per_frame': _cellsPerFrame,
      'clears_dirty_tracking_each_frame': true,
    },
    runBatch: () {
      for (var frame = 0; frame < framesPerBatch; frame++) {
        for (var y = 0; y < _height; y++) {
          for (var x = 0; x < _width; x++) {
            buffer.setCell(x, y, cells[(x + y + generation) % cells.length]);
          }
        }
        buffer.clearDirtyTracking();
        generation++;
      }
      return _mix(generation, buffer.line(generation % _height)!.renderHash());
    },
  );
}

_Benchmark _asciiWidth() {
  final strings = List<String>.generate(
    256,
    (index) =>
        'row-${index.toRadixString(16).padLeft(2, '0')}: '
        'abcdefghijklmnopqrstuvwxyz012345',
    growable: false,
  );
  const repeats = 32;
  return _Benchmark(
    name: 'width.ascii_40',
    unit: 'string',
    operationsPerBatch: repeats * strings.length,
    context: const <String, Object?>{'code_units_per_string': 40},
    runBatch: () {
      var total = 0;
      for (var repeat = 0; repeat < repeats; repeat++) {
        for (final value in strings) {
          total += stringWidth(value);
        }
      }
      return total;
    },
  );
}

_Benchmark _unicodeWidthCacheHit() {
  final strings = List<String>.generate(
    256,
    (index) => 'item-$index: 漢字 café 👩🏽‍💻',
    growable: false,
  );
  for (final value in strings) {
    stringWidth(value);
  }
  const repeats = 32;
  return _Benchmark(
    name: 'width.unicode_cache_hit',
    unit: 'string',
    operationsPerBatch: repeats * strings.length,
    context: const <String, Object?>{'working_set': 256},
    runBatch: () {
      var total = 0;
      for (var repeat = 0; repeat < repeats; repeat++) {
        for (final value in strings) {
          total += stringWidth(value);
        }
      }
      return total;
    },
  );
}

_Benchmark _unicodeWidthCacheThrash() {
  final strings = List<String>.generate(
    4096,
    (index) => 'unique-$index-${String.fromCharCode(0x4e00 + index % 0x1000)}',
    growable: false,
  );
  var offset = 0;
  return _Benchmark(
    name: 'width.unicode_cache_thrash',
    unit: 'string',
    operationsPerBatch: strings.length,
    context: const <String, Object?>{
      'working_set': 4096,
      'cache_capacity': 2048,
    },
    runBatch: () {
      var total = 0;
      for (var i = 0; i < strings.length; i++) {
        total += stringWidth(strings[(i + offset) & 4095]);
      }
      offset = (offset + 257) & 4095;
      return _mix(total, offset);
    },
  );
}

_Benchmark _styleDiffs() {
  final styles = _benchmarkStyles();
  const repeats = 32;
  return _Benchmark(
    name: 'style.rgb_transitions',
    unit: 'transition',
    operationsPerBatch: repeats * styles.length,
    context: const <String, Object?>{'working_set': 256},
    runBatch: () {
      var total = 0;
      for (var repeat = 0; repeat < repeats; repeat++) {
        for (var i = 0; i < styles.length; i++) {
          total += styleDiff(styles[i], styles[(i + 1) & 255]).length;
        }
      }
      return total;
    },
  );
}

_Benchmark _styleTransitions() {
  final styles = _benchmarkStyles();
  const repeats = 32;
  return _Benchmark(
    name: 'style.rich_sgr_transitions',
    unit: 'transition',
    operationsPerBatch: repeats * styles.length,
    context: const <String, Object?>{'working_set': 256},
    runBatch: () {
      var total = 0;
      for (var repeat = 0; repeat < repeats; repeat++) {
        for (var i = 0; i < styles.length; i++) {
          total += styleTransitionSgr(styles[i], styles[(i + 1) & 255]).length;
        }
      }
      return total;
    },
  );
}

List<UvStyle> _benchmarkStyles() => List<UvStyle>.generate(
  256,
  (index) => UvStyle(
    fg: UvColor.rgb(index, (index * 31) & 0xff, (index * 67) & 0xff),
    bg: index.isEven
        ? UvColor.rgb((index * 13) & 0xff, (index * 19) & 0xff, index)
        : null,
    attrs: index % 3 == 0
        ? Attr.bold
        : index % 3 == 1
        ? Attr.italic
        : 0,
    underline: index % 7 == 0 ? UnderlineStyle.single : UnderlineStyle.none,
  ),
  growable: false,
);

_Benchmark _eventDecode() {
  final events = <List<int>>[
    const <int>[0x61],
    const <int>[0x1b, 0x5b, 0x41],
    ...List<List<int>>.generate(
      32,
      (index) => '\x1b[<0;${index + 1};${index % 20 + 1}M'.codeUnits,
    ),
    ...List<List<int>>.generate(
      32,
      (index) => '\x1b[${index + 10};${index % 8 + 1}~'.codeUnits,
    ),
    const <int>[0xf0, 0x9f, 0x98, 0x80],
  ];
  const repeats = 64;
  return _Benchmark(
    name: 'decoder.mixed_complete_events',
    unit: 'event',
    operationsPerBatch: repeats * events.length,
    context: <String, Object?>{'working_set': events.length},
    runBatch: () {
      final decoder = EventDecoder();
      var total = 0;
      for (var repeat = 0; repeat < repeats; repeat++) {
        for (final bytes in events) {
          final (consumed, event) = decoder.decode(
            bytes,
            allowIncompleteEsc: true,
          );
          total += consumed + (event == null ? 0 : 1);
        }
      }
      return total;
    },
  );
}

_Benchmark _csiParameterDecode() {
  final events = <List<int>>[
    ...List<List<int>>.generate(
      64,
      (index) =>
          '\x1b[${97 + index}:65:${97 + index};${index % 8 + 1}:2u'.codeUnits,
    ),
    ...List<List<int>>.generate(
      64,
      (index) => '\x1b[<${index % 4};${index + 1};${index % 40 + 1}M'.codeUnits,
    ),
  ];
  const repeats = 64;
  return _Benchmark(
    name: 'decoder.csi_parameters',
    unit: 'sequence',
    operationsPerBatch: repeats * events.length,
    context: <String, Object?>{
      'working_set': events.length,
      'includes_colon_subparameters': true,
    },
    runBatch: () {
      final decoder = EventDecoder();
      var total = 0;
      for (var repeat = 0; repeat < repeats; repeat++) {
        for (final bytes in events) {
          final (consumed, event) = decoder.decode(
            bytes,
            allowIncompleteEsc: true,
          );
          total += consumed + (event == null ? 0 : 1);
        }
      }
      return total;
    },
  );
}

UvTerminalRenderer _renderer(_CountingSink sink) {
  final renderer = UvTerminalRenderer(
    sink,
    env: const <String>['TERM=xterm-256color', 'COLORTERM=truecolor'],
    isTty: true,
  );
  renderer.setFullscreen(true);
  renderer.setRelativeCursor(false);
  renderer.resize(_width, _height);
  return renderer;
}

Buffer _makeBuffer({
  required bool tracksDirty,
  required Cell Function(int x, int y) cellAt,
}) {
  final buffer = Buffer.create(_width, _height, tracksDirty: tracksDirty);
  for (var y = 0; y < _height; y++) {
    final line = buffer.line(y)!;
    for (var x = 0; x < _width; x++) {
      line.set(x, cellAt(x, y));
    }
  }
  return buffer;
}

(List<Cell>, List<Cell>) _plainPalettes() {
  return (
    List<Cell>.generate(95, (index) => Cell.ascii(0x20 + index)),
    List<Cell>.generate(95, (index) => Cell.ascii(0x20 + (index + 47) % 95)),
  );
}

(List<Cell>, List<Cell>) _stylePalettes() {
  List<Cell> make(int seed) => List<Cell>.generate(128, (index) {
    final n = index + seed;
    return Cell.asciiStyled(
      0x21 + n % 94,
      style: UvStyle(
        fg: UvColor.rgb((n * 17) & 0xff, (n * 31) & 0xff, (n * 47) & 0xff),
        bg: UvColor.rgb((n * 59) & 0xff, (n * 71) & 0xff, (n * 89) & 0xff),
        attrs: n % 4 == 0
            ? Attr.bold
            : n % 4 == 1
            ? Attr.italic
            : 0,
      ),
    );
  }, growable: false);

  return (make(0), make(193));
}

Future<_Result> _run(_Benchmark benchmark, _Options options) async {
  var checksum = 0;
  final warmup = Stopwatch()..start();
  do {
    checksum = _mix(checksum, benchmark.runBatch());
  } while (warmup.elapsedMilliseconds < options.warmupMs);

  var batchesPerSample = 1;
  while (true) {
    final probe = Stopwatch()..start();
    for (var i = 0; i < batchesPerSample; i++) {
      checksum = _mix(checksum, benchmark.runBatch());
    }
    probe.stop();
    if (probe.elapsedMilliseconds >= options.sampleMs ||
        batchesPerSample >= 1 << 20) {
      break;
    }
    final elapsedUs = math.max(probe.elapsedMicroseconds, 1);
    final targetUs = options.sampleMs * 1000;
    final scale = (targetUs / elapsedUs).ceil().clamp(2, 16);
    batchesPerSample *= scale;
  }

  final samples = <double>[];
  void measureSamples() {
    for (var sample = 0; sample < options.samples; sample++) {
      final watch = Stopwatch()..start();
      for (var batch = 0; batch < batchesPerSample; batch++) {
        checksum = _mix(checksum, benchmark.runBatch());
      }
      watch.stop();
      final operations = batchesPerSample * benchmark.operationsPerBatch;
      samples.add(watch.elapsedMicroseconds * 1000 / operations);
    }
  }

  if (_profilerRegionsEnabled) {
    await profileRegion(
      'ultraviolet.${benchmark.name}',
      attributes: <String, String>{
        'package': 'ultraviolet',
        'unit': benchmark.unit,
        'samples': '${options.samples}',
      },
      () async => measureSamples(),
    );
  } else {
    measureSamples();
  }

  return _Result.fromSamples(
    benchmark: benchmark,
    samplesNsPerOperation: samples,
    batchesPerSample: batchesPerSample,
    checksum: checksum,
  );
}

const _profilerDtdUri = String.fromEnvironment('DEVTOOLS_PROFILER_DTD_URI');
const _profilerSessionId = String.fromEnvironment(
  'DEVTOOLS_PROFILER_SESSION_ID',
);

bool get _profilerRegionsEnabled =>
    (_profilerDtdUri.isNotEmpty && _profilerSessionId.isNotEmpty) ||
    ((Platform.environment['DEVTOOLS_PROFILER_DTD_URI']?.isNotEmpty ?? false) &&
        (Platform.environment['DEVTOOLS_PROFILER_SESSION_ID']?.isNotEmpty ??
            false));

Map<String, Object?> _metadata(_Options options) {
  String command(String executable, List<String> args) {
    try {
      final result = Process.runSync(executable, args);
      return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unavailable';
    } on ProcessException {
      return 'unavailable';
    }
  }

  String cpuModel() {
    if (!Platform.isLinux) return 'unavailable';
    try {
      final line = File(
        '/proc/cpuinfo',
      ).readAsLinesSync().firstWhere((value) => value.startsWith('model name'));
      return line.split(':').last.trim();
    } on Object {
      return 'unavailable';
    }
  }

  List<String> cpuGovernors() {
    if (!Platform.isLinux) return const <String>[];
    try {
      final values = <String>{};
      final root = Directory('/sys/devices/system/cpu/cpufreq');
      for (final entry in root.listSync()) {
        if (entry is! Directory ||
            !entry.path.split('/').last.startsWith('policy')) {
          continue;
        }
        final file = File('${entry.path}/scaling_governor');
        if (file.existsSync()) values.add(file.readAsStringSync().trim());
      }
      return values.toList()..sort();
    } on Object {
      return const <String>[];
    }
  }

  double? maximumHardwareTemperatureCelsius() {
    if (!Platform.isLinux) return null;
    try {
      double? maximum;
      final root = Directory('/sys/class/hwmon');
      for (final entry in root.listSync()) {
        if (entry is! Directory) continue;
        for (final file in entry.listSync()) {
          final name = file.path.split('/').last;
          if (file is! File ||
              !name.startsWith('temp') ||
              !name.endsWith('_input')) {
            continue;
          }
          final millidegrees = double.tryParse(file.readAsStringSync().trim());
          if (millidegrees == null) continue;
          final celsius = millidegrees / 1000;
          if (celsius < -20 || celsius > 150) continue;
          maximum = maximum == null ? celsius : math.max(maximum, celsius);
        }
      }
      return maximum;
    } on Object {
      return null;
    }
  }

  bool? acOnline() {
    if (!Platform.isLinux) return null;
    try {
      final root = Directory('/sys/class/power_supply');
      var foundExternalSupply = false;
      for (final entry in root.listSync()) {
        if (entry is! Directory) continue;
        final type = File('${entry.path}/type');
        final online = File('${entry.path}/online');
        if (!type.existsSync() || !online.existsSync()) continue;
        final value = type.readAsStringSync().trim();
        if (value == 'Mains' || value == 'USB' || value == 'USB_C') {
          foundExternalSupply = true;
          if (online.readAsStringSync().trim() == '1') return true;
        }
      }
      return foundExternalSupply ? false : null;
    } on Object {
      return null;
    }
  }

  return <String, Object?>{
    'timestamp_utc': DateTime.now().toUtc().toIso8601String(),
    'dart_version': Platform.version,
    'aot_product_mode': const bool.fromEnvironment('dart.vm.product'),
    'operating_system': Platform.operatingSystem,
    'operating_system_version': Platform.operatingSystemVersion,
    'cpu_model': cpuModel(),
    'processors': Platform.numberOfProcessors,
    'cpu_governors': cpuGovernors(),
    'ac_online': acOnline(),
    'maximum_hardware_temperature_celsius_after_run':
        maximumHardwareTemperatureCelsius(),
    'git_revision': command('git', const <String>['rev-parse', 'HEAD']),
    'git_dirty_tracked': command('git', const <String>[
      'status',
      '--porcelain',
      '--untracked-files=no',
    ]).isNotEmpty,
    'samples': options.samples,
    'warmup_ms': options.warmupMs,
    'target_sample_ms': options.sampleMs,
  };
}

void _printHumanReport(Map<String, Object?> report, List<_Result> results) {
  final metadata = report['metadata']! as Map<String, Object?>;
  stdout
    ..writeln('Ultraviolet performance baseline')
    ..writeln('  Dart: ${('${metadata['dart_version']}').split('\n').first}')
    ..writeln(
      '  CPU:  ${metadata['cpu_model']} (${metadata['processors']} logical)',
    )
    ..writeln(
      '  Power: governor=${metadata['cpu_governors']} '
      'AC=${metadata['ac_online']} '
      'max temp after run=${metadata['maximum_hardware_temperature_celsius_after_run']} C',
    )
    ..writeln(
      '  Mode: ${metadata['aot_product_mode'] == true ? 'AOT product' : 'JIT'}',
    )
    ..writeln(
      '  Git:  ${metadata['git_revision']}${metadata['git_dirty_tracked'] == true ? ' (dirty)' : ''}',
    )
    ..writeln(
      '  Samples: ${metadata['samples']} x ~${metadata['target_sample_ms']}ms after ${metadata['warmup_ms']}ms warmup',
    )
    ..writeln('');

  for (final result in results) {
    final median = _formatDuration(result.medianNs);
    final p95 = _formatDuration(result.p95Ns);
    final throughput = _formatRate(1e9 / result.medianNs);
    stdout.writeln(
      '${result.name.padRight(42)} $median/${result.unit}  '
      '$throughput ${result.unit}s/s  p95 $p95  CV ${result.cvPercent.toStringAsFixed(2)}%',
    );
  }
  final noisy = results
      .where((result) => result.cvPercent > 5)
      .map((result) => result.name)
      .toList(growable: false);
  if (noisy.isNotEmpty) {
    stdout.writeln(
      '\nWARNING: CV exceeded 5% for ${noisy.join(', ')}; rerun before '
      'using these values as a performance gate.',
    );
  }
  final temperature =
      metadata['maximum_hardware_temperature_celsius_after_run'];
  if (temperature is num && temperature >= 90) {
    stdout.writeln(
      'WARNING: maximum hardware temperature reached $temperature C; '
      'thermal throttling may invalidate comparisons.',
    );
  }
  stdout.writeln('\nChecksum: ${report['checksum']}');
}

String _formatDuration(double nanoseconds) {
  if (nanoseconds >= 1e6) return '${(nanoseconds / 1e6).toStringAsFixed(2)} ms';
  if (nanoseconds >= 1e3) return '${(nanoseconds / 1e3).toStringAsFixed(2)} us';
  return '${nanoseconds.toStringAsFixed(1)} ns';
}

String _formatRate(double value) {
  if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}G';
  if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
  if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
  return value.toStringAsFixed(2);
}

int _mix(int a, int b) => ((a * 0x1fffffff) ^ b) & 0x7fffffffffffffff;

final class _CountingSink implements StringSink {
  int codeUnitsWritten = 0;

  @override
  void write(Object? object) {
    codeUnitsWritten += '$object'.length;
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    var first = true;
    for (final object in objects) {
      if (!first) codeUnitsWritten += separator.length;
      write(object);
      first = false;
    }
  }

  @override
  void writeCharCode(int charCode) {
    codeUnitsWritten++;
  }

  @override
  void writeln([Object? object = '']) {
    write(object);
    codeUnitsWritten++;
  }
}

final class _Benchmark {
  const _Benchmark({
    required this.name,
    required this.unit,
    required this.operationsPerBatch,
    required this.context,
    required this.runBatch,
  });

  final String name;
  final String unit;
  final int operationsPerBatch;
  final Map<String, Object?> context;
  final int Function() runBatch;
}

final class _Result {
  const _Result({
    required this.name,
    required this.unit,
    required this.context,
    required this.samplesNsPerOperation,
    required this.batchesPerSample,
    required this.medianNs,
    required this.p95Ns,
    required this.madNs,
    required this.meanNs,
    required this.cvPercent,
    required this.checksum,
  });

  factory _Result.fromSamples({
    required _Benchmark benchmark,
    required List<double> samplesNsPerOperation,
    required int batchesPerSample,
    required int checksum,
  }) {
    final sorted = List<double>.of(samplesNsPerOperation)..sort();
    final median = _percentile(sorted, 0.5);
    final deviations = sorted.map((value) => (value - median).abs()).toList()
      ..sort();
    final mean = sorted.reduce((a, b) => a + b) / sorted.length;
    var squaredDifference = 0.0;
    for (final value in sorted) {
      squaredDifference += (value - mean) * (value - mean);
    }
    final standardDeviation = math.sqrt(squaredDifference / sorted.length);
    return _Result(
      name: benchmark.name,
      unit: benchmark.unit,
      context: benchmark.context,
      samplesNsPerOperation: samplesNsPerOperation,
      batchesPerSample: batchesPerSample,
      medianNs: median,
      p95Ns: _percentile(sorted, 0.95),
      madNs: _percentile(deviations, 0.5),
      meanNs: mean,
      cvPercent: mean == 0 ? 0 : standardDeviation / mean * 100,
      checksum: checksum,
    );
  }

  final String name;
  final String unit;
  final Map<String, Object?> context;
  final List<double> samplesNsPerOperation;
  final int batchesPerSample;
  final double medianNs;
  final double p95Ns;
  final double madNs;
  final double meanNs;
  final double cvPercent;
  final int checksum;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'unit': unit,
    'context': context,
    'batches_per_sample': batchesPerSample,
    'median_ns_per_operation': medianNs,
    'p95_ns_per_operation': p95Ns,
    'mad_ns_per_operation': madNs,
    'mean_ns_per_operation': meanNs,
    'coefficient_of_variation_percent': cvPercent,
    'operations_per_second': 1e9 / medianNs,
    'samples_ns_per_operation': samplesNsPerOperation,
    'checksum': checksum,
  };
}

double _percentile(List<double> sorted, double percentile) {
  if (sorted.length == 1) return sorted.single;
  final position = (sorted.length - 1) * percentile;
  final lower = position.floor();
  final upper = position.ceil();
  if (lower == upper) return sorted[lower];
  final fraction = position - lower;
  return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
}

final class _Options {
  const _Options({
    required this.samples,
    required this.warmupMs,
    required this.sampleMs,
    required this.json,
    required this.only,
  });

  factory _Options.parse(List<String> arguments) {
    var samples = 15;
    var warmupMs = 750;
    var sampleMs = 200;
    var json = false;
    String? only;

    for (final argument in arguments) {
      if (argument == '--json') {
        json = true;
      } else if (argument.startsWith('--samples=')) {
        samples = int.parse(argument.substring('--samples='.length));
      } else if (argument.startsWith('--warmup-ms=')) {
        warmupMs = int.parse(argument.substring('--warmup-ms='.length));
      } else if (argument.startsWith('--sample-ms=')) {
        sampleMs = int.parse(argument.substring('--sample-ms='.length));
      } else if (argument.startsWith('--only=')) {
        only = argument.substring('--only='.length);
      } else if (argument == '--help' || argument == '-h') {
        stdout.writeln(
          'Usage: baseline [--json] [--only=substring] [--samples=15] '
          '[--warmup-ms=750] [--sample-ms=200]',
        );
        exit(0);
      } else {
        stderr.writeln('Unknown argument: $argument');
        exit(64);
      }
    }

    if (samples < 3 || warmupMs < 0 || sampleMs < 10) {
      stderr.writeln('Use samples >= 3, warmup-ms >= 0, and sample-ms >= 10.');
      exit(64);
    }
    return _Options(
      samples: samples,
      warmupMs: warmupMs,
      sampleMs: sampleMs,
      json: json,
      only: only,
    );
  }

  final int samples;
  final int warmupMs;
  final int sampleMs;
  final bool json;
  final String? only;
}
