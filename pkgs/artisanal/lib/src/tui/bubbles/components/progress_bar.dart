import 'dart:async';

import '../../cmd.dart';
import '../../component.dart';
import '../../msg.dart';
import 'base.dart';
import '../../../style/style.dart';

/// A progress bar component.
///
/// For static rendering (shows current state):
/// ```dart
/// print(ProgressBarComponent(current: 50, total: 100).render());
/// ```
///
/// {@category TUI}
///
/// {@macro artisanal_bubbles_display_components}
class ProgressBarComponent extends DisplayComponent {
  const ProgressBarComponent({
    required this.current,
    required this.total,
    this.width = 40,
    this.fillChar = '=',
    this.emptyChar = ' ',
    this.showPercentage = true,
    this.showCount = true,
    this.renderConfig = const RenderConfig(),
  });

  final int current;
  final int total;
  final int width;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;
  final bool showCount;
  final RenderConfig renderConfig;

  @override
  String render() {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final filled = (progress * width).round();
    final empty = width - filled;

    final bar = '[${fillChar * filled}${emptyChar * empty}]';
    final parts = <String>[bar];
    final dim = renderConfig.configureStyle(Style().dim());

    if (showCount) {
      parts.add(dim.render('$current/$total'));
    }
    if (showPercentage) {
      parts.add(dim.render('$pct%'));
    }

    return parts.join(' ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TUI-first model + messages (UV-safe)
// ─────────────────────────────────────────────────────────────────────────────

int _lastProgressBarId = 0;
int _nextProgressBarId() => ++_lastProgressBarId;

sealed class ProgressBarMsg extends Msg {
  const ProgressBarMsg({required this.id});
  final int id;
}

final class ProgressBarSetMsg extends ProgressBarMsg {
  const ProgressBarSetMsg({
    required super.id,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;
}

final class ProgressBarAdvanceMsg extends ProgressBarMsg {
  const ProgressBarAdvanceMsg({required super.id, this.step = 1});
  final int step;
}

final class ProgressBarIterateDoneMsg extends ProgressBarMsg {
  const ProgressBarIterateDoneMsg({required super.id});
}

final class ProgressBarIterateErrorMsg extends ProgressBarMsg {
  const ProgressBarIterateErrorMsg({
    required super.id,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}

/// A UV-safe progress bar model that can be hosted inside a parent [Model].
///
/// This model **does not write to the terminal**. It only renders via [view()].
///
/// Drive it using:
/// - [ProgressBarSetMsg] / [ProgressBarAdvanceMsg], or
/// - [progressIterateCmd] for a turn-key stream command.
final class ProgressBarModel extends ViewComponent {
  ProgressBarModel({
    int? id,
    this.current = 0,
    this.total = 0,
    this.width = 40,
    this.fillChar = '=',
    this.emptyChar = ' ',
    this.showPercentage = true,
    this.showCount = true,
    this.renderConfig = const RenderConfig(),
  }) : id = id ?? _nextProgressBarId();

  final int id;
  final int current;
  final int total;
  final int width;
  final String fillChar;
  final String emptyChar;
  final bool showPercentage;
  final bool showCount;
  final RenderConfig renderConfig;

  ProgressBarModel copyWith({
    int? current,
    int? total,
    int? width,
    String? fillChar,
    String? emptyChar,
    bool? showPercentage,
    bool? showCount,
    RenderConfig? renderConfig,
  }) {
    return ProgressBarModel(
      id: id,
      current: current ?? this.current,
      total: total ?? this.total,
      width: width ?? this.width,
      fillChar: fillChar ?? this.fillChar,
      emptyChar: emptyChar ?? this.emptyChar,
      showPercentage: showPercentage ?? this.showPercentage,
      showCount: showCount ?? this.showCount,
      renderConfig: renderConfig ?? this.renderConfig,
    );
  }

  @override
  Cmd? init() => null;

  @override
  (ViewComponent, Cmd?) update(Msg msg) {
    return switch (msg) {
      ProgressBarSetMsg(:final id, :final current, :final total)
          when id == this.id =>
        (copyWith(current: current, total: total), null),
      ProgressBarAdvanceMsg(:final id, :final step) when id == this.id => (
        copyWith(
          current: total > 0
              ? (current + step).clamp(0, total)
              : current + step,
        ),
        null,
      ),
      _ => (this, null),
    };
  }

  @override
  String view() {
    return ProgressBarComponent(
      current: current,
      total: total,
      width: width,
      fillChar: fillChar,
      emptyChar: emptyChar,
      showPercentage: showPercentage,
      showCount: showCount,
      renderConfig: renderConfig,
    ).render();
  }
}

/// Produces a UV-safe [StreamCmd] that runs [onItem] for each element and emits
/// progress updates for a hosted [ProgressBarModel].
///
/// The returned command emits:
/// - an initial [ProgressBarSetMsg] (0/total)
/// - a [ProgressBarSetMsg] after each item completes (n/total)
/// - [ProgressBarIterateDoneMsg] when finished
/// - [ProgressBarIterateErrorMsg] on failure (and then completes)
StreamCmd<Msg> progressIterateCmd<T>({
  required int id,
  required Iterable<T> items,
  required Future<void> Function(T item) onItem,
}) {
  final list = items.toList(growable: false);
  final total = list.length;

  Stream<Msg> stream() async* {
    yield ProgressBarSetMsg(id: id, current: 0, total: total);
    try {
      for (var i = 0; i < total; i++) {
        await onItem(list[i]);
        yield ProgressBarSetMsg(id: id, current: i + 1, total: total);
      }
      yield ProgressBarIterateDoneMsg(id: id);
    } catch (e, st) {
      yield ProgressBarIterateErrorMsg(id: id, error: e, stackTrace: st);
    }
  }

  return Cmd.listen<Msg>(stream(), onData: (m) => m);
}
