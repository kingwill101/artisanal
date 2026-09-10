import 'package:artisanal/editor_core.dart' show EditorCommandIds;

/// Editing modes owned by the Artisanal Editor application.
enum ModalEditingMode { normal, insert, visual, visualLine, operatorPending }

/// One command invocation emitted by [ModalEditingController].
final class ModalCommandInvocation {
  const ModalCommandInvocation(this.commandId);

  final String commandId;

  @override
  bool operator ==(Object other) =>
      other is ModalCommandInvocation && other.commandId == commandId;

  @override
  int get hashCode => commandId.hashCode;
}

/// Result of resolving an editor key.
final class ModalEditingResult {
  const ModalEditingResult({
    required this.handled,
    required this.mode,
    this.commands = const [],
  });

  final bool handled;
  final ModalEditingMode mode;
  final List<ModalCommandInvocation> commands;
}

/// Application-owned Vim-style key state.
///
/// The Artisanal packages provide commands and editing primitives. This class
/// deliberately stays in the product because mode semantics and key choices
/// are editor policy.
final class ModalEditingController {
  ModalEditingMode _mode = ModalEditingMode.normal;
  String? _prefix;
  String? _operator;
  int _count = 0;
  int _operatorCount = 1;

  ModalEditingMode get mode => _mode;

  String get modeLabel => switch (_mode) {
    ModalEditingMode.normal => 'NORMAL',
    ModalEditingMode.insert => 'INSERT',
    ModalEditingMode.visual => 'VISUAL',
    ModalEditingMode.visualLine => 'V-LINE',
    ModalEditingMode.operatorPending => pendingKeys.toUpperCase(),
  };

  String get pendingKeys {
    final output = StringBuffer();
    if (_operator != null && _operatorCount > 1) {
      output.write(_operatorCount);
    } else if (_count > 0) {
      output.write(_count);
    }
    output.write(_operator ?? '');
    if (_operator != null && _operatorCount > 1 && _count > 0) {
      output.write(_count);
    }
    output.write(_prefix ?? '');
    return output.toString();
  }

  ModalEditingResult handle(String chord) {
    if (chord == 'escape') {
      final wasVisual =
          _mode == ModalEditingMode.visual ||
          _mode == ModalEditingMode.visualLine;
      _reset();
      return _result(
        true,
        commands: wasVisual
            ? const [ModalCommandInvocation(EditorCommandIds.clearSelection)]
            : const [],
      );
    }

    if (chord == 'ctrl+z') {
      return _commands(EditorCommandIds.undo);
    }
    if (chord == 'ctrl+r') {
      return _commands(EditorCommandIds.redo);
    }
    if (_mode == ModalEditingMode.insert) return _result(false);
    if (_isModified(chord)) {
      return _result(false);
    }
    if (_mode == ModalEditingMode.operatorPending) {
      return _handleOperator(chord);
    }
    if (_mode == ModalEditingMode.visual ||
        _mode == ModalEditingMode.visualLine) {
      return _handleVisual(chord);
    }
    return _handleNormal(chord);
  }

  ModalEditingResult _handleNormal(String chord) {
    if (_acceptCount(chord)) return _result(true);

    if (_prefix != null) {
      final prefix = _prefix;
      _prefix = null;
      if (prefix == 'g' && chord == 'g') {
        return _commands(EditorCommandIds.cursorDocumentStart);
      }
      _count = 0;
      return _result(true);
    }
    if (chord == 'g') {
      _prefix = chord;
      return _result(true);
    }
    if (chord == 'd' || chord == 'c') {
      _operator = chord;
      _operatorCount = _takeCount();
      _mode = ModalEditingMode.operatorPending;
      return _result(true);
    }

    final count = _takeCount();
    return switch (chord) {
      'i' => _enterInsert(),
      'a' => _enterInsert(
        commandId: EditorCommandIds.cursorRight,
        repeat: count,
      ),
      'I' => _enterInsert(commandId: EditorCommandIds.cursorLineStart),
      'A' => _enterInsert(commandId: EditorCommandIds.cursorLineEnd),
      'o' => _enterInsertWith([
        const ModalCommandInvocation(EditorCommandIds.cursorLineEnd),
        const ModalCommandInvocation(EditorCommandIds.insertLineBreak),
      ]),
      'O' => _enterInsertWith([
        const ModalCommandInvocation(EditorCommandIds.cursorLineStart),
        const ModalCommandInvocation(EditorCommandIds.insertLineBreak),
        const ModalCommandInvocation(EditorCommandIds.cursorUp),
      ]),
      'v' => _enterVisual(),
      'V' => _enterVisualLine(),
      'h' || 'left' => _commands(EditorCommandIds.cursorLeft, repeat: count),
      'j' || 'down' => _commands(EditorCommandIds.cursorDown, repeat: count),
      'k' || 'up' => _commands(EditorCommandIds.cursorUp, repeat: count),
      'l' || 'right' => _commands(EditorCommandIds.cursorRight, repeat: count),
      'w' || 'e' => _commands(EditorCommandIds.cursorWordRight, repeat: count),
      'b' => _commands(EditorCommandIds.cursorWordLeft, repeat: count),
      '0' || 'home' => _commands(EditorCommandIds.cursorLineStart),
      r'$' || 'end' => _commands(EditorCommandIds.cursorLineEnd),
      'G' => _commands(EditorCommandIds.cursorDocumentEnd),
      'x' || 'delete' => _commands(EditorCommandIds.deleteRight, repeat: count),
      'X' ||
      'backspace' => _commands(EditorCommandIds.deleteLeft, repeat: count),
      'D' => _commands(EditorCommandIds.deleteLineRight),
      'C' => _enterInsert(commandId: EditorCommandIds.deleteLineRight),
      'u' => _commands(EditorCommandIds.undo, repeat: count),
      'J' => _commands(EditorCommandIds.joinLines, repeat: count),
      '>' => _commands(EditorCommandIds.indentLines, repeat: count),
      '<' => _commands(EditorCommandIds.outdentLines, repeat: count),
      _ => _result(true),
    };
  }

