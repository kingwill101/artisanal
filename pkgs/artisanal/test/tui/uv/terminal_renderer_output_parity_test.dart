import 'dart:io' show Platform;

import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/terminal_renderer_output_test.go`

final class _TestSink implements StringSink {
  final StringBuffer _b = StringBuffer();

  String get value => _b.toString();

  void reset() => _b.clear();

  @override
  void write(Object? obj) => _b.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _b.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _b.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) => _b.writeln(obj);
}

void main() {
  test('UvTerminalRenderer output parity (upstream cases)', () {
    final isWindows = Platform.isWindows;

    final cases =
        <
          ({
            String name,
            List<String> input,
            List<bool> wrap,
            bool relative,
            bool altscreen,
            List<String> expected,
          })
        >[
          (
            name: 'scroll to bottom in inline mode',
            input: ['ABC', 'XXX'],
            wrap: const [],
            relative: true,
            altscreen: false,
            expected: ['\rABC\r\n\n\n\n', '\x1b[4AXXX'],
          ),
          (
            name: 'scroll one line',
            input: [loremIpsum[0], loremIpsum[0].substring(10)],
            wrap: [true, true],
            relative: false,
            altscreen: true,
            expected: isWindows
                ? [
                    '\x1b[H\x1b[2JLorem ipsu\r\nm dolor si\r\nt amet, co\r\nnsectetur\r\nadipiscin\x1b[?7lg\x1b[?7h',
                    '\x1b[Hm dolor si\r\nt amet, co\r\nnsectetur\x1b[K\r\nadipiscing\r\n elit. Vi\x1b[?7lv\x1b[?7h',
                  ]
                : [
                    '\x1b[H\x1b[2JLorem ipsu\r\nm dolor si\r\nt amet, co\r\nnsectetur\r\nadipiscin\x1b[?7lg\x1b[?7h',
                    '\r\n elit. Vi\x1b[?7lv\x1b[?7h',
                  ],
          ),
          (
            name: 'scroll two lines',
            input: [loremIpsum[0], loremIpsum[0].substring(20)],
            wrap: [true, true],
            relative: false,
            altscreen: true,
            expected: isWindows
                ? [
                    '\x1b[H\x1b[2JLorem ipsu\r\nm dolor si\r\nt amet, co\r\nnsectetur\r\nadipiscin\x1b[?7lg\x1b[?7h',
                    '\x1b[Ht amet, co\r\nnsectetur\x1b[K\r\nadipiscing\r\n elit. Viv\r\namus at o\x1b[?7lr\x1b[?7h',
                  ]
                : [
                    '\x1b[H\x1b[2JLorem ipsu\r\nm dolor si\r\nt amet, co\r\nnsectetur\r\nadipiscin\x1b[?7lg\x1b[?7h',
                    '\r\x1b[2S\x1bM elit. Viv\r\namus at o\x1b[?7lr\x1b[?7h',
                  ],
          ),
          (
            name: 'insert line in the middle',
            input: ['ABC\nDEF\nGHI\n', 'ABC\n\nDEF\nGHI'],
            wrap: [true, true],
            relative: false,
            altscreen: true,
            expected: isWindows
                ? [
                    '\x1b[H\x1b[2JABC\r\nDEF\r\nGHI',
                    '\r\x1bM\x1b[K\nDEF\r\nGHI',
                  ]
                : ['\x1b[H\x1b[2JABC\r\nDEF\r\nGHI', '\r\x1bM\x1b[L'],
          ),
          (
            name: 'erase until end of line',
            input: ['\nABCEFGHIJK', '\nABCE      '],
            wrap: const [],
            relative: false,
            altscreen: false,
            expected: ['\x1b[2;1HABCEFGHIJK\r\n\n\n', '\x1b[2;5H\x1b[K'],
          ),
        ];

    for (final tc in cases) {
      final out = _TestSink();
      final r = UvTerminalRenderer(
        out,
        env: const ['TERM=xterm-256color', 'COLORTERM=truecolor'],
      );

      r.setScrollOptim(!isWindows);
      r.setFullscreen(tc.altscreen);
      r.setRelativeCursor(tc.relative);
      if (tc.altscreen) {
        r.saveCursor();
        r.erase();
      }

      final scr = ScreenBuffer(10, 5);
      for (var i = 0; i < tc.input.length; i++) {
        out.reset();

        final comp = newStyledString(tc.input[i]);
        if (i < tc.wrap.length) {
          comp.wrap = tc.wrap[i];
        }
        comp.draw(scr, scr.bounds());
        r.render(scr.buffer);
        r.flush();

        expect(out.value, tc.expected[i], reason: '${tc.name} output[$i]');
      }
    }
  });
}

// Copied from upstream `terminal_renderer_output_test.go`.
const loremIpsum = [
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus at ornare risus, quis lacinia magna. Suspendisse egestas purus risus, id rutrum diam porta non. Duis luctus tempus dictum. Maecenas luctus metus vitae nulla consectetur egestas. Curabitur faucibus nunc vel eros semper scelerisque. Proin dictum aliquam lacus dignissim fringilla. Praesent ut quam id dui aliquam vehicula in vitae orci. Fusce imperdiet aliquam quam. Nullam euismod magna tincidunt nisl ullamcorper, dignissim rutrum arcu rutrum. Nulla ac fringilla velit. Duis non pellentesque erat.',
  'In egestas ex et sem vulputate, congue bibendum diam ultrices. Nam auctor dictum enim, in rutrum nulla vestibulum sit amet. Vestibulum vel velit ac sem pellentesque accumsan. Vivamus pharetra mi non arcu tristique gravida. Interdum et malesuada fames ac ante ipsum primis in faucibus. Sed molestie lectus nunc, sit amet rhoncus orci laoreet vel. Nulla eget mattis massa. Nunc porta eros sollicitudin lorem dapibus luctus. Vestibulum ut turpis ut nibh tincidunt feugiat. Integer eget augue nunc. Morbi vitae ultrices neque. Nulla et convallis libero. Cras nec faucibus odio. Maecenas lacinia sed odio sit amet ultrices.',
  'Nunc at molestie massa. Phasellus commodo dui odio, quis pulvinar orci eleifend a. In et erat nec nisl auctor facilisis at at orci. Curabitur ut ligula in ipsum consequat consectetur. Suspendisse pulvinar arcu metus, et faucibus risus interdum pharetra. Vestibulum vulputate, arcu at malesuada varius, nisl turpis molestie risus, ut lobortis dolor neque vitae diam. Donec lectus libero, iaculis non diam sit amet, sagittis mattis lectus. Vestibulum a magna molestie neque molestie faucibus sagittis et ante. Etiam porta tincidunt nisi sit amet blandit. Vivamus et tellus diam. Vivamus id dolor placerat, tristique magna non, congue est. Nulla a condimentum nulla. Fusce maximus semper nunc, at bibendum mi. Nam malesuada vitae mi molestie tincidunt. Pellentesque sed vestibulum lectus, eu ultrices ligula. Phasellus id nibh tristique, ultricies diam vel, cursus odio.',
  'Integer sed mi viverra, convallis urna congue, efficitur libero. Duis non eros commodo, ultricies quam hendrerit, molestie velit. Nunc non eros vitae lectus hendrerit gravida. Nunc lacinia neque sapien, et accumsan orci elementum vel. Praesent vel interdum nisl. Duis eget diam turpis. Nunc gravida, lacus dictum congue pharetra, dui est laoreet massa, ac convallis elit est sed dui. Morbi luctus convallis dui id tristique.',
  'Praesent vitae laoreet risus. Sed ac facilisis justo. Morbi fringilla in est vel volutpat. Aliquam erat tortor, posuere ac libero sit amet, vehicula blandit sapien. Nullam feugiat purus eget sapien bibendum, id posuere risus finibus. Aliquam erat volutpat. Pellentesque ac purus accumsan, accumsan mi vel, viverra lectus. Ut sed porta erat, vitae mollis nibh. Nunc dignissim quis tellus sed blandit. Mauris id velit in odio commodo aliquet.',
];
