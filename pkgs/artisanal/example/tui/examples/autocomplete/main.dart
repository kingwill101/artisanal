/// Autocomplete example (fetches Charm repos) ported from Bubble Tea.
library;

import 'dart:convert';
import 'dart:io';

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/src/tui/bubbles/textinput.dart'
    show defaultTextInputStyles;
import 'package:artisanal/tui.dart' as tui;

const _reposUrl = 'https://api.github.com/orgs/charmbracelet/repos';

class GotReposSuccessMsg extends tui.Msg {
  GotReposSuccessMsg(this.repos);
  final List<String> repos;
}

class GotReposErrMsg extends tui.Msg {
  GotReposErrMsg(this.error);
  final Object error;
}

class AutocompleteModel implements tui.Model {
  AutocompleteModel({required this.input, tui.HelpModel? help})
    : help = help ?? tui.HelpModel();

  final tui.TextInputModel input;
  final tui.HelpModel help;

  AutocompleteModel copyWith({tui.TextInputModel? input, tui.HelpModel? help}) {
    return AutocompleteModel(
      input: input ?? this.input,
      help: help ?? this.help,
    );
  }

  @override
  tui.Cmd? init() {
    final focusCmd = input.focus();
    return tui.Cmd.batch([focusCmd ?? tui.Cmd.none(), _getRepos()]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        if (key.type == tui.KeyType.enter ||
            key.type == tui.KeyType.escape ||
            (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63)) {
          return (this, tui.Cmd.quit());
        }

      case GotReposSuccessMsg(:final repos):
        input.suggestions = repos;
        return (this, null);

      case GotReposErrMsg():
        // Ignore errors; keep whatever suggestions exist.
        return (this, null);
    }

    final (newInput, cmd) = input.update(msg);
    return (copyWith(input: newInput), cmd);
  }

  @override
  String view() {
    final helpLine = help.view(_AutoKeyMap());
    return 'Pick a Charm™ repo:\n\n  ${input.view()}\n\n$helpLine\n';
  }
}

class _AutoKeyMap implements tui.KeyMap {
  _AutoKeyMap()
    : bindings = [
        tui.KeyBinding.withHelp(['tab'], 'tab', 'complete'),
        tui.KeyBinding.withHelp(['ctrl+n'], 'ctrl+n', 'next'),
        tui.KeyBinding.withHelp(['ctrl+p'], 'ctrl+p', 'prev'),
        tui.KeyBinding.withHelp(['esc'], 'esc', 'quit'),
      ];

  final List<tui.KeyBinding> bindings;

  @override
  List<tui.KeyBinding> shortHelp() => bindings;

  @override
  List<List<tui.KeyBinding>> fullHelp() => [bindings];
}

tui.Cmd _getRepos() {
  return tui.Cmd(() async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(_reposUrl));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      req.headers.set('X-GitHub-Api-Version', '2022-11-28');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode >= 400) {
        return GotReposErrMsg(
          HttpException('HTTP ${resp.statusCode}', uri: req.uri),
        );
      }
      final decoded = jsonDecode(body) as List<dynamic>;
      final repos = decoded
          .map(
            (e) =>
                e is Map<String, dynamic> ? (e['name'] as String? ?? '') : '',
          )
          .where((s) => s.isNotEmpty)
          .toList();
      return GotReposSuccessMsg(repos);
    } catch (e) {
      return GotReposErrMsg(e);
    }
  });
}

AutocompleteModel _initialModel() {
  final ti = tui.TextInputModel(
    placeholder: 'repository',
    prompt: Style().foreground(const AnsiColor(63)).render('charmbracelet/'),
    styles: defaultTextInputStyles(),
    charLimit: 50,
    width: 20,
    showSuggestions: true,
  );
  return AutocompleteModel(input: ti);
}

Future<void> main() async {
  await tui.runProgram(
    _initialModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
