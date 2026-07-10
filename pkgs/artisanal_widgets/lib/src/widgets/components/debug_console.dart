import 'dart:async';
import 'dart:math' as math;

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color, Border, Style;

DateTime _defaultDebugConsoleNowProvider() => DateTime.now();

/// One line in a [DebugConsoleController].
final class DebugConsoleEntry {
  DebugConsoleEntry({
    required this.message,
    this.level = 'info',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Console line text.
  final String message;

  /// Semantic level label such as `debug`, `info`, `warn`, or `error`.
  final String level;

  /// Timestamp attached when the line was added.
  final DateTime timestamp;

  String get timestampLabel {
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    final ss = timestamp.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// Mutable controller for a debug console pane.
///
/// This is intentionally lightweight and framework-local. Apps can hold one
/// controller, append logs from business logic, and let [DebugConsole] or
/// [ArtisanalApp] render the current tail.
final class DebugConsoleController {
  DebugConsoleController({
    this.maxEntries = 200,
    bool initiallyVisible = false,
    DateTime Function()? nowProvider,
  }) : _visible = initiallyVisible,
       _nowProvider = nowProvider ?? _defaultDebugConsoleNowProvider;

  /// Maximum number of stored log lines.
  final int maxEntries;

  final List<DebugConsoleEntry> _entries = <DebugConsoleEntry>[];
  final Set<void Function()> _listeners = <void Function()>{};
  final StreamController<int> _events = StreamController<int>.broadcast(
    sync: true,
  );
  bool _visible;
  int _revision = 0;
  final DateTime Function() _nowProvider;

  /// Current immutable log entries.
  List<DebugConsoleEntry> get entries =>
      List<DebugConsoleEntry>.unmodifiable(_entries);

  /// Stream of controller revisions for runtime-integrated listeners.
  Stream<int> get stream => _events.stream;

  /// Whether an attached console pane should currently be visible.
  bool get visible => _visible;

  /// Appends a log line.
  void add(String message, {String level = 'info', DateTime? timestamp}) {
    final ts = timestamp ?? _nowProvider();
    final lines = message.split('\n');
    for (final line in lines) {
      _entries.add(
        DebugConsoleEntry(message: line, level: level, timestamp: ts),
      );
    }
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    _notifyListeners();
  }

  /// Appends an informational line.
  void info(String message) => add(message, level: 'info');

  /// Appends a debug line.
  void debug(String message) => add(message, level: 'debug');

  /// Appends a warning line.
  void warn(String message) => add(message, level: 'warn');

  /// Appends an error line.
  void error(String message) => add(message, level: 'error');

  /// Appends an exception and optional stack trace as an error entry.
  void exception(Object error, [StackTrace? stackTrace]) {
    final buffer = StringBuffer()..write(error);
    if (stackTrace != null) {
      buffer
        ..writeln()
        ..write(stackTrace);
    }
    add(buffer.toString(), level: 'error');
  }

  /// Removes all entries.
  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    _notifyListeners();
  }

  /// Sets pane visibility.
  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    _notifyListeners();
  }

  /// Toggles pane visibility.
  void toggle() => setVisible(!_visible);

  /// Adds a listener fired whenever entries or visibility change.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Runs [body] in a zone that can forward `print()` and uncaught errors into
  /// this console controller.
  ///
  /// This is useful for wiring the controller into app-level runners so
  /// diagnostics land in the built-in console without manually threading the
  /// controller through business logic.
  Future<T> runZoned<T>(
    FutureOr<T> Function() body, {
    bool capturePrint = true,
    bool captureErrors = true,
    String printLevel = 'debug',
  }) {
    final completer = Completer<T>();

    final zoneSpecification = capturePrint
        ? ZoneSpecification(
            print: (self, parent, zone, line) {
              add(line, level: printLevel);
            },
          )
        : null;

    runZonedGuarded(
      () async {
        try {
          final result = await body();
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (error, stackTrace) {
          if (captureErrors) {
            exception(error, stackTrace);
          }
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      (error, stackTrace) {
        if (captureErrors) {
          exception(error, stackTrace);
        }
      },
      zoneSpecification: zoneSpecification,
    );

    return completer.future;
  }

  void _notifyListeners() {
    _revision++;
    _events.add(_revision);
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }
}

/// Exposes a [DebugConsoleController] to descendant widgets.
class DebugConsoleScope extends InheritedWidget {
  DebugConsoleScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final DebugConsoleController controller;

  /// Returns the nearest controller, if any.
  static DebugConsoleController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DebugConsoleScope>()
        ?.controller;
  }

  /// Returns the nearest controller.
  static DebugConsoleController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No DebugConsoleScope found in the widget tree');
    return controller!;
  }

  @override
  bool updateShouldNotify(covariant DebugConsoleScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// A scrollable developer console pane.
class DebugConsole extends StatefulWidget {
  DebugConsole({
    required this.controller,
    this.title = 'Debug Console',
    this.height = 8,
    this.showHelp = true,
    this.showToggleShortcut = false,
    this.emptyText = 'No console entries yet.',
    super.key,
  });

  /// Controller providing entries and visibility state.
  final DebugConsoleController controller;

  /// Pane title.
  final String title;

  /// Number of visible log rows.
  final int height;

  /// Whether to show a compact shortcut footer.
  final bool showHelp;

  /// Whether to include the host toggle shortcut in the footer.
  final bool showToggleShortcut;

  /// Placeholder text shown when the console is empty.
  final String emptyText;

  @override
  State createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final WidgetScrollController _scrollController = WidgetScrollController();

  @override
  Cmd? handleInit() {
    _syncTailOffset();
    return Cmd.listen<int>(
      widget.controller.stream,
      onData: (_) => const _DebugConsoleChangedMsg(),
    );
  }

  void _syncTailOffset() {
    final contentExtent = math.max(1, widget.controller.entries.length);
    _scrollController.updateMetrics(
      viewportExtent: math.max(1, widget.height),
      contentExtent: contentExtent,
    );
    _scrollController.jumpTo(_scrollController.maxOffset);
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _DebugConsoleChangedMsg) {
      _syncTailOffset();
      setState(() {});
      return null;
    }
    return super.handleUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final surface = theme.resolvedSurfaceVariant;
    final foreground = theme.resolvedOnSurfaceVariant;
    final headerStyle = theme.labelLarge.copy()..foreground(foreground);
    final subtleStyle = theme.bodySmall.copy()..foreground(theme.muted);
    final rows = widget.controller.entries;

    return Card(
      padding: const EdgeInsets.all(0),
      background: surface,
      child: Column(
        gap: 0,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: surface,
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: headerStyle),
                Text('${rows.length} lines', style: subtleStyle),
              ],
            ),
          ),
          Divider(),
          SizedBox(
            height: widget.height,
            child: Scrollbar(
              controller: _scrollController,
              trackStyle: subtleStyle.copy(),
              thumbStyle: theme.bodySmall.copy()..foreground(theme.primary),
              child: SingleChildScrollView(
                controller: _scrollController,
                handleKeys: false,
                child: Column(
                  gap: 0,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows.isEmpty
                      ? <Widget>[
                          Container(
                            color: surface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1,
                              vertical: 0,
                            ),
                            child: Text(widget.emptyText, style: subtleStyle),
                          ),
                        ]
                      : rows
                            .map((entry) => _DebugConsoleRow(entry: entry))
                            .toList(growable: false),
                ),
              ),
            ),
          ),
          if (widget.showHelp) Divider(),
          if (widget.showHelp)
            HelpView(
              keyMap: _DebugConsoleHelpKeyMap(
                showToggleShortcut: widget.showToggleShortcut,
              ),
              itemSpacing: 2,
              runSpacing: 0,
            ),
        ],
      ),
    );
  }
}

