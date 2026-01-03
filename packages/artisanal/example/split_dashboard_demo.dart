import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/src/tui/harmonica.dart' as hz;

/// Helper class to read real system info from /proc/ (Linux)
class SystemInfo {
  // CPU tracking for delta calculation
  int _lastCpuTotal = 0;
  int _lastCpuIdle = 0;
  double cpuPercent = 0.0;

  // Network tracking for rate calculation
  int _lastNetRx = 0;
  int _lastNetTx = 0;
  int netRxRate = 0; // bytes/sec
  int netTxRate = 0;
  int totalNetRx = 0;
  int totalNetTx = 0;

  // Memory info
  int memTotal = 0;
  int memUsed = 0;
  int memAvailable = 0;
  double memPercent = 0.0;

  // Disk info
  int diskTotal = 0;
  int diskUsed = 0;
  int diskAvailable = 0;
  double diskPercent = 0.0;

  // Process/system info
  int processCount = 0;
  int uptime = 0; // seconds
  int tcpConnections = 0;

  DateTime _lastUpdate = DateTime.now();

  void update() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;

    if (Platform.isLinux) {
      _updateCpuLinux();
      _updateMemLinux();
      _updateNetLinux(elapsed);
      _updateDiskLinux();
      _updateProcessCountLinux();
      _updateUptimeLinux();
      _updateTcpConnectionsLinux();
    } else {
      // Fallback for non-Linux (use fake data)
      cpuPercent = 30 + (DateTime.now().millisecond % 40).toDouble();
      memPercent = 50 + (DateTime.now().millisecond % 30).toDouble();
    }
  }

  void _updateCpuLinux() {
    try {
      final stat = File('/proc/stat').readAsStringSync();
      final line = stat.split('\n').first; // cpu  user nice system idle ...
      final parts = line
          .split(RegExp(r'\s+'))
          .skip(1)
          .take(7)
          .map(int.parse)
          .toList();
      final idle = parts[3];
      final total = parts.reduce((a, b) => a + b);

      if (_lastCpuTotal > 0) {
        final deltaTotal = total - _lastCpuTotal;
        final deltaIdle = idle - _lastCpuIdle;
        if (deltaTotal > 0) {
          cpuPercent = 100.0 * (1 - deltaIdle / deltaTotal);
        }
      }
      _lastCpuTotal = total;
      _lastCpuIdle = idle;
    } catch (_) {}
  }

  void _updateMemLinux() {
    try {
      final meminfo = File('/proc/meminfo').readAsStringSync();
      int? total, available, free, buffers, cached;
      for (final line in meminfo.split('\n')) {
        final parts = line.split(RegExp(r'[:\s]+'));
        if (parts.length >= 2) {
          final val = int.tryParse(parts[1]) ?? 0;
          switch (parts[0]) {
            case 'MemTotal':
              total = val;
              break;
            case 'MemAvailable':
              available = val;
              break;
            case 'MemFree':
              free = val;
              break;
            case 'Buffers':
              buffers = val;
              break;
            case 'Cached':
              cached = val;
              break;
          }
        }
      }
      memTotal = total ?? 0;
      memAvailable = available ?? (free ?? 0) + (buffers ?? 0) + (cached ?? 0);
      memUsed = memTotal - memAvailable;
      memPercent = memTotal > 0 ? 100.0 * memUsed / memTotal : 0;
    } catch (_) {}
  }

  void _updateNetLinux(double elapsed) {
    try {
      final netdev = File('/proc/net/dev').readAsStringSync();
      int rxTotal = 0, txTotal = 0;
      for (final line in netdev.split('\n').skip(2)) {
        final parts = line.trim().split(RegExp(r'[:\s]+'));
        if (parts.length >= 10 && !parts[0].startsWith('lo')) {
          rxTotal += int.tryParse(parts[1]) ?? 0;
          txTotal += int.tryParse(parts[9]) ?? 0;
        }
      }
      if (_lastNetRx > 0 && elapsed > 0) {
        netRxRate = ((rxTotal - _lastNetRx) / elapsed).round();
        netTxRate = ((txTotal - _lastNetTx) / elapsed).round();
      }
      _lastNetRx = rxTotal;
      _lastNetTx = txTotal;
      totalNetRx = rxTotal;
      totalNetTx = txTotal;
    } catch (_) {}
  }

  void _updateDiskLinux() {
    try {
      final result = Process.runSync('df', ['-B1', '/']);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        if (lines.length >= 2) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            diskTotal = int.tryParse(parts[1]) ?? 0;
            diskUsed = int.tryParse(parts[2]) ?? 0;
            diskAvailable = int.tryParse(parts[3]) ?? 0;
            diskPercent = diskTotal > 0 ? 100.0 * diskUsed / diskTotal : 0;
          }
        }
      }
    } catch (_) {}
  }

  void _updateProcessCountLinux() {
    try {
      final dir = Directory('/proc');
      processCount = dir.listSync().where((e) {
        final name = e.path.split('/').last;
        return int.tryParse(name) != null;
      }).length;
    } catch (_) {}
  }

  void _updateUptimeLinux() {
    try {
      final content = File('/proc/uptime').readAsStringSync();
      uptime = double.parse(content.split(' ').first).round();
    } catch (_) {}
  }

  void _updateTcpConnectionsLinux() {
    try {
      final tcp = File('/proc/net/tcp').readAsStringSync();
      final tcp6 = File('/proc/net/tcp6').readAsStringSync();
      // Count established connections (state 01)
      tcpConnections =
          tcp.split('\n').where((l) => l.contains(' 01 ')).length +
          tcp6.split('\n').where((l) => l.contains(' 01 ')).length;
    } catch (_) {}
  }

  String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
    return '${bytes}B';
  }

  String formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m ${seconds % 60}s';
  }
}

