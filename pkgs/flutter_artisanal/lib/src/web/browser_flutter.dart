import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

import '../terminal_painter.dart';
import '../input_encoder.dart';

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
    this.onResize,
    this.onPlatformBrightnessChanged,
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
  final void Function(int width, int height)? onResize;
  final void Function(bool isDark)? onPlatformBrightnessChanged;

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  late final FocusNode _focusNode;

  static List<int> _encodeSgrMouse({
    required int x,
    required int y,
    required int button,
    required bool press,
    bool motion = false,
    bool shift = false,
    bool alt = false,
    bool ctrl = false,
  }) {
    return InputEncoder.encodeSgrMouse(
      x: x,
      y: y,
      button: button,
      press: press,
      motion: motion,
      shift: shift,
      alt: alt,
      ctrl: ctrl,
    );
  }

  void _sendMouse(int x, int y, int button, bool press,
      {bool motion = false, bool shift = false, bool alt = false, bool ctrl = false}) {
    final bytes = _encodeSgrMouse(
      x: x,
      y: y,
      button: button,
      press: press,
      motion: motion,
      shift: shift,
      alt: alt,
      ctrl: ctrl,
    );
    widget.onKey?.call(bytes);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.repaint?.addListener(_onRepaint);
    // RawKeyboard listener captures hardware keys regardless of Focus state.
    // This is the reliable low-level path on desktop Linux where Focus
    // autofocus is not guaranteed without a parent WidgetsApp/MaterialApp.
    // ignore: deprecated_member_use
    RawKeyboard.instance.addListener(_onRawKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = MediaQuery.of(context).platformBrightness;
    widget.onPlatformBrightnessChanged?.call(brightness == Brightness.dark);
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
    // ignore: deprecated_member_use
    RawKeyboard.instance.removeListener(_onRawKey);
    _focusNode.dispose();
    widget.repaint?.removeListener(_onRepaint);
    super.dispose();
  }

  void _onRepaint() {
    if (mounted) setState(() {});
  }

  // ignore: deprecated_member_use
  void _onRawKey(RawKeyEvent event) {
    if (widget.onKey == null) return;
    if (event is! RawKeyDownEvent) return;

    final bytes = <int>[];
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      final codeUnit = character.codeUnitAt(0);
      if (codeUnit >= 0x20 && codeUnit != 0x7f) {
        bytes.addAll(utf8.encode(character));
      }
    }

    if (bytes.isEmpty) {
      final mapped = InputEncoder.encodeSpecialKey(event.logicalKey);
      if (mapped.isNotEmpty) {
        bytes.addAll(mapped);
      }
    }

    if (bytes.isEmpty) {
      final label = event.logicalKey.keyLabel;
      if (label.isNotEmpty) {
        final codeUnit = label.codeUnitAt(0);
        if (codeUnit >= 0x20 && codeUnit != 0x7f) {
          bytes.addAll(utf8.encode(label));
        }
      }
    }

    if (bytes.isNotEmpty) {
      widget.onKey!(bytes);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (widget.onKey == null) {
      return KeyEventResult.ignored;
    }

    if (event is KeyUpEvent) {
      return KeyEventResult.handled;
    }

    final bytes = <int>[];
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      final codeUnit = character.codeUnitAt(0);
      if (codeUnit >= 0x20 && codeUnit != 0x7f) {
        bytes.addAll(utf8.encode(character));
      }
    }

    if (bytes.isEmpty) {
      final mapped = InputEncoder.encodeSpecialKey(event.logicalKey);
      if (mapped.isNotEmpty) {
        bytes.addAll(mapped);
      }
    }

    if (bytes.isEmpty && event is KeyDownEvent) {
      final label = event.logicalKey.keyLabel;
      if (label.isNotEmpty) {
        final codeUnit = label.codeUnitAt(0);
        if (codeUnit >= 0x20 && codeUnit != 0x7f) {
          bytes.addAll(utf8.encode(label));
        }
      }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final cols = maxWidth > 0 ? (maxWidth / cw).floor() : 80;
        final rows = maxHeight > 0 ? (maxHeight / ch).floor() : 24;

        if (widget.onResize != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onResize!(cols, rows);
          });
        }

        final paintWidth = cw * cols;
        final paintHeight = ch * rows;

        final terminal = SizedBox.expand(
          child: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _focusNode.requestFocus();
              },
              child: Focus(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: _handleKey,
                child: CustomPaint(
                  size: Size(paintWidth, paintHeight),
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
              ),
            ),
          ),
        );

        if (widget.onKey == null) return terminal;

        return MouseRegion(
          child: Listener(
            onPointerHover: (event) {
              final x = (event.localPosition.dx / cw).floor();
              final y = (event.localPosition.dy / ch).floor();
              final buttons = event.buttons;
              int button = 0;
              bool press = false;
              if (buttons == kPrimaryButton) {
                button = 0;
                press = true;
              } else if (buttons == kSecondaryButton) {
                button = 2;
                press = true;
              } else if (buttons == 4) {
                button = 1;
                press = true;
              }
              if (button == 0 && !press) {
                button = 3;
              }
              _sendMouse(x, y, button, press, motion: true);
            },
            onPointerDown: (event) {
              final x = (event.localPosition.dx / cw).floor();
              final y = (event.localPosition.dy / ch).floor();
              int button = 0;
              if (event.buttons == kSecondaryButton) {
                button = 2;
              } else if (event.buttons == 4) {
                button = 1;
              } else {
                button = 0;
              }
              _sendMouse(x, y, button, true);
            },
            onPointerUp: (event) {
              final x = (event.localPosition.dx / cw).floor();
              final y = (event.localPosition.dy / ch).floor();
              int button = 3;
              _sendMouse(x, y, button, false);
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final x = (event.localPosition.dx / cw).floor();
                final y = (event.localPosition.dy / ch).floor();
                final scroll = event.scrollDelta;
                int button = 0;
                if (scroll.dy > 0) {
                  button = 65;
                } else if (scroll.dy < 0) {
                  button = 64;
                } else if (scroll.dx > 0) {
                  button = 67;
                } else if (scroll.dx < 0) {
                  button = 66;
                }
                if (button != 0) {
                  _sendMouse(x, y, button, true);
                }
              }
            },
            child: terminal,
          ),
        );
      },
    );
  }
}
