import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/style.dart' as style;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../model.dart';
import '../panels/devices.dart' show platformIcon;
import '../theme.dart';

sealed class DevicePickerInput {
  const DevicePickerInput();
}

final class DeviceFound extends DevicePickerInput {
  const DeviceFound(this.device);

  final FlutterCliDevice device;
}

final class ToggleDevice extends DevicePickerInput {
  const ToggleDevice(this.index);

  final int index;
}

final class SelectAllDevices extends DevicePickerInput {
  const SelectAllDevices();
}

final class ConfirmDevices extends DevicePickerInput {
  const ConfirmDevices();
}

final class CancelDevices extends DevicePickerInput {
  const CancelDevices();
}

sealed class DevicePickerOutcome {
  const DevicePickerOutcome();
}

final class PickedDevices extends DevicePickerOutcome {
  const PickedDevices(this.serials);

  final List<String> serials;
}

final class CancelledDevices extends DevicePickerOutcome {
  const CancelledDevices();
}

class DevicePickerView extends w.StatefulWidget {
  DevicePickerView({
    List<FlutterCliDevice> devices = const [],
    this.flTheme = FlutterCliTheme.tokyoNight,
    super.key,
  }) : devices = List<FlutterCliDevice>.of(devices);

  final List<FlutterCliDevice> devices;
  final FlutterCliTheme flTheme;

  @override
  w.State createState() => DevicePickerViewState();
}

class DevicePickerViewState extends w.State<DevicePickerView> {
  late final List<({FlutterCliDevice device, bool checked})> devices;
  int cursor = 0;
  DevicePickerOutcome? outcome;
  bool quitting = false;

  @override
  void initState() {
    super.initState();
    devices = [
      for (final device in widget.devices) (device: device, checked: false),
    ];
  }

  void apply(DevicePickerInput input) {
    switch (input) {
      case DeviceFound(:final device):
        if (!devices.any((entry) => entry.device.serial == device.serial)) {
          devices.add((device: device, checked: false));
        }
      case ToggleDevice(:final index):
        if (index >= 0 && index < devices.length) {
          final entry = devices[index];
          devices[index] = (device: entry.device, checked: !entry.checked);
        }
      case SelectAllDevices():
        final anyUnchecked = devices.any((entry) => !entry.checked);
        for (var i = 0; i < devices.length; i++) {
          devices[i] = (device: devices[i].device, checked: anyUnchecked);
        }
      case ConfirmDevices():
        final serials = [
          for (final entry in devices)
            if (entry.checked) entry.device.serial,
        ];
        if (serials.isNotEmpty) {
          outcome = PickedDevices(serials);
          quitting = true;
        }
      case CancelDevices():
        outcome = const CancelledDevices();
        quitting = true;
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.flTheme;
    final lines = <w.Widget>[];
    for (var i = 0; i < devices.length; i++) {
      final entry = devices[i];
      final device = entry.device;
      final arrow = i == cursor ? '▸ ' : '  ';
      final bullet = entry.checked ? '[✓]' : '[ ]';
      final conn = switch (device.connection) {
        FlutterCliConnectionKind.wifi => 'WiFi',
        FlutterCliConnectionKind.usb => 'USB',
      };
      final platform = device.platform ?? '';
      final platformLabel = platform == 'ios-simulator' ? 'ios-sim' : platform;
      final glyph = platformIcon(platform);
      final platformField = glyph.isEmpty
          ? platformLabel.padRight(9)
          : '$glyph  ${platformLabel.padRight(7)}';
      lines.add(
        w.Text(
          '$arrow$bullet ${device.name.padRight(22)} $platformField $conn · ${device.serial}',
          style: i == cursor ? theme.fgStyle(theme.accent) : theme.base,
          softWrap: false,
        ),
      );
    }
    if (devices.isEmpty) {
      lines.add(w.Text('(awaiting devices…)', style: theme.dimmed));
    }
    lines.add(w.Text('', style: theme.dimmed));
    lines.add(
      w.Text(
        '↑↓ navigate   space toggle   a select all   enter run   q quit',
        style: theme.dimmed,
      ),
    );

    return w.Frame(
      border: style.Border.normal,
      borderColor: theme.accent,
      background: theme.bg,
      foreground: theme.fg,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        children: [
          w.Text(' flutter-cli run ── Select devices ', style: theme.header),
          ...lines,
        ],
      ),
    );
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is! runtime.KeyMsg) return null;
    final key = msg.key;
    final char = key.char;
    if (char == 'q' || key.type == KeyType.escape || key.ctrlC) {
      setState(() => apply(const CancelDevices()));
      return null;
    }
    if (key.type == KeyType.down && cursor + 1 < devices.length) {
      setState(() => cursor++);
      return null;
    }
    if (key.type == KeyType.up && cursor > 0) {
      setState(() => cursor--);
      return null;
    }
    if (char == ' ') {
      setState(() => apply(ToggleDevice(cursor)));
      return null;
    }
    if (char == 'a') {
      setState(() => apply(const SelectAllDevices()));
      return null;
    }
    if (key.type == KeyType.enter) {
      setState(() => apply(const ConfirmDevices()));
      return null;
    }
    return null;
  }
}

extension on runtime.Key {
  bool get ctrlC => ctrl && runes.length == 1 && runes.first == 0x63;
}