class LogMsg extends tui.Msg {
  const LogMsg(this.text);
  final String text;
}

class SysInfoMsg extends tui.Msg {
  const SysInfoMsg();
}

class DashboardModel implements tui.Model {
  DashboardModel()
    : cpuProgress = tui.ProgressModel(width: 20, fullColor: '#AF87FF'),
      memProgress = tui.ProgressModel(width: 20, fullColor: '#5F87FF'),
      netProgress = tui.ProgressModel(width: 20, fullColor: '#00AFFF'),
      dskProgress = tui.ProgressModel(width: 20, fullColor: '#FFAF00'),
      blockSpring = hz.newSpringFromFps(60, 5.0, 0.5),
      debugOverlay = tui.DebugOverlayModel.initial(rendererLabel: 'UV'),
      sysInfo = SystemInfo();

  tui.ProgressModel cpuProgress;
  tui.ProgressModel memProgress;
  tui.ProgressModel netProgress;
  tui.ProgressModel dskProgress;
  final SystemInfo sysInfo;

  List<String> logs = [];
  int logCounter = 0;
  int width = 0;
  int height = 0;
  double splitRatio = 0.55;
  int logIntervalMs = 50;
  bool autoScroll = true; // Track if at bottom for indicator

  /// Scroll offset for logs (0 = show oldest, max = show newest)
  int _scrollOffset = 0;

  // Animation state
  double blockPos = 0.0;
  List<double> verticalBars = List.generate(10, (_) => 0.0);

  // Spring state for blocks
  final hz.Spring blockSpring;
  List<double> blockSpringPos = List.generate(4, (_) => 0.0);
  List<double> blockSpringVel = List.generate(4, (_) => 0.0);
  List<double> blockTargets = List.generate(4, (_) => 0.0);
  int nextBlockIndex = 0;
  bool isMovingRight = true;
  int animationDelay = 0;

  tui.DebugOverlayModel debugOverlay;

  // Precomputed view string (computed in update, returned in view)
  String _cachedView = 'Initializing...';
  bool _viewDirty = true;

