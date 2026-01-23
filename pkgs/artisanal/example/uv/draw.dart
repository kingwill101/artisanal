import 'package:artisanal/uv.dart';

void main() async {
  final terminal = Terminal();

  await terminal.start();
  terminal.enableMouse();
  terminal.enableFocusReporting();

  final size = await terminal.getSize();
  int width = size.width;
  int height = size.height;

  const help = '''Welcome to Draw Example!

Use the mouse to draw on the screen.
Press ctrl+c to exit.
Press esc to clear the screen.
Press alt+esc to reset the pen character, color, and the screen.
Press 0-9 to set the foreground color.
Press any other key to set the pen character.
Press ctrl+h for this help message.

Press any key to continue...''';

  final helpComp = StyledString(help);
  final helpArea = helpComp.bounds();
  final helpW = helpArea.width;
  final helpH = helpArea.height;

  Buffer? prevHelpBuf;
  bool showingHelp = true;

  void displayHelp(bool show) {
    final midX = (width / 2).toInt();
    final midY = (height / 2).toInt();
    final x = midX - (helpW / 2).toInt();
    final y = midY - (helpH / 2).toInt();
    final midArea = rect(x, y, helpW, helpH);

    if (show) {
      prevHelpBuf = terminal.cloneArea(midArea);
      helpComp.draw(terminal, midArea);
    } else if (prevHelpBuf != null) {
      prevHelpBuf!.draw(terminal, midArea);
    }
    terminal.draw();
  }

  void clearScreen() {
    terminal.clear();
    terminal.draw();
  }

  displayHelp(showingHelp);

  const defaultChar = '█';
  var pen = Cell(content: defaultChar);

  void draw(MouseEvent ev) {
    final m = ev.mouse();
    final cur = terminal.cellAt(m.x, m.y);
    if (cur == null) return;

    terminal.setCell(m.x, m.y, pen);
    terminal.draw();
  }

  try {
    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        width = event.width;
        height = event.height;
        terminal.resize(width, height);
        terminal.clearScreen();
        if (showingHelp) displayHelp(true);
      } else if (event is KeyEvent) {
        if (showingHelp) {
          showingHelp = false;
          displayHelp(false);
          continue;
        }

        if (event.matchString('ctrl+c', 'q')) {
          break;
        } else if (event.matchString('esc')) {
          clearScreen();
        } else if (event.matchString('alt+esc')) {
          pen = Cell(content: defaultChar);
          clearScreen();
        } else if (event.matchString('ctrl+h')) {
          showingHelp = true;
          displayHelp(true);
        } else if (RegExp(r'^[0-9]$').hasMatch(event.key().text)) {
          final colorIdx = int.parse(event.key().text);
          // Simple color mapping for 0-9
          final colors = [
            UvColor.rgb(0, 0, 0), // Black
            UvColor.rgb(255, 0, 0), // Red
            UvColor.rgb(0, 255, 0), // Green
            UvColor.rgb(255, 255, 0), // Yellow
            UvColor.rgb(0, 0, 255), // Blue
            UvColor.rgb(255, 0, 255), // Magenta
            UvColor.rgb(0, 255, 255), // Cyan
            UvColor.rgb(255, 255, 255), // White
            UvColor.rgb(128, 128, 128), // Gray
            UvColor.rgb(255, 128, 0), // Orange
          ];
          pen = Cell(
            content: pen.content,
            style: UvStyle(fg: colors[colorIdx]),
          );
        } else if (event.key().text.length == 1) {
          pen = Cell(content: event.key().text, style: pen.style);
        }
      } else if (event is MouseEvent) {
        if (showingHelp) continue;
        // In Go example, it checks for button press.
        // Here we'll just draw on any mouse event if it's a click or motion with button down.
        // But for simplicity, let's just draw on click.
        if (event is MouseClickEvent || event is MouseMotionEvent) {
          draw(event);
        }
      }
    }
  } finally {
    await terminal.stop();
  }
}
