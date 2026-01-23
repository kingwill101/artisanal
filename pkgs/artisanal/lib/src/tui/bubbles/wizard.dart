/// Wizard component for multi-step forms.
///
/// Provides a sequential form flow with different input types, conditional logic,
/// and answer accumulation.
library;

import '../cmd.dart';
import '../key.dart';
import '../component.dart';
import '../model.dart';
import '../msg.dart';
import 'textinput.dart';
import 'confirm.dart';
import 'select.dart';
import 'password.dart';
import 'key_binding.dart';

/// Message sent when a wizard step is completed.
class WizardStepCompletedMsg extends Msg {
  const WizardStepCompletedMsg(this.stepIndex, this.answer);

  /// The index of the completed step.
  final int stepIndex;

  /// The answer provided for this step.
  final dynamic answer;

  @override
  String toString() => 'WizardStepCompletedMsg($stepIndex, $answer)';
}

/// Message sent when the entire wizard is completed.
class WizardCompletedMsg extends Msg {
  const WizardCompletedMsg(this.answers);

  /// Map of step keys to their answers.
  final Map<String, dynamic> answers;

  @override
  String toString() => 'WizardCompletedMsg($answers)';
}

/// Message sent when the wizard is cancelled.
class WizardCancelledMsg extends Msg {
  const WizardCancelledMsg();

  @override
  String toString() => 'WizardCancelledMsg()';
}

/// Validation function for wizard steps.
typedef ValidateFunc = String? Function(String value);

/// Base class for wizard steps.
abstract class WizardStep {
  /// Creates a wizard step.
  const WizardStep({required this.key, this.description});

  /// Unique key for this step (used to store answer).
  final String key;

  /// Optional description displayed for this step.
  final String? description;

  /// Whether this step should be skipped based on previous answers.
  bool shouldSkip(Map<String, dynamic> answers) => false;

  /// Creates the model for this step.
  Model createModel(Map<String, dynamic> answers);

  /// Extracts the answer from the model after completion.
  dynamic extractAnswer(Model model);

  /// Creates a text input step.
  factory WizardStep.textInput({
    required String key,
    required String prompt,
    String? placeholder,
    String? defaultValue,
    ValidateFunc? validate,
    String? description,
  }) = TextInputStep;

  /// Creates a confirmation (yes/no) step.
  factory WizardStep.confirm({
    required String key,
    required String prompt,
    bool? defaultValue,
    String? description,
  }) = ConfirmStep;

  /// Creates a single-select step.
  factory WizardStep.select({
    required String key,
    required String prompt,
    required List<String> options,
    int? defaultIndex,
    String? description,
  }) = SelectStep;

  /// Creates a multi-select step.
  factory WizardStep.multiSelect({
    required String key,
    required String prompt,
    required List<String> options,
    List<int>? defaultSelected,
    String? description,
  }) = MultiSelectStep;

  /// Creates a password input step.
  factory WizardStep.password({
    required String key,
    required String prompt,
    ValidateFunc? validate,
    String? description,
  }) = PasswordStep;

  /// Creates a conditional step (shown only if condition is true).
  factory WizardStep.conditional({
    required WizardStep step,
    required bool Function(Map<String, dynamic>) condition,
  }) = ConditionalStep;

  /// Creates a group of steps with a title.
  factory WizardStep.group({
    required String key,
    required String title,
    required List<WizardStep> steps,
    String? description,
  }) = GroupStep;
}

/// Text input wizard step.
class TextInputStep extends WizardStep {
  /// Creates a text input step.
  const TextInputStep({
    required super.key,
    required this.prompt,
    this.placeholder,
    this.defaultValue,
    this.validate,
    super.description,
  });

  /// The prompt to display.
  final String prompt;

  /// Placeholder text.
  final String? placeholder;

  /// Default value.
  final String? defaultValue;

  /// Validation function.
  final ValidateFunc? validate;

  @override
  Model createModel(Map<String, dynamic> answers) {
    final model = TextInputModel(
      prompt: prompt,
      placeholder: placeholder ?? '',
      validate: validate,
    );
    if (defaultValue != null) {
      model.value = defaultValue!;
    }
    model.focus();
    return model;
  }

  @override
  dynamic extractAnswer(Model model) {
    if (model is TextInputModel) {
      return model.value;
    }
    return null;
  }
}

/// Confirmation wizard step.
class ConfirmStep extends WizardStep {
  /// Creates a confirmation step.
  const ConfirmStep({
    required super.key,
    required this.prompt,
    this.defaultValue,
    super.description,
  });

  /// The prompt to display.
  final String prompt;

  /// Default value.
  final bool? defaultValue;

  @override
  Model createModel(Map<String, dynamic> answers) {
    return ConfirmModel(prompt: prompt, defaultValue: defaultValue ?? false);
  }

