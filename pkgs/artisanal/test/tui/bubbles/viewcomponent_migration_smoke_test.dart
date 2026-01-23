import 'dart:io';

import 'package:artisanal/src/tui/bubbles/anticipate.dart';
import 'package:artisanal/src/tui/bubbles/confirm.dart';
import 'package:artisanal/src/tui/bubbles/cursor.dart';
import 'package:artisanal/src/tui/bubbles/filepicker.dart';
import 'package:artisanal/src/tui/bubbles/pause.dart';
import 'package:artisanal/src/tui/bubbles/password.dart';
import 'package:artisanal/src/tui/bubbles/search.dart';
import 'package:artisanal/src/tui/bubbles/select.dart';
import 'package:artisanal/src/tui/bubbles/stopwatch.dart';
import 'package:artisanal/src/tui/bubbles/table.dart';
import 'package:artisanal/src/tui/bubbles/timer.dart';
import 'package:artisanal/src/tui/bubbles/wizard.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('Bubbles ViewComponent migration', () {
    test('models instantiate as ViewComponent', () {
      final models = <ViewComponent>[
        TimerModel(timeout: const Duration(seconds: 1)),
        StopwatchModel(),
        CursorModel(),
        PauseModel(),
        CountdownModel(duration: const Duration(seconds: 1)),
        TableModel(
          columns: [Column(title: 'A', width: 1)],
          rows: [
            ['x'],
          ],
        ),
        AnticipateModel().focus(),
        ConfirmModel(prompt: 'Confirm?'),
        DestructiveConfirmModel(prompt: 'Type YES', confirmText: 'YES'),
        PasswordModel(),
        PasswordConfirmModel(),
        SearchModel<String>(items: const ['a', 'b']),
        SelectModel<String>(items: const ['a', 'b']),
        MultiSelectModel<String>(items: const ['a', 'b']),
        WizardModel(
          steps: const [TextInputStep(key: 'name', prompt: 'Name')],
        ),
        FilePickerModel(currentDirectory: Directory.systemTemp.path),
      ];

      for (final m in models) {
        expect(m, isA<ViewComponent>());
        // Smoke: update through base type
        final (next, _) = m.update(const KeyMsg(Key(KeyType.escape)));
        expect(next, isA<ViewComponent>());
      }
    });
  });
}
