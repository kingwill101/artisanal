library;
import 'package:artisanal/bubbles.dart' as tui hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;
import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;

import 'dart:math' as math;

import 'package:artisanal/artisanal.dart' as chart;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' show Cell, Rectangle, Screen, UvStyle;

import 'data.dart';
import 'physics_scene.dart';
import 'theme.dart';
import 'widgets.dart';

const _tickRate = Duration(milliseconds: 140);
const _maxLogs = 220;
const _maxConsoleLines = 120;

final class NexusTickMsg extends tui.Msg {
  const NexusTickMsg();
}

enum FocusArea { nodes, logs, console }

enum Page { nexus, physics, charts }

final class ChartPaletteConfig {
  const ChartPaletteConfig({
    required this.name,
    required this.seriesHex,
    required this.heatmapHex,
  });

  final String name;
  final List<String> seriesHex;
  final List<String> heatmapHex;
}

const _chartPalettes = [
  ChartPaletteConfig(
    name: 'neon',
    seriesHex: ['#9b5de5', '#00bbf9', '#00f5d4', '#f15bb5'],
    heatmapHex: [
      '#0b1020',
      '#173b66',
      '#2d7dd2',
      '#5ed6b2',
      '#f4c95d',
      '#f25c54',
    ],
  ),
  ChartPaletteConfig(
    name: 'aurora',
    seriesHex: ['#06d6a0', '#118ab2', '#ef476f', '#ffd166'],
    heatmapHex: [
      '#061a40',
      '#0b2a5b',
      '#145da0',
      '#2ec4b6',
      '#ffd166',
      '#ef476f',
    ],
  ),
  ChartPaletteConfig(
    name: 'ember',
    seriesHex: ['#ff7a00', '#ffb703', '#fb5607', '#ff006e'],
    heatmapHex: [
      '#2b0d0d',
      '#5c1d14',
      '#903c1d',
      '#d65d32',
      '#f4a259',
      '#f7d488',
    ],
  ),
];

final class NexusKeys extends tui.KeyMap {
  NexusKeys()
    : next = tui.KeyBinding.withHelp(['tab'], 'tab', 'next focus'),
      prev = tui.KeyBinding.withHelp(['shift+tab'], 'shift+tab', 'prev focus'),
      pageNext = tui.KeyBinding.withHelp([']'], ']', 'next page'),
      pagePrev = tui.KeyBinding.withHelp(['['], '[', 'prev page'),
      toggleHelp = tui.KeyBinding.withHelp(['?'], '?', 'help'),
      togglePause = tui.KeyBinding.withHelp(['p'], 'p', 'pause'),
      toggleFollow = tui.KeyBinding.withHelp(['f'], 'f', 'follow logs'),
      theme = tui.KeyBinding.withHelp(['t'], 't', 'theme'),
      debug = tui.KeyBinding.withHelp(['d'], 'd', 'debug overlay'),
      clear = tui.KeyBinding.withHelp(['c'], 'c', 'clear logs'),
      reseed = tui.KeyBinding.withHelp(['r'], 'r', 'reseed'),
      physicsReset = tui.KeyBinding.withHelp(['r'], 'r', 'reset physics'),
      physicsSpawn = tui.KeyBinding.withHelp(['s'], 's', 'spawn body'),
      physicsBlast = tui.KeyBinding.withHelp(['x'], 'x', 'blast'),
      physicsGravity = tui.KeyBinding.withHelp(['g'], 'g', 'toggle gravity'),
      chartsPalette = tui.KeyBinding.withHelp(['m'], 'm', 'chart palette'),
      quit = tui.KeyBinding.withHelp(['esc', 'ctrl+c', 'q'], 'esc/q', 'quit'),
      enter = tui.KeyBinding.withHelp(['enter'], 'enter', 'run cmd') {
    shortHelp = [
      next,
      prev,
      pagePrev,
      pageNext,
      toggleHelp,
      togglePause,
      toggleFollow,
      theme,
      quit,
    ];
    fullHelp = [
      [next, prev, pagePrev, pageNext, toggleHelp, enter],
      [togglePause, toggleFollow, theme, reseed, clear, debug],
      [physicsSpawn, physicsGravity, physicsBlast, physicsReset, chartsPalette],
      [quit],
    ];
  }

  final tui.KeyBinding next;
  final tui.KeyBinding prev;
  final tui.KeyBinding pageNext;
  final tui.KeyBinding pagePrev;
  final tui.KeyBinding toggleHelp;
  final tui.KeyBinding togglePause;
  final tui.KeyBinding toggleFollow;
  final tui.KeyBinding theme;
  final tui.KeyBinding debug;
  final tui.KeyBinding clear;
  final tui.KeyBinding reseed;
  final tui.KeyBinding physicsReset;
  final tui.KeyBinding physicsSpawn;
  final tui.KeyBinding physicsBlast;
  final tui.KeyBinding physicsGravity;
  final tui.KeyBinding chartsPalette;
  final tui.KeyBinding quit;
  final tui.KeyBinding enter;
}

final class LayoutSpec {
  const LayoutSpec({
    required this.width,
    required this.height,
    required this.compact,
    required this.headerHeight,
    required this.footerHeight,
    required this.columnGap,
    required this.leftWidth,
    required this.rightWidth,
    required this.telemetryHeight,
    required this.nodesHeight,
    required this.pipelineHeight,
    required this.logsHeight,
    required this.topologyHeight,
    required this.consoleHeight,
  });

  final int width;
  final int height;
  final bool compact;
  final int headerHeight;
  final int footerHeight;
  final int columnGap;
  final int leftWidth;
  final int rightWidth;
  final int telemetryHeight;
  final int nodesHeight;
  final int pipelineHeight;
  final int logsHeight;
  final int topologyHeight;
  final int consoleHeight;

  int get leftInnerWidth => math.max(10, leftWidth - 4);
  int get rightInnerWidth => math.max(10, rightWidth - 4);

  static LayoutSpec compute(int width, int height, bool fullHelp) {
    final safeWidth = width <= 0 ? 120 : width;
    final safeHeight = height <= 0 ? 40 : height;
    final headerHeight = 2;
    final footerHeight = fullHelp ? 6 : 2;
    final bodyHeight = math.max(
      10,
      safeHeight - headerHeight - footerHeight - 2,
    );
    final compact = safeWidth < 110 || safeHeight < 30;

    if (compact) {
      final gap = 1;
      final totalGap = gap * 5;
      final usable = math.max(12, bodyHeight - totalGap);
      final parts = _distributeHeights(usable, [3, 4, 3, 4, 3, 3]);
      return LayoutSpec(
        width: safeWidth,
        height: safeHeight,
        compact: true,
        headerHeight: headerHeight,
        footerHeight: footerHeight,
        columnGap: gap,
        leftWidth: safeWidth,
        rightWidth: safeWidth,
        telemetryHeight: parts[0],
        nodesHeight: parts[1],
        pipelineHeight: parts[2],
        logsHeight: parts[3],
        topologyHeight: parts[4],
        consoleHeight: parts[5],
      );
    }

    final gap = 2;
    final leftWidth = (safeWidth * 0.56).floor();
    final rightWidth = math.max(30, safeWidth - leftWidth - gap);

    final leftGap = 2;
    final rightGap = 2;
    final leftUsable = math.max(12, bodyHeight - leftGap * 2);
    final rightUsable = math.max(12, bodyHeight - rightGap * 2);

    final leftParts = _distributeHeights(leftUsable, [4, 6, 4]);
    final rightParts = _distributeHeights(rightUsable, [7, 5, 4]);

    return LayoutSpec(
      width: safeWidth,
      height: safeHeight,
      compact: false,
      headerHeight: headerHeight,
      footerHeight: footerHeight,
      columnGap: gap,
      leftWidth: leftWidth,
      rightWidth: rightWidth,
      telemetryHeight: leftParts[0],
      nodesHeight: leftParts[1],
      pipelineHeight: leftParts[2],
      logsHeight: rightParts[0],
      topologyHeight: rightParts[1],
      consoleHeight: rightParts[2],
    );
  }
}

