import 'dart:async';

import 'package:artisanal/style.dart' show ColorProfile;
import 'package:artisanal/terminal.dart' show Terminal, RawModeGuard;

/// A minimal mock terminal for widget tests that need a [Program]-level
/// terminal without touching real stdio.
class MockTerminal implements Terminal {
  MockTerminal({this.terminalWidth = 80, this.terminalHeight = 24});

  final int terminalWidth;
  final int terminalHeight;

  final List<String> operations = [];
  final List<String> output = [];
  final StreamController<List<int>> _inputController =
      StreamController<List<int>>.broadcast();

  bool rawModeEnabled = false;
  bool altScreenEnabled = false;
  bool cursorHidden = false;
  bool mouseEnabled = false;
  bool bracketedPasteEnabled = false;
  bool disposed = false;

  @override
  int get width => terminalWidth;

  @override
  int get height => terminalHeight;

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  bool get isTerminal => true;

  @override
  bool get supportsAnsi => true;

  @override
  ColorProfile get colorProfile => ColorProfile.trueColor;

  @override
  Stream<List<int>> get input => _inputController.stream;

  void sendInput(List<int> bytes) {
    _inputController.add(bytes);
  }

  void sendError(Object error) {
    _inputController.addError(error);
  }

  void sendKey(int byte) {
    sendInput([byte]);
  }

  @override
  void write(String data) {
    output.add(data);
    operations.add('write: $data');
  }

  @override
  void writeln([String data = '']) {
    output.add('$data\n');
    operations.add('writeln: $data');
  }

  @override
  Future<void> flush() async {
    operations.add('flush');
  }

  @override
  Future<String?> query(
    String query, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    operations.add('query: $query');
    return null;
  }

  @override
  RawModeGuard enableRawMode() {
    rawModeEnabled = true;
    operations.add('enableRawMode');
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    rawModeEnabled = false;
    operations.add('disableRawMode');
  }

  @override
  bool get isRawMode => rawModeEnabled;

  @override
  void enterAltScreen() {
    altScreenEnabled = true;
    operations.add('enterAltScreen');
  }

  @override
  void exitAltScreen() {
    altScreenEnabled = false;
    operations.add('exitAltScreen');
  }

  @override
  bool get isAltScreen => altScreenEnabled;

  @override
  void hideCursor() {
    cursorHidden = true;
    operations.add('hideCursor');
  }

  @override
  void showCursor() {
    cursorHidden = false;
    operations.add('showCursor');
  }

  @override
  void saveCursor() {
    operations.add('saveCursor');
  }

  @override
  void restoreCursor() {
    operations.add('restoreCursor');
  }

  @override
  void moveCursor(int row, int col) {
    operations.add('moveCursor($row, $col)');
  }

  @override
  void cursorHome() {
    operations.add('cursorHome');
  }

  @override
  void cursorUp([int lines = 1]) {
    operations.add('cursorUp($lines)');
  }

  @override
  void cursorDown([int lines = 1]) {
    operations.add('cursorDown($lines)');
  }

  @override
  void cursorRight([int cols = 1]) {
    operations.add('cursorRight($cols)');
  }

  @override
  void cursorLeft([int cols = 1]) {
    operations.add('cursorLeft($cols)');
  }

  @override
  void cursorToColumn(int col) {
    operations.add('cursorToColumn($col)');
  }

  @override
  void enableMouse() {
    mouseEnabled = true;
    operations.add('enableMouse');
  }

  @override
  void enableMouseCellMotion() {
    mouseEnabled = true;
    operations.add('enableMouseCellMotion');
  }

  @override
  void enableMouseAllMotion() {
    mouseEnabled = true;
    operations.add('enableMouseAllMotion');
  }

  @override
  void disableMouse() {
    mouseEnabled = false;
    operations.add('disableMouse');
  }

  @override
  bool get isMouseEnabled => mouseEnabled;

  @override
  void enableBracketedPaste() {
    bracketedPasteEnabled = true;
    operations.add('enableBracketedPaste');
  }

  @override
  void disableBracketedPaste() {
    bracketedPasteEnabled = false;
    operations.add('disableBracketedPaste');
  }

  @override
  bool get isBracketedPasteEnabled => bracketedPasteEnabled;

  @override
  void enableFocusReporting() {
    operations.add('enableFocusReporting');
  }

  @override
  void disableFocusReporting() {
    operations.add('disableFocusReporting');
  }

  @override
  void setTitle(String title) {
    operations.add('setTitle($title)');
  }

  @override
  void setProgressBar(int state, int value) {
    operations.add('setProgressBar($state, $value)');
  }

  @override
  void bell() {
    operations.add('bell');
  }

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      (useTabs: false, useBackspace: true);

  @override
  void clearScreen() {
    operations.add('clearScreen');
  }

  @override
  void clearToEnd() {
    operations.add('clearToEnd');
  }

  @override
  void clearToStart() {
    operations.add('clearToStart');
  }

  @override
  void clearLine() {
    operations.add('clearLine');
  }

  @override
  void clearLineToEnd() {
    operations.add('clearLineToEnd');
  }

  @override
  void clearLineToStart() {
    operations.add('clearLineToStart');
  }

  @override
  void clearPreviousLines(int lines) {
    operations.add('clearPreviousLines($lines)');
  }

  @override
  void scrollUp([int lines = 1]) {
    operations.add('scrollUp($lines)');
  }

  @override
  void scrollDown([int lines = 1]) {
    operations.add('scrollDown($lines)');
  }

  @override
  int readByte() => -1;

  @override
  String? readLine() => null;

  @override
  void dispose() {
    disposed = true;
    operations.add('dispose');
    _inputController.close();
  }

  /// Checks if terminal was properly restored after a panic.
  bool get isProperlyRestored {
    return !rawModeEnabled &&
        !altScreenEnabled &&
        !cursorHidden &&
        !mouseEnabled &&
        !bracketedPasteEnabled;
  }

  /// Clears recorded operations (useful between test phases).
  void clearOperations() {
    operations.clear();
    output.clear();
  }
}