  @override
  dynamic extractAnswer(Model model) {
    if (model is ConfirmModel) {
      return model.value;
    }
    return null;
  }
}

/// Single-select wizard step.
class SelectStep extends WizardStep {
  /// Creates a select step.
  const SelectStep({
    required super.key,
    required this.prompt,
    required this.options,
    this.defaultIndex,
    super.description,
  });

  /// The prompt to display.
  final String prompt;

  /// Available options.
  final List<String> options;

  /// Default selected index.
  final int? defaultIndex;

  @override
  Model createModel(Map<String, dynamic> answers) {
    return SelectModel<String>(
      items: options,
      title: prompt,
      initialIndex: defaultIndex ?? 0,
    );
  }

  @override
  dynamic extractAnswer(Model model) {
    if (model is SelectModel<String>) {
      return model.selectedItem;
    }
    return null;
  }
}

/// Multi-select wizard step.
class MultiSelectStep extends WizardStep {
  /// Creates a multi-select step.
  const MultiSelectStep({
    required super.key,
    required this.prompt,
    required this.options,
    this.defaultSelected,
    super.description,
  });

  /// The prompt to display.
  final String prompt;

  /// Available options.
  final List<String> options;

  /// Default selected indices.
  final List<int>? defaultSelected;

  @override
  Model createModel(Map<String, dynamic> answers) {
    return MultiSelectModel<String>(
      items: options,
      title: prompt,
      initialSelected: defaultSelected != null
          ? Set.from(defaultSelected!)
          : null,
    );
  }

  @override
  dynamic extractAnswer(Model model) {
    if (model is MultiSelectModel<String>) {
      return model.selectedItems;
    }
    return [];
  }
}

/// Password input wizard step.
class PasswordStep extends WizardStep {
  /// Creates a password step.
  const PasswordStep({
    required super.key,
    required this.prompt,
    this.validate,
    super.description,
  });

  /// The prompt to display.
  final String prompt;

  /// Validation function.
  final ValidateFunc? validate;

  @override
  Model createModel(Map<String, dynamic> answers) {
    final model = PasswordModel(prompt: prompt, validate: validate);
    model.focus();
    return model;
  }

  @override
  dynamic extractAnswer(Model model) {
    if (model is PasswordModel) {
      return model.value;
    }
    return null;
  }
}

/// Conditional wizard step.
class ConditionalStep extends WizardStep {
  /// Creates a conditional step.
  const ConditionalStep({required this.step, required this.condition})
    : super(key: '', description: null);

  /// The step to conditionally show.
  final WizardStep step;

  /// Condition determining whether to show the step.
  final bool Function(Map<String, dynamic>) condition;

  @override
  bool shouldSkip(Map<String, dynamic> answers) => !condition(answers);

  @override
  Model createModel(Map<String, dynamic> answers) => step.createModel(answers);

  @override
  dynamic extractAnswer(Model model) => step.extractAnswer(model);

  @override
  String get key => step.key;

  @override
  String? get description => step.description;
}

/// Group of wizard steps.
class GroupStep extends WizardStep {
  /// Creates a group step.
  const GroupStep({
    required super.key,
    required this.title,
    required this.steps,
    super.description,
  });

  /// Title of the group.
  final String title;

  /// Steps in this group.
  final List<WizardStep> steps;

  @override
  bool shouldSkip(Map<String, dynamic> answers) =>
      steps.every((step) => step.shouldSkip(answers));

  @override
  Model createModel(Map<String, dynamic> answers) {
    // Groups don't have their own model; they're just organizational
    throw UnsupportedError('GroupStep does not have its own model');
  }

  @override
  dynamic extractAnswer(Model model) {
    throw UnsupportedError('GroupStep does not extract answers');
  }
}

/// Wizard model for multi-step forms.
///
/// ## Example
///
/// ```dart
/// final wizard = WizardModel(
///   steps: [
///     WizardStep.textInput(
///       key: 'name',
///       prompt: 'What is your name?',
///     ),
///     WizardStep.confirm(
///       key: 'subscribe',
///       prompt: 'Subscribe to newsletter?',
///     ),
///   ],
/// );
///
/// // In your update function:
/// switch (msg) {
///   case WizardCompletedMsg(:final answers):
///     print('Name: ${answers['name']}');
///     print('Subscribe: ${answers['subscribe']}');
///     return (this, Cmd.quit());
/// }
/// ```
class WizardModel extends ViewComponent {
  /// Creates a wizard model.
  WizardModel({required this.steps, this.title, this.showProgress = true})
    : _answers = {},
      _currentStepIndex = 0,
      _currentModel = null {
    _flattenedSteps = _flattenSteps(steps);
    _initCurrentStep();
  }

