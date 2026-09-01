import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ultraviolet/input.dart';
import 'ansi.dart';
import 'terminal_io_impl.dart';

/// Parsed terminal report values captured via direct `/dev/tty` probing.
final class TerminalReportSnapshot {
  const TerminalReportSnapshot({
    required this.rawResponse,
    this.terminalVersion,
    this.primaryAttributes = const <int>[],
    this.secondaryAttributes = const <int>[],
    this.windowPixelWidth,
    this.windowPixelHeight,
    this.cellPixelWidth,
    this.cellPixelHeight,
  });

  /// Raw bytes decoded as text for debugging.
  final String rawResponse;

  /// XTVERSION / terminal-identifying version string.
  final String? terminalVersion;

  /// Primary device attributes (DA1).
  final List<int> primaryAttributes;

  /// Secondary device attributes (DA2).
  final List<int> secondaryAttributes;

  /// Reported terminal window width in pixels.
  final int? windowPixelWidth;

  /// Reported terminal window height in pixels.
  final int? windowPixelHeight;

  /// Reported cell width in pixels.
  final int? cellPixelWidth;

  /// Reported cell height in pixels.
  final int? cellPixelHeight;

  /// Whether the terminal advertised sixel support via DA1 attribute 4.
  bool get hasSixel => primaryAttributes.contains(4);
}

/// Best-effort direct `/dev/tty` report probe.
///
/// This is useful when the main runtime input path is not receiving terminal
/// replies reliably but the controlling TTY can still be queried directly.
final class TerminalReportProbe {
  /// Decodes a raw terminal report payload into a structured snapshot.
  ///
  /// Exposed so examples and tests can validate decoding independently of live
  /// `/dev/tty` I/O.
  static TerminalReportSnapshot decodeBytes(List<int> bytes) {
    return _decodeSnapshot(bytes);
  }

  /// Queries `/dev/tty` directly and parses a small set of terminal reports.
  static Future<TerminalReportSnapshot?> probe({
    Duration idleTimeout = const Duration(milliseconds: 120),
    Duration totalTimeout = const Duration(milliseconds: 600),
    String ttyPath = '/dev/tty',
  }) async {
    final tty = TtyTerminal.tryOpen(path: ttyPath);
    if (tty == null || !tty.supportsAnsi || !tty.isTerminal) return null;

    final bytes = BytesBuilder(copy: false);
    StreamSubscription<List<int>>? sub;
    Timer? idleTimer;
    Timer? deadlineTimer;
    final done = Completer<void>();

    void finish() {
      if (!done.isCompleted) done.complete();
    }

    try {
      tty.enableRawMode();

      sub = tty.input.listen(
        (chunk) {
          if (chunk.isNotEmpty) bytes.add(chunk);
          idleTimer?.cancel();
          idleTimer = Timer(idleTimeout, finish);
        },
        onError: (_, _) => finish(),
        onDone: finish,
        cancelOnError: false,
      );
      deadlineTimer = Timer(totalTimeout, finish);

      tty.write(Ansi.requestPrimaryDeviceAttributes);
      tty.write(Ansi.requestSecondaryDeviceAttributes);
      tty.write(Ansi.requestTerminalVersion);
      tty.write('\x1b[14t');
      tty.write('\x1b[16t');
      await tty.flush();

      idleTimer = Timer(idleTimeout, finish);
      await done.future;
      await sub.cancel();

      final collected = bytes.takeBytes();
      return decodeBytes(collected);
    } finally {
      idleTimer?.cancel();
      deadlineTimer?.cancel();
      await sub?.cancel();
      tty.dispose();
    }
  }

  static TerminalReportSnapshot _decodeSnapshot(List<int> bytes) {
    final decoder = EventDecoder();
    final pending = List<int>.from(bytes);

    String? terminalVersion;
    List<int> primary = const <int>[];
    List<int> secondary = const <int>[];
    int? windowPixelWidth;
    int? windowPixelHeight;
    int? cellPixelWidth;
    int? cellPixelHeight;

    void handleEvent(Event event) {
      if (event is MultiEvent) {
        for (final child in event.events) {
          handleEvent(child);
        }
        return;
      }
      switch (event) {
        case TerminalVersionEvent(:final name):
          terminalVersion = name;
        case PrimaryDeviceAttributesEvent(:final attrs):
          primary = List<int>.unmodifiable(attrs);
        case SecondaryDeviceAttributesEvent(:final attrs):
          secondary = List<int>.unmodifiable(attrs);
        case WindowPixelSizeEvent(:final width, :final height):
          windowPixelWidth = width;
          windowPixelHeight = height;
        case CellSizeEvent(:final width, :final height):
          cellPixelWidth = width;
          cellPixelHeight = height;
        default:
          break;
      }
    }

    while (pending.isNotEmpty) {
      final (consumed, event) = decoder.decode(
        pending,
        allowIncompleteEsc: true,
      );
      if (consumed <= 0) break;
      pending.removeRange(0, consumed);
      if (event != null) handleEvent(event);
    }

    return TerminalReportSnapshot(
      rawResponse: utf8.decode(bytes, allowMalformed: true),
      terminalVersion: terminalVersion,
      primaryAttributes: primary,
      secondaryAttributes: secondary,
      windowPixelWidth: windowPixelWidth,
      windowPixelHeight: windowPixelHeight,
      cellPixelWidth: cellPixelWidth,
      cellPixelHeight: cellPixelHeight,
    );
  }
}