class _DebugConsoleRow extends StatelessWidget {
  _DebugConsoleRow({required this.entry});

  final DebugConsoleEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final prefixStyle = theme.bodySmall.copy()..foreground(theme.muted);
    final levelStyle = theme.bodySmall.copy()
      ..foreground(_levelColor(theme, entry.level))
      ..bold();
    final messageStyle = theme.bodySmall.copy()..foreground(theme.onSurface);

    return Container(
      color: theme.resolvedSurfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(style: prefixStyle, text: '[${entry.timestampLabel}] '),
            TextSpan(
              style: levelStyle,
              text: '${entry.level.toUpperCase().padRight(5)} ',
            ),
            TextSpan(style: messageStyle, text: entry.message),
          ],
        ),
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _levelColor(Theme theme, String level) {
    return switch (level.toLowerCase()) {
      'error' => theme.error,
      'warn' || 'warning' => theme.warning,
      'debug' => theme.resolvedInfo,
      _ => theme.onSurface,
    };
  }
}

final class _DebugConsoleHelpKeyMap extends KeyMap {
  _DebugConsoleHelpKeyMap({required bool showToggleShortcut}) {
    final bindings = <KeyBinding>[
      if (showToggleShortcut) KeyBinding.withHelp(['f10'], 'f10', 'toggle'),
      KeyBinding.withHelp(['ctrl+l'], 'ctrl+l', 'clear'),
    ];
    shortHelp = bindings;
    fullHelp = [bindings];
  }
}

/// Wraps a subtree with a toggleable debug console overlay.
class DebugConsoleHost extends StatefulWidget {
  DebugConsoleHost({
    required this.child,
    required this.controller,
    this.consoleHeight = 8,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final DebugConsoleController controller;
  final int consoleHeight;
  final bool enabled;

  @override
  State createState() => _DebugConsoleHostState();
}

class _DebugConsoleHostState extends State<DebugConsoleHost> {
  bool _isCtrlLShortcut(terminal_keys.Key key) {
    if (key.runes.length == 1 && key.runes.first == 0x0c) {
      return true;
    }
    if (!key.ctrl || key.alt || key.meta || key.hyper || key.superKey) {
      return false;
    }
    final char = key.char;
    return char != null && char.toLowerCase() == 'l';
  }

  @override
  Cmd? handleInit() {
    return Cmd.listen<int>(
      widget.controller.stream,
      onData: (_) => const _DebugConsoleHostChangedMsg(),
    );
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (!widget.enabled || msg is! KeyMsg) return null;

    if (msg.key.type == terminal_keys.KeyType.f10) {
      setState(() {
        widget.controller.toggle();
      });
      return Cmd.none();
    }

    if (widget.controller.visible && _isCtrlLShortcut(msg.key)) {
      setState(() {
        widget.controller.clear();
      });
      return Cmd.none();
    }

    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _DebugConsoleHostChangedMsg) {
      setState(() {});
      return null;
    }
    return super.handleUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;

    if (widget.enabled && widget.controller.visible) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: math.max(
                32,
                MediaQuery.of(context).size.width.toInt() - 2,
              ),
              child: DebugConsole(
                controller: widget.controller,
                height: widget.consoleHeight,
                showToggleShortcut: true,
              ),
            ),
          ),
        ],
      );
    }

    return DebugConsoleScope(controller: widget.controller, child: child);
  }
}

class _DebugConsoleChangedMsg extends Msg {
  const _DebugConsoleChangedMsg();
}

class _DebugConsoleHostChangedMsg extends Msg {
  const _DebugConsoleHostChangedMsg();
}