  // Cached styles (created once)
  static final _headerStyle = Style().foreground(Colors.cyan).bold();
  static final _footerStyle = Style().foreground(Colors.gray);
  static final _cpuLabelStyle = Style().foreground(BasicColor('#AF87FF'));
  static final _memLabelStyle = Style().foreground(BasicColor('#5F87FF'));
  static final _netLabelStyle = Style().foreground(BasicColor('#00AFFF'));
  static final _dskLabelStyle = Style().foreground(BasicColor('#FFAF00'));
  static final _statsLabelStyle = Style().foreground(Colors.purple);
  static final _blockColors = [
    Style().foreground(Colors.pink),
    Style().foreground(Colors.cyan),
    Style().foreground(Colors.yellow),
    Style().foreground(Colors.green),
  ];
  static final _barColorPink = Style().foreground(Colors.pink);
  static final _barColorYellow = Style().foreground(Colors.yellow);

  @override
  tui.Cmd? init() {
    // Only schedule log generation - frame ticks are automatic via ProgramOptions.frameTick
    return tui.Cmd.batch([_generateLog(), _scheduleSysInfoUpdate()]);
  }

  tui.Cmd _scheduleSysInfoUpdate() {
    return tui.Cmd.tick(
      const Duration(milliseconds: 500),
      (_) => const SysInfoMsg(),
    );
  }

