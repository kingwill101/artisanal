import 'dart:collection';

enum FlutterCliLogLevel { trace, debug, info, warn, error }

enum FlutterCliConnectionKind { usb, wifi }

enum FlutterCliSessionState { connecting, reloading, ready, stopped, failed }

enum FlutterCliBannerKind { info, warn, error, success }

enum FlutterCliDeviceState { online, offline, unauthorized, connecting }

enum FlutterCliBuildMode { debug, profile, release }

enum FlutterCliStepStatus { running, done, failed }

enum FlutterCliTestResult { success, failure, error, skipped }

enum FlutterCliScrollFocus { tests, failures }

enum FlutterCliTestBannerKind { success, info }

sealed class FlutterCliFlutterEvent {
  const FlutterCliFlutterEvent();
}

final class FlutterCliProgressEvent extends FlutterCliFlutterEvent {
  const FlutterCliProgressEvent({
    required this.id,
    required this.message,
    this.finished = false,
  });

  final String id;
  final String message;
  final bool finished;
}

final class FlutterCliBuildLogEvent extends FlutterCliFlutterEvent {
  const FlutterCliBuildLogEvent(this.level, this.message);

  final FlutterCliLogLevel level;
  final String message;
}

final class FlutterCliStoppedEvent extends FlutterCliFlutterEvent {
  const FlutterCliStoppedEvent(this.exitCode);

  final int? exitCode;
}

sealed class FlutterCliTestEvent {
  const FlutterCliTestEvent();
}

final class FlutterCliTestStarted extends FlutterCliTestEvent {
  const FlutterCliTestStarted({required this.id, required this.name});

  final int id;
  final String name;
}

final class FlutterCliTestDone extends FlutterCliTestEvent {
  const FlutterCliTestDone({
    required this.id,
    required this.name,
    required this.result,
    required this.durationMs,
  });

  final int id;
  final String name;
  final FlutterCliTestResult result;
  final int durationMs;
}

final class FlutterCliTestError extends FlutterCliTestEvent {
  const FlutterCliTestError({this.id, required this.message, this.stack});

  final int? id;
  final String message;
  final String? stack;
}

final class FlutterCliAllDone extends FlutterCliTestEvent {
  const FlutterCliAllDone({required this.success});

  final bool success;
}

final class FlutterCliSession {
  FlutterCliSession({
    required this.serial,
    required this.shortName,
    required this.displayName,
    required this.connection,
    required this.state,
    this.platform,
    this.ip,
  });

  final String serial;
  final String shortName;
  String displayName;
  FlutterCliConnectionKind connection;
  FlutterCliSessionState state;
  String? platform;
  String? ip;
}

final class FlutterCliDevice {
  FlutterCliDevice({
    required this.serial,
    required this.name,
    required this.connection,
    required this.state,
    this.model,
    this.ip,
    this.androidVersion,
    this.battery,
    this.platform,
  });

  final String serial;
  final String name;
  final FlutterCliConnectionKind connection;
  final FlutterCliDeviceState state;
  final String? model;
  final String? ip;
  final String? androidVersion;
  final int? battery;
  final String? platform;
}

final class FlutterCliLogLine {
  const FlutterCliLogLine(this.level, this.message);

  final FlutterCliLogLevel level;
  final String message;
}

final class FlutterCliPerf {
  FlutterCliPerf({
    Iterable<double> fps = const [],
    Iterable<double> memory = const [],
    this.frameUiMs = 0,
    this.frameRasterMs = 0,
    this.heapCapacityMb = 0,
  }) : fpsSamples = ListQueue<double>.from(fps),
       memSamples = ListQueue<double>.from(memory);

  final ListQueue<double> fpsSamples;
  final ListQueue<double> memSamples;
  double frameUiMs;
  double frameRasterMs;
  double heapCapacityMb;
}

final class FlutterCliNetworkRequest {
  const FlutterCliNetworkRequest({
    required this.device,
    required this.method,
    required this.url,
    this.status,
    this.durationMs,
    this.error,
  });

  final String device;
  final String method;
  final String url;
  final int? status;
  final int? durationMs;
  final String? error;
}

final class FlutterCliProgressPhase {
  FlutterCliProgressPhase({
    required this.id,
    required this.message,
    required this.startedAt,
    this.finishedAt,
    this.xcodeSubSteps = 0,
  });

  final String id;
  final String message;
  final DateTime startedAt;
  DateTime? finishedAt;
  int xcodeSubSteps;
}

final class FlutterCliBanner {
  const FlutterCliBanner({
    required this.kind,
    required this.message,
    this.persistent = false,
  });

  final FlutterCliBannerKind kind;
  final String message;
  final bool persistent;
}

final class FlutterCliBuildStep {
  FlutterCliBuildStep({
    required this.id,
    required this.message,
    required this.status,
    required this.startedAt,
    this.finishedAt,
  });

  final String id;
  String message;
  FlutterCliStepStatus status;
  final DateTime startedAt;
  DateTime? finishedAt;
}

final class FlutterCliTestFailure {
  const FlutterCliTestFailure({
    required this.name,
    required this.message,
    this.stack,
  });

  final String name;
  final String message;
  final String? stack;
}

final class FlutterCliTestBanner {
  const FlutterCliTestBanner({
    required this.kind,
    required this.message,
    required this.shownAt,
    this.duration = const Duration(milliseconds: 2500),
  });

  final FlutterCliTestBannerKind kind;
  final String message;
  final DateTime shownAt;
  final Duration duration;
}

