import 'package:artisanal/uv.dart';

void main() async {
  final terminal = Terminal();

  final size = await terminal.getSize();
  int width = size.width;
  int height = size.height;

  await terminal.start();

  bool altScreen = false;
  int frameHeight = 2;
  bool cursorHidden = false;

  void updateViewport(bool isAlt) {
    if (isAlt) {
      frameHeight = height;
      terminal.enterAltScreen();
    } else {
      frameHeight = 2;
      terminal.exitAltScreen();
    }
    terminal.resize(width, frameHeight);
  }

  const help = 'Press space to toggle screen mode or ctrl+c to exit.';

  void display() {
    updateViewport(altScreen);
    String str;
    if (altScreen) {
      str = 'This is using alternate screen mode.\n$help';
    } else {
      str = 'This is using inline mode.\n$help';
    }

    final ss = StyledString(str);
    terminal.clear();
    ss.draw(terminal, terminal.bounds());
    terminal.draw();
  }

  try {
    display();

    await for (final event in terminal.events) {
      if (event is WindowSizeEvent) {
        width = event.width;
        height = event.height;
        terminal.clearScreen();
        display();
      } else if (event is KeyEvent) {
        if (event.matchString('ctrl+c', 'q')) {
          altScreen = false;
          break;
        } else if (event.matchString(' ')) {
          altScreen = !altScreen;
        } else {
          if (cursorHidden) {
            terminal.hideCursor();
          } else {
            terminal.showCursor();
          }
          cursorHidden = !cursorHidden;
        }
      }
      display();
    }
  } finally {
    await terminal.stop();
  }
}