  tui.Cmd _generateLog() {
    return tui.Cmd.tick(Duration(milliseconds: logIntervalMs), (_) {
      logCounter++;
      return LogMsg(
        'Test output $logCounter: This should appear above the renderer and scroll naturally',
      );
    });
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd>[];

    // Handle debug overlay updates first
    final debugUpdate = debugOverlay.update(msg);
    debugOverlay = debugUpdate.model;
    if (debugUpdate.consumed) {
      return (this, debugUpdate.cmd);
    }

    switch (msg) {
      case tui.RenderMetricsMsg():
        // Metrics updated in debugOverlay.update - no view rebuild needed
        return (this, null);

      case tui.WindowSizeMsg(:final width, :final height):
        this.width = width;
        this.height = height;
        final progressWidth = (width - 12).clamp(10, 200);
        cpuProgress = cpuProgress.copyWith(width: progressWidth);
        memProgress = memProgress.copyWith(width: progressWidth);
        netProgress = netProgress.copyWith(width: progressWidth);
        dskProgress = dskProgress.copyWith(width: progressWidth);
        _viewDirty = true;
        break;

      case tui.MouseMsg(:final button, :final action):
        if (action == tui.MouseAction.press ||
            action == tui.MouseAction.wheel) {
          // Handle mouse wheel scroll - scrolls entire screen
          if (button == tui.MouseButton.wheelUp) {
            _scrollOffset -= 3;
            autoScroll = false; // User is scrolling, disable auto-scroll
            _viewDirty = true;
          } else if (button == tui.MouseButton.wheelDown) {
            _scrollOffset += 3;
            // autoScroll will be re-enabled in _rebuildView if at bottom
            _viewDirty = true;
          }
        }
        break;

      case tui.KeyMsg(key: final key):
        if (key.isChar('q') || key.type == tui.KeyType.escape) {
          return (this, tui.Cmd.quit());
        }
        if (key.isChar('u')) {
          debugOverlay = debugOverlay.toggle();
        }
        if (key.isChar('+')) {
          splitRatio = (splitRatio + 0.05).clamp(0.1, 0.9);
          _viewDirty = true;
        }
        if (key.isChar('-')) {
          splitRatio = (splitRatio - 0.05).clamp(0.1, 0.9);
          _viewDirty = true;
        }
        if (key.isChar('m')) {
          logIntervalMs = (logIntervalMs - 10).clamp(1, 1000);
        }
        if (key.isChar('l')) {
          logIntervalMs = (logIntervalMs + 10).clamp(1, 1000);
        }
        // Scroll controls - scrolls entire screen (logs + panels)
        if (key.type == tui.KeyType.up || key.isChar('k')) {
          _scrollOffset -= 1;
          autoScroll = false;
          _viewDirty = true;
        }
        if (key.type == tui.KeyType.down || key.isChar('j')) {
          _scrollOffset += 1;
          _viewDirty = true;
        }
        if (key.type == tui.KeyType.pageUp) {
          _scrollOffset -= (height ~/ 2);
          autoScroll = false;
          _viewDirty = true;
        }
        if (key.type == tui.KeyType.pageDown) {
          _scrollOffset += (height ~/ 2);
          _viewDirty = true;
        }
        if (key.type == tui.KeyType.home || key.isChar('g')) {
          // Go to top of scrollback (oldest logs)
          _scrollOffset = 0;
          autoScroll = false;
          _viewDirty = true;
        }
        if (key.type == tui.KeyType.end || key.isChar('G')) {
          // Jump back to live panel (bottom) and re-enable auto-scroll
          autoScroll = true;
          _viewDirty = true;
        }
        break;

      case LogMsg(:final text):
        logs.add(text);
        if (logs.length > 2000) logs.removeAt(0);
        cmds.add(_generateLog());
        // Mark dirty so view rebuilds on next frame tick
        _viewDirty = true;
        break;

      case SysInfoMsg():
        sysInfo.update();
        cmds.add(_scheduleSysInfoUpdate());
        break;

      case tui.FrameTickMsg(:final time):
        // Update animations
        if (animationDelay > 0) {
          animationDelay--;
        } else {
          if (isMovingRight) {
            if (nextBlockIndex < 4) {
              blockTargets[nextBlockIndex] = 1.0;
              nextBlockIndex++;
              animationDelay = 12;
            } else {
              bool allReached = true;
              for (var p in blockSpringPos) {
                if (p < 0.98) allReached = false;
              }
              if (allReached) {
                isMovingRight = false;
                nextBlockIndex = 3;
                animationDelay = 40;
              }
            }
          } else {
            if (nextBlockIndex >= 0) {
              blockTargets[nextBlockIndex] = 0.0;
              blockSpringVel[nextBlockIndex] -= 5.0;
              nextBlockIndex--;
              animationDelay = 4;
            } else {
              bool allReached = true;
              for (var p in blockSpringPos) {
                if (p > 0.02) allReached = false;
              }
              if (allReached) {
                isMovingRight = true;
                nextBlockIndex = 0;
                animationDelay = 40;
              }
            }
          }
        }

        for (var i = 0; i < blockSpringPos.length; i++) {
          final (newPos, newVel) = blockSpring.update(
            blockSpringPos[i],
            blockSpringVel[i],
            blockTargets[i],
          );
          blockSpringPos[i] = newPos;
          blockSpringVel[i] = newVel;
        }

        for (var i = 0; i < verticalBars.length; i++) {
          verticalBars[i] =
              0.5 +
              0.5 * math.sin(time.millisecondsSinceEpoch / 200.0 + i * 0.8);
        }

        // Update progress bars with real values (sysInfo updated via SysInfoMsg)
        final (newCpu, cpuCmd) = cpuProgress.setPercent(
          sysInfo.cpuPercent / 100.0,
        );
        final (newMem, memCmd) = memProgress.setPercent(
          sysInfo.memPercent / 100.0,
        );
        // Network bar shows relative activity (capped at 10MB/s for full bar)
        final netActivity =
            (sysInfo.netRxRate + sysInfo.netTxRate) / (10 * 1024 * 1024);
        final (newNet, netCmd) = netProgress.setPercent(
          netActivity.clamp(0.0, 1.0),
        );
        final (newDsk, dskCmd) = dskProgress.setPercent(
          sysInfo.diskPercent / 100.0,
        );

        cpuProgress = newCpu;
        memProgress = newMem;
        netProgress = newNet;
        dskProgress = newDsk;

        if (cpuCmd != null) cmds.add(cpuCmd);
        if (memCmd != null) cmds.add(memCmd);
        if (netCmd != null) cmds.add(netCmd);
        if (dskCmd != null) cmds.add(dskCmd);

        // Mark dirty - view will be rebuilt lazily in view()
        _viewDirty = true;
        break;
    }

    // Delegate to progress components
    final (newCpu, cpuCmd) = cpuProgress.update(msg);
    cpuProgress = newCpu;
    if (cpuCmd != null) cmds.add(cpuCmd);

    final (newMem, memCmd) = memProgress.update(msg);
    memProgress = newMem;
    if (memCmd != null) cmds.add(memCmd);

    final (newNet, netCmd) = netProgress.update(msg);
    netProgress = newNet;
    if (netCmd != null) cmds.add(netCmd);

    final (newDsk, dskCmd) = dskProgress.update(msg);
    dskProgress = newDsk;
    if (dskCmd != null) cmds.add(dskCmd);

    return (this, tui.Cmd.batch(cmds));
  }

