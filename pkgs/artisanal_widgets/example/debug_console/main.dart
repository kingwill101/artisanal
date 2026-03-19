import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final controller = w.DebugConsoleController(initiallyVisible: true);
  final shell = app.ArtisanalApp(
    title: 'Debug Console Showcase',
    debugConsoleController: controller,
    debugConsoleCapturePrint: true,
    debugConsoleCaptureErrors: true,
    home: DebugConsoleShowcaseScreen(),
  );
  await app.runArtisanalApp(shell);
}

class DebugConsoleShowcaseScreen extends w.StatefulWidget {
  DebugConsoleShowcaseScreen({super.key});

  @override
  w.State createState() => _DebugConsoleShowcaseScreenState();
}

class _DebugConsoleShowcaseScreenState
    extends w.State<DebugConsoleShowcaseScreen> {
  int _counter = 0;

  w.DebugConsoleController get _console => w.DebugConsoleScope.of(context);

  @override
  runtime.Cmd? handleInit() {
    _console.info('Debug console ready.');
    _console.debug('Press space to add logs. Press F10 to toggle the pane.');
    print('Captured startup print');
    return null;
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is! runtime.KeyMsg) return null;

    final char = msg.key.char;
    if (char == 'q') return runtime.Cmd.quit();

    if (char == ' ') {
      setState(() => _counter++);
      _console.info('Counter advanced to $_counter');
      return null;
    }

    if (char == 'w') {
      _console.warn('Warning sample at counter=$_counter');
      return null;
    }

    if (char == 'e') {
      Future<void>.microtask(() {
        throw StateError('Captured async error at counter=$_counter');
      });
      return null;
    }

    if (char == 'c') {
      _console.clear();
      _console.debug('Console cleared from app action.');
      return null;
    }

    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final subtle = theme.bodySmall.copy()..foreground(theme.muted);

    return w.Container(
      color: theme.background,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text('Debug Console Showcase', style: theme.titleLarge),
          w.Text(
            'space log | w warn | e error | c clear | F10 toggle console | q quit',
            style: subtle,
          ),
          w.Divider(),
          w.Text('Counter: $_counter', style: theme.titleMedium),
          w.Text(
            'This demo logs through DebugConsoleScope so child widgets can write to the app-shell console without threading callbacks everywhere.',
            style: subtle,
          ),
        ],
      ),
    );
  }
}
