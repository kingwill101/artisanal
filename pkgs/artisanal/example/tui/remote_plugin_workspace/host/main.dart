import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:artisanal/runtime.dart';
import 'package:artisanal/uv.dart' as uv;

const _connectTimeout = Duration(seconds: 15);
const _snapshotSettleDelay = Duration(milliseconds: 150);
const _workspaceWidth = 96;
const _workspaceHeight = 29;
const _primaryPluginId = 'overview';

Future<void> main(List<String> args) async {
  if (args.contains('--snapshot')) {
    final runtime = await _startWorkspace(_primaryPluginId);
    try {
      io.stdout.writeln(
        _renderWorkspace(
          loading: false,
          selectedPluginId: _primaryPluginId,
          status: 'Snapshot render',
          log: const <String>[
            'Snapshot mode',
            'Loaded 3 plugin processes',
          ],
          revision: 0,
          runtime: runtime,
        ),
      );
    } finally {
      await runtime.dispose(kill: true);
    }
    return;
  }

  await runProgram(
    const _RemotePluginWorkspaceModel(),
    options: const ProgramOptions(
      altScreen: true,
      startupProbes: false,
      hideCursor: false,
      startupTitle: 'Remote Plugin Workspace',
    ),
  );
}

final class _RemotePluginWorkspaceModel implements Model {
  const _RemotePluginWorkspaceModel({
    this.runtime,
    this.loading = true,
    this.selectedPluginId = _primaryPluginId,
    this.status = 'Starting plugin workspace...',
    this.log = const <String>[],
    this.error,
    this.revision = 0,
  });

  final _WorkspaceRuntime? runtime;
  final bool loading;
  final String selectedPluginId;
  final String status;
  final List<String> log;
  final String? error;
  final int revision;