  /// The wizard steps.
  final List<WizardStep> steps;

  /// Optional title displayed at the top.
  final String? title;

  /// Whether to show progress (e.g., "Step 2 of 5").
  final bool showProgress;

  // Internal state
  final Map<String, dynamic> _answers;
  late final List<WizardStep> _flattenedSteps;
  int _currentStepIndex;
  Model? _currentModel;

  /// Gets the current answers.
  Map<String, dynamic> get answers => Map.unmodifiable(_answers);

  /// Gets the current step index.
  int get currentStepIndex => _currentStepIndex;

  /// Gets the total number of steps (excluding skipped ones).
  int get totalSteps {
    return _flattenedSteps.where((step) => !step.shouldSkip(_answers)).length;
  }

  /// Gets the current visible step number (1-indexed).
  int get currentVisibleStep {
    int visible = 0;
    for (int i = 0; i <= _currentStepIndex && i < _flattenedSteps.length; i++) {
      if (!_flattenedSteps[i].shouldSkip(_answers)) {
        visible++;
      }
    }
    return visible;
  }

  /// Flattens nested group steps into a single list.
  List<WizardStep> _flattenSteps(List<WizardStep> steps) {
    final flattened = <WizardStep>[];
    for (final step in steps) {
      if (step is GroupStep) {
        flattened.addAll(_flattenSteps(step.steps));
      } else if (step is ConditionalStep) {
        flattened.add(step);
      } else {
        flattened.add(step);
      }
    }
    return flattened;
  }

  /// Initialize the current step's model.
  void _initCurrentStep() {
    // Skip any steps that should be skipped
    while (_currentStepIndex < _flattenedSteps.length &&
        _flattenedSteps[_currentStepIndex].shouldSkip(_answers)) {
      _currentStepIndex++;
    }

    if (_currentStepIndex < _flattenedSteps.length) {
      _currentModel = _flattenedSteps[_currentStepIndex].createModel(_answers);
    }
  }

  /// Move to the next step.
  Cmd? _nextStep() {
    // Save the answer from the current step
    if (_currentModel != null && _currentStepIndex < _flattenedSteps.length) {
      final step = _flattenedSteps[_currentStepIndex];
      final answer = step.extractAnswer(_currentModel!);
      _answers[step.key] = answer;
    }

    _currentStepIndex++;
    _initCurrentStep();

    // Check if wizard is complete
    if (_currentStepIndex >= _flattenedSteps.length) {
      return Cmd.message(WizardCompletedMsg(_answers));
    }

    return null;
  }

  @override
  Cmd? init() {
    // Initialize the first step's model if it has an init
    return _currentModel?.init();
  }

  @override
  (WizardModel, Cmd?) update(Msg msg) {
    // Handle cancel (Escape key)
    if (msg is KeyMsg &&
        keyMatches(msg.key, [
          KeyBinding(
            keys: ['esc'],
            help: Help(key: 'esc', desc: 'cancel'),
          ),
        ])) {
      return (this, Cmd.message(const WizardCancelledMsg()));
    }

    // Text input steps submit on Enter (the underlying TextInputModel is purely
    // an editor; submission is handled at the parent level).
    if (_currentModel is TextInputModel &&
        msg is KeyMsg &&
        msg.key.type == KeyType.enter) {
      final nextCmd = _nextStep();
      return (this, nextCmd);
    }

    // Check for step completion messages
    if (_isStepCompleteMsg(msg)) {
      final nextCmd = _nextStep();
      return (this, nextCmd);
    }

    // Forward message to current step's model
    if (_currentModel != null) {
      final (newModel, cmd) = _currentModel!.update(msg);
      _currentModel = newModel;
      return (this, cmd);
    }

    return (this, null);
  }

  /// Check if a message indicates step completion.
  bool _isStepCompleteMsg(Msg msg) {
    // Check for completion messages from various input models
    return msg is ConfirmResultMsg ||
        msg is SelectionMadeMsg ||
        msg is MultiSelectionMadeMsg ||
        msg is PasswordSubmittedMsg;
  }

  @override
  String view() {
    final buffer = StringBuffer();

    // Title
    if (title != null) {
      buffer.writeln(title);
      buffer.writeln();
    }

    // Progress
    if (showProgress) {
      buffer.writeln('Step $currentVisibleStep of $totalSteps');
      buffer.writeln();
    }

    // Current step description
    if (_currentStepIndex < _flattenedSteps.length) {
      final step = _flattenedSteps[_currentStepIndex];
      if (step.description != null) {
        buffer.writeln(step.description);
        buffer.writeln();
      }
    }

    // Current step view
    if (_currentModel != null) {
      buffer.write(_currentModel!.view());
    }

    return buffer.toString();
  }
}
