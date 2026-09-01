library;

import 'package:artisanal/runtime.dart'
    show
        Cmd,
        Msg,
        KeyMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        HitTestMouseMsg,
        View,
        TuiTrace;
import 'package:artisanal/style.dart' show Layout, Style;
import '../animation/animated_builder.dart' show ListenableBuilder;
import '../animation/listenable.dart' show ChangeNotifier, ValueListenable;
import '../focus/focus.dart' show FocusController, FocusScope;
import '../core/framework.dart'
    show BuildContext, State, StatefulWidget, StatelessWidget;
import '../layout/_layout_core.dart' show Text, TextAlign, TextOverflow;
import '../rendering/render_object.dart'
    show LeafRenderObjectWidget, RenderBox, RenderObject;
import '../layout/geometry.dart' show BoxConstraints, Size;
import '../selection/selection.dart' show SelectableView, SelectionController;
import '../theme/theme.dart' show Theme, currentTheme;
import '../theme/theme_scope.dart' show ThemeScope;
import '../core/widget.dart';
import 'package:artisanal/text_editing.dart'
    show
        EchoMode,
        TextCommandResult,
        TextAreaCursorStyle,
        TextAreaKeyMap,
        TextCursorCommandResult,
        TextLineCommandResult,
        TextAreaModel,
        TextAreaStyleState,
        TextAreaStyles,
        TextDocument,
        TextDocumentChange,
        TextInputCursorStyle,
        TextInputKeyMap,
        TextInputModel,
        TextInputStyleState,
        TextInputStyles,
        CursorModel,
        CursorMode,
        TextDecorationRange,
        TextDiagnosticRange,
        TextPositionDiagnosticRange,
        TextLineDecoration,
        textActiveLineDecorationKey,
        textActiveLineNumberDecorationKey,
        textDefaultDecorationLayerPriority,
        textDefaultLineDecorationLayerPriority,
        textDiagnosticErrorDecorationKey,
        textDiagnosticErrorLineDecorationKey,
        textDiagnosticErrorLineNumberDecorationKey,
        textDiagnosticHintDecorationKey,
        textDiagnosticHintLineDecorationKey,
        textDiagnosticHintLineNumberDecorationKey,
        textDiagnosticInfoDecorationKey,
        textDiagnosticInfoLineDecorationKey,
        textDiagnosticInfoLineNumberDecorationKey,
        textDiagnosticWarningDecorationKey,
        textDiagnosticWarningLineDecorationKey,
        textDiagnosticWarningLineNumberDecorationKey,
        textSearchActiveMatchDecorationKey,
        textSearchMatchDecorationKey;
import 'package:artisanal/uv.dart' show CursorShape;

/// Signature for text change notifications from [TextField].
typedef TextChangedCallback = void Function(String value);

/// Range of text that is selected.
class TextSelection {
  /// Creates a selection between [baseOffset] and [extentOffset].
  const TextSelection({required this.baseOffset, required this.extentOffset});

  /// Creates a collapsed selection at [offset].
  const TextSelection.collapsed({required int offset})
    : baseOffset = offset,
      extentOffset = offset;

  /// Anchor position for this selection.
  final int baseOffset;

  /// Active edge position for this selection.
  final int extentOffset;

  /// Whether this selection has no selected range.
  bool get isCollapsed => baseOffset == extentOffset;

  /// The smaller of [baseOffset] and [extentOffset].
  int get start => baseOffset < extentOffset ? baseOffset : extentOffset;

  /// The larger of [baseOffset] and [extentOffset].
  int get end => baseOffset < extentOffset ? extentOffset : baseOffset;

  /// Returns a copy with optional overrides.
  TextSelection copyWith({int? baseOffset, int? extentOffset}) {
    return TextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSelection &&
        other.baseOffset == baseOffset &&
        other.extentOffset == extentOffset;
  }

  @override
  int get hashCode => Object.hash(baseOffset, extentOffset);
}

/// The current state of a text field.
class TextEditingValue {
  /// Creates a text editing value.
  const TextEditingValue({
    this.text = '',
    this.selection = const TextSelection.collapsed(offset: 0),
  });

  /// Current plain-text value.
  final String text;

  /// Current selection range.
  final TextSelection selection;

  /// Empty value with collapsed selection at offset 0.
  static const empty = TextEditingValue();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextEditingValue &&
        other.text == text &&
        other.selection == selection;
  }

  @override
  int get hashCode => Object.hash(text, selection);
}