final class NexusModel implements tui.Model {
  const NexusModel({
    required this.page,
    required this.theme,
    required this.focus,
    required this.paused,
    required this.followLogs,
    required this.telemetry,
    required this.nodes,
    required this.pipeline,
    required this.logs,
    required this.consoleLines,
    required this.heatmap,
    required this.chartPaletteIndex,
    required this.physics,
    required this.nodeList,
    required this.nodeDelegate,
    required this.logViewport,
    required this.consoleInput,
    required this.pipelineProgress,
    required this.pipelineSpinner,
    required this.help,
    required this.keys,
    required this.debugOverlay,
    required this.topology,
    required this.topologyPhase,
    required this.terminalWidth,
    required this.terminalHeight,
    required this.frame,
  });

  factory NexusModel.initial() {
    final theme = DemoTheme.obsidian;
    final themeInfo = themeData(theme);

    final nodes = generateServices();
    final delegate = NodeDelegate(themeInfo);
    final list = tui.ListModel(
      items: nodes.map(NodeItem.new).toList(),
      delegate: delegate,
      width: 48,
      height: 14,
      showTitle: false,
      showFilter: false,
      showStatusBar: false,
      showPagination: false,
      showHelp: false,
      filteringEnabled: false,
    );
    list.disableQuitKeybindings();

    final input = tui.TextInputModel(
      prompt: 'λ ',
      placeholder: 'type help',
      showSuggestions: true,
      charLimit: 200,
    );
    input.suggestions = _commandSuggestions;
    input.blur();

    final progress = tui.ProgressModel(
      width: 28,
      useGradient: true,
      gradientColorA: themeInfo.chartA.toHex(),
      gradientColorB: themeInfo.chartD.toHex(),
      showPercentage: true,
    );

    return NexusModel(
      page: Page.nexus,
      theme: theme,
      focus: FocusArea.nodes,
      paused: false,
      followLogs: true,
      telemetry: TelemetryState.initial(),
      nodes: nodes,
      pipeline: PipelineState.initial(),
      logs: const [],
      consoleLines: const [
        'system ready — type help to explore commands',
        'focus console and run: theme aurora',
      ],
      heatmap: HeatmapState.seed(36, 14),
      chartPaletteIndex: 0,
      physics: PhysicsScene.initial(),
      nodeList: list,
      nodeDelegate: delegate,
      logViewport: tui.ViewportModel(width: 64, height: 10, softWrap: true),
      consoleInput: input,
      pipelineProgress: progress,
      pipelineSpinner: tui.SpinnerModel(spinner: tui.Spinners.moon),
      help: tui.HelpModel(),
      keys: NexusKeys(),
      debugOverlay: tui.DebugOverlayModel.initial(
        title: 'UV Render Metrics',
        rendererLabel: 'UV',
        panelWidth: 42,
      ),
      topology: generateTopology(nodes: nodes.length),
      topologyPhase: 0,
      terminalWidth: 120,
      terminalHeight: 40,
      frame: 0,
    );
  }

  final DemoTheme theme;
  final Page page;
  final FocusArea focus;
  final bool paused;
  final bool followLogs;
  final TelemetryState telemetry;
  final List<ServiceNode> nodes;
  final PipelineState pipeline;
  final List<LogEntry> logs;
  final List<String> consoleLines;
  final HeatmapState heatmap;
  final int chartPaletteIndex;
  final PhysicsScene physics;
  final tui.ListModel nodeList;
  final NodeDelegate nodeDelegate;
  final tui.ViewportModel logViewport;
  final tui.TextInputModel consoleInput;
  final tui.ProgressModel pipelineProgress;
  final tui.SpinnerModel pipelineSpinner;
  final tui.HelpModel help;
  final NexusKeys keys;
  final tui.DebugOverlayModel debugOverlay;
  final TopologyLayout topology;
  final double topologyPhase;
  final int terminalWidth;
  final int terminalHeight;
  final int frame;

  DemoThemeData get themeInfo => themeData(theme);

  NexusModel copyWith({
    Page? page,
    DemoTheme? theme,
    FocusArea? focus,
    bool? paused,
    bool? followLogs,
    TelemetryState? telemetry,
    List<ServiceNode>? nodes,
    PipelineState? pipeline,
    List<LogEntry>? logs,
    List<String>? consoleLines,
    HeatmapState? heatmap,
    int? chartPaletteIndex,
    PhysicsScene? physics,
    tui.ListModel? nodeList,
    NodeDelegate? nodeDelegate,
    tui.ViewportModel? logViewport,
    tui.TextInputModel? consoleInput,
    tui.ProgressModel? pipelineProgress,
    tui.SpinnerModel? pipelineSpinner,
    tui.HelpModel? help,
    NexusKeys? keys,
    tui.DebugOverlayModel? debugOverlay,
    TopologyLayout? topology,
    double? topologyPhase,
    int? terminalWidth,
    int? terminalHeight,
    int? frame,
  }) {
    return NexusModel(
      page: page ?? this.page,
      theme: theme ?? this.theme,
      focus: focus ?? this.focus,
      paused: paused ?? this.paused,
      followLogs: followLogs ?? this.followLogs,
      telemetry: telemetry ?? this.telemetry,
      nodes: nodes ?? this.nodes,
      pipeline: pipeline ?? this.pipeline,
      logs: logs ?? this.logs,
      consoleLines: consoleLines ?? this.consoleLines,
      heatmap: heatmap ?? this.heatmap,
      chartPaletteIndex: chartPaletteIndex ?? this.chartPaletteIndex,
      physics: physics ?? this.physics,
      nodeList: nodeList ?? this.nodeList,
      nodeDelegate: nodeDelegate ?? this.nodeDelegate,
      logViewport: logViewport ?? this.logViewport,
      consoleInput: consoleInput ?? this.consoleInput,
      pipelineProgress: pipelineProgress ?? this.pipelineProgress,
      pipelineSpinner: pipelineSpinner ?? this.pipelineSpinner,
      help: help ?? this.help,
      keys: keys ?? this.keys,
      debugOverlay: debugOverlay ?? this.debugOverlay,
      topology: topology ?? this.topology,
      topologyPhase: topologyPhase ?? this.topologyPhase,
      terminalWidth: terminalWidth ?? this.terminalWidth,
      terminalHeight: terminalHeight ?? this.terminalHeight,
      frame: frame ?? this.frame,
    );
  }

