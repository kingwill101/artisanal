import 'dart:math' as math;

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';

typedef WizardValidateFunc = String? Function(String value);

abstract class WizardFormStep {
  const WizardFormStep({
    required this.key,
    required this.prompt,
    this.description,
  });

  final String key;
  final String prompt;
  final String? description;

  bool shouldSkip(Map<String, dynamic> answers) => false;

  factory WizardFormStep.textInput({
    required String key,
    required String prompt,
    String? placeholder,
    String? defaultValue,
    WizardValidateFunc? validate,
    String? description,
  }) = _WizardTextInputStep;

  factory WizardFormStep.password({
    required String key,
    required String prompt,
    String? placeholder,
    String? defaultValue,
    WizardValidateFunc? validate,
    String? description,
  }) = _WizardPasswordStep;

  factory WizardFormStep.confirm({
    required String key,
    required String prompt,
    bool? defaultValue,
    String? description,
  }) = _WizardConfirmStep;

  factory WizardFormStep.select({
    required String key,
    required String prompt,
    required List<String> options,
    int? defaultIndex,
    String? description,
  }) = _WizardSelectStep;

  factory WizardFormStep.multiSelect({
    required String key,
    required String prompt,
    required List<String> options,
    List<int>? defaultSelected,
    String? description,
  }) = _WizardMultiSelectStep;

  factory WizardFormStep.conditional({
    required WizardFormStep step,
    required bool Function(Map<String, dynamic>) condition,
  }) = _WizardConditionalStep;

  factory WizardFormStep.group({
    required String key,
    required String title,
    required List<WizardFormStep> steps,
    String? description,
  }) = _WizardGroupStep;
}

final class _WizardTextInputStep extends WizardFormStep {
  const _WizardTextInputStep({
    required super.key,
    required super.prompt,
    this.placeholder,
    this.defaultValue,
    this.validate,
    super.description,
  });

  final String? placeholder;
  final String? defaultValue;
  final WizardValidateFunc? validate;
}

final class _WizardPasswordStep extends WizardFormStep {
  const _WizardPasswordStep({
    required super.key,
    required super.prompt,
    this.placeholder,
    this.defaultValue,
    this.validate,
    super.description,
  });

  final String? placeholder;
  final String? defaultValue;
  final WizardValidateFunc? validate;
}

final class _WizardConfirmStep extends WizardFormStep {
  const _WizardConfirmStep({
    required super.key,
    required super.prompt,
    this.defaultValue,
    super.description,
  });

  final bool? defaultValue;
}

final class _WizardSelectStep extends WizardFormStep {
  const _WizardSelectStep({
    required super.key,
    required super.prompt,
    required this.options,
    this.defaultIndex,
    super.description,
  });

  final List<String> options;
  final int? defaultIndex;
}

final class _WizardMultiSelectStep extends WizardFormStep {
  const _WizardMultiSelectStep({
    required super.key,
    required super.prompt,
    required this.options,
    this.defaultSelected,
    super.description,
  });

  final List<String> options;
  final List<int>? defaultSelected;
}

final class _WizardConditionalStep extends WizardFormStep {
  _WizardConditionalStep({required this.step, required this.condition})
    : super(key: step.key, prompt: step.prompt, description: step.description);

  final WizardFormStep step;
  final bool Function(Map<String, dynamic>) condition;

  @override
  bool shouldSkip(Map<String, dynamic> answers) => !condition(answers);
}

final class _WizardGroupStep extends WizardFormStep {
  const _WizardGroupStep({
    required super.key,
    required String title,
    required this.steps,
    super.description,
  }) : super(prompt: title);

  final List<WizardFormStep> steps;
}

class Wizard extends StatefulWidget {
  Wizard({
    required this.steps,
    this.title,
    this.showProgress = true,
    this.showStepIndicator = true,
    this.initialAnswers = const {},
    this.onCompleted,
    this.onCancelled,
    this.onExit,
    this.width,
    this.nextLabel = 'Next',
    this.finishLabel = 'Finish',
    this.backLabel = 'Back',
    this.cancelLabel = 'Cancel',
    this.exitLabel = 'Quit',
    this.showHelp = true,
    super.key,
  });

