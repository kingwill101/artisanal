/// Log Viewer TUI Demo - A monitoring dashboard-style log viewer.
///
/// Run:
///   dart run packages/artisanal/example/log_viewer_demo.dart
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

// ─────────────────────────────────────────────────────────────────────────────
// Log Entry Model
// ─────────────────────────────────────────────────────────────────────────────

enum LogLevel { info, debug, warning, error }

final class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.latency,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String source;
  final String message;
  final Duration? latency;

  String get levelStr => switch (level) {
    LogLevel.info => 'INF',
    LogLevel.debug => 'DBG',
    LogLevel.warning => 'WRN',
    LogLevel.error => 'ERR',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake Log Generator
// ─────────────────────────────────────────────────────────────────────────────

final _random = math.Random();

final _sources = [
  'api-gateway',
  'auth-service',
  'db-postgres',
  'db-redis',
  'user-service',
  'payment-service',
  'notification-svc',
  'scheduler',
  'worker-01',
  'worker-02',
  'nginx-proxy',
  'health-check',
];

final _infoMessages = [
  'Request completed successfully',
  'Connection established',
  'Cache hit for key',
  'Session validated',
  'User authenticated',
  'Background job started',
  'Metrics exported',
  'Health check passed',
  'Configuration reloaded',
  'New connection accepted',
  'Request queued for processing',
  'Rate limit check passed',
];

final _debugMessages = [
  'Parsing request headers',
  'Executing SQL query',
  'Serializing response payload',
  'Loading configuration from env',
  'Validating JWT token',
  'Checking cache TTL',
  'Resolving DNS for upstream',
  'Building response object',
  'Initializing connection pool',
  'Trace ID: \${traceId}',
];

final _warningMessages = [
  'Slow query detected (>500ms)',
  'Connection pool near capacity',
  'Rate limit threshold approaching',
  'Retry attempt 2/3',
  'Certificate expires in 7 days',
  'Memory usage above 80%',
  'Deprecated API endpoint called',
  'Response time exceeded SLA',
  'Queue depth increasing',
  'Fallback to secondary service',
];

final _errorMessages = [
  'Connection refused to upstream',
  'Query timeout after 30s',
  'Authentication failed',
  'Invalid request payload',
  'Service unavailable',
  'Database connection lost',
  'Out of memory',
  'Rate limit exceeded',
  'Permission denied',
  'Internal server error',
];

LogEntry _generateLogEntry() {
  final level = switch (_random.nextDouble()) {
    < 0.50 => LogLevel.info,
    < 0.75 => LogLevel.debug,
    < 0.92 => LogLevel.warning,
    _ => LogLevel.error,
  };

  final messages = switch (level) {
    LogLevel.info => _infoMessages,
    LogLevel.debug => _debugMessages,
    LogLevel.warning => _warningMessages,
    LogLevel.error => _errorMessages,
  };

  Duration? latency;
  if (_random.nextDouble() < 0.3) {
    latency = Duration(milliseconds: 50 + _random.nextInt(1000));
  }

  return LogEntry(
    timestamp: DateTime.now(),
    level: level,
    source: _sources[_random.nextInt(_sources.length)],
    message: messages[_random.nextInt(messages.length)],
    latency: latency,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────────────────────

class _TickMsg extends tui.Msg {
  const _TickMsg();
}

class _NewLogMsg extends tui.Msg {
  const _NewLogMsg(this.entry);
  final LogEntry entry;
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Viewer Model
// ─────────────────────────────────────────────────────────────────────────────

final class LogViewerModel implements tui.Model {
  LogViewerModel({
    required this.width,
    required this.height,
    required this.logs,
    required this.totalGenerated,
    required this.viewport,
    required this.activeTab,
    required this.liveMode,
    required this.debugOverlay,
    required this.lastRenderTime,
  });

  factory LogViewerModel.initial() {
    return LogViewerModel(
      width: 80,
      height: 24,
      logs: [],
      totalGenerated: 0,
      viewport: tui.ViewportModel(width: 76, height: 14),
      activeTab: 1, // Logs tab
      liveMode: true,
      debugOverlay: tui.DebugOverlayModel.initial(
        title: 'Render Metrics',
        rendererLabel: 'UV',
      ),
      lastRenderTime: DateTime.now(),
    );
  }

  final int width;
  final int height;
  final List<LogEntry> logs;
  final int totalGenerated;
  final tui.ViewportModel viewport;
  final int activeTab;
  final bool liveMode;
  final tui.DebugOverlayModel debugOverlay;
  final DateTime lastRenderTime;

  // Max logs to keep in buffer
  static const maxLogs = 10000;

  LogViewerModel copyWith({
    int? width,
    int? height,
    List<LogEntry>? logs,
    int? totalGenerated,
    tui.ViewportModel? viewport,
    int? activeTab,
    bool? liveMode,
    tui.DebugOverlayModel? debugOverlay,
    DateTime? lastRenderTime,
  }) {
    return LogViewerModel(
      width: width ?? this.width,
      height: height ?? this.height,
      logs: logs ?? this.logs,
      totalGenerated: totalGenerated ?? this.totalGenerated,
      viewport: viewport ?? this.viewport,
      activeTab: activeTab ?? this.activeTab,
      liveMode: liveMode ?? this.liveMode,
      debugOverlay: debugOverlay ?? this.debugOverlay,
      lastRenderTime: lastRenderTime ?? this.lastRenderTime,
    );
  }

  @override
  tui.Cmd? init() {
    return tui.Cmd.batch([
      tui.Cmd.tick(const Duration(milliseconds: 16), (_) => const _TickMsg()),
      _scheduleNewLog(),
    ]);
  }

  tui.Cmd _scheduleNewLog() {
    // Random interval between 50-300ms for realistic log flow
    final interval = 50 + _random.nextInt(250);
    return tui.Cmd.tick(Duration(milliseconds: interval), (_) {
      return _NewLogMsg(_generateLogEntry());
    });
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd>[];

    // Handle debug overlay updates
    final debugUpdate = debugOverlay.update(msg);
    var nextDebug = debugUpdate.model;

    switch (msg) {
      case tui.RenderMetricsMsg():
        return (copyWith(debugOverlay: nextDebug), null);

      case tui.WindowSizeMsg(:final width, :final height):
        final nextViewport = viewport.copyWith(
          width: width - 4,
          height: height - 10,
        );
        // Re-format logs for new width
        final logLines = logs
            .map((e) => _formatLogEntry(e, nextViewport.width))
            .toList();
        final updatedViewport = nextViewport.setContent(logLines.join('\n'));

        return (
          copyWith(
            width: width,
            height: height,
            viewport: updatedViewport,
            debugOverlay: nextDebug,
          ),
          null,
        );

      case tui.KeyMsg(:final key):
        // Toggle debug overlay with 'u'
        if (key.isChar('u') || key.isChar('U')) {
          return (copyWith(debugOverlay: nextDebug.toggle()), null);
        }

        // Quit
        if (key.isChar('q') || key.type == tui.KeyType.escape) {
          return (this, tui.Cmd.quit());
        }

        // Toggle live mode
        if (key.isChar('t') || key.isChar('T')) {
          return (copyWith(liveMode: !liveMode, debugOverlay: nextDebug), null);
        }

        // Tab switching
        if (key.type == tui.KeyType.tab) {
          final nextTab = key.shift
              ? (activeTab - 1).clamp(0, 3)
              : (activeTab + 1) % 4;
          return (copyWith(activeTab: nextTab, debugOverlay: nextDebug), null);
        }

        // Go to bottom (live mode)
        if (key.isChar('G')) {
          final nextViewport = viewport.gotoBottom();
          return (
            copyWith(viewport: nextViewport, debugOverlay: nextDebug),
            null,
          );
        }

        // Go to top
        if (key.isChar('g')) {
          final nextViewport = viewport.gotoTop();
          return (
            copyWith(viewport: nextViewport, debugOverlay: nextDebug),
            null,
          );
        }

        // Delegate other keys to viewport
        final (nextViewport, viewportCmd) = viewport.update(msg);
        return (
          copyWith(viewport: nextViewport, debugOverlay: nextDebug),
          viewportCmd,
        );

      case tui.MouseMsg():
        // Handle debug overlay first
        if (debugUpdate.consumed) {
          return (copyWith(debugOverlay: nextDebug), debugUpdate.cmd);
        }

        // Delegate to viewport
        final (nextViewport, viewportCmd) = viewport.update(msg);
        return (
          copyWith(viewport: nextViewport, debugOverlay: nextDebug),
          viewportCmd,
        );

      case _NewLogMsg(:final entry):
        if (!liveMode) {
          cmds.add(_scheduleNewLog());
          return (copyWith(debugOverlay: nextDebug), tui.Cmd.batch(cmds));
        }

        var newLogs = List<LogEntry>.from(logs)..add(entry);
        var newTotal = totalGenerated + 1;

        if (newLogs.length > maxLogs) {
          newLogs = newLogs.sublist(newLogs.length - maxLogs);
        }

        // Update viewport content
        final logLines = newLogs
            .map((e) => _formatLogEntry(e, viewport.width))
            .toList();
        var nextViewport = viewport.setContent(logLines.join('\n'));

        // Auto-scroll if it was at the bottom before adding the new log
        if (viewport.atBottom) {
          nextViewport = nextViewport.gotoBottom();
        }

        cmds.add(_scheduleNewLog());
        return (
          copyWith(
            logs: newLogs,
            totalGenerated: newTotal,
            viewport: nextViewport,
            debugOverlay: nextDebug,
          ),
          tui.Cmd.batch(cmds),
        );

      case _TickMsg():
        cmds.add(
          tui.Cmd.tick(
            const Duration(milliseconds: 16),
            (_) => const _TickMsg(),
          ),
        );
        return (
          copyWith(lastRenderTime: DateTime.now(), debugOverlay: nextDebug),
          tui.Cmd.batch(cmds),
        );

      default:
        return (copyWith(debugOverlay: nextDebug), null);
    }
  }

  @override
  String view() {
    if (width == 0 || height == 0) return 'Initializing...';

    final content = _buildContent();

    // Compose with debug overlay if enabled
    if (debugOverlay.enabled) {
      return debugOverlay.compose(content);
    }
    return content;
  }

  String _buildContent() {
    final lines = <String>[];

    // Header bar
    lines.add(_buildHeader());

    // Tab bar
    lines.add(_buildTabBar());

    // Breadcrumb
    lines.add(_buildBreadcrumb());

    // Empty line for spacing
    lines.add('');

    // Main log panel
    lines.addAll(_buildLogPanel());

    // Footer
    lines.add(_buildFooter());

    // Pad to screen height
    while (lines.length < height) {
      lines.add(' ' * width);
    }

    // Trim to screen height
    if (lines.length > height) {
      return lines.sublist(0, height).join('\n');
    }

    return lines.join('\n');
  }

  String _buildHeader() {
    final titleStyle = Style().foreground(Colors.cyan).bold();
    final timeStyle = Style().foreground(Colors.gray);

    final title = titleStyle.render(' ◆ LOG VIEWER ');
    final time = timeStyle.render(_formatTime(lastRenderTime));

    final titleLen = Style.visibleLength(title);
    final timeLen = Style.visibleLength(time);
    final padding = width - titleLen - timeLen;

    if (padding > 0) {
      return '$title${' ' * padding}$time';
    }
    return title;
  }

  String _buildTabBar() {
    final tabs = ['Overview', 'Logs', 'Database', 'Health'];
    final buffer = StringBuffer();
    buffer.write(' ');

    for (var i = 0; i < tabs.length; i++) {
      final isActive = i == activeTab;
      final style = isActive
          ? Style().foreground(Colors.black).background(Colors.cyan).bold()
          : Style().foreground(Colors.gray);

      if (i > 0) buffer.write(' │ ');
      buffer.write(style.render(' ${tabs[i]} '));
    }

    final content = buffer.toString();
    final contentLen = Style.visibleLength(content);
    if (contentLen < width) {
      return '$content${' ' * (width - contentLen)}';
    }
    return content;
  }

  String _buildBreadcrumb() {
    final style = Style().foreground(Colors.gray).dim();
    final highlightStyle = Style().foreground(Colors.cyan);

    final breadcrumb =
        '${style.render(' Monitoring')} → ${highlightStyle.render('Logs')}';
    final len = Style.visibleLength(breadcrumb);
    if (len < width) {
      return '$breadcrumb${' ' * (width - len)}';
    }
    return breadcrumb;
  }

  List<String> _buildLogPanel() {
    // Panel title with count and live indicator
    final liveIndicator = liveMode
        ? Style().foreground(Colors.green).render('● LIVE')
        : Style().foreground(Colors.yellow).render('● PAUSED');
    final countStyle = Style().foreground(Colors.cyan);
    final titleStyle = Style().foreground(Colors.cyan).bold();

    final panelTitle =
        '${titleStyle.render('● LOGS')} '
        '[${countStyle.render(logs.length.toString())}] '
        '$liveIndicator';

    // Build the viewport content
    final viewportContent = viewport.view();

    // Scrollback indicator
    final followIndicator = viewport.atBottom
        ? Style().foreground(Colors.green).dim().render('● Following new logs')
        : Style()
              .foreground(Colors.yellow)
              .render('▲ Scrollback mode - Press G to follow');

    final content = [viewportContent, '', followIndicator].join('\n');

    final panel = tui.PanelComponent(
      title: panelTitle,
      content: content,
      width: width,
      padding: 1,
      chars: tui.PanelBoxChars.rounded,
      borderStyle: Style().foreground(Colors.blue).dim(),
      renderConfig: tui.RenderConfig(terminalWidth: width),
    );

    return panel.render().split('\n');
  }

  String _formatLogEntry(LogEntry entry, int maxWidth, {bool dim = false}) {
    // Timestamp
    final timestamp = _formatTimestamp(entry.timestamp);
    final timestampStyle = Style().foreground(Colors.gray);

    // Level with color
    final levelStyle = switch (entry.level) {
      LogLevel.info => Style().foreground(Colors.green),
      LogLevel.debug => Style().foreground(Colors.blue),
      LogLevel.warning => Style().foreground(Colors.yellow),
      LogLevel.error => Style().foreground(Colors.red).bold(),
    };

    // Source
    final sourceStyle = Style().foreground(Colors.purple);

    // Latency badge
    String latencyStr = '';
    if (entry.latency != null) {
      final ms = entry.latency!.inMilliseconds;
      final latencyStyle = ms > 500
          ? Style().foreground(Colors.red)
          : ms > 200
          ? Style().foreground(Colors.yellow)
          : Style().foreground(Colors.green);
      latencyStr = ' ${latencyStyle.render('[$ms ms]')}';
    }

    // Build the log line
    final parts = <String>[
      timestampStyle.render(timestamp),
      levelStyle.render('[${entry.levelStr}]'),
      sourceStyle.render(entry.source.padRight(16)),
      entry.message,
      latencyStr,
    ];

    var line = parts.join(' ');

    // Truncate if too long
    if (Style.visibleLength(line) > maxWidth) {
      final targetLen = maxWidth - 3;
      if (targetLen > 0) {
        // Crude truncation
        line = '${line.substring(0, math.min(line.length, targetLen))}...';
      }
    }

    // Dim old entries if requested
    if (dim) {
      return Style().dim().render(line);
    }
    return line;
  }

  String _buildFooter() {
    final style = Style().foreground(Colors.gray);
    final highlightStyle = Style().foreground(Colors.cyan);

    // Controls
    final controls = [
      '[${highlightStyle.render('↑↓')}] Scroll',
      '[${highlightStyle.render('PgUp/Dn')}] Page',
      '[${highlightStyle.render('g')}] Top',
      '[${highlightStyle.render('G')}] Live',
      '[${highlightStyle.render('T')}] ${liveMode ? 'Pause' : 'Resume'}',
      '[${highlightStyle.render('U')}] Debug',
      '[${highlightStyle.render('q')}] Quit',
    ];

    final controlsStr = style.render(controls.join(' │ '));
    final timeStr = style.render(_formatTime(lastRenderTime));

    // FPS indicator
    final fps = debugOverlay.metrics?.averageFps ?? 0.0;
    final fpsStr = style.render('${fps.toStringAsFixed(0)} FPS');

    final leftPart = ' $controlsStr';
    final rightPart = '$timeStr  $fpsStr ';

    final leftLen = Style.visibleLength(leftPart);
    final rightLen = Style.visibleLength(rightPart);
    final padding = width - leftLen - rightLen;

    if (padding > 0) {
      return '$leftPart${' ' * padding}$rightPart';
    }
    return leftPart;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = (dt.millisecond ~/ 10).toString().padLeft(2, '0');
    return '$h:$m:$s.$ms';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  final p = tui.Program(
    LogViewerModel.initial(),
    options: const tui.ProgramOptions(
      useUltravioletRenderer: true,
      altScreen: true,
      metricsInterval: Duration(milliseconds: 250),
      mouseMode: tui.MouseMode.allMotion,
    ),
  );

  await p.run();
}
