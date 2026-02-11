@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'package:artisanal/tui.dart'
    show
        Cmd,
        Msg,
        KeyMsg,
        MouseMsg,
        MouseButton,
        HitTestMouseMsg,
        View,
        TuiTrace;
import 'package:artisanal/style.dart' show Layout, Style;
import '../animation/listenable.dart' show ChangeNotifier, ValueListenable;
import '../focus/focus.dart' show FocusController, FocusScope;
import '../core/framework.dart' show BuildContext, State, StatefulWidget;
import '../layout/layout_widgets.dart' show Text, TextOverflow;
import '../rendering/render_object.dart'
    show LeafRenderObjectWidget, RenderBox, RenderObject;
import '../layout/geometry.dart' show BoxConstraints, Size;
import '../theme/theme.dart' show Theme, currentTheme;
import '../theme/theme_scope.dart' show ThemeScope;
import '../core/widget.dart';
import 'package:artisanal/bubbles.dart'
    show
        EchoMode,
        TextInputCursorStyle,
        TextInputKeyMap,
        TextInputModel,
        TextInputStyleState,
        TextInputStyles,
        CursorModel,
        CursorMode;
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
    _model.value = value;
    _model.selectionStart = null;
    _model.selectionEnd = null;
    _model.position = value.length;
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
    _model.value = newValue.text;
    if (newValue.selection.isCollapsed) {
      _model.selectionStart = null;
      _model.selectionEnd = null;
    } else {
      _model.selectionStart = newValue.selection.baseOffset;
      _model.selectionEnd = newValue.selection.extentOffset;
    }
    _model.position = newValue.selection.extentOffset;
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
}

/// Alias for [TextEditingController] for backward compatibility.
typedef TextFieldController = TextEditingController;

String _modelViewString(Object view) {
  if (view is String) return view;
  if (view is View) return view.content;
  return view.toString();
}

TextInputStyles _textInputStylesFromTheme(Theme theme) {
  return TextInputStyles(
    focused: TextInputStyleState(
      prompt: theme.labelLarge.copy(),
      text: theme.bodyMedium.copy(),
      placeholder: theme.labelSmall.copy(),
      suggestion: theme.labelSmall.copy(),
      selection: Style().background(theme.primary).foreground(theme.onPrimary),
    ),
    blurred: TextInputStyleState(
      prompt: theme.labelSmall.copy(),
      text: theme.bodySmall.copy(),
      placeholder: theme.labelSmall.copy(),
      suggestion: theme.labelSmall.copy(),
      selection: Style().background(theme.muted).foreground(theme.onSurface),
    ),
    cursor: TextInputCursorStyle(
      color: theme.primary,
      shape: CursorShape.block,
      blink: false,
    ),
  );
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
    return _applyUpdate(msg);
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is HitTestMouseMsg) {
      // Hit-test path (useHitTesting: true, the default).
      // Request focus when left button is clicked.
      if (msg.event.button == MouseButton.left) {
        _focusController?.requestFocus(_focusId);
      }
      return null;
    }
    if (msg is KeyMsg) {
      return _handleKey(msg);
    }
    if (msg is MouseMsg) {
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
///   4. Measures the content and reports [size].
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
