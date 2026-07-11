/// Flutter-style widget testing harness for TUI widgets.
///
/// Provides [WidgetTester] for mounting widgets, sending input events,
/// and asserting on rendered output — similar to Flutter's `WidgetTester`.
///
/// Unlike a direct `WidgetApp.update()` / `WidgetApp.view()` approach,
/// this harness runs a real [Program] with a mock terminal so that every
/// event goes through the production message pipeline:
///
///   program.send(msg) → _drainMessageQueue → _processMessage
///     → model.update(msg) → _render() → model.view() → renderer.render()
///
/// This means message coalescing, queue draining, command execution, the
/// update→render ordering, and View interception all behave exactly as they
/// do at runtime.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal_widgets/widgets.dart' as w;
/// import 'package:artisanal/tui.dart' as tui;
/// import 'package:artisanal_widgets/testing.dart';
///
/// void main() {
///   testWidgets('counter increments on tap', (tester) async {
///     await tester.pumpWidget(MyCounterWidget());
///     expect(tester.find.text('count: 0'), isTrue);
///
///     tester.tap(tester.find.textLocation('count: 0'));
///     expect(tester.find.text('count: 1'), isTrue);
///   });
/// }
/// ```
library;

import 'dart:async';

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/terminal.dart' show Terminal, RawModeGuard;
import 'package:artisanal/style.dart' show ColorProfile, Layout;
import 'package:artisanal/tui.dart'
    show
        Msg,
        KeyMsg,
        PasteMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        WindowSizeMsg,
        RepaintMsg,
        Program,
        ProgramOptions,
        ZoneInfo;
import 'package:artisanal_widgets/src/widgets/components/debug_overlay.dart';
import '../app/widget_app.dart';
import '../animation/animation_tick.dart';
import '../components/components_widgets.dart' show DebugOverlayPosition;
import '../core/widget.dart';
import '../core/key.dart' show Key;
import '../core/element.dart' show HitTestElementEntry, Element;
import '../layout/layout.dart' show ImageAutoMode;
import '../rendering/render_object.dart' show RenderObject;
import 'manual_clock.dart';

// ---------------------------------------------------------------------------
// testWidgets — top-level convenience
// ---------------------------------------------------------------------------

/// Runs [callback] with a fresh [WidgetTester], managing setup/teardown
/// automatically.
///
/// The callback is async because [WidgetTester.pumpWidget] needs to start
/// a [Program] instance.
///
/// ```dart
/// testWidgets('my widget works', (tester) async {
///   await tester.pumpWidget(MyWidget());
///   expect(tester.find.text('hello'), isTrue);
/// });
/// ```
Future<void> testWidgets(
  String description,
  Future<void> Function(WidgetTester tester) callback, {
  Object? skip,
}) async {
  final tester = WidgetTester();
  try {
    await callback(tester);
  } finally {
    await tester.dispose();
  }
}

// ---------------------------------------------------------------------------
// _TestTerminal — lightweight mock terminal for widget tests
// ---------------------------------------------------------------------------

/// A minimal mock terminal that captures rendered output without touching
/// real stdio.  Modelled after the `MockTerminal` in program_test.dart and
/// the `StringTerminal` in terminal_base.dart but purpose-built for the
/// widget tester so we can track the last rendered view efficiently.
class _TestTerminal implements Terminal {
  _TestTerminal({this.terminalWidth = 80, this.terminalHeight = 24});

  int terminalWidth;
  int terminalHeight;

  // We only care about capturing view output written by the renderer.
  // SimpleTuiRenderer calls terminal.writeln(content).
  final List<String> _writes = [];
  String? _lastWrittenView;

  /// The last string that was written via [writeln] — this corresponds to
  /// the most recent view rendered by the Program's renderer.
  String get lastView => _lastWrittenView ?? '';

  /// All content written via [write]/[writeln].
  String get allOutput => _writes.join();

  // -- State tracking -------------------------------------------------------
  bool _raw = false;
  bool _alt = false;
  bool _mouse = false;
  bool _paste = false;

  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();

  // -- Terminal interface ----------------------------------------------------

  @override
  int get width => terminalWidth;

