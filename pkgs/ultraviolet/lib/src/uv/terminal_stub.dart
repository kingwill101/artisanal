import 'dart:async';

final _inputController = StreamController<List<int>>.broadcast();
final StringBuffer _outputBuffer = StringBuffer();

Stream<List<int>> get defaultInput => _inputController.stream;

StringSink get defaultOutput => _outputBuffer;

List<String> get defaultEnv => const [];

bool get defaultIsWindows => false;

bool get defaultIsTty => false;

StreamSubscription<Object?>? watchSigint(void Function() handler) => null;

void exitProcess() {}

bool isStdin(Stream<List<int>> input) => false;

bool get stdinHasTerminal => false;

void enterRawMode() {}

void exitRawMode() {}