  final List<WizardFormStep> steps;
  final String? title;
  final bool showProgress;
  final bool showStepIndicator;
  final Map<String, dynamic> initialAnswers;
  final ValueCmdCallback<Map<String, dynamic>>? onCompleted;
  final CmdCallback? onCancelled;
  final CmdCallback? onExit;
  final int? width;
  final String nextLabel;
  final String finishLabel;
  final String backLabel;
  final String cancelLabel;
  final String exitLabel;
  final bool showHelp;

  @override
  State createState() => _WizardState();
}

class _WizardState extends State<Wizard> {
  static const _textFocusId = 'wizard-current-input';

  late List<WizardFormStep> _flattenedSteps;
  late Map<String, dynamic> _answers;
  final FocusController _focusController = FocusController();
  int _currentStepIndex = 0;
  TextEditingController? _textController;
  String? _validationError;
  int _highlightedIndex = 0;
  bool _confirmValue = false;
  Set<int> _multiSelected = <int>{};

  WizardFormStep? get _currentStep =>
      _currentStepIndex >= 0 && _currentStepIndex < _flattenedSteps.length
      ? _flattenedSteps[_currentStepIndex]
      : null;

  List<WizardFormStep> get _visibleSteps => _flattenedSteps
      .where((step) => !step.shouldSkip(_answers))
      .toList(growable: false);

  int get _currentVisibleStepIndex {
    var visible = -1;
    for (var i = 0; i <= _currentStepIndex && i < _flattenedSteps.length; i++) {
      if (!_flattenedSteps[i].shouldSkip(_answers)) {
        visible++;
      }
    }
    return visible.clamp(0, math.max(0, _visibleSteps.length - 1));
  }

  bool get _isOnLastVisibleStep =>
      _visibleSteps.isNotEmpty &&
      _currentVisibleStepIndex == _visibleSteps.length - 1;

  @override
  void initState() {
    super.initState();
    _initializeWizard();
  }