  @override
  tui.Cmd? init() {
    return tui.Cmd.batch([
      tui.Cmd.tick(_tickRate, (_) => const NexusTickMsg()),
      pipelineSpinner.tick(),
    ]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final debugUpdate = debugOverlay.update(msg);
    var nextDebug = debugUpdate.model;
    final cmds = <tui.Cmd>[if (debugUpdate.cmd != null) debugUpdate.cmd!];

    if (debugUpdate.consumed) {
      return (copyWith(debugOverlay: nextDebug), _batch(cmds));
    }

    switch (msg) {
      case tui.RenderMetricsMsg():
        return (copyWith(debugOverlay: nextDebug), _batch(cmds));

      case tui.WindowSizeMsg(:final width, :final height):
        return (_handleResize(width, height, nextDebug), _batch(cmds));

      case tui.SpinnerTickMsg():
        final (updatedSpinner, cmd) = pipelineSpinner.update(msg);
        if (cmd != null) cmds.add(cmd);
        return (
          copyWith(pipelineSpinner: updatedSpinner, debugOverlay: nextDebug),
          _batch(cmds),
        );

      case tui.ProgressFrameMsg():
        final (updatedProgress, cmd) = pipelineProgress.update(msg);
        if (cmd != null) cmds.add(cmd);
        return (
          copyWith(pipelineProgress: updatedProgress, debugOverlay: nextDebug),
          _batch(cmds),
        );

      case NexusTickMsg():
        return _handleTick(cmds, nextDebug);

      case tui.KeyMsg(:final key):
        return _handleKey(key, cmds, nextDebug);

      default:
        return (copyWith(debugOverlay: nextDebug), _batch(cmds));
    }
  }

  (tui.Model, tui.Cmd?) _handleTick(
    List<tui.Cmd> cmds,
    tui.DebugOverlayModel nextDebug,
  ) {
    var nextTelemetry = telemetry;
    var nextNodes = nodes;
    var nextPipeline = pipeline;
    var nextLogs = logs;
    var nextTopologyPhase = topologyPhase + 0.2;
    var nextPhysics = physics;
    var nextHeatmap = heatmap;

    if (!paused) {
      if (page == Page.nexus) {
        nextTelemetry = telemetry.evolve();
        nextNodes = nodes.map((n) => n.evolve()).toList();
        nextPipeline = pipeline.advance();

        if (math.Random().nextDouble() < 0.65) {
          nextLogs = [...nextLogs, randomLog(nextNodes)];
          if (nextLogs.length > _maxLogs) {
            nextLogs = nextLogs.sublist(nextLogs.length - _maxLogs);
          }
        }
      } else if (page == Page.physics) {
        nextPhysics = physics.step(_tickRate.inMilliseconds / 1000);
      }
      nextHeatmap = heatmap.evolve();
    }

    var nextList = nodeList;
    nextList.items = nextNodes.map(NodeItem.new).toList();

    final nextViewport = _refreshViewport(
      logViewport,
      nextLogs,
      themeInfo,
      followLogs,
    );

    final (progress, progressCmd) = pipelineProgress.setPercent(
      nextPipeline.progress,
    );
    if (progressCmd != null) cmds.add(progressCmd);

    cmds.add(tui.Cmd.tick(_tickRate, (_) => const NexusTickMsg()));

    return (
      copyWith(
        telemetry: nextTelemetry,
        nodes: nextNodes,
        pipeline: nextPipeline,
        logs: nextLogs,
        heatmap: nextHeatmap,
        physics: nextPhysics,
        nodeList: nextList,
        logViewport: nextViewport,
        pipelineProgress: progress,
        topologyPhase: nextTopologyPhase,
        frame: frame + 1,
        debugOverlay: nextDebug,
      ),
      _batch(cmds),
    );
  }

  (tui.Model, tui.Cmd?) _handleKey(
    tui.Key key,
    List<tui.Cmd> cmds,
    tui.DebugOverlayModel nextDebug,
  ) {
    final isConsole = focus == FocusArea.console;

    if (key.matchesSingle(keys.quit) ||
        key.type == tui.KeyType.escape ||
        (key.type == tui.KeyType.runes &&
            key.ctrl &&
            key.runes.length == 1 &&
            key.runes.first == 0x63)) {
      return (copyWith(debugOverlay: nextDebug), tui.Cmd.quit());
    }

    if (key.matchesSingle(keys.pageNext)) {
      return (_switchPage(1, nextDebug), _batch(cmds));
    }

    if (key.matchesSingle(keys.pagePrev)) {
      return (_switchPage(-1, nextDebug), _batch(cmds));
    }

    if (key.type == tui.KeyType.runes && key.runes.length == 1) {
      final char = String.fromCharCode(key.runes.first);
      if (char == '1') {
        return (
          copyWith(page: Page.nexus, debugOverlay: nextDebug),
          _batch(cmds),
        );
      }
      if (char == '2') {
        return (
          copyWith(page: Page.physics, debugOverlay: nextDebug),
          _batch(cmds),
        );
      }
      if (char == '3') {
        return (
          copyWith(page: Page.charts, debugOverlay: nextDebug),
          _batch(cmds),
        );
      }
    }

    if (page == Page.physics) {
      final handled = _handlePhysicsKey(key, nextDebug);
      if (handled != null) {
        return (handled, _batch(cmds));
      }
    }

    if (page == Page.charts) {
      final handled = _handleChartsKey(key, nextDebug);
      if (handled != null) {
        return (handled, _batch(cmds));
      }
    }

    if (key.matchesSingle(keys.next)) {
      final nextFocus = _cycleFocus(1);
      final focusCmd = _applyFocus(nextFocus);
      if (focusCmd != null) cmds.add(focusCmd);
      return (
        copyWith(focus: nextFocus, debugOverlay: nextDebug),
        _batch(cmds),
      );
    }

    if (key.matchesSingle(keys.prev)) {
      final nextFocus = _cycleFocus(-1);
      final focusCmd = _applyFocus(nextFocus);
      if (focusCmd != null) cmds.add(focusCmd);
      return (
        copyWith(focus: nextFocus, debugOverlay: nextDebug),
        _batch(cmds),
      );
    }

    if (isConsole) {
      if (key.matchesSingle(keys.enter)) {
        final input = consoleInput.value.trim();
        if (input.isEmpty) {
          return (copyWith(debugOverlay: nextDebug), _batch(cmds));
        }

        final (nextModel, outputLines, cmd) = _executeCommand(input, nextDebug);
        final appended = _appendConsoleLines(
          input,
          outputLines,
          nextModel.consoleLines,
          themeData(nextModel.theme),
        );
        nextModel.consoleInput.reset();
        if (cmd != null) cmds.add(cmd);

        return (nextModel.copyWith(consoleLines: appended), _batch(cmds));
      }

      final (updatedInput, cmd) = consoleInput.update(tui.KeyMsg(key));
      if (cmd != null) cmds.add(cmd);
      return (
        copyWith(consoleInput: updatedInput, debugOverlay: nextDebug),
        _batch(cmds),
      );
    }

    if (key.matchesSingle(keys.toggleHelp)) {
      return (
        copyWith(
          help: help.copyWith(showAll: !help.showAll),
          debugOverlay: nextDebug,
        ),
        _batch(cmds),
      );
    }

    if (key.matchesSingle(keys.togglePause)) {
      final next = !paused;
      return (copyWith(paused: next, debugOverlay: nextDebug), _batch(cmds));
    }

    if (key.matchesSingle(keys.toggleFollow)) {
      final next = !followLogs;
      return (
        copyWith(followLogs: next, debugOverlay: nextDebug),
        _batch(cmds),
      );
    }

    if (key.matchesSingle(keys.theme)) {
      final nextThemeId = nextTheme(theme);
      return (_applyTheme(nextThemeId, nextDebug), _batch(cmds));
    }

    if (key.matchesSingle(keys.debug)) {
      return (copyWith(debugOverlay: nextDebug.toggle()), _batch(cmds));
    }

    if (key.matchesSingle(keys.clear)) {
      final cleared = _refreshViewport(logViewport, const [], themeInfo, true);
      return (
        copyWith(logs: const [], logViewport: cleared, debugOverlay: nextDebug),
        _batch(cmds),
      );
    }

    if (key.matchesSingle(keys.reseed)) {
      if (page != Page.nexus) {
        return (copyWith(debugOverlay: nextDebug), _batch(cmds));
      }
      final nextNodes = generateServices();
      final list = nodeList..items = nextNodes.map(NodeItem.new).toList();
      return (
        copyWith(
          nodes: nextNodes,
          nodeList: list,
          topology: generateTopology(nodes: nextNodes.length),
          debugOverlay: nextDebug,
        ),
        _batch(cmds),
      );
    }

    if (focus == FocusArea.nodes) {
      final (updatedList, cmd) = nodeList.update(tui.KeyMsg(key));
      if (cmd != null) cmds.add(cmd);
      return (
        copyWith(nodeList: updatedList, debugOverlay: nextDebug),
        _batch(cmds),
      );
    }

    if (focus == FocusArea.logs) {
      final (updatedViewport, cmd) = logViewport.update(tui.KeyMsg(key));
      if (cmd != null) cmds.add(cmd);
      return (
        copyWith(logViewport: updatedViewport, debugOverlay: nextDebug),
        _batch(cmds),
      );
    }

    return (copyWith(debugOverlay: nextDebug), _batch(cmds));
  }

  NexusModel _switchPage(int delta, tui.DebugOverlayModel nextDebug) {
    final pages = Page.values;
    final idx = pages.indexOf(page);
    final nextIdx = (idx + delta) % pages.length;
    return copyWith(
      page: pages[nextIdx < 0 ? pages.length - 1 : nextIdx],
      debugOverlay: nextDebug,
    );
  }

  NexusModel? _handlePhysicsKey(tui.Key key, tui.DebugOverlayModel nextDebug) {
    if (key.matchesSingle(keys.physicsGravity)) {
      return copyWith(
        physics: physics.toggleGravity(),
        debugOverlay: nextDebug,
      );
    }
    if (key.matchesSingle(keys.physicsSpawn)) {
      return copyWith(physics: physics.spawnBurst(3), debugOverlay: nextDebug);
    }
    if (key.matchesSingle(keys.physicsBlast)) {
      return copyWith(physics: physics.blast(), debugOverlay: nextDebug);
    }
    if (key.matchesSingle(keys.physicsReset)) {
      return copyWith(physics: physics.reset(), debugOverlay: nextDebug);
    }
    return null;
  }

  NexusModel? _handleChartsKey(tui.Key key, tui.DebugOverlayModel nextDebug) {
    if (key.matchesSingle(keys.chartsPalette)) {
      final nextIndex = (chartPaletteIndex + 1) % _chartPalettes.length;
      return copyWith(chartPaletteIndex: nextIndex, debugOverlay: nextDebug);
    }
    return null;
  }

  tui.Cmd? _applyFocus(FocusArea nextFocus) {
    if (nextFocus == FocusArea.console) {
      return consoleInput.focus();
    }
    consoleInput.blur();
    return null;
  }

  FocusArea _cycleFocus(int delta) {
    final values = FocusArea.values;
    final idx = values.indexOf(focus);
    final nextIdx = (idx + delta) % values.length;
    return values[nextIdx < 0 ? values.length - 1 : nextIdx];
  }

  NexusModel _handleResize(
    int width,
    int height,
    tui.DebugOverlayModel nextDebug,
  ) {
    final spec = LayoutSpec.compute(width, height, help.showAll);
    final list = nodeList
      ..setSize(spec.leftInnerWidth, math.max(6, spec.nodesHeight - 2));
    final viewport = logViewport.copyWith(
      width: spec.rightInnerWidth,
      height: math.max(4, spec.logsHeight - 3),
      softWrap: true,
    );
    final input = consoleInput..width = spec.rightInnerWidth;
    final progress = pipelineProgress.copyWith(
      width: math.max(18, spec.leftInnerWidth - 6),
    );

    return copyWith(
      terminalWidth: width,
      terminalHeight: height,
      nodeList: list,
      logViewport: _refreshViewport(viewport, logs, themeInfo, followLogs),
      consoleInput: input,
      pipelineProgress: progress,
      help: help.copyWith(width: width),
      debugOverlay: nextDebug,
    );
  }

  NexusModel _applyTheme(DemoTheme nextTheme, tui.DebugOverlayModel nextDebug) {
    final data = themeData(nextTheme);
    nodeDelegate.updateTheme(data);

    final listStyles = tui.ListStyles(
      title: Style().foreground(data.palette.textBold),
      statusBar: Style().foreground(data.palette.textDim),
      filterPrompt: Style().foreground(data.palette.accent),
      paginationStyle: Style().foreground(data.palette.textDim),
      helpStyle: Style().foreground(data.palette.textDim),
      dividerDot: Style().foreground(data.palette.textDim),
    );

    final inputStyles = tui.TextInputStyles(
      focused: tui.TextInputStyleState(
        text: Style().foreground(data.palette.textBold),
        placeholder: Style().foreground(data.palette.textDim),
        suggestion: Style().foreground(data.palette.info),
        prompt: Style().foreground(data.palette.accentBold),
      ),
      blurred: tui.TextInputStyleState(
        text: Style().foreground(data.palette.textDim),
        placeholder: Style().foreground(data.palette.textDim),
        suggestion: Style().foreground(data.palette.textDim),
        prompt: Style().foreground(data.palette.textDim),
      ),
      cursor: tui.TextInputCursorStyle(color: data.palette.accentBold),
    );

    final updatedProgress = pipelineProgress.copyWith(
      gradientColorA: data.chartA.toHex(),
      gradientColorB: data.chartD.toHex(),
      fullColor: data.chartA.toHex(),
    );

    nodeList.styles = listStyles;
    consoleInput.styles = inputStyles;

    return copyWith(
      theme: nextTheme,
      pipelineProgress: updatedProgress,
      debugOverlay: nextDebug,
    );
  }

  (NexusModel, List<String>, tui.Cmd?) _executeCommand(
    String input,
    tui.DebugOverlayModel nextDebug,
  ) {
    final parts = input.split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return (copyWith(debugOverlay: nextDebug), ['noop'], null);
    }

    final command = parts.first.toLowerCase();
    final args = parts.skip(1).toList();

    switch (command) {
      case 'help':
        return (copyWith(debugOverlay: nextDebug), _commandHelp(), null);

      case 'pause':
        return (
          copyWith(paused: true, debugOverlay: nextDebug),
          ['paused telemetry + log flow'],
          null,
        );

      case 'resume':
        return (
          copyWith(paused: false, debugOverlay: nextDebug),
          ['resumed telemetry + log flow'],
          null,
        );

      case 'theme':
        if (args.isEmpty) {
          return (
            copyWith(debugOverlay: nextDebug),
            [
              'themes: ${demoThemes.map((t) => t.name.toLowerCase()).join(', ')}',
            ],
            null,
          );
        }
        final target = args.first.toLowerCase();
        final match = demoThemes.firstWhere(
          (t) => t.name.toLowerCase() == target,
          orElse: () => themeInfo,
        );
        return (
          _applyTheme(match.id, nextDebug),
          ['theme set → ${match.name}'],
          null,
        );

      case 'focus':
        if (args.isEmpty) {
          return (
            copyWith(debugOverlay: nextDebug),
            ['focus nodes | logs | console'],
            null,
          );
        }
        final area = args.first.toLowerCase();
        final target = switch (area) {
          'nodes' => FocusArea.nodes,
          'logs' => FocusArea.logs,
          'console' => FocusArea.console,
          _ => focus,
        };
        final focusCmd = _applyFocus(target);
        if (focusCmd != null) {
          return (
            copyWith(focus: target, debugOverlay: nextDebug),
            ['focus set → ${target.name}'],
            focusCmd,
          );
        }
        return (
          copyWith(focus: target, debugOverlay: nextDebug),
          ['focus set → ${target.name}'],
          null,
        );

      case 'clear':
        final cleared = _refreshViewport(
          logViewport,
          const [],
          themeInfo,
          true,
        );
        return (
          copyWith(
            logs: const [],
            logViewport: cleared,
            debugOverlay: nextDebug,
          ),
          ['log buffer cleared'],
          null,
        );

      case 'reseed':
        final nextNodes = generateServices();
        final list = nodeList..items = nextNodes.map(NodeItem.new).toList();
        return (
          copyWith(
            nodes: nextNodes,
            nodeList: list,
            topology: generateTopology(nodes: nextNodes.length),
            debugOverlay: nextDebug,
          ),
          ['service mesh reseeded'],
          null,
        );

      case 'inject':
        if (args.length < 2) {
          return (
            copyWith(debugOverlay: nextDebug),
            ['usage: inject <info|warn|error|success|trace> <message>'],
            null,
          );
        }
        final level = _parseLevel(args.first);
        final message = args.skip(1).join(' ');
        final entry = LogEntry(
          time: DateTime.now(),
          level: level,
          source: 'operator',
          message: message,
        );
        final nextLogs = [...logs, entry];
        return (
          copyWith(
            logs: nextLogs,
            logViewport: _refreshViewport(
              logViewport,
              nextLogs,
              themeInfo,
              followLogs,
            ),
            debugOverlay: nextDebug,
          ),
          ['injected ${level.name} log'],
          null,
        );

      default:
        return (
          copyWith(debugOverlay: nextDebug),
          ['unknown command: $command'],
          null,
        );
    }
  }

