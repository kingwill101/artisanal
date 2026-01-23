import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  test('Console title has deterministic output when ansi is disabled', () {
    final out = StringBuffer();
    final err = StringBuffer();
    final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
    final io = Console(renderer: renderer, out: out.writeln, err: err.writeln);

    io.title('Hello');

    expect(err.toString(), isEmpty);
    expect(out.toString(), contains('Hello'));
    expect(out.toString(), contains('====='));
    expect(out.toString(), isNot(contains('\x1B[')));
  });

  test('Console table alignment ignores ANSI sequences', () {
    final out = StringBuffer();
    final renderer = StringRenderer(colorProfile: ColorProfile.trueColor);
    final io = Console(renderer: renderer, out: out.writeln, err: (_) {});

    io.table(
      headers: ['status'],
      rows: [
        [io.style.foreground(Colors.success).render('DONE')],
      ],
    );

    final rendered = out.toString();
    expect(rendered, contains('\x1B['));
    expect(Style.stripAnsi(rendered), contains('DONE'));
    expect(Style.stripAnsi(rendered), contains('+'));
  });

  test('Console confirm returns default in non-interactive mode', () {
    final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
    final io = Console(
      renderer: renderer,
      out: (_) {},
      err: (_) {},
      interactive: false,
    );

    expect(io.confirm('Continue?', defaultValue: true), isTrue);
    expect(io.confirm('Continue?', defaultValue: false), isFalse);
  });

  test('Console confirm reads input in interactive mode', () {
    final inputs = <String>['n', 'yes'];
    String? readLine() => inputs.removeAt(0);

    final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
    final io = Console(
      renderer: renderer,
      out: (_) {},
      err: (_) {},
      readLine: readLine,
      interactive: true,
    );

    expect(io.confirm('Continue?', defaultValue: true), isFalse);
    expect(io.confirm('Continue?', defaultValue: false), isTrue);
  });

  group('secret()', () {
    test('returns fallback in non-interactive mode', () async {
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(
        renderer: renderer,
        out: (_) {},
        err: (_) {},
        interactive: false,
      );

      expect(await io.secret('Password', fallback: 'default123'), 'default123');
    });

    test('throws in non-interactive mode without fallback', () async {
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(
        renderer: renderer,
        out: (_) {},
        err: (_) {},
        interactive: false,
      );

      expect(() => io.secret('Password'), throwsStateError);
    });

    test('uses injected secretReader when provided', () async {
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(
        renderer: renderer,
        out: (_) {},
        err: (_) {},
        interactive: true,
        secretReader: (prompt, {fallback}) => 'injected-secret',
      );

      expect(await io.secret('Password'), 'injected-secret');
    });
  });

  group('components', () {
    test('provides access to Components facade', () {
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(renderer: renderer, out: (_) {}, err: (_) {});

      expect(io.components, isA<Components>());
      // Same instance on repeated access
      expect(io.components, same(io.components));
    });

    test('components.bulletList outputs formatted list', () {
      final out = StringBuffer();
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(renderer: renderer, out: out.writeln, err: (_) {});

      io.components.bulletList(['Item 1', 'Item 2', 'Item 3']);

      final output = out.toString();
      expect(output, contains('Item 1'));
      expect(output, contains('Item 2'));
      expect(output, contains('Item 3'));
      expect(output, contains('•'));
    });

    test('components.definitionList outputs aligned terms', () {
      final out = StringBuffer();
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(renderer: renderer, out: out.writeln, err: (_) {});

      io.components.definitionList({
        'Name': 'My Application',
        'Version': '1.0.0',
      });

      final output = out.toString();
      expect(output, contains('Name'));
      expect(output, contains('My Application'));
      expect(output, contains('Version'));
      expect(output, contains('1.0.0'));
      expect(output, contains('.')); // dot fill
    });

    test('components.rule outputs horizontal separator', () {
      final out = StringBuffer();
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(renderer: renderer, out: out.writeln, err: (_) {});

      io.components.rule();
      io.components.rule('Section');

      final output = out.toString();
      expect(output, contains('─')); // horizontal line character
      expect(output, contains('Section'));
    });

    test('components.twoColumnDetail delegates to io', () {
      final out = StringBuffer();
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(renderer: renderer, out: out.writeln, err: (_) {});

      io.components.twoColumnDetail('Key', 'Value');

      final output = out.toString();
      expect(output, contains('Key'));
      expect(output, contains('Value'));
    });
  });

  group('selectChoice / multiSelectChoice', () {
    test('selectChoice returns default in non-interactive mode', () async {
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(
        renderer: renderer,
        out: (_) {},
        err: (_) {},
        interactive: false,
      );

      final result = await io.selectChoice(
        'Pick one',
        choices: ['A', 'B', 'C'],
        defaultIndex: 1,
      );

      expect(result, 'B');
    });

    test('selectChoice throws in non-interactive mode without default', () {
      final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
      final io = Console(
        renderer: renderer,
        out: (_) {},
        err: (_) {},
        interactive: false,
      );

      expect(
        () => io.selectChoice('Pick one', choices: ['A', 'B', 'C']),
        throwsStateError,
      );
    });

    test(
      'multiSelectChoice returns defaults in non-interactive mode',
      () async {
        final renderer = StringRenderer(colorProfile: ColorProfile.ascii);
        final io = Console(
          renderer: renderer,
          out: (_) {},
          err: (_) {},
          interactive: false,
        );

        final result = await io.multiSelectChoice(
          'Pick many',
          choices: ['A', 'B', 'C'],
          defaultSelected: [0, 2],
        );

        expect(result, ['A', 'C']);
      },
    );
  });
}
