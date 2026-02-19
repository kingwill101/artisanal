import 'dart:io';
import 'dart:math';
import 'package:ultraviolet/ultraviolet.dart';

const _headerHeight = 3;
const _footerHeight = 2;
const _ansiReset = '\x1b[0m';
const _ansiBold = '\x1b[1m';
const _ansiDim = '\x1b[2m';

String _ansiFg256(int color) => '\x1b[38;5;${color}m';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/uv/bat.dart <file>');
    return;
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!await file.exists()) {
    print('File not found: $filePath');
    return;
  }

  final content = await file.readAsString();
  final lines = content.split('\n');

  final terminal = Terminal();
  await terminal.start();
  terminal.setScrollOptim(false);
  terminal.enterAltScreen();
  terminal.hideCursor();

  final size = await terminal.getSize();
  int width = size.width;
  int height = size.height;

  final lineNumWidth = lines.length.toString().length;
  int scrollOffset = 0;

  String styled(
    String text, {
    String color = '',
    bool bold = false,
    bool dim = false,
  }) {
    return [
      color,
      if (bold) _ansiBold,
      if (dim) _ansiDim,
      text,
      _ansiReset,
    ].join();
  }

  String truncate(String text, int maxWidth) {
    if (maxWidth <= 0 || text.isEmpty) return '';
    if (text.length <= maxWidth) return text;
    if (maxWidth <= 3) return text.substring(0, maxWidth);
    return '${text.substring(0, maxWidth - 3)}...';
  }

  int maxScroll(int contentHeight) {
    if (contentHeight <= 0) return 0;
    return max(0, lines.length - contentHeight);
  }

  void display() {
    terminal.clear();
    terminal.clearScreen();

    final fileName = filePath.split('/').last;
    final gutterWidth = lineNumWidth + 3; // "{line} │ "
    final contentWidth = max(0, width - gutterWidth);
    final leftBorderWidth = lineNumWidth + 1; // "{line} "
    final headerWidth = max(0, width - leftBorderWidth - 1);
    final contentHeight = max(0, height - _headerHeight - _footerHeight);
    final maxScrollOffset = maxScroll(contentHeight);
    if (scrollOffset > maxScrollOffset) {
      scrollOffset = maxScrollOffset;
    }
    final gutterPad = styled(
      ' ' * lineNumWidth,
      color: _ansiFg256(240),
      dim: true,
    );
    final gutterSpacer = styled(' ', color: _ansiFg256(240), dim: true);

    // Header
    final topBorder =
        '${styled('─' * leftBorderWidth, color: _ansiFg256(240), dim: true)}'
        '┬'
        '${styled('─' * headerWidth, color: _ansiFg256(240), dim: true)}';
    final headerText =
        'File: $fileName  '
        'Lines: ${lines.length}';
    final fileLine =
        '$gutterPad$gutterSpacer${styled('│', color: _ansiFg256(240), dim: true)} '
        '${styled(truncate(headerText, contentWidth), color: _ansiFg256(81), bold: true)}';
    final midBorder =
        '${styled('─' * leftBorderWidth, color: _ansiFg256(240), dim: true)}'
        '┼'
        '${styled('─' * headerWidth, color: _ansiFg256(240), dim: true)}';

    StyledString(topBorder).draw(terminal, rect(0, 0, width, 1));
    StyledString(fileLine).draw(terminal, rect(0, 1, width, 1));
    StyledString(midBorder).draw(terminal, rect(0, 2, width, 1));

    // Content
    int visibleLines = max(0, min(contentHeight, lines.length - scrollOffset));
    for (int i = 0; i < visibleLines; i++) {
      int lineIndex = scrollOffset + i;
      final lineNumText = (lineIndex + 1).toString();
      final lineNum = styled(
        lineNumText.padLeft(lineNumWidth),
        color: _ansiFg256(244),
        dim: true,
      );
      final lineText =
          '$lineNum'
          '$gutterSpacer${styled('│', color: _ansiFg256(240), dim: true)} '
          '${truncate(lines[lineIndex], contentWidth)}';
      final ss = StyledString(lineText);
      ss.draw(terminal, rect(0, 3 + i, width, 1));
    }

    // Status line
    String status;
    if (lines.isEmpty) {
      status = '0/0';
    } else if (scrollOffset + visibleLines >= lines.length) {
      status = 'END';
    } else {
      int startLine = scrollOffset + 1;
      int endLine = scrollOffset + visibleLines;
      final percent = ((endLine / lines.length) * 100).floor();
      status = '$startLine-$endLine/${lines.length} ($percent%)';
    }
    final statusLine =
        '$gutterPad$gutterSpacer${styled('│', color: _ansiFg256(240), dim: true)} '
        '${styled(truncate(status, contentWidth), color: _ansiFg256(247), bold: true)}';
    final helpLine =
        '$gutterPad$gutterSpacer${styled('│', color: _ansiFg256(240), dim: true)} '
        '${styled(truncate('q: quit  Up/Down: scroll  PgUp/PgDn: page', contentWidth), color: _ansiFg256(245), dim: true)}';

    StyledString(statusLine).draw(terminal, rect(0, height - 2, width, 1));
    StyledString(helpLine).draw(terminal, rect(0, height - 1, width, 1));

    terminal.draw();
  }

  display();

  await for (final event in terminal.events) {
    if (event is KeyEvent) {
      if (event.matchString('q', 'ctrl+c')) {
        break;
      } else if (event.matchString('up')) {
        if (scrollOffset > 0) {
          scrollOffset--;
          display();
        }
      } else if (event.matchString('down')) {
        final contentHeight = max(0, height - _headerHeight - _footerHeight);
        if (scrollOffset < maxScroll(contentHeight)) {
          scrollOffset++;
          display();
        }
      } else if (event.matchString('page_up')) {
        final contentHeight = max(0, height - _headerHeight - _footerHeight);
        scrollOffset = max(0, scrollOffset - contentHeight);
        display();
      } else if (event.matchString('page_down')) {
        final contentHeight = max(0, height - _headerHeight - _footerHeight);
        scrollOffset = min(
          maxScroll(contentHeight),
          scrollOffset + contentHeight,
        );
        display();
      } else if (event.matchString('home')) {
        scrollOffset = 0;
        display();
      } else if (event.matchString('end')) {
        final contentHeight = max(0, height - _headerHeight - _footerHeight);
        scrollOffset = maxScroll(contentHeight);
        display();
      }
    } else if (event is WindowSizeEvent) {
      width = event.width;
      height = event.height;
      terminal.resize(width, height);
      // Adjust scrollOffset if necessary
      final contentHeight = max(0, height - _headerHeight - _footerHeight);
      if (scrollOffset > maxScroll(contentHeight)) {
        scrollOffset = maxScroll(contentHeight);
      }
      display();
    }
  }

  await terminal.stop();
}
