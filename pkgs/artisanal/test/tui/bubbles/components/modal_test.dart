import 'package:artisanal/bubbles.dart';
import 'package:test/test.dart';

void main() {
  group('renderModal', () {
    test('centers a titled dialog over the base view', () {
      final view = renderModal(
        'line one\nline two\nline three\nline four',
        ['hello world'],
        chrome: const ModalChrome(title: 'Hi', footer: ['esc close']),
        screenW: 40,
        screenH: 10,
      );
      expect(view, contains('Hi'));
      expect(view, contains('hello world'));
      expect(view, contains('esc close'));
      expect(view, contains('line one')); // base shows around dialog
    });

    test('clamps oversized dialogs to the screen', () {
      final view = renderModal(
        'base',
        [for (var i = 0; i < 50; i++) 'row $i'],
        screenW: 30,
        screenH: 8,
      );
      expect(view.split('\n').length, lessThanOrEqualTo(8));
    });

    test('preserves ANSI colors across the splice', () {
      const colored = '\x1B[31mred text here\x1B[0m';
      final view = renderModal(
        'plain base line here',
        [colored],
        screenW: 40,
        screenH: 8,
      );
      expect(view, contains('\x1B[31m'));
    });

    test('tiny screens return the base view untouched', () {
      expect(
        renderModal('base', ['x'], screenW: 5, screenH: 3),
        'base',
      );
    });
  });
}