  @override
  int get height => terminalHeight;

  @override
  ({int width, int height}) get size =>
      (width: terminalWidth, height: terminalHeight);

  @override
  bool get supportsAnsi => true;

  @override
  bool get isTerminal => true;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  Stream<List<int>> get input => _inputController.stream;

  @override
  void write(String data) {
    _writes.add(data);
  }

  @override
  void writeln([String data = '']) {
    final content = '$data\n';
    _writes.add(content);
    // SimpleTuiRenderer calls writeln with the rendered view content.
    _lastWrittenView = data;
  }

  @override
  Future<void> flush() async {}

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    return null;
  }

  @override
  RawModeGuard enableRawMode() {
    _raw = true;
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() => _raw = false;

  @override
  bool get isRawMode => _raw;

  @override
  void enterAltScreen() => _alt = true;

  @override
  void exitAltScreen() => _alt = false;

  @override
  bool get isAltScreen => _alt;

  @override
  void hideCursor() {}

  @override
  void showCursor() {}

  @override
  void saveCursor() {}

  @override
  void restoreCursor() {}

  @override
  void moveCursor(int row, int col) {}

  @override
  void cursorHome() {}

  @override
  void cursorUp([int rows = 1]) {}

  @override
  void cursorDown([int rows = 1]) {}

  @override
  void cursorRight([int cols = 1]) {}

  @override
  void cursorLeft([int cols = 1]) {}

  @override
  void cursorToColumn(int col) {}

  @override
  void clearScreen() {}

  @override
  void clearToEnd() {}

  @override
  void clearToStart() {}

  @override
  void clearLine() {}

  @override
  void clearLineToEnd() {}

  @override
  void clearLineToStart() {}

  @override
  void clearPreviousLines(int lines) {}

  @override
  void scrollUp([int lines = 1]) {}

  @override
  void scrollDown([int lines = 1]) {}

  @override
  void enableMouse() => _mouse = true;

  @override
  void enableMouseCellMotion() => _mouse = true;

  @override
  void enableMouseAllMotion() => _mouse = true;

  @override
  void disableMouse() => _mouse = false;

  @override
  bool get isMouseEnabled => _mouse;

  @override
  void enableBracketedPaste() => _paste = true;

  @override
  void disableBracketedPaste() => _paste = false;

  @override
  bool get isBracketedPasteEnabled => _paste;

  @override
  void enableFocusReporting() {}

  @override
  void disableFocusReporting() {}

  @override
  void setTitle(String title) {}

  @override
  void setProgressBar(int state, int value) {}

  @override
  void bell() {}

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      (useTabs: false, useBackspace: true);

  @override
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {
    _inputController.close();
  }
}

// ---------------------------------------------------------------------------
// WidgetTestFrame
// ---------------------------------------------------------------------------

/// One deterministic frame snapshot captured by [WidgetTester].
final class WidgetTestFrame {
  const WidgetTestFrame({
    required this.sequence,
    required this.pumpCount,
    required this.width,
    required this.height,
    required this.trigger,
    required this.view,
  });

  /// Monotonic frame sequence within one tester instance.
  final int sequence;

  /// Pump count at the moment the frame was captured.
  final int pumpCount;

  /// Terminal width used for this frame.
  final int width;

  /// Terminal height used for this frame.
  final int height;

  /// Stable label describing what caused the capture.
  final String trigger;

  /// Canonical rendered view string from the current [WidgetApp].
  final String view;

  /// ANSI-stripped lines from [view], useful for stable assertions.
  List<String> get lines => view.split('\n').map(Layout.stripAnsi).toList();
}

// ---------------------------------------------------------------------------
// WidgetTester
// ---------------------------------------------------------------------------

/// A testing harness for TUI widgets that drives events through a real
/// [Program] instance.
///
/// This ensures message coalescing, the update→render cycle, command
/// execution, and all other Program-level behaviour are exercised — matching
/// what happens at runtime.
///
/// Mouse/tap interactions use render-tree hit-testing by default.
class WidgetTester {
  /// Creates a new tester.
  ///
  /// [enableZones] is a deprecated no-op kept for compatibility.
  WidgetTester({
    this.screenWidth = 80,
    this.screenHeight = 24,
    bool enableZones = false,
  }) {
    // Legacy no-op retained for source compatibility.
    if (enableZones) {}
  }