/// Controls the state of a [TextField].
///
/// Whenever the user modifies a text field with an associated
/// [TextEditingController], the text field updates [model] and the controller
/// notifies its listeners.
class TextEditingController extends ChangeNotifier
    implements ValueListenable<TextEditingValue> {
  TextEditingController({String? text, TextInputModel? model})
    : _model =
          model ??
          TextInputModel(cursor: CursorModel(mode: CursorMode.static)) {
    if (text != null) {
      _model.value = text;
    }
  }

  TextInputModel _model;

  /// The current [TextInputModel] managed by this controller.
  TextInputModel get model => _model;

  /// Sets the model and notifies listeners.
  set model(TextInputModel next) {
    if (identical(_model, next)) return;
    _model = next;
    notifyListeners();
  }

  /// The current text being edited.
  String get text => _model.value;

  /// Sets the text and notifies listeners.
  set text(String value) {
    if (_model.value == value) return;
    _model.setText(value);
    notifyListeners();
  }

  /// The current selection.
  TextSelection get selection => TextSelection(
    baseOffset: _model.selectionStart ?? _model.position,
    extentOffset: _model.selectionEnd ?? _model.position,
  );

  /// Sets the selection and notifies listeners.
  set selection(TextSelection value) {
    if (selection == value) return;
    if (value.isCollapsed) {
      _model.selectionStart = null;
      _model.selectionEnd = null;
    } else {
      _model.selectionStart = value.baseOffset;
      _model.selectionEnd = value.extentOffset;
    }
    _model.position = value.extentOffset;
    notifyListeners();
  }

  @override
  TextEditingValue get value =>
      TextEditingValue(text: text, selection: selection);

  /// Sets the value and notifies listeners.
  set value(TextEditingValue newValue) {
    if (value == newValue) return;
    _model.setTextState(
      text: newValue.text,
      selectionBase: newValue.selection.baseOffset,
      selectionExtent: newValue.selection.extentOffset,
    );
    notifyListeners();
  }

  /// Updates the model using the provided [msg].
  ///
  /// Returns the [Cmd] produced by the model update.
  Cmd? update(Msg msg) {
    final (next, cmd) = _model.update(msg);
    if (!identical(next, _model)) {
      _model = next;
      notifyListeners();
    }
    return cmd;
  }

  /// Clears the text.
  void clear() {
    value = TextEditingValue.empty;
  }

  /// Selects all text.
  void selectAll() {
    _model.selectAll();
    notifyListeners();
  }

  /// Starts a fresh undo step for the next edit.
  void pushHistoryBoundary() {
    _model.pushHistoryBoundary();
  }

  /// Inserts [text] at the cursor, optionally replacing the selection.
  void insertText(
    String text, {
    bool replaceSelection = true,
    bool coalesce = false,
  }) {
    _model.insertText(
      text,
      replaceSelection: replaceSelection,
      coalesce: coalesce,
    );
    notifyListeners();
  }

  /// Replaces the current selection, or inserts at the cursor if collapsed.
  void replaceSelection(String text) {
    _model.replaceSelection(text);
    notifyListeners();
  }

  /// Deletes the current selection.
  bool deleteSelection() {
    final changed = _model.deleteSelection();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Deletes backward from the cursor or removes the current selection.
  bool deleteBackward({bool word = false, bool coalesce = false}) {
    final changed = _model.deleteBackward(word: word, coalesce: coalesce);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Deletes forward from the cursor or removes the current selection.
  bool deleteForward({bool word = false, bool coalesce = false}) {
    final changed = _model.deleteForward(word: word, coalesce: coalesce);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Whether there is an edit available to undo.
  bool get canUndo => _model.canUndo;

  /// Whether there is an undone edit available to redo.
  bool get canRedo => _model.canRedo;

  /// Restores the previous edit state and notifies listeners.
  bool undo() {
    final changed = _model.undo();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Reapplies the most recently undone edit state and notifies listeners.
  bool redo() {
    final changed = _model.redo();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Clears all undo and redo history.
  void clearHistory() {
    _model.clearHistory();
  }
}

/// Alias for [TextEditingController] for backward compatibility.
typedef TextFieldController = TextEditingController;

String _modelViewString(Object view) {
  if (view is String) return view;
  if (view is View) return view.content;
  return view.toString();
}

TextInputStyles _textInputStylesFromTheme(Theme theme) {
  final selection = Style()
      .background(theme.resolvedHighlight)
      .foreground(theme.resolvedOnHighlight);
  return TextInputStyles(
    focused: TextInputStyleState(
      prompt: theme.labelLarge.copy().foreground(theme.onBackground),
      text: theme.bodyMedium.copy().foreground(theme.onBackground),
      placeholder: theme.labelSmall.copy().foreground(theme.muted),
      suggestion: theme.labelSmall.copy(),
      selection: selection,
    ),
    blurred: TextInputStyleState(
      prompt: theme.labelSmall.copy().foreground(theme.onBackground),
      text: theme.bodySmall.copy().foreground(theme.onBackground),
      placeholder: theme.labelSmall.copy().foreground(theme.muted),
      suggestion: theme.labelSmall.copy(),
      selection: selection,
    ),
    cursor: TextInputCursorStyle(
      color: theme.primary,
      shape: CursorShape.block,
      blink: false,
    ),
  );
}

TextAreaStyles textAreaStylesFromTheme(Theme theme) {
  final editorTheme = theme.editorTheme;
  final selection = Style()
      .background(theme.resolvedHighlight)
      .foreground(theme.resolvedOnHighlight);
  final focusedPrompt = theme.labelLarge.copy()
    ..foreground(editorTheme?.focusedPromptForeground ?? theme.onSurface)
    ..bold();
  final focusedText = theme.bodyMedium.copy().foreground(
    editorTheme?.focusedTextForeground ?? theme.onSurface,
  );
  final focusedPlaceholder = theme.labelMedium.copy().foreground(
    editorTheme?.focusedPlaceholderForeground ?? theme.resolvedOnSurfaceVariant,
  );
  final focusedLineNumber = theme.labelMedium.copy().foreground(
    editorTheme?.focusedLineNumberForeground ?? theme.resolvedOutline,
  );
  final blurredPrompt = theme.labelMedium.copy().foreground(
    editorTheme?.blurredPromptForeground ?? theme.resolvedOnSurfaceVariant,
  );
  final blurredText = theme.bodyMedium.copy().foreground(
    editorTheme?.blurredTextForeground ?? theme.resolvedOnSurfaceVariant,
  );
  final blurredPlaceholder = theme.labelSmall.copy()
    ..foreground(editorTheme?.blurredPlaceholderForeground ?? theme.muted);
  final blurredLineNumber = theme.labelSmall.copy().foreground(
    editorTheme?.blurredLineNumberForeground ?? theme.resolvedOutline,
  );
  final searchMatch = Style()
      .background(
        editorTheme?.searchMatchBackground ?? theme.resolvedSurfaceVariant,
      )
      .underline()
      .underlineColor(editorTheme?.searchMatchUnderlineColor ?? theme.primary);
  final errorLineNumber = theme.labelSmall.copy().foreground(theme.error);
  final warningLineNumber = theme.labelSmall.copy().foreground(theme.warning);
  final infoLineNumber = theme.labelSmall.copy().foreground(theme.resolvedInfo);
  final hintLineNumber = theme.labelSmall.copy().foreground(theme.muted);
  return TextAreaStyles(
    focused: TextAreaStyleState(
      decorationStyles: <String, Style>{
        textSearchMatchDecorationKey: searchMatch,
        textSearchActiveMatchDecorationKey: Style()
            .background(theme.resolvedHighlight)
            .foreground(theme.resolvedOnHighlight),
        textDiagnosticErrorDecorationKey: Style().underline().underlineColor(
          theme.error,
        ),
        textDiagnosticWarningDecorationKey: Style().underline().underlineColor(
          theme.warning,
        ),
        textDiagnosticInfoDecorationKey: Style().underline().underlineColor(
          theme.resolvedInfo,
        ),
        textDiagnosticHintDecorationKey: Style().underline().underlineColor(
          theme.muted,
        ),
      },
      lineDecorationStyles: <String, Style>{
        textActiveLineDecorationKey: Style().background(
          theme.resolvedSurfaceVariant,
        ),
        textActiveLineNumberDecorationKey: theme.labelSmall.copy().foreground(
          theme.primary,
        ),
        textDiagnosticErrorLineDecorationKey: Style(),
        textDiagnosticWarningLineDecorationKey: Style(),
        textDiagnosticInfoLineDecorationKey: Style(),
        textDiagnosticHintLineDecorationKey: Style(),
        textDiagnosticErrorLineNumberDecorationKey: errorLineNumber,
        textDiagnosticWarningLineNumberDecorationKey: warningLineNumber,
        textDiagnosticInfoLineNumberDecorationKey: infoLineNumber,
        textDiagnosticHintLineNumberDecorationKey: hintLineNumber,
      },
      prompt: focusedPrompt,
      text: focusedText,
      placeholder: focusedPlaceholder,
      lineNumber: focusedLineNumber,
      cursorLine: Style().background(
        editorTheme?.focusedCursorLineBackground ??
            theme.resolvedSurfaceVariant,
      ),
      cursorLineNumber: theme.labelMedium.copy()
        ..foreground(
          editorTheme?.focusedCursorLineNumberForeground ?? theme.primary,
        )
        ..bold(),
      endOfBuffer: theme.labelSmall.copy().foreground(theme.resolvedOutline),
      selection: selection,
    ),
    blurred: TextAreaStyleState(
      decorationStyles: <String, Style>{
        textSearchMatchDecorationKey: searchMatch,
        textSearchActiveMatchDecorationKey: Style()
            .background(theme.resolvedHighlight)
            .foreground(theme.resolvedOnHighlight),
        textDiagnosticErrorDecorationKey: Style().underline().underlineColor(
          theme.error,
        ),
        textDiagnosticWarningDecorationKey: Style().underline().underlineColor(
          theme.warning,
        ),
        textDiagnosticInfoDecorationKey: Style().underline().underlineColor(
          theme.resolvedInfo,
        ),
        textDiagnosticHintDecorationKey: Style().underline().underlineColor(
          theme.muted,
        ),
      },
      lineDecorationStyles: <String, Style>{
        textActiveLineDecorationKey: Style().background(
          editorTheme?.blurredCursorLineBackground ??
              theme.resolvedSurfaceVariant,
        ),
        textActiveLineNumberDecorationKey: theme.labelSmall.copy().foreground(
          theme.primary,
        ),
        textDiagnosticErrorLineDecorationKey: Style(),
        textDiagnosticWarningLineDecorationKey: Style(),
        textDiagnosticInfoLineDecorationKey: Style(),
        textDiagnosticHintLineDecorationKey: Style(),
        textDiagnosticErrorLineNumberDecorationKey: errorLineNumber,
        textDiagnosticWarningLineNumberDecorationKey: warningLineNumber,
        textDiagnosticInfoLineNumberDecorationKey: infoLineNumber,
        textDiagnosticHintLineNumberDecorationKey: hintLineNumber,
      },
      prompt: blurredPrompt,
      text: blurredText,
      placeholder: blurredPlaceholder,
      lineNumber: blurredLineNumber,
      cursorLine: Style().background(
        editorTheme?.blurredCursorLineBackground ??
            theme.resolvedSurfaceVariant,
      ),
      cursorLineNumber: blurredLineNumber.copy()
        ..foreground(
          editorTheme?.blurredCursorLineNumberForeground ??
              theme.resolvedOutline,
        ),
      endOfBuffer: theme.labelSmall.copy().foreground(theme.resolvedOutline),
      selection: selection,
    ),
    cursor: TextAreaCursorStyle(
      color: theme.primary,
      shape: CursorShape.block,
      blink: false,
    ),
  );
}

/// Controls the state of a [TextArea].
class TextAreaController extends ChangeNotifier
    implements ValueListenable<String> {
  TextAreaController({String? text, TextAreaModel? model})
    : _model = model ?? TextAreaModel() {
    if (text != null) {
      _model.value = text;
    }
  }

  TextAreaModel _model;

  /// The underlying textarea model.
  TextAreaModel get model => _model;
  set model(TextAreaModel value) {
    if (identical(_model, value)) return;
    _model = value;
    notifyListeners();
  }

  /// Current plain-text value.
  @override
  String get value => text;

  /// Current plain-text value.
  String get text => _model.value;
  set text(String value) {
    if (_model.value == value) return;
    _model.value = value;
    notifyListeners();
  }

  /// Current cursor line.
  int get line => _model.line;

  /// Current cursor column.
  int get column => _model.column;

  /// Whether the textarea is focused.
  bool get focused => _model.focused;

  /// Whether there is a non-collapsed selection.
  bool get hasSelection => _model.hasSelection;

  /// Anchor position of the current selection, if any.
  ({int line, int column})? get selectionBase => _model.selectionBase;

  /// Active extent position of the current selection, if any.
  ({int line, int column})? get selectionExtent => _model.selectionExtent;

  /// Current selected text, if any.
  String get selectedText => _model.getSelectedText();

  /// Current non-selection decoration ranges in flat document offsets.
  TextDocument get document => _model.document;
  List<TextDiagnosticRange> get diagnostics => _model.diagnostics;
  TextDiagnosticRange? get activeDiagnostic => _model.activeDiagnostic;
  List<TextDecorationRange> get decorations => _model.decorations;
  List<TextLineDecoration> get lineDecorations => _model.lineDecorations;
  List<TextDecorationRange> decorationsForLayer(String layerKey) {
    return _model.decorationsForLayer(layerKey);
  }

  List<TextLineDecoration> lineDecorationsForLayer(String layerKey) {
    return _model.lineDecorationsForLayer(layerKey);
  }

  /// Returns and clears the most recent document-aware text change, if any.
  TextDocumentChange? consumeLastDocumentChange() {
    return _model.consumeLastDocumentChange();
  }

  /// Applies an offset-based editor-core command result.
  void applyTextCommandResult(
    TextCommandResult result, {
    bool pushHistoryBoundary = true,
  }) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.applyTextCommandResult(
      result,
      pushHistoryBoundary: pushHistoryBoundary,
    );
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Applies an offset-cursor editor-core command result.
  void applyTextCursorCommandResult(
    TextCursorCommandResult result, {
    bool pushHistoryBoundary = true,
  }) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.applyTextCursorCommandResult(
      result,
      pushHistoryBoundary: pushHistoryBoundary,
    );
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Applies a line-based editor-core command result.
  void applyTextLineCommandResult(
    TextLineCommandResult result, {
    bool pushHistoryBoundary = true,
  }) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.applyTextLineCommandResult(
      result,
      pushHistoryBoundary: pushHistoryBoundary,
    );
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Whether there is an edit available to undo.
  bool get canUndo => _model.canUndo;

  /// Whether there is an undone edit available to redo.
  bool get canRedo => _model.canRedo;

  /// Replaces the text content and resets the cursor to the end.
  void clear() {
    _model.reset();
    notifyListeners();
  }

  /// Clears all undo and redo history.
  void clearHistory() {
    _model.clearHistory();
  }

  /// Starts a fresh undo step for the next edit.
  void pushHistoryBoundary() {
    _model.pushHistoryBoundary();
  }

  /// Sets the cursor location.
  void setCursor(int row, int col) {
    final beforeLine = _model.line;
    final beforeColumn = _model.column;
    _model.setCursor(row, col);
    if (beforeLine != _model.line || beforeColumn != _model.column) {
      notifyListeners();
    }
  }

  /// Sets a multi-line selection and places the cursor at the extent.
  void setSelection({
    required int baseLine,
    required int baseColumn,
    required int extentLine,
    required int extentColumn,
  }) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.setSelection(
      baseLine: baseLine,
      baseColumn: baseColumn,
      extentLine: extentLine,
      extentColumn: extentColumn,
    );
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Clears the current selection.
  void clearSelection() {
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.clearSelection();
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Selects the entire textarea contents.
  void selectAll() {
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.selectAll();
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Selects the current line, or expands the current selection to full lines.
  void selectCurrentLine() {
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.selectCurrentLine();
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Inserts text at the current cursor location.
  void insertText(String text) {
    if (text.isEmpty) return;
    final before = _TextAreaControllerSnapshot.capture(_model);
    _model.insertString(text);
    if (!before.matches(_model)) {
      notifyListeners();
    }
  }

  /// Applies document decoration ranges used for search or other overlays.
  void setDecorations(Iterable<TextDecorationRange> decorations) {
    final changed = _model.setDecorations(decorations);
    if (changed) {
      notifyListeners();
    }
  }

  /// Applies decoration ranges to a named layer.
  void setDecorationLayer(
    String layerKey,
    Iterable<TextDecorationRange> decorations, {
    int priority = textDefaultDecorationLayerPriority,
  }) {
    final changed = _model.setDecorationLayer(
      layerKey,
      decorations,
      priority: priority,
    );
    if (changed) {
      notifyListeners();
    }
  }

  /// Clears non-selection decoration ranges.
  void clearDecorations() {
    final changed = _model.clearDecorations();
    if (changed) {
      notifyListeners();
    }
  }

  /// Clears one named decoration layer.
  void clearDecorationLayer(String layerKey) {
    final changed = _model.clearDecorationLayer(layerKey);
    if (changed) {
      notifyListeners();
    }
  }

  /// Applies typed diagnostic range and line overlays.
  void setDiagnostics(Iterable<TextDiagnosticRange> diagnostics) {
    final changed = _model.setDiagnostics(diagnostics);
    if (changed) {
      notifyListeners();
    }
  }

  /// Applies typed diagnostic overlays from line/column positions.
  void setDiagnosticsFromPositions(
    Iterable<TextPositionDiagnosticRange> diagnostics,
  ) {
    final changed = _model.setDiagnosticsFromPositions(diagnostics);
    if (changed) {
      notifyListeners();
    }
  }

  /// Clears typed diagnostic overlays.
  void clearDiagnostics() {
    final changed = _model.clearDiagnostics();
    if (changed) {
      notifyListeners();
    }
  }

  /// Selects the next diagnostic range.
  bool selectNextDiagnostic({bool wrap = true}) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    final changed = _model.selectNextDiagnostic(wrap: wrap);
    if (changed && !before.matches(_model)) {
      notifyListeners();
    }
    return changed;
  }

  /// Selects the previous diagnostic range.
  bool selectPreviousDiagnostic({bool wrap = true}) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    final changed = _model.selectPreviousDiagnostic(wrap: wrap);
    if (changed && !before.matches(_model)) {
      notifyListeners();
    }
    return changed;
  }

  /// Selects the diagnostic that covers [lineIndex], if any.
  bool selectDiagnosticAtLine(int lineIndex) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    final changed = _model.selectDiagnosticAtLine(lineIndex);
    if (changed && !before.matches(_model)) {
      notifyListeners();
    }
    return changed;
  }

  /// Applies whole-line decorations to the default line layer.
  void setLineDecorations(Iterable<TextLineDecoration> decorations) {
    final changed = _model.setLineDecorations(decorations);
    if (changed) {
      notifyListeners();
    }
  }

  /// Applies whole-line decorations to a named layer.
  void setLineDecorationLayer(
    String layerKey,
    Iterable<TextLineDecoration> decorations, {
    int priority = textDefaultLineDecorationLayerPriority,
  }) {
    final changed = _model.setLineDecorationLayer(
      layerKey,
      decorations,
      priority: priority,
    );
    if (changed) {
      notifyListeners();
    }
  }

  /// Clears whole-line decorations across all layers.
  void clearLineDecorations() {
    final changed = _model.clearLineDecorations();
    if (changed) {
      notifyListeners();
    }
  }

  /// Clears one named whole-line decoration layer.
  void clearLineDecorationLayer(String layerKey) {
    final changed = _model.clearLineDecorationLayer(layerKey);
    if (changed) {
      notifyListeners();
    }
  }

  /// Focuses the textarea.
  Cmd? focus() {
    final cmd = _model.focus();
    notifyListeners();
    return cmd;
  }

  /// Blurs the textarea.
  void blur() {
    if (!_model.focused) return;
    _model.blur();
    notifyListeners();
  }

  /// Restores the previous edit state.
  bool undo() {
    final changed = _model.undo();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Reapplies the most recently undone edit state.
  bool redo() {
    final changed = _model.redo();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Indents the selected lines, or the current line if there is no selection.
  bool indentLines({int width = 2}) {
    final changed = _model.indentLines(width: width);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Outdents the selected lines, or the current line if there is no selection.
  bool outdentLines({int width = 2}) {
    final changed = _model.outdentLines(width: width);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Moves the selected lines, or the current line, one row upward.
  bool moveLinesUp() {
    final changed = _model.moveLinesUp();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Moves the selected lines, or the current line, one row downward.
  bool moveLinesDown() {
    final changed = _model.moveLinesDown();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Duplicates the selected lines, or the current line, above the current
  /// block.
  bool duplicateLinesAbove() {
    final changed = _model.duplicateLinesAbove();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Duplicates the selected lines, or the current line, below the current
  /// block.
  bool duplicateLinesBelow() {
    final changed = _model.duplicateLinesBelow();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Cleans up trailing horizontal whitespace in the selected block, or the
  /// entire buffer when there is no selection.
  bool cleanupWhitespace({bool trimTrailingBlankLines = true}) {
    final changed = _model.cleanupWhitespace(
      trimTrailingBlankLines: trimTrailingBlankLines,
    );
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Deletes the selected lines, or the current line if there is no selection.
  bool deleteLines() {
    final changed = _model.deleteLines();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Joins the current line with the next line, or joins the selected block
  /// into a single line.
  bool joinLines() {
    final changed = _model.joinLines();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Splits the current line at the cursor, or replaces the current
  /// selection with a newline.
  bool splitLine() {
    final changed = _model.splitLine();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Uppercases the selected range, or the current line when there is no
  /// selection.
  bool uppercaseSelectionOrLine() {
    final changed = _model.uppercaseSelectionOrLine();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Lowercases the selected range, or the current line when there is no
  /// selection.
  bool lowercaseSelectionOrLine() {
    final changed = _model.lowercaseSelectionOrLine();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Capitalizes words in the selected range, or the current line when there
  /// is no selection.
  bool capitalizeSelectionOrLine() {
    final changed = _model.capitalizeSelectionOrLine();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Sorts the selected lines, or the entire buffer when there is no
  /// selection.
  bool sortSelectedLines({
    bool descending = false,
    bool caseSensitive = false,
  }) {
    final changed = _model.sortSelectedLines(
      descending: descending,
      caseSensitive: caseSensitive,
    );
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Toggles [prefix] on the current line or selected block.
  bool toggleLinePrefix(
    String prefix, {
    bool addSpaceWhenNonEmpty = true,
    bool skipBlankLinesWhenChecking = true,
  }) {
    final changed = _model.toggleLinePrefix(
      prefix,
      addSpaceWhenNonEmpty: addSpaceWhenNonEmpty,
      skipBlankLinesWhenChecking: skipBlankLinesWhenChecking,
    );
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Toggles numbered list prefixes on the current line or selected block.
  bool toggleNumberedList({int startAt = 1}) {
    final changed = _model.toggleNumberedList(startAt: startAt);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Renumbers existing numbered list items in the current line or selected
  /// block.
  bool renumberNumberedList({int startAt = 1}) {
    final changed = _model.renumberNumberedList(startAt: startAt);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Toggles Markdown heading prefixes on the current line or selected block.
  bool toggleHeadingPrefix({int level = 1}) {
    final changed = _model.toggleHeadingPrefix(level: level);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Toggles checklist completion state on the current line or selected block.
  bool toggleChecklistState({String checkedMarker = 'x'}) {
    final changed = _model.toggleChecklistState(checkedMarker: checkedMarker);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Wraps the current selection with [before] and [after].
  ///
  /// If [after] is omitted, [before] is used for both sides.
  bool wrapSelection(String before, {String? after}) {
    final changed = _model.wrapSelection(before, after: after);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Removes a matching surrounding delimiter pair around the current
  /// selection.
  bool unwrapSelection() {
    final changed = _model.unwrapSelection();
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  /// Forwards a message to the textarea model.
  Cmd? update(Msg msg) {
    final before = _TextAreaControllerSnapshot.capture(_model);
    final (_, cmd) = _model.update(msg);
    if (!before.matches(_model)) {
      notifyListeners();
    }
    return cmd;
  }
}

class _TextAreaControllerSnapshot {
  const _TextAreaControllerSnapshot({
    required this.text,
    required this.line,
    required this.column,
    required this.focused,
    required this.hasSelection,
    required this.selectionBase,
    required this.selectionExtent,
    required this.selectedText,
  });

  final String text;
  final int line;
  final int column;
  final bool focused;
  final bool hasSelection;
  final ({int line, int column})? selectionBase;
  final ({int line, int column})? selectionExtent;
  final String selectedText;

  static _TextAreaControllerSnapshot capture(TextAreaModel model) {
    return _TextAreaControllerSnapshot(
      text: model.value,
      line: model.line,
      column: model.column,
      focused: model.focused,
      hasSelection: model.hasSelection,
      selectionBase: model.selectionBase,
      selectionExtent: model.selectionExtent,
      selectedText: model.getSelectedText(),
    );
  }

  bool matches(TextAreaModel model) {
    return text == model.value &&
        line == model.line &&
        column == model.column &&
        focused == model.focused &&
        hasSelection == model.hasSelection &&
        selectionBase == model.selectionBase &&
        selectionExtent == model.selectionExtent &&
        selectedText == model.getSelectedText();
  }
}

/// A read-only selectable view of a [TextEditingController].
///
/// This bridges controller-backed editor content into [SelectionArea] without
/// participating in the live editing selection model.
class SelectableTextFieldView extends StatelessWidget {
  SelectableTextFieldView({
    required this.controller,
    this.selectionController,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    super.key,
  });

  final TextEditingController controller;
  final SelectionController? selectionController;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        return SelectableView(
          _modelViewString(controller.model.view()),
          controller: selectionController,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxWidth: maxWidth,
        );
      },
    );
  }
}

/// A read-only selectable view of a [TextAreaController].
///
/// This exposes textarea-backed content to [SelectionArea] as a shared
/// selectable fragment while keeping editing selection and focus separate.
class SelectableTextAreaView extends StatelessWidget {
  SelectableTextAreaView({
    required this.controller,
    this.selectionController,
    this.textAlign = TextAlign.left,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxWidth,
    super.key,
  });

  final TextAreaController controller;
  final SelectionController? selectionController;
  final TextAlign textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        return SelectableView(
          _modelViewString(controller.model.view()),
          controller: selectionController,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxWidth: maxWidth,
        );
      },
    );
  }
}

/// A text input widget supporting single-line and multi-line editing.
///
/// This wraps [TextInputModel] and integrates with [FocusController] so
/// keyboard input is handled only when focused. Mouse presses are handled
/// inside the input zone for cursor positioning and selection.
///
/// For multi-line editing, set [multiline] to `true` and provide a [width]
/// for soft-wrapping. Optionally set [maxLines] to limit the visible height
/// and enable vertical scrolling.
class TextField extends StatefulWidget {
  TextField({
    this.model,
    this.controller,
    this.prompt,
    this.placeholder,
    this.width,
    this.echoMode,
    this.echoCharacter,
    this.charLimit,
    this.showSuggestions,
    this.suggestions,
    this.collapseLargePaste,
    this.collapsedPasteMinChars,
    this.collapsedPasteMinLines,
    this.useVirtualCursor,
    this.styles,
    this.keyMap,
    this.cursor,
    this.onChanged,
    this.focusController,
    this.focusId,
    this.autofocus = false,
    this.enabled = true,
    this.multiline = false,
    this.maxLines = 0,
    this.mouseXOffset = 0,
    this.zoneId,
    super.key,
  });

  /// Optional model to use for input behavior.
  final TextInputModel? model;

  /// Optional controller to hold input state.
  final TextFieldController? controller;

  /// Prompt displayed before input.
  final String? prompt;

  /// Placeholder text when empty.
  final String? placeholder;

  /// Display width for horizontal scrolling (0 = unlimited).
  final int? width;

  /// Echo mode for displaying text.
  final EchoMode? echoMode;

  /// Character to show in password mode.
  final String? echoCharacter;

  /// Maximum characters allowed (0 = unlimited).
  final int? charLimit;

  /// Whether to show suggestions.
  final bool? showSuggestions;

  /// Suggestions for autocomplete.
  final List<String>? suggestions;

  /// Whether to collapse large pasted content into a compact reference token.
  final bool? collapseLargePaste;

  /// Minimum paste size in characters to collapse.
  final int? collapsedPasteMinChars;

  /// Minimum paste size in lines to collapse.
  final int? collapsedPasteMinLines;

  /// Whether to render a virtual cursor.
  final bool? useVirtualCursor;

  /// Styles used for focused/blurred input.
  final TextInputStyles? styles;

  /// Optional key bindings.
  final TextInputKeyMap? keyMap;

  /// Optional cursor model. Defaults to a static cursor.
  final CursorModel? cursor;

  /// Called when the value changes.
  final TextChangedCallback? onChanged;

  /// Optional focus controller for focus coordination.
  final FocusController? focusController;

  /// Optional focus identifier.
  final String? focusId;

  /// Whether to request focus on first build.
  final bool autofocus;

  /// Whether input is enabled.
  final bool enabled;

  /// Whether to enable multi-line editing.
  ///
  /// When `true`, Enter/Shift+Enter inserts newlines, text soft-wraps at
  /// [width], and Up/Down arrows navigate between lines.
  final bool multiline;

  /// Maximum visible height in rows (0 = unlimited growth).
  ///
  /// Only used when [multiline] is `true`. When the number of wrapped lines
  /// exceeds this value, vertical scrolling is enabled.
  final int maxLines;

  /// Optional horizontal offset correction (in cells) applied to mouse hit
  /// coordinates before they are forwarded to [TextInputModel].
  ///
  /// Useful when embedding the field in composite panes that add visual left
  /// chrome around the editable content.
  final int mouseXOffset;

  /// Optional zone id for mouse interactions.
  final String? zoneId;

  @override
  State createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField> {
  TextEditingController? _internalController;
  TextEditingController get _controller =>
      widget.controller ??
      (_internalController ??= TextEditingController(model: widget.model));

  TextInputModel get _model => _controller.model;

  String _lastValue = '';
  FocusController? _focusController;
  FocusController? _localController;
  bool _focused = false;
  bool _mouseSelectionActive = false;
  MouseMsg? _lastHitMouseEvent;
  bool _autofocusSent = false;
  Theme? _themeFromContext;
  bool _themeResolved = false;

  @override
  void initState() {
    super.initState();
    _lastValue = _model.value;
    _controller.addListener(_handleControllerChanged);
    _applyConfig();
    if (TuiTrace.enabled) {
      TuiTrace.log('tf.initState id=$_focusId autofocus=${widget.autofocus}');
    }
    _resolveFocusController();
  }

  @override
  Cmd? didUpdateWidget(covariant TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(
        _handleControllerChanged,
      );
      _controller.addListener(_handleControllerChanged);
    }

    if (oldWidget.model != widget.model && widget.model != null) {
      _controller.model = widget.model!;
    }

    _applyConfig();

    if (oldWidget.focusController != widget.focusController ||
        oldWidget.focusId != widget.focusId) {
      _resolveFocusController();
    }
    return null;
  }

  @override
  void dispose() {
    if (TuiTrace.enabled) {
      TuiTrace.log('tf.dispose id=$_focusId');
    }
    _focusController?.removeListener(_handleFocusChange);
    _focusController?.unregister(_focusId);
    (widget.controller ?? _internalController)?.removeListener(
      _handleControllerChanged,
    );
    _internalController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_lastValue != _controller.text) {
      _lastValue = _controller.text;
      widget.onChanged?.call(_controller.text);
    }
  }

  void _resolveFocusController() {
    _focusController?.removeListener(_handleFocusChange);
    _focusController?.unregister(_focusId);
    final fromScope = FocusScope.of(context);
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'tf.resolve id=$_focusId fromScope=${fromScope != null} hasExplicit=${widget.focusController != null}',
      );
    }
    _focusController =
        widget.focusController ??
        fromScope ??
        (_localController ??= FocusController());
    _focusController?.addListener(_handleFocusChange);

    final parentScopeId = FocusScope.nearestScopeId(context);
    if (TuiTrace.enabled) {
      TuiTrace.log('tf.resolve parentScopeId=$parentScopeId');
    }
    _focusController?.register(_focusId, parentId: parentScopeId);

    _syncFocusFromController();
  }

  void _maybeAttachScope() {
    if (widget.focusController != null) return;
    final scope = FocusScope.of(context);
    if (scope == null || identical(scope, _focusController)) return;

    if (TuiTrace.enabled) {
      TuiTrace.log('tf.attachScope id=$_focusId SWITCHING');
    }
    _focusController?.removeListener(_handleFocusChange);
    _focusController?.unregister(_focusId);
    _focusController = scope;
    _focusController?.addListener(_handleFocusChange);

    final parentScopeId = FocusScope.nearestScopeId(context);
    _focusController?.register(_focusId, parentId: parentScopeId);

    _autofocusSent = false;

    _syncFocusFromController();
  }

  String get _focusId => widget.focusId ?? widget.id;

  bool get _isFocused {
    final controller = _focusController;
    if (controller == null) return _model.focused;
    return controller.isFocused(_focusId);
  }

  void _syncFocusFromController() {
    if (_focusController == null) return;
    final next = _focusController!.isFocused(_focusId);
    if (TuiTrace.enabled) {
      TuiTrace.log(
        'tf.syncFocus id=$_focusId next=$next current=$_focused modelFocused=${_model.focused}',
      );
    }
    if (next == _focused) return;
    _focused = next;
    if (_focused) {
      _model.focus();
    } else {
      _model.blur();
    }
    setState(() {});
  }

  void _handleFocusChange() {
    if (!mounted) return;
    _syncFocusFromController();
  }

  void _ensureStaticCursor() {
    if (widget.cursor != null) return;
    if (_model.cursor.mode == CursorMode.static) return;
    final (next, _) = _model.cursor.setMode(CursorMode.static);
    _model.cursor = next;
  }

  void _applyConfig() {
    final model = _model;
    if (widget.prompt != null) model.prompt = widget.prompt!;
    if (widget.placeholder != null) model.placeholder = widget.placeholder!;
    if (widget.width != null) model.width = widget.width!;
    if (widget.echoMode != null) model.echoMode = widget.echoMode!;
    if (widget.echoCharacter != null) {
      model.echoCharacter = widget.echoCharacter!;
    }
    if (widget.charLimit != null) model.charLimit = widget.charLimit!;
    if (widget.showSuggestions != null) {
      model.showSuggestions = widget.showSuggestions!;
    }
    if (widget.collapseLargePaste != null) {
      model.collapseLargePaste = widget.collapseLargePaste!;
    }
    if (widget.collapsedPasteMinChars != null) {
      model.collapsedPasteMinChars = widget.collapsedPasteMinChars!;
    }
    if (widget.collapsedPasteMinLines != null) {
      model.collapsedPasteMinLines = widget.collapsedPasteMinLines!;
    }
    if (widget.useVirtualCursor != null) {
      model.useVirtualCursor = widget.useVirtualCursor!;
    }
    if (widget.suggestions != null) {
      model.suggestions = widget.suggestions!;
    }
    if (widget.styles != null) {
      model.styles = widget.styles!;
    }
    if (widget.keyMap != null) {
      model.keyMap = widget.keyMap!;
    }
    if (widget.cursor != null && widget.cursor != model.cursor) {
      model.cursor = widget.cursor!;
    }
    model.multiline = widget.multiline;
    model.maxHeight = widget.maxLines;
    _ensureStaticCursor();
  }

  void _applyThemeFromContext(BuildContext context) {
    if (widget.styles != null) return;
    final scoped = ThemeScope.maybeOf(context);
    final theme = scoped ?? currentTheme;
    if (_themeResolved && identical(theme, _themeFromContext)) return;
    _themeResolved = true;
    _themeFromContext = theme;
    _model.styles = _textInputStylesFromTheme(theme);
    if (_model.focused) {
      _model.focus();
    } else {
      _model.blur();
    }
    _ensureStaticCursor();
  }

  Cmd? _applyUpdate(Msg msg) {
    final beforeValue = _model.value;
    final beforePos = _model.position;
    final beforeFocused = _model.focused;
    final beforeSelStart = _model.selectionStart;
    final beforeSelEnd = _model.selectionEnd;
    final cmd = _controller.update(msg);

    _ensureStaticCursor();
    Cmd? focusCmd;
    final shouldBeFocused = _isFocused;
    if (shouldBeFocused && !_model.focused) {
      focusCmd = _model.focus();
    } else if (!shouldBeFocused && _model.focused) {
      _model.blur();
    }
    final changed =
        beforeValue != _model.value ||
        beforePos != _model.position ||
        beforeFocused != _model.focused ||
        beforeSelStart != _model.selectionStart ||
        beforeSelEnd != _model.selectionEnd ||
        (focusCmd != null);
    if (changed) {
      setState(() {});
    }
    if (beforeValue != _model.value && _lastValue != _model.value) {
      _lastValue = _model.value;
      widget.onChanged?.call(_model.value);
    }
    if (cmd == null) return focusCmd;
    if (focusCmd == null) return cmd;
    return Cmd.batch([cmd, focusCmd]);
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!widget.enabled) return null;
    if (!_isFocused) return null;
    final beforeValue = _model.value;
    final beforePos = _model.position;
    final beforeSelStart = _model.selectionStart;
    final beforeSelEnd = _model.selectionEnd;
    final beforeFocused = _model.focused;

    final cmd = _applyUpdate(msg);
    if (cmd != null) return cmd;

    final handledByModel =
        beforeValue != _model.value ||
        beforePos != _model.position ||
        beforeSelStart != _model.selectionStart ||
        beforeSelEnd != _model.selectionEnd ||
        beforeFocused != _model.focused;

    // Key events use one-winner bubbling in Element.dispatch. If the focused
    // text model handled a key but produced no command, return Cmd.none() so
    // the event is still considered consumed and does not traverse the rest
    // of large sibling subtrees (which is expensive while typing).
    if (handledByModel) {
      return Cmd.none();
    }

    return null;
  }

  Cmd? _finalizeMouseSelectionOutsideHit() {
    if (!_mouseSelectionActive) return null;
    _mouseSelectionActive = false;
    final syntheticRelease = const MouseMsg(
      action: MouseAction.release,
      button: MouseButton.left,
      x: 0,
      y: 0,
    );
    if (TuiTrace.enabled) {
      TuiTrace.log('tf.mouseSelection finalizeOutside id=$_focusId');
    }
    return _applyUpdate(syntheticRelease);
  }

  Cmd? _clearFocusOnOutsidePress(MouseMsg msg) {
    if (msg.button != MouseButton.left || msg.action != MouseAction.press) {
      return null;
    }
    if (_focusController == null || !_focusController!.isFocused(_focusId)) {
      return null;
    }
    final cleared = _focusController!.clearFocus();
    if (!cleared) {
      return null;
    }
    _syncFocusFromController();
    return Cmd.none();
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) {
      // Hit-test path (useHitTesting: true, the default).
      // Request focus when left button is clicked.
      if (msg.event.button == MouseButton.left) {
        _focusController?.requestFocus(_focusId);
        _syncFocusFromController();
        if (msg.event.action == MouseAction.press) {
          _mouseSelectionActive = true;
        } else if (msg.event.action == MouseAction.release) {
          _mouseSelectionActive = false;
        }
      }
      if (!widget.enabled) return null;

      _lastHitMouseEvent = msg.event;
      final localX = msg.localX.floor();
      final localY = msg.localY.floor();

      final adjustedX = localX - widget.mouseXOffset;
      final local = msg.event.copyWith(x: adjustedX, y: localY);
      if (TuiTrace.enabled) {
        TuiTrace.log(
          'tf.hitMouse id=$_focusId event=(${msg.event.x},${msg.event.y}) '
          'hitLocal=(${msg.localX.floor()},${msg.localY.floor()}) '
          'local=(${local.x},${local.y}) xOffset=${widget.mouseXOffset} '
          'action=${msg.event.action} '
          'button=${msg.event.button} pos=${_model.position}',
        );
      }
      return _applyUpdate(local);
    }
    if (msg is KeyMsg) {
      return _handleKey(msg);
    }
    if (msg is MouseMsg) {
      if (!widget.enabled) return null;
      final sameAsLastHit =
          _lastHitMouseEvent != null && msg == _lastHitMouseEvent;
      if (sameAsLastHit) {
        return null;
      }
      final blurCmd = _clearFocusOnOutsidePress(msg);
      if (blurCmd != null) {
        return blurCmd;
      }
      if (_mouseSelectionActive) {
        return _finalizeMouseSelectionOutsideHit();
      }
      return null;
    }
    return _applyUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    _maybeAttachScope();
    _applyThemeFromContext(context);
    if (widget.autofocus && !_autofocusSent) {
      _autofocusSent = true;
      if (TuiTrace.enabled) {
        TuiTrace.log(
          'tf.build.autofocus id=$_focusId trapId=${_focusController?.trapId}',
        );
      }
      _focusController?.requestFocus(_focusId);
      _syncFocusFromController();
    }
    if (widget.multiline) {
      return _TextFieldRender(model: _model);
    }
    final content = Text(
      _modelViewString(_model.view()),
      softWrap: false,
      overflow: TextOverflow.clip,
    );
    return content;
  }
}

// ---------------------------------------------------------------------------
// Custom render pipeline for multi-line TextField
// ---------------------------------------------------------------------------

/// A leaf render-object widget that bridges [TextInputModel] to the layout
/// pipeline for multi-line editing.
///
/// During layout, it sets [TextInputModel.width] from the incoming
/// [BoxConstraints.maxWidth] (minus the prompt display width) so that
/// soft-wrapping is driven by the parent's available space. It then calls
/// [TextInputModel.view()] to produce the rendered content and sizes itself
/// from the result.
///
class _TextFieldRender extends LeafRenderObjectWidget {
  _TextFieldRender({required this.model});

  final TextInputModel model;

  @override
  Object view() {
    return _modelViewString(model.view());
  }

  @override
  RenderObject createRenderObject() {
    return _RenderTextField(model: model);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderTextField;
    ro.model = model;
  }
}

/// Render object that manages multi-line [TextInputModel] rendering.
///
/// Layout:
///   1. Derives available width from [BoxConstraints.maxWidth] minus the
///      prompt's display width.
///   2. Sets [TextInputModel.width] so wrapped-line computation uses the
///      correct column count.
///   3. Calls [TextInputModel.view()] to get rendered content.
///   4. Measures the content and reports the `size`.
///
/// Paint:
///   Returns the cached content string.
class _RenderTextField extends RenderBox {
  _RenderTextField({required this.model});

  TextInputModel model;

  /// Cached content produced during [layout], returned by [paint].
  String _cachedContent = '';

  int _lineCount(String value) {
    if (value.isEmpty) return 1;
    var lines = 1;
    for (var i = 0; i < value.length; i++) {
      if (value.codeUnitAt(i) == 10) lines++;
    }
    return lines;
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    // Derive the text area width from layout constraints.
    // The prompt occupies some columns on the first line; the model's `width`
    // field controls soft-wrapping of the text content (excluding prompt).
    // For multi-line, width = total available columns. The model already
    // accounts for prompt width internally during wrapped-line computation.
    if (constraints.hasBoundedWidth) {
      final availableWidth = constraints.maxWidth.toInt();
      if (availableWidth > 0 && model.width != availableWidth) {
        model.width = availableWidth;
      }
    }

    // Render the model content.
    final viewResult = model.view();
    var content = _modelViewString(viewResult);

    _cachedContent = content;

    // Measure the rendered content to determine our size.
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : Layout.getWidth(content).toDouble();
    final height = _lineCount(content).toDouble();
    size = constraints.constrain(Size(width, height));
  }

  @override
  String paint() => _cachedContent;
}

/// A multi-line text editor widget powered by the bubbles textarea model.
class TextArea extends StatefulWidget {
  TextArea({
    this.model,
    this.controller,
    this.prompt,
    this.placeholder,
    this.width,
    this.height = 6,
    this.showLineNumbers = true,
    this.charLimit,
    this.softWrap = true,
    this.useVirtualCursor,
    this.styles,
    this.keyMap,
    this.cursor,
    this.onChanged,
    this.focusController,
    this.focusId,
    this.autofocus = false,
    this.enabled = true,
    this.mouseXOffset = 0,
    this.zoneId,
    super.key,
  });

  /// Optional model to use for textarea behavior.
  final TextAreaModel? model;

  /// Optional controller to hold textarea state.
  final TextAreaController? controller;

  /// Prompt displayed before each line.
  final String? prompt;

  /// Placeholder text when the textarea is empty.
  final String? placeholder;

  /// Explicit textarea width in cells.
  final int? width;

  /// Visible textarea height in rows.
  final int height;

  /// Whether to show line numbers.
  final bool showLineNumbers;

  /// Maximum characters allowed (0 = unlimited).
  final int? charLimit;

  /// Whether to soft-wrap long lines.
  final bool softWrap;

  /// Whether to render a virtual cursor.
  final bool? useVirtualCursor;

  /// Styles used for focused/blurred textarea rendering.
  final TextAreaStyles? styles;

  /// Optional key bindings.
  final TextAreaKeyMap? keyMap;

  /// Optional cursor model. Defaults to a static cursor.
  final CursorModel? cursor;

  /// Called when the text changes.
  final TextChangedCallback? onChanged;

  /// Optional focus controller for focus coordination.
  final FocusController? focusController;

  /// Optional focus identifier.
  final String? focusId;

  /// Whether to request focus on first build.
  final bool autofocus;

  /// Whether input is enabled.
  final bool enabled;

  /// Optional horizontal offset correction for mouse hit coordinates.
  final int mouseXOffset;

  /// Optional zone id for mouse interactions.
  final String? zoneId;

  @override
  State createState() => _TextAreaState();
}

class _TextAreaState extends State<TextArea> {
  TextAreaController? _internalController;
  TextAreaController get _controller =>
      widget.controller ??
      (_internalController ??= TextAreaController(model: widget.model));

  TextAreaModel get _model => _controller.model;

  String _lastValue = '';
  FocusController? _focusController;
  FocusController? _localController;
  bool _focused = false;
  bool _mouseSelectionActive = false;
  MouseMsg? _lastHitMouseEvent;
  bool _autofocusSent = false;
  Theme? _themeFromContext;
  bool _themeResolved = false;

  @override
  void initState() {
    super.initState();
    _lastValue = _model.value;
    _controller.addListener(_handleControllerChanged);
    _applyConfig();
    _resolveFocusController();
  }

  @override
  Cmd? didUpdateWidget(covariant TextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(
        _handleControllerChanged,
      );
      _controller.addListener(_handleControllerChanged);
    }

    if (oldWidget.model != widget.model && widget.model != null) {
      _controller.model = widget.model!;
    }

    _applyConfig();

    if (oldWidget.focusController != widget.focusController ||
        oldWidget.focusId != widget.focusId) {
      _resolveFocusController();
    }
    return null;
  }

  @override
  void dispose() {
    _focusController?.removeListener(_handleFocusChange);
    _focusController?.unregister(_focusId);
    (widget.controller ?? _internalController)?.removeListener(
      _handleControllerChanged,
    );
    _internalController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_lastValue != _controller.text) {
      _lastValue = _controller.text;
      widget.onChanged?.call(_controller.text);
    }
  }

  void _resolveFocusController() {
    _focusController?.removeListener(_handleFocusChange);
    _focusController?.unregister(_focusId);
    final fromScope = FocusScope.of(context);
    _focusController =
        widget.focusController ??
        fromScope ??
        (_localController ??= FocusController());
    _focusController?.addListener(_handleFocusChange);
    final parentScopeId = FocusScope.nearestScopeId(context);
    _focusController?.register(_focusId, parentId: parentScopeId);
    _syncFocusFromController();
  }

  void _maybeAttachScope() {
    if (widget.focusController != null) return;
    final scope = FocusScope.of(context);
    if (scope == null || identical(scope, _focusController)) return;
    _focusController?.removeListener(_handleFocusChange);
    _focusController?.unregister(_focusId);
    _focusController = scope;
    _focusController?.addListener(_handleFocusChange);
    final parentScopeId = FocusScope.nearestScopeId(context);
    _focusController?.register(_focusId, parentId: parentScopeId);
    _autofocusSent = false;
    _syncFocusFromController();
  }

  String get _focusId => widget.focusId ?? widget.id;

  bool get _isFocused {
    final controller = _focusController;
    if (controller == null) return _model.focused;
    return controller.isFocused(_focusId);
  }

  void _syncFocusFromController() {
    if (_focusController == null) return;
    final next = _focusController!.isFocused(_focusId);
    if (next == _focused) return;
    _focused = next;
    if (_focused) {
      _model.focus();
    } else {
      _model.blur();
    }
    setState(() {});
  }

  void _handleFocusChange() {
    if (!mounted) return;
    _syncFocusFromController();
  }

  void _ensureStaticCursor() {
    if (widget.cursor != null) return;
    if (_model.cursor.mode == CursorMode.static) return;
    final (next, _) = _model.cursor.setMode(CursorMode.static);
    _model.cursor = next;
  }

  void _applyConfig() {
    final model = _model;
    if (widget.prompt != null) model.prompt = widget.prompt!;
    if (widget.placeholder != null) model.placeholder = widget.placeholder!;
    if (widget.width != null) model.setWidth(widget.width!);
    model.setHeight(widget.height);
    model.showLineNumbers = widget.showLineNumbers;
    model.softWrap = widget.softWrap;
    if (widget.charLimit != null) model.setCharLimit(widget.charLimit!);
    if (widget.useVirtualCursor != null) {
      model.useVirtualCursor = widget.useVirtualCursor!;
    }
    if (widget.styles != null) {
      model.styles = widget.styles!;
    }
    if (widget.keyMap != null) {
      model.keyMap = widget.keyMap!;
    }
    if (widget.cursor != null && widget.cursor != model.cursor) {
      model.cursor = widget.cursor!;
    }
    _ensureStaticCursor();
  }

  void _applyThemeFromContext(BuildContext context) {
    if (widget.styles != null) return;
    final scoped = ThemeScope.maybeOf(context);
    final theme = scoped ?? currentTheme;
    if (_themeResolved && identical(theme, _themeFromContext)) return;
    _themeResolved = true;
    _themeFromContext = theme;
    _model.styles = textAreaStylesFromTheme(theme);
    if (_model.focused) {
      _model.focus();
    } else {
      _model.blur();
    }
    _ensureStaticCursor();
  }

  _TextAreaControllerSnapshot _snapshot() {
    return _TextAreaControllerSnapshot.capture(_model);
  }

  Cmd? _applyUpdate(Msg msg) {
    final before = _snapshot();
    final cmd = _controller.update(msg);
    _ensureStaticCursor();
    Cmd? focusCmd;
    final shouldBeFocused = _isFocused;
    if (shouldBeFocused && !_model.focused) {
      focusCmd = _model.focus();
    } else if (!shouldBeFocused && _model.focused) {
      _model.blur();
    }
    final changed = !before.matches(_model) || focusCmd != null;
    if (changed) {
      setState(() {});
    }
    if (before.text != _model.value && _lastValue != _model.value) {
      _lastValue = _model.value;
      widget.onChanged?.call(_model.value);
    }
    if (cmd == null) return focusCmd;
    if (focusCmd == null) return cmd;
    return Cmd.batch([cmd, focusCmd]);
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!widget.enabled) return null;
    if (!_isFocused) return null;
    final before = _snapshot();
    final cmd = _applyUpdate(msg);
    if (cmd != null) return cmd;
    if (!before.matches(_model)) {
      return Cmd.none();
    }
    return null;
  }

  Cmd? _finalizeMouseSelectionOutsideHit() {
    if (!_mouseSelectionActive) return null;
    _mouseSelectionActive = false;
    final syntheticRelease = const MouseMsg(
      action: MouseAction.release,
      button: MouseButton.left,
      x: 0,
      y: 0,
    );
    return _applyUpdate(syntheticRelease);
  }

  Cmd? _clearFocusOnOutsidePress(MouseMsg msg) {
    if (msg.button != MouseButton.left || msg.action != MouseAction.press) {
      return null;
    }
    if (_focusController == null || !_focusController!.isFocused(_focusId)) {
      return null;
    }
    final cleared = _focusController!.clearFocus();
    if (!cleared) {
      return null;
    }
    _syncFocusFromController();
    return Cmd.none();
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) {
      if (msg.event.button == MouseButton.left) {
        _focusController?.requestFocus(_focusId);
        _syncFocusFromController();
        if (msg.event.action == MouseAction.press) {
          _mouseSelectionActive = true;
        } else if (msg.event.action == MouseAction.release) {
          _mouseSelectionActive = false;
        }
      }
      if (!widget.enabled) return null;
      _lastHitMouseEvent = msg.event;
      final localX = msg.localX.floor() - widget.mouseXOffset;
      final localY = msg.localY.floor();
      final local = msg.event.copyWith(x: localX, y: localY);
      return _applyUpdate(local);
    }
    if (msg is KeyMsg) {
      return _handleKey(msg);
    }
    if (msg is MouseMsg) {
      if (!widget.enabled) return null;
      final sameAsLastHit =
          _lastHitMouseEvent != null && msg == _lastHitMouseEvent;
      if (sameAsLastHit) {
        return null;
      }
      final blurCmd = _clearFocusOnOutsidePress(msg);
      if (blurCmd != null) {
        return blurCmd;
      }
      if (_mouseSelectionActive) {
        return _finalizeMouseSelectionOutsideHit();
      }
      return null;
    }
    return _applyUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    _maybeAttachScope();
    _applyThemeFromContext(context);
    if (widget.autofocus && !_autofocusSent) {
      _autofocusSent = true;
      _focusController?.requestFocus(_focusId);
      _syncFocusFromController();
    }
    return _TextAreaRender(model: _model, configuredHeight: widget.height);
  }
}

class _TextAreaRender extends LeafRenderObjectWidget {
  _TextAreaRender({required this.model, required this.configuredHeight});

  final TextAreaModel model;
  final int configuredHeight;

  @override
  Object view() {
    return _modelViewString(model.view());
  }

  @override
  RenderObject createRenderObject() {
    return _RenderTextArea(model: model, configuredHeight: configuredHeight);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderTextArea;
    ro.model = model;
    ro.configuredHeight = configuredHeight;
  }
}

class _RenderTextArea extends RenderBox {
  _RenderTextArea({required this.model, required this.configuredHeight});

  TextAreaModel model;
  int configuredHeight;
  String _cachedContent = '';

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    if (constraints.hasBoundedWidth && constraints.maxWidth.isFinite) {
      final availableWidth = constraints.maxWidth.toInt();
      if (availableWidth > 0 && model.width != availableWidth) {
        model.setWidth(availableWidth);
      }
    }

    final boundedHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight.toInt()
        : configuredHeight;
    final effectiveHeight =
        constraints.hasBoundedHeight && constraints.maxHeight.isFinite
        ? (boundedHeight < 1 ? 1 : boundedHeight)
        : configuredHeight;
    if (model.height != effectiveHeight) {
      model.setHeight(effectiveHeight);
    }

    final viewResult = model.view();
    _cachedContent = _modelViewString(viewResult);

    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : Layout.getWidth(_cachedContent).toDouble();
    final height = effectiveHeight.toDouble();
    size = constraints.constrain(Size(width, height));
  }

  @override
  String paint() => _cachedContent;
}
