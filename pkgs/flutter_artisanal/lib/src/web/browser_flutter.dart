import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

import '../terminal_painter.dart';

class TerminalWidget extends StatefulWidget {
  const TerminalWidget({
    super.key,
    this.buffer,
    this.cellWidth,
    this.cellHeight,
    this.fontFamily = 'monospace',
    this.fontSize = 14,
    this.defaultFg,
    this.defaultBg,
    this.cursorColor,
    this.repaint,
    this.onKey,
  });

  final uv.Buffer? buffer;
  final double? cellWidth;
  final double? cellHeight;
  final String fontFamily;
  final double fontSize;
  final ui.Color? defaultFg;
  final ui.Color? defaultBg;
  final ui.Color? cursorColor;
  final Listenable? repaint;
  final void Function(List<int> bytes)? onKey;

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..requestFocus();
    widget.repaint?.addListener(_onRepaint);
  }

  @override
  void didUpdateWidget(TerminalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repaint != widget.repaint) {
      oldWidget.repaint?.removeListener(_onRepaint);
      widget.repaint?.addListener(_onRepaint);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.repaint?.removeListener(_onRepaint);
    super.dispose();
  }

  void _onRepaint() {
    if (mounted) setState(() {});
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (widget.onKey == null) {
      return KeyEventResult.ignored;
    }

    final bytes = <int>[];
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      bytes.addAll(utf8.encode(character));
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      bytes.add(0x1b);
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      bytes.add(0x0d);
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      bytes.add(0x08);
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      bytes.add(0x09);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      bytes.addAll([0x1b, 0x5b, 0x41]);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      bytes.addAll([0x1b, 0x5b, 0x42]);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      bytes.addAll([0x1b, 0x5b, 0x43]);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      bytes.addAll([0x1b, 0x5b, 0x44]);
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      bytes.addAll([0x1b, 0x5b, 0x48]);
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      bytes.addAll([0x1b, 0x5b, 0x46]);
    } else if (event.logicalKey == LogicalKeyboardKey.delete) {
      bytes.addAll([0x1b, 0x5b, 0x33, 0x7e]);
    } else if (event.logicalKey == LogicalKeyboardKey.insert) {
      bytes.addAll([0x1b, 0x5b, 0x32, 0x7e]);
    } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      bytes.addAll([0x1b, 0x5b, 0x35, 0x7e]);
    } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      bytes.addAll([0x1b, 0x5b, 0x36, 0x7e]);
    } else if (event.logicalKey == LogicalKeyboardKey.f1) {
      bytes.addAll([0x1b, 0x4f, 0x50]);
    } else if (event.logicalKey == LogicalKeyboardKey.f2) {
      bytes.addAll([0x1b, 0x4f, 0x51]);
    } else if (event.logicalKey == LogicalKeyboardKey.f3) {
      bytes.addAll([0x1b, 0x4f, 0x52]);
    } else if (event.logicalKey == LogicalKeyboardKey.f4) {
      bytes.addAll([0x1b, 0x4f, 0x53]);
    } else {
      return KeyEventResult.ignored;
    }

    if (bytes.isNotEmpty) {
      widget.onKey!(bytes);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final buf = widget.buffer;
    if (buf == null) return const SizedBox.shrink();

    final cw = widget.cellWidth ?? widget.fontSize * 0.6;
    final ch = widget.cellHeight ?? widget.fontSize * 1.2;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: CustomPaint(
        size: Size(cw * buf.width(), ch * buf.height()),
        painter: TerminalPainter(
          screen: buf,
          cellWidth: cw,
          cellHeight: ch,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          defaultFg: widget.defaultFg ?? const ui.Color(0xFFE5E5E5),
          defaultBg: widget.defaultBg ?? const ui.Color(0xFF000000),
          cursorColor: widget.cursorColor ?? const ui.Color(0xFF00FF00),
          repaint: widget.repaint,
        ),
      ),
    );
  }
}
