import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';

import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'key_binding.dart';

class FilePickerReadDirMsg extends Msg {
  const FilePickerReadDirMsg(this.id, this.entries);

  final int id;
  final List<Object?> entries;
}

class FilePickerErrorMsg extends Msg {
  const FilePickerErrorMsg(this.id, this.error);

  final int id;
  final String error;
}

class FilePickerKeyMap {
  FilePickerKeyMap()
    : goToTop = KeyBinding.withHelp(['g', 'home'], 'g/home', 'go to start'),
      goToLast = KeyBinding.withHelp(['G', 'end'], 'G/end', 'go to end'),
      down = KeyBinding.withHelp(['j', 'down', 'ctrl+n'], 'j/down', 'down'),
      up = KeyBinding.withHelp(['k', 'up', 'ctrl+p'], 'k/up', 'up'),
      pageUp = KeyBinding.withHelp(
        ['K', 'pgup', 'ctrl+u'],
        'K/pgup',
        'page up',
      ),
      pageDown = KeyBinding.withHelp(
        ['J', 'pgdown', 'ctrl+d'],
        'J/pgdown',
        'page down',
      ),
      toggleHidden = KeyBinding.withHelp(['.'], '.', 'toggle hidden'),
      back = KeyBinding.withHelp(
        ['h', 'backspace', 'left', 'esc'],
        'h/left',
        'go back',
      ),
      open = KeyBinding.withHelp(
        ['l', 'right', 'enter'],
        'l/right/enter',
        'open',
      ),
      select = KeyBinding.withHelp(['enter'], 'enter', 'select');

  final KeyBinding goToTop;
  final KeyBinding goToLast;
  final KeyBinding down;
  final KeyBinding up;
  final KeyBinding pageUp;
  final KeyBinding pageDown;
  final KeyBinding toggleHidden;
  final KeyBinding back;
  final KeyBinding open;
  final KeyBinding select;

  List<KeyBinding> get fullHelp => [
    goToTop,
    goToLast,
    down,
    up,
    pageUp,
    pageDown,
    toggleHidden,
    back,
    open,
    select,
  ];

  List<KeyBinding> get shortHelp => [up, down, open, back];
}

class FilePickerStyles {
  FilePickerStyles({
    Style? cursor,
    Style? symlink,
    Style? directory,
    Style? file,
    Style? permission,
    Style? selected,
    Style? disabledCursor,
    Style? disabledFile,
    Style? disabledSelected,
    Style? fileSize,
    Style? emptyDirectory,
  }) : cursor = cursor ?? Style().foreground(AnsiColor(212)),
       symlink = symlink ?? Style().foreground(AnsiColor(36)),
       directory = directory ?? Style().foreground(AnsiColor(99)),
       file = file ?? Style(),
       permission = permission ?? Style().foreground(AnsiColor(244)),
       selected = selected ?? Style().bold().foreground(AnsiColor(212)),
       disabledCursor = disabledCursor ?? Style().foreground(AnsiColor(247)),
       disabledFile = disabledFile ?? Style().foreground(AnsiColor(243)),
       disabledSelected =
           disabledSelected ?? Style().foreground(AnsiColor(247)),
       fileSize = fileSize ?? Style().foreground(AnsiColor(240)).width(7),
       emptyDirectory =
           emptyDirectory ?? Style().foreground(AnsiColor(240)).italic();

  final Style cursor;
  final Style symlink;
  final Style directory;
  final Style file;
  final Style permission;
  final Style selected;
  final Style disabledCursor;
  final Style disabledFile;
  final Style disabledSelected;
  final Style fileSize;
  final Style emptyDirectory;
}

class ViewState {
  const ViewState(this.selected, this.min, this.max);

  final int selected;
  final int min;
  final int max;
}

class FileEntry {
  FileEntry({required this.entity, this.stat});

  final Object? entity;
  final Object? stat;

  String get name {
    final value = entity.toString();
    final slash = value.lastIndexOf('/');
    return slash == -1 ? value : value.substring(slash + 1);
  }

  bool get isDirectory => false;
  bool get isSymlink => false;
  int get size => 0;
  int get mode => 0;
  String get permissions => '---------';
}

class FilePickerModel extends ViewComponent {
  FilePickerModel({
    required String currentDirectory,
    List<String>? allowedTypes,
    bool fileAllowed = true,
    bool dirAllowed = false,
    bool showHidden = false,
    bool showPermissions = true,
    bool showSize = true,
    int height = 10,
    bool autoHeight = true,
    String cursor = '> ',
    FilePickerKeyMap? keyMap,
    FilePickerStyles? styles,
  }) : _currentDirectory = currentDirectory,
       _allowedTypes = allowedTypes ?? [],
       _fileAllowed = fileAllowed,
       _dirAllowed = dirAllowed,
       _showHidden = showHidden,
       _showPermissions = showPermissions,
       _showSize = showSize,
       _height = height,
       _autoHeight = autoHeight,
       _cursor = cursor,
       _keyMap = keyMap ?? FilePickerKeyMap(),
       _styles = styles ?? FilePickerStyles(),
       _files = const [],
       _selected = 0,
       _min = 0,
       _max = height - 1,
       _selectedPath = null,
       _selectedStack = const [],
       _id = 0,
       _errorMessage = null;

