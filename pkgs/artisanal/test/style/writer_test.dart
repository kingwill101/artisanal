import 'dart:io' as io;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  tearDown(resetWriter);

  test('stringForProfile downsample/strip behavior', () {
    final s = Style()
        .foreground(const BasicColor('#ff00ff'))
        .bold()
        .render('hi');

    expect(stringForProfile(s, ColorProfile.trueColor), contains('38;2'));
    expect(stringForProfile(s, ColorProfile.ansi256), isNot(contains('38;2')));
    expect(stringForProfile(s, ColorProfile.ansi), isNot(contains('38;2')));
    // noColor keeps bold but drops colors
    final nc = stringForProfile(s, ColorProfile.noColor);
    expect(nc, contains('\x1b[1m'));
    expect(nc, isNot(contains('38;')));
    // ascii strips everything
    expect(stringForProfile(s, ColorProfile.ascii), equals('hi'));
  });

  test('SprintAll/Sprintf uses Writer.colorProfile', () {
    Writer = StringRenderer(colorProfile: ColorProfile.ansi);
    final colored = Style()
        .foreground(const BasicColor('#00ff00'))
        .render('ok');
    final out = SprintAll([colored]);
    expect(out, isNot(contains('38;2')));
  });

  test('Fprintln writes to sink and returns count', () {
    final path = io.Directory.systemTemp
        .createTempSync('artisanal_writer_test')
        .path;
    final file = io.File('$path/out.txt');
    final sink = file.openWrite();
    try {
      final n = Fprintln(sink, ['a', 'b']);
      expect(n, 4); // "a b\n"
    } finally {
      sink.close();
    }
  });
}