  List<String> _appendConsoleLines(
    String input,
    List<String> lines,
    List<String> base,
    DemoThemeData theme,
  ) {
    final next = <String>[
      ...base,
      Style().foreground(theme.palette.accentBold).render('λ $input'),
      ...lines.map(
        (line) => Style().foreground(theme.palette.text).render('› $line'),
      ),
    ];
    if (next.length > _maxConsoleLines) {
      return next.sublist(next.length - _maxConsoleLines);
    }
    return next;
  }

  List<String> _commandHelp() {
    return [
      'help                 show commands',
      'pause | resume       toggle live telemetry',
      'theme <name>         set palette',
      'focus <panel>        nodes | logs | console',
      'clear                clear logs',
      'reseed               reseed node mesh',
      'inject <lvl> <msg>   push custom log line',
    ];
  }

  LogLevel _parseLevel(String raw) {
    return switch (raw.toLowerCase()) {
      'warn' || 'warning' => LogLevel.warning,
      'err' || 'error' => LogLevel.error,
      'success' => LogLevel.success,
      'trace' => LogLevel.trace,
      _ => LogLevel.info,
    };
  }

  tui.ViewportModel _refreshViewport(
    tui.ViewportModel viewport,
    List<LogEntry> entries,
    DemoThemeData theme,
    bool follow,
  ) {
    final lines = entries.map((e) => _formatLogLine(e, theme)).toList();
    var next = viewport.setContent(lines.join('\n'));
    if (follow) {
      next = next.gotoBottom();
    }
    return next;
  }

