// ignore_for_file: unused_element

import 'dart:async';
import 'dart:math' as math;

import 'key.dart';
import 'msg.dart';
import 'program.dart';
import 'evidence.dart';
import 'render_recorder.dart';
import 'trace.dart';

/// Screen metadata captured for replay coordinate scaling.
final class ReplayScreen {
  const ReplayScreen({
    this.width = 0,
    this.height = 0,
    this.fixedRightWidth = 0,
  });

  final int width;
  final int height;
  final int fixedRightWidth;

  factory ReplayScreen.fromJson(Map<String, dynamic> json) {
    return ReplayScreen(
      width: (json['width'] as int?) ?? 0,
      height: (json['height'] as int?) ?? 0,
      fixedRightWidth:
          (json['fixedRightWidth'] as int?) ??
          (json['rightFixedWidth'] as int?) ??
          0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'width': width,
      'height': height,
      'fixedRightWidth': fixedRightWidth,
    };
  }
}

/// Structured custom event embedded in replay actions.
final class ReplayCustomEvent {
  const ReplayCustomEvent({
    required this.type,
    this.fields = const <String, Object?>{},
  });

  /// Event type, usually copied from `TuiTrace.event(type: ...)`.
  final String type;

  /// Event payload fields.
  final Map<String, Object?> fields;

  /// Whether this event carries a runtime render-capture payload.
  bool get isRenderCapture =>
      type == 'runtime.render_capture' &&
      fields['recordType'] == 'runtime.render' &&
      fields['decisionType'] == 'render_capture';

  /// Decodes the embedded render-capture payload when this event carries one.
  ProgramRenderCapturePayload? get renderCapturePayload {
    if (!isRenderCapture) return null;
    return ProgramRenderCapturePayload.fromJson(fields);
  }

  /// Typed render-capture inspector when this event carries one.
  ReplayRenderCaptureEvent? get renderCapture {
    final payload = renderCapturePayload;
    if (payload == null) return null;
    return ReplayRenderCaptureEvent(event: this, payload: payload);
  }

  /// Shared presentation model for replay/debug consumers.
  ReplayEventPresentation get presentation =>
      renderCapture?.presentation ?? ReplayEventPresentation.generic(this);
}

/// Shared replay-event summary for debug UIs and status surfaces.
final class ReplayEventPresentation {
  /// Creates a replay-event presentation model.
  const ReplayEventPresentation({
    required this.summary,
    required this.statusHint,
    required this.fields,
    this.detailLines = const <String>[],
  });

  /// Human-readable one-line summary.
  final String summary;

  /// Compact footer/status-bar hint.
  final String statusHint;

  /// Structured fields useful for logging or event inspection.
  final Map<String, Object?> fields;

  /// Optional detailed lines for richer debug UIs.
  final List<String> detailLines;

  /// Generic presentation for non-render-capture replay events.
  factory ReplayEventPresentation.generic(ReplayCustomEvent event) {
    return ReplayEventPresentation(
      summary: 'replay event -> ${event.type}',
      statusHint: '/replay ${event.type}',
      fields: <String, Object?>{'type': event.type, 'fields': event.fields},
      detailLines: <String>['event: ${event.type}'],
    );
  }
}

/// Typed replay-side view of one `runtime.render_capture` custom event.
final class ReplayRenderCaptureEvent {
  /// Creates a typed replay render-capture event view.
  const ReplayRenderCaptureEvent({required this.event, required this.payload});

  /// Original replay custom event.
  final ReplayCustomEvent event;

  /// Decoded structured capture payload.
  final ProgramRenderCapturePayload payload;

  /// Run identifier propagated from evidence, when present.
  String? get runId => event.fields['runId'] as String?;

  /// Source record type, usually `runtime.render`.
  String? get recordType => event.fields['recordType'] as String?;

  /// Evidence decision type, usually `render_capture`.
  String? get decisionType => event.fields['decisionType'] as String?;

  /// Evidence result label, usually `captured`.
  String? get result => event.fields['result'] as String?;

  /// Shared presentation model for replay/debug consumers.
  ReplayEventPresentation get presentation {
    final summaryModel = payload.lastSnapshotSummary;
    final generation = summaryModel?.renderGeneration;
    final width = summaryModel?.width ?? payload.report.lastWidth;
    final height = summaryModel?.height ?? payload.report.lastHeight;
    final changes =
        summaryModel?.changeSummary ?? payload.stats.lastChangeSummary;

    final summaryParts = <String>['render capture'];
    if (generation != null) {
      summaryParts.add('g$generation');
    }
    if (width != null && height != null) {
      summaryParts.add('${width}x$height');
    }
    if (changes != null) {
      summaryParts.add('cells ${changes.changedCellCount}');
      summaryParts.add('spans ${changes.changedSpanCount}');
    }

    final statusParts = <String>['/replay'];
    if (generation != null) {
      statusParts.add('g$generation');
    }
    if (width != null && height != null) {
      statusParts.add('${width}x$height');
    }
    if (changes != null) {
      statusParts.add('c${changes.changedCellCount}');
      statusParts.add('s${changes.changedSpanCount}');
    }

    return ReplayEventPresentation(
      summary: summaryParts.join(' '),
      statusHint: statusParts.join(' '),
      fields: <String, Object?>{
        'type': event.type,
        if (recordType != null) 'recordType': recordType,
        if (decisionType != null) 'decisionType': decisionType,
        if (result != null) 'result': result,
        if (generation != null) 'renderGeneration': generation,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (changes != null) 'changeSummary': changes.toJson(),
      },
      detailLines: toLines(),
    );
  }

