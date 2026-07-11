#!/usr/bin/env dart
// tui:allow-stdout - this example is a one-shot capability report, not a TUI.

import 'dart:io' as io;

import 'package:artisanal/src/terminal/report_probe.dart';
import 'package:artisanal/uv.dart' as uv;

Future<void> main(List<String> arguments) async {
  final report = await TerminalReportProbe.probe();
  final env = io.Platform.environment;
  final capabilities = uv.TerminalCapabilities(
    env: env.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .toList(growable: false),
  );

  if (report != null) {
    if (report.terminalVersion case final version?) {
      capabilities.updateFromEvent(uv.TerminalVersionEvent(version));
    }
    if (report.primaryAttributes.isNotEmpty) {
      capabilities.updateFromEvent(
        uv.PrimaryDeviceAttributesEvent(
          List<int>.from(report.primaryAttributes),
        ),
      );
    }
    if (report.secondaryAttributes.isNotEmpty) {
      capabilities.updateFromEvent(
        uv.SecondaryDeviceAttributesEvent(
          List<int>.from(report.secondaryAttributes),
        ),
      );
    }
  }

  io.stdout.writeln('Terminal Capability Probe');
  io.stdout.writeln();
  io.stdout.writeln('Environment');
  io.stdout.writeln('  TERM: ${_valueOrNotReported(env['TERM'])}');
  io.stdout.writeln(
    '  TERM_PROGRAM: ${_valueOrNotReported(env['TERM_PROGRAM'])}',
  );
  io.stdout.writeln(
    '  LC_TERMINAL: ${_valueOrNotReported(env['LC_TERMINAL'])}',
  );
  io.stdout.writeln(
    '  KITTY_WINDOW_ID: ${_valueOrNotReported(env['KITTY_WINDOW_ID'])}',
  );
  io.stdout.writeln();
  io.stdout.writeln('Reports');
  io.stdout.writeln(
    '  terminal version: ${_valueOrNotReported(report?.terminalVersion)}',
  );
  io.stdout.writeln(
    '  primary DA: ${report == null || report.primaryAttributes.isEmpty ? 'not reported' : report.primaryAttributes.join(', ')}',
  );
  io.stdout.writeln(
    '  secondary DA: ${report == null || report.secondaryAttributes.isEmpty ? 'not reported' : report.secondaryAttributes.join(', ')}',
  );
  io.stdout.writeln(
    '  window px: ${_pairOrNotReported(report?.windowPixelWidth, report?.windowPixelHeight)}',
  );
  io.stdout.writeln(
    '  cell px: ${_pairOrNotReported(report?.cellPixelWidth, report?.cellPixelHeight)}',
  );
  io.stdout.writeln();
  io.stdout.writeln('Derived');
  io.stdout.writeln('  hasSixel: ${capabilities.hasSixel}');
  io.stdout.writeln('  hasKittyGraphics: ${capabilities.hasKittyGraphics}');
  io.stdout.writeln('  hasITerm2: ${capabilities.hasITerm2}');
  io.stdout.writeln();
  io.stdout.writeln('Raw response');
  io.stdout.writeln('  ${_valueOrNotReported(report?.rawResponse)}');
}

String _valueOrNotReported(String? value) {
  if (value == null || value.isEmpty) return 'not reported';
  return value;
}

String _pairOrNotReported(int? width, int? height) {
  if (width == null || height == null) return 'not reported';
  return '$width x $height';
}