  String _formatLogLine(LogEntry entry, DemoThemeData theme) {
    final stamp = entry.time.toIso8601String().substring(11, 19);
    final level = switch (entry.level) {
      LogLevel.trace => Style().foreground(theme.palette.textDim).render('TRC'),
      LogLevel.info => Style().foreground(theme.palette.info).render('INF'),
      LogLevel.success =>
        Style().foreground(theme.palette.success).render('OK '),
      LogLevel.warning =>
        Style().foreground(theme.palette.warning).render('WRN'),
      LogLevel.error => Style().foreground(theme.palette.error).render('ERR'),
    };
    final source = Style()
        .foreground(theme.palette.accent)
        .render(entry.source);
    return '$stamp $level $source ${entry.message}';
  }

  @override
  String view() {
    final theme = themeInfo;
    final spec = LayoutSpec.compute(
      terminalWidth,
      terminalHeight,
      help.showAll,
    );

    final header = _renderHeader(theme, spec.width);
    final body = switch (page) {
      Page.physics => _renderPhysicsPage(theme, spec),
      Page.charts => _renderChartsPage(theme, spec),
      _ =>
        spec.compact
            ? _renderCompactBody(theme, spec)
            : _renderWideBody(theme, spec),
    };
    final helpView = _padBlock(help.view(keys), spec.width);

    final combined = Layout.joinVertical(HorizontalAlign.left, [
      header,
      body,
      helpView,
    ], gap: 1);

    return debugOverlay.compose(combined);
  }

  String _renderHeader(DemoThemeData theme, int width) {
    final accent = Style().foreground(theme.palette.accentBold).bold();
    final dim = Style().foreground(theme.palette.textDim);

    final status = paused
        ? Style().foreground(theme.palette.warning).render('PAUSED')
        : Style().foreground(theme.palette.success).render('LIVE');

    final focusLabel = Style()
        .foreground(theme.palette.info)
        .render(focus.name);
    final themeLabel = Style()
        .foreground(theme.palette.highlight)
        .render(theme.name);
    final pageLabel = Style()
        .foreground(theme.palette.accent)
        .render(page.name);

    final line1 = Layout.pad(
      '${accent.render('ARTISANAL NEXUS')}  ${dim.render('UV + TUI')}  $status  page:$pageLabel  focus:$focusLabel  theme:$themeLabel',
      width,
    );
    final statusLine = switch (page) {
      Page.physics =>
        'bodies ${physics.bodies.length} ${DotChars.middle} gravity ${physics.gravityEnabled ? 'on' : 'off'} ${DotChars.middle} world ${physics.worldWidth.toStringAsFixed(0)}x${physics.worldHeight.toStringAsFixed(0)}',
      Page.charts =>
        'charts palette ${_chartPalettes[chartPaletteIndex].name} ${DotChars.middle} heatmap ${heatmap.width}x${heatmap.height} ${DotChars.middle} series ${telemetry.cpuSeries.values.length}',
      _ =>
        'telemetry ${telemetry.cpu.toStringAsFixed(1)}% cpu ${DotChars.middle} ${telemetry.netIn.toStringAsFixed(0)} mb/s in ${DotChars.middle} ${telemetry.netOut.toStringAsFixed(0)} mb/s out',
    };
    final line2 = Layout.pad(dim.render(statusLine), width);

    return '$line1\n$line2';
  }

  String _renderWideBody(DemoThemeData theme, LayoutSpec spec) {
    final leftPanels = Layout.joinVertical(HorizontalAlign.left, [
      _buildTelemetryPanel(theme, spec.leftWidth, spec.telemetryHeight),
      _buildNodesPanel(theme, spec.leftWidth, spec.nodesHeight),
      _buildPipelinePanel(theme, spec.leftWidth, spec.pipelineHeight),
    ], gap: 1);

    final rightPanels = Layout.joinVertical(HorizontalAlign.left, [
      _buildLogsPanel(theme, spec.rightWidth, spec.logsHeight),
      _buildTopologyPanel(theme, spec.rightWidth, spec.topologyHeight),
      _buildConsolePanel(theme, spec.rightWidth, spec.consoleHeight),
    ], gap: 1);

    return Layout.joinHorizontal(VerticalAlign.top, [
      leftPanels,
      rightPanels,
    ], gap: spec.columnGap);
  }

