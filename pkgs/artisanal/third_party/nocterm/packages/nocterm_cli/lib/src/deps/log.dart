import 'package:scoped_deps/scoped_deps.dart';

final logProvider = create(Logger.new);

Logger get log => read(logProvider);

class Logger {
  const Logger();

  void call(String message) {
    print(message);
  }
}