  /// Rebuild the cached view string
  void _rebuildView() {
    if (width == 0 || height == 0) {
      _cachedView = 'Initializing...';
      return;
    }

    // Build live panel content
    final title = _headerStyle
        .width(width)
        .render(' ◆ SPLIT MODE DEMO - ANIMATED DASHBOARD ◆');
    final animPanel = _buildAnimationPanel(width, 5);
    final sysPanel = _buildSystemMonitor(width);
    final statsPanel = _buildRealTimeStats(width);
    final scrollIndicator = autoScroll
        ? ''
        : ' [SCROLLBACK - Press G to return]';
    final footer = _footerStyle.render(
      '[↑↓/jk] Scroll | [PgUp/Dn] Page | [g] Top | [G] Live | [U] Debug$scrollIndicator',
    );

    // Build complete content buffer: logs + separator + panels
    // This is the "virtual document" that we scroll through
    final panelLines = [
      title,
      ...animPanel.split('\n'),
      ...sysPanel.split('\n'),
      ...statsPanel.split('\n'),
      footer,
    ];

    final totalLines = logs.length + panelLines.length;
    final maxOffset = (totalLines - height).clamp(0, totalLines);

    // Auto-scroll: when at bottom, keep scroll offset at max so new content is visible
    if (autoScroll) {
      _scrollOffset = maxOffset;
    }

    // Clamp scroll offset to valid range
    _scrollOffset = _scrollOffset.clamp(0, maxOffset);

    // Check if we're at the bottom (for autoScroll state)
    final atBottom = _scrollOffset >= maxOffset;
    if (atBottom && !autoScroll) {
      // User scrolled back to bottom, re-enable auto-scroll
      autoScroll = true;
    }

    // Extract visible window without copying the whole logs list
    final visibleLines = <String>[];
    for (var i = 0; i < height; i++) {
      final idx = _scrollOffset + i;
      if (idx < logs.length) {
        visibleLines.add(logs[idx]);
      } else {
        final pIdx = idx - logs.length;
        if (pIdx < panelLines.length) {
          visibleLines.add(panelLines[pIdx]);
        }
      }
    }

    // Pad if needed (when content is shorter than screen)
    while (visibleLines.length < height) {
      visibleLines.insert(0, '');
    }

    _cachedView = visibleLines.join('\n');
  }

  String _buildAnimationPanel(int w, int h) {
    final contentHeight = (h - 2).clamp(1, 10);
    final grid = List.generate(contentHeight, (_) => List.filled(w - 2, ' '));

    const blockStr = '███';
    final blockY = contentHeight - 1;
    final maxBlockX = (w - 20).clamp(0, w - 5);

    for (var i = 0; i < blockSpringPos.length; i++) {
      var pos = (blockSpringPos[i] * maxBlockX).toInt().clamp(0, maxBlockX);
      final style = _blockColors[i % _blockColors.length];
      for (var j = 0; j < blockStr.length; j++) {
        if (pos + j < grid[blockY].length) {
          grid[blockY][pos + j] = style.render(blockStr[j]);
        }
      }
    }

    final maxBarHeight = blockY;
    for (var i = 0; i < 5; i++) {
      final val = verticalBars[i % verticalBars.length];
      final fillLines = (val * maxBarHeight).round();
      final barX = w - 15 + i;
      if (barX >= 0 && barX < w - 2) {
        final color = i % 2 == 0 ? _barColorPink : _barColorYellow;
        for (var y = 0; y < contentHeight; y++) {
          if (y < fillLines) {
            grid[y][barX] = color.render('█');
          }
        }
      }
    }

    final content = grid.map((row) => row.join()).join('\n');
    return tui.PanelComponent(
      content: content,
      width: w,
      padding: 0,
      renderConfig: tui.RenderConfig(terminalWidth: width),
    ).render();
  }