  @override
  Cmd? didUpdateWidget(covariant Wizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.steps, widget.steps) ||
        !identical(oldWidget.initialAnswers, widget.initialAnswers)) {
      _initializeWizard();
    }
    return null;
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  void _initializeWizard() {
    _flattenedSteps = _flattenSteps(widget.steps);
    _answers = Map<String, dynamic>.from(widget.initialAnswers);
    _currentStepIndex = 0;
    _seekToNextVisibleStep();
    _configureCurrentStepState();
  }

  List<WizardFormStep> _flattenSteps(List<WizardFormStep> steps) {
    final result = <WizardFormStep>[];
    for (final step in steps) {
      if (step is _WizardGroupStep) {
        result.addAll(_flattenSteps(step.steps));
      } else if (step is _WizardConditionalStep) {
        result.add(step);
      } else {
        result.add(step);
      }
    }
    return result;
  }

  void _seekToNextVisibleStep() {
    while (_currentStepIndex < _flattenedSteps.length &&
        _flattenedSteps[_currentStepIndex].shouldSkip(_answers)) {
      _currentStepIndex++;
    }
  }

  void _configureCurrentStepState() {
    _validationError = null;
    final step = _currentStep;
    if (step == null) {
      _disposeTextController();
      return;
    }

    switch (step) {
      case _WizardTextInputStep():
        _ensureTextController(
          _stringAnswer(step.key) ?? step.defaultValue ?? '',
        );
        break;
      case _WizardPasswordStep():
        _ensureTextController(
          _stringAnswer(step.key) ?? step.defaultValue ?? '',
        );
        break;
      case _WizardSelectStep():
        _disposeTextController();
        _highlightedIndex = _resolveSelectIndex(step);
        break;
      case _WizardMultiSelectStep():
        _disposeTextController();
        final existing = _answers[step.key];
        if (existing is List) {
          _multiSelected = existing
              .map((value) => step.options.indexOf(value.toString()))
              .where((index) => index >= 0)
              .toSet();
        } else {
          _multiSelected = Set<int>.from(step.defaultSelected ?? const <int>[]);
        }
        _highlightedIndex = _multiSelected.isNotEmpty
            ? _multiSelected.first
            : 0;
        break;
      case _WizardConfirmStep():
        _disposeTextController();
        final existing = _answers[step.key];
        _confirmValue = existing is bool
            ? existing
            : (step.defaultValue ?? false);
        break;
      case _WizardConditionalStep():
        break;
      case _WizardGroupStep():
        break;
    }
  }

  void _ensureTextController(String text) {
    final controller = _textController;
    if (controller == null) {
      _textController = TextEditingController(text: text);
      return;
    }
    controller.text = text;
  }

  void _disposeTextController() {
    _textController?.dispose();
    _textController = null;
  }

  String? _stringAnswer(String key) {
    final value = _answers[key];
    if (value is String) return value;
    return null;
  }

  int _resolveSelectIndex(_WizardSelectStep step) {
    final existing = _answers[step.key];
    final answerIndex = existing is String
        ? step.options.indexOf(existing)
        : -1;
    if (answerIndex >= 0) return answerIndex;
    if (step.options.isEmpty) return 0;
    return (step.defaultIndex ?? 0).clamp(0, step.options.length - 1);
  }

  int? _previousVisibleStepIndex() {
    for (var i = _currentStepIndex - 1; i >= 0; i--) {
      if (!_flattenedSteps[i].shouldSkip(_answers)) return i;
    }
    return null;
  }

  void _pruneSkippedAnswers() {
    for (final step in _flattenedSteps) {
      if (step.shouldSkip(_answers)) {
        _answers.remove(step.key);
      }
    }
  }

  dynamic _currentAnswer() {
    final step = _currentStep;
    if (step == null) return null;

    switch (step) {
      case _WizardTextInputStep():
        return _textController?.text ?? '';
      case _WizardPasswordStep():
        return _textController?.text ?? '';
      case _WizardConfirmStep():
        return _confirmValue;
      case _WizardSelectStep():
        if (step.options.isEmpty) return null;
        final index = _highlightedIndex.clamp(0, step.options.length - 1);
        return step.options[index];
      case _WizardMultiSelectStep():
        return step.options
            .asMap()
            .entries
            .where((entry) => _multiSelected.contains(entry.key))
            .map((entry) => entry.value)
            .toList(growable: false);
      case _WizardConditionalStep():
        return null;
      case _WizardGroupStep():
        return null;
    }
    return null;
  }

  String? _validateCurrentStep() {
    final step = _currentStep;
    if (step == null) return null;

    switch (step) {
      case _WizardTextInputStep():
        return step.validate?.call(_textController?.text ?? '');
      case _WizardPasswordStep():
        return step.validate?.call(_textController?.text ?? '');
      case _WizardSelectStep():
        if (step.options.isEmpty) {
          return 'Add at least one option to this step.';
        }
        return null;
      case _WizardMultiSelectStep():
        return null;
      case _WizardConfirmStep():
        return null;
      case _WizardConditionalStep():
        return null;
      case _WizardGroupStep():
        return null;
    }
    return null;
  }

  Cmd? _advance() {
    final step = _currentStep;
    if (step == null) return null;

    final validationError = _validateCurrentStep();
    if (validationError != null) {
      setState(() {
        _validationError = validationError;
      });
      return null;
    }

    final answer = _currentAnswer();
    Map<String, dynamic>? completedAnswers;
    setState(() {
      _answers[step.key] = answer;
      _pruneSkippedAnswers();
      _currentStepIndex++;
      _seekToNextVisibleStep();
      if (_currentStepIndex >= _flattenedSteps.length) {
        completedAnswers = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(_answers),
        );
      } else {
        _configureCurrentStepState();
      }
    });

    if (completedAnswers != null) {
      return widget.onCompleted?.call(completedAnswers!);
    }
    return null;
  }

  Cmd? _goBack() {
    final previous = _previousVisibleStepIndex();
    if (previous == null) return null;
    setState(() {
      _currentStepIndex = previous;
      _configureCurrentStepState();
    });
    return null;
  }

  Cmd? _setConfirm(bool value) {
    setState(() {
      _confirmValue = value;
      _validationError = null;
    });
    return null;
  }

  Cmd? _setHighlightedIndex(int index) {
    final step = _currentStep;
    var maxIndex = 0;
    if (step case final _WizardSelectStep current) {
      maxIndex = math.max(0, current.options.length - 1);
    } else if (step case final _WizardMultiSelectStep current) {
      maxIndex = math.max(0, current.options.length - 1);
    }

    setState(() {
      _highlightedIndex = index.clamp(0, maxIndex);
      _validationError = null;
    });
    return null;
  }

  Cmd? _toggleHighlightedMultiOption() {
    final step = _currentStep;
    if (step is! _WizardMultiSelectStep || step.options.isEmpty) return null;
    setState(() {
      if (_multiSelected.contains(_highlightedIndex)) {
        _multiSelected.remove(_highlightedIndex);
      } else {
        _multiSelected.add(_highlightedIndex);
      }
      _validationError = null;
    });
    return null;
  }

  bool _isCtrlCShortcut(terminal_keys.Key key) {
    if (!key.ctrl || key.alt || key.meta || key.hyper || key.superKey) {
      return key.runes.length == 1 && key.runes.first == 0x03;
    }
    if (key.runes.isEmpty) return false;
    if (key.runes.length == 1 && key.runes.first == 0x03) {
      return true;
    }
    final char = key.char;
    return char != null && char.toLowerCase() == 'c';
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is InterruptMsg && widget.onExit != null) {
      return widget.onExit?.call() ?? Cmd.none();
    }

    if (msg is! KeyMsg) return null;
    final key = msg.key;

    if (_isCtrlCShortcut(key) && widget.onExit != null) {
      return widget.onExit?.call() ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.escape) {
      return widget.onCancelled?.call() ?? Cmd.none();
    }

    final step = _currentStep;
    if (step == null) return Cmd.none();

    switch (step) {
      case _WizardTextInputStep():
      case _WizardPasswordStep():
        if (key.type == terminal_keys.KeyType.enter) {
          return _advance() ?? Cmd.none();
        }
        return null;
      case _WizardSelectStep():
        if (key.type == terminal_keys.KeyType.up) {
          return _setHighlightedIndex(_highlightedIndex - 1) ?? Cmd.none();
        }
        if (key.type == terminal_keys.KeyType.down) {
          return _setHighlightedIndex(_highlightedIndex + 1) ?? Cmd.none();
        }
        if (key.type == terminal_keys.KeyType.enter) {
          return _advance() ?? Cmd.none();
        }
        return null;
      case _WizardMultiSelectStep():
        if (key.type == terminal_keys.KeyType.up) {
          return _setHighlightedIndex(_highlightedIndex - 1) ?? Cmd.none();
        }
        if (key.type == terminal_keys.KeyType.down) {
          return _setHighlightedIndex(_highlightedIndex + 1) ?? Cmd.none();
        }
        if (key.type == terminal_keys.KeyType.enter) {
          return _advance() ?? Cmd.none();
        }
        if (key.type == terminal_keys.KeyType.space || key.char == ' ') {
          return _toggleHighlightedMultiOption() ?? Cmd.none();
        }
        return null;
      case _WizardConfirmStep():
        if (key.type == terminal_keys.KeyType.left ||
            key.type == terminal_keys.KeyType.up ||
            key.char == 'n') {
          return _setConfirm(false) ?? Cmd.none();
        }
        if (key.type == terminal_keys.KeyType.right ||
            key.type == terminal_keys.KeyType.down ||
            key.char == 'y') {
          return _setConfirm(true) ?? Cmd.none();
        }
        if (key.type == terminal_keys.KeyType.enter) {
          return _advance() ?? Cmd.none();
        }
        return null;
      case _WizardConditionalStep():
      case _WizardGroupStep():
        return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final media = MediaQuery.of(context);
    final step = _currentStep;
    if (step == null) {
      return Text('No wizard steps available.', style: theme.bodyMedium);
    }

    final visibleSteps = _visibleSteps;
    final currentVisibleStep = _currentVisibleStepIndex + 1;
    final titleStyle = theme.titleMedium.copy()..foreground(theme.onSurface);
    final subtleStyle = theme.bodySmall.copy()..foreground(theme.muted);
    final errorStyle = theme.bodySmall.copy()
      ..foreground(theme.error)
      ..bold();
    final compactFooter = media.size.width < 56;

    final content = <Widget>[
      if (widget.title != null) Text(widget.title!, style: theme.titleLarge),
      if (widget.title != null) Divider(),
      if (widget.showProgress && visibleSteps.isNotEmpty)
        Text(
          'Step $currentVisibleStep of ${visibleSteps.length}',
          style: subtleStyle,
        ),
      if (widget.showStepIndicator && visibleSteps.length > 1)
        Card(
          padding: const EdgeInsets.only(left: 1, right: 1, top: 1, bottom: 1),
          background: theme.surface,
          child: StepIndicator(
            current: _currentVisibleStepIndex,
            steps: visibleSteps
                .map((item) => StepItem(label: item.prompt))
                .toList(growable: false),
          ),
        ),
      Card(
        padding: const EdgeInsets.all(1),
        background: theme.surface,
        child: Column(
          gap: 1,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(step.prompt, style: titleStyle),
            if (step.description != null)
              Text(step.description!, style: subtleStyle),
            _buildStepBody(context, step),
            if (_validationError != null)
              Text(_validationError!, style: errorStyle),
          ],
        ),
      ),
      _buildFooter(compactFooter),
      if (widget.showHelp)
        HelpView(
          keyMap: _WizardHelpKeyMap(
            step: step,
            showExit: widget.onExit != null,
            isLastStep: _isOnLastVisibleStep,
          ),
          itemSpacing: 2,
          runSpacing: 0,
        ),
    ];

    return FocusScope(
      controller: _focusController,
      child: SizedBox(
        width: widget.width,
        child: Column(
          gap: 1,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: content,
        ),
      ),
    );
  }

  Widget _buildFooter(bool compactFooter) {
    final nextLabel = _isOnLastVisibleStep
        ? widget.finishLabel
        : widget.nextLabel;
    final backButton = Button(
      label: widget.backLabel,
      variant: ButtonVariant.ghost,
      enabled: _previousVisibleStepIndex() != null,
      onPressed: _goBack,
    );
    final cancelButton = Button(
      label: widget.cancelLabel,
      variant: ButtonVariant.secondary,
      onPressed: widget.onCancelled,
    );
    final exitButton = widget.onExit == null
        ? null
        : Button(
            label: widget.exitLabel,
            variant: ButtonVariant.ghost,
            onPressed: widget.onExit,
          );
    final nextButton = Button(label: nextLabel, onPressed: _advance);

    if (compactFooter) {
      return Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nextButton,
          Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [backButton, cancelButton, ?exitButton],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        backButton,
        Row(gap: 1, children: [?exitButton, cancelButton, nextButton]),
      ],
    );
  }

  Widget _buildStepBody(BuildContext context, WizardFormStep step) {
    final theme = ThemeScope.of(context);
    return switch (step) {
      _WizardTextInputStep current => Frame(
        background: theme.background,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: TextField(
          key: ValueKey<String>('wizard-input-${step.key}'),
          controller: _textController,
          placeholder: current.placeholder ?? 'Enter a value',
          focusController: _focusController,
          focusId: _textFocusId,
          autofocus: true,
          onChanged: (_) {
            if (_validationError != null) {
              setState(() {
                _validationError = null;
              });
            }
          },
        ),
      ),
      _WizardPasswordStep current => Frame(
        background: theme.background,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: TextField(
          key: ValueKey<String>('wizard-input-${step.key}'),
          controller: _textController,
          placeholder: current.placeholder ?? 'Enter a secret',
          focusController: _focusController,
          focusId: _textFocusId,
          autofocus: true,
          echoMode: .password,
          onChanged: (_) {
            if (_validationError != null) {
              setState(() {
                _validationError = null;
              });
            }
          },
        ),
      ),
      _WizardConfirmStep() => _WizardChoiceRow(
        left: _WizardChoiceButton(
          label: 'No',
          selected: !_confirmValue,
          onTap: () => _setConfirm(false),
        ),
        right: _WizardChoiceButton(
          label: 'Yes',
          selected: _confirmValue,
          onTap: () => _setConfirm(true),
        ),
      ),
      _WizardSelectStep current => Column(
        gap: 0,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < current.options.length; i++)
            _WizardOptionRow(
              label: current.options[i],
              marker: i == _highlightedIndex ? '(*)' : '( )',
              selected: i == _highlightedIndex,
              onTap: () => _setHighlightedIndex(i),
            ),
        ],
      ),
      _WizardMultiSelectStep current => Column(
        gap: 0,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < current.options.length; i++)
            _WizardOptionRow(
              label: current.options[i],
              marker: _multiSelected.contains(i) ? '[x]' : '[ ]',
              selected: i == _highlightedIndex,
              onTap: () {
                _setHighlightedIndex(i);
                return _toggleHighlightedMultiOption();
              },
            ),
        ],
      ),
      _ => Text('', style: theme.bodyMedium),
    };
  }
}

