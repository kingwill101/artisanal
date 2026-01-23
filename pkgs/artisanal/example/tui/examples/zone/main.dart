// BubbleZone Example - Mouse click zones in TUI
//
// This example demonstrates using zones to track clickable regions
// in a terminal application. Click on the buttons to see them respond!
//
// Run with: dart run example/tui/examples/zone/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() async {
  // Initialize the global zone manager before running the program
  initGlobalZone();

  await runProgram(
    ZoneExampleModel(),
    options: const ProgramOptions(
      mouse: true, // Enable mouse support
      altScreen: true, // Use alternate screen
    ),
  );

  // Clean up when done
  closeGlobalZone();
}

// Button styles
final _titleStyle = Style().bold().foreground(Colors.cyan);
final _buttonStyle = Style()
    .foreground(Colors.white)
    .background(Colors.gray700);
final _buttonHoverStyle = Style()
    .bold()
    .foreground(Colors.black)
    .background(Colors.cyan);
final _buttonActiveStyle = Style()
    .bold()
    .foreground(Colors.black)
    .background(Colors.success);
final _quitButtonStyle = Style()
    .foreground(Colors.white)
    .background(Colors.error);
final _quitButtonHoverStyle = Style()
    .bold()
    .foreground(Colors.white)
    .background(Colors.brightRed);
final _labelStyle = Style().dim();
final _valueStyle = Style().foreground(Colors.yellow);
final _helpStyle = Style().dim().italic();

class ZoneExampleModel implements Model {
  ZoneExampleModel({
    this.clicks = 0,
    this.lastClicked = '',
    this.hoveredButton = '',
  });

  final int clicks;
  final String lastClicked;
  final String hoveredButton;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      // Quit on 'q' or Ctrl+C
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (
        this,
        Cmd.quit(),
      ),
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (this, Cmd.quit()),

      // Handle mouse clicks
      MouseMsg(action: MouseAction.press, button: MouseButton.left) =>
        _handleClick(msg),

      // Handle mouse motion for hover effects
      MouseMsg(action: MouseAction.motion) => _handleMotion(msg),

      _ => (this, null),
    };
  }

  (Model, Cmd?) _handleClick(MouseMsg msg) {
    // Check each button zone
    for (final buttonId in ['btn-ok', 'btn-cancel', 'btn-help', 'btn-quit']) {
      final zoneInfo = zone.get(buttonId);
      if (zoneInfo?.inBounds(msg) ?? false) {
        if (buttonId == 'btn-quit') {
          return (this, Cmd.quit());
        }
        return (
          ZoneExampleModel(
            clicks: clicks + 1,
            lastClicked: buttonId,
            hoveredButton: hoveredButton,
          ),
          null,
        );
      }
    }
    return (this, null);
  }

  (Model, Cmd?) _handleMotion(MouseMsg msg) {
    // Find which button is being hovered
    String newHovered = '';
    for (final buttonId in ['btn-ok', 'btn-cancel', 'btn-help', 'btn-quit']) {
      final zoneInfo = zone.get(buttonId);
      if (zoneInfo?.inBounds(msg) ?? false) {
        newHovered = buttonId;
        break;
      }
    }

    if (newHovered != hoveredButton) {
      return (
        ZoneExampleModel(
          clicks: clicks,
          lastClicked: lastClicked,
          hoveredButton: newHovered,
        ),
        null,
      );
    }
    return (this, null);
  }

  @override
  String view() {
    final buffer = StringBuffer();

    // Title
    buffer.writeln();
    buffer.writeln(
      '  ${_titleStyle.render('BubbleZone Demo')} - Click the buttons!',
    );
    buffer.writeln();

    // Buttons row
    final buttons = [
      _renderButton('btn-ok', '  OK  '),
      _renderButton('btn-cancel', 'Cancel'),
      _renderButton('btn-help', ' Help '),
      _renderButton('btn-quit', ' Quit ', isQuit: true),
    ];
    buffer.writeln('  ${buttons.join('  ')}');
    buffer.writeln();

    // Status
    buffer.writeln(
      '  ${_labelStyle.render('Total clicks:')} ${_valueStyle.render('$clicks')}',
    );
    if (lastClicked.isNotEmpty) {
      final buttonName = lastClicked.replaceFirst('btn-', '').toUpperCase();
      buffer.writeln(
        '  ${_labelStyle.render('Last clicked:')} ${_valueStyle.render(buttonName)}',
      );
    }
    if (hoveredButton.isNotEmpty) {
      final buttonName = hoveredButton.replaceFirst('btn-', '').toUpperCase();
      buffer.writeln(
        '  ${_labelStyle.render('Hovering:')} ${_valueStyle.render(buttonName)}',
      );
    }
    buffer.writeln();

    // Instructions
    buffer.writeln('  ${_helpStyle.render('Press q to quit')}');
    buffer.writeln();

    // Scan the entire output to register zones
    return zone.scan(buffer.toString());
  }

  String _renderButton(String id, String label, {bool isQuit = false}) {
    final isHovered = hoveredButton == id;
    final isLastClicked = lastClicked == id;

    // Select the appropriate style
    Style style;
    if (isQuit) {
      style = isHovered ? _quitButtonHoverStyle : _quitButtonStyle;
    } else if (isHovered) {
      style = _buttonHoverStyle;
    } else if (isLastClicked) {
      style = _buttonActiveStyle;
    } else {
      style = _buttonStyle;
    }

    // Render the button with padding
    final rendered = style.render(' $label ');

    // Wrap with zone marker
    return zone.mark(id, rendered);
  }
}
