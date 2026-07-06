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
import 'data.dart';
import 'models/chat_model.dart';
import 'models/message.dart';
import 'screens/agent_overview.dart';
import 'screens/home.dart';
import 'screens/session.dart';
import 'theme.dart';
import 'widgets/model_list_dialog.dart';
import 'widgets/session_list_dialog.dart';
import 'widgets/state/build_mode.dart';
import 'widgets/state/open_code_ui_state.dart';
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

  // UI state
  bool _chordActive = false;

  @override
  void initState() {
    super.initState();
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
    _chordActive = true;
    _scannerController.start();

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _scannerController.stop();
      setState(() {
        _chordActive = false;
      });
    });
  }

  void _handleSubmit(String text) {
    _addUserMessage(text);
    _startScanner();
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = openCodeTheme();

    // Helper to wrap content with theme list + session list + command palette
    w.Widget wrapWithOverlays(w.Widget content) {
      return w.Stack(
        fit: w.StackFit.expand,
        children: [
          content,
          if (_commandPaletteOpen)
            w.CommandPalette(
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
                    final n = _navigator;
                    if (n != null) {
                      SessionListDialog.show(
                        n,
                        sessions: sampleSessions(),
                        onSelect: (session) {
                          setState(() {
                            _model = ChatModel(
                              route: _model.route,
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
                          });
                          _navigator?.pushNamed('/session');
                        },
                      );
                    }
                  }
                  if (item.label == 'Toggle Theme') {
                    final n = _navigator;
                    if (n != null) {
                      ThemeListDialog.show(
                        n,
                        themes: _themeOptions,
                        currentTheme: _currentThemeName,
                        onSelect: (themeName) {
                          _applyTheme(themeName);
                        },
                      );
                    }
                  }
                  if (item.label == 'Go to Home') {
                    _navigator?.popUntil((route) => route.settings.name == '/');
                  }
                  if (item.label == 'Go to Session') {
                    _navigator?.pushNamed('/session');
                  }
                  if (item.label == 'Go to Agent Overview') {
                    _navigator?.pushNamed('/agent-overview');
                  }
                });
                return null;
              },
              child: content,
            ),
        ],
      );
    }

    final navigator = w.Navigator(
      key: const w.ValueKey('app-navigator'),
      popBehavior: const w.PopBehavior(escapeEnabled: false),
      initialRoute: '/',
      routes: {
        '/': (ctx) {
          _navigator ??= w.Navigator.of(ctx);
          return HomeView(
            model: _model,
            statusHint: _footerStatusHint,
            promptController: _promptController,
            scanner: _scannerController,
            onSubmit: (text) {
              _addUserMessage(text);
              _navigator?.pushNamed('/session');
              _startScanner();
            },
          );
        },
        '/session': (ctx) => SessionShell(
          model: _model,
          scrollController: _scrollController,
          promptController: _promptController,
          statusHint: _footerStatusHint,
          chordActive: _chordActive,
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
        '/agent-overview': (ctx) => AgentOverview(model: _model),
      },
    );

    return w.ThemeScope(theme: theme, child: wrapWithOverlays(navigator));
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.InterruptMsg) {
      return tui.Cmd.quit();
    }

    switch (msg) {
      case tui.KeyChordResolvedMsg(:final id):
        setState(() {
          _chordActive = false;

          if (id == AppChord.sidebar.id) {
            _model = _model.copyWith(sidebarOpen: !_model.sidebarOpen);
          }
          if (id == AppChord.models.id) {
            final n = _navigator;
            if (n != null) {
              ModelListDialog.show(
                n,
                models: sampleModels(),
                currentModelName: _model.modelName,
                onSelect: (model) {
                  setState(() {
                    _model = _model.copyWith(
                      modelName: model.modelName,
                      providerName: model.providerName,
                    );
                  });
                },
              );
            }
          }
        });

        break;

      // Prefix detected: show "waiting for second key"
      case tui.KeyChordPrefixMsg():
        setState(() {
          _chordActive = true;
        });
        break;

      // Cancelled (timeout or unmatched key)
      case tui.KeyChordCancelledMsg():
        setState(() {
          _chordActive = false;
        });
        break;
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

      // ctrl+p to toggle command palette
      if (key == tui.Keys.ctrl('p')) {
        setState(() => _commandPaletteOpen = !_commandPaletteOpen);
        return tui.Cmd.none();
      }
      // ctr\l+p to toggle command palette
      if (key == tui.Keys.ctrl('q')) {
        return tui.Cmd.quit();
      }
      // ctr\l+p to toggle command palette
      if (key == tui.Keys.ctrl('c')) {
        return tui.Cmd.quit();
      }

      // ctrl+l to open session list dialog
      if (key == tui.Keys.ctrl('l')) {
        final n = _navigator;
        if (n != null) {
          SessionListDialog.show(
            n,
            sessions: sampleSessions(),
            onSelect: (session) {
              setState(() {
                _model = ChatModel(
                  route: _model.route,
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
              });
              _navigator?.pushNamed('/session');
            },
          );
        }
        return tui.Cmd.none();
      }

      // ctrl+t to open theme list dialog
      if (key == tui.Keys.ctrl('t')) {
        final n = _navigator;
        if (n != null) {
          ThemeListDialog.show(
            n,
            themes: _themeOptions,
            currentTheme: _currentThemeName,
            onSelect: (themeName) {
              _applyTheme(themeName);
            },
          );
        }
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
}