  @override
  Cmd? init() {
    return Cmd.perform(
      () => _startWorkspace(selectedPluginId),
      onSuccess: _WorkspaceLoadedMsg.new,
      onError: (error, _) => _WorkspaceLoadFailedMsg(error.toString()),
    );
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      _WorkspaceLoadedMsg(:final runtime) => _handleWorkspaceLoaded(runtime),
      _WorkspaceLoadFailedMsg(:final message) => (
        copyWith(
          loading: false,
          error: message,
          status: 'Workspace failed to start',
          revision: revision + 1,
          log: _appendLog(log, 'error: $message'),
        ),
        null,
      ),
      _HostFocusAppliedMsg(:final pluginId) => (
        copyWith(
          status: 'Focused $pluginId',
          revision: revision + 1,
          log: _appendLog(log, 'focused $pluginId'),
        ),
        null,
      ),
      _PluginSurfaceChangedMsg(:final pluginId, :final message) => (
        copyWith(
          status: '$pluginId updated ${message.messageType.wireName}',
          revision: revision + 1,
        ),
        null,
      ),
      _PluginOtherMessageMsg(:final pluginId, :final message) => (
        copyWith(
          status: '$pluginId sent ${message.messageType.wireName}',
          revision: revision + 1,
          log: _appendLog(
            log,
            '$pluginId: ${message.messageType.wireName}',
          ),
        ),
        null,
      ),
      _PluginExitedMsg(:final pluginId, :final exitCode) => (
        copyWith(
          status: '$pluginId exited ($exitCode)',
          revision: revision + 1,
          log: _appendLog(log, '$pluginId exit=$exitCode'),
        ),
        null,
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => _quit(),
      KeyMsg(key: Key(type: KeyType.escape)) => _quit(),
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => _quit(),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x31])) =>
        _focusPlugin('overview'),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x32])) =>
        _focusPlugin('activity'),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x33])) =>
        _focusPlugin('alerts'),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x72])) => _reload(),
      _ => (this, null),
    };
  }

  (Model, Cmd?) _handleWorkspaceLoaded(_WorkspaceRuntime nextRuntime) {
    final commands = <Cmd>[
      for (final entry in nextRuntime.connections.entries)
        Cmd.listen<plugins.RemotePluginMessage>(
          entry.value.surfaceMessages,
          onData: (message) => _PluginSurfaceChangedMsg(entry.key, message),
          onError: (error, _) =>
              _WorkspaceLoadFailedMsg('surface stream ${entry.key}: $error'),
        ),
      for (final entry in nextRuntime.connections.entries)
        Cmd.listen<plugins.RemotePluginMessage>(
          entry.value.otherMessages,
          onData: (message) => _PluginOtherMessageMsg(entry.key, message),
          onError: (error, _) =>
              _WorkspaceLoadFailedMsg('other stream ${entry.key}: $error'),
        ),
      for (final entry in nextRuntime.connections.entries)
        Cmd.listen<int>(
          entry.value.process.exitCode.asStream(),
          onData: (exitCode) => _PluginExitedMsg(entry.key, exitCode),
        ),
    ];

    return (
      copyWith(
        runtime: nextRuntime,
        loading: false,
        clearError: true,
        status: 'Loaded ${nextRuntime.connections.length} plugin processes',
        revision: revision + 1,
        log: _appendLog(log, 'workspace ready'),
      ),
      Cmd.batch(commands),
    );
  }

  (Model, Cmd?) _focusPlugin(String pluginId) {
    final activeRuntime = runtime;
    if (activeRuntime == null || loading) {
      return (this, null);
    }

    return (
      copyWith(
        selectedPluginId: pluginId,
        status: 'Focusing $pluginId',
        revision: revision + 1,
        log: _appendLog(log, 'focus $pluginId'),
      ),
      Cmd.perform(
        () => _applyFocus(activeRuntime, pluginId),
        onSuccess: (_) => _HostFocusAppliedMsg(pluginId),
        onError: (error, _) => _WorkspaceLoadFailedMsg('focus failed: $error'),
      ),
    );
  }

  (Model, Cmd?) _reload() {
    final activeRuntime = runtime;
    return (
      copyWith(
        clearRuntime: true,
        loading: true,
        clearError: true,
        status: 'Reloading plugin workspace...',
        revision: revision + 1,
        log: _appendLog(log, 'reload'),
      ),
      Cmd.perform(
        () async {
          if (activeRuntime != null) {
            await activeRuntime.dispose(kill: true);
          }
          return _startWorkspace(selectedPluginId);
        },
        onSuccess: _WorkspaceLoadedMsg.new,
        onError: (error, _) => _WorkspaceLoadFailedMsg(error.toString()),
      ),
    );
  }

  (Model, Cmd?) _quit() {
    final activeRuntime = runtime;
    return (
      copyWith(
        status: 'Shutting down plugin workspace...',
        revision: revision + 1,
      ),
      Cmd.perform(
        () async {
          if (activeRuntime != null) {
            await activeRuntime.dispose(kill: true);
          }
          return const QuitMsg();
        },
        onSuccess: (message) => message,
        onError: (error, _) => _WorkspaceLoadFailedMsg(error.toString()),
      ),
    );
  }

  @override
  Object view() {
    return View(
      content: _renderWorkspace(
        loading: loading,
        selectedPluginId: selectedPluginId,
        status: status,
        log: log,
        revision: revision,
        runtime: runtime,
        error: error,
      ),
      altScreen: true,
      windowTitle: 'Remote Plugin Workspace',
    );
  }

  _RemotePluginWorkspaceModel copyWith({
    _WorkspaceRuntime? runtime,
    bool clearRuntime = false,
    bool? loading,
    String? selectedPluginId,
    String? status,
    List<String>? log,
    String? error,
    bool clearError = false,
    int? revision,
  }) {
    return _RemotePluginWorkspaceModel(
      runtime: clearRuntime ? null : (runtime ?? this.runtime),
      loading: loading ?? this.loading,
      selectedPluginId: selectedPluginId ?? this.selectedPluginId,
      status: status ?? this.status,
      log: log ?? this.log,
      error: clearError ? null : (error ?? this.error),
      revision: revision ?? this.revision,
    );
  }
}

final class _WorkspaceLoadedMsg extends Msg {
  const _WorkspaceLoadedMsg(this.runtime);

  final _WorkspaceRuntime runtime;
}

final class _WorkspaceLoadFailedMsg extends Msg {
  const _WorkspaceLoadFailedMsg(this.message);

  final String message;
}