  String _buildSystemMonitor(int w) {
    // Calculate available width for progress bars (w - borders - label - stats text)
    // Label ~5 chars, stats ~15 chars, borders 4 chars = ~24 overhead per line
    final barWidth = (w - 28).clamp(10, 100);

    final cpuPct = sysInfo.cpuPercent.toStringAsFixed(0).padLeft(3);
    final memPct = sysInfo.memPercent.toStringAsFixed(0).padLeft(3);
    final netRx = sysInfo.formatBytes(sysInfo.netRxRate);
    final netTx = sysInfo.formatBytes(sysInfo.netTxRate);
    final dskPct = sysInfo.diskPercent.toStringAsFixed(0).padLeft(3);

    // Create compact progress bars inline with gradient colors using blend1D
    final cpuBar = _miniBar(sysInfo.cpuPercent / 100, barWidth, [
      Colors.purple,
      Colors.pink,
    ]);
    final memBar = _miniBar(sysInfo.memPercent / 100, barWidth, [
      Colors.blue,
      Colors.sky,
    ]);
    final netBar = _miniBar(
      (sysInfo.netRxRate + sysInfo.netTxRate) / (10 * 1024 * 1024),
      barWidth,
      [Colors.teal, Colors.cyan],
    );
    final dskBar = _miniBar(sysInfo.diskPercent / 100, barWidth, [
      Colors.orange,
      Colors.yellow,
    ]);

    final content =
        '${_cpuLabelStyle.render('CPU:')} $cpuBar $cpuPct%\n'
        '${_memLabelStyle.render('MEM:')} $memBar $memPct%\n'
        '${_netLabelStyle.render('NET:')} $netBar ↓$netRx ↑$netTx\n'
        '${_dskLabelStyle.render('DSK:')} $dskBar $dskPct%';

    return tui.PanelComponent(
      content: content,
      title: 'SYSTEM MONITOR',
      width: w,
      renderConfig: tui.RenderConfig(terminalWidth: width),
    ).render();
  }

  String _miniBar(double percent, int width, List<Color> stops) {
    final filled = (percent.clamp(0, 1) * width).round();
    final empty = width - filled;

    if (filled == 0) {
      return Style().dim().render('░' * width);
    }

    // Use blend1D for smooth gradient
    final grad = blend1D(filled, stops, hasDarkBackground: true);
    final bar = grad.map((c) => Style().foreground(c).render('█')).join();

    return bar + Style().dim().render('░' * empty);
  }

  String _buildRealTimeStats(int w) {
    final totalNet = sysInfo.formatBytes(
      sysInfo.totalNetRx + sysInfo.totalNetTx,
    );
    final uptime = sysInfo.formatUptime(sysInfo.uptime);

    final content =
        '${_statsLabelStyle.render('NET TOTAL:')} $totalNet  '
        '${_statsLabelStyle.render('TCP:')} ${sysInfo.tcpConnections}  '
        '${_statsLabelStyle.render('PROC:')} ${sysInfo.processCount}  '
        '${_statsLabelStyle.render('UP:')} $uptime';

    return tui.PanelComponent(
      content: content,
      title: 'REAL-TIME STATS',
      width: w,
      renderConfig: tui.RenderConfig(terminalWidth: width),
    ).render();
  }

  @override
  String view() {
    if (width == 0 || height == 0) return 'Initializing...';

    // Only rebuild content if dirty
    if (_viewDirty) {
      _rebuildView();
      _viewDirty = false;
    }

    // Only apply debug overlay when enabled (it shows live metrics)
    if (debugOverlay.enabled) {
      return debugOverlay.compose(_cachedView);
    }
    return _cachedView;
  }
}

void main() async {
  final p = tui.Program(
    DashboardModel(),
    options: const tui.ProgramOptions(
      useUltravioletRenderer: true,
      altScreen: true,
      metricsInterval: Duration(
        milliseconds: 250,
      ), // Update metrics 4x per second
      mouseMode: tui.MouseMode.allMotion, // Enable mouse for dragging
    ),
  );

  await p.run();
}
