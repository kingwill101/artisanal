/// Command Center TUI Demo - A monitoring dashboard with multiple panels.
///
/// Uses responsive layout with percentage-based panel heights.
/// Features: log filtering, search, level filters, debug overlay.
///
/// Run:
///   dart run packages/artisanal/example/command_center_demo.dart
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' as uv;

// ─────────────────────────────────────────────────────────────────────────────
// Log Entry Model
// ─────────────────────────────────────────────────────────────────────────────

enum LogLevel { info, debug, warning, error }

// Using library ThemePalette themes - available names:
// 'dark', 'light', 'hacker', 'ocean', 'monokai', 'dracula', 'nord', 'solarizedDark', 'solarizedLight'

final class Alert {
  const Alert({
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  final String message;
  final LogLevel severity;
  final DateTime timestamp;
}

final class SparklineData {
  const SparklineData({required this.values, required this.maxValue});

  factory SparklineData.empty() =>
      const SparklineData(values: [], maxValue: 10);

  final List<int> values;
  final int maxValue;

  SparklineData addValue(int value) {
    final newValues = [...values, value];
    // Keep last 30 data points
    final trimmed = newValues.length > 30
        ? newValues.sublist(newValues.length - 30)
        : newValues;
    final newMax = trimmed.fold<int>(maxValue, (a, b) => b > a ? b : a);
    return SparklineData(values: trimmed, maxValue: math.max(10, newMax));
  }

  String render(int width) {
    if (values.isEmpty) return '─' * width;
    final chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    final buffer = StringBuffer();
    final step = values.length > width ? values.length / width : 1.0;

    for (var i = 0; i < width && i * step < values.length; i++) {
      final idx = (i * step).floor();
      final value = idx < values.length ? values[idx] : 0;
      final normalized = maxValue > 0
          ? (value / maxValue).clamp(0.0, 1.0)
          : 0.0;
      final charIdx = (normalized * (chars.length - 1)).round();
      buffer.write(chars[charIdx]);
    }

    // Pad with baseline if needed
    while (buffer.length < width) {
      buffer.write('▁');
    }
    return buffer.toString();
  }
}

final class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.project,
    required this.environment,
    required this.source,
    required this.message,
    this.filename,
    this.lineNumber,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String project;
  final String environment;
  final String source;
  final String message;
  final String? filename;
  final int? lineNumber;

  String get levelStr => switch (level) {
    LogLevel.info => 'INF',
    LogLevel.debug => 'DBG',
    LogLevel.warning => 'WRN',
    LogLevel.error => 'ERR',
  };
}

/// Tracks log statistics by level
final class LogStats {
  const LogStats({
    required this.infoCount,
    required this.debugCount,
    required this.warningCount,
    required this.errorCount,
    required this.logsPerSecond,
    required this.recentLogs,
  });

  factory LogStats.empty() => const LogStats(
    infoCount: 0,
    debugCount: 0,
    warningCount: 0,
    errorCount: 0,
    logsPerSecond: 0.0,
    recentLogs: [],
  );

  final int infoCount;
  final int debugCount;
  final int warningCount;
  final int errorCount;
  final double logsPerSecond;
  final List<DateTime> recentLogs; // Track timestamps for rate calculation

  int get total => infoCount + debugCount + warningCount + errorCount;

  double get errorRate => total > 0 ? errorCount / total * 100 : 0;

  LogStats addLog(LogLevel level) {
    final now = DateTime.now();
    // Keep only logs from the last 60 seconds for rate calculation
    final cutoff = now.subtract(const Duration(seconds: 60));
    final recent = [...recentLogs.where((t) => t.isAfter(cutoff)), now];
    final rate = recent.length / 60.0; // logs per second

    return LogStats(
      infoCount: level == LogLevel.info ? infoCount + 1 : infoCount,
      debugCount: level == LogLevel.debug ? debugCount + 1 : debugCount,
      warningCount: level == LogLevel.warning ? warningCount + 1 : warningCount,
      errorCount: level == LogLevel.error ? errorCount + 1 : errorCount,
      logsPerSecond: rate,
      recentLogs: recent,
    );
  }

