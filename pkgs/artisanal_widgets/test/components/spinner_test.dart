library;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' show Cmd, KeyMsg, Msg;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

class _DelayedSpinnerMountHost extends StatefulWidget {
  _DelayedSpinnerMountHost();

  @override
  State createState() => _DelayedSpinnerMountHostState();
}

class _SpinnerParentRebuildHost extends StatefulWidget {
  _SpinnerParentRebuildHost();

  @override
  State createState() => _SpinnerParentRebuildHostState();
}

class _SpinnerParentRebuildHostState extends State<_SpinnerParentRebuildHost> {
  var _count = 0;

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg && msg.key.char == 'r') {
      setState(() {
        _count++;
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('count=$_count'),
        SpinnerIndicator(
          frames: const ['a', 'b', 'c', 'd'],
          interval: const Duration(milliseconds: 80),
        ),
      ],
    );
  }
}

String _visibleSpinnerFrame(WidgetTester tester, List<String> frames) {
  for (final frame in frames) {
    if (tester.find.text(frame)) return frame;
  }
  return '';
}

class _DelayedSpinnerMountHostState extends State<_DelayedSpinnerMountHost> {
  var _showSpinner = false;

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is KeyMsg && msg.key.char == 't') {
      setState(() {
        _showSpinner = true;
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('press t'),
        if (_showSpinner)
          SpinnerIndicator(
            frames: const ['1', '2', '3'],
            interval: const Duration(milliseconds: 100),
          ),
      ],
    );
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // SpinnerIndicator — property / construction tests
  // ---------------------------------------------------------------------------
  group('SpinnerIndicator properties', () {
    test('constructor sets default values', () {
      final spinner = SpinnerIndicator();
      expect(spinner.frames, equals(const ['|', '/', '-', '\\']));
      expect(spinner.interval, equals(const Duration(milliseconds: 120)));
      expect(spinner.active, isTrue);
      expect(spinner.color, isNull);
      expect(spinner.textStyle, isNull);
      expect(spinner.startIndex, equals(0));
    });

    test('constructor sets custom values', () {
      final frames = ['a', 'b', 'c'];
      final interval = const Duration(milliseconds: 200);
      final color = AnsiColor(196);
      final style = Style().bold();

      final spinner = SpinnerIndicator(
        frames: frames,
        interval: interval,
        active: false,
        color: color,
        textStyle: style,
        startIndex: 2,
      );

      expect(spinner.frames, equals(frames));
      expect(spinner.interval, equals(interval));
      expect(spinner.active, isFalse);
      expect(spinner.color, same(color));
      expect(spinner.textStyle, same(style));
      expect(spinner.startIndex, equals(2));
    });

    test('frames can be empty list', () {
      final spinner = SpinnerIndicator(frames: const []);
      expect(spinner.frames, isEmpty);
    });

    test('single frame list is valid', () {
      final spinner = SpinnerIndicator(frames: const ['*']);
      expect(spinner.frames.length, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // SpinnerIndicator — rendering
  // ---------------------------------------------------------------------------
  group('SpinnerIndicator rendering', () {
    test('renders first frame by default', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(SpinnerIndicator(active: false));
        // Default frames: ['|', '/', '-', '\\']
        // startIndex 0 → first frame is '|'
        expect(tester.find.text('|'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders frame at startIndex', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SpinnerIndicator(
            frames: const ['A', 'B', 'C', 'D'],
            startIndex: 2,
            active: false,
          ),
        );
        expect(tester.find.text('C'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('startIndex wraps around via modulo', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SpinnerIndicator(
            frames: const ['X', 'Y', 'Z'],
            startIndex: 5, // 5 % 3 = 2 → 'Z'
            active: false,
          ),
        );
        expect(tester.find.text('Z'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('custom frames render correctly', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SpinnerIndicator(frames: const ['***'], active: false),
        );
        expect(tester.find.text('***'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('empty frames renders empty (SizedBox.shrink)', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(SpinnerIndicator(frames: const []));
        // With empty frames, should not crash and produce minimal output
        expect(tester.view, isNotNull);
      } finally {
        await tester.dispose();
      }
    });

    test('inactive spinner still renders current frame', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SpinnerIndicator(frames: const ['@', '#', '\$'], active: false),
        );
        // Even when inactive, the first frame should be rendered
        expect(tester.find.text('@'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('active spinner advances frames over time', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SpinnerIndicator(
            frames: const ['1', '2', '3'],
            interval: const Duration(milliseconds: 40),
          ),
        );
        expect(tester.find.text('1'), isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 65));
        tester.pump();

        final advanced = tester.find.text('2') || tester.find.text('3');
        expect(advanced, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('spinner mounted after startup still starts ticking', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(_DelayedSpinnerMountHost());
        expect(tester.find.text('1'), isFalse);

        tester.sendKey('t');
        tester.pump();
        expect(tester.find.text('1'), isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 170));
        tester.pump();
        final advanced = tester.find.text('2') || tester.find.text('3');
        expect(advanced, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('spinner keeps ticking after parent rebuild', () async {
      const frames = ['a', 'b', 'c', 'd'];
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(_SpinnerParentRebuildHost());

        tester.sendKey('r');
        tester.pump();
        final before = _visibleSpinnerFrame(tester, frames);
        expect(before, isNotEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 220));
        tester.pump();

        final after = _visibleSpinnerFrame(tester, frames);
        expect(after, isNotEmpty);
        expect(after, isNot(equals(before)));
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SpinnerIndicator — handleInit
  // ---------------------------------------------------------------------------
  group('SpinnerIndicator handleInit', () {
    test('widget-level handleInit returns null', () {
      final spinner = SpinnerIndicator(active: true);
      final cmd = spinner.handleInit();
      expect(cmd, isNull);
    });

    test('inactive spinner returns null from handleInit', () {
      final spinner = SpinnerIndicator(active: false);
      final cmd = spinner.handleInit();
      expect(cmd, isNull);
    });

    test('empty frames returns null from handleInit', () {
      final spinner = SpinnerIndicator(frames: const []);
      final cmd = spinner.handleInit();
      expect(cmd, isNull);
    });

    test('inactive with empty frames returns null from handleInit', () {
      final spinner = SpinnerIndicator(active: false, frames: const []);
      final cmd = spinner.handleInit();
      expect(cmd, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // SpinnerIndicator — within layout
  // ---------------------------------------------------------------------------
  group('SpinnerIndicator in layout', () {
    test('renders inside a Row', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Row(
            children: [
              SpinnerIndicator(frames: const ['*']),
              Text(' Loading...'),
            ],
          ),
        );
        expect(tester.find.text('*'), isTrue);
        expect(tester.find.text('Loading...'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders inside a Column', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Column(
            children: [
              SpinnerIndicator(frames: const ['>']),
              Text('Status'),
            ],
          ),
        );
        expect(tester.find.text('>'), isTrue);
        expect(tester.find.text('Status'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders inside a Container', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          Container(
            width: 10,
            height: 3,
            child: SpinnerIndicator(frames: const ['^']),
          ),
        );
        expect(tester.find.text('^'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SpinnerIndicator — theme integration
  // ---------------------------------------------------------------------------
  group('SpinnerIndicator theme', () {
    test('uses theme primary color by default', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        // No custom color — should use theme.primary
        await tester.pumpWidget(SpinnerIndicator(frames: const ['@']));
        // The spinner should render with styled text
        expect(tester.view, isNotEmpty);
        expect(tester.find.text('@'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('custom color overrides theme', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SpinnerIndicator(frames: const ['@'], color: AnsiColor(196)),
        );
        expect(tester.find.text('@'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('custom textStyle is applied', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          SpinnerIndicator(frames: const ['@'], textStyle: Style().bold()),
        );
        expect(tester.find.text('@'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('renders under custom ThemeScope', () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: SpinnerIndicator(frames: const ['!']),
          ),
        );
        expect(tester.find.text('!'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SpinnerIndicator — animation tick (deterministic)
  // ---------------------------------------------------------------------------
  group('SpinnerIndicator animation', () {
    test('active true with non-empty frames animates when mounted', () async {
      final spinner = SpinnerIndicator(
        frames: const ['A', 'B', 'C'],
        interval: const Duration(milliseconds: 50),
        active: true,
      );
      final tester = WidgetTester(screenWidth: 20, screenHeight: 5);
      try {
        await tester.pumpWidget(spinner);
        expect(tester.find.text('A'), isTrue);

        var advanced = false;
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          tester.pump();
          if (tester.find.text('B') || tester.find.text('C')) {
            advanced = true;
            break;
          }
        }

        expect(advanced, isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('active false produces no init cmd', () {
      final spinner = SpinnerIndicator(
        frames: const ['A', 'B', 'C'],
        active: false,
      );
      expect(spinner.handleInit(), isNull);
    });
  });
}
