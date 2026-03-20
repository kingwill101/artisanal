/// Stable editor and text-input entrypoint for terminal widget apps.
///
/// Prefer this library when you want the supported text editing surface
/// without importing the full widget namespace:
///
/// - `TextField` / `TextEditingController`
/// - `TextArea` / `TextAreaController`
/// - `TextDiagnosticsBinding`
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
        SelectableTextFieldView,
        SelectableTextAreaView,
        TextField,
        TextArea;
export 'src/widgets/input/text_diagnostics_binding.dart'
    show TextDiagnosticsBinding, TextDiagnosticsBuilder;
export 'src/widgets/input/text_decoration_binding.dart'
    show
        TextDecorationLayerBinding,
        TextDecorationLayerBuilder,
        TextLineDecorationLayerBinding,
        TextLineDecorationLayerBuilder;
export 'package:artisanal/bubbles.dart'
    show
        TextInputKeyMap,
        TextAreaKeyMap,
        TextDecorationRange,
        TextLineDecoration,
        TextDiagnosticSeverity,
        TextDiagnosticRange,
        TextPositionDiagnosticRange,
        TextPatternDiagnosticRule,
        textPatternDiagnostics;
export 'src/widgets/components/components_widgets.dart'
    show TextEditor, CodeEditor, MarkdownEditor;
