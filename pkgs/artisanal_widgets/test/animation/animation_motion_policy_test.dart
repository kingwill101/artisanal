import 'package:artisanal/runtime.dart' show Cmd, ParallelCmd;
import 'package:artisanal_widgets/testing.dart' show WidgetTester;
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('AnimationMixin follows live reduced-motion policy changes', () async {
    final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
    try {
      await tester.pumpWidget(_MotionHost());
      expect(tester.view, contains('0.0 forward full'));

      tester.tap(tester.find.textLocation('reduce'));
      expect(tester.view, contains('1.0 completed reduced'));
      expect(tester.view, contains('pulse:0.0 forward'));

      tester.tap(tester.find.textLocation('reverse'));
      expect(tester.view, contains('0.0 dismissed reduced'));

      tester.tap(tester.find.textLocation('enable'));
      expect(tester.view, contains('0.0 forward full'));
      expect(tester.view, contains('pulse:0.0 forward'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      tester.pump();
      expect(tester.view, matches(RegExp(r'pulse:0\.[1-9] forward')));
    } finally {
      await tester.dispose();
    }
  });
}

class _MotionHost extends StatefulWidget {
  _MotionHost();

  @override
  State<_MotionHost> createState() => _MotionHostState();
}

class _MotionHostState extends State<_MotionHost> {
  bool _animationsEnabled = true;
  double _target = 1;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        onTap: () {
          setState(() => _animationsEnabled = false);
          return null;
        },
        child: Text('reduce'),
      ),
      GestureDetector(
        onTap: () {
          setState(() => _target = 0);
          return null;
        },
        child: Text('reverse'),
      ),
      GestureDetector(
        onTap: () {
          setState(() {
            _animationsEnabled = true;
            _target = 1;
          });
          return null;
        },
        child: Text('enable'),
      ),
      MotionScope(
        enabled: _animationsEnabled,
        child: _MotionProbe(target: _target),
      ),
    ],
  );
}

class _MotionProbe extends StatefulWidget {
  _MotionProbe({required this.target});

  final double target;

  @override
  State<_MotionProbe> createState() => _MotionProbeState();
}

class _MotionProbeState extends State<_MotionProbe> with AnimationMixin {
  late final AnimationController _controller;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration: const Duration(seconds: 1),
    );
    _pulse = createAnimationController(duration: const Duration(seconds: 1));
    _controller.addListener(() => setState(() {}));
    _pulse.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() =>
      ParallelCmd([_controller.animateTo(widget.target), _pulse.repeat()]);

  @override
  Cmd? didUpdateWidget(covariant _MotionProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      return _controller.animateTo(widget.target);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '${_controller.value.toStringAsFixed(1)} '
        '${_controller.status.name} '
        '${_controller.disableAnimations ? 'reduced' : 'full'}',
      ),
      Text('pulse:${_pulse.value.toStringAsFixed(1)} ${_pulse.status.name}'),
    ],
  );
}