final class FlutterCliState {
  FlutterCliState({
    required this.appName,
    required this.mode,
    required this.startedAt,
    Iterable<FlutterCliSession> sessions = const [],
    Iterable<FlutterCliLogLine> logs = const [],
    Iterable<double> fps = const [],
    Iterable<double> memory = const [],
    Iterable<FlutterCliProgressPhase> phases = const [],
    Iterable<FlutterCliNetworkRequest> network = const [],
    Map<String, FlutterCliPerf> devicePerf = const {},
    this.frameUiMs = 0,
    this.frameRasterMs = 0,
    this.heapCapacityMb = 0,
    this.vmConnected = false,
    this.compileFinished,
    this.showNetwork = false,
    this.banner,
  }) : activeSessions = sessions.toList(),
       logs = ListQueue<FlutterCliLogLine>.from(logs),
       fpsSamples = ListQueue<double>.from(fps),
       memSamples = ListQueue<double>.from(memory),
       progressPhases = phases.toList(),
       networkRequests = ListQueue<FlutterCliNetworkRequest>.from(network),
       devicePerf = Map<String, FlutterCliPerf>.from(devicePerf);

  factory FlutterCliState.demo({bool ready = true}) {
    final now = DateTime.now();
    final fps = <double>[58, 60, 59, 44, 48, 61, 57, 55, 60, 58, 52, 49];
    final mem = <double>[98, 104, 117, 128, 134, 142, 139, 151, 148, 156];
    return FlutterCliState(
      appName: 'wonderous',
      mode: 'debug',
      startedAt: now.subtract(const Duration(seconds: 83)),
      sessions: [
        FlutterCliSession(
          serial: '00008110-001C5D083A91801E',
          shortName: '00008110',
          displayName: 'iPhone 15 Pro',
          connection: FlutterCliConnectionKind.usb,
          state: FlutterCliSessionState.ready,
          platform: 'ios',
        ),
        FlutterCliSession(
          serial: 'emulator-5554',
          shortName: 'emulator',
          displayName: 'Pixel 8 API 35',
          connection: FlutterCliConnectionKind.wifi,
          state: FlutterCliSessionState.reloading,
          platform: 'android-arm64',
          ip: '192.168.1.42',
        ),
      ],
      logs: const [
        FlutterCliLogLine(FlutterCliLogLevel.info, 'Launching lib/main.dart'),
        FlutterCliLogLine(FlutterCliLogLevel.debug, 'Running Xcode build...'),
        FlutterCliLogLine(FlutterCliLogLevel.info, 'App started - build done'),
      ],
      fps: fps,
      memory: mem,
      frameUiMs: 7.4,
      frameRasterMs: 6.1,
      heapCapacityMb: 256,
      phases: [
        FlutterCliProgressPhase(
          id: '1',
          message: 'Resolving dependencies',
          startedAt: now.subtract(const Duration(seconds: 80)),
          finishedAt: now.subtract(const Duration(seconds: 76)),
        ),
        FlutterCliProgressPhase(
          id: '2',
          message: 'Running Xcode build...',
          startedAt: now.subtract(const Duration(seconds: 76)),
          xcodeSubSteps: 88,
        ),
      ],
      network: const [
        FlutterCliNetworkRequest(
          device: 'iPhone',
          method: 'GET',
          url: 'https://api.example.dev/feed?cursor=latest',
          status: 200,
          durationMs: 84,
        ),
        FlutterCliNetworkRequest(
          device: 'Pixel',
          method: 'POST',
          url: 'https://api.example.dev/session/refresh',
          status: 204,
          durationMs: 121,
        ),
        FlutterCliNetworkRequest(
          device: 'iPhone',
          method: 'GET',
          url: 'https://cdn.example.dev/images/hero.png',
          status: 404,
          durationMs: 32,
        ),
      ],
      devicePerf: {
        '00008110-001C5D083A91801E': FlutterCliPerf(
          fps: fps,
          memory: mem,
          frameUiMs: 7.4,
          frameRasterMs: 6.1,
          heapCapacityMb: 256,
        ),
        'emulator-5554': FlutterCliPerf(
          fps: const [44, 48, 52, 58, 60, 57, 49, 51],
          memory: const [120, 124, 131, 140, 138, 145],
          frameUiMs: 8.8,
          frameRasterMs: 9.2,
          heapCapacityMb: 256,
        ),
      },
      vmConnected: ready,
      compileFinished: ready ? const Duration(seconds: 71) : null,
      banner: const FlutterCliBanner(
        kind: FlutterCliBannerKind.success,
        message: 'Hot reload complete',
      ),
    );
  }

  final String appName;
  final String mode;
  final DateTime startedAt;
  final List<FlutterCliSession> activeSessions;
  final ListQueue<FlutterCliLogLine> logs;
  final ListQueue<double> fpsSamples;
  final ListQueue<double> memSamples;
  final Map<String, FlutterCliPerf> devicePerf;
  final List<FlutterCliProgressPhase> progressPhases;
  final ListQueue<FlutterCliNetworkRequest> networkRequests;
  double frameUiMs;
  double frameRasterMs;
  double heapCapacityMb;
  bool vmConnected;
  Duration? compileFinished;
  bool showNetwork;
  FlutterCliBanner? banner;

  bool get appReady => vmConnected;

  Duration get elapsed =>
      compileFinished ?? DateTime.now().difference(startedAt);
}
