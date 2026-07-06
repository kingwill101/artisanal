import 'dart:async';
import 'dart:math' as math;

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show Cmd, KeyMsg, KeyBinding;
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/compat.dart';



class FilePicker extends StatefulWidget {
  FilePicker({
    required this.directory,
    this.title,
    this.allowedExtensions = const [],
    this.fileAllowed = true,
    this.directoryAllowed = false,
    this.showHidden = false,
    this.showPermissions = true,
    this.showSize = true,
    this.width,
    this.height,
    this.showHelp = true,
    this.selectLabel = 'Select',
    this.openLabel = 'Open',
    this.parentLabel = 'Up',
    this.cancelLabel = 'Cancel',
    this.exitLabel = 'Quit',
    this.onSelected,
    this.onCancelled,
    this.onExit,
    super.key,
  });

  final String directory;
  final String? title;
  final List<String> allowedExtensions;
  final bool fileAllowed;
  final bool directoryAllowed;
  final bool showHidden;
  final bool showPermissions;
  final bool showSize;
  final int? width;
  final int? height;
  final bool showHelp;
  final String selectLabel;
  final String openLabel;
  final String parentLabel;
  final String cancelLabel;
  final String exitLabel;
  final ValueCmdCallback<String>? onSelected;
  final CmdCallback? onCancelled;
  final CmdCallback? onExit;

  @override
  State<FilePicker> createState() => _FilePickerState();
}

class _FilePickerState extends State<FilePicker> {
  final WidgetScrollController _listController = WidgetScrollController();
  String _currentDirectory = '.';
  bool _showHidden = false;
  bool _loading = true;
  String? _errorMessage;
  List<_FilePickerEntry> _entries = const [];
  final List<_FilePickerViewState> _history = <_FilePickerViewState>[];
  int _selectedIndex = 0;
  int _lastListHeight = 10;
  int _requestId = 0;
  int? _pendingScrollOffset;

  @override
  void initState() {
    super.initState();
    _currentDirectory = widget.directory;
    _showHidden = widget.showHidden;
    _listController.addListener(_handleScrollChanged);
  }

  @override
  void dispose() {
    _listController.removeListener(_handleScrollChanged);
    super.dispose();
  }

  void _handleScrollChanged() {
    setState(() {});
  }

  @override
  Cmd? handleInit() => _loadDirectory(_currentDirectory);

  @override
  Cmd? didUpdateWidget(covariant FilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.directory != widget.directory) {
      setState(() {
        _currentDirectory = widget.directory;
        _entries = const [];
        _history.clear();
        _selectedIndex = 0;
        _loading = true;
        _errorMessage = null;
      });
      _pendingScrollOffset = 0;
      return _loadDirectory(_currentDirectory);
    }

    if (oldWidget.showHidden != widget.showHidden) {
      setState(() {
        _showHidden = widget.showHidden;
        _entries = const [];
        _selectedIndex = 0;
        _loading = true;
        _errorMessage = null;
      });
      _pendingScrollOffset = 0;
      return _loadDirectory(_currentDirectory);
    }

