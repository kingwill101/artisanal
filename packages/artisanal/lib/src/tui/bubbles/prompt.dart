import 'dart:async';

import '../cmd.dart';
import '../key.dart';
import '../component.dart';
import '../msg.dart';
import '../view.dart' as tui_view;
import '../program.dart';
import '../terminal.dart';
import 'anticipate.dart';
import 'confirm.dart';
import 'password.dart';
import 'search.dart';
import 'select.dart';
import 'spinner.dart';
import 'textinput.dart';
import 'textarea.dart';
import 'wizard.dart';

/// Shared defaults for "artisanal-style" prompts that run a single bubble and
/// return a value.
///
/// Prompts run in inline mode to preserve the artisanal command UX (print output
/// above/between prompts), while still using the Bubble Tea event loop.
const promptProgramOptions = ProgramOptions(
  altScreen: false,
  hideCursor: false,
  fps: 20,
  mouse: false,
  bracketedPaste: false,
  signalHandlers: false,
  sendInterrupt: false,
  useUltravioletRenderer: false,
  useUltravioletInputDecoder: false,
  shutdownSharedStdinOnExit: false,
);

/// Dedicated defaults for full-screen text editing prompts.
const textareaPromptOptions = ProgramOptions(
  altScreen: true,
  hideCursor: true,
  fps: 60,
  mouse: false,
  bracketedPaste: true,
  signalHandlers: false,
  sendInterrupt: false,
  useUltravioletRenderer: true,
  useUltravioletInputDecoder: true,
  shutdownSharedStdinOnExit: false,
);