  /// Screen width used for [WindowSizeMsg] and MediaQueryData.
  int screenWidth;

  /// Screen height used for [WindowSizeMsg] and MediaQueryData.
  int screenHeight;

  _TestTerminal? _terminal;
  Program<WidgetApp>? _program;
  Future<dynamic>? _runFuture;
  WidgetApp? _app;
  String _lastView = '';
  int _pumpCount = 0;
  bool _recordFrames = false;
  int _frameSequence = 0;
  final List<WidgetTestFrame> _recordedFrames = <WidgetTestFrame>[];

  /// The underlying [WidgetApp], or `null` if [pumpWidget] hasn't been called.
  WidgetApp? get app => _app;

  /// The most recently rendered view string.
  String get view => _lastView;

  /// Raw terminal output captured by the mock terminal.
  ///
  /// This includes all writes emitted by the renderer, not just the latest
  /// canonical view. Harness analyzers use this for output hygiene checks such
  /// as synchronized-output and flicker detection.
  String get terminalOutput {
    _ensureRunning();
    return _terminal!.allOutput;
  }

  /// Number of times [pump] has been called (including the implicit pump
  /// inside [pumpWidget]).
  int get pumpCount => _pumpCount;

  /// Whether frame recording is currently enabled.
  bool get isRecordingFrames => _recordFrames;

  /// Recorded deterministic frame snapshots captured while recording.
  List<WidgetTestFrame> get recordedFrames =>
      List<WidgetTestFrame>.unmodifiable(_recordedFrames);

  /// The most recently recorded frame, or `null` if no frames were captured.
  WidgetTestFrame? get lastRecordedFrame =>
      _recordedFrames.isEmpty ? null : _recordedFrames.last;

  /// A [Finder] scoped to this tester's latest rendered output.
  Finder get find => Finder._(this);

  /// The [Program] driving this tester, or `null` before [pumpWidget].
  Program<WidgetApp>? get program => _program;

  /// Returns mounted elements that satisfy [predicate].
  ///
  /// Useful for advanced tree-level assertions in tests.
  List<Element> elementsWhere(bool Function(Element element) predicate) {
    _ensureRunning();
    return _app!.debugElementsWhere(predicate);
  }

