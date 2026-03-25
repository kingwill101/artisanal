import 'dart:async';
import 'package:artisanal/artisanal.dart';

void main() async {
  final customTheme = OutputTheme(
    info: AdaptiveColor(
      light: BasicColor('#ff00ff'),
      dark: BasicColor('#ff00ff'),
    ), // Magenta
    success: AdaptiveColor(
      light: BasicColor('#00ffff'),
      dark: BasicColor('#00ffff'),
    ), // Cyan
  );

  final console = Console(outputTheme: customTheme);

  console.title('Theme Integration Test');

  console.info('This should be magenta');
  console.success('This should be cyan');

  await console.task(
    'Task status test',
    run: () async {
      await Future.delayed(Duration(seconds: 1));
      return TaskResult.success;
    },
  );

  await console.steps(
    title: 'Steps test',
    steps: [
      (
        'Magenta step',
        () async => await Future.delayed(Duration(milliseconds: 500)),
      ),
      (
        'Cyan success',
        () async => await Future.delayed(Duration(milliseconds: 500)),
      ),
    ],
  );

  console.section('UVConsole Test');

  await console.spin(
    'UV Spinner (Magenta)',
    run: () async => await Future.delayed(Duration(seconds: 1)),
  );

  await console.progress(
    'UV Progress (Magenta)',
    run: (setProgress) async {
      for (var i = 0; i <= 10; i++) {
        await Future.delayed(Duration(milliseconds: 100));
        setProgress(i / 10);
      }
    },
  );

  console.section('Components Test');
  console.components.info('Info Title', 'This should have magenta title');
  console.components.success('Success Title', 'This should have cyan title');
  console.components.warn(
    'Warning Title',
    'This should have default warning color (orange/yellow)',
  );
  console.components.alert('Alert Message (Warning color)');
  console.components.bulletList(['Item 1', 'Item 2']);

  console.writeln('\nTest complete.');
}