  String _renderCompactBody(DemoThemeData theme, LayoutSpec spec) {
    return Layout.joinVertical(HorizontalAlign.left, [
      _buildTelemetryPanel(theme, spec.leftWidth, spec.telemetryHeight),
      _buildNodesPanel(theme, spec.leftWidth, spec.nodesHeight),
      _buildLogsPanel(theme, spec.leftWidth, spec.logsHeight),
      _buildTopologyPanel(theme, spec.leftWidth, spec.topologyHeight),
      _buildPipelinePanel(theme, spec.leftWidth, spec.pipelineHeight),
      _buildConsolePanel(theme, spec.leftWidth, spec.consoleHeight),
    ], gap: 1);
  }

  String _renderPhysicsPage(DemoThemeData theme, LayoutSpec spec) {
    final bodyHeight = math.max(
      6,
      spec.height - spec.headerHeight - spec.footerHeight - 2,
    );

    if (spec.width >= 110) {
      final gap = 2;
      final leftWidth = (spec.width * 0.72).floor();
      final rightWidth = math.max(26, spec.width - leftWidth - gap);
      final main = _buildPhysicsPanel(theme, leftWidth, bodyHeight);
      final stats = _buildPhysicsStatsPanel(theme, rightWidth, bodyHeight);
      return Layout.joinHorizontal(VerticalAlign.top, [main, stats], gap: gap);
    }

    return _buildPhysicsPanel(theme, spec.width, bodyHeight);
  }

  String _renderChartsPage(DemoThemeData theme, LayoutSpec spec) {
    final bodyHeight = math.max(
      10,
      spec.height - spec.headerHeight - spec.footerHeight - 2,
    );

    if (spec.width < 90 || bodyHeight < 24) {
      final gap = 1;
      final usable = math.max(6, bodyHeight - gap * 6);
      final parts = _distributeHeights(usable, [4, 4, 4, 3, 3, 3, 2]);
      return Layout.joinVertical(HorizontalAlign.left, [
        _buildChartsRibbonPanel(theme, spec.width, parts[0]),
        _buildChartsHeatmapPanel(theme, spec.width, parts[1]),
        _buildChartsLinePanel(theme, spec.width, parts[2]),
        _buildChartsPiePanel(theme, spec.width, parts[3]),
        _buildChartsHistogramPanel(theme, spec.width, parts[4]),
        _buildChartsSparklinePanel(theme, spec.width, parts[5]),
        _buildChartsHelpPanel(theme, spec.width, parts[6]),
      ], gap: gap);
    }

    final gap = 2;
    final colWidth = (spec.width - gap) ~/ 2;
    final rowHeights = _distributeHeights(bodyHeight - gap * 2, [4, 4, 3]);

    final row1 = Layout.joinHorizontal(VerticalAlign.top, [
      _buildChartsRibbonPanel(theme, colWidth, rowHeights[0]),
      _buildChartsHeatmapPanel(theme, colWidth, rowHeights[0]),
    ], gap: gap);

    final row2 = Layout.joinHorizontal(VerticalAlign.top, [
      _buildChartsLinePanel(theme, colWidth, rowHeights[1]),
      _buildChartsPiePanel(theme, colWidth, rowHeights[1]),
    ], gap: gap);

    final rightStack = rowHeights[2] < 8
        ? _buildChartsSparklinePanel(theme, colWidth, rowHeights[2])
        : () {
            final available = rowHeights[2] - 1;
            var sparkHeight = math.max(4, (available * 2 / 3).round());
            var helpHeight = available - sparkHeight;
            if (helpHeight < 4) {
              helpHeight = 4;
              sparkHeight = math.max(4, available - helpHeight);
            }
            return Layout.joinVertical(HorizontalAlign.left, [
              _buildChartsSparklinePanel(theme, colWidth, sparkHeight),
              _buildChartsHelpPanel(theme, colWidth, helpHeight),
            ], gap: 1);
          }();

    final row3 = Layout.joinHorizontal(VerticalAlign.top, [
      _buildChartsHistogramPanel(theme, colWidth, rowHeights[2]),
      rightStack,
    ], gap: gap);

    return Layout.joinVertical(HorizontalAlign.left, [
      row1,
      row2,
      row3,
    ], gap: gap);
  }