  LogStats withRate(double rate) => LogStats(
    infoCount: infoCount,
    debugCount: debugCount,
    warningCount: warningCount,
    errorCount: errorCount,
    logsPerSecond: rate,
    recentLogs: recentLogs,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake Log Generator
// ─────────────────────────────────────────────────────────────────────────────

final _random = math.Random();

const _logProjects = ['kasm', '███', 'vault', 'sync', 'api', 'auth'];
const _logEnvironments = ['PROD', 'STAG', 'DEV'];

const _logSources = [
  'kasm_rdp',
  'kasm_gua',
  'db',
  'nginx',
  'worker',
  'scheduler',
  'api_gw',
  'redis',
  'auth_svc',
  'health',
];

const _logFilenames = [
  'main.go',
  'handler.go',
  'server.go',
  'client.py',
  'worker.rs',
  'index.ts',
];

const _infoLogMessages = [
  'Received a healthcheck',
  'checkpoint starting: time',
  'Connection pool initialized',
  'Session established for user',
  'Request completed successfully',
  'Cache refreshed',
  'Metrics exported to prometheus',
  'Worker registered successfully',
  'Configuration reloaded',
  'Background job completed',
];

const _debugLogMessages = [
  'Hostnames received: [kasm→',
  'Parsing request headers',
  'Executing query: SELECT * FROM',
  'Validating JWT token claims',
  'Resolving DNS for upstream host',
  'Building response object',
  'Trace context propagated',
  'Cache lookup for key=session_',
];

const _warningLogMessages = [
  'Slow query detected (>500ms)',
  'Connection pool near capacity: 85%',
  'Rate limit threshold approaching',
  'Retry attempt 2/3 for upstream',
  'Memory usage above threshold: 82%',
  'Certificate expires in 7 days',
  'Queue depth increasing: 1,024',
];

const _errorLogMessages = [
  'Connection refused to upstream',
  'Query timeout after 30s',
  'Authentication failed for user',
  'Service unavailable: db-primary',
  'Out of memory: killed process',
  'Rate limit exceeded: 429',
  'Permission denied: access_token',
];

LogEntry _generateLogEntry() {
  final level = switch (_random.nextDouble()) {
    < 0.45 => LogLevel.info,
    < 0.75 => LogLevel.debug,
    < 0.92 => LogLevel.warning,
    _ => LogLevel.error,
  };

  final messages = switch (level) {
    LogLevel.info => _infoLogMessages,
    LogLevel.debug => _debugLogMessages,
    LogLevel.warning => _warningLogMessages,
    LogLevel.error => _errorLogMessages,
  };

  String? filename;
  int? lineNumber;
  if (_random.nextDouble() < 0.4) {
    filename = _logFilenames[_random.nextInt(_logFilenames.length)];
    lineNumber = 50 + _random.nextInt(400);
  }

  return LogEntry(
    timestamp: DateTime.now(),
    level: level,
    project: _logProjects[_random.nextInt(_logProjects.length)],
    environment: _logEnvironments[_random.nextInt(_logEnvironments.length)],
    source: _logSources[_random.nextInt(_logSources.length)],
    message: messages[_random.nextInt(messages.length)],
    filename: filename,
    lineNumber: lineNumber,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Main navigation tabs.
const _mainTabs = [
  'Overview',
  'Infrastructure',
  'Applications',
  'MONITORING',
  'Operations',
  'Configuration',
];

/// Sub-tabs for the Monitoring section.
const _subTabs = ['Logs', 'Database', 'Log Database', 'Health'];

/// Project names for the header.
const _projects = [
  'KASM Workspaces',
  'CloudSync',
  'API Gateway',
  'truck-reports',
  'vault',
  'metrics-hub',
];

// ─────────────────────────────────────────────────────────────────────────────
// Messages
// ─────────────────────────────────────────────────────────────────────────────

class _NewLogMsg extends tui.Msg {
  const _NewLogMsg(this.entry);
  final LogEntry entry;
}

class _SparklineTickMsg extends tui.Msg {
  const _SparklineTickMsg();
}

class _DismissAlertMsg extends tui.Msg {
  const _DismissAlertMsg();
}

// ─────────────────────────────────────────────────────────────────────────────
// Command Center Model
// ─────────────────────────────────────────────────────────────────────────────

class CommandCenterModel implements tui.Model {
  CommandCenterModel({
    required this.width,
    required this.height,
    required this.activeMainTab,
    required this.activeSubTab,
    required this.projects,
    required this.currentTime,
    required this.version,
    required this.logs,
    required this.totalLogs,
    required this.viewport,
    required this.liveMode,
    required this.latencyMs,
    required this.debugOverlay,
    required this.levelFilter,
    required this.projectFilter,
    required this.searchQuery,
    required this.searchMode,
    required this.logStats,
    required this.theme,
    required this.alerts,
    required this.sparkline,
    required this.searchInput,
    required this.cpuUsage,
    required this.memUsage,
    required this.networkIn,
    required this.networkOut,
    required this.showStats,
  });

  factory CommandCenterModel.initial() {
    return CommandCenterModel(
      width: 100,
      height: 24,
      activeMainTab: 3, // MONITORING tab (0-indexed)
      activeSubTab: 0, // Logs sub-tab (0-indexed)
      projects: _projects,
      currentTime: DateTime.now(),
      version: 'v2.0.0',
      logs: [],
      totalLogs: 1908196, // Simulated total log count
      viewport: tui.ViewportModel(width: 96, height: 14),
      liveMode: true,
      latencyMs: 138,
      debugOverlay: tui.DebugOverlayModel.initial(
        title: 'Render Metrics',
        rendererLabel: 'UV',
      ),
      levelFilter: {
        LogLevel.info,
        LogLevel.debug,
        LogLevel.warning,
        LogLevel.error,
      },
      projectFilter: null, // null = all projects
      searchQuery: '',
      searchMode: false,
      logStats: LogStats.empty(),
      theme: 'dark',
      alerts: [],
      sparkline: SparklineData.empty(),
      searchInput: tui.TextInputModel(
        prompt: '/',
        placeholder: 'Search logs...',
        width: 30,
      ),
      cpuUsage: 45.0,
      memUsage: 62.0,
      networkIn: 1.2,
      networkOut: 0.8,
      showStats: true,
    );
  }

  int width;
  int height;
  int activeMainTab;
  int activeSubTab;
  List<String> projects;
  DateTime currentTime;
  String version;
  List<LogEntry> logs;
  int totalLogs;
  tui.ViewportModel viewport;
  bool liveMode;
  int latencyMs;
  tui.DebugOverlayModel debugOverlay;
  Set<LogLevel> levelFilter;
  String? projectFilter; // null = all projects
  String searchQuery;
  bool searchMode;
  LogStats logStats;
  String theme; // Theme name - see ThemePalette.names for available themes
  List<Alert> alerts;
  SparklineData sparkline;
  tui.TextInputModel searchInput;
  double cpuUsage;
  double memUsage;
  double networkIn;
  double networkOut;
  bool showStats;

  // Cached view string
  String _cachedView = 'Initializing...';
  bool _viewDirty = true;

  // Max logs to keep in buffer
  static const maxLogs = 500;

  // ─────────────────────────────────────────────────────────────────────────
  // Theme-aware Style Methods
  // ─────────────────────────────────────────────────────────────────────────

  ThemePalette get _palette => ThemePalette.byName(theme);

  Style _accentStyle() => Style().foreground(_palette.accent);
  Style _accentBoldStyle() => Style().foreground(_palette.accentBold).bold();
  Style _textStyle() => Style().foreground(_palette.text);
  Style _textDimStyle() => Style().foreground(_palette.textDim).dim();
  Style _textBoldStyle() => Style().foreground(_palette.textBold).bold();
  Style _borderStyle() => Style().foreground(_palette.border).dim();
  Style _successStyle() => Style().foreground(_palette.success);
  Style _warningStyle() => Style().foreground(_palette.warning);
  Style _errorStyle() => Style().foreground(_palette.error);
  Style _infoStyle() => Style().foreground(_palette.info);
  Style _highlightStyle() => Style().foreground(_palette.highlight);
  Style _activeTabStyle() =>
      Style().foreground(Colors.black).background(_palette.accent).bold();

  /// Get filtered logs based on current filters
  List<LogEntry> get filteredLogs {
    return logs.where((log) {
      // Level filter
      if (!levelFilter.contains(log.level)) return false;
      // Project filter
      if (projectFilter != null && log.project != projectFilter) return false;
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!log.message.toLowerCase().contains(query) &&
            !log.source.toLowerCase().contains(query) &&
            !log.project.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  CommandCenterModel copyWith({
    int? width,
    int? height,
    int? activeMainTab,
    int? activeSubTab,
    List<String>? projects,
    DateTime? currentTime,
    String? version,
    List<LogEntry>? logs,
    int? totalLogs,
    tui.ViewportModel? viewport,
    bool? liveMode,
    int? latencyMs,
    tui.DebugOverlayModel? debugOverlay,
    Set<LogLevel>? levelFilter,
    String? projectFilter,
    String? searchQuery,
    bool? searchMode,
    LogStats? logStats,
    String? theme,
    List<Alert>? alerts,
    SparklineData? sparkline,
    tui.TextInputModel? searchInput,
    double? cpuUsage,
    double? memUsage,
    double? networkIn,
    double? networkOut,
    bool? showStats,
    bool markDirty = true,
  }) {
    final newModel = CommandCenterModel(
      width: width ?? this.width,
      height: height ?? this.height,
      activeMainTab: activeMainTab ?? this.activeMainTab,
      activeSubTab: activeSubTab ?? this.activeSubTab,
      projects: projects ?? this.projects,
      currentTime: currentTime ?? this.currentTime,
      version: version ?? this.version,
      logs: logs ?? this.logs,
      totalLogs: totalLogs ?? this.totalLogs,
      viewport: viewport ?? this.viewport,
      liveMode: liveMode ?? this.liveMode,
      latencyMs: latencyMs ?? this.latencyMs,
      debugOverlay: debugOverlay ?? this.debugOverlay,
      levelFilter: levelFilter ?? this.levelFilter,
      projectFilter: projectFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      searchMode: searchMode ?? this.searchMode,
      logStats: logStats ?? this.logStats,
      theme: theme ?? this.theme,
      alerts: alerts ?? this.alerts,
      sparkline: sparkline ?? this.sparkline,
      searchInput: searchInput ?? this.searchInput,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memUsage: memUsage ?? this.memUsage,
      networkIn: networkIn ?? this.networkIn,
      networkOut: networkOut ?? this.networkOut,
      showStats: showStats ?? this.showStats,
    );
    // Copy cached view if not dirty
    if (!markDirty) {
      newModel._cachedView = _cachedView;
      newModel._viewDirty = false;
    } else {
      newModel._viewDirty = true;
    }
    return newModel;
  }

  tui.Cmd _scheduleNewLog() {
    // Random interval between 50-300ms for realistic log flow
    final interval = 50 + _random.nextInt(250);
    return tui.Cmd.tick(Duration(milliseconds: interval), (_) {
      return _NewLogMsg(_generateLogEntry());
    });
  }

  tui.Cmd _scheduleSparklineUpdate() {
    return tui.Cmd.tick(
      const Duration(seconds: 1),
      (_) => const _SparklineTickMsg(),
    );
  }

  @override
  tui.Cmd? init() {
    // Schedule log generation and sparkline updates
    // Frame ticks are automatic via ProgramOptions.frameTick
    return tui.Cmd.batch([_scheduleNewLog(), _scheduleSparklineUpdate()]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    // Handle debug overlay updates first
    final debugUpdate = debugOverlay.update(msg);
    var nextDebug = debugUpdate.model;

    switch (msg) {
      case tui.RenderMetricsMsg():
        return (copyWith(debugOverlay: nextDebug), null);

      case tui.WindowSizeMsg(:final width, :final height):
        // Calculate log panel height responsively
        // Fixed panels: header(4) + nav(3) + breadcrumb(4) + footer(3) = 14
        final fixedPanelsHeight = 14;
        final logPanelHeight = math.max(6, height - fixedPanelsHeight);
        // Content area inside log panel (minus borders and chrome)
        final logContentHeight = math.max(
          3,
          logPanelHeight - 8,
        ); // 8 = borders + search + follow + controls + spacing

        final nextViewport = viewport.copyWith(
          width: width - 4,
          height: logContentHeight,
        );
        // Re-format filtered logs for new width
        final logLines = filteredLogs
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
        // Search mode handling
        if (searchMode) {
          if (key.type == tui.KeyType.escape) {
            return (copyWith(searchMode: false, debugOverlay: nextDebug), null);
          }
          if (key.type == tui.KeyType.enter) {
            // Apply search and exit search mode
            final query = searchInput.value;
            return (
              _updateViewportWithFilter(
                levelFilter,
                projectFilter,
                query,
                nextDebug,
              ).copyWith(searchMode: false),
              null,
            );
          }
          // Forward to text input
          final (nextInput, inputCmd) = searchInput.update(tui.KeyMsg(key));
          return (
            copyWith(searchInput: nextInput, debugOverlay: nextDebug),
            inputCmd,
          );
        }

        // Dismiss alert with Enter
        if (key.type == tui.KeyType.enter && alerts.isNotEmpty) {
          final newAlerts = alerts.sublist(1);
          return (copyWith(alerts: newAlerts, debugOverlay: nextDebug), null);
        }

        // Quit
        if (key.isChar('q') || key.type == tui.KeyType.escape) {
          return (this, tui.Cmd.quit());
        }

        // Enter search mode
        if (key.isChar('/')) {
          final focusCmd = searchInput.focus();
          return (
            copyWith(searchMode: true, debugOverlay: nextDebug),
            focusCmd,
          );
        }

        // Toggle debug overlay
        if (key.isChar('u') || key.isChar('U')) {
          return (copyWith(debugOverlay: nextDebug.toggle()), null);
        }

        // Toggle stats panel
        if (key.isChar('s') || key.isChar('S')) {
          return (
            copyWith(showStats: !showStats, debugOverlay: nextDebug),
            null,
          );
        }

        // Cycle color themes
        if (key.isChar('c') || key.isChar('C')) {
          final themes = ThemePalette.names;
          final currentIdx = themes.indexOf(theme);
          final nextIdx = (currentIdx + 1) % themes.length;
          final nextTheme = themes[nextIdx];
          return (copyWith(theme: nextTheme, debugOverlay: nextDebug), null);
        }

        // Sub-tab switching (A-D)
        if (key.isChar('a') || key.isChar('A')) {
          return (copyWith(activeSubTab: 0, debugOverlay: nextDebug), null);
        }
        if (key.isChar('b') || key.isChar('B')) {
          return (copyWith(activeSubTab: 1, debugOverlay: nextDebug), null);
        }
        // Note: C is taken by theme cycle, using Shift+C for sub-tab
        // D is taken by debug filter

        // Main tab switching (1-6)
        if (key.isChar('1')) {
          return (copyWith(activeMainTab: 0, debugOverlay: nextDebug), null);
        }
        if (key.isChar('2')) {
          return (copyWith(activeMainTab: 1, debugOverlay: nextDebug), null);
        }
        if (key.isChar('3')) {
          return (copyWith(activeMainTab: 2, debugOverlay: nextDebug), null);
        }
        if (key.isChar('4')) {
          return (copyWith(activeMainTab: 3, debugOverlay: nextDebug), null);
        }
        if (key.isChar('5')) {
          return (copyWith(activeMainTab: 4, debugOverlay: nextDebug), null);
        }
        if (key.isChar('6')) {
          return (copyWith(activeMainTab: 5, debugOverlay: nextDebug), null);
        }

        // Log level filter toggles (F1-F4 or Shift+I/D/W/E)
        if (key.isChar('I')) {
          final newFilter = Set<LogLevel>.from(levelFilter);
          if (newFilter.contains(LogLevel.info)) {
            newFilter.remove(LogLevel.info);
          } else {
            newFilter.add(LogLevel.info);
          }
          return (
            _updateViewportWithFilter(
              newFilter,
              projectFilter,
              searchQuery,
              nextDebug,
            ),
            null,
          );
        }
        if (key.isChar('D')) {
          final newFilter = Set<LogLevel>.from(levelFilter);
          if (newFilter.contains(LogLevel.debug)) {
            newFilter.remove(LogLevel.debug);
          } else {
            newFilter.add(LogLevel.debug);
          }
          return (
            _updateViewportWithFilter(
              newFilter,
              projectFilter,
              searchQuery,
              nextDebug,
            ),
            null,
          );
        }
        if (key.isChar('W')) {
          final newFilter = Set<LogLevel>.from(levelFilter);
          if (newFilter.contains(LogLevel.warning)) {
            newFilter.remove(LogLevel.warning);
          } else {
            newFilter.add(LogLevel.warning);
          }
          return (
            _updateViewportWithFilter(
              newFilter,
              projectFilter,
              searchQuery,
              nextDebug,
            ),
            null,
          );
        }
        if (key.isChar('E')) {
          final newFilter = Set<LogLevel>.from(levelFilter);
          if (newFilter.contains(LogLevel.error)) {
            newFilter.remove(LogLevel.error);
          } else {
            newFilter.add(LogLevel.error);
          }
          return (
            _updateViewportWithFilter(
              newFilter,
              projectFilter,
              searchQuery,
              nextDebug,
            ),
            null,
          );
        }

        // Clear all filters
        if (key.isChar('x') || key.isChar('X')) {
          final allLevels = {
            LogLevel.info,
            LogLevel.debug,
            LogLevel.warning,
            LogLevel.error,
          };
          return (
            _updateViewportWithFilter(allLevels, null, '', nextDebug),
            null,
          );
        }

        // Cycle through project filter
        if (key.isChar('p')) {
          final projectList = [null, ..._logProjects];
          final currentIndex = projectFilter == null
              ? 0
              : projectList.indexOf(projectFilter);
          final nextIndex = (currentIndex + 1) % projectList.length;
          final nextProject = projectList[nextIndex];
          return (
            _updateViewportWithFilter(
              levelFilter,
              nextProject,
              searchQuery,
              nextDebug,
            ),
            null,
          );
        }

        // Toggle live mode
        if (key.isChar('t')) {
          return (copyWith(liveMode: !liveMode, debugOverlay: nextDebug), null);
        }

        // Refresh (simulate latency change)
        if (key.isChar('r')) {
          final newLatency = 50 + _random.nextInt(200);
          return (
            copyWith(latencyMs: newLatency, debugOverlay: nextDebug),
            null,
          );
        }

        // Go to bottom (follow mode)
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

        // Delegate scroll keys to viewport
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
          return (copyWith(debugOverlay: nextDebug), _scheduleNewLog());
        }

        var newLogs = List<LogEntry>.from(logs)..add(entry);
        var newTotal = totalLogs + 1;
        var newStats = logStats.addLog(entry.level);

        if (newLogs.length > maxLogs) {
          newLogs = newLogs.sublist(newLogs.length - maxLogs);
        }

        // Check for alert conditions (high error rate)
        var newAlerts = List<Alert>.from(alerts);
        if (entry.level == LogLevel.error &&
            newStats.errorRate > 15 &&
            alerts.length < 3) {
          newAlerts.add(
            Alert(
              message:
                  'High error rate: ${newStats.errorRate.toStringAsFixed(1)}%',
              severity: LogLevel.error,
              timestamp: DateTime.now(),
            ),
          );
        }

        // Update viewport content with filtered logs
        final filtered = newLogs.where((log) {
          if (!levelFilter.contains(log.level)) return false;
          if (projectFilter != null && log.project != projectFilter) {
            return false;
          }
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            if (!log.message.toLowerCase().contains(query) &&
                !log.source.toLowerCase().contains(query) &&
                !log.project.toLowerCase().contains(query)) {
              return false;
            }
          }
          return true;
        }).toList();

        final logLines = filtered
            .map((e) => _formatLogEntry(e, viewport.width))
            .toList();
        var nextViewport = viewport.setContent(logLines.join('\n'));

        // Auto-scroll if it was at the bottom before adding the new log
        if (viewport.atBottom) {
          nextViewport = nextViewport.gotoBottom();
        }

        // Simulate latency fluctuation
        final newLatency = latencyMs + (_random.nextInt(21) - 10);
        final clampedLatency = newLatency.clamp(50, 300);

        return (
          copyWith(
            logs: newLogs,
            totalLogs: newTotal,
            viewport: nextViewport,
            logStats: newStats,
            alerts: newAlerts,
            debugOverlay: nextDebug,
            latencyMs: clampedLatency,
          ),
          _scheduleNewLog(),
        );

      case tui.FrameTickMsg(:final time):
        // Only update time if the second changed (avoid unnecessary rebuilds)
        final timeChanged = time.second != currentTime.second;
        return (
          timeChanged
              ? copyWith(currentTime: time, debugOverlay: nextDebug)
              : copyWith(debugOverlay: nextDebug, markDirty: false),
          null, // No manual tick needed - FrameTickMsg is automatic
        );

      case _SparklineTickMsg():
        // Update sparkline with current log rate
        final logsLastSecond = logStats.recentLogs
            .where(
              (t) => t.isAfter(
                DateTime.now().subtract(const Duration(seconds: 1)),
              ),
            )
            .length;
        final newSparkline = sparkline.addValue(logsLastSecond);

        // Simulate system metrics fluctuation
        final newCpu = (cpuUsage + (_random.nextDouble() * 10 - 5)).clamp(
          10.0,
          95.0,
        );
        final newMem = (memUsage + (_random.nextDouble() * 4 - 2)).clamp(
          30.0,
          90.0,
        );
        final newNetIn = (networkIn + (_random.nextDouble() * 0.4 - 0.2)).clamp(
          0.1,
          5.0,
        );
        final newNetOut = (networkOut + (_random.nextDouble() * 0.3 - 0.15))
            .clamp(0.1, 3.0);

        return (
          copyWith(
            sparkline: newSparkline,
            cpuUsage: newCpu,
            memUsage: newMem,
            networkIn: newNetIn,
            networkOut: newNetOut,
            debugOverlay: nextDebug,
          ),
          _scheduleSparklineUpdate(),
        );

      case _DismissAlertMsg():
        final newAlerts = alerts.isNotEmpty ? alerts.sublist(1) : <Alert>[];
        return (copyWith(alerts: newAlerts, debugOverlay: nextDebug), null);

      default:
        return (copyWith(debugOverlay: nextDebug), null);
    }
  }

  /// Helper to update viewport content when filters change
  CommandCenterModel _updateViewportWithFilter(
    Set<LogLevel> newLevelFilter,
    String? newProjectFilter,
    String newSearchQuery,
    tui.DebugOverlayModel newDebug,
  ) {
    final filtered = logs.where((log) {
      if (!newLevelFilter.contains(log.level)) return false;
      if (newProjectFilter != null && log.project != newProjectFilter) {
        return false;
      }
      if (newSearchQuery.isNotEmpty) {
        final query = newSearchQuery.toLowerCase();
        if (!log.message.toLowerCase().contains(query) &&
            !log.source.toLowerCase().contains(query) &&
            !log.project.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    final logLines = filtered
        .map((e) => _formatLogEntry(e, viewport.width))
        .toList();
    final newViewport = viewport.setContent(logLines.join('\n'));

    return copyWith(
      levelFilter: newLevelFilter,
      projectFilter: newProjectFilter,
      searchQuery: newSearchQuery,
      viewport: newViewport,
      debugOverlay: newDebug,
    );
  }

  @override
  String view() {
    if (width == 0 || height == 0) return 'Initializing...';

    // Only rebuild content if dirty
    if (_viewDirty) {
      _rebuildView();
      _viewDirty = false;
    }

    // Always apply debug overlay (it shows live metrics)
    if (debugOverlay.enabled) {
      return debugOverlay.compose(_cachedView);
    }
    return _cachedView;
  }

  void _rebuildView() {
    // Use responsive layout with splitVertical
    // Total screen area
    final screenArea = uv.Rectangle(
      minX: 0,
      minY: 0,
      maxX: width,
      maxY: height,
    );

    // Panel 1: Header - Fixed 4 lines (title + project + borders)
    final (:top, :bottom) = uv.splitVertical(screenArea, const uv.Fixed(4));
    final headerArea = top;
    var remainingArea = bottom;

    // Panel 2: Navigation - Fixed 3 lines
    final split2 = uv.splitVertical(remainingArea, const uv.Fixed(3));
    final navArea = split2.top;
    remainingArea = split2.bottom;

    // Panel 3: Breadcrumb - Fixed 4 lines
    final split3 = uv.splitVertical(remainingArea, const uv.Fixed(4));
    final breadcrumbArea = split3.top;
    remainingArea = split3.bottom;

    // Panel 5: Footer - Fixed 3 lines (take from bottom)
    // Remaining area is split into log panel (flexible) and footer (fixed 3 lines)
    final logArea = uv.Rectangle(
      minX: remainingArea.minX,
      minY: remainingArea.minY,
      maxX: remainingArea.maxX,
      maxY: remainingArea.maxY - 3, // Reserve 3 lines for footer
    );
    final footerArea = uv.Rectangle(
      minX: remainingArea.minX,
      minY: remainingArea.maxY - 3,
      maxX: remainingArea.maxX,
      maxY: remainingArea.maxY,
    );

    final lines = <String>[];

    // Panel 1: Header Panel
    lines.addAll(_buildHeaderPanel(headerArea.height));

    // Panel 2: Navigation Tabs Panel
    lines.addAll(_buildNavigationPanel(navArea.height));

    // Panel 3: Breadcrumb + Sub-tabs Panel
    lines.addAll(_buildBreadcrumbPanel(breadcrumbArea.height));

    // Panel 4: Main Log Panel (fills remaining space)
    lines.addAll(_buildLogPanel(logArea.height));

    // Panel 5: Footer Panel
    lines.addAll(_buildFooterPanel(footerArea.height));

    // Ensure exact fit to screen height
    while (lines.length < height) {
      lines.add('');
    }
    if (lines.length > height) {
      lines.removeRange(height, lines.length);
    }

    final content = lines.join('\n');
    _cachedView = content;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 1: Header Panel (fixed height)
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildHeaderPanel(int panelHeight) {
    // Title line
    final title = _accentBoldStyle().render('◆ ███ ███ COMMAND CENTER ◆');

    // Theme indicator - style based on theme name
    final themeLabel = switch (theme) {
      'dark' => _textDimStyle().render('[DARK]'),
      'light' => _textStyle().render('[LIGHT]'),
      'hacker' => _successStyle().render('[HACKER]'),
      'ocean' => _infoStyle().render('[OCEAN]'),
      'monokai' => _warningStyle().render('[MONOKAI]'),
      'dracula' => _highlightStyle().render('[DRACULA]'),
      'nord' => _infoStyle().render('[NORD]'),
      'solarizedDark' => _warningStyle().render('[SOLARIZED DARK]'),
      'solarizedLight' => _textStyle().render('[SOLARIZED LIGHT]'),
      _ => _textDimStyle().render('[${theme.toUpperCase()}]'),
    };

    // Time and version (right side)
    final timeStr = _formatTime(currentTime);
    final rightSide =
        '$themeLabel  ${_textStyle().render(timeStr)}  ${_textDimStyle().render(version)}';

    // Project line with pills/badges and optional alert
    final projectLine = _buildProjectLine();

    // Alert line if any alerts
    String? alertLine;
    if (alerts.isNotEmpty) {
      final alert = alerts.first;
      final alertStyle = switch (alert.severity) {
        LogLevel.error => _errorStyle().bold(),
        LogLevel.warning => _warningStyle().bold(),
        _ => _accentStyle(),
      };
      alertLine = alertStyle.render(
        '⚠ ALERT: ${alert.message}  [press Enter to dismiss]',
      );
    }

    // Build content lines
    final titleLen = Style.visibleLength(title);
    final rightLen = Style.visibleLength(rightSide);
    final innerWidth = width - 4; // Account for panel borders and padding

    // First line: title on left, time/version on right
    final padding1 = innerWidth - titleLen - rightLen;
    final line1 = padding1 > 0
        ? '$title${' ' * padding1}$rightSide'
        : '$title  $rightSide';

    final lines = [line1, projectLine];
    if (alertLine != null) {
      lines.add(alertLine);
    }

    final panel = tui.Panel()
        .lines(lines)
        .border(Border.rounded)
        .borderStyle(_borderStyle())
        .padding(0, 1)
        .width(width);

    return panel.render().split('\n');
  }

  String _buildProjectLine() {
    final label = _accentStyle().render('● PROJECT:');
    final countStr = _textStyle().render(
      ' ${projects.length} total projects: ',
    );

    final pills = <String>[];
    for (final project in projects) {
      pills.add(_buildPill(project));
    }

    return '$label$countStr${pills.join(' ')}';
  }

  String _buildPill(String text) {
    // Create a pill/badge style
    return _textDimStyle().render('[$text]');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 2: Navigation Tabs Panel (fixed height)
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildNavigationPanel(int panelHeight) {
    final buffer = StringBuffer();

    for (var i = 0; i < _mainTabs.length; i++) {
      final isActive = i == activeMainTab;
      final tabLabel = '${_mainTabs[i]}[${i + 1}]';

      if (i > 0) buffer.write(_textStyle().render(' | '));

      if (isActive) {
        buffer.write(_activeTabStyle().render(' $tabLabel '));
      } else {
        buffer.write(_textStyle().render(' $tabLabel '));
      }
    }

    final panel = tui.Panel()
        .content(buffer.toString())
        .border(Border.rounded)
        .borderStyle(_borderStyle())
        .padding(0, 1)
        .width(width);

    return panel.render().split('\n');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 3: Breadcrumb + Sub-tabs Panel (fixed height)
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildBreadcrumbPanel(int panelHeight) {
    // Breadcrumb line
    final breadcrumb =
        '${_textStyle().render('Monitoring')} → ${_textBoldStyle().render('Logs')}';

    // Sub-tabs line
    final subTabsLine = _buildSubTabsLine();

    final panel = tui.Panel()
        .lines([breadcrumb, subTabsLine])
        .border(Border.rounded)
        .borderStyle(_borderStyle())
        .padding(0, 1)
        .width(width);

    return panel.render().split('\n');
  }

  String _buildSubTabsLine() {
    final buffer = StringBuffer();
    buffer.write('▶ ');

    final keys = ['A', 'B', 'C', 'D'];

    for (var i = 0; i < _subTabs.length; i++) {
      final isActive = i == activeSubTab;
      final tabLabel = '${_subTabs[i]} [${keys[i]}]';

      if (i > 0) buffer.write(_textStyle().render(' | '));

      if (isActive) {
        buffer.write(_accentStyle().render(tabLabel));
      } else {
        buffer.write(_textStyle().render(tabLabel));
      }
    }

    return buffer.toString();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 4: Main Log Panel (flexible height - fills remaining space)
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildLogPanel(int panelHeight) {
    // Calculate content height (panel height - 2 for border)
    final contentHeight = math.max(3, panelHeight - 2);

    // Title line: "◎ LOGS [1,908,196] ● LIVE"
    final titlePart = _accentBoldStyle().render('◎ LOGS');
    final countPart = '[${_formatNumber(totalLogs)}]';
    final liveIndicator = liveMode
        ? _successStyle().render('● LIVE')
        : _warningStyle().render('● PAUSED');
    final panelTitle = '$titlePart $countPart $liveIndicator';

    // Search/Filter bar
    final searchBar = _buildSearchFilterBar();

    // Scroll indicator
    final scrollIndicator = viewport.atBottom
        ? ''
        : _warningStyle().render(
            '▲ Scroll up for older (${logs.length} loaded / '
            '${_formatNumber(totalLogs)} total)',
          );

    // Follow indicator
    final followIndicator = viewport.atBottom
        ? _successStyle().render('● Following new logs')
        : _warningStyle().render('▲ Scrollback mode - Press G to follow');

    // Panel controls line
    final controlsLine = _buildLogPanelControls();

    // Calculate how many lines we have for actual log content
    // contentHeight - searchBar(1) - scrollIndicator(0-1) - spacing(2) - followIndicator(1) - controls(1)
    final hasScrollIndicator = scrollIndicator.isNotEmpty;
    final fixedLines =
        1 +
        (hasScrollIndicator ? 1 : 0) +
        2 +
        1 +
        1; // search + scroll? + spacing + follow + controls
    final logViewLines = math.max(1, contentHeight - fixedLines);

    // Get visible log lines from viewport, but limit to available space
    final viewportLines = viewport.view().split('\n');
    final visibleLogLines = viewportLines.take(logViewLines).toList();

    // Pad if needed
    while (visibleLogLines.length < logViewLines) {
      visibleLogLines.add('');
    }

    // Combine all content
    final contentLines = <String>[
      searchBar,
      if (hasScrollIndicator) scrollIndicator,
      '',
      ...visibleLogLines,
      '',
      followIndicator,
      controlsLine,
    ];

    final panel = tui.Panel()
        .lines(contentLines)
        .border(Border.rounded)
        .borderStyle(_borderStyle())
        .title(panelTitle)
        .padding(0, 1)
        .width(width);

    final rendered = panel.render().split('\n');

    // Ensure we return exactly panelHeight lines
    if (rendered.length > panelHeight) {
      return rendered.sublist(0, panelHeight);
    }
    while (rendered.length < panelHeight) {
      rendered.add(' ' * width);
    }
    return rendered;
  }

  String _buildSearchFilterBar() {
    final buffer = StringBuffer();

    // Search input - show active input in search mode
    if (searchMode) {
      buffer.write(_accentStyle().bold().render('[/] '));
      buffer.write(searchInput.view());
    } else if (searchQuery.isNotEmpty) {
      buffer.write(_accentStyle().render('[/] [ $searchQuery ]'));
    } else {
      buffer.write(_textStyle().render('[/] [ search ... ]'));
    }
    buffer.write('  ');

    // Project filter
    final projectLabel = projectFilter ?? 'All Projects';
    buffer.write(_textStyle().render('[p]'));
    buffer.write(' ');
    buffer.write(
      projectFilter != null
          ? _accentStyle().render(projectLabel)
          : _textDimStyle().render(projectLabel),
    );
    buffer.write('  ');

    // Level filters with toggle indicators
    final levels = [
      ('I', 'INF', LogLevel.info, _successStyle()),
      ('D', 'DBG', LogLevel.debug, _infoStyle()),
      ('W', 'WRN', LogLevel.warning, _warningStyle()),
      ('E', 'ERR', LogLevel.error, _errorStyle()),
    ];

    for (final (key, label, level, style) in levels) {
      final isActive = levelFilter.contains(level);
      buffer.write(_textStyle().render('[$key]'));
      buffer.write(' ');
      if (isActive) {
        buffer.write(style.render(label));
      } else {
        buffer.write(_textDimStyle().render('---'));
      }
      buffer.write('  ');
    }

    // Log stats
    buffer.write(_textDimStyle().render('│'));
    buffer.write(' ');
    buffer.write(_successStyle().render('${logStats.infoCount}'));
    buffer.write(_textDimStyle().render('/'));
    buffer.write(_infoStyle().render('${logStats.debugCount}'));
    buffer.write(_textDimStyle().render('/'));
    buffer.write(_warningStyle().render('${logStats.warningCount}'));
    buffer.write(_textDimStyle().render('/'));
    buffer.write(_errorStyle().render('${logStats.errorCount}'));

    // Error rate indicator
    if (logStats.total > 0) {
      buffer.write('  ');
      final errorRate = logStats.errorRate;
      final rateStyle = errorRate > 15
          ? _errorStyle().bold()
          : errorRate > 10
          ? _warningStyle()
          : _successStyle();
      buffer.write(rateStyle.render('${errorRate.toStringAsFixed(1)}% err'));
    }

    return buffer.toString();
  }

  String _buildLogPanelControls() {
    final buffer = StringBuffer();

    // Left side: controls
    final controls = ['[↑↓] Scroll', '[<>] Pan', '[T] Live', '[R] Refresh'];
    buffer.write(_textStyle().render(controls.join('  ')));

    // Calculate padding
    final leftPart = buffer.toString();
    final leftLen = Style.visibleLength(leftPart);

    // Right side: latency + time
    final latencyStr = _textStyle().render('${latencyMs}ms');
    final timeStr = _textStyle().render(_formatTime(currentTime));
    final rightPart = '$latencyStr  $timeStr';
    final rightLen = Style.visibleLength(rightPart);

    final innerWidth = width - 4; // Account for border and padding
    final padding = innerWidth - leftLen - rightLen;

    if (padding > 0) {
      return '$leftPart${' ' * padding}$rightPart';
    }
    return '$leftPart  $rightPart';
  }

  String _formatLogEntry(LogEntry entry, int maxWidth) {
    // Timestamp: [HH:MM:SS]
    final h = entry.timestamp.hour.toString().padLeft(2, '0');
    final m = entry.timestamp.minute.toString().padLeft(2, '0');
    final s = entry.timestamp.second.toString().padLeft(2, '0');
    final timestamp = _textStyle().render('[$h:$m:$s]');

    // Level with color
    final levelStyle = switch (entry.level) {
      LogLevel.info => _successStyle(),
      LogLevel.debug => _infoStyle(),
      LogLevel.warning => _warningStyle(),
      LogLevel.error => _errorStyle().bold(),
    };
    final level = levelStyle.render(entry.levelStr);

    // Project/Env badge: "kasm/PROD" (accent/success pill style)
    final projectBadge =
        '${_accentStyle().render(entry.project)}/'
        '${_successStyle().render(entry.environment)}';

    // Source tag: [kasm_rdp] (highlight in brackets)
    final sourceTag = _highlightStyle().render('[${entry.source}]');

    // ISO timestamp for the message
    final isoTime = _formatIsoTimestamp(entry.timestamp);

    // Build file:line if present
    String fileLine = '';
    if (entry.filename != null && entry.lineNumber != null) {
      fileLine = '${entry.filename}:${entry.lineNumber} ';
    }

    // Full message
    final message = '$isoTime $fileLine${entry.message}';

    // Build the log line
    final parts = [timestamp, level, projectBadge, sourceTag, message];
    var line = parts.join(' ');

    // Truncate if too long
    final visibleLen = Style.visibleLength(line);
    if (visibleLen > maxWidth) {
      // Crude truncation - keep ANSI codes but add ellipsis
      final overflow = visibleLen - maxWidth + 1;
      if (line.length > overflow + 3) {
        line = '${line.substring(0, line.length - overflow)}→';
      }
    }

    return line;
  }

  String _formatIsoTimestamp(DateTime dt) {
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$y-$mo-${d}T$h:$m:$s.${ms}Z';
  }

  String _formatNumber(int n) {
    final str = n.toString();
    final result = StringBuffer();
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Panel 5: Footer Panel (fixed height)
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _buildFooterPanel(int panelHeight) {
    // Left side: sparkline showing log rate
    final sparklineStr = _accentStyle().render(sparkline.render(20));
    final rateStr = _successStyle().render(
      '${logStats.logsPerSecond.toStringAsFixed(1)}/s',
    );
    final leftPart =
        '${_textStyle().render('LOG RATE:')} $sparklineStr $rateStr';

    // Middle: key shortcuts
    final shortcuts = _textDimStyle().render(
      '[/]Search [C]Theme [S]Stats [U]Debug [Q]Quit',
    );

    // Right side: system stats if enabled
    String rightPart;
    if (showStats) {
      final cpu = _colorForPercent(
        cpuUsage,
      ).render('CPU:${cpuUsage.toStringAsFixed(0)}%');
      final mem = _colorForPercent(
        memUsage,
      ).render('MEM:${memUsage.toStringAsFixed(0)}%');
      final net = _textStyle().render(
        'NET:↓${networkIn.toStringAsFixed(1)} ↑${networkOut.toStringAsFixed(1)}',
      );
      rightPart = '$cpu $mem $net';
    } else {
      final breadcrumb =
          '${_accentStyle().render('MONITORING')} → ${_textBoldStyle().render('LOGS')}';
      rightPart = breadcrumb;
    }

    // Calculate padding
    final leftLen = Style.visibleLength(leftPart);
    final midLen = Style.visibleLength(shortcuts);
    final rightLen = Style.visibleLength(rightPart);
    final innerWidth = width - 4; // Account for border and padding

    final totalLen = leftLen + midLen + rightLen;
    final availPadding = innerWidth - totalLen;

    String content;
    if (availPadding > 4) {
      final pad1 = availPadding ~/ 2;
      final pad2 = availPadding - pad1;
      content = '$leftPart${' ' * pad1}$shortcuts${' ' * pad2}$rightPart';
    } else if (availPadding > 0) {
      content = '$leftPart $shortcuts $rightPart';
    } else {
      // Too narrow, just show left and right
      final padding = innerWidth - leftLen - rightLen;
      content = padding > 0
          ? '$leftPart${' ' * padding}$rightPart'
          : '$leftPart $rightPart';
    }

    final panel = tui.Panel()
        .content(content)
        .border(Border.rounded)
        .borderStyle(_borderStyle())
        .padding(0, 1)
        .width(width);

    return panel.render().split('\n');
  }

  Style _colorForPercent(double percent) {
    if (percent > 80) return _errorStyle();
    if (percent > 60) return _warningStyle();
    return _successStyle();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m:$s $ampm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  final p = tui.Program(
    CommandCenterModel.initial(),
    options: const tui.ProgramOptions(
      useUltravioletRenderer: true,
      altScreen: true,
      metricsInterval: Duration(
        milliseconds: 250,
      ), // Update metrics 4x per second
      mouseMode: tui.MouseMode.allMotion,
    ),
  );

  await p.run();
}