  /// Compact metric lines suitable for replay/debug UIs.
  List<String> toLines({String? prefix}) {
    final effectivePrefix = prefix ?? payload.report.prefix;
    final lines = <String>[
      '$effectivePrefix event: ${event.type}',
      if (recordType != null || decisionType != null || result != null)
        '$effectivePrefix source: '
            '${recordType ?? 'unknown'} / ${decisionType ?? 'unknown'} / ${result ?? 'unknown'}',
      ...payload.report.toLines(),
    ];
    return List<String>.unmodifiable(lines);
  }
}

/// Replay control decision for a custom replay event.
enum ReplayEventControl {
  /// Keep replay running.
  proceed,

  /// Stop replay immediately without forcing quit.
  stop,

  /// Emit a quit message and stop replay.
  quit,
}

/// Hook decision produced for [ReplayCustomEvent] actions.
final class ReplayEventDirective {
  const ReplayEventDirective._({
    this.messages = const <Msg>[],
    this.delay = Duration.zero,
    this.control = ReplayEventControl.proceed,
  });

  /// Continue replay without changes.
  static const ReplayEventDirective proceed = ReplayEventDirective._();

  /// Optional messages to inject when this event is encountered.
  final List<Msg> messages;

  /// Optional delay to apply before [messages] are emitted.
  final Duration delay;

  /// Replay control after emitting [messages].
  final ReplayEventControl control;

  /// Continue replay and emit [messages].
  factory ReplayEventDirective.emit(
    Iterable<Msg> messages, {
    Duration delay = Duration.zero,
  }) {
    return ReplayEventDirective._(
      messages: messages.toList(growable: false),
      delay: delay,
    );
  }

  /// Stop replay after optionally emitting [messages].
  factory ReplayEventDirective.stop({
    Iterable<Msg> messages = const <Msg>[],
    Duration delay = Duration.zero,
  }) {
    return ReplayEventDirective._(
      messages: messages.toList(growable: false),
      delay: delay,
      control: ReplayEventControl.stop,
    );
  }

  /// Emit [QuitMsg] and stop replay after optionally emitting [messages].
  factory ReplayEventDirective.quit({
    Iterable<Msg> messages = const <Msg>[],
    Duration delay = Duration.zero,
  }) {
    return ReplayEventDirective._(
      messages: messages.toList(growable: false),
      delay: delay,
      control: ReplayEventControl.quit,
    );
  }
}

/// Hook invoked when replay reaches an `event` action.
///
/// Return `null` to use default behavior (emit [ReplayEventMsg]).
typedef ReplayEventHook =
    FutureOr<ReplayEventDirective?> Function(ReplayCustomEvent event);

/// Replay action schema used by TUI scenario JSON files.
final class ReplayAction {
  const ReplayAction({
    required this.type,
    this.repeat = 1,
    this.ms = 0,
    this.value = '',
    this.key = '',
    this.direction = 'down',
    this.x = 0,
    this.y = 0,
    this.x2 = 0,
    this.y2 = 0,
    this.steps = 8,
    this.eventType = '',
    this.eventFields = const <String, Object?>{},
  });

  final String type;
  final int repeat;
  final int ms;
  final String value;
  final String key;
  final String direction;
  final int x;
  final int y;
  final int x2;
  final int y2;
  final int steps;
  final String eventType;
  final Map<String, Object?> eventFields;

  ReplayCustomEvent? get customEvent {
    if (type != 'event') return null;
    final normalizedType = eventType.trim();
    if (normalizedType.isEmpty) return null;
    return ReplayCustomEvent(type: normalizedType, fields: eventFields);
  }

