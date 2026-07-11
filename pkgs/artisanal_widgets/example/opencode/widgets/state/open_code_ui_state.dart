/// Reactive UI state for the OpenCode example.
library;

import 'package:artisanal_widgets/widgets.dart' show ChangeNotifier;

import 'build_mode.dart';

/// Controls how Enter behaves in the prompt input.
enum EnterBehavior {
  /// Enter sends the message, Shift+Enter inserts a newline.
  send,

  /// Enter inserts a newline (default text-area behavior).
  newline,
}

/// App-wide UI state managed via ChangeNotifier.
///
/// Owns all transient UI concerns: dialog visibility, chord activity,
/// mode, sidebar, toast messages, and theme options. Domain data
/// (messages, sessions, model info) lives in [ChatModel].
class OpenCodeUIState extends ChangeNotifier {
  bool _chordActive = false;
  BuildMode _mode = BuildMode.build;
  bool _sidebarVisible = true;
  bool _commandPaletteOpen = false;
  bool _sessionListOpen = false;
  bool _themeListOpen = false;
  bool _modelListOpen = false;
  String? _copyToastMessage;
  String _footerStatusHint = '/status';
  String _currentThemeName = '';
  List<String> _themeOptions = const [];
  String? _scannerFrame;
  EnterBehavior _enterBehavior = EnterBehavior.send;

  // ── Getters ──────────────────────────────────────────────────────────

  bool get chordActive => _chordActive;
  BuildMode get mode => _mode;
  bool get sidebarVisible => _sidebarVisible;
  bool get commandPaletteOpen => _commandPaletteOpen;
  bool get sessionListOpen => _sessionListOpen;
  bool get themeListOpen => _themeListOpen;
  bool get modelListOpen => _modelListOpen;
  String? get copyToastMessage => _copyToastMessage;
  String get footerStatusHint => _footerStatusHint;
  String get currentThemeName => _currentThemeName;
  List<String> get themeOptions => List.unmodifiable(_themeOptions);
  String? get scannerFrame => _scannerFrame;
  EnterBehavior get enterBehavior => _enterBehavior;

  // ── Chord state ──────────────────────────────────────────────────────

  void setChordActive(bool value) {
    if (_chordActive == value) return;
    _chordActive = value;
    notifyListeners();
  }

  // ── Mode ─────────────────────────────────────────────────────────────

  void cycleMode() {
    final values = BuildMode.values;
    _mode = values[(_mode.index + 1) % values.length];
    notifyListeners();
  }

  // ── Sidebar ──────────────────────────────────────────────────────────

  void toggleSidebar() {
    _sidebarVisible = !_sidebarVisible;
    notifyListeners();
  }

  // ── Dialog open/close with mutual exclusion ──────────────────────────

  void toggleCommandPalette() {
    _commandPaletteOpen = !_commandPaletteOpen;
    if (_commandPaletteOpen) _closeAllExcept('command');
    notifyListeners();
  }

  void toggleSessionList() {
    _sessionListOpen = !_sessionListOpen;
    if (_sessionListOpen) _closeAllExcept('session');
    notifyListeners();
  }

  void toggleThemeList() {
    _themeListOpen = !_themeListOpen;
    if (_themeListOpen) _closeAllExcept('theme');
    notifyListeners();
  }

  void toggleModelList() {
    _modelListOpen = !_modelListOpen;
    if (_modelListOpen) _closeAllExcept('model');
    notifyListeners();
  }

  void openThemeList() {
    _closeAllExcept('theme');
    _themeListOpen = true;
    notifyListeners();
  }

  void openModelList() {
    _closeAllExcept('model');
    _modelListOpen = true;
    notifyListeners();
  }

  void openSessionList() {
    _closeAllExcept('session');
    _sessionListOpen = true;
    notifyListeners();
  }

  void dismissAllDialogs() {
    _commandPaletteOpen = false;
    _sessionListOpen = false;
    _themeListOpen = false;
    _modelListOpen = false;
    notifyListeners();
  }

  void _closeAllExcept(String keep) {
    if (keep != 'command') _commandPaletteOpen = false;
    if (keep != 'session') _sessionListOpen = false;
    if (keep != 'theme') _themeListOpen = false;
    if (keep != 'model') _modelListOpen = false;
  }

  // ── Toast ────────────────────────────────────────────────────────────

  void showToast(String message) {
    _copyToastMessage = message;
    notifyListeners();
  }

  void dismissToast() {
    if (_copyToastMessage == null) return;
    _copyToastMessage = null;
    notifyListeners();
  }

  // ── Theme ────────────────────────────────────────────────────────────

  void setThemeOptions(List<String> options) {
    _themeOptions = List.of(options);
    notifyListeners();
  }

  void setCurrentThemeName(String name) {
    _currentThemeName = name;
    notifyListeners();
  }

  // ── Status hint ──────────────────────────────────────────────────────

  void setStatusHint(String hint) {
    _footerStatusHint = hint;
    notifyListeners();
  }

  // ── Scanner ─────────────────────────────────────────────────────────

  void setScannerFrame(String? frame) {
    _scannerFrame = frame;
    notifyListeners();
  }

  void setEnterBehavior(EnterBehavior behavior) {
    _enterBehavior = behavior;
    notifyListeners();
  }
}
