import 'package:artisanal/args.dart' show CommandRunner;
import 'package:artisanal/tui.dart' show HarnessCommandsMixin;
import 'package:test/test.dart';

void main() {
  test(
    'HarnessCommandsMixin adds replay and profile commands lazily',
    () async {
      final runner = _TestRunner();

      await runner.run(<String>['--help']);

      expect(runner.commands, contains('replay'));
      expect(runner.commands, contains('profile'));
    },
  );
}

final class _TestRunner extends CommandRunner<void> with HarnessCommandsMixin {
  _TestRunner() : super('test', 'test runner');

  @override
  String get harnessEntrypointPath => 'bin/test.dart';
}