  /// Returns all mounted elements in depth-first order.
  List<Element> get elements {
    _ensureRunning();
    return _app!.debugElements();
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Mounts [widget] in a [WidgetApp] wrapped by a [Program] and performs
  /// the initial render.
  ///
  /// This is the TUI equivalent of Flutter's `tester.pumpWidget(widget)`.
  /// It is async because the [Program] requires async initialisation.
  Future<void> pumpWidget(
    Widget widget, {
    bool scanZones = false,
    bool useHitTesting = true,
    bool debugOverlay = false,
    DebugOverlayPosition? debugOverlayPosition,
    ImageAutoMode imageAutoMode = ImageAutoMode.portableFallback,
    int? width,
    int? height,
  }) async {
    final start = DateTime.now();
    if (width != null) screenWidth = width;
    if (height != null) screenHeight = height;
    print('tester.pumpWidget.start');

    _app = WidgetApp(
      widget,
      scanZones: scanZones,
      useHitTesting: useHitTesting,
      debugOverlay: debugOverlay,
      imageAutoMode: imageAutoMode,
      debugOverlayPosition:
          debugOverlayPosition ?? DebugOverlayPosition.topRight,
    );

    _terminal = _TestTerminal(
      terminalWidth: screenWidth,
      terminalHeight: screenHeight,
    );

    _program = Program<WidgetApp>(
      _app!,
      options: const ProgramOptions(
        altScreen: false,
        hideCursor: false,
        mouse: true,
        disableRenderer: true,
        signalHandlers: false,
        catchPanics: false,
      ),
      terminal: _terminal!,
    );

    // Start the program.  run() is a long-lived future that resolves when
    // the program quits; we keep it around for cleanup.
    _runFuture = _program!.run();
    print('program.run started after ${DateTime.now().difference(start)}');

    // Give the async initialisation (_setup + _initialize) a chance to
    // complete.  With the mock terminal this resolves almost immediately.
    await _yieldToEventLoop();
    print('yield complete after ${DateTime.now().difference(start)}');

    // Capture the initial view.
    _syncView(trigger: 'pumpWidget');
    print('syncView complete after ${DateTime.now().difference(start)}');
    _pumpCount++;
  }

  /// Triggers a render cycle — rebuilds dirty elements and captures the
  /// latest rendered output.
  ///
  /// With the Program-based harness the update→render cycle happens
  /// automatically inside `Program._processMessage` after each `send`.
  /// Calling [pump] is still useful if you want to capture the view without
  /// sending an event, or after batching multiple no-pump calls.
  void pump() {
    _ensureRunning();
    // Force a render by sending a no-op repaint message.
    // Program handles RepaintMsg by calling _forceRender().
    _program!.send(const RepaintMsg());
    _syncView(trigger: 'pump');
    _pumpCount++;
  }

  /// Rebuilds the widget tree with a new simulated terminal size.
  ///
  /// Equivalent to the terminal window being resized.
  void resize(int width, int height) {
    screenWidth = width;
    screenHeight = height;
    _terminal!.terminalWidth = width;
    _terminal!.terminalHeight = height;
    _program!.send(WindowSizeMsg(width, height));
    _syncView(trigger: 'resize');
    _pumpCount++;
  }

  /// Tears down the tester, stopping the [Program] and releasing resources.
  Future<void> dispose() async {
    if (_program != null) {
      _program!.quit();
      try {
        await _runFuture?.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            _program!.kill();
          },
        );
      } catch (_) {
        // Swallow errors during cleanup (e.g. ProgramCancelledError).
      }
    }
    _program = null;
    _app = null;
    _terminal = null;
    _runFuture = null;
  }

  // -------------------------------------------------------------------------
  // Input helpers
  // -------------------------------------------------------------------------

  /// Starts recording deterministic frame snapshots after each synced render.
  ///
  /// When [clearExisting] is true, previously captured frames are discarded.
  ///
  /// When [captureCurrentFrame] is true, the current view is immediately
  /// recorded before any new input is sent.
  void startFrameRecording({
    bool clearExisting = true,
    bool captureCurrentFrame = false,
  }) {
    if (clearExisting) {
      clearRecordedFrames();
    }
    _recordFrames = true;
    if (captureCurrentFrame) {
      captureFrame(trigger: 'startFrameRecording');
    }
  }

  /// Stops frame recording and returns the captured frames.
  List<WidgetTestFrame> stopFrameRecording() {
    _recordFrames = false;
    return recordedFrames;
  }

  /// Removes all recorded frames and resets the local frame sequence.
  void clearRecordedFrames() {
    _recordedFrames.clear();
    _frameSequence = 0;
  }

  /// Returns recorded frames whose sequence is greater than [sequence].
  List<WidgetTestFrame> recordedFramesSince(int sequence) {
    return List<WidgetTestFrame>.unmodifiable(
      _recordedFrames.where((frame) => frame.sequence > sequence),
    );
  }

  /// Records the current frame immediately without requiring a message send.
  void captureFrame({String trigger = 'captureFrame'}) {
    _ensureRunning();
    _recordFrame(trigger: trigger);
  }

  /// Runs [action] while frame recording is enabled and returns the frames.
  ///
  /// Any previous recording state is restored after [action] completes.
  T recordFramesWhile<T>(
    T Function() action, {
    bool clearExisting = true,
    bool captureCurrentFrame = false,
  }) {
    final wasRecording = _recordFrames;
    startFrameRecording(
      clearExisting: clearExisting,
      captureCurrentFrame: captureCurrentFrame,
    );
    try {
      return action();
    } finally {
      _recordFrames = wasRecording;
    }
  }

  /// Sends a [KeyMsg] for the given character through the Program pipeline
  /// and captures the resulting view.
  ///
  /// ```dart
  /// tester.sendKey('+');
  /// expect(tester.find.text('count: 1'), isTrue);
  /// ```
  void sendKey(String char) {
    _ensureRunning();
    _program!.send(
      KeyMsg(
        terminal_keys.Key(terminal_keys.KeyType.runes, runes: char.codeUnits),
      ),
    );
    _syncView(trigger: 'sendKey($char)');
  }

  /// Sends a [KeyMsg] for a special key (e.g. enter, escape, arrow keys).
  void sendSpecialKey(terminal_keys.KeyType type) {
    _ensureRunning();
    _program!.send(KeyMsg(terminal_keys.Key(type)));
    _syncView(trigger: 'sendSpecialKey(${type.name})');
  }

  /// Sends a [KeyMsg] without capturing the view afterwards.
  ///
  /// Useful when you want to batch multiple events before a single [pump].
  void sendKeyNoPump(String char) {
    _ensureRunning();
    _program!.send(
      KeyMsg(
        terminal_keys.Key(terminal_keys.KeyType.runes, runes: char.codeUnits),
      ),
    );
  }

  /// Types [text] as a sequence of rune key presses.
  ///
  /// This is useful for widgets that expect real key events rather than a
  /// paste payload.
  void typeText(String text) {
    _ensureRunning();
    for (final rune in text.runes) {
      _program!.send(
        KeyMsg(
          terminal_keys.Key(terminal_keys.KeyType.runes, runes: <int>[rune]),
        ),
      );
    }
    _syncView(trigger: 'typeText(${text.runes.length} chars)');
  }

  /// Sends [text] as a single paste payload.
  void pasteText(String text) {
    _ensureRunning();
    _program!.send(PasteMsg(text));
    _syncView(trigger: 'pasteText(${text.length} chars)');
  }

  /// Sends an arbitrary [Msg] to the Program and captures the view.
  void sendMsg(Msg msg) {
    _ensureRunning();
    _program!.send(msg);
    _syncView(trigger: 'sendMsg(${msg.runtimeType})');
  }

  /// Sends an arbitrary [Msg] without capturing the view.
  void sendMsgNoPump(Msg msg) {
    _ensureRunning();
    _program!.send(msg);
  }

  /// Sends an [AnimationTickMsg] with an explicit timestamp.
  void sendAnimationTick(Object controllerId, DateTime time) {
    _ensureRunning();
    _program!.send(AnimationTickMsg(controllerId, time));
    _syncView(trigger: 'sendAnimationTick');
  }

  /// Advances [clock] by [delta] and sends the resulting animation tick.
  void advanceAnimation(
    Object controllerId,
    ManualClock clock, {
    Duration delta = Duration.zero,
  }) {
    sendAnimationTick(controllerId, clock.advance(delta));
  }

  // -------------------------------------------------------------------------
  // Mouse / tap helpers
  // -------------------------------------------------------------------------

  /// Simulates a full tap (press + release) at the location of [target].
  ///
  /// [target] is resolved lazily — typically a [Finder.textLocation] result.
  ///
  /// ```dart
  /// tester.tap(tester.find.textLocation('Submit'));
  /// // or with raw coordinates:
  /// tester.tapAt(5, 3);
  /// ```
  void tap(TapTarget target) {
    final coords = target._resolve(this);
    tapAt(coords.x, coords.y);
  }

  /// Simulates a full tap (press + release) at raw terminal coordinates.
  ///
  /// Events go through [Program.send] → the full update/render pipeline.
  /// The press and release are sent as separate messages with a render
  /// pass in between, matching the real-world flow (the terminal delivers
  /// press and release as separate escape sequences).
  void tapAt(int x, int y) {
    _ensureRunning();

    // Press
    _program!.send(
      MouseMsg(action: MouseAction.press, button: MouseButton.left, x: x, y: y),
    );
    // The Program renders after processing the press.  Sync view so hit-test
    // offsets are up-to-date for the release (matches real runtime flow).
    _syncView(trigger: 'tapDown($x,$y)');

    // Release
    _program!.send(
      MouseMsg(
        action: MouseAction.release,
        button: MouseButton.left,
        x: x,
        y: y,
      ),
    );
    _syncView(trigger: 'tapUp($x,$y)');
  }

  /// Simulates a full tap on the zone with [zoneId].
  ///
  /// **Deprecated** — use [tap] with [Finder.textLocation] or [tapAt].
  @Deprecated('Use tap(find.textLocation(...)) or tapAt(x, y) instead')
  void tapZone(String zoneId) {
    throw UnsupportedError(
      'Zone-based interactions were removed from artisanal_widgets. '
      'Use tap(find.textLocation(...)) or tapAt(x, y).',
    );
  }

  /// Sends a mouse press at (x, y) without releasing.
  void mouseDown(int x, int y, {MouseButton button = MouseButton.left}) {
    _ensureRunning();
    _program!.send(
      MouseMsg(action: MouseAction.press, button: button, x: x, y: y),
    );
    _syncView(trigger: 'mouseDown(${button.name}@$x,$y)');
  }

  /// Sends a mouse release at (x, y).
  void mouseUp(int x, int y, {MouseButton button = MouseButton.left}) {
    _ensureRunning();
    _program!.send(
      MouseMsg(action: MouseAction.release, button: button, x: x, y: y),
    );
    _syncView(trigger: 'mouseUp(${button.name}@$x,$y)');
  }

  /// Sends a mouse motion event at (x, y).
  void mouseMove(int x, int y) {
    _ensureRunning();
    _program!.send(
      MouseMsg(
        action: MouseAction.motion,
        button: MouseButton.none,
        x: x,
        y: y,
      ),
    );
    _syncView(trigger: 'mouseMove($x,$y)');
  }

  /// Sends a drag gesture from the start coordinates to the end coordinates.
  ///
  /// [steps] controls how many intermediate motion events are emitted between
  /// the press and release, allowing tests to exercise drag handling without
  /// open-coding repeated mouse events.
  void drag(
    int startX,
    int startY,
    int endX,
    int endY, {
    int steps = 1,
    MouseButton button = MouseButton.left,
  }) {
    _ensureRunning();
    if (steps < 1) {
      throw ArgumentError.value(steps, 'steps', 'Must be at least 1');
    }

    mouseDown(startX, startY, button: button);
    for (var step = 1; step <= steps; step++) {
      final progress = step / steps;
      final x = startX + ((endX - startX) * progress).round();
      final y = startY + ((endY - startY) * progress).round();
      _program!.send(
        MouseMsg(action: MouseAction.motion, button: button, x: x, y: y),
      );
      _syncView(trigger: 'dragMove(${button.name}@$x,$y)');
    }
    mouseUp(endX, endY, button: button);
  }

  // -------------------------------------------------------------------------
  // Hit-test queries
  // -------------------------------------------------------------------------

  /// Performs a hit-test at terminal coordinates (x, y) against the render
  /// tree and returns the list of hit elements, deepest first.
  List<HitTestElementEntry> hitTestAt(int x, int y) {
    _ensureRunning();
    // Make sure offsets are current by accessing the model's view.
    final model = _program!.currentModel!;
    model.view();
    return model.hitTestAt(x.toDouble(), y.toDouble());
  }

  // -------------------------------------------------------------------------
  // Zone queries (deprecated — kept for compatibility)
  // -------------------------------------------------------------------------

  /// Returns all gesture zone IDs currently registered.
  ///
  /// **Deprecated** — always empty.
  @Deprecated('Zone-based dispatch is deprecated; use hit-testing instead')
  List<String> get gestureZoneIds => const <String>[];

  /// Returns the [ZoneInfo] for [zoneId], or `null` if not registered.
  ///
  /// **Deprecated** — always returns `null`.
  @Deprecated('Zone-based dispatch is deprecated; use hit-testing instead')
  ZoneInfo? getZone(String zoneId) => null;

  // -------------------------------------------------------------------------
  // View assertions
  // -------------------------------------------------------------------------

  /// Returns `true` if the latest rendered view contains [text].
  bool viewContains(String text) => _lastView.contains(text);

  /// Returns the visible (ANSI-stripped) lines of the last rendered view.
  List<String> get viewLines => _lastView.split('\n');

  // -------------------------------------------------------------------------
  // Text location — finds the (x, y) of a piece of text in the rendered view
  // -------------------------------------------------------------------------

  /// Finds the terminal coordinates of [text] in the ANSI-stripped rendered
  /// output.  Returns `null` if not found.
  ///
  /// This is the primary way to locate a widget for tapping when using
  /// hit-test-based dispatch — no zone IDs needed.
  ({int x, int y})? locateText(String text) {
    final lines = _lastView.split('\n');
    for (var row = 0; row < lines.length; row++) {
      final stripped = Layout.stripAnsi(lines[row]);
      final col = stripped.indexOf(text);
      if (col >= 0) {
        return (x: col, y: row);
      }
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  /// Reads the latest rendered view from the model.
  ///
  /// After Program processes a message it calls `_render()` which invokes
  /// `model.view()` and sends the result to the renderer.  We read back
  /// from the model directly so we get the canonical view string without
  /// terminal noise (escape sequences written during setup, etc.).
  void _syncView({String trigger = 'sync'}) {
    final model = _program?.currentModel;
    if (model != null) {
      _lastView = model.view().toString();
      if (_recordFrames) {
        _recordFrame(trigger: trigger);
      }
    }
  }

  void _recordFrame({required String trigger}) {
    final model = _program?.currentModel;
    if (model == null) {
      return;
    }
    _lastView = model.view().toString();
    _recordedFrames.add(
      WidgetTestFrame(
        sequence: _frameSequence++,
        pumpCount: _pumpCount,
        width: screenWidth,
        height: screenHeight,
        trigger: trigger,
        view: _lastView,
      ),
    );
  }

  void _ensureRunning() {
    if (_program == null) {
      throw StateError(
        'No Program — call pumpWidget() before interacting with the tester.',
      );
    }
  }

  /// Yields to the Dart event loop so that async setup (Program.run →
  /// _setup → _initialize) can complete.  With the mock terminal the
  /// async operations resolve near-instantly but they still require at
  /// least one microtask turn.
  static Future<void> _yieldToEventLoop() async {
    // Three microtask rounds is enough for Program._setup,
    // _runStartupProbesIfNeeded (skipped with mock), _initialize,
    // and the first _render.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

// ---------------------------------------------------------------------------
// Finder
// ---------------------------------------------------------------------------

/// Query helper for locating text in the rendered output.
///
/// Accessed via `tester.find`.
class Finder {
  Finder._(this._tester);

  final WidgetTester _tester;

  /// Returns `true` if the latest rendered view contains [text].
  bool text(String text) => Layout.stripAnsi(_tester._lastView).contains(text);

  /// Returns mounted elements whose widget type is [T].
  List<Element> byType<T extends Widget>() {
    return _tester.elementsWhere((e) => e.widget is T);
  }

  /// Returns the first mounted element whose widget type is [T], or `null`.
  Element? firstByType<T extends Widget>() {
    final matches = byType<T>();
    return matches.isEmpty ? null : matches.first;
  }

  /// Returns mounted elements whose widget key equals [key].
  List<Element> byKey(Key key) {
    return _tester.elementsWhere((e) => e.widget.key == key);
  }

  /// Returns the first mounted element whose widget key equals [key], or `null`.
  Element? firstByKey(Key key) {
    final matches = byKey(key);
    return matches.isEmpty ? null : matches.first;
  }

  /// Returns `true` if the latest rendered view contains a line matching
  /// the regular expression [pattern].
  bool textMatching(Pattern pattern) =>
      pattern.allMatches(Layout.stripAnsi(_tester._lastView)).isNotEmpty;

  /// Returns a [TapTarget] for a zone with [zoneId].
  ///
  /// **Deprecated** — use [textLocation] instead.
  @Deprecated('Use textLocation() instead')
  TapTarget zone(String zoneId) => _ZoneTapTarget(zoneId);

  /// Returns a [TapTarget] that locates [text] in the rendered output and
  /// taps at its coordinates.
  ///
  /// This is the preferred way to tap widgets when using hit-test dispatch.
  ///
  /// ```dart
  /// tester.tap(tester.find.textLocation('Submit'));
  /// ```
  TapTarget textLocation(String text) => _TextTapTarget(text);

  /// Returns a [TapTarget] centered on [element]'s render bounds.
  TapTarget element(Element element) => _ElementTapTarget(element);

  /// Returns a [TapTarget] centered on the first match for widget type [T].
  TapTarget byTypeLocation<T extends Widget>() {
    final match = firstByType<T>();
    if (match == null) {
      throw StateError('No mounted element found for type $T');
    }
    return _ElementTapTarget(match);
  }

  /// Returns a [TapTarget] centered on the first match for [key].
  TapTarget byKeyLocation(Key key) {
    final match = firstByKey(key);
    if (match == null) {
      throw StateError('No mounted element found for key $key');
    }
    return _ElementTapTarget(match);
  }

  /// Returns the Nth gesture zone (0-indexed).
  ///
  /// **Deprecated** — use [textLocation] instead.
  @Deprecated('Use textLocation() instead')
  TapTarget gesture(int index) => _ZoneTapTarget('gesture-$index');

  /// Returns `true` if a zone with [zoneId] exists and is non-zero.
  ///
  /// **Deprecated** — always returns `false`.
  @Deprecated('Zone-based dispatch is deprecated; use hit-testing instead')
  bool hasZone(String zoneId) => false;

  /// Returns all registered gesture zone IDs.
  ///
  /// **Deprecated** — zone-based dispatch is being replaced by hit-testing.
  @Deprecated('Zone-based dispatch is deprecated; use hit-testing instead')
  // ignore: deprecated_member_use_from_same_package
  List<String> get gestureZones => _tester.gestureZoneIds;
}

// ---------------------------------------------------------------------------
// TapTarget
// ---------------------------------------------------------------------------

/// A lazy reference to a screen position, resolved at tap time.
abstract class TapTarget {
  ({int x, int y}) _resolve(WidgetTester tester);
}

/// Legacy zone tap target kept for API compatibility.
class _ZoneTapTarget extends TapTarget {
  _ZoneTapTarget(this.zoneId);

  final String zoneId;

  @override
  ({int x, int y}) _resolve(WidgetTester tester) {
    throw UnsupportedError(
      'Zone-based tap targets were removed from artisanal_widgets. '
      'Use Finder.textLocation, Finder.byTypeLocation, or Finder.byKeyLocation.',
    );
  }
}

/// Resolves a visible text string to coordinates by scanning the rendered view.
class _TextTapTarget extends TapTarget {
  _TextTapTarget(this.text);

  final String text;

  @override
  ({int x, int y}) _resolve(WidgetTester tester) {
    final loc = tester.locateText(text);
    if (loc == null) {
      final snippet = tester.view.length > 500
          ? '${tester.view.substring(0, 500)}...'
          : tester.view;
      throw StateError(
        'Text "$text" not found in rendered view.\n'
        'View:\n$snippet',
      );
    }
    // Tap in the middle of the text horizontally.
    return (x: loc.x + text.length ~/ 2, y: loc.y);
  }
}

/// Resolves an [Element] to the center of its render bounds.
class _ElementTapTarget extends TapTarget {
  _ElementTapTarget(this.element);

  final Element element;

  @override
  ({int x, int y}) _resolve(WidgetTester tester) {
    final ro = element.renderObject ?? _firstRenderObject(element);
    if (ro == null) {
      throw StateError(
        'Element ${element.widget.runtimeType} has no render object; '
        'use textLocation() or query a render-object-backed widget.',
      );
    }

    final pos = _globalOffset(ro);
    final x = (pos.x + (ro.size.width / 2)).floor();
    final y = (pos.y + (ro.size.height / 2)).floor();
    return (x: x, y: y);
  }
}

RenderObject? _firstRenderObject(Element element) {
  final direct = element.renderObject;
  if (direct != null) return direct;
  for (final child in element.children) {
    final nested = _firstRenderObject(child);
    if (nested != null) return nested;
  }
  return null;
}

({double x, double y}) _globalOffset(RenderObject ro) {
  var x = 0.0;
  var y = 0.0;
  RenderObject? current = ro;
  while (current != null) {
    x += current.offset.dx;
    y += current.offset.dy;
    current = current.parent;
  }
  return (x: x, y: y);
}
