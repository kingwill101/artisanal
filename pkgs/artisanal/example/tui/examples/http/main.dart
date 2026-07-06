/// HTTP GET status example ported from Bubble Tea.
library;

import 'dart:io' as io;

import 'package:artisanal/tui.dart' as tui;

const _url = 'https://charm.sh/';

class StatusMsg extends tui.Msg {
  const StatusMsg(this.status);
  final int status;
}

class ErrMsg extends tui.Msg {
  const ErrMsg(this.error);
  final Object error;
  @override
  String toString() => error.toString();
}

class HttpModel implements tui.Model {
  const HttpModel({this.status = 0, this.error});

  final int status;
  final Object? error;

  @override
  tui.Cmd? init() => _checkServer();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (rune == 0x71 ||
            key.type == tui.KeyType.escape ||
            (key.ctrl && rune == 0x63)) {
          return (this, tui.Cmd.quit());
        }
        return (this, null);
      case StatusMsg(:final status):
        return (copyWith(status: status), tui.Cmd.quit());
      case ErrMsg(:final error):
        return (copyWith(error: error), null);
    }
    return (this, null);
  }

  HttpModel copyWith({int? status, Object? error}) =>
      HttpModel(status: status ?? this.status, error: error ?? this.error);

  @override
  String view() {
    var s = 'Checking $_url...';
    if (error != null) {
      s += 'something went wrong: $error';
    } else if (status != 0) {
      s += '$status';
    }
    return '$s\n';
  }
}

tui.Cmd _checkServer() {
  return tui.Cmd.perform(
    () async {
      final client = io.HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final request = await client.getUrl(Uri.parse(_url));
        final response = await request.close();
        return response.statusCode;
      } finally {
        client.close(force: true);
      }
    },
    onSuccess: (status) => StatusMsg(status),
    onError: (error, _) => ErrMsg(error),
  );
}

Future<void> main() async {
  await tui.runProgram(
    const HttpModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