  ModalEditingResult _handleVisual(String chord) {
    if (_acceptCount(chord)) return _result(true);
    if (chord == 'v' || chord == 'V') {
      _reset();
      return _commands(EditorCommandIds.clearSelection);
    }

    final count = _takeCount();
    if (chord == 'd' || chord == 'x') {
      _reset();
      return _commands(EditorCommandIds.deleteRight);
    }
    if (chord == 'c') {
      _mode = ModalEditingMode.insert;
      return _commands(EditorCommandIds.deleteRight);
    }

    final commandId = switch (chord) {
      'h' || 'left' => EditorCommandIds.selectLeft,
      'j' || 'down' => EditorCommandIds.selectDown,
      'k' || 'up' => EditorCommandIds.selectUp,
      'l' || 'right' => EditorCommandIds.selectRight,
      'w' || 'e' => EditorCommandIds.selectWordRight,
      'b' => EditorCommandIds.selectWordLeft,
      '0' || 'home' => EditorCommandIds.selectLineStart,
      r'$' || 'end' => EditorCommandIds.selectLineEnd,
      'G' => EditorCommandIds.selectDocumentEnd,
      _ => null,
    };
    if (commandId == null) return _result(true);

    return _result(
      true,
      commands: [
        for (var index = 0; index < count; index++)
          ModalCommandInvocation(commandId),
        if (_mode == ModalEditingMode.visualLine)
          const ModalCommandInvocation(EditorCommandIds.selectLine),
      ],
    );
  }

  ModalEditingResult _handleOperator(String chord) {
    if (_acceptCount(chord)) return _result(true);

    final activeOperator = _operator;
    final repeat = _operatorCount * _takeCount();
    final commandId = switch (chord) {
      'd' when activeOperator == 'd' => EditorCommandIds.deleteLine,
      'c' when activeOperator == 'c' => EditorCommandIds.deleteLine,
      'w' || 'e' => EditorCommandIds.deleteWordRight,
      'b' => EditorCommandIds.deleteWordLeft,
      '0' || 'home' => EditorCommandIds.deleteLineLeft,
      r'$' || 'end' => EditorCommandIds.deleteLineRight,
      _ => null,
    };
    final enterInsert = activeOperator == 'c' && commandId != null;
    _reset(
      mode: enterInsert ? ModalEditingMode.insert : ModalEditingMode.normal,
    );
    return commandId == null
        ? _result(true)
        : _commands(commandId, repeat: repeat);
  }

  ModalEditingResult _enterInsert({String? commandId, int repeat = 1}) {
    _mode = ModalEditingMode.insert;
    return commandId == null
        ? _result(true)
        : _commands(commandId, repeat: repeat);
  }

  ModalEditingResult _enterInsertWith(List<ModalCommandInvocation> commands) {
    _mode = ModalEditingMode.insert;
    return _result(true, commands: commands);
  }

  ModalEditingResult _enterVisual() {
    _mode = ModalEditingMode.visual;
    return _result(true);
  }

  ModalEditingResult _enterVisualLine() {
    _mode = ModalEditingMode.visualLine;
    return _commands(EditorCommandIds.selectLine);
  }

  bool _acceptCount(String chord) {
    if (chord.length != 1) return false;
    final digit = int.tryParse(chord);
    if (digit == null || (digit == 0 && _count == 0)) return false;
    _count = (_count * 10) + digit;
    return true;
  }

  int _takeCount() {
    final result = _count < 1 ? 1 : _count;
    _count = 0;
    return result;
  }

  bool _isModified(String chord) =>
      chord.startsWith('ctrl+') ||
      chord.startsWith('alt+') ||
      chord.startsWith('meta+') ||
      chord.startsWith('super+');

  ModalEditingResult _commands(String commandId, {int repeat = 1}) {
    return _result(
      true,
      commands: [
        for (var index = 0; index < repeat; index++)
          ModalCommandInvocation(commandId),
      ],
    );
  }

  ModalEditingResult _result(
    bool handled, {
    List<ModalCommandInvocation> commands = const [],
  }) {
    return ModalEditingResult(
      handled: handled,
      mode: _mode,
      commands: List.unmodifiable(commands),
    );
  }

  void _reset({ModalEditingMode mode = ModalEditingMode.normal}) {
    _mode = mode;
    _prefix = null;
    _operator = null;
    _count = 0;
    _operatorCount = 1;
  }
}
