/// Stable editor and text-input entrypoint for terminal widget apps.
///
/// Prefer this library when you want the supported text editing surface
/// without importing the full widget namespace:
///
/// - `TextField` / `TextEditingController`
/// - `TextArea` / `TextAreaController`
/// - `TextInputKeyMap` / `TextAreaKeyMap`
/// - `TextEditor`
/// - `CodeEditor`
/// - `MarkdownEditor`
library;

export 'src/widgets/input/input_widgets.dart'
    show
        TextChangedCallback,
        TextSelection,
        TextEditingValue,
        TextEditingController,
        TextFieldController,
        TextAreaController,
        TextField,
        TextArea;
export 'package:artisanal/bubbles.dart' show TextInputKeyMap, TextAreaKeyMap;
export 'src/widgets/components/components_widgets.dart'
    show TextEditor, CodeEditor, MarkdownEditor;
