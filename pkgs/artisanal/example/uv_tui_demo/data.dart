library;

import 'dart:math' as math;

final _rng = math.Random();

// ─────────────────────────────────────────────────────────────────────────────
// Telemetry
// ─────────────────────────────────────────────────────────────────────────────

final class SparkSeries {
  const SparkSeries({required this.values, required this.maxSamples});

  factory SparkSeries.seed(double value, {int maxSamples = 48}) {
    return SparkSeries(values: [value], maxSamples: maxSamples);
  }

  final List<double> values;
  final int maxSamples;

  SparkSeries push(double value) {
    final next = [...values, value];
    if (next.length > maxSamples) {
      next.removeRange(0, next.length - maxSamples);
    }
    return SparkSeries(values: next, maxSamples: maxSamples);
  }
}

final class TelemetryState {
  const TelemetryState({
    required this.cpu,
    required this.memory,
    required this.gpu,
    required this.netIn,
    required this.netOut,
    required this.temperature,
    required this.cpuSeries,
    required this.memorySeries,
    required this.netSeries,
    required this.tempSeries,
  });

  factory TelemetryState.initial() {
    return TelemetryState(
      cpu: 42,
      memory: 63,
      gpu: 38,
      netIn: 420,
      netOut: 260,
      temperature: 64,
      cpuSeries: SparkSeries.seed(42),
      memorySeries: SparkSeries.seed(63),
      netSeries: SparkSeries.seed(42),
      tempSeries: SparkSeries.seed(64),
    );
  }

  final double cpu;
  final double memory;
  final double gpu;
  final double netIn;
  final double netOut;
  final double temperature;
  final SparkSeries cpuSeries;
  final SparkSeries memorySeries;
  final SparkSeries netSeries;
  final SparkSeries tempSeries;

  TelemetryState evolve() {
    final nextCpu = _drift(cpu, 3.6, 8, 98);
    final nextMem = _drift(memory, 2.1, 30, 96);
    final nextGpu = _drift(gpu, 4.2, 5, 99);
    final nextNetIn = _drift(netIn, 60, 20, 980);
    final nextNetOut = _drift(netOut, 45, 10, 820);
    final nextTemp = _drift(temperature, 1.4, 48, 96);

    return TelemetryState(
      cpu: nextCpu,
      memory: nextMem,
      gpu: nextGpu,
      netIn: nextNetIn,
      netOut: nextNetOut,
      temperature: nextTemp,
      cpuSeries: cpuSeries.push(nextCpu),
      memorySeries: memorySeries.push(nextMem),
      netSeries: netSeries.push(nextNetIn),
      tempSeries: tempSeries.push(nextTemp),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Charts
// ─────────────────────────────────────────────────────────────────────────────

final class HeatmapState {
  const HeatmapState({
    required this.width,
    required this.height,
    required this.cells,
  });

  factory HeatmapState.seed(int width, int height) {
    final cells = List<double>.generate(
      width * height,
      (_) => _rng.nextDouble().clamp(0, 1),
      growable: false,
    );
    return HeatmapState(width: width, height: height, cells: cells);
  }

  final int width;
  final int height;
  final List<double> cells;

  List<List<double>> get grid {
    if (width <= 0 || height <= 0) return const [];
    final rows = <List<double>>[];
    for (var y = 0; y < height; y++) {
      final row = cells.sublist(y * width, (y + 1) * width);
      rows.add(row);
    }
    return rows;
  }

  HeatmapState evolve({double jitter = 0.12}) {
    final next = List<double>.generate(cells.length, (i) {
      final value = cells[i];
      final drifted = _drift(value, jitter, 0, 1);
      return drifted;
    }, growable: false);

    return HeatmapState(width: width, height: height, cells: next);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Services + Pipeline
// ─────────────────────────────────────────────────────────────────────────────

enum ServiceStatus { online, warming, degraded, offline }

enum LogLevel { trace, info, success, warning, error }

final class ServiceNode {
  const ServiceNode({
    required this.id,
    required this.name,
    required this.region,
    required this.status,
    required this.cpu,
    required this.memory,
    required this.latency,
    required this.traffic,
    required this.errors,
    required this.uptimeHours,
  });

  final String id;
  final String name;
  final String region;
  final ServiceStatus status;
  final double cpu;
  final double memory;
  final double latency;
  final double traffic;
  final int errors;
  final int uptimeHours;

  ServiceNode evolve() {
    final nextCpu = _drift(cpu, 6, 0, 100);
    final nextMem = _drift(memory, 3, 10, 98);
    final nextLatency = _drift(latency, 18, 8, 320);
    final nextTraffic = _drift(traffic, 45, 50, 980);
    final nextErrors = (errors + _rng.nextInt(3) - 1).clamp(0, 120);

    final statusShift = _rng.nextDouble();
    final nextStatus = switch (status) {
      ServiceStatus.online when statusShift < 0.03 => ServiceStatus.warming,
      ServiceStatus.warming when statusShift < 0.2 => ServiceStatus.online,
      ServiceStatus.warming when statusShift > 0.94 => ServiceStatus.degraded,
      ServiceStatus.degraded when statusShift < 0.4 => ServiceStatus.warming,
      ServiceStatus.degraded when statusShift > 0.95 => ServiceStatus.offline,
      ServiceStatus.offline when statusShift < 0.4 => ServiceStatus.warming,
      _ => status,
    };

    return ServiceNode(
      id: id,
      name: name,
      region: region,
      status: nextStatus,
      cpu: nextCpu,
      memory: nextMem,
      latency: nextLatency,
      traffic: nextTraffic,
      errors: nextErrors,
      uptimeHours: uptimeHours + (status == ServiceStatus.offline ? 0 : 1),
    );
  }
}

final class PipelineState {
  const PipelineState({
    required this.stages,
    required this.stageIndex,
    required this.progress,
  });

  factory PipelineState.initial() {
    return const PipelineState(
      stages: [
        'Preflight',
        'Snapshot',
        'Shard Fusion',
        'UV Raster',
        'Checksums',
        'Deploy',
      ],
      stageIndex: 0,
      progress: 0.08,
    );
  }

  final List<String> stages;
  final int stageIndex;
  final double progress;

  PipelineState advance() {
    final bump = 0.015 + _rng.nextDouble() * 0.02;
    var next = progress + bump;
    var nextStage = stageIndex;
    if (next >= 1) {
      next = 0.02 + _rng.nextDouble() * 0.08;
      nextStage = (stageIndex + 1) % stages.length;
    }
    return PipelineState(stages: stages, stageIndex: nextStage, progress: next);
  }
}

final class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.source,
    required this.message,
  });

  final DateTime time;
  final LogLevel level;
  final String source;
  final String message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Topology
// ─────────────────────────────────────────────────────────────────────────────

final class TopologyNode {
  const TopologyNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
  });

  final String id;
  final String label;
  final double x;
  final double y;
}

final class TopologyLink {
  const TopologyLink({required this.from, required this.to});

