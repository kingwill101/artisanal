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
import 'data.dart';
import 'models/chat_model.dart';
import 'screens/home.dart';
import 'screens/session.dart';
import 'theme.dart';
import 'widgets/copy_toast.dart';
import 'widgets/session_list_dialog.dart';
import 'widgets/theme_list_dialog.dart';


// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class OpenCodeApp extends w.StatefulWidget {
  OpenCodeApp({super.key});

  @override
  w.State createState() => _OpenCodeAppState();
}

class _HideCopyToastMsg extends tui.Msg {
  const _HideCopyToastMsg(this.token);
  final int token;
}

class _OpenCodeAppState extends w.State<OpenCodeApp> {
  late ChatModel _model;
  final _scrollController = w.WidgetScrollController();
  final _promptController = w.TextFieldController();
  bool _commandPaletteOpen = false;
  bool _sessionListOpen = false;
  bool _themeListOpen = false;
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

  @override
  void initState() {
    super.initState();
    _model = initialModel();
    if (_model.inputText.isNotEmpty) {
      _promptController.text = _model.inputText;
    }
    _currentThemeName = currentOpenCodeThemeName();
    _loadThemeOptions();
  }

  @override
  void dispose() {
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
    if (!ok) {
      setState(() {
        _themeListOpen = false;
      });
      return;
    }
    setState(() {
      _currentThemeName = currentOpenCodeThemeName();
      _themeListOpen = false;
    });
  }

  bool _isCtrlCShortcut(tui.Key key) {
    if (!key.ctrl || key.alt || key.meta || key.hyper || key.superKey) {
      return false;
    }
    if (key.runes.isEmpty) return false;
    if (key.runes.length == 1 && key.runes.first == 0x03) {
      return true;
    }
    final char = key.char;
    return char != null && char.toLowerCase() == 'c';
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.InterruptMsg) {
      return tui.Cmd.quit();
    }
    if (msg is tui.KeyMsg && _isCtrlCShortcut(msg.key)) {
      return tui.Cmd.quit();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = openCodeTheme();
    setOpenCodeRouteBackground(
      _model.route == AppRoute.home ? OC.background : OC.background,
    );

    // Helper to wrap content with theme list + session list + command palette
    w.Widget wrapWithOverlays(w.Widget content) {
      final overlays = ThemeListDialog(
        open: _themeListOpen,
        themes: _themeOptions,
        currentTheme: _currentThemeName,
        onDismiss: () {
          setState(() => _themeListOpen = false);
          return null;
        },
        onSelect: (themeName) {
          _applyTheme(themeName);
        },
        child: SessionListDialog(
          open: _sessionListOpen,
          sessions: sampleSessions(),
          onDismiss: () {
            setState(() => _sessionListOpen = false);
            return null;
          },
          onSelect: (session) {
            setState(() {
              _sessionListOpen = false;
              // Navigate to the selected session (or stay on current)
              if (!session.isCurrent) {
                _model = ChatModel(
                  route: AppRoute.session,
                  messages: _model.messages,
                  inputText: _promptController.text,
                  modelName: _model.modelName,
                  providerName: _model.providerName,
                  agentName: _model.agentName,
                  sessionTitle: session.title,
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
              } else {
                _model = ChatModel(
                  route: AppRoute.session,
                  messages: _model.messages,
                  inputText: _promptController.text,
                  modelName: _model.modelName,
                  providerName: _model.providerName,
                  agentName: _model.agentName,
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
              }
            });
          },
          child: w.CommandPalette(
            open: _commandPaletteOpen,
            title: 'Commands',
            hint: 'Search',
            backdropOpacity: 0.7,
            items: sampleCommands(),
            onDismiss: () {
              setState(() => _commandPaletteOpen = false);
              return null;
            },
            onSelect: (item) {
              if (item.label == 'Exit') {
                setState(() {
                  _commandPaletteOpen = false;
                });
                return tui.Cmd.quit();
              }
              setState(() {
                _commandPaletteOpen = false;
                if (item.label == 'Session List') {
                  _sessionListOpen = true;
                }
                if (item.label == 'Toggle Theme') {
                  _themeListOpen = true;
                }
              });
              return null;
            },
            child: content,
          ),
        ),
      );

      return w.Stack(
        fit: w.StackFit.expand,
        children: [
          overlays,
          if (_copyToastMessage != null)
            w.Positioned(
              top: 1,
              left: 0,
              right: 0,
              child: w.IgnorePointer(
                child: w.Center(
                  child: w.ConstrainedBox(
                    constraints: w.BoxConstraints(maxWidth: 38),
                    child: CopyToast(message: _copyToastMessage!),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Home view — landing screen
    if (_model.route == AppRoute.home) {
      return w.ThemeScope(
        theme: theme,
        child: wrapWithOverlays(
          HomeView(
            model: _model,
            statusHint: _footerStatusHint,
            promptController: _promptController,
            onSubmit: (text) {
              setState(() {
                _model = ChatModel(
                  route: AppRoute.session,
                  messages: _model.messages,
                  inputText: text,
                  modelName: _model.modelName,
                  providerName: _model.providerName,
                  agentName: _model.agentName,
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
            },
          ),
        ),
      );
    }

    final mainLayout = SessionShell(
      model: _model,
      scrollController: _scrollController,
      promptController: _promptController,
      statusHint: _footerStatusHint,
      replayEvents: _recentReplayPresentations,
      replayHistory: _replayHistory,
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
    );

    // Wrap with theme + session list + command palette
    return w.ThemeScope(theme: theme, child: wrapWithOverlays(mainLayout));
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
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

      // ctrl+p to toggle command palette
      if (key == tui.Keys.ctrl('p')) {
        setState(() => _commandPaletteOpen = !_commandPaletteOpen);
        return tui.Cmd.none();
      }

      // ctrl+l to toggle session list dialog
      if (key == tui.Keys.ctrl('l')) {
        setState(() => _sessionListOpen = !_sessionListOpen);
        return tui.Cmd.none();
      }

      // ctrl+t to toggle theme list dialog
      if (key == tui.Keys.ctrl('t')) {
        setState(() => _themeListOpen = !_themeListOpen);
        return tui.Cmd.none();
      }

      // ctrl+b to toggle sidebar
      if (key == tui.Keys.ctrl('b')) {
        setState(() {
          _model = ChatModel(
            route: _model.route,
            messages: _model.messages,
            inputText: _promptController.text,
            modelName: _model.modelName,
            providerName: _model.providerName,
            agentName: _model.agentName,
            sessionTitle: _model.sessionTitle,
            contextTokens: _model.contextTokens,
            contextPercentage: _model.contextPercentage,
            cost: _model.cost,
            sidebar: _model.sidebar,
            sidebarOpen: !_model.sidebarOpen,
            todos: _model.todos,
            modifiedFiles: _model.modifiedFiles,
            mcpServers: _model.mcpServers,
            lspServers: _model.lspServers,
            workingDirectory: _model.workingDirectory,
          );
        });
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