  factory ReplayAction.fromJson(Map<String, dynamic> json) {
    return ReplayAction(
      type: (json['type'] as String? ?? '').trim(),
      repeat: (json['repeat'] as int?) ?? 1,
      ms: (json['ms'] as int?) ?? 0,
      value: (json['value'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      direction: (json['direction'] as String?) ?? 'down',
      x: (json['x'] as int?) ?? 0,
      y: (json['y'] as int?) ?? 0,
      x2: (json['x2'] as int?) ?? (json['x'] as int?) ?? 0,
      y2: (json['y2'] as int?) ?? (json['y'] as int?) ?? 0,
      steps: (json['steps'] as int?) ?? 8,
      eventType: (json['eventType'] as String? ?? '').trim(),
      eventFields: _asJsonObject(json['eventFields']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type,
      if (repeat != 1) 'repeat': repeat,
      if (ms != 0) 'ms': ms,
      if (value.isNotEmpty) 'value': value,
      if (key.isNotEmpty) 'key': key,
      if (direction != 'down') 'direction': direction,
      if (x != 0) 'x': x,
      if (y != 0) 'y': y,
      if (x2 != 0) 'x2': x2,
      if (y2 != 0) 'y2': y2,
      if (steps != 8) 'steps': steps,
      if (eventType.isNotEmpty) 'eventType': eventType,
      if (eventFields.isNotEmpty) 'eventFields': eventFields,
    };
  }

  /// Expands this action into one or more low-level replay messages.
  List<Msg> toMessages() {
    final times = math.max(1, repeat);
    final output = <Msg>[];
    switch (type) {
      case 'text':
        for (var r = 0; r < times; r++) {
          for (final rune in value.runes) {
            output.add(KeyMsg(Key(KeyType.runes, runes: [rune])));
          }
        }
        return output;
      case 'special':
        final parsed = _parseKeyType(key);
        for (var i = 0; i < times; i++) {
          output.add(KeyMsg(Key(parsed)));
        }
        return output;
      case 'wheel':
        final button = _parseWheelButton(direction);
        for (var i = 0; i < times; i++) {
          output.add(
            ReplayMouseMsg(
              action: MouseAction.wheel,
              button: button,
              x: x,
              y: y,
            ),
          );
        }
        return output;
      case 'tap':
        for (var i = 0; i < times; i++) {
          output.add(
            ReplayMouseMsg(
              action: MouseAction.press,
              button: MouseButton.left,
              x: x,
              y: y,
            ),
          );
          output.add(
            ReplayMouseMsg(
              action: MouseAction.release,
              button: MouseButton.left,
              x: x,
              y: y,
            ),
          );
        }
        return output;
      case 'move':
        for (var i = 0; i < times; i++) {
          output.add(
            ReplayMouseMsg(
              action: MouseAction.motion,
              button: MouseButton.none,
              x: x,
              y: y,
            ),
          );
        }
        return output;
      case 'drag':
        final dragSteps = math.max(1, steps);
        for (var r = 0; r < times; r++) {
          output.add(
            ReplayMouseMsg(
              action: MouseAction.press,
              button: MouseButton.left,
              x: x,
              y: y,
            ),
          );
          for (var i = 1; i <= dragSteps; i++) {
            final t = i / dragSteps;
            output.add(
              ReplayMouseMsg(
                action: MouseAction.motion,
                button: MouseButton.left,
                x: x + ((x2 - x) * t).round(),
                y: y + ((y2 - y) * t).round(),
              ),
            );
          }
          output.add(
            ReplayMouseMsg(
              action: MouseAction.release,
              button: MouseButton.left,
              x: x2,
              y: y2,
            ),
          );
        }
        return output;
      case 'event':
        final event = customEvent;
        if (event == null) return const <Msg>[];
        for (var i = 0; i < times; i++) {
          output.add(ReplayEventMsg(event));
        }
        return output;
      default:
        return const <Msg>[];
    }
  }
}

/// Replay scenario document.
final class ReplayScenario {
  const ReplayScenario({
    required this.name,
    required this.actions,
    this.description = '',
    this.screen = const ReplayScreen(),
  });

  final String name;
  final String description;
  final ReplayScreen screen;
  final List<ReplayAction> actions;

  factory ReplayScenario.fromJson(
    Map<String, dynamic> json, {
    String fallbackName = 'replay',
  }) {
    final rawScreen = json['screen'];
    final screen = rawScreen is Map<String, dynamic>
        ? ReplayScreen.fromJson(rawScreen)
        : rawScreen is Map
        ? ReplayScreen.fromJson(Map<String, dynamic>.from(rawScreen))
        : const ReplayScreen();
    final actionsRaw = (json['actions'] as List<dynamic>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
    return ReplayScenario(
      name: (json['name'] as String?) ?? fallbackName,
      description: (json['description'] as String?) ?? '',
      screen: screen,
      actions: actionsRaw.map(ReplayAction.fromJson).toList(growable: false),
    );
  }

  static Future<ReplayScenario> load(String path) async {
    throw UnsupportedError('File I/O is not supported on this platform');
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      if (description.isNotEmpty) 'description': description,
      'screen': screen.toJson(),
      'actions': actions
          .map((action) => action.toJson())
          .toList(growable: false),
    };
  }

  Future<void> save(String path) async {
    throw UnsupportedError('File I/O is not supported on this platform');
  }

  ProgramReplay toProgramReplay({
    bool loop = false,
    bool keepOpen = false,
    double speed = 1.0,
    ReplayEventHook? eventHook,
  }) {
    return ProgramReplay.stream(
      replayScenarioStream(
        actions,
        loop: loop,
        keepOpen: keepOpen,
        speed: speed,
        eventHook: eventHook,
      ),
    );
  }
}

/// Replay-only mouse message marker.
///
/// This message still behaves as [MouseMsg] for model update logic, but can
/// be targeted by [ReplayCoordinateInterceptor] so live terminal mouse input
/// is not scaled.
final class ReplayMouseMsg extends MouseMsg {
  const ReplayMouseMsg({
    required super.action,
    required super.button,
    required super.x,
    required super.y,
    super.ctrl,
    super.alt,
    super.shift,
  });
}

/// Replay message emitted for custom `event` actions.
final class ReplayEventMsg extends Msg {
  const ReplayEventMsg(this.event);

  final ReplayCustomEvent event;
}

/// Coordinate interceptor that scales replay mouse coordinates to current
/// runtime window dimensions.
final class ReplayCoordinateInterceptor extends ProgramInterceptor {
  ReplayCoordinateInterceptor({
    required this.sourceWidth,
    required this.sourceHeight,
    this.sourceRightFixedWidth = 0,
  });

  final int sourceWidth;
  final int sourceHeight;
  final int sourceRightFixedWidth;

  int? _targetWidth;
  int? _targetHeight;

  @override
  Msg? onSend(Msg msg) {
    if (msg is! ReplayMouseMsg) return msg;

    final targetWidth = _targetWidth;
    final targetHeight = _targetHeight;
    final scaledX = sourceWidth > 0 && targetWidth != null && targetWidth > 0
        ? _scaleXCoordinate(msg.x, sourceWidth, targetWidth)
        : msg.x;
    final scaledY = sourceHeight > 0 && targetHeight != null && targetHeight > 0
        ? _scaleCoordinate(msg.y, sourceHeight, targetHeight)
        : msg.y;

    return MouseMsg(
      action: msg.action,
      button: msg.button,
      x: scaledX,
      y: scaledY,
      ctrl: msg.ctrl,
      alt: msg.alt,
      shift: msg.shift,
    );
  }

  @override
  void onProcessed(Msg msg, Duration elapsed) {
    if (msg is WindowSizeMsg) {
      _targetWidth = msg.width;
      _targetHeight = msg.height;
    }
  }

  int _scaleXCoordinate(int value, int sourceExtent, int targetExtent) {
    final fixedRight = sourceRightFixedWidth;
    if (fixedRight <= 0 ||
        fixedRight >= sourceExtent ||
        fixedRight >= targetExtent) {
      return _scaleCoordinate(value, sourceExtent, targetExtent);
    }

    final sourceFlexibleExtent = sourceExtent - fixedRight;
    final targetFlexibleExtent = targetExtent - fixedRight;
    if (sourceFlexibleExtent <= 0 || targetFlexibleExtent <= 0) {
      return _scaleCoordinate(value, sourceExtent, targetExtent);
    }

    if (value < sourceFlexibleExtent) {
      return _scaleCoordinate(
        value,
        sourceFlexibleExtent,
        targetFlexibleExtent,
      );
    }

    final rightOffset = value - sourceFlexibleExtent;
    final anchored = targetFlexibleExtent + rightOffset;
    return anchored.clamp(0, targetExtent - 1);
  }

  int _scaleCoordinate(int value, int sourceExtent, int targetExtent) {
    if (targetExtent <= 0 || sourceExtent <= 0) return value;
    if (sourceExtent == targetExtent) return value.clamp(0, targetExtent - 1);
    if (sourceExtent == 1) return 0;

    final scaled = (value * (targetExtent - 1) / (sourceExtent - 1)).round();
    return scaled.clamp(0, targetExtent - 1);
  }
}

/// Builds a replay message stream from a list of replay actions.
Stream<Msg> replayScenarioStream(
  List<ReplayAction> actions, {
  required bool loop,
  required bool keepOpen,
  required double speed,
  ReplayEventHook? eventHook,
}) async* {
  if (actions.isEmpty) {
    if (!keepOpen && !loop) yield const QuitMsg();
    return;
  }

  Duration pendingDelay = Duration.zero;

  Duration scaled(Duration input) {
    final micros = (input.inMicroseconds / speed).round();
    return Duration(microseconds: math.max(0, micros));
  }

  do {
    for (final action in actions) {
      if (action.type == 'sleep') {
        pendingDelay += scaled(Duration(milliseconds: action.ms));
        continue;
      }

      if (action.type == 'event') {
        if (pendingDelay > Duration.zero) {
          await Future<void>.delayed(pendingDelay);
          pendingDelay = Duration.zero;
        }

        final event = action.customEvent;
        if (event == null) {
          continue;
        }

        final directive =
            await eventHook?.call(event) ??
            ReplayEventDirective.emit(<Msg>[ReplayEventMsg(event)]);

        final hookDelay = scaled(directive.delay);
        if (hookDelay > Duration.zero) {
          await Future<void>.delayed(hookDelay);
        }
        for (final msg in directive.messages) {
          yield msg;
        }
        if (directive.control == ReplayEventControl.quit) {
          yield const QuitMsg();
          return;
        }
        if (directive.control == ReplayEventControl.stop) {
          return;
        }
        continue;
      }

      final events = action.toMessages();
      for (final msg in events) {
        if (pendingDelay > Duration.zero) {
          await Future<void>.delayed(pendingDelay);
          pendingDelay = Duration.zero;
        }
        yield msg;
      }
    }

    if (pendingDelay > Duration.zero) {
      await Future<void>.delayed(pendingDelay);
      pendingDelay = Duration.zero;
    }
  } while (loop);

  if (!keepOpen) {
    yield const QuitMsg();
  }
}

/// Trace conversion options for [ReplayTraceConverter].
final class ReplayTraceConversionOptions {
  const ReplayTraceConversionOptions({
    this.name,
    this.description = 'Generated from trace',
    this.screenWidth = 0,
    this.screenHeight = 0,
    this.fixedRightWidth = 0,
    this.fromUs,
    this.toUs,
    this.minSleepUs = 30000,
    this.includeHoverMoves = false,
    this.includeCustomEvents = true,
  });

  final String? name;
  final String description;
  final int screenWidth;
  final int screenHeight;
  final int fixedRightWidth;
  final int? fromUs;
  final int? toUs;
  final int minSleepUs;
  final bool includeHoverMoves;
  final bool includeCustomEvents;
}

/// Conversion output returned by [ReplayTraceConverter.convertFile].
final class ReplayTraceConversionResult {
  const ReplayTraceConversionResult({
    required this.tracePath,
    required this.scenario,
    required this.eventCount,
    required this.actionCount,
    required this.skippedCount,
    required this.inferredScreenWidth,
    required this.inferredScreenHeight,
  });

  final String tracePath;
  final ReplayScenario scenario;
  final int eventCount;
  final int actionCount;
  final int skippedCount;
  final int inferredScreenWidth;
  final int inferredScreenHeight;
}

/// Converts `TuiTrace` logs into replay scenarios.
final class ReplayTraceConverter {
  static final Map<String, KeyType> _keyTypeByName = <String, KeyType>{
    for (final keyType in KeyType.values) keyType.name: keyType,
  };
  static final Map<String, MouseAction> _mouseActionByName =
      <String, MouseAction>{
        for (final action in MouseAction.values) action.name: action,
      };
  static final Map<String, MouseButton> _mouseButtonByName =
      <String, MouseButton>{
        for (final button in MouseButton.values) button.name: button,
      };

  static Future<ReplayTraceConversionResult> convertFile(
    String tracePath, {
    ReplayTraceConversionOptions options = const ReplayTraceConversionOptions(),
  }) async {
    throw UnsupportedError('File I/O is not supported on this platform');
  }

  static _ParsedTrace _parseTrace(
    List<String> lines, {
    required bool includeCustomEvents,
  }) {
    final events = <_ParsedEvent>[];
    var inferredScreenWidth = 0;
    var inferredScreenHeight = 0;
    var hasStructuredInput = false;
    var hasCustomEvents = false;
    for (final line in lines) {
      final evidenceRecord = TuiEvidence.tryParseLine(line);
      if (evidenceRecord != null) {
        final (width, height) = _screenSizeForEvidence(evidenceRecord);
        if (width != null &&
            width > 0 &&
            height != null &&
            height > 0 &&
            (inferredScreenWidth <= 0 || inferredScreenHeight <= 0)) {
          inferredScreenWidth = width;
          inferredScreenHeight = height;
        }

        if (includeCustomEvents) {
          hasCustomEvents = true;
          events.add(
            _ParsedCustomTraceEvent(
              tsUs: evidenceRecord.timestampUs,
              event: ReplayCustomEvent(
                type: _customEventTypeForEvidence(evidenceRecord),
                fields: <String, Object?>{
                  'source': 'evidence',
                  'recordType': evidenceRecord.type,
                  'decisionType': evidenceRecord.decisionType,
                  'result': evidenceRecord.result,
                  if (evidenceRecord.runId != null)
                    'runId': evidenceRecord.runId,
                  ...evidenceRecord.factors,
                },
              ),
            ),
          );
        }
        continue;
      }

      final eventLine = TuiTrace.tryParseEventLine(line);
      if (eventLine == null) continue;

      if (eventLine.type == TraceEventType.windowSize) {
        final width = _asInt(eventLine.fields['width']);
        final height = _asInt(eventLine.fields['height']);
        if (width != null && width > 0 && height != null && height > 0) {
          inferredScreenWidth = width;
          inferredScreenHeight = height;
        }
        continue;
      }

      if (eventLine.type == TraceEventType.inputBatch) {
        hasStructuredInput = true;
        final messages = _asMapList(eventLine.fields['messages']);
        for (var i = 0; i < messages.length; i++) {
          final payload = messages[i];
          final tsUs = eventLine.timestampUs + i;
          final parsedEvent = _parsedInputMessage(tsUs, payload);
          if (parsedEvent == null) continue;
          if (parsedEvent case _ParsedWindowSizeEvent(
            :final width,
            :final height,
          )) {
            if (width > 0 && height > 0) {
              inferredScreenWidth = width;
              inferredScreenHeight = height;
            }
            continue;
          }
          events.add(parsedEvent);
        }
        continue;
      }

      if (includeCustomEvents) {
        hasCustomEvents = true;
        events.add(
          _ParsedCustomTraceEvent(
            tsUs: eventLine.timestampUs,
            event: ReplayCustomEvent(
              type: eventLine.type,
              fields: eventLine.fields,
            ),
          ),
        );
      }
    }
    return _ParsedTrace(
      events: events,
      inferredScreenWidth: inferredScreenWidth,
      inferredScreenHeight: inferredScreenHeight,
      hasStructuredInput: hasStructuredInput,
      hasCustomEvents: hasCustomEvents,
    );
  }

  static (int?, int?) _screenSizeForEvidence(TuiEvidenceRecord record) {
    final topLevelWidth = _asInt(record.factors['width']);
    final topLevelHeight = _asInt(record.factors['height']);
    if (topLevelWidth != null && topLevelHeight != null) {
      return (topLevelWidth, topLevelHeight);
    }

    final report = _asJsonObject(record.factors['report']);
    final reportWidth = _asInt(report['lastWidth']);
    final reportHeight = _asInt(report['lastHeight']);
    if (reportWidth != null && reportHeight != null) {
      return (reportWidth, reportHeight);
    }

    final summary = _asJsonObject(record.factors['lastSnapshotSummary']);
    final summaryWidth = _asInt(summary['width']);
    final summaryHeight = _asInt(summary['height']);
    if (summaryWidth != null && summaryHeight != null) {
      return (summaryWidth, summaryHeight);
    }

    final snapshot = _asJsonObject(record.factors['lastSnapshot']);
    return (_asInt(snapshot['width']), _asInt(snapshot['height']));
  }

  static String _customEventTypeForEvidence(TuiEvidenceRecord record) {
    if (record.type == 'runtime.render') {
      return 'runtime.${record.decisionType}';
    }
    if (record.type == 'runtime.decision') {
      return '${record.type}.${record.decisionType}';
    }
    return record.type;
  }

  static _ActionConversion _toActions(
    List<_ParsedEvent> events, {
    required int replayStartUs,
    required int minSleepUs,
    required bool includeHoverMoves,
  }) {
    final actions = <ReplayAction>[];
    var skipped = 0;
    int? prevKeptTs = math.max(0, replayStartUs);
    var i = 0;

    void maybeSleep(int tsUs) {
      final prev = prevKeptTs;
      if (prev == null) return;
      final deltaUs = tsUs - prev;
      if (deltaUs < minSleepUs) return;
      final ms = math.max(1, (deltaUs / 1000).round());
      actions.add(ReplayAction(type: 'sleep', ms: ms));
    }

    while (i < events.length) {
      final event = events[i];
      if (event is _ParsedKeyEvent) {
        final action = _keyEventToAction(event.key);
        if (action == null) {
          skipped++;
          i++;
          continue;
        }
        maybeSleep(event.tsUs);
        actions.add(action);
        prevKeptTs = event.tsUs;
        i++;
        continue;
      }

      if (event is _ParsedCustomTraceEvent) {
        maybeSleep(event.tsUs);
        actions.add(
          ReplayAction(
            type: 'event',
            eventType: event.event.type,
            eventFields: event.event.fields,
          ),
        );
        prevKeptTs = event.tsUs;
        i++;
        continue;
      }

      final mouse = event as _ParsedMouseEvent;
      if (mouse.action == MouseAction.wheel) {
        final direction = _wheelDirection(mouse.button);
        if (direction == null) {
          skipped++;
          i++;
          continue;
        }
        maybeSleep(mouse.tsUs);
        var repeat = 1;
        var j = i + 1;
        var lastTs = mouse.tsUs;
        while (j < events.length) {
          final next = events[j];
          if (next is! _ParsedMouseEvent) break;
          if (next.action != MouseAction.wheel || next.button != mouse.button) {
            break;
          }
          if (next.x != mouse.x || next.y != mouse.y) break;
          if (next.tsUs - lastTs > 120000) break;
          repeat++;
          lastTs = next.tsUs;
          j++;
        }
        actions.add(
          ReplayAction(
            type: 'wheel',
            direction: direction,
            x: mouse.x,
            y: mouse.y,
            repeat: repeat,
          ),
        );
        prevKeptTs = lastTs;
        i = j;
        continue;
      }

      if (mouse.action == MouseAction.press &&
          mouse.button == MouseButton.left) {
        maybeSleep(mouse.tsUs);
        final startX = mouse.x;
        final startY = mouse.y;
        var endX = mouse.x;
        var endY = mouse.y;
        var steps = 0;
        var releaseTs = mouse.tsUs;
        var j = i + 1;
        var foundRelease = false;

        while (j < events.length) {
          final next = events[j];
          if (next is! _ParsedMouseEvent) {
            j++;
            continue;
          }
          if (next.action == MouseAction.motion &&
              next.button == MouseButton.left) {
            endX = next.x;
            endY = next.y;
            releaseTs = next.tsUs;
            steps++;
            j++;
            continue;
          }
          if (next.action == MouseAction.release &&
              next.button == MouseButton.left) {
            if (steps == 0) {
              endX = next.x;
              endY = next.y;
            }
            releaseTs = next.tsUs;
            foundRelease = true;
            j++;
            break;
          }
          j++;
        }

        if (steps == 0 && endX == startX && endY == startY) {
          actions.add(ReplayAction(type: 'tap', x: startX, y: startY));
        } else if (steps == 0) {
          actions.add(
            ReplayAction(
              type: 'drag',
              x: startX,
              y: startY,
              x2: endX,
              y2: endY,
              steps: 1,
            ),
          );
        } else {
          actions.add(
            ReplayAction(
              type: 'drag',
              x: startX,
              y: startY,
              x2: endX,
              y2: endY,
              steps: math.max(1, steps),
            ),
          );
        }

        prevKeptTs = releaseTs;
        i = foundRelease ? j : math.max(i + 1, j);
        continue;
      }

      if (includeHoverMoves &&
          mouse.action == MouseAction.motion &&
          mouse.button == MouseButton.none) {
        maybeSleep(mouse.tsUs);
        actions.add(ReplayAction(type: 'move', x: mouse.x, y: mouse.y));
        prevKeptTs = mouse.tsUs;
      } else {
        skipped++;
      }
      i++;
    }
    return _ActionConversion(actions: actions, skippedCount: skipped);
  }

  static _ParsedEvent? _parsedInputMessage(
    int tsUs,
    Map<String, dynamic> payload,
  ) {
    final kind = payload['kind'];
    if (kind is! String || kind.isEmpty) return null;

    if (kind == 'key') {
      final keyTypeName = payload['keyType'];
      if (keyTypeName is! String || keyTypeName.isEmpty) return null;
      final keyType = _keyTypeByName[keyTypeName];
      if (keyType == null) return null;
      final runes = _asIntList(payload['runes']);
      return _ParsedKeyEvent(
        tsUs: tsUs,
        key: Key(
          keyType,
          runes: runes,
          ctrl: _asBool(payload['ctrl']),
          alt: _asBool(payload['alt']),
          shift: _asBool(payload['shift']),
          meta: _asBool(payload['meta']),
          hyper: _asBool(payload['hyper']),
          superKey: _asBool(payload['superKey']),
          isRelease: _asBool(payload['isRelease']),
          isRepeat: _asBool(payload['isRepeat']),
        ),
      );
    }

    if (kind == 'mouse') {
      final actionName = payload['action'];
      final buttonName = payload['button'];
      if (actionName is! String || buttonName is! String) return null;
      final action = _mouseActionByName[actionName];
      final button = _mouseButtonByName[buttonName];
      final x = _asInt(payload['x']);
      final y = _asInt(payload['y']);
      if (action == null || button == null || x == null || y == null) {
        return null;
      }
      return _ParsedMouseEvent(
        tsUs: tsUs,
        action: action,
        button: button,
        x: x,
        y: y,
      );
    }

    if (kind == 'window_size') {
      final width = _asInt(payload['width']);
      final height = _asInt(payload['height']);
      if (width == null || height == null) return null;
      return _ParsedWindowSizeEvent(tsUs: tsUs, width: width, height: height);
    }

    return null;
  }

  static ReplayAction? _keyEventToAction(Key key) {
    if (key.isRelease || key.isRepeat || key.hasModifier) return null;
    switch (key.type) {
      case KeyType.runes:
        if (key.runes.isEmpty) return null;
        return ReplayAction(
          type: 'text',
          value: String.fromCharCodes(key.runes),
        );
      case KeyType.enter:
        return const ReplayAction(type: 'special', key: 'enter');
      case KeyType.tab:
        return const ReplayAction(type: 'special', key: 'tab');
      case KeyType.backspace:
        return const ReplayAction(type: 'special', key: 'backspace');
      case KeyType.delete:
        return const ReplayAction(type: 'special', key: 'delete');
      case KeyType.escape:
        return const ReplayAction(type: 'special', key: 'escape');
      case KeyType.space:
        return const ReplayAction(type: 'special', key: 'space');
      case KeyType.up:
        return const ReplayAction(type: 'special', key: 'up');
      case KeyType.down:
        return const ReplayAction(type: 'special', key: 'down');
      case KeyType.left:
        return const ReplayAction(type: 'special', key: 'left');
      case KeyType.right:
        return const ReplayAction(type: 'special', key: 'right');
      case KeyType.home:
        return const ReplayAction(type: 'special', key: 'home');
      case KeyType.end:
        return const ReplayAction(type: 'special', key: 'end');
      case KeyType.pageUp:
        return const ReplayAction(type: 'special', key: 'pageUp');
      case KeyType.pageDown:
        return const ReplayAction(type: 'special', key: 'pageDown');
      default:
        return null;
    }
  }

  static String? _wheelDirection(MouseButton button) {
    return switch (button) {
      MouseButton.wheelDown => 'down',
      MouseButton.wheelUp => 'up',
      MouseButton.wheelLeft => 'left',
      MouseButton.wheelRight => 'right',
      _ => null,
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static List<int> _asIntList(Object? value) {
    if (value is! List) return const <int>[];
    final output = <int>[];
    for (final entry in value) {
      final parsed = _asInt(entry);
      if (parsed != null) output.add(parsed);
    }
    return output;
  }

  static bool _asBool(Object? value) => value == true;

  static List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    final output = <Map<String, dynamic>>[];
    for (final entry in value) {
      if (entry is Map) {
        output.add(Map<String, dynamic>.from(entry));
      }
    }
    return output;
  }

  static String _resolvedScenarioName(String? explicitName, String tracePath) {
    final trimmed = explicitName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final filename = tracePath.replaceAll('\\', '/').split('/').last;
    final dot = filename.lastIndexOf('.');
    if (dot <= 0) return filename;
    return filename.substring(0, dot);
  }
}

final class _ParsedTrace {
  const _ParsedTrace({
    required this.events,
    required this.inferredScreenWidth,
    required this.inferredScreenHeight,
    required this.hasStructuredInput,
    required this.hasCustomEvents,
  });

  final List<_ParsedEvent> events;
  final int inferredScreenWidth;
  final int inferredScreenHeight;
  final bool hasStructuredInput;
  final bool hasCustomEvents;
}

sealed class _ParsedEvent {
  const _ParsedEvent({required this.tsUs});

  final int tsUs;
}

final class _ParsedKeyEvent extends _ParsedEvent {
  const _ParsedKeyEvent({required super.tsUs, required this.key});

  final Key key;
}

final class _ParsedMouseEvent extends _ParsedEvent {
  const _ParsedMouseEvent({
    required super.tsUs,
    required this.action,
    required this.button,
    required this.x,
    required this.y,
  });

  final MouseAction action;
  final MouseButton button;
  final int x;
  final int y;
}

final class _ParsedCustomTraceEvent extends _ParsedEvent {
  const _ParsedCustomTraceEvent({required super.tsUs, required this.event});

  final ReplayCustomEvent event;
}

final class _ParsedWindowSizeEvent extends _ParsedEvent {
  const _ParsedWindowSizeEvent({
    required super.tsUs,
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

final class _ActionConversion {
  const _ActionConversion({required this.actions, required this.skippedCount});

  final List<ReplayAction> actions;
  final int skippedCount;
}

Map<String, Object?> _asJsonObject(Object? raw) {
  if (raw is! Map) return const <String, Object?>{};
  final out = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key?.toString().trim();
    if (key == null || key.isEmpty) continue;
    out[key] = _normalizeJsonValue(entry.value);
  }
  return out;
}

Object? _normalizeJsonValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return value.map(_normalizeJsonValue).toList(growable: false);
  }
  if (value is Map) {
    return _asJsonObject(value);
  }
  return value.toString();
}

KeyType _parseKeyType(String key) {
  final normalized = key.trim();
  return switch (normalized) {
    'enter' => KeyType.enter,
    'tab' => KeyType.tab,
    'backspace' => KeyType.backspace,
    'delete' => KeyType.delete,
    'escape' => KeyType.escape,
    'space' => KeyType.space,
    'up' => KeyType.up,
    'down' => KeyType.down,
    'left' => KeyType.left,
    'right' => KeyType.right,
    'home' => KeyType.home,
    'end' => KeyType.end,
    'pageUp' => KeyType.pageUp,
    'pageDown' => KeyType.pageDown,
    _ => throw FormatException('Unsupported special key: $key'),
  };
}

MouseButton _parseWheelButton(String direction) {
  final normalized = direction.trim();
  return switch (normalized) {
    'up' => MouseButton.wheelUp,
    'down' => MouseButton.wheelDown,
    'left' => MouseButton.wheelLeft,
    'right' => MouseButton.wheelRight,
    _ => throw FormatException('Unsupported wheel direction: $direction'),
  };
}