    return null;
  }

  _FilePickerEntry? get _selectedEntry {
    if (_entries.isEmpty) return null;
    final index = _selectedIndex.clamp(0, _entries.length - 1);
    return _entries[index];
  }

  bool _isCtrlCShortcut(terminal_keys.Key key) {
    if (key.runes.length == 1 && key.runes.first == 0x03) {
      return true;
    }
    if (!key.ctrl || key.alt || key.meta || key.hyper || key.superKey) {
      return false;
    }
    final char = key.char;
    return char != null && char.toLowerCase() == 'c';
  }

  bool _matchesChar(terminal_keys.Key key, String value) {
    final char = key.char;
    return char != null && char == value;
  }

  bool _matchesLowerChar(terminal_keys.Key key, String value) {
    final char = key.char;
    return char != null && char.toLowerCase() == value;
  }

  int _effectiveListHeight(MediaQueryData media) {
    final explicit = widget.height;
    if (explicit != null) return math.max(4, explicit);
    return math.max(6, media.size.height.toInt() - 14);
  }

  void _updateListMetrics([int? listHeight]) {
    final height = math.max(1, listHeight ?? _lastListHeight);
    final contentExtent = _entries.isEmpty ? 1 : _entries.length;
    _listController.updateMetrics(
      viewportExtent: height,
      contentExtent: contentExtent,
    );
  }

  void _applyPendingScrollOffset([int? listHeight]) {
    final pending = _pendingScrollOffset;
    if (pending == null) return;

    final height = math.max(1, listHeight ?? _lastListHeight);
    final contentExtent = _entries.isEmpty ? 1 : _entries.length;
    final maxOffset = math.max(0, contentExtent - height);
    _pendingScrollOffset = null;
    _listController.jumpTo(pending.clamp(0, maxOffset));
  }

  void _scrollSelectionIntoView([int? listHeight]) {
    if (_entries.isEmpty) {
      _selectedIndex = 0;
      _listController.jumpTo(0);
      return;
    }

    final height = math.max(1, listHeight ?? _lastListHeight);
    _selectedIndex = _selectedIndex.clamp(0, _entries.length - 1);
    final offset = _listController.offset;

    if (_selectedIndex < offset) {
      _listController.jumpTo(_selectedIndex);
    } else if (_selectedIndex >= offset + height) {
      _listController.jumpTo(_selectedIndex - height + 1);
    }
  }

  Cmd _loadDirectory(String directory) {
    final requestId = ++_requestId;

    return Cmd(() async {
      try {
        final dir = Directory(directory);
        var entities = await dir.list().toList();
        if (!_showHidden) {
          entities = entities
              .where((entity) => !_basename(entity.path).startsWith('.'))
              .toList(growable: false);
        }

        final entries = await Future.wait(
          entities.map(_buildEntry),
          eagerError: false,
        );

        entries.sort((left, right) {
          if (left.isDirectoryLike && !right.isDirectoryLike) return -1;
          if (!left.isDirectoryLike && right.isDirectoryLike) return 1;
          return left.name.toLowerCase().compareTo(right.name.toLowerCase());
        });

        return _FilePickerLoadedMsg(requestId, directory, entries);
      } catch (error) {
        return _FilePickerErrorMsg(requestId, directory, error.toString());
      }
    });
  }

  Future<_FilePickerEntry> _buildEntry(FileSystemEntity entity) async {
    FileStat? stat;
    try {
      stat = await entity.stat();
    } catch (_) {
      stat = null;
    }

    String? symlinkTarget;
    var isDirectoryLike = entity is Directory;

    final isSymlink = entity is Link || stat?.type == FileSystemEntityType.link;
    if (isSymlink) {
      try {
        symlinkTarget = await Link(entity.path).target();
      } catch (_) {
        symlinkTarget = null;
      }

      try {
        final resolvedPath = await Link(entity.path).resolveSymbolicLinks();
        if (await Directory(resolvedPath).exists()) {
          isDirectoryLike = true;
        }
      } catch (_) {
        // Ignore broken or inaccessible symlinks.
      }
    }

    return _FilePickerEntry(
      entity: entity,
      name: _basename(entity.path),
      stat: stat,
      isDirectoryLike: isDirectoryLike,
      symlinkTarget: symlinkTarget,
    );
  }

  bool _isExtensionAllowed(_FilePickerEntry entry) {
    if (entry.isDirectoryLike || widget.allowedExtensions.isEmpty) {
      return true;
    }

    final name = entry.name.toLowerCase();
    return widget.allowedExtensions.any((extension) {
      final normalized = extension.toLowerCase();
      return name.endsWith(normalized);
    });
  }

  bool _canSelect(_FilePickerEntry entry) {
    if (entry.isDirectoryLike) return widget.directoryAllowed;
    if (!widget.fileAllowed) return false;
    return _isExtensionAllowed(entry);
  }

  String _selectionError(_FilePickerEntry entry) {
    if (entry.isDirectoryLike && !widget.directoryAllowed) {
      return 'Directory selection is disabled.';
    }
    if (!entry.isDirectoryLike && !widget.fileAllowed) {
      return 'File selection is disabled.';
    }
    if (!_isExtensionAllowed(entry)) {
      final allowed = widget.allowedExtensions.join(', ');
      return '${entry.name} is not allowed. Use: $allowed';
    }
    return 'Selection is unavailable.';
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Cmd? _moveSelection(int delta) {
    if (_entries.isEmpty) return null;
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(0, _entries.length - 1);
      _errorMessage = null;
    });
    _updateListMetrics();
    _scrollSelectionIntoView();
    return null;
  }

  Cmd? _jumpToEdge(bool toEnd) {
    if (_entries.isEmpty) return null;
    setState(() {
      _selectedIndex = toEnd ? _entries.length - 1 : 0;
      _errorMessage = null;
    });
    _updateListMetrics();
    _scrollSelectionIntoView();
    return null;
  }

  Cmd? _pageSelection(int direction) {
    if (_entries.isEmpty) return null;
    final delta = math.max(1, _lastListHeight) * direction;
    return _moveSelection(delta);
  }

  Cmd? _toggleHidden() {
    setState(() {
      _showHidden = !_showHidden;
      _entries = const [];
      _selectedIndex = 0;
      _loading = true;
      _errorMessage = null;
    });
    _pendingScrollOffset = 0;
    return _loadDirectory(_currentDirectory);
  }

  Cmd? _goUpDirectory() {
    final parent = Directory(_currentDirectory).parent.path;
    if (parent == _currentDirectory) return null;

    final restore = _history.isEmpty ? null : _history.removeLast();
    setState(() {
      _currentDirectory = parent;
      _entries = const [];
      _selectedIndex = restore?.selectedIndex ?? 0;
      _loading = true;
      _errorMessage = null;
    });
    _pendingScrollOffset = restore?.scrollOffset ?? 0;
    return _loadDirectory(_currentDirectory);
  }

  Cmd? _openSelectedDirectory() {
    final entry = _selectedEntry;
    if (entry == null || !entry.isDirectoryLike) return null;

    setState(() {
      _history.add(
        _FilePickerViewState(
          directory: _currentDirectory,
          selectedIndex: _selectedIndex,
          scrollOffset: _listController.offset,
        ),
      );
      _currentDirectory = entry.entity.path;
      _entries = const [];
      _selectedIndex = 0;
      _loading = true;
      _errorMessage = null;
    });
    _pendingScrollOffset = 0;
    return _loadDirectory(_currentDirectory);
  }

  Cmd? _selectCurrentEntry() {
    final entry = _selectedEntry;
    if (entry == null) return null;

    if (!_canSelect(entry)) {
      if (entry.isDirectoryLike && !widget.directoryAllowed) {
        return _openSelectedDirectory();
      }
      _setError(_selectionError(entry));
      return null;
    }

    setState(() {
      _errorMessage = null;
    });
    return widget.onSelected?.call(entry.entity.path);
  }

  Cmd? _handleRowTap(int index) {
    if (index < 0 || index >= _entries.length) return null;

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _errorMessage = null;
      });
      _updateListMetrics();
      _scrollSelectionIntoView();
      return null;
    }

    return _selectCurrentEntry();
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    switch (msg) {
      case _FilePickerLoadedMsg():
        if (msg.requestId != _requestId || msg.directory != _currentDirectory) {
          return null;
        }
        setState(() {
          _entries = msg.entries;
          _loading = false;
          _errorMessage = null;
          _selectedIndex = _selectedIndex.clamp(
            0,
            math.max(0, _entries.length - 1),
          );
        });
        _updateListMetrics();
        _applyPendingScrollOffset();
        _scrollSelectionIntoView();
        return null;
      case _FilePickerErrorMsg():
        if (msg.requestId != _requestId || msg.directory != _currentDirectory) {
          return null;
        }
        setState(() {
          _entries = const [];
          _loading = false;
          _errorMessage = msg.error;
          _selectedIndex = 0;
        });
        _pendingScrollOffset = 0;
        _updateListMetrics();
        _listController.jumpTo(0);
        return null;
      default:
        return null;
    }
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

    if (key.type == terminal_keys.KeyType.up ||
        _matchesLowerChar(key, 'k') ||
        (key.ctrl && _matchesLowerChar(key, 'p'))) {
      return _moveSelection(-1) ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.down ||
        _matchesLowerChar(key, 'j') ||
        (key.ctrl && _matchesLowerChar(key, 'n'))) {
      return _moveSelection(1) ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.pageUp ||
        _matchesChar(key, 'K') ||
        (key.ctrl && _matchesLowerChar(key, 'u'))) {
      return _pageSelection(-1) ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.pageDown ||
        _matchesChar(key, 'J') ||
        (key.ctrl && _matchesLowerChar(key, 'd'))) {
      return _pageSelection(1) ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.home || _matchesChar(key, 'g')) {
      return _jumpToEdge(false) ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.end || _matchesChar(key, 'G')) {
      return _jumpToEdge(true) ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.backspace ||
        key.type == terminal_keys.KeyType.left ||
        _matchesLowerChar(key, 'h')) {
      return _goUpDirectory() ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.right ||
        _matchesLowerChar(key, 'l')) {
      return _openSelectedDirectory() ?? Cmd.none();
    }

    if (_matchesChar(key, '.')) {
      return _toggleHidden() ?? Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.enter) {
      return _selectCurrentEntry() ?? Cmd.none();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final media = MediaQuery.of(context);
    final width = widget.width ?? math.max(48, media.size.width.toInt() - 4);
    final listHeight = _effectiveListHeight(media);
    _lastListHeight = listHeight;
    _updateListMetrics(listHeight);
    _applyPendingScrollOffset(listHeight);

    final selectedEntry = _selectedEntry;
    final compactFooter = width < 64;
    final canGoUp =
        Directory(_currentDirectory).parent.path != _currentDirectory;
    final openButtonVisible =
        selectedEntry != null &&
        selectedEntry.isDirectoryLike &&
        widget.directoryAllowed;
    final primaryLabel =
        selectedEntry != null &&
            selectedEntry.isDirectoryLike &&
            !widget.directoryAllowed
        ? widget.openLabel
        : widget.selectLabel;
    final metaWidth = width - 4;
    final showPermissions = widget.showPermissions && metaWidth >= 62;
    final showSize = widget.showSize && metaWidth >= 48;
    final visibleStart = _entries.isEmpty
        ? 0
        : math.min(_entries.length, _listController.offset + 1);
    final visibleEnd = _entries.isEmpty
        ? 0
        : math.min(_entries.length, _listController.offset + listHeight);
    final countLabel = _entries.isEmpty
        ? '0 items'
        : '$visibleStart-$visibleEnd of ${_entries.length}';
    final hiddenLabel = _showHidden ? 'hidden on' : 'hidden off';
    final extensionLabel = widget.allowedExtensions.isEmpty
        ? 'all files'
        : widget.allowedExtensions.join(', ');

    final subtleStyle = theme.bodySmall.copy()..foreground(theme.muted);
    final errorStyle = theme.bodySmall.copy()
      ..foreground(theme.error)
      ..bold();

    return SizedBox(
      width: widget.width,
      child: Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null)
            Text(widget.title!, style: theme.titleLarge),
          if (widget.title != null) Divider(),
          Text('Current directory', style: theme.labelMedium),
          Text(
            _currentDirectory,
            style: subtleStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            maxWidth: math.max(12, width - 2),
          ),
          Text(
            '$countLabel | $hiddenLabel | $extensionLabel',
            style: subtleStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            maxWidth: math.max(12, width - 2),
          ),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: errorStyle,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              maxWidth: math.max(12, width - 2),
            ),
          Card(
            padding: const EdgeInsets.all(0),
            background: theme.surface,
            child: SizedBox(
              height: listHeight,
              child: Scrollbar(
                controller: _listController,
                trackStyle: theme.bodySmall.copy()..foreground(theme.muted),
                thumbStyle: theme.bodySmall.copy()..foreground(theme.primary),
                child: SingleChildScrollView(
                  controller: _listController,
                  handleKeys: false,
                  child: Column(
                    gap: 0,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildListRows(
                      context,
                      width: width,
                      showPermissions: showPermissions,
                      showSize: showSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(
            compactFooter: compactFooter,
            canGoUp: canGoUp,
            openButtonVisible: openButtonVisible,
            primaryLabel: primaryLabel,
          ),
          if (widget.showHelp)
            HelpView(
              keyMap: _FilePickerHelpKeyMap(showExit: widget.onExit != null),
              itemSpacing: 2,
              runSpacing: 0,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildListRows(
    BuildContext context, {
    required int width,
    required bool showPermissions,
    required bool showSize,
  }) {
    final theme = ThemeScope.of(context);
    if (_loading) {
      return <Widget>[
        Container(
          color: theme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
          child: Text('Loading files...', style: theme.bodyMedium),
        ),
      ];
    }

    if (_entries.isEmpty) {
      return <Widget>[
        Container(
          color: theme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
          child: Text('No files found.', style: theme.bodyMedium),
        ),
      ];
    }

    return List<Widget>.generate(
      _entries.length,
      (index) => _FilePickerRow(
        entry: _entries[index],
        selected: index == _selectedIndex,
        disabled: !_canSelect(_entries[index]),
        showPermissions: showPermissions,
        showSize: showSize,
        availableWidth: math.max(16, width - 5),
        onTap: () => _handleRowTap(index),
      ),
      growable: false,
    );
  }

  Widget _buildFooter({
    required bool compactFooter,
    required bool canGoUp,
    required bool openButtonVisible,
    required String primaryLabel,
  }) {
    final selectedEntry = _selectedEntry;
    final primaryEnabled = !_loading && selectedEntry != null;
    final openEnabled =
        !_loading && selectedEntry != null && selectedEntry.isDirectoryLike;

    final upButton = Button(
      label: widget.parentLabel,
      variant: ButtonVariant.ghost,
      enabled: canGoUp && !_loading,
      onPressed: _goUpDirectory,
    );
    final openButton = Button(
      label: widget.openLabel,
      variant: ButtonVariant.secondary,
      enabled: openEnabled,
      onPressed: _openSelectedDirectory,
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
    final primaryButton = Button(
      label: primaryLabel,
      enabled: primaryEnabled,
      onPressed: _selectCurrentEntry,
    );

    final trailing = <Widget>[
      if (openButtonVisible) openButton,
      ?exitButton,
      cancelButton,
      primaryButton,
    ];

    if (compactFooter) {
      return Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primaryButton,
          Wrap(
            spacing: 1,
            runSpacing: 1,
            children: [
              upButton,
              if (openButtonVisible) openButton,
              cancelButton,
              ?exitButton,
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        upButton,
        Row(gap: 1, children: trailing),
      ],
    );
  }
}

class _FilePickerLoadedMsg extends Msg {
  const _FilePickerLoadedMsg(this.requestId, this.directory, this.entries);

  final int requestId;
  final String directory;
  final List<_FilePickerEntry> entries;
}

class _FilePickerErrorMsg extends Msg {
  const _FilePickerErrorMsg(this.requestId, this.directory, this.error);

  final int requestId;
  final String directory;
  final String error;
}

class _FilePickerViewState {
  const _FilePickerViewState({
    required this.directory,
    required this.selectedIndex,
    required this.scrollOffset,
  });

  final String directory;
  final int selectedIndex;
  final int scrollOffset;
}

class _FilePickerEntry {
  const _FilePickerEntry({
    required this.entity,
    required this.name,
    required this.stat,
    required this.isDirectoryLike,
    required this.symlinkTarget,
  });

  final FileSystemEntity entity;
  final String name;
  final FileStat? stat;
  final bool isDirectoryLike;
  final String? symlinkTarget;

  bool get isSymlink =>
      entity is Link || stat?.type == FileSystemEntityType.link;

  int get size => stat?.size ?? 0;

  String get permissions {
    final mode = stat?.mode;
    if (mode == null) return '---------';
    return _modeString(mode);
  }

  static String _modeString(int mode) {
    final buffer = StringBuffer();
    buffer.write(mode & 0x100 != 0 ? 'r' : '-');
    buffer.write(mode & 0x80 != 0 ? 'w' : '-');
    buffer.write(mode & 0x40 != 0 ? 'x' : '-');
    buffer.write(mode & 0x20 != 0 ? 'r' : '-');
    buffer.write(mode & 0x10 != 0 ? 'w' : '-');
    buffer.write(mode & 0x8 != 0 ? 'x' : '-');
    buffer.write(mode & 0x4 != 0 ? 'r' : '-');
    buffer.write(mode & 0x2 != 0 ? 'w' : '-');
    buffer.write(mode & 0x1 != 0 ? 'x' : '-');
    return buffer.toString();
  }
}

class _FilePickerRow extends StatelessWidget {
  _FilePickerRow({
    required this.entry,
    required this.selected,
    required this.disabled,
    required this.showPermissions,
    required this.showSize,
    required this.availableWidth,
    required this.onTap,
  });

  final _FilePickerEntry entry;
  final bool selected;
  final bool disabled;
  final bool showPermissions;
  final bool showSize;
  final int availableWidth;
  final CmdCallback onTap;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final background = selected
        ? theme.listRowSelectedBackground
        : theme.listRowBackground;
    final foreground = selected
        ? entry.isDirectoryLike
              ? theme.listRowSelectedAccentForeground
              : theme.listRowSelectedForeground
        : disabled
        ? theme.muted
        : entry.isDirectoryLike
        ? theme.secondary
        : theme.listRowForeground;
    final meta = selected
        ? theme.listRowSelectedMutedForeground
        : theme.listRowMutedForeground;
    final cursor = selected
        ? theme.listRowSelectedMarkerForeground
        : theme.listRowMutedForeground;

    final cursorStyle = theme.labelMedium.copy()..foreground(cursor);
    final metaStyle = theme.bodySmall.copy()..foreground(meta);
    final nameStyle = theme.bodyMedium.copy()..foreground(foreground);
    if (selected) {
      nameStyle.bold();
    } else if (disabled) {
      nameStyle.dim();
    }

    final label = _entryLabel(entry, availableWidth);
    final spans = <TextSpan>[
      TextSpan(style: cursorStyle, text: selected ? '> ' : '  '),
      if (showPermissions)
        TextSpan(style: metaStyle, text: '${entry.permissions} '),
      if (showSize)
        TextSpan(
          style: metaStyle,
          text: '${_formatSize(entry.size).padLeft(8)} ',
        ),
      TextSpan(style: nameStyle, text: label),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
        child: Text.rich(
          TextSpan(children: spans),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          maxWidth: math.max(8, availableWidth),
        ),
      ),
    );
  }

  String _entryLabel(_FilePickerEntry entry, int availableWidth) {
    var label = entry.name;
    if (entry.isDirectoryLike) {
      label = '$label/';
    }
    if (entry.isSymlink &&
        entry.symlinkTarget != null &&
        availableWidth >= 56) {
      label = '$label -> ${entry.symlinkTarget}';
    }
    return label;
  }
}

final class _FilePickerHelpKeyMap extends KeyMap {
  _FilePickerHelpKeyMap({required bool showExit}) {
    final bindings = <KeyBinding>[
      KeyBinding.withHelp(['up', 'k'], 'up/k', 'move'),
      KeyBinding.withHelp(['down', 'j'], 'down/j', 'move'),
      KeyBinding.withHelp(['enter'], 'enter', 'select'),
      KeyBinding.withHelp(['right', 'l'], 'right/l', 'open'),
      KeyBinding.withHelp(['left', 'backspace'], 'left', 'up'),
      KeyBinding.withHelp(['.'], '.', 'hidden'),
      KeyBinding.withHelp(['esc'], 'esc', 'cancel'),
      if (showExit) KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'quit'),
    ];
    shortHelp = bindings;
    fullHelp = [bindings];
  }
}

String _basename(String path) {
  var value = path;
  while (value.length > 1 &&
      (value.endsWith(Platform.pathSeparator) ||
          value.endsWith('/') ||
          value.endsWith(r'\'))) {
    value = value.substring(0, value.length - 1);
  }

  if (value == Platform.pathSeparator || value == '/' || value == r'\') {
    return value;
  }

  final slash = value.lastIndexOf('/');
  final backslash = value.lastIndexOf(r'\');
  final index = math.max(slash, backslash);
  if (index < 0 || index == value.length - 1) {
    return value;
  }
  return value.substring(index + 1);
}
