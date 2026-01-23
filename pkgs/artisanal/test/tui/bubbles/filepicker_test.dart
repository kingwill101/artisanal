import 'dart:io';

import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/tui/bubbles/filepicker.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

/// Helper to create a KeyMsg with a character key
KeyMsg keyChar(String c) => KeyMsg(Keys.char(c));

/// Helper to create a KeyMsg with enter
KeyMsg keyEnter() => KeyMsg(Keys.enter);

void main() {
  group('FileEntry', () {
    test('creates from file system entity', () {
      final entry = FileEntry(entity: Directory.current);
      expect(entry.name, isNotEmpty);
      expect(entry.entity, isNotNull);
    });

    test('isDirectory returns true for directories', () {
      final entry = FileEntry(entity: Directory.current);
      expect(entry.isDirectory, isTrue);
    });

    test('permissions format correctly', () {
      final entry = FileEntry(entity: Directory.current);
      final perms = entry.permissions;
      expect(perms.length, 9);
    });
  });

  group('FilePickerKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = FilePickerKeyMap();
      expect(keyMap.down.keys, contains('j'));
      expect(keyMap.down.keys, contains('down'));
      expect(keyMap.up.keys, contains('k'));
      expect(keyMap.up.keys, contains('up'));
      expect(keyMap.open.keys, contains('enter'));
      expect(keyMap.back.keys, contains('backspace'));
    });

    test('fullHelp returns all bindings', () {
      final keyMap = FilePickerKeyMap();
      expect(keyMap.fullHelp.length, 10);
    });

    test('shortHelp returns subset of bindings', () {
      final keyMap = FilePickerKeyMap();
      expect(keyMap.shortHelp.length, 4);
    });
  });

  group('FilePickerStyles', () {
    test('creates with default styles', () {
      final styles = FilePickerStyles();
      expect(styles.cursor, isNotNull);
      expect(styles.directory, isNotNull);
      expect(styles.file, isNotNull);
      expect(styles.symlink, isNotNull);
      expect(styles.selected, isNotNull);
    });
  });

  group('FilePickerModel', () {
    group('New', () {
      test('creates with current directory', () {
        final picker = FilePickerModel(
          currentDirectory: Directory.current.path,
        );
        expect(picker.currentDirectory, Directory.current.path);
      });

      test('creates with allowed types', () {
        final picker = FilePickerModel(
          currentDirectory: '/tmp',
          allowedTypes: ['.dart', '.yaml'],
        );
        expect(picker.allowedTypes, ['.dart', '.yaml']);
      });

      test('defaults to file allowed and dir not allowed', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        expect(picker.fileAllowed, isTrue);
        expect(picker.dirAllowed, isFalse);
      });

      test('defaults to hiding hidden files', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        expect(picker.showHidden, isFalse);
      });

      test('defaults to showing permissions and size', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        expect(picker.showPermissions, isTrue);
        expect(picker.showSize, isTrue);
      });

      test('has unique id', () {
        final p1 = FilePickerModel(currentDirectory: '/tmp');
        final p2 = FilePickerModel(currentDirectory: '/tmp');
        expect(p1.id, isNot(p2.id));
      });

      test('starts with default height of 10', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        expect(picker.height, 10);
      });
    });
    group('Parity Features', () {
      test('setAllowedExtensions parity', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        picker.setAllowedExtensions(['.txt']);
        expect(picker.allowedTypes, ['.txt']);
      });

      test('setDirAllowed parity', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        picker.setDirAllowed(true);
        expect(picker.dirAllowed, isTrue);
      });

      test('setFileAllowed parity', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        picker.setFileAllowed(false);
        expect(picker.fileAllowed, isFalse);
      });

      test('setHeight parity', () {
        final picker = FilePickerModel(currentDirectory: '/tmp', height: 10);
        picker.setHeight(20);
        expect(picker.height, 20);
      });
    });
    group('init', () {
      test('returns command to read directory', () {
        final picker = FilePickerModel(
          currentDirectory: Directory.current.path,
        );
        final cmd = picker.init();
        expect(cmd, isNotNull);
      });
    });

    group('canSelect', () {
      test('returns true when no allowed types set', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        expect(picker.canSelect('anything.txt'), isTrue);
      });

      test('returns true when file matches allowed type', () {
        final picker = FilePickerModel(
          currentDirectory: '/tmp',
          allowedTypes: ['.dart', '.yaml'],
        );
        expect(picker.canSelect('main.dart'), isTrue);
        expect(picker.canSelect('pubspec.yaml'), isTrue);
      });

      test('returns false when file does not match allowed type', () {
        final picker = FilePickerModel(
          currentDirectory: '/tmp',
          allowedTypes: ['.dart'],
        );
        expect(picker.canSelect('readme.md'), isFalse);
        expect(picker.canSelect('file.txt'), isFalse);
      });
    });

    group('update', () {
      group('FilePickerReadDirMsg', () {
        test('ignores messages with wrong id', () {
          final picker = FilePickerModel(currentDirectory: '/tmp');
          final (updated, cmd) = picker.update(FilePickerReadDirMsg(999, []));
          expect((updated).files, isEmpty);
          expect(cmd, isNull);
        });

        test('populates files from message', () {
          final picker = FilePickerModel(currentDirectory: '/tmp');
          final entities = [Directory('/tmp/subdir'), File('/tmp/file.txt')];
          final (updated, cmd) = picker.update(
            FilePickerReadDirMsg(picker.id, entities),
          );
          final model = updated;
          // Directories are sorted first
          expect(model.files.length, 2);
          expect(cmd, isNull);
        });
      });

      group('FilePickerErrorMsg', () {
        test('ignores messages with wrong id', () {
          final picker = FilePickerModel(currentDirectory: '/tmp');
          final (updated, cmd) = picker.update(
            FilePickerErrorMsg(999, 'error'),
          );
          expect(updated, isA<FilePickerModel>());
          expect(cmd, isNull);
        });

        test('ignores errors and keeps current state', () {
          final picker = FilePickerModel(currentDirectory: '/tmp');
          final (updated, cmd) = picker.update(
            FilePickerErrorMsg(picker.id, 'error'),
          );
          expect(updated, isA<FilePickerModel>());
          expect(cmd, isNull);
        });
      });

      group('KeyMsg navigation', () {
        late FilePickerModel picker;

        setUp(() {
          picker = FilePickerModel(currentDirectory: '/tmp');
          // Populate with some files
          final entities = [
            Directory('/tmp/dir1'),
            Directory('/tmp/dir2'),
            File('/tmp/file1.txt'),
            File('/tmp/file2.txt'),
            File('/tmp/file3.txt'),
          ];
          final (updated, _) = picker.update(
            FilePickerReadDirMsg(picker.id, entities),
          );
          picker = updated;
        });

        test('down moves selection down', () {
          expect(picker.selected, 0);
          final (updated, _) = picker.update(keyChar('j'));
          expect((updated).selected, 1);
        });

        test('up moves selection up', () {
          // First move down
          var (updated, _) = picker.update(keyChar('j'));
          picker = updated;
          expect(picker.selected, 1);

          // Then move up
          (updated, _) = picker.update(keyChar('k'));
          expect((updated).selected, 0);
        });

        test('up does not go below 0', () {
          expect(picker.selected, 0);
          final (updated, _) = picker.update(keyChar('k'));
          expect((updated).selected, 0);
        });

        test('go to top moves to first item', () {
          // First move down
          var (updated, _) = picker.update(keyChar('j'));
          (updated, _) = (updated).update(keyChar('j'));
          picker = updated;
          expect(picker.selected, 2);

          // Go to top
          (updated, _) = picker.update(keyChar('g'));
          expect((updated).selected, 0);
        });

        test('go to last moves to last item', () {
          expect(picker.selected, 0);
          final (updated, _) = picker.update(keyChar('G'));
          expect((updated).selected, picker.files.length - 1);
        });
      });

      test('returns unchanged model for unknown messages', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        final (updated, cmd) = picker.update(_UnknownMsg());
        expect(updated, isA<FilePickerModel>());
        expect(cmd, isNull);
      });
    });

    group('view', () {
      test('shows empty directory message when no files', () {
        final picker = FilePickerModel(currentDirectory: '/tmp', height: 5);
        final view = picker.view();
        expect(Ansi.stripAnsi(view), contains('Bummer. No Files Found.'));
      });

      test('renders files', () {
        var picker = FilePickerModel(
          currentDirectory: '/tmp',
          showPermissions: false,
          showSize: false,
        );
        final entities = [File('/tmp/test.txt')];
        final (updated, _) = picker.update(
          FilePickerReadDirMsg(picker.id, entities),
        );
        picker = updated;
        final view = picker.view();
        expect(view, contains('test.txt'));
      });
    });

    group('copyWith', () {
      test('copies all fields', () {
        final picker = FilePickerModel(
          currentDirectory: '/tmp',
          allowedTypes: ['.dart'],
          fileAllowed: true,
          dirAllowed: false,
          showHidden: false,
          height: 10,
        );
        final copied = picker.copyWith(
          currentDirectory: '/home',
          height: 20,
          showHidden: true,
        );
        expect(copied.currentDirectory, '/home');
        expect(copied.height, 20);
        expect(copied.showHidden, isTrue);
        expect(copied.allowedTypes, ['.dart']);
        expect(copied.id, picker.id);
      });

      test('preserves unchanged fields', () {
        final picker = FilePickerModel(currentDirectory: '/tmp', height: 15);
        final copied = picker.copyWith(currentDirectory: '/home');
        expect(copied.currentDirectory, '/home');
        expect(copied.height, 15);
      });
    });

    group('didSelectFile', () {
      test('returns false for non-KeyMsg', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        final (didSelect, path) = picker.didSelectFile(_UnknownMsg());
        expect(didSelect, isFalse);
        expect(path, isNull);
      });

      test('returns false when no files', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        final (didSelect, path) = picker.didSelectFile(keyEnter());
        expect(didSelect, isFalse);
        expect(path, isNull);
      });
    });

    group('didSelectDisabledFile', () {
      test('returns false for non-KeyMsg', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        final (didSelect, path) = picker.didSelectDisabledFile(_UnknownMsg());
        expect(didSelect, isFalse);
        expect(path, isNull);
      });

      test('returns false when no files', () {
        final picker = FilePickerModel(currentDirectory: '/tmp');
        final (didSelect, path) = picker.didSelectDisabledFile(keyEnter());
        expect(didSelect, isFalse);
        expect(path, isNull);
      });
    });
  });
}

class _UnknownMsg extends Msg {}