/// Runs a [PasswordModel] and resolves to the submitted password, or `null` if
/// cancelled.
Future<String?> runPasswordPrompt(
  PasswordModel model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<String?>();
  final program = Program(
    _PasswordPromptModel(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [PasswordConfirmModel] and resolves to the submitted password, or
/// `null` if cancelled.
Future<String?> runPasswordConfirmPrompt(
  PasswordConfirmModel model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<String?>();
  final program = Program(
    _PasswordConfirmPromptModel(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [SelectModel] and resolves to the selected item, or `null` if
/// cancelled.
Future<T?> runSelectPrompt<T>(
  SelectModel<T> model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<T?>();
  final program = Program(
    _SelectPromptModel<T>(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [MultiSelectModel] and resolves to the selected items, or `null` if
/// cancelled.
Future<List<T>?> runMultiSelectPrompt<T>(
  MultiSelectModel<T> model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<List<T>?>();
  final program = Program(
    _MultiSelectPromptModel<T>(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [ConfirmModel] and resolves to the selected value, or `null` if
/// cancelled.
Future<bool?> runConfirmPrompt(
  ConfirmModel model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<bool?>();
  final program = Program(
    _ConfirmPromptModel(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [SearchModel] and resolves to the selected item, or `null` if
/// cancelled.
Future<T?> runSearchPrompt<T>(
  SearchModel<T> model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<T?>();
  final program = Program(
    _SearchPromptModel<T>(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs an [AnticipateModel] and resolves to the accepted value, or `null` if
/// cancelled.
Future<String?> runAnticipatePrompt(
  AnticipateModel model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<String?>();
  final program = Program(
    _AnticipatePromptModel(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [TextInputModel] and resolves to the submitted value, or `null` if
/// cancelled.
Future<String?> runTextInputPrompt(
  TextInputModel model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<String?>();
  final program = Program(
    _TextInputPromptModel(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [TextAreaModel] and resolves to the submitted value, or `null` if
/// cancelled.
///
/// By default, `ctrl+s` submits and `esc` cancels.
Future<String?> runTextAreaPrompt(
  TextAreaModel model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<String?>();
  final program = Program(
    _TextAreaPromptModel(model, controller),
    options: options ?? textareaPromptOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs a [WizardModel] and resolves to the final answers, or `null` if
/// cancelled.
Future<Map<String, dynamic>?> runWizardPrompt(
  WizardModel model,
  Terminal terminal, {
  ProgramOptions? options,
}) async {
  final controller = _PromptController<Map<String, dynamic>?>();
  final program = Program(
    _WizardPromptModel(model, controller),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

/// Runs an animated spinner while executing [task], returning its result.
Future<T> runSpinnerTask<T>({
  required String message,
  required Future<T> Function() task,
  Spinner spinner = Spinners.miniDot,
  required Terminal terminal,
  ProgramOptions? options,
}) async {
  final controller = _PromptController<T>();
  final program = Program(
    _SpinnerTaskModel<T>(
      message: message,
      task: task,
      spinner: spinner,
      controller: controller,
    ),
    options: options ?? promptProgramOptions,
    terminal: terminal,
  );
  await program.run();
  return await controller.future;
}

class _PromptController<T> {
  final Completer<T> _completer = Completer<T>();

  bool get isCompleted => _completer.isCompleted;

  Future<T> get future => _completer.future;

  void complete(T value) {
    if (_completer.isCompleted) return;
    _completer.complete(value);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
  }
}

class _PasswordPromptModel extends ViewComponent {
  _PasswordPromptModel(this._model, this._controller);

  PasswordModel _model;
  final _PromptController<String?> _controller;

  @override
  Cmd? init() => _model.init();

  @override
  (_PasswordPromptModel, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is PasswordSubmittedMsg) {
      _controller.complete(msg.password);
      return (this, Cmd.quit());
    }

    if (msg is PasswordCancelledMsg) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _PasswordConfirmPromptModel extends ViewComponent {
  _PasswordConfirmPromptModel(this._model, this._controller);

  PasswordConfirmModel _model;
  final _PromptController<String?> _controller;

  @override
  Cmd? init() => _model.init();

  @override
  (_PasswordConfirmPromptModel, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is PasswordSubmittedMsg) {
      _controller.complete(msg.password);
      return (this, Cmd.quit());
    }

    if (msg is PasswordCancelledMsg) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _ConfirmPromptModel extends ViewComponent {
  _ConfirmPromptModel(this._model, this._controller);

  ConfirmModel _model;
  final _PromptController<bool?> _controller;

  @override
  Cmd? init() => _model.init();

  @override
  (_ConfirmPromptModel, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is ConfirmResultMsg) {
      _controller.complete(msg.confirmed);
      return (this, Cmd.quit());
    }

    if (msg is ConfirmCancelledMsg) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _SelectPromptModel<T> extends ViewComponent {
  _SelectPromptModel(this._model, this._controller);

  SelectModel<T> _model;
  final _PromptController<T?> _controller;

  @override
  Cmd? init() => _model.init();

  @override
  (_SelectPromptModel<T>, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is SelectionMadeMsg<T>) {
      _controller.complete(msg.item);
      return (this, Cmd.quit());
    }

    if (msg is SelectionCancelledMsg) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _SearchPromptModel<T> extends ViewComponent {
  _SearchPromptModel(this._model, this._controller);

  SearchModel<T> _model;
  final _PromptController<T?> _controller;

  @override
  Cmd? init() => _model.init();

  @override
  (_SearchPromptModel<T>, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is SearchSelectionMadeMsg<T>) {
      _controller.complete(msg.item);
      return (this, Cmd.quit());
    }

    if (msg is SearchCancelledMsg) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _AnticipatePromptModel extends ViewComponent {
  _AnticipatePromptModel(this._model, this._controller);

  AnticipateModel _model;
  final _PromptController<String?> _controller;

  @override
  Cmd? init() {
    _model = _model.focus();
    return _model.init();
  }

  @override
  (_AnticipatePromptModel, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is KeyMsg &&
        (msg.key.type == KeyType.escape ||
            (msg.key.ctrl &&
                msg.key.runes.isNotEmpty &&
                msg.key.runes.first == 0x63))) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;

    // Anticipate "completes" when it loses focus.
    if (!_model.focused) {
      final value = _model.value.isEmpty ? null : _model.value;
      _controller.complete(value);
      return (this, Cmd.quit());
    }

    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _TextInputPromptModel extends ViewComponent {
  _TextInputPromptModel(this._model, this._controller);

  TextInputModel _model;
  final _PromptController<String?> _controller;

  @override
  Cmd? init() => _model.focus();

  @override
  (_TextInputPromptModel, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is KeyMsg) {
      if (msg.key.type == KeyType.enter) {
        _controller.complete(_model.value);
        return (this, Cmd.quit());
      }

      if (msg.key.type == KeyType.escape ||
          (msg.key.ctrl &&
              msg.key.runes.isNotEmpty &&
              msg.key.runes.first == 0x63)) {
        _controller.complete(null);
        return (this, Cmd.quit());
      }
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _MultiSelectPromptModel<T> extends ViewComponent {
  _MultiSelectPromptModel(this._model, this._controller);

  MultiSelectModel<T> _model;
  final _PromptController<List<T>?> _controller;

  @override
  Cmd? init() => _model.init();

  @override
  (_MultiSelectPromptModel<T>, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is MultiSelectionMadeMsg<T>) {
      _controller.complete(msg.items);
      return (this, Cmd.quit());
    }

    if (msg is SelectionCancelledMsg) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _TextAreaPromptModel extends ViewComponent {
  _TextAreaPromptModel(this._model, this._controller);

  TextAreaModel _model;
  final _PromptController<String?> _controller;

  @override
  Cmd? init() => _model.focus();

  @override
  (_TextAreaPromptModel, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is KeyMsg) {
      if (msg.key.type == KeyType.escape ||
          (msg.key.ctrl &&
              msg.key.runes.isNotEmpty &&
              msg.key.runes.first == 0x63)) {
        _controller.complete(null);
        return (this, Cmd.quit());
      }

      // Ctrl+S to submit (mirrors common editor save shortcut).
      if (msg.key.runes.isNotEmpty &&
          (msg.key.runes.first == 0x73 || msg.key.runes.first == 0x13) &&
          (msg.key.ctrl || msg.key.runes.first == 0x13)) {
        _controller.complete(_model.value);
        return (this, Cmd.quit());
      }
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() {
    final Object v = _model.view();
    if (v is tui_view.View) return v.content;
    return v.toString();
  }
}

class _WizardPromptModel extends ViewComponent {
  _WizardPromptModel(this._model, this._controller);

  WizardModel _model;
  final _PromptController<Map<String, dynamic>?> _controller;

  @override
  Cmd? init() => _model.init();

  @override
  (_WizardPromptModel, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is WizardCompletedMsg) {
      _controller.complete(msg.answers);
      return (this, Cmd.quit());
    }

    if (msg is WizardCancelledMsg) {
      _controller.complete(null);
      return (this, Cmd.quit());
    }

    final (newModel, cmd) = _model.update(msg);
    _model = newModel;
    return (this, cmd);
  }

  @override
  String view() => _model.view();
}

class _SpinnerTaskDoneMsg<T> extends Msg {
  const _SpinnerTaskDoneMsg(this.result);

  final T result;
}

class _SpinnerTaskErrorMsg extends Msg {
  const _SpinnerTaskErrorMsg(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

class _SpinnerTaskModel<T> extends ViewComponent {
  _SpinnerTaskModel({
    required this.message,
    required this.task,
    required Spinner spinner,
    required _PromptController<T> controller,
  }) : _spinner = SpinnerModel(spinner: spinner),
       _controller = controller;

  final String message;
  final Future<T> Function() task;

  SpinnerModel _spinner;
  final _PromptController<T> _controller;

  @override
  Cmd? init() {
    return Cmd.batch([
      _spinner.tick(),
      Cmd.perform<T>(
        task,
        onSuccess: (result) => _SpinnerTaskDoneMsg<T>(result),
        onError: (error, stack) => _SpinnerTaskErrorMsg(error, stack),
      ),
    ]);
  }

  @override
  (_SpinnerTaskModel<T>, Cmd?) update(Msg msg) {
    if (_controller.isCompleted) return (this, null);

    if (msg is _SpinnerTaskDoneMsg<T>) {
      _controller.complete(msg.result);
      return (this, Cmd.quit());
    }

    if (msg is _SpinnerTaskErrorMsg) {
      _controller.completeError(msg.error, msg.stackTrace);
      return (this, Cmd.quit());
    }

    final (newSpinner, cmd) = _spinner.update(msg);
    _spinner = newSpinner;
    return (this, cmd);
  }

  @override
  String view() => '${_spinner.view()} $message';
}
