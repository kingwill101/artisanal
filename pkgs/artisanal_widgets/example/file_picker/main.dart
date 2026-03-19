import 'dart:io' as io;
import 'dart:math' as math;

import 'package:artisanal/app.dart' as app;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/widgets.dart' as w;

void main() async {
  await app.runArtisanalApp(
    app.ArtisanalApp(
      title: 'File Picker Showcase',
      home: FilePickerShowcaseScreen(),
    ),
  );
}

class FilePickerShowcaseScreen extends w.StatefulWidget {
  FilePickerShowcaseScreen({this.initialDirectory, super.key});

  final String? initialDirectory;

  @override
  w.State createState() => _FilePickerShowcaseState();
}

class _FilePickerShowcaseState extends w.State<FilePickerShowcaseScreen> {
  String? _selectedPath;
  bool _cancelled = false;

  String get _initialDirectory =>
      widget.initialDirectory ??
      io.Platform.environment['HOME'] ??
      io.Directory.current.path;

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = math.min(84, math.max(48, media.size.width.toInt() - 4));
    final listHeight = math.max(6, media.size.height.toInt() - 22);

    return w.Center(
      child: w.SizedBox(
        width: width,
        child: w.Padding(
          padding: const w.EdgeInsets.all(1),
          child: _selectedPath != null || _cancelled
              ? _buildSummary(context)
              : _buildPicker(width, listHeight),
        ),
      ),
    );
  }

  w.Widget _buildPicker(int width, int listHeight) {
    return w.FilePicker(
      title: 'Browse project files',
      directory: _initialDirectory,
      width: width,
      height: listHeight,
      allowedExtensions: const ['.dart', '.md', '.yaml', '.yml'],
      onSelected: (path) {
        setState(() {
          _selectedPath = path;
          _cancelled = false;
        });
        return null;
      },
      onCancelled: () {
        setState(() {
          _cancelled = true;
        });
        return null;
      },
      onExit: runtime.Cmd.quit,
    );
  }

  w.Widget _buildSummary(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final subtleStyle = theme.bodySmall.copy()..foreground(theme.muted);

    return w.Column(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Card(
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text(
                _cancelled ? 'Picker cancelled' : 'Selection ready',
                style: theme.titleMedium,
              ),
              w.Text(
                _cancelled ? 'No file was selected.' : _selectedPath ?? '-',
                style: _cancelled ? subtleStyle : theme.bodyMedium,
                overflow: w.TextOverflow.ellipsis,
                maxWidth: 72,
              ),
            ],
          ),
        ),
        w.Row(
          mainAxisAlignment: w.MainAxisAlignment.end,
          children: [
            w.Button(
              label: 'Browse again',
              onPressed: () {
                setState(() {
                  _selectedPath = null;
                  _cancelled = false;
                });
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }
}
