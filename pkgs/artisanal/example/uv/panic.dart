import 'package:artisanal/uv.dart';
import 'dart:async';

void main() async {
  final terminal = Terminal();

  await terminal.start();
  terminal.exitAltScreen();

  var counter = 5;
  Timer? timer;

  void display() {
    final view =
        'Panicking after $counter seconds...\nPress "q" or "Ctrl+C" to exit.';
    final ss = StyledString(view);
    terminal.clear();
    ss.draw(terminal, terminal.bounds());
    terminal.draw();
  }

  timer = Timer.periodic(const Duration(seconds: 1), (t) {
    counter--;
    if (counter < 0) {
      t.cancel();
      throw Exception("Time's up!");
    }
    display();
  });

  try {
    display();

    await for (final event in terminal.events) {
      if (event is KeyEvent) {
        if (event.matchString('q', 'ctrl+c')) {
          break;
        }
      }
      display();
    }
  } catch (e, stack) {
    await terminal.stop();
    print('\r\nRecovered from error: $e');
    print(stack);
    return;
  } finally {
    timer.cancel();
    await terminal.stop();
  }
}