final class _WizardHelpKeyMap extends KeyMap {
  _WizardHelpKeyMap({
    required WizardFormStep step,
    required bool showExit,
    required bool isLastStep,
  }) {
    final help = _buildShortHelp(step, showExit, isLastStep);
    shortHelp = help;
    fullHelp = [help];
  }

  static List<KeyBinding> _buildShortHelp(
    WizardFormStep step,
    bool showExit,
    bool isLastStep,
  ) {
    final bindings = <KeyBinding>[];

    if (step is _WizardSelectStep || step is _WizardMultiSelectStep) {
      bindings.add(KeyBinding.withHelp(['up', 'k'], '↑/k', 'move up'));
      bindings.add(KeyBinding.withHelp(['down', 'j'], '↓/j', 'move down'));
    }

    if (step is _WizardMultiSelectStep) {
      bindings.add(KeyBinding.withHelp(['space'], 'space', 'toggle'));
    }

    if (step is _WizardConfirmStep) {
      bindings.add(KeyBinding.withHelp(['left', 'n'], '←/n', 'no'));
      bindings.add(KeyBinding.withHelp(['right', 'y'], '→/y', 'yes'));
    }

    bindings.add(
      KeyBinding.withHelp(
        ['enter'],
        'enter',
        isLastStep ? 'finish' : 'continue',
      ),
    );
    bindings.add(KeyBinding.withHelp(['esc'], 'esc', 'cancel'));
    if (showExit) {
      bindings.add(KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'quit'));
    }

    return bindings;
  }
}

final class _WizardChoiceRow extends StatelessWidget {
  _WizardChoiceRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      gap: 1,
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    );
  }
}

final class _WizardChoiceButton extends StatelessWidget {
  _WizardChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final CmdCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: selected
            ? theme.listRowSelectedBackground
            : theme.listRowBackground,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Center(
          child: Text(
            label,
            style: (selected ? theme.labelLarge : theme.bodyMedium).copy()
              ..foreground(
                selected
                    ? theme.listRowSelectedForeground
                    : theme.listRowForeground,
              ),
          ),
        ),
      ),
    );
  }
}

final class _WizardOptionRow extends StatelessWidget {
  _WizardOptionRow({
    required this.label,
    required this.marker,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String marker;
  final bool selected;
  final CmdCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final style = (selected ? theme.labelLarge : theme.bodyMedium).copy()
      ..foreground(
        selected ? theme.listRowSelectedForeground : theme.listRowForeground,
      );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: selected
            ? theme.listRowSelectedBackground
            : theme.listRowBackground,
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
        child: Row(
          gap: 1,
          children: [
            Text(marker, style: style),
            Expanded(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}
