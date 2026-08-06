// OpenCode Chat UI — Widget Example
//
// Demonstrates an OpenCode-style chat interface built with
// artisanal_widgets: session header, scrollable message body with
// text/tool/reasoning parts, prompt input, sidebar with collapsible
// sections, footer status bar, and a command palette overlay.
//
// Run with: dart run example/opencode/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:artisanal_widgets/src/widgets/animation/spinner_controller.dart';
import 'chords.dart';
import 'data.dart';
import 'models/chat_model.dart';
import 'models/message.dart';
import 'screens/agent_overview.dart';
import 'screens/home.dart';
import 'screens/review.dart';
import 'screens/session.dart';
import 'theme.dart';
import 'widgets/dialog/agent_list_dialog.dart';
import 'widgets/dialog/open_code_overlay.dart';
import 'widgets/model_list_dialog.dart';
import 'widgets/session_list_dialog.dart';
import 'widgets/state/build_mode.dart';
import 'widgets/state/open_code_ui_state.dart';
import 'widgets/theme_list_dialog.dart';

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class OpenCodeApp extends w.StatefulWidget {
  OpenCodeApp({tui.KeymapHub? hub, super.key})
      : hub = hub ?? openCodeKeymapHub();

  /// Surface-first keymap hub (also the program interceptor).
  final tui.KeymapHub hub;

  @override
  w.State createState() => _OpenCodeAppState();
}

class _HideCopyToastMsg extends tui.Msg {
  const _HideCopyToastMsg(this.token);
  final int token;
}

class _OpenCodeAppState extends w.State<OpenCodeApp> {
  w.NavigatorState? _navigator;
  late ChatModel _model;
  final _scrollController = w.WidgetScrollController();
  final _promptController = w.TextFieldController();
  bool _commandPaletteOpen = false;
  String _currentThemeName = openCodeDefaultThemeName;
  List<String> _themeOptions = const [openCodeDefaultThemeName];
  String? _copyToastMessage;
  int _copyToastToken = 0;
  String _footerStatusHint = '/status';
  w.ReplayEventHistoryState _replayHistory = const w.ReplayEventHistoryState(
    filter: w.ReplayEventHistoryFilter.renderCaptures,
    mode: w.ReplayEventHistoryMode.grouped,
  );
  final List<tui.ReplayEventPresentation> _recentReplayPresentations =
      <tui.ReplayEventPresentation>[];
  late final SpinnerController _scannerController;

  /// Last known terminal width for responsive sidebar toggles (OpenCode >120).
  int _terminalWidth = 120;

  /// Inline session dock demo (permission / question above prompt).
  SessionAgentDock _sessionDock = SessionAgentDock.none;

  /// OpenCode-style mutual-exclusion picker overlay (stable Stack host).
  OpenCodeOverlayKind _overlay = OpenCodeOverlayKind.none;