  final int from;
  final int to;
}

final class TopologyLayout {
  const TopologyLayout({required this.nodes, required this.links});

  final List<TopologyNode> nodes;
  final List<TopologyLink> links;
}

TopologyLayout generateTopology({int nodes = 9}) {
  final center = TopologyNode(id: 'core', label: 'CORE', x: 0.5, y: 0.45);
  final ring = <TopologyNode>[];
  for (var i = 0; i < nodes; i++) {
    final angle = (math.pi * 2 / nodes) * i;
    final radius = 0.35 + (_rng.nextDouble() * 0.08);
    ring.add(
      TopologyNode(
        id: 'n$i',
        label: 'N${i + 1}',
        x: 0.5 + math.cos(angle) * radius,
        y: 0.45 + math.sin(angle) * radius,
      ),
    );
  }

  final allNodes = [center, ...ring];
  final links = <TopologyLink>[];
  for (var i = 1; i < allNodes.length; i++) {
    links.add(TopologyLink(from: 0, to: i));
    if (i > 1) {
      links.add(TopologyLink(from: i - 1, to: i));
    }
  }
  links.add(TopologyLink(from: allNodes.length - 1, to: 1));

  return TopologyLayout(nodes: allNodes, links: links);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data generators
// ─────────────────────────────────────────────────────────────────────────────

List<ServiceNode> generateServices() {
  const regions = ['us-east', 'us-west', 'eu-north', 'ap-south'];
  return List<ServiceNode>.generate(9, (i) {
    final status =
        ServiceStatus.values[_rng.nextInt(ServiceStatus.values.length)];
    return ServiceNode(
      id: 'svc-$i',
      name: 'edge-${i + 1}'.padLeft(6, '0'),
      region: regions[i % regions.length],
      status: status,
      cpu: 10 + _rng.nextDouble() * 80,
      memory: 20 + _rng.nextDouble() * 70,
      latency: 20 + _rng.nextDouble() * 180,
      traffic: 120 + _rng.nextDouble() * 800,
      errors: _rng.nextInt(8),
      uptimeHours: 4 + _rng.nextInt(240),
    );
  });
}

LogEntry randomLog(List<ServiceNode> nodes) {
  final node = nodes[_rng.nextInt(nodes.length)];
  final roll = _rng.nextDouble();
  final level = switch (roll) {
    < 0.1 => LogLevel.error,
    < 0.25 => LogLevel.warning,
    < 0.55 => LogLevel.info,
    < 0.8 => LogLevel.success,
    _ => LogLevel.trace,
  };

  final message = switch (level) {
    LogLevel.error => _errorMessages[_rng.nextInt(_errorMessages.length)],
    LogLevel.warning => _warningMessages[_rng.nextInt(_warningMessages.length)],
    LogLevel.success => _successMessages[_rng.nextInt(_successMessages.length)],
    LogLevel.trace => _traceMessages[_rng.nextInt(_traceMessages.length)],
    LogLevel.info => _infoMessages[_rng.nextInt(_infoMessages.length)],
  };

  return LogEntry(
    time: DateTime.now(),
    level: level,
    source: node.name,
    message: message,
  );
}

const _infoMessages = [
  'replication window aligned',
  'shard map reconciled',
  'cache warm sweep complete',
  'ingest cadence synchronized',
  'fabric lattice stabilized',
  'priority queue drained',
];

const _successMessages = [
  'packet burst routed cleanly',
  'latency budget reclaimed',
  'consensus reached in 12ms',
  'autoscaler settled',
  'uplink authenticated',
];

const _warningMessages = [
  'cold node detected, rerouting',
  'throttle guard engaged',
  'entropy spike on mesh',
  'retry burst on shard 7',
  'disk queue pressure rising',
];

const _errorMessages = [
  'decoder drift beyond threshold',
  'packet loss on uplink',
  'event horizon checksum failed',
  'quota wall breached',
  'orchestrator missed heartbeat',
];

const _traceMessages = [
  'trace: warp pulse 0x12f',
  'trace: voltage ridge 5.2v',
  'trace: uv buffer swap 4.8ms',
  'trace: heatmap sample ok',
  'trace: path resolver delta',
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

double _drift(double value, double delta, double min, double max) {
  final change = (_rng.nextDouble() * 2 - 1) * delta;
  final next = value + change;
  return next.clamp(min, max).toDouble();
}