  FilePickerModel._({
    required String currentDirectory,
    required List<String> allowedTypes,
    required bool fileAllowed,
    required bool dirAllowed,
    required bool showHidden,
    required bool showPermissions,
    required bool showSize,
    required int height,
    required bool autoHeight,
    required String cursor,
    required FilePickerKeyMap keyMap,
    required FilePickerStyles styles,
    required List<FileEntry> files,
    required int selected,
    required int min,
    required int max,
    required String? selectedPath,
    required List<ViewState> selectedStack,
    required int id,
    String? errorMessage,
  }) : _currentDirectory = currentDirectory,
       _allowedTypes = allowedTypes,
       _fileAllowed = fileAllowed,
       _dirAllowed = dirAllowed,
       _showHidden = showHidden,
       _showPermissions = showPermissions,
       _showSize = showSize,
       _height = height,
       _autoHeight = autoHeight,
       _cursor = cursor,
       _keyMap = keyMap,
       _styles = styles,
       _files = files,
       _selected = selected,
       _min = min,
       _max = max,
       _selectedPath = selectedPath,
       _selectedStack = selectedStack,
       _id = id,
       _errorMessage = errorMessage;

  final String _currentDirectory;
  List<String> _allowedTypes;
  bool _fileAllowed;
  bool _dirAllowed;
  final bool _showHidden;
  final bool _showPermissions;
  final bool _showSize;
  int _height;
  final bool _autoHeight;
  final String _cursor;
  final FilePickerKeyMap _keyMap;
  final FilePickerStyles _styles;
  final List<FileEntry> _files;
  final int _selected;
  final int _min;
  final int _max;
  final String? _selectedPath;
  final List<ViewState> _selectedStack;
  final int _id;
  final String? _errorMessage;

  String get currentDirectory => _currentDirectory;
  List<String> get allowedTypes => _allowedTypes;
  bool get fileAllowed => _fileAllowed;
  bool get dirAllowed => _dirAllowed;
  bool get showHidden => _showHidden;
  bool get showPermissions => _showPermissions;
  bool get showSize => _showSize;
  int get height => _height;
  bool get autoHeight => _autoHeight;
  String get cursor => _cursor;
  FilePickerKeyMap get keyMap => _keyMap;
  FilePickerStyles get styles => _styles;
  List<FileEntry> get files => _files;
  int get selected => _selected;
  String? get selectedPath => _selectedPath;
  String? get errorMessage => _errorMessage;
  int get id => _id;

  FilePickerModel copyWith({
    String? currentDirectory,
    List<String>? allowedTypes,
    bool? fileAllowed,
    bool? dirAllowed,
    bool? showHidden,
    bool? showPermissions,
    bool? showSize,
    int? height,
    bool? autoHeight,
    String? cursor,
    FilePickerKeyMap? keyMap,
    FilePickerStyles? styles,
    List<FileEntry>? files,
    int? selected,
    int? min,
    int? max,
    String? selectedPath,
    bool clearSelectedPath = false,
    List<ViewState>? selectedStack,
    int? id,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FilePickerModel._(
      currentDirectory: currentDirectory ?? _currentDirectory,
      allowedTypes: allowedTypes ?? _allowedTypes,
      fileAllowed: fileAllowed ?? _fileAllowed,
      dirAllowed: dirAllowed ?? _dirAllowed,
      showHidden: showHidden ?? _showHidden,
      showPermissions: showPermissions ?? _showPermissions,
      showSize: showSize ?? _showSize,
      height: height ?? _height,
      autoHeight: autoHeight ?? _autoHeight,
      cursor: cursor ?? _cursor,
      keyMap: keyMap ?? _keyMap,
      styles: styles ?? _styles,
      files: files ?? _files,
      selected: selected ?? _selected,
      min: min ?? _min,
      max: max ?? _max,
      selectedPath: clearSelectedPath ? null : (selectedPath ?? _selectedPath),
      selectedStack: selectedStack ?? _selectedStack,
      id: id ?? _id,
      errorMessage: clearError ? null : (errorMessage ?? _errorMessage),
    );
  }

  void setAllowedExtensions(List<String> extensions) {
    _allowedTypes = extensions;
  }

  void setDirAllowed(bool allowed) {
    _dirAllowed = allowed;
  }

  void setFileAllowed(bool allowed) {
    _fileAllowed = allowed;
  }

  @override
  Cmd? init() => null;

  @override
  (FilePickerModel, Cmd?) update(Msg msg) => (this, null);

  bool canSelect(String fileName) {
    if (_allowedTypes.isEmpty) return true;
    return _allowedTypes.any(fileName.endsWith);
  }

  (bool, String?) didSelectFile(Msg msg) => (false, null);

  (bool, String?) didSelectDisabledFile(Msg msg) => (false, null);

  void setHeight(int h) {
    _height = h;
  }

  void setWidth(int w) {}

  @override
  String view() => 'File browser is not available on this platform.';
}