  @override
  void initState() {
    super.initState();
    // Do not listen to hub here — KeymapHubScope rebuilds on pending/stack
    // changes. Rebuilding this State would re-run route builders and thrash
    // ShortcutSurfaceScope registration.
    _model = initialModel();
    _scrollController.autoScrollToBottom = true;
    if (_model.inputText.isNotEmpty) {
      _promptController.text = _model.inputText;
    }
    _currentThemeName = currentOpenCodeThemeName();
    _loadThemeOptions();
    _scannerController = SpinnerController(tui.Spinners.scanner());
    _scannerController.stop();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadThemeOptions() async {
    final options = await discoverOpenCodeThemeNames();
    if (!mounted) return;
    setState(() {
      _themeOptions = options;
    });
  }

  Future<void> _applyTheme(String themeName) async {
    final ok = await applyOpenCodeThemeOverride(themeName);
    if (!mounted) return;
    if (!ok) return;
    setState(() {
      _currentThemeName = currentOpenCodeThemeName();
    });
  }

  void _addUserMessage(String text) {
    if (text.trim().isEmpty) return;

    _promptController.text = '';
    final updatedMessages = List<ChatMessage>.of(_model.messages)
      ..add(ChatMessage.user(text));

    setState(() {
      _model = _model.copyWith(
        route: _model.route,
        messages: updatedMessages,
        inputText: '',
        modelName: _model.modelName,
        providerName: _model.providerName,
        sessionTitle: _model.sessionTitle,
        contextTokens: _model.contextTokens,
        contextPercentage: _model.contextPercentage,
        cost: _model.cost,
        sidebar: _model.sidebar,
        sidebarOpen: _model.sidebarOpen,
        todos: _model.todos,
        modifiedFiles: _model.modifiedFiles,
        mcpServers: _model.mcpServers,
        lspServers: _model.lspServers,
        workingDirectory: _model.workingDirectory,
      );
    });
  }

  void _startScanner() {
    _scannerController.start();
    // Rebuild so session chrome can dim while the scanner runs.
    setState(() {});

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _scannerController.stop();
      setState(() {});
    });
  }

  void _handleSubmit(String text) {
    _addUserMessage(text);
    _startScanner();
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = openCodeTheme();
    final mq = w.MediaQuery.maybeOf(context);
    if (mq != null) {
      _terminalWidth = mq.size.width.toInt();
    }

    // OpenCode pickers sit in a stable overlay host (never remounts routes).
    w.Widget wrapWithChrome(w.Widget content) {
      void dismissOverlay() => _closeOverlay();

      return OpenCodeOverlayHost(
        kind: _overlay,
        onDismiss: dismissOverlay,
        commandPalette: w.CommandPalette(
          open: true,
          title: 'Commands',
          hint: 'Search',
          backdropOpacity: 0.0,
          items: sampleCommands(),
          onDismiss: () {
            dismissOverlay();
            return null;
          },
          onSelect: (item) {
            if (item.label == 'Exit') {
              dismissOverlay();
              return tui.Cmd.quit();
            }
            dismissOverlay();
            switch (item.label) {
              case 'New Session':
              case 'Go to Home':
                _handleAction(AppChord.newSession.id);
              case 'Session List':
                _handleAction(AppChord.sessions.id);
              case 'Toggle Sidebar':
                _handleAction(AppChord.sidebar.id);
              case 'Toggle Theme':
                _handleAction(AppChord.theme.id);
              case 'Go to Session':
                _handleAction(AppChord.status.id);
              case 'Go to Agent Overview':
                _navigator?.pushNamed('/agent-overview');
              case 'Switch Agent':
                _openAgentList();
              case 'Open Diff Review':
                _handleAction(AppChord.review.id);
              case 'Switch Model':
                _handleAction(AppChord.models.id);
              case 'Demo Permission Dock':
                setState(() {
                  _sessionDock = SessionAgentDock.permission;
                });
                _navigator?.pushNamed('/session');
              case 'Demo Question Dock':
                setState(() {
                  _sessionDock = SessionAgentDock.question;
                });
                _navigator?.pushNamed('/session');
              case 'Clear Agent Dock':
                setState(() => _sessionDock = SessionAgentDock.none);
              default:
                break;
            }
            return null;
          },
          // CommandPalette when embedded only needs a stub child.
          child: w.SizedBox.shrink(),
        ),
        sessionList: SessionListDialog(
          sessions: sampleSessions(),
          onDismiss: dismissOverlay,
          onSelect: (session) {
            dismissOverlay();
            setState(() {
              _model = _model.copyWith(sessionTitle: session.title);
            });
            _navigator?.pushNamed('/session');
          },
        ),
        modelList: ModelListDialog(
          models: sampleModels(),
          currentModelName: _model.modelName,
          onDismiss: dismissOverlay,
          onSelect: (model) {
            dismissOverlay();
            setState(() {
              _model = _model.copyWith(
                modelName: model.modelName,
                providerName: model.providerName,
              );
            });
          },
        ),
        themeList: ThemeListDialog(
          themes: _themeOptions,
          currentTheme: _currentThemeName,
          onDismiss: dismissOverlay,
          onSelect: (themeName) {
            dismissOverlay();
            _applyTheme(themeName);
          },
        ),
        agentList: AgentListDialog(
          agents: sampleAgents(),
          currentAgentName: _model.agentName,
          onDismiss: dismissOverlay,
          onSelect: (agent) {
            dismissOverlay();
            setState(() {
              _model = _model.copyWith(agentName: agent.name);
            });
          },
        ),
        child: content,
      );
    }

    final hub = widget.hub;
    final footerHint =
        hub.isSequencePending ? hub.pendingStatusHint : _footerStatusHint;

    final navigator = w.Navigator(
      key: const w.ValueKey('app-navigator'),
      popBehavior: const w.PopBehavior(escapeEnabled: false),
      initialRoute: '/',
      routes: {
        '/': (ctx) {
          _navigator ??= w.Navigator.of(ctx);
          return w.ShortcutSurfaceScope(
            surfaceId: 'home',
            bindings: openCodeHomeBindings(),
            child: HomeView(
              model: _model,
              statusHint: footerHint,
              promptController: _promptController,
              scanner: _scannerController,
              onSubmit: (text) {
                _addUserMessage(text);
                _navigator?.pushNamed('/session');
                _startScanner();
              },
            ),
          );
        },
        '/session': (ctx) => w.ShortcutSurfaceScope(
          surfaceId: 'session',
          bindings: openCodeSessionBindings(),
          child: SessionShell(
            model: _model,
            scrollController: _scrollController,
            promptController: _promptController,
            statusHint: footerHint,
            agentDock: _sessionDock,
            onAgentDockDismiss: () {
              setState(() => _sessionDock = SessionAgentDock.none);
            },
            scanner: _scannerController,
            replayEvents: _recentReplayPresentations,
            replayHistory: _replayHistory,
            onSubmit: _handleSubmit,
            onReplayHistoryModeSelected: (mode) {
              setState(() {
                _replayHistory = _replayHistory.withMode(mode);
              });
              return tui.Cmd.none();
            },
            onReplayHistoryExpandedChanged: (expanded) {
              setState(() {
                _replayHistory = _replayHistory.withExpanded(expanded);
              });
              return tui.Cmd.none();
            },
          ),
        ),
        '/agent-overview': (ctx) => w.ShortcutSurfaceScope(
          surfaceId: 'agent',
          bindings: openCodeAgentBindings(),
          child: AgentOverview(model: _model),
        ),
        '/review': (ctx) => w.ShortcutSurfaceScope(
          surfaceId: 'review',
          bindings: openCodeReviewBindings(),
          child: ReviewScreen(
            workingDirectory: _model.workingDirectory,
          ),
        ),
      },
    );

    // KeymapHubScope sits above the navigator so routes rebuild when a
    // sequence is pending and each route owns a ShortcutSurfaceScope.
    return w.ThemeScope(
      theme: theme,
      child: w.KeymapHubScope(
        hub: hub,
        onAction: (id, surfaceId) => _handleAction(id),
        child: wrapWithChrome(navigator),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.InterruptMsg) {
      return tui.Cmd.quit();
    }

    if (msg is tui.ClipboardSetMsg) {
      final token = ++_copyToastToken;
      setState(() {
        _copyToastMessage = 'Copied to clipboard';
      });
      return tui.Cmd.delayed(
        const Duration(milliseconds: 1600),
        () => _HideCopyToastMsg(token),
      );
    }

    if (msg is _HideCopyToastMsg) {
      if (msg.token == _copyToastToken && _copyToastMessage != null) {
        setState(() {
          _copyToastMessage = null;
        });
      }
      return null;
    }

    if (msg is tui.ReplayEventMsg) {
      final presentation = msg.event.presentation;
      setState(() {
        _footerStatusHint = presentation.statusHint;
        _recentReplayPresentations.insert(0, presentation);
        if (_recentReplayPresentations.length > 5) {
          _recentReplayPresentations.removeRange(
            5,
            _recentReplayPresentations.length,
          );
        }
      });
      return tui.Cmd.none();
    }

    if (msg is tui.KeyMsg) {
      final key = msg.key;

      if (key.isCtrlD) {
        return tui.Cmd.quit();
      }

      if (key.isTab) {
        setState(() {
          _model = _model.copyWith(
            mode: switch (_model.mode) {
              BuildMode.build => .plan,
              BuildMode.plan => .build,
            },
          );
        });
      }

      // ctrl+p / leader chords are handled by KeymapHub surfaces (chords.dart).
      if (key == tui.Keys.ctrl('q') || key == tui.Keys.ctrl('c')) {
        return tui.Cmd.quit();
      }

      if (key.isEnterLike) {
        if (_model.enterBehavior == EnterBehavior.newline && !key.shift) {
          return tui.Cmd.none();
        }

        _handleSubmit(_promptController.text);

        return tui.Cmd.none();
      }
    }
    return null;
  }

  /// Dispatch a resolved keymap action id (leader chord or single).
  void _handleAction(String id) {
    if (id == 'command_list') {
      _toggleOverlay(OpenCodeOverlayKind.commands);
      return;
    }
    if (id == AppChord.sidebar.id) {
      setState(() => _model = _model.toggleSidebar(_terminalWidth));
      return;
    }
    if (id == AppChord.sessions.id) {
      _openOverlay(OpenCodeOverlayKind.sessions);
      return;
    }
    if (id == AppChord.models.id) {
      _openOverlay(OpenCodeOverlayKind.models);
      return;
    }
    if (id == AppChord.theme.id) {
      _openOverlay(OpenCodeOverlayKind.themes);
      return;
    }
    if (id == AppChord.newSession.id) {
      _closeOverlay();
      _navigator?.popUntil((route) => route.settings.name == '/');
      return;
    }
    if (id == AppChord.agents.id) {
      // OpenCode: agent list picker (full overview remains a route).
      _openAgentList();
      return;
    }
    if (id == AppChord.review.id) {
      _closeOverlay();
      _navigator?.pushNamed('/review');
      return;
    }
    if (id == AppChord.status.id) {
      _closeOverlay();
      _navigator?.pushNamed('/session');
    }
  }

  void _openAgentList() => _openOverlay(OpenCodeOverlayKind.agents);

  void _toggleOverlay(OpenCodeOverlayKind kind) {
    if (_overlay == kind) {
      _closeOverlay();
    } else {
      _openOverlay(kind);
    }
  }

  void _openOverlay(OpenCodeOverlayKind kind) {
    if (kind == OpenCodeOverlayKind.none) {
      _closeOverlay();
      return;
    }
    setState(() {
      _overlay = kind;
      _commandPaletteOpen = kind == OpenCodeOverlayKind.commands;
    });
    // Exclusive surface: route leader chords blocked; keys still reach dialogs.
    if (!widget.hub.contains(openCodeOverlaySurfaceId)) {
      widget.hub.push(openCodeOverlaySurface());
    } else {
      widget.hub.activate(openCodeOverlaySurfaceId);
    }
  }

  void _closeOverlay() {
    if (_overlay == OpenCodeOverlayKind.none && !_commandPaletteOpen) return;
    setState(() {
      _overlay = OpenCodeOverlayKind.none;
      _commandPaletteOpen = false;
    });
    if (widget.hub.contains(openCodeOverlaySurfaceId)) {
      widget.hub.pop(openCodeOverlaySurfaceId);
    }
  }
}
