import 'package:artisanal/args.dart';

class HelloCommand extends Command {
  @override
  String get name => 'hello';
  
  @override
  String get description => 'Say hello';

  @override
  void run() {
    io.success('Hello, world!');
  }
}

void main(List<String> args) {
  final runner = CommandRunner('my-cli', 'A great CLI');
  runner.addCommand(HelloCommand());
  runner.run(args);
}