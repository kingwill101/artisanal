// tui:allow-stdout
import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/tui.dart';
import 'package:artisanal/uv.dart' as uv;

const _connectTimeout = Duration(seconds: 30);
const _snapshotSettleDelay = Duration(milliseconds: 150);
const _workspaceWidth = 96;
const _workspaceHeight = 29;
const _primaryPluginId = 'overview';
const _defaultPluginDirectoryPath =
    'pkgs/artisanal/example/tui/remote_plugin_workspace/plugins';
const _pluginDirectoryEnvVar = 'ARTISANAL_REMOTE_PLUGIN_WORKSPACE_PLUGIN_DIR';

Future<void> main(List<String> args) async {
  if (args.contains('--snapshot')) {
    final runtime = await _startWorkspace(_primaryPluginId);
    var selectedPluginId = _primaryPluginId;
    final click = _parseSnapshotClick(args);
    final motion = _parseSnapshotMotion(args);
    final key = _parseSnapshotKey(args);
    try {
      await _waitForSnapshotWorkspaceReady(runtime);
      if (click case final point?) {
        selectedPluginId = await _routeWorkspaceMousePress(
          runtime,
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: point.$1,
            y: point.$2,
          ),
          selectedPluginId: selectedPluginId,
        );
        await _waitForSnapshotSurfaceText(
          runtime,
          selectedPluginId,
          contains:
              '${_pluginDisplayName(runtime, selectedPluginId)} [focused]',
        );
      }
      if (key case final value?) {
        await _routeWorkspaceKey(runtime, value);
        await _waitForSnapshotSurfaceText(
          runtime,
          selectedPluginId,
          contains: _snapshotKeyExpectation(value.label),
          timeout: _snapshotKeyTimeout(value.label),
        );
      }
      if (motion case final point?) {
        await _routeWorkspaceMouseMotion(
          runtime,
          MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.none,
            x: point.$1,
            y: point.$2,
          ),
        );
        await _waitForSnapshotSurfaceText(
          runtime,
          'alerts',
          contains: 'Hover: ${point.$1 - 3},${point.$2 - 17}',
        );
      }
      io.stdout.writeln(
        _renderWorkspace(
          loading: false,
          selectedPluginId: selectedPluginId,
          status: switch ((click, motion, key)) {
            (null, null, null) => 'Snapshot render',
            (_, null, null) => 'Snapshot click render',
            (_, _, null) => 'Snapshot pointer render',
            _ => 'Snapshot input render',
          },
          log: <String>[
            'Snapshot mode',
            if (click != null) 'click ${click.$1},${click.$2}',
            if (motion != null) 'motion ${motion.$1},${motion.$2}',
            if (key != null) 'key ${key.label}',
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
      mouseMode: MouseMode.allMotion,
      startupTitle: 'Remote Plugin Workspace',
    ),
  );
}

String _snapshotKeyExpectation(String label) {
  return switch (label) {
    'c' => 'Clipboard: workspace clipboard',
    'o' => 'URL: opened',
    'n' => 'Notice: sent',
    'p' => 'Picker: /tmp/workspace.txt',
    _ => 'Last key: $label',
  };
}

Duration _snapshotKeyTimeout(String label) {
  return switch (label) {
    'c' || 'o' || 'n' || 'p' => const Duration(seconds: 10),
    _ => const Duration(seconds: 2),
  };
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

  final plugins.RemotePluginWorkspace? runtime;
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
      _HostMouseRoutedMsg(:final pluginId) => (
        copyWith(
          selectedPluginId: pluginId,
          status: 'Clicked $pluginId',
          revision: revision + 1,
          log: _appendLog(log, 'mouse $pluginId'),
        ),
        null,
      ),
      _HostKeyRoutedMsg(:final label) => (
        copyWith(
          status: 'Sent key $label to $selectedPluginId',
          revision: revision + 1,
          log: _appendLog(log, 'key $label'),
        ),
        null,
      ),
      _HostMouseMovedMsg(:final pluginId) => (
        copyWith(
          status: pluginId == null ? 'Hover cleared' : 'Hovering $pluginId',
          revision: revision + 1,
          log: _appendLog(
            log,
            pluginId == null ? 'hover none' : 'hover $pluginId',
          ),
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
          log: _appendLog(log, '$pluginId: ${message.messageType.wireName}'),
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
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x31])) => _focusPlugin(
        'overview',
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x32])) => _focusPlugin(
        'activity',
      ),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x33])) => _focusPlugin(
        'alerts',
      ),
      MouseMsg(action: MouseAction.press) => _handleMousePress(msg),
      MouseMsg(action: MouseAction.motion) => _handleMouseMotion(msg),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x72])) => _reload(),
      KeyMsg(:final key) => _handlePluginKey(key),
      _ => (this, null),
    };
  }

  (Model, Cmd?) _handleWorkspaceLoaded(
    plugins.RemotePluginWorkspace nextRuntime,
  ) {
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

  (Model, Cmd?) _handleMousePress(MouseMsg msg) {
    final activeRuntime = runtime;
    if (activeRuntime == null || loading) {
      return (this, null);
    }

    return (
      copyWith(
        status: 'Routing click at ${msg.x},${msg.y}',
        revision: revision + 1,
      ),
      Cmd.perform(
        () => _routeWorkspaceMousePress(
          activeRuntime,
          msg,
          selectedPluginId: selectedPluginId,
        ),
        onSuccess: _HostMouseRoutedMsg.new,
        onError: (error, _) => _WorkspaceLoadFailedMsg('mouse failed: $error'),
      ),
    );
  }

  (Model, Cmd?) _handlePluginKey(Key key) {
    final activeRuntime = runtime;
    if (activeRuntime == null || loading) {
      return (this, null);
    }

    final snapshotKey = _snapshotKeyFromKey(key);
    final keyLabel = snapshotKey.label;
    return (
      copyWith(status: 'Routing key $keyLabel', revision: revision + 1),
      Cmd.perform(
        () => _routeWorkspaceKey(activeRuntime, snapshotKey),
        onSuccess: (value) => _HostKeyRoutedMsg(value.label),
        onError: (error, _) => _WorkspaceLoadFailedMsg('key failed: $error'),
      ),
    );
  }

  (Model, Cmd?) _handleMouseMotion(MouseMsg msg) {
    final activeRuntime = runtime;
    if (activeRuntime == null || loading) {
      return (this, null);
    }

    return (
      copyWith(
        status: 'Routing hover at ${msg.x},${msg.y}',
        revision: revision + 1,
      ),
      Cmd.perform(
        () => _routeWorkspaceMouseMotion(activeRuntime, msg),
        onSuccess: _HostMouseMovedMsg.new,
        onError: (error, _) => _WorkspaceLoadFailedMsg('hover failed: $error'),
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
    plugins.RemotePluginWorkspace? runtime,
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

  final plugins.RemotePluginWorkspace runtime;
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

final class _HostMouseRoutedMsg extends Msg {
  const _HostMouseRoutedMsg(this.pluginId);

  final String pluginId;
}

final class _HostKeyRoutedMsg extends Msg {
  const _HostKeyRoutedMsg(this.label);

  final String label;
}

final class _HostMouseMovedMsg extends Msg {
  const _HostMouseMovedMsg(this.pluginId);

  final String? pluginId;
}

Future<plugins.RemotePluginWorkspace> _startWorkspace(
  String selectedPluginId,
) async {
  final genericCatalog = plugins.RemotePluginGenericServiceCatalog.builtIns(
    readClipboard: (_) => 'workspace clipboard',
    openUrl: (_) {},
    notify: (_) {},
    pickPaths: (_) => const <String>['/tmp/workspace.txt'],
  );
  final pluginDirectoryPath =
      io.Platform.environment[_pluginDirectoryEnvVar] ??
      _defaultPluginDirectoryPath;
  final runtime = await plugins.RemotePluginWorkspace.startManifestDirectory(
    _resolveWorkspacePath(pluginDirectoryPath),
    executable: io.Platform.resolvedExecutable,
    hostHello: plugins.RemotePluginHostHello(
      hostName: 'artisanal',
      hostVersion: '0.2.0',
      capabilities: const <String>['surfaces'],
    ),
    genericServices: genericCatalog,
    timeout: _connectTimeout,
  );
  await runtime.focusPlugin(selectedPluginId);
  await Future<void>.delayed(_snapshotSettleDelay);
  return runtime;
}

Future<void> _applyFocus(
  plugins.RemotePluginWorkspace runtime,
  String pluginId,
) async {
  await runtime.focusPlugin(pluginId);
}

Future<String> _routeWorkspaceMousePress(
  plugins.RemotePluginWorkspace runtime,
  MouseMsg msg, {
  required String selectedPluginId,
}) async {
  final hit = runtime.router.hitTest(msg.x, msg.y);
  if (hit == null) {
    return selectedPluginId;
  }

  final pluginId = runtime.pluginIdForSurface(hit.surface.surfaceId);
  if (pluginId != null) {
    await _applyFocus(runtime, pluginId);
    selectedPluginId = pluginId;
  }

  await runtime.router.sendTuiMouse(msg, focusOnPress: false);
  return selectedPluginId;
}

Future<_SnapshotKey> _routeWorkspaceKey(
  plugins.RemotePluginWorkspace runtime,
  _SnapshotKey key,
) async {
  await runtime.router.sendKey(
    key: key.value,
    code: key.code,
    ctrl: key.ctrl,
    alt: key.alt,
    shift: key.shift,
    meta: key.meta,
  );
  return key;
}

Future<String?> _routeWorkspaceMouseMotion(
  plugins.RemotePluginWorkspace runtime,
  MouseMsg msg,
) async {
  final hit = await runtime.router.sendTuiMouse(msg, focusOnPress: false);
  if (hit == null) {
    return null;
  }
  return runtime.pluginIdForSurface(hit.surface.surfaceId);
}

Future<void> _waitForSnapshotSurfaceText(
  plugins.RemotePluginWorkspace runtime,
  String pluginId, {
  required String contains,
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (_surfaceContainsText(runtime, pluginId, contains)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Future<void> _waitForSnapshotWorkspaceReady(
  plugins.RemotePluginWorkspace runtime, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  for (final expectation in const <(String, String)>[
    ('overview', 'Overview'),
    ('activity', 'Activity'),
    ('alerts', 'Alerts'),
  ]) {
    await _waitForSnapshotSurfaceText(
      runtime,
      expectation.$1,
      contains: expectation.$2,
      timeout: timeout,
    );
  }
}

bool _surfaceContainsText(
  plugins.RemotePluginWorkspace runtime,
  String pluginId,
  String contains,
) {
  final manifest = runtime.manifestForPlugin(pluginId);
  if (manifest == null) {
    return false;
  }

  final surface = runtime.surfaces[manifest.primarySurfaceId];
  if (surface == null || surface.height < 2) {
    return false;
  }

  for (var row = 0; row < surface.height; row++) {
    final line = <String>[
      for (var column = 0; column < surface.width; column++)
        surface.cellAt(column, row).symbol,
    ].join();
    if (line.contains(contains)) {
      return true;
    }
  }
  return false;
}

String _resolveWorkspacePath(String path) {
  return io.Directory.current.uri.resolve(path).toFilePath();
}

String _pluginDisplayName(
  plugins.RemotePluginWorkspace runtime,
  String pluginId,
) {
  return runtime.manifestForPlugin(pluginId)?.displayName ?? pluginId;
}

(int, int)? _parseSnapshotClick(List<String> args) {
  for (final arg in args) {
    if (!arg.startsWith('--snapshot-click=')) {
      continue;
    }

    final value = arg.substring('--snapshot-click='.length);
    final parts = value.split(',');
    if (parts.length != 2) {
      throw FormatException(
        'Expected --snapshot-click=<column>,<row>, got "$value".',
      );
    }
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
  return null;
}

(int, int)? _parseSnapshotMotion(List<String> args) {
  for (final arg in args) {
    if (!arg.startsWith('--snapshot-motion=')) {
      continue;
    }

    final value = arg.substring('--snapshot-motion='.length);
    final parts = value.split(',');
    if (parts.length != 2) {
      throw FormatException(
        'Expected --snapshot-motion=<column>,<row>, got "$value".',
      );
    }
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
  return null;
}

_SnapshotKey? _parseSnapshotKey(List<String> args) {
  for (final arg in args) {
    if (!arg.startsWith('--snapshot-key=')) {
      continue;
    }

    final value = arg.substring('--snapshot-key='.length);
    return _pluginHostKey(value);
  }
  return null;
}

_SnapshotKey _snapshotKeyFromKey(Key key) {
  return _SnapshotKey(
    value: key.char ?? key.type.name,
    code: key.char == null ? key.type.name : null,
    ctrl: key.ctrl,
    alt: key.alt,
    shift: key.shift,
    meta: key.meta,
  );
}

_SnapshotKey _pluginHostKey(String value) {
  return switch (value) {
    'Enter' => const _SnapshotKey(value: 'Enter', code: 'Enter'),
    'Tab' => const _SnapshotKey(value: 'Tab', code: 'Tab'),
    'Escape' => const _SnapshotKey(value: 'Escape', code: 'Escape'),
    'ArrowUp' => const _SnapshotKey(value: 'ArrowUp', code: 'ArrowUp'),
    'ArrowDown' => const _SnapshotKey(value: 'ArrowDown', code: 'ArrowDown'),
    'ArrowLeft' => const _SnapshotKey(value: 'ArrowLeft', code: 'ArrowLeft'),
    'ArrowRight' => const _SnapshotKey(value: 'ArrowRight', code: 'ArrowRight'),
    _ => _SnapshotKey(value: value, code: null),
  };
}

final class _SnapshotKey {
  const _SnapshotKey({
    required this.value,
    required this.code,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  final String value;
  final String? code;
  final bool ctrl;
  final bool alt;
  final bool shift;
  final bool meta;

  String get label {
    final modifiers = <String>[
      if (ctrl) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
      if (meta) 'Meta',
    ];
    if (modifiers.isEmpty) {
      return value;
    }
    return '${modifiers.join('+')}+$value';
  }
}

String _renderWorkspace({
  required bool loading,
  required String selectedPluginId,
  required String status,
  required List<String> log,
  required int revision,
  required plugins.RemotePluginWorkspace? runtime,
  String? error,
}) {
  final layers = <uv.Layer>[
    uv.Layer(
      uv.StyledString(
        _backgroundText(
          selectedPluginId: selectedPluginId,
          status: status,
          log: log,
          revision: revision,
          loading: loading,
          error: error,
        ),
      ),
    ).setId('host.background').setZ(0),
  ];

  if (runtime != null) {
    layers.addAll(
      plugins.buildRemotePluginSurfaceLayers(
        runtime.surfaces,
        placements: runtime.manifests.map(
          (manifest) => manifest.placement.toSurfacePlacement(),
        ),
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
  writeAt(2, 3, '1 overview  2 activity  3 alerts  r reload  q quit');
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
