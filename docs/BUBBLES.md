# Bubbles Components

Artisanal Bubbles are reusable interactive TUI components. Use them directly via prompt helpers or compose them into larger programs.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Prompt Helpers](#prompt-helpers)
  - [Select and Multi-Select](#select-and-multi-select)
  - [Search and Anticipate](#search-and-anticipate)
  - [Text Area](#text-area)
  - [Password Prompts](#password-prompts)
  - [Wizard](#wizard)
- [Compose in a Program](#compose-in-a-program)
- [Display Components](#display-components)
- [Model Catalog](#model-catalog)
- [Prompt Options](#prompt-options)
- [Gotchas](#gotchas)
- [Related Docs](#related-docs)

## Overview

There are two primary ways to use Bubbles:

1. Prompt helpers for simple, inline prompts.
2. Full TUI programs using `Model`, `Msg`, and `Program`.

## Quick Start

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/terminal.dart';

Future<void> main() async {
  final terminal = StdioTerminal();
  final model = TextInputModel(
    prompt: 'Name: ',
    placeholder: 'Ada Lovelace',
  );

  final value = await runTextInputPrompt(model, terminal);
  terminal.writeln('Hello ${value ?? 'anonymous'}');
}
```

## Prompt Helpers

Prompt helpers run a single bubble and return a value. They are designed to run inline so they work well inside CLI command flows.

### Select and Multi-Select

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/terminal.dart';

Future<void> main() async {
  final terminal = StdioTerminal();

  final choice = await runSelectPrompt(
    SelectModel<String>(
      items: ['alpha', 'beta', 'gamma'],
      title: 'Choose one',
    ),
    terminal,
  );

  final multi = await runMultiSelectPrompt(
    MultiSelectModel<String>(
      items: ['red', 'green', 'blue'],
      title: 'Choose many',
    ),
    terminal,
  );

  terminal.writeln('choice=$choice');
  terminal.writeln('multi=$multi');
}
```

### Search and Anticipate

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/terminal.dart';

Future<void> main() async {
  final terminal = StdioTerminal();

  final result = await runSearchPrompt(
    SearchModel<String>(
      items: ['apple', 'banana', 'cherry'],
      title: 'Search fruit',
    ),
    terminal,
  );

  final anticipated = await runAnticipatePrompt(
    AnticipateModel(
      prompt: 'City: ',
      suggestions: ['Paris', 'London', 'Tokyo'],
    ),
    terminal,
  );

  terminal.writeln('search=$result');
  terminal.writeln('anticipate=$anticipated');
}
```

### Text Area

Text areas run in full-screen mode by default, with `ctrl+s` to submit and `esc` to cancel.

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/terminal.dart';

Future<void> main() async {
  final terminal = StdioTerminal();
  final model = TextAreaModel(placeholder: 'Notes...');

  final value = await runTextAreaPrompt(
    model,
    terminal,
    options: textareaPromptOptions,
  );

  terminal.writeln(value ?? 'No input');
}
```

### Password Prompts

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/terminal.dart';

Future<void> main() async {
  final terminal = StdioTerminal();

  final password = await runPasswordPrompt(
    PasswordModel(prompt: 'Password: '),
    terminal,
  );

  final confirmed = await runPasswordConfirmPrompt(
    PasswordConfirmModel(prompt: 'Confirm: '),
    terminal,
  );

  terminal.writeln('password=$password');
  terminal.writeln('confirm=$confirmed');
}
```

### Wizard

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/terminal.dart';

Future<void> main() async {
  final terminal = StdioTerminal();
  final wizard = WizardModel([
    WizardStep.textInput(key: 'name', prompt: 'Name: '),
    WizardStep.confirm(key: 'confirm', prompt: 'Continue?'),
  ]);

  final result = await runWizardPrompt(wizard, terminal);
  terminal.writeln('result=$result');
}
```

## Compose in a Program

```dart
import 'package:artisanal/tui.dart';
import 'package:artisanal/bubbles.dart';

class DemoModel with ComponentHost implements Model {
  final TextInputModel input;
  final SpinnerModel spinner;

  DemoModel({TextInputModel? input, SpinnerModel? spinner})
    : input = input ?? TextInputModel(prompt: 'Search: '),
      spinner = spinner ?? SpinnerModel();

  @override
  Cmd? init() => spinner.init();

  @override
  (Model, Cmd?) update(Msg msg) {
    final (newInput, inputCmd) = updateComponent(input, msg);
    final (newSpinner, spinnerCmd) = updateComponent(spinner, msg);
    final cmds = <Cmd>[];
    if (inputCmd != null) cmds.add(inputCmd);
    if (spinnerCmd != null) cmds.add(spinnerCmd);
    return (DemoModel(input: newInput, spinner: newSpinner), Cmd.batch(cmds));
  }

  @override
  String view() => '${spinner.view()} ${input.view()}';
}

Future<void> main() async {
  await runProgram(DemoModel());
}
```

## Display Components

Display components are non-interactive renderers (tables, lists, blocks). Use them directly or through `Console.components`.

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/artisanal.dart';

void main() {
  final io = Console();
  final component = BulletList(
    items: ['one', 'two', 'three'],
    bullet: '-',
    renderConfig: io.renderConfig,
  );

  component.writelnTo(io);
}
```

## Model Catalog

- Input: `TextInputModel`, `TextAreaModel`, `PasswordModel`, `PasswordConfirmModel`, `AnticipateModel`
- Selection: `SelectModel`, `MultiSelectModel`, `ListModel`, `SearchModel`, `ConfirmModel`
- Navigation: `ViewportModel`, `TableModel`, `PaginatorModel`, `HelpModel`
- Progress/Time: `SpinnerModel`, `ProgressModel`, `TimerModel`, `StopwatchModel`, `CountdownModel`
- File system: `FilePickerModel`
- Flow: `WizardModel`

## Prompt Options

Prompt helpers accept optional `ProgramOptions`:

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/terminal.dart';
import 'package:artisanal/tui.dart';

Future<void> main() async {
  final terminal = StdioTerminal();
  final options = ProgramOptions(altScreen: false, fps: 30);

  final value = await runTextInputPrompt(
    TextInputModel(prompt: 'Value: '),
    terminal,
    options: options,
  );

  terminal.writeln('value=$value');
}
```

Use `textareaPromptOptions` for full-screen editing and `promptProgramOptions` for inline prompts.

## Gotchas

- Prompt helpers return `null` on cancel; handle `null` explicitly.
- Text area prompts use `ctrl+s` to submit and `esc` to cancel by default.
- `RenderConfig` should match terminal width for display components.

## Related Docs

- [DOCS_INDEX.md](DOCS_INDEX.md) - Full documentation index
- [TUI.md](TUI.md)
- [IO_COMPONENTS.md](IO_COMPONENTS.md)