final class _PluginSurfaceChangedMsg extends Msg {
  const _PluginSurfaceChangedMsg(this.pluginId, this.message);

  final String pluginId;
  final plugins.RemotePluginMessage message;
}

final class _PluginOtherMessageMsg extends Msg {
  const _PluginOtherMessageMsg(this.pluginId, this.message);

  final String pluginId;
  final plugins.RemotePluginMessage message;
}

final class _PluginExitedMsg extends Msg {
  const _PluginExitedMsg(this.pluginId, this.exitCode);

  final String pluginId;
  final int exitCode;
}

final class _HostFocusAppliedMsg extends Msg {
  const _HostFocusAppliedMsg(this.pluginId);

  final String pluginId;
}

final class _WorkspaceRuntime {
  const _WorkspaceRuntime({
    required this.surfaces,
    required this.connections,
  });

  final plugins.RemotePluginSurfaceStore surfaces;
  final Map<String, plugins.RemotePluginHostConnection> connections;

  Future<void> dispose({bool kill = false}) async {
    for (final connection in connections.values) {
      await connection.dispose(kill: kill);
    }
  }
}

final class _PluginSpec {
  const _PluginSpec({
    required this.id,
    required this.scriptPath,
    required this.primarySurfaceId,
    required this.surfaceIds,
    required this.placement,
  });

  final String id;
  final String scriptPath;
  final String primarySurfaceId;
  final List<String> surfaceIds;
  final plugins.RemotePluginSurfacePlacement placement;
}

const _pluginSpecs = <_PluginSpec>[
  _PluginSpec(
    id: 'overview',
    scriptPath:
        'pkgs/artisanal/example/tui/remote_plugin_workspace/plugins/overview_plugin.dart',
    primarySurfaceId: 'overview.panel',
    surfaceIds: <String>['overview.panel'],
    placement: plugins.RemotePluginSurfacePlacement(
      surfaceId: 'overview.panel',
      x: 3,
      y: 5,
      z: 10,
    ),
  ),
  _PluginSpec(
    id: 'activity',
    scriptPath:
        'pkgs/artisanal/example/tui/remote_plugin_workspace/plugins/activity_plugin.dart',
    primarySurfaceId: 'activity.panel',
    surfaceIds: <String>['activity.panel'],
    placement: plugins.RemotePluginSurfacePlacement(
      surfaceId: 'activity.panel',
      x: 36,
      y: 5,
      z: 10,
    ),
  ),
  _PluginSpec(
    id: 'alerts',
    scriptPath:
        'pkgs/artisanal/example/tui/remote_plugin_workspace/plugins/alerts_plugin.dart',
    primarySurfaceId: 'alerts.panel',
    surfaceIds: <String>['alerts.panel', 'alerts.popup'],
    placement: plugins.RemotePluginSurfacePlacement(
      surfaceId: 'alerts.panel',
      x: 3,
      y: 17,
      z: 10,
    ),
  ),
];

Future<_WorkspaceRuntime> _startWorkspace(String selectedPluginId) async {
  final surfaces = plugins.RemotePluginSurfaceStore();
  final connections = <String, plugins.RemotePluginHostConnection>{};
  try {
    for (final spec in _pluginSpecs) {
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[_resolveWorkspacePath(spec.scriptPath)],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
          capabilities: <String>['surfaces'],
        ),
        surfaces: surfaces,
        timeout: _connectTimeout,
      );
      connections[spec.id] = connection;
    }

    await _waitForSurfaceIds(
      surfaces,
      _pluginSpecs.expand((spec) => spec.surfaceIds),
    );

    final runtime = _WorkspaceRuntime(
      surfaces: surfaces,
      connections: connections,
    );
    await _applyFocus(runtime, selectedPluginId);
    await Future<void>.delayed(_snapshotSettleDelay);
    return runtime;
  } catch (_) {
    for (final connection in connections.values) {
      await connection.dispose(kill: true);
    }
    rethrow;
  }
}

