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
      down = KeyBinding.withHelp(['j', 'down', 'ctrl+n'], 'j/↓', 'down'),
      up = KeyBinding.withHelp(['k', 'up', 'ctrl+p'], 'k/↑', 'up'),
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
        'h/←',
        'go back',
      ),
      open = KeyBinding.withHelp(['l', 'right', 'enter'], 'l/→/enter', 'open'),
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
}

class FilePickerStyles {
  const FilePickerStyles({
    this.style,
    this.selectedStyle,
    this.directoryStyle,
    this.fileStyle,
    this.symlinkStyle,
    this.executableStyle,
    this.hiddenItemStyle,
    this.headerStyle,
    this.errorHeaderStyle,
    this.errorBodyStyle,
    this.infoStyle,
  });

  final Style? style;
  final Style? selectedStyle;
  final Style? directoryStyle;
  final Style? fileStyle;
  final Style? symlinkStyle;
  final Style? executableStyle;
  final Style? hiddenItemStyle;
  final Style? headerStyle;
  final Style? errorHeaderStyle;
  final Style? errorBodyStyle;
  final Style? infoStyle;
}

class ViewState {
  ViewState({
    this.currentPath = '',
    this.currentDirEntries = const [],
    this.cursorIndex = 0,
    this.topIndex = 0,
    this.showHidden = false,
    this.error,
    this.isLoading = false,
  });

  String currentPath;
  List<Object?> currentDirEntries;
  int cursorIndex;
  int topIndex;
  bool showHidden;
  String? error;
  bool isLoading;
}

class FileEntry {
  FileEntry({required this.entity, this.stat});

  final Object? entity;
  final Object? stat;

  bool get isSymlink => false;
  bool get isDirectory => false;
  bool get isFile => false;
  bool get isHidden => false;
  String get displayName => entity?.toString() ?? '';
  String get fullPath => entity?.toString() ?? '';
}

class FilePickerModel extends ViewComponent {
  FilePickerModel({
    this.id = 0,
    this.rootPath = '',
    this.title = 'File Browser',
    this.allowFileSelection = true,
    this.allowDirectorySelection = false,
    this.maxHeight = 20,
    this.indentSize = 2,
    this.styles = const FilePickerStyles(),
    FilePickerKeyMap? keyMap,
  }) : _keyMap = keyMap ?? FilePickerKeyMap();

  final int id;
  final String rootPath;
  final String title;
  final bool allowFileSelection;
  final bool allowDirectorySelection;
  final int maxHeight;
  final int indentSize;
  final FilePickerStyles styles;
  final FilePickerKeyMap _keyMap;
  final ViewState _viewState = ViewState();

  FilePickerKeyMap get keyMap => _keyMap;
  bool get showHidden => _viewState.showHidden;
  String get currentPath => _viewState.currentPath;
  String? get error => _viewState.error;

  List<Object?> get files => _viewState.currentDirEntries;

  @override
  (FilePickerModel, Cmd?) update(Msg msg) {
    return (this, null);
  }

  @override
  String view() => 'File browser is not available on this platform.';
}
