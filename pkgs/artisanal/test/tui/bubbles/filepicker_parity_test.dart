import 'dart:io';

import 'package:artisanal/src/tui/bubbles/filepicker.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('FilePicker parity behaviors', () {
    test('disabled file selection sets error and does not select', () {
      final model =
          FilePickerModel(
            currentDirectory: '/tmp',
            allowedTypes: ['.txt'],
            fileAllowed: true,
            dirAllowed: false,
            showHidden: false,
          ).copyWith(
            files: [FileEntry(entity: File('/tmp/foo.exe'))],
            selected: 0,
            min: 0,
            max: 0,
          );

      final (next, _) = model.update(const KeyMsg(Key(KeyType.enter)));
      final fm = next;
      final (didSelect, path) = fm.didSelectFile(
        const KeyMsg(Key(KeyType.enter)),
      );
      expect(didSelect, isFalse);
      expect(path, isNull);
      expect(fm.errorMessage, isNotNull);
    });

    test('toggle hidden flips flag', () {
      final model = FilePickerModel(
        currentDirectory: '/tmp',
        showHidden: false,
      );

      final (next, _) = model.update(
        const KeyMsg(Key(KeyType.runes, runes: [0x2e])), // '.'
      );
      final fm = next;
      expect(fm.showHidden, isTrue);
    });
  });
}
