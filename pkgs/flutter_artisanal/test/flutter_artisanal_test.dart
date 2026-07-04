import 'dart:async';
import 'dart:convert';

import 'package:artisanal/runtime.dart' show Model, Cmd, Msg;
import 'package:artisanal_widgets/artisanal_widgets.dart'
    show StatelessWidget, Widget, BuildContext, WidgetApp, SizedBox;
import 'package:artisanal_widgets/widgets.dart'
    show ArtisanalApp;
import 'package:flutter/foundation.dart';
import 'package:flutter_artisanal/flutter_artisanal.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestRoot extends StatelessWidget {
  _TestRoot();

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}

class _TestModel implements Model {
  const _TestModel([this.count = 0]);

  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg && msg.key.type == KeyType.enter) {
      return (_TestModel(count + 1), null);
    }
    return (this, null);
  }

  @override
  String view() => 'Count: $count';
}

void main() {
  Future<void> _waitForFirstFrame(Listenable repaint) async {
    final completer = Completer<void>();
    repaint.addListener(() {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  group('TuiController', () {
    test('start initializes backend and renderer', () async {
      final controller = TuiController<_TestModel>(
        model: const _TestModel(),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      expect(controller.buffer, isNull);
      expect(controller.done, isNull);

      await controller.start();

      expect(controller.done, isNotNull);

      await controller.dispose();
    });

    test('addInput forwards bytes to backend', () async {
      final controller = TuiController<_TestModel>(
        model: const _TestModel(),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      await controller.start();

      controller.addInput(utf8.encode('hello'));
      controller.requestShutdown();

      await controller.dispose();
    });

    test('resize notifies backend of new size', () async {
      final controller = TuiController<_TestModel>(
        model: const _TestModel(),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      await controller.start();

      controller.resize(120, 40);
      controller.requestShutdown();

      await controller.dispose();
    });

    test('dispose cleans up resources', () async {
      final controller = TuiController<_TestModel>(
        model: const _TestModel(),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      await controller.start();
      controller.requestShutdown();
      await controller.dispose();

      expect(() => controller.addInput([]), returnsNormally);
    });

    test('start throws if already started', () async {
      final controller = TuiController<_TestModel>(
        model: const _TestModel(),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      await controller.start();
      expect(() => controller.start(), throwsStateError);

      controller.requestShutdown();
      await controller.dispose();
    });
  });

  group('WidgetAppBinding', () {
    test('exposes buffer, repaint, and done', () async {
      final binding = WidgetAppBinding(
        app: WidgetApp(_TestRoot()),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      expect(binding.buffer, isNull);
      expect(binding.repaint, isNotNull);
      expect(binding.done, isNull);

      await binding.start();

      expect(binding.done, isNotNull);

      await binding.dispose();
    });

    test('addInput and resize forward to controller', () async {
      final binding = WidgetAppBinding(
        app: WidgetApp(_TestRoot()),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      await binding.start();

      binding.addInput(utf8.encode('x'));
      binding.resize(100, 30);
      binding.requestShutdown();

      await binding.dispose();
    });
  });

  group('ArtisanalAppBinding', () {
    test('start resolves options from app title', () async {
      final binding = ArtisanalAppBinding(
        app: ArtisanalApp(title: 'Test', home: _TestRoot()),
        options: const ProgramOptions(altScreen: true, hotReload: false),
      );

      await binding.start();

      expect(binding.done, isNotNull);
      expect(binding.app, isNotNull);

      await binding.dispose();
    });
  });
}