  String _buildChartsRibbonPanel(DemoThemeData theme, int width, int height) {
    final innerWidth = math.max(12, width - 4);
    final innerHeight = math.max(4, height - 2);
    final palette = _chartPalettes[chartPaletteIndex % _chartPalettes.length];
    final seriesStyles = palette.seriesHex
        .map(chart.uvStyleFromHex)
        .toList(growable: false);
    final legendEntries = [
      chart.ChartLegendEntry(
        label: 'cpu',
        style: seriesStyles[0],
        labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
      ),
      chart.ChartLegendEntry(
        label: 'mem',
        style: seriesStyles[1],
        labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
      ),
      chart.ChartLegendEntry(
        label: 'net',
        style: seriesStyles[2],
        labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
      ),
      chart.ChartLegendEntry(
        label: 'tmp',
        style: seriesStyles[3],
        labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
      ),
    ];

    final lines = _renderChartLines(innerWidth, innerHeight, (screen, area) {
      chart.drawRibbonChart(
        screen,
        area,
        [
          telemetry.cpuSeries.values,
          telemetry.memorySeries.values,
          telemetry.netSeries.values,
          telemetry.tempSeries.values,
        ],
        styles: seriesStyles,
        normalizeTotals: true,
        showGrid: true,
        gridRows: 2,
        gridStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
      );
      final legendWidth = math.max(6, math.min(26, area.width - 1));
      final legendArea = Rectangle(
        minX: area.minX + 1,
        minY: area.minY + 1,
        maxX: area.minX + 1 + legendWidth,
        maxY: area.minY + 3,
      );
      _clearChartArea(screen, legendArea);
      chart.drawLegend(screen, legendArea, legendEntries, columns: 2);
    });

    return panelBox(
      title: 'Signal Ribbons',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildChartsHeatmapPanel(DemoThemeData theme, int width, int height) {
    final innerWidth = math.max(12, width - 4);
    final innerHeight = math.max(4, height - 2);
    final palette = _chartPalettes[chartPaletteIndex % _chartPalettes.length];
    final ramp = chart.ChartRamp.fromHexes(palette.heatmapHex);

    final lines = _renderChartLines(innerWidth, innerHeight, (screen, area) {
      chart.drawHeatmap(
        screen,
        area,
        heatmap.grid,
        ramp: ramp,
        useBackground: true,
        glyph: ' ',
        showGrid: true,
        gridRows: 4,
        gridCols: 4,
        gridStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
        xLabels: const ['0', 't+5', 't+10', 't+15'],
        yLabels: const ['hi', 'mid', 'low'],
        labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
      );
    });

    return panelBox(
      title: 'Density Heatmap',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildChartsHistogramPanel(
    DemoThemeData theme,
    int width,
    int height,
  ) {
    final innerWidth = math.max(12, width - 4);
    final innerHeight = math.max(4, height - 2);
    final palette = _chartPalettes[chartPaletteIndex % _chartPalettes.length];
    final barStyle = chart.uvStyleFromHex(palette.seriesHex.first);
    final axisStyle = chart.uvStyleFromHex(theme.palette.textDim.toHex());
    final gridStyle = chart.uvStyleFromHex(theme.palette.textDim.toHex());

    final values = nodes.map((node) => node.latency).toList(growable: false);
    final lines = _renderChartLines(innerWidth, innerHeight, (screen, area) {
      chart.drawHistogram(
        screen,
        area,
        values,
        barStyle: barStyle,
        axisStyle: axisStyle,
        showAxis: true,
        showGrid: true,
        gridRows: 3,
        gridCols: 2,
        gridStyle: gridStyle,
        xLabels: const ['0', 'mid', 'max'],
        yLabels: const ['300ms', '150ms', '0'],
        labelStyle: axisStyle,
      );
    });

    return panelBox(
      title: 'Latency Histogram',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildChartsSparklinePanel(
    DemoThemeData theme,
    int width,
    int height,
  ) {
    final innerWidth = math.max(12, width - 4);
    final innerHeight = math.max(4, height - 2);
    final palette = _chartPalettes[chartPaletteIndex % _chartPalettes.length];
    final labelStyle = Style().foreground(theme.palette.textDim);
    final labelWidth = 5;
    final chartWidth = math.max(8, innerWidth - labelWidth - 1);

    final entries = [
      ('CPU', telemetry.cpuSeries.values, palette.seriesHex[0]),
      ('MEM', telemetry.memorySeries.values, palette.seriesHex[1]),
      ('NET', telemetry.netSeries.values, palette.seriesHex[2]),
      ('TMP', telemetry.tempSeries.values, palette.seriesHex[3]),
    ];

    final lines = <String>[];
    for (final (label, series, hex) in entries) {
      final sparkLine = chart.renderChartLines(
        chartWidth,
        1,
        (screen, area) => chart.drawSparkline(
          screen,
          area,
          series,
          style: chart.uvStyleFromHex(hex),
          showGrid: true,
          gridStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
        ),
      );
      final line =
          '${labelStyle.render(label.padRight(labelWidth))} ${sparkLine.isEmpty ? '' : sparkLine.first}';
      lines.add(line);
    }

    final fitted = fitChartLines(lines, innerWidth, innerHeight);

    return panelBox(
      title: 'Signal Sparklines',
      lines: fitted,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildChartsLinePanel(DemoThemeData theme, int width, int height) {
    final innerWidth = math.max(12, width - 4);
    final innerHeight = math.max(4, height - 2);
    final palette = _chartPalettes[chartPaletteIndex % _chartPalettes.length];
    final lineStyle = chart.uvStyleFromHex(palette.seriesHex[0]);
    final gridStyle = chart.uvStyleFromHex(theme.palette.textDim.toHex());

    final lines = _renderChartLines(innerWidth, innerHeight, (screen, area) {
      chart.drawLineChart(
        screen,
        area,
        telemetry.cpuSeries.values,
        lineStyle: lineStyle,
        showGrid: true,
        gridRows: 3,
        gridCols: 3,
        gridStyle: gridStyle,
        showMarkers: true,
        xLabels: const ['-45s', '-30s', '-15s', 'now'],
        yLabels: const ['100%', '50%', '0%'],
        labelStyle: gridStyle,
      );
    });

    return panelBox(
      title: 'CPU Line Trace',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildChartsPiePanel(DemoThemeData theme, int width, int height) {
    final innerWidth = math.max(12, width - 4);
    final innerHeight = math.max(4, height - 2);
    final palette = _chartPalettes[chartPaletteIndex % _chartPalettes.length];
    final sliceStyles = palette.seriesHex
        .map(chart.uvStyleFromHex)
        .toList(growable: false);

    final values = [
      telemetry.cpu,
      telemetry.memory,
      telemetry.gpu,
      telemetry.temperature,
    ];

    final lines = _renderChartLines(innerWidth, innerHeight, (screen, area) {
      chart.drawPieChart(
        screen,
        area,
        values,
        styles: sliceStyles,
        donut: true,
        useBackground: true,
      );
      final legendEntries = [
        chart.ChartLegendEntry(
          label: 'cpu',
          style: sliceStyles[0],
          labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
        ),
        chart.ChartLegendEntry(
          label: 'mem',
          style: sliceStyles[1],
          labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
        ),
        chart.ChartLegendEntry(
          label: 'gpu',
          style: sliceStyles[2],
          labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
        ),
        chart.ChartLegendEntry(
          label: 'tmp',
          style: sliceStyles[3],
          labelStyle: chart.uvStyleFromHex(theme.palette.textDim.toHex()),
        ),
      ];
      final legendWidth = math.max(6, math.min(26, area.width - 1));
      final legendArea = Rectangle(
        minX: area.minX + 1,
        minY: area.maxY - 3,
        maxX: area.minX + 1 + legendWidth,
        maxY: area.maxY - 1,
      );
      _clearChartArea(screen, legendArea);
      chart.drawLegend(screen, legendArea, legendEntries, columns: 2);
    });

    return panelBox(
      title: 'Resource Pie',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildChartsHelpPanel(DemoThemeData theme, int width, int height) {
    final palette = _chartPalettes[chartPaletteIndex % _chartPalettes.length];
    final accent = Style().foreground(theme.palette.accentBold);
    final dim = Style().foreground(theme.palette.textDim);

    final lines = <String>[
      accent.render('Charts Controls'),
      'm  palette (${palette.name})',
      '[ / ]  switch pages',
      '1 / 2 / 3  jump',
      '',
      dim.render('Palette'),
      palette.seriesHex.map((hex) => hex.toUpperCase()).join('  '),
    ];

    return panelBox(
      title: 'Charts Help',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  List<String> _renderChartLines(
    int width,
    int height,
    chart.ChartPainter painter,
  ) {
    final lines = chart.renderChartLines(width, height, painter);
    return fitChartLines(lines, width, height);
  }

  void _clearChartArea(Screen screen, Rectangle area) {
    if (area.isEmpty) return;
    for (var y = area.minY; y < area.maxY; y++) {
      for (var x = area.minX; x < area.maxX; x++) {
        screen.setCell(x, y, Cell(content: ' ', style: const UvStyle()));
      }
    }
  }

  String _buildPhysicsPanel(DemoThemeData theme, int width, int height) {
    final innerWidth = math.max(10, width - 4);
    final innerHeight = math.max(5, height - 2);
    final lines = renderPhysicsScene(
      scene: physics,
      width: innerWidth,
      height: innerHeight,
      theme: theme,
    );
    return panelBox(
      title: 'Physics Lab',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.accentBold),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildPhysicsStatsPanel(DemoThemeData theme, int width, int height) {
    var totalSpeed = 0.0;
    var count = 0;
    for (final body in physics.bodies) {
      if (body.bodyType != BodyType.dynamic) continue;
      totalSpeed += body.linearVelocity.length;
      count++;
    }
    final avgSpeed = count == 0 ? 0.0 : totalSpeed / count;

    final lines = <String>[
      'Gravity: ${physics.gravityEnabled ? 'ON' : 'OFF'}',
      'Bodies:  ${physics.bodies.length}',
      'Avg v:   ${avgSpeed.toStringAsFixed(2)}',
      '',
      Style().foreground(theme.palette.textDim).render('Controls'),
      'g  toggle gravity',
      's  spawn bodies',
      'x  blast impulse',
      'r  reset world',
      '',
      Style().foreground(theme.palette.textDim).render('Pages'),
      '[ / ] or 1 / 2 / 3',
    ];

    return panelBox(
      title: 'Physics Control',
      lines: lines,
      width: width,
      height: height,
      borderStyle: Style().foreground(theme.palette.border),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildTelemetryPanel(DemoThemeData theme, int width, int height) {
    final innerWidth = math.max(12, width - 4);
    final barWidth = math.max(10, innerWidth - 18);

    final lines = <String>[
      'CPU  ${renderBar(telemetry.cpu / 100, barWidth, theme.chartA)} ${telemetry.cpu.toStringAsFixed(1).padLeft(5)}%',
      'MEM  ${renderBar(telemetry.memory / 100, barWidth, theme.chartB)} ${telemetry.memory.toStringAsFixed(1).padLeft(5)}%',
      'GPU  ${renderBar(telemetry.gpu / 100, barWidth, theme.chartC)} ${telemetry.gpu.toStringAsFixed(1).padLeft(5)}%',
      'TMP  ${renderBar(telemetry.temperature / 100, barWidth, theme.chartD)} ${telemetry.temperature.toStringAsFixed(1).padLeft(5)}°C',
      '',
      'CPU ${renderSparkline(telemetry.cpuSeries.values, math.max(10, innerWidth - 4), theme.chartA)}',
      'NET ${renderSparkline(telemetry.netSeries.values, math.max(10, innerWidth - 4), theme.chartC)}',
    ];

    return panelBox(
      title: 'Telemetry Core',
      lines: lines,
      width: width,
      height: height,
      borderStyle: _borderStyleFor(FocusArea.nodes, theme),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildNodesPanel(DemoThemeData theme, int width, int height) {
    final listView = nodeList.view();
    return panelBox(
      title: 'Node Swarm',
      lines: listView.split('\n'),
      width: width,
      height: height,
      borderStyle: _borderStyleFor(FocusArea.nodes, theme, panel: true),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildPipelinePanel(DemoThemeData theme, int width, int height) {
    final innerHeight = math.max(3, height - 2);
    final stage = pipeline.stages[pipeline.stageIndex];
    final spinner = pipelineSpinner.view();
    final progress = pipelineProgress.view();

    final rows = <List<Object?>>[];
    for (var i = 0; i < pipeline.stages.length; i++) {
      final label = pipeline.stages[i];
      final state = i < pipeline.stageIndex
          ? 'DONE'
          : i == pipeline.stageIndex
          ? 'RUN'
          : 'PEND';
      final eta = i < pipeline.stageIndex
          ? 'ok'
          : i == pipeline.stageIndex
          ? '${(pipeline.progress * 100).round()}%'
          : '--';
      rows.add([label, state, eta]);
    }

    final table = TableComponent(
      headers: const ['Stage', 'State', 'ETA'],
      rows: rows,
      styleFunc: (row, col, data) {
        if (row < 0) {
          return Style().foreground(theme.palette.textBold).bold();
        }
        if (col == 1 && data == 'RUN') {
          return Style().foreground(theme.palette.accentBold).bold();
        }
        if (col == 1 && data == 'DONE') {
          return Style().foreground(theme.palette.success);
        }
        if (col == 1 && data == 'PEND') {
          return Style().foreground(theme.palette.textDim);
        }
        return null;
      },
    ).render();

    final headerLines = <String>[
      'Active: ${Style().foreground(theme.palette.accent).render(stage)}  $spinner',
      progress,
      '',
    ];

    final available = innerHeight - headerLines.length;
    final tableLines = table.split('\n');
    final lines = <String>[...headerLines];

    if (available >= 5) {
      final top = tableLines.take(3).toList();
      final bottom = tableLines.last;
      final rowLines = tableLines.sublist(3, tableLines.length - 1);
      final rowSlots = available - 4; // top(3) + bottom(1)
      final maxStart = math.max(0, rowLines.length - rowSlots);
      final start = (pipeline.stageIndex - rowSlots ~/ 2).clamp(0, maxStart);
      final visibleRows = rowLines
          .skip(start)
          .take(rowSlots)
          .toList(growable: false);
      lines
        ..addAll(top)
        ..addAll(visibleRows)
        ..add(bottom);
    } else {
      final nextStage =
          pipeline.stages[(pipeline.stageIndex + 1) % pipeline.stages.length];
      lines.addAll([
        'Next: ${Style().foreground(theme.palette.textBold).render(nextStage)}',
        'Stages: ${pipeline.stages.length} total',
      ]);
    }

    return panelBox(
      title: 'Pipeline Forge',
      lines: lines,
      width: width,
      height: height,
      borderStyle: _borderStyleFor(FocusArea.nodes, theme),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildLogsPanel(DemoThemeData theme, int width, int height) {
    final status = paused
        ? Style().foreground(theme.palette.warning).render('PAUSED')
        : Style().foreground(theme.palette.success).render('LIVE');
    final follow = followLogs
        ? Style().foreground(theme.palette.info).render('FOLLOW')
        : Style().foreground(theme.palette.textDim).render('FREE');
    final header =
        '$status  $follow  logs:${logs.length.toString().padLeft(3)}';

    final viewportLines = logViewport.view().split('\n');
    final lines = [header, ...viewportLines];

    return panelBox(
      title: 'Event Stream',
      lines: lines,
      width: width,
      height: height,
      borderStyle: _borderStyleFor(FocusArea.logs, theme, panel: true),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildTopologyPanel(DemoThemeData theme, int width, int height) {
    final innerWidth = math.max(10, width - 4);
    final innerHeight = math.max(4, height - 2);

    final selected = nodeList.selectedItem;
    final node = selected is NodeItem ? selected.node : null;
    final nodeLine = node == null
        ? 'no node selected'
        : '${node.name} ${node.region}  ${node.latency.toStringAsFixed(0)}ms  err ${node.errors}';

    final mapHeight = math.max(3, innerHeight - 2);
    final topoLines = renderTopology(
      layout: topology,
      width: innerWidth,
      height: mapHeight,
      selectedIndex: node == null ? 0 : nodes.indexOf(node) + 1,
      phase: topologyPhase,
      theme: theme,
    );

    final lines = [
      Style().foreground(theme.palette.textBold).render(nodeLine),
      Style()
          .foreground(theme.palette.textDim)
          .render('pulse field ${topologyPhase.toStringAsFixed(1)}'),
      ...topoLines,
    ];

    return panelBox(
      title: 'Topology Pulse',
      lines: lines,
      width: width,
      height: height,
      borderStyle: _borderStyleFor(FocusArea.logs, theme),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  String _buildConsolePanel(DemoThemeData theme, int width, int height) {
    final innerHeight = math.max(3, height - 2);
    final maxHistory = math.max(1, innerHeight - 1);
    final start = consoleLines.length > maxHistory
        ? consoleLines.length - maxHistory
        : 0;
    final history = consoleLines.sublist(start);
    final inputLine = consoleInput.view().toString();
    final lines = [...history, inputLine];

    return panelBox(
      title: 'Command Console',
      lines: lines,
      width: width,
      height: height,
      borderStyle: _borderStyleFor(FocusArea.console, theme, panel: true),
      titleStyle: Style().foreground(theme.palette.accentBold),
    );
  }

  Style _borderStyleFor(
    FocusArea area,
    DemoThemeData theme, {
    bool panel = false,
  }) {
    if (focus == area && panel) {
      return Style().foreground(theme.palette.accentBold).bold();
    }
    return Style().foreground(theme.palette.border);
  }

  tui.Cmd? _batch(List<tui.Cmd> cmds) {
    if (cmds.isEmpty) return null;
    return tui.Cmd.batch(cmds);
  }
}

List<int> _distributeHeights(int total, List<int> weights) {
  final sum = weights.fold<int>(0, (a, b) => a + b);
  final heights = weights
      .map((w) => (total * w / sum).floor())
      .toList(growable: false);
  var used = heights.fold<int>(0, (a, b) => a + b);
  var idx = 0;
  while (used < total) {
    heights[idx % heights.length] += 1;
    used++;
    idx++;
  }
  return heights;
}

String _padBlock(String block, int width) {
  return block.split('\n').map((line) => Layout.pad(line, width)).join('\n');
}

List<String> _commandSuggestions = [
  'help',
  'pause',
  'resume',
  'theme obsidian',
  'theme aurora',
  'theme monokai',
  'theme dracula',
  'theme nord',
  'focus nodes',
  'focus logs',
  'focus console',
  'clear',
  'reseed',
  'inject warn mesh overheating',
];