Future<void> _applyFocus(_WorkspaceRuntime runtime, String pluginId) async {
  final specById = <String, _PluginSpec>{
    for (final spec in _pluginSpecs) spec.id: spec,
  };
  final selected = specById[pluginId];
  if (selected == null) {
    return;
  }

  for (final spec in _pluginSpecs) {
    final connection = runtime.connections[spec.id];
    if (connection == null) {
      continue;
    }
    final message = spec.id == pluginId
        ? plugins.RemotePluginFocusInput(surfaceId: spec.primarySurfaceId)
        : plugins.RemotePluginBlurInput(surfaceId: spec.primarySurfaceId);
    await connection.send(message);
  }
}

Future<void> _waitForSurfaceIds(
  plugins.RemotePluginSurfaceStore surfaces,
  Iterable<String> surfaceIds, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  final expected = surfaceIds.toSet();
  while (DateTime.now().isBefore(deadline)) {
    final open = expected.every((surfaceId) => surfaces[surfaceId] != null);
    if (open) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }

  throw TimeoutException(
    'Timed out waiting for plugin surfaces: ${expected.join(', ')}',
    timeout,
  );
}

String _resolveWorkspacePath(String path) {
  return io.Directory.current.uri.resolve(path).toFilePath();
}

String _renderWorkspace({
  required bool loading,
  required String selectedPluginId,
  required String status,
  required List<String> log,
  required int revision,
  required _WorkspaceRuntime? runtime,
  String? error,
}) {
  final layers = <uv.Layer>[
    uv.Layer(uv.StyledString(_backgroundText(
      selectedPluginId: selectedPluginId,
      status: status,
      log: log,
      revision: revision,
      loading: loading,
      error: error,
    ))).setId('host.background').setZ(0),
  ];

  if (runtime != null) {
    layers.addAll(
      plugins.buildRemotePluginSurfaceLayers(
        runtime.surfaces,
        placements: _pluginSpecs.map((spec) => spec.placement),
      ),
    );
  }

  return uv.Compositor(layers).render();
}

String _backgroundText({
  required String selectedPluginId,
  required String status,
  required List<String> log,
  required int revision,
  required bool loading,
  required String? error,
}) {
  final grid = List<List<String>>.generate(
    _workspaceHeight,
    (_) => List<String>.filled(_workspaceWidth, ' '),
  );

  void writeAt(int row, int column, String text) {
    if (row < 0 || row >= _workspaceHeight) {
      return;
    }
    for (var index = 0; index < text.length; index++) {
      final target = column + index;
      if (target < 0 || target >= _workspaceWidth) {
        continue;
      }
      grid[row][target] = text[index];
    }
  }

  grid[0][0] = '┌';
  grid[0][_workspaceWidth - 1] = '┐';
  grid[_workspaceHeight - 1][0] = '└';
  grid[_workspaceHeight - 1][_workspaceWidth - 1] = '┘';
  for (var column = 1; column < _workspaceWidth - 1; column++) {
    grid[0][column] = '─';
    grid[3][column] = '─';
    grid[_workspaceHeight - 6][column] = '─';
    grid[_workspaceHeight - 1][column] = '─';
  }
  for (var row = 1; row < _workspaceHeight - 1; row++) {
    grid[row][0] = '│';
    grid[row][_workspaceWidth - 1] = '│';
  }

  writeAt(1, 3, 'Remote Plugin Workspace');
  writeAt(
    2,
    3,
    '1 overview  2 activity  3 alerts  r reload  q quit',
  );
  writeAt(
    4,
    3,
    'Selected: $selectedPluginId    Revision: $revision    ${loading ? 'loading...' : 'running'}',
  );
  writeAt(5, 3, 'Status: $status');
  if (error != null) {
    writeAt(6, 3, 'Error: $error');
  } else {
    writeAt(
      6,
      3,
      'Host app composes three remote plugin processes into one UV canvas.',
    );
  }
  writeAt(_workspaceHeight - 5, 3, 'Recent host events');

  final visibleLog = log.isEmpty ? const <String>['(no host events yet)'] : log;
  for (var index = 0; index < 4; index++) {
    final line = index < visibleLog.length ? visibleLog[index] : '';
    writeAt(_workspaceHeight - 4 + index, 3, line);
  }

  return grid.map((row) => row.join()).join('\n');
}

List<String> _appendLog(List<String> log, String entry) {
  final next = <String>[entry, ...log];
  if (next.length > 4) {
    return next.sublist(0, 4);
  }
  return next;
}
